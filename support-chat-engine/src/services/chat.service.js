const { pool } = require('../config/db');
const { v4: uuidv4 } = require('uuid');
const { sendWorkerChatNotification, sendBulkWorkerChatNotifications } = require('./fcm.service');

// Helper to extract YouTube video ID from URL
function extractYouTubeId(url) {
  if (!url) return null;
  const match = url.match(/(?:youtu\.be\/|youtube\.com\/(?:embed\/|v\/|watch\?v=|watch\?.+&v=))([\w-]{11})/);
  return match ? match[1] : null;
}

class ChatService {
  /**
   * Get or create conversation for a worker
   */
  async getOrCreateConversation(workerId, workerDetails = {}) {
    // Lookup user & worker info from DB
    const [userRows] = await pool.query(
      `SELECT u.id, u.email, u.avatar_url, w.full_name, w.phone 
       FROM users u 
       LEFT JOIN workers w ON w.user_id = u.id 
       WHERE u.id = ? OR u.email = ? LIMIT 1`,
      [workerId, workerDetails.email || '']
    );

    const userInfo = userRows[0] || {};
    const avatar = workerDetails.avatarUrl || workerDetails.photoUrl || userInfo.avatar_url || '';

    const [existing] = await pool.query(
      'SELECT * FROM support_conversations WHERE worker_id = ? LIMIT 1',
      [workerId]
    );

    if (existing.length > 0) {
      if (avatar && (!existing[0].worker_avatar_url || existing[0].worker_avatar_url === '')) {
        await pool.query('UPDATE support_conversations SET worker_avatar_url = ? WHERE id = ?', [avatar, existing[0].id]);
        existing[0].worker_avatar_url = avatar;
      }
      return existing[0];
    }

    const name = workerDetails.name || userInfo.full_name || userInfo.email?.split('@')[0] || 'Worker';
    const email = workerDetails.email || userInfo.email || '';
    const phone = workerDetails.phone || userInfo.phone || '';

    const newId = uuidv4();
    await pool.query(
      `INSERT INTO support_conversations 
       (id, worker_id, worker_name, worker_phone, worker_email, worker_avatar_url, last_message_text, last_message_type, last_message_at, unread_admin_count, unread_worker_count)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, NOW(), 0, 0)`,
      [newId, workerId, name, phone, email, avatar, 'Started conversation', 'TEXT']
    );

    const [created] = await pool.query('SELECT * FROM support_conversations WHERE id = ?', [newId]);
    return created[0];
  }

  /**
   * Get conversations for Admin (WhatsApp-like list)
   */
  async getConversations({ search = '', limit = 50, offset = 0 } = {}) {
    let query = `
      SELECT c.*, 
             COALESCE(NULLIF(c.worker_avatar_url, ''), u.avatar_url) as worker_avatar_url,
             w.last_active_at, w.total_tasks_completed, w.status as worker_status
      FROM support_conversations c
      LEFT JOIN workers w ON w.user_id = c.worker_id
      LEFT JOIN users u ON (u.id = c.worker_id OR u.email = c.worker_email)
    `;
    const params = [];

    if (search && search.trim()) {
      query += ` WHERE (c.worker_name LIKE ? OR c.worker_email LIKE ? OR c.worker_phone LIKE ? OR c.last_message_text LIKE ?)`;
      const term = `%${search.trim()}%`;
      params.push(term, term, term, term);
    }

    query += ` ORDER BY c.last_message_at DESC LIMIT ? OFFSET ?`;
    params.push(parseInt(limit, 10), parseInt(offset, 10));

    const [rows] = await pool.query(query, params);

    // Total unread count for admin badge
    const [countRows] = await pool.query(
      'SELECT SUM(unread_admin_count) as total_unread FROM support_conversations'
    );
    const totalUnread = countRows[0]?.total_unread || 0;

    return {
      conversations: rows,
      totalUnread: Number(totalUnread),
    };
  }

  /**
   * Get messages for a conversation
   */
  async getMessages(conversationId, { limit = 100, offset = 0 } = {}) {
    const [rows] = await pool.query(
      `SELECT * FROM support_messages 
       WHERE conversation_id = ? 
       ORDER BY created_at ASC 
       LIMIT ? OFFSET ?`,
      [conversationId, parseInt(limit, 10), parseInt(offset, 10)]
    );
    return rows;
  }

  /**
   * Get messages by worker ID directly (for worker app convenience)
   */
  async getMessagesByWorkerId(workerId, { limit = 100, offset = 0 } = {}) {
    const conv = await this.getOrCreateConversation(workerId);
    const messages = await this.getMessages(conv.id, { limit, offset });
    return {
      conversation: conv,
      messages,
    };
  }

  /**
   * Create and persist a message
   */
  async createMessage({
    conversationId,
    workerId,
    senderType, // 'WORKER' | 'ADMIN'
    messageType = 'TEXT', // 'TEXT' | 'IMAGE' | 'AUDIO' | 'YOUTUBE'
    content = '',
    mediaUrl = null,
    youtubeId = null,
    durationSeconds = 0,
  }) {
    if (!conversationId && workerId) {
      const conv = await this.getOrCreateConversation(workerId);
      conversationId = conv.id;
    }

    // Auto-detect YouTube URL if text contains a youtube link
    if (messageType === 'TEXT' && senderType === 'ADMIN') {
      const ytId = extractYouTubeId(content);
      if (ytId) {
        messageType = 'YOUTUBE';
        youtubeId = ytId;
      }
    } else if (messageType === 'YOUTUBE' && !youtubeId) {
      youtubeId = extractYouTubeId(content) || extractYouTubeId(mediaUrl);
    }

    const messageId = uuidv4();
    await pool.query(
      `INSERT INTO support_messages 
       (id, conversation_id, worker_id, sender_type, message_type, content, media_url, youtube_id, duration_seconds, is_read, created_at)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, 0, NOW())`,
      [
        messageId,
        conversationId,
        workerId,
        senderType,
        messageType,
        content,
        mediaUrl,
        youtubeId,
        durationSeconds || 0,
      ]
    );

    // Update conversation snippet & counters
    let previewText = content;
    if (messageType === 'YOUTUBE') previewText = '📹 Video Link';
    else if (messageType === 'AUDIO') previewText = '🎙️ Voice Note';
    else if (messageType === 'IMAGE') previewText = '📷 Photo';

    if (senderType === 'ADMIN') {
      await pool.query(
        `UPDATE support_conversations 
         SET last_message_text = ?, last_message_type = ?, last_message_at = NOW(), unread_worker_count = unread_worker_count + 1 
         WHERE id = ?`,
        [previewText, messageType, conversationId]
      );

      // Trigger Push Notification to Worker
      sendWorkerChatNotification(workerId, {
        id: messageId,
        conversation_id: conversationId,
        content,
        message_type: messageType,
      }).catch(() => {});
    } else {
      // Message from Worker: update unread for Admin (Admin receives no loud push, stays silent)
      await pool.query(
        `UPDATE support_conversations 
         SET last_message_text = ?, last_message_type = ?, last_message_at = NOW(), unread_admin_count = unread_admin_count + 1 
         WHERE id = ?`,
        [previewText, messageType, conversationId]
      );
    }

    const [rows] = await pool.query('SELECT * FROM support_messages WHERE id = ?', [messageId]);
    return rows[0];
  }

  /**
   * Mark messages as read
   */
  async markRead(conversationId, readerType) {
    if (readerType === 'ADMIN') {
      await pool.query(
        'UPDATE support_conversations SET unread_admin_count = 0 WHERE id = ?',
        [conversationId]
      );
      await pool.query(
        'UPDATE support_messages SET is_read = 1 WHERE conversation_id = ? AND sender_type = "WORKER"',
        [conversationId]
      );
    } else {
      await pool.query(
        'UPDATE support_conversations SET unread_worker_count = 0 WHERE id = ?',
        [conversationId]
      );
      await pool.query(
        'UPDATE support_messages SET is_read = 1 WHERE conversation_id = ? AND sender_type = "ADMIN"',
        [conversationId]
      );
    }
    return { success: true };
  }

  /**
   * Bulk Broadcast to workers
   */
  async sendBulkMessage({
    segment = 'ALL', // 'ALL' | 'NEW' | 'ACTIVE' | 'CUSTOM'
    customWorkerIds = [],
    messageType = 'TEXT',
    content = '',
    mediaUrl = null,
    youtubeId = null,
    durationSeconds = 0,
  }) {
    let targetWorkerIds = [];

    if (segment === 'CUSTOM' && Array.isArray(customWorkerIds) && customWorkerIds.length > 0) {
      targetWorkerIds = customWorkerIds;
    } else if (segment === 'NEW') {
      // Workers joined in the last 7 days
      const [rows] = await pool.query(
        `SELECT id FROM users 
         WHERE role = 'WORKER' AND created_at >= DATE_SUB(NOW(), INTERVAL 7 DAY)`
      );
      targetWorkerIds = rows.map((r) => r.id);
    } else if (segment === 'ACTIVE') {
      // Workers with at least 1 completed task or active in last 7 days
      const [rows] = await pool.query(
        `SELECT u.id 
         FROM users u
         JOIN workers w ON w.user_id = u.id
         WHERE u.role = 'WORKER' AND (w.total_tasks_completed > 0 OR w.last_active_at >= DATE_SUB(NOW(), INTERVAL 7 DAY))`
      );
      targetWorkerIds = rows.map((r) => r.id);
    } else {
      // ALL Workers
      const [rows] = await pool.query(
        `SELECT id FROM users WHERE role = 'WORKER'`
      );
      targetWorkerIds = rows.map((r) => r.id);
    }

    if (targetWorkerIds.length === 0) {
      return { success: false, message: 'No target workers found for segment ' + segment, count: 0 };
    }

    // Auto-detect YouTube ID if present
    if (messageType === 'TEXT') {
      const yt = extractYouTubeId(content);
      if (yt) {
        messageType = 'YOUTUBE';
        youtubeId = yt;
      }
    } else if (messageType === 'YOUTUBE' && !youtubeId) {
      youtubeId = extractYouTubeId(content) || extractYouTubeId(mediaUrl);
    }

    console.log(`[ChatService] Broadcasting bulk message to ${targetWorkerIds.length} workers (Segment: ${segment})...`);

    // Process in batches for high throughput
    const batchSize = 25;
    for (let i = 0; i < targetWorkerIds.length; i += batchSize) {
      const batch = targetWorkerIds.slice(i, i + batchSize);
      await Promise.all(
        batch.map(async (workerId) => {
          try {
            const conv = await this.getOrCreateConversation(workerId);
            await this.createMessage({
              conversationId: conv.id,
              workerId,
              senderType: 'ADMIN',
              messageType,
              content,
              mediaUrl,
              youtubeId,
              durationSeconds,
            });
          } catch (e) {
            console.warn(`[ChatService] Failed to send bulk message to worker ${workerId}:`, e.message);
          }
        })
      );
    }

    return {
      success: true,
      count: targetWorkerIds.length,
      segment,
    };
  }

  /**
   * Get filterable worker list with stats for Admin Sorting & Selection
   */
  async getFilterableWorkers({ search = '', segment = 'ALL', limit = 100 } = {}) {
    let query = `
      SELECT u.id, u.email, u.created_at,
             w.full_name, w.phone, w.total_tasks_completed, w.total_earnings,
             w.status, w.last_active_at,
             (CASE WHEN u.created_at >= DATE_SUB(NOW(), INTERVAL 7 DAY) THEN 1 ELSE 0 END) as is_new,
             (CASE WHEN (w.total_tasks_completed > 0 OR w.last_active_at >= DATE_SUB(NOW(), INTERVAL 7 DAY)) THEN 1 ELSE 0 END) as is_active,
             COALESCE(c.unread_admin_count, 0) as unread_chat_count
      FROM users u
      LEFT JOIN workers w ON w.user_id = u.id
      LEFT JOIN support_conversations c ON c.worker_id = u.id
      WHERE u.role = 'WORKER'
    `;
    const params = [];

    if (segment === 'NEW') {
      query += ` AND u.created_at >= DATE_SUB(NOW(), INTERVAL 7 DAY)`;
    } else if (segment === 'ACTIVE') {
      query += ` AND (w.total_tasks_completed > 0 OR w.last_active_at >= DATE_SUB(NOW(), INTERVAL 7 DAY))`;
    }

    if (search && search.trim()) {
      query += ` AND (w.full_name LIKE ? OR u.email LIKE ? OR w.phone LIKE ?)`;
      const term = `%${search.trim()}%`;
      params.push(term, term, term);
    }

    query += ` ORDER BY u.created_at DESC LIMIT ?`;
    params.push(parseInt(limit, 10));

    const [rows] = await pool.query(query, params);

    // Segment summary counts
    const [counts] = await pool.query(`
      SELECT 
        COUNT(*) as total_count,
        SUM(CASE WHEN u.created_at >= DATE_SUB(NOW(), INTERVAL 7 DAY) THEN 1 ELSE 0 END) as new_count,
        SUM(CASE WHEN (w.total_tasks_completed > 0 OR w.last_active_at >= DATE_SUB(NOW(), INTERVAL 7 DAY)) THEN 1 ELSE 0 END) as active_count
      FROM users u
      LEFT JOIN workers w ON w.user_id = u.id
      WHERE u.role = 'WORKER'
    `);

    return {
      workers: rows,
      counts: counts[0] || { total_count: 0, new_count: 0, active_count: 0 },
    };
  }

  /**
   * Delete specific messages by IDs (single or bulk)
   * Permanently removes from SQL database
   */
  async deleteMessages(messageIds = []) {
    if (!messageIds || messageIds.length === 0) {
      return { success: false, deleted: 0, affectedWorkerIds: [], affectedConvIds: [] };
    }

    const placeholders = messageIds.map(() => '?').join(',');
    
    // First get conversation_ids of messages being deleted for updating last_message
    const [msgRows] = await pool.query(
      `SELECT DISTINCT conversation_id FROM support_messages WHERE id IN (${placeholders})`,
      messageIds
    );
    const affectedConvIds = msgRows.map(r => r.conversation_id);

    // Get worker_ids of affected conversations for socket notifications
    let affectedWorkerIds = [];
    if (affectedConvIds.length > 0) {
      const convPlaceholders = affectedConvIds.map(() => '?').join(',');
      const [convRows] = await pool.query(
        `SELECT DISTINCT worker_id FROM support_conversations WHERE id IN (${convPlaceholders})`,
        affectedConvIds
      );
      affectedWorkerIds = convRows.map(r => r.worker_id);
    }

    // Delete messages from SQL
    const [result] = await pool.query(
      `DELETE FROM support_messages WHERE id IN (${placeholders})`,
      messageIds
    );

    // Update last_message for affected conversations
    for (const convId of affectedConvIds) {
      try {
        const [lastMsg] = await pool.query(
          `SELECT content, message_type, created_at FROM support_messages 
           WHERE conversation_id = ? ORDER BY created_at DESC LIMIT 1`,
          [convId]
        );
        if (lastMsg.length > 0) {
          await pool.query(
            `UPDATE support_conversations SET last_message_text = ?, last_message_type = ?, last_message_at = ? WHERE id = ?`,
            [lastMsg[0].content, lastMsg[0].message_type, lastMsg[0].created_at, convId]
          );
        } else {
          // All messages deleted, reset conversation
          await pool.query(
            `UPDATE support_conversations SET last_message_text = 'No messages', last_message_type = 'TEXT', unread_admin_count = 0, unread_worker_count = 0 WHERE id = ?`,
            [convId]
          );
        }
      } catch (e) {
        console.warn(`[ChatService] Failed to update last_message for conv ${convId}:`, e.message);
      }
    }

    console.log(`[ChatService] Deleted ${result.affectedRows} messages (IDs: ${messageIds.join(', ')})`);
    return { success: true, deleted: result.affectedRows, affectedWorkerIds, affectedConvIds };
  }

  /**
   * Delete ALL messages in a conversation
   */
  async deleteAllConversationMessages(conversationId) {
    if (!conversationId) {
      return { success: false, deleted: 0, workerId: null };
    }

    const [convRows] = await pool.query(
      `SELECT worker_id FROM support_conversations WHERE id = ?`,
      [conversationId]
    );
    const workerId = convRows.length > 0 ? convRows[0].worker_id : null;

    const [result] = await pool.query(
      `DELETE FROM support_messages WHERE conversation_id = ?`,
      [conversationId]
    );

    // Reset conversation metadata
    await pool.query(
      `UPDATE support_conversations SET last_message_text = 'No messages', last_message_type = 'TEXT', unread_admin_count = 0, unread_worker_count = 0 WHERE id = ?`,
      [conversationId]
    );

    console.log(`[ChatService] Deleted ALL ${result.affectedRows} messages from conversation ${conversationId}`);
    return { success: true, deleted: result.affectedRows, workerId };
  }

  /**
   * Delete multiple conversations and their messages (bulk delete from chat list)
   */
  async deleteConversationsBulk(conversationIds = []) {
    if (!conversationIds || !Array.isArray(conversationIds) || conversationIds.length === 0) {
      return { success: false, deletedConversations: 0, deletedMessages: 0, affectedWorkerIds: [] };
    }

    const placeholders = conversationIds.map(() => '?').join(',');

    // 1. Get worker_ids of conversations for socket notifications
    const [convRows] = await pool.query(
      `SELECT id, worker_id FROM support_conversations WHERE id IN (${placeholders})`,
      conversationIds
    );
    const affectedWorkerIds = convRows.map((r) => r.worker_id);

    // 2. Delete all messages of these conversations
    const [msgResult] = await pool.query(
      `DELETE FROM support_messages WHERE conversation_id IN (${placeholders})`,
      conversationIds
    );

    // 3. Delete the conversations themselves
    const [convResult] = await pool.query(
      `DELETE FROM support_conversations WHERE id IN (${placeholders})`,
      conversationIds
    );

    console.log(`[ChatService] Bulk deleted ${convResult.affectedRows} conversations and ${msgResult.affectedRows} messages`);
    return {
      success: true,
      deletedConversations: convResult.affectedRows,
      deletedMessages: msgResult.affectedRows,
      affectedWorkerIds,
      conversationIds,
    };
  }

  /**
   * Delete ALL messages & conversations for ALL workers (complete wipe of support chats)
   */
  async deleteAllWorkersChats() {
    // 1. Delete all messages
    const [msgResult] = await pool.query(`DELETE FROM support_messages`);

    // 2. Delete all conversations
    const [convResult] = await pool.query(`DELETE FROM support_conversations`);

    console.log(`[ChatService] Deleted ALL chats for ALL workers: ${convResult.affectedRows} conversations, ${msgResult.affectedRows} messages`);
    return {
      success: true,
      deletedConversations: convResult.affectedRows,
      deletedMessages: msgResult.affectedRows,
    };
  }
}

module.exports = new ChatService();

