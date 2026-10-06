const { pool } = require('../config/db');
const { v4: uuidv4 } = require('uuid');
const { sendBuyerChatNotification } = require('../services/fcm.service');

// Helper to extract YouTube video ID from URL
function extractYouTubeId(url) {
  if (!url) return null;
  const match = url.match(/(?:youtu\.be\/|youtube\.com\/(?:embed\/|v\/|watch\?v=|watch\?.+&v=))([\w-]{11})/);
  return match ? match[1] : null;
}

class BuyerChatService {
  /**
   * Ensure buyer support tables exist in MySQL
   */
  async initTables() {
    const connection = await pool.getConnection();
    try {
      // 1. buyer_support_conversations
      await connection.query(`
        CREATE TABLE IF NOT EXISTS buyer_support_conversations (
          id VARCHAR(36) PRIMARY KEY,
          buyer_id VARCHAR(255) NOT NULL UNIQUE,
          buyer_name VARCHAR(255) NULL,
          buyer_phone VARCHAR(50) NULL,
          buyer_email VARCHAR(255) NULL,
          buyer_avatar_url VARCHAR(500) NULL,
          fcm_token VARCHAR(500) NULL,
          last_message_text TEXT NULL,
          last_message_type VARCHAR(20) DEFAULT 'TEXT',
          last_message_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
          unread_admin_count INT NOT NULL DEFAULT 0,
          unread_buyer_count INT NOT NULL DEFAULT 0,
          created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
          updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
          INDEX idx_buyer_conv (buyer_id),
          INDEX idx_buyer_last_msg (last_message_at DESC)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
      `);

      // Add fcm_token column if existing table lacks it
      try {
        await connection.query(`ALTER TABLE buyer_support_conversations ADD COLUMN fcm_token VARCHAR(500) NULL;`);
      } catch (_) {}

      // 2. buyer_support_messages
      await connection.query(`
        CREATE TABLE IF NOT EXISTS buyer_support_messages (
          id VARCHAR(36) PRIMARY KEY,
          conversation_id VARCHAR(36) NOT NULL,
          buyer_id VARCHAR(255) NOT NULL,
          sender_type ENUM('BUYER', 'ADMIN') NOT NULL,
          message_type ENUM('TEXT', 'IMAGE', 'AUDIO', 'YOUTUBE') NOT NULL DEFAULT 'TEXT',
          content TEXT NOT NULL,
          media_url TEXT NULL,
          youtube_id VARCHAR(100) NULL,
          duration_seconds INT NOT NULL DEFAULT 0,
          is_read TINYINT(1) NOT NULL DEFAULT 0,
          created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
          INDEX idx_buyer_msg_conv (conversation_id),
          INDEX idx_buyer_msg_user (buyer_id),
          INDEX idx_buyer_msg_created (created_at ASC)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
      `);

      console.log('[BuyerChatService] Buyer support tables verified successfully.');
    } catch (err) {
      console.error('[BuyerChatService] Error verifying tables:', err);
    } finally {
      connection.release();
    }
  }

  /**
   * Get or create conversation for a Buyer
   */
  async getOrCreateConversation(buyerId, buyerDetails = {}) {
    // Lookup user & buyer info from DB
    const [userRows] = await pool.query(
      `SELECT u.id, u.email, u.full_name as user_full_name, u.avatar_url, u.phone as user_phone
       FROM users u 
       WHERE u.id = ? OR u.email = ? LIMIT 1`,
      [buyerId, buyerDetails.email || '']
    );

    const userInfo = userRows[0] || {};
    const avatar = buyerDetails.avatarUrl || buyerDetails.photoUrl || userInfo.avatar_url || '';
    const resolvedName = buyerDetails.name || userInfo.user_full_name || userInfo.email?.split('@')[0] || 'Buyer';
    const email = buyerDetails.email || userInfo.email || '';
    const phone = buyerDetails.phone || userInfo.user_phone || '';

    const [existing] = await pool.query(
      'SELECT * FROM buyer_support_conversations WHERE buyer_id = ? LIMIT 1',
      [buyerId]
    );

    if (existing.length > 0) {
      let needsUpdate = false;
      const updates = [];
      const updateParams = [];

      if (avatar && (!existing[0].buyer_avatar_url || existing[0].buyer_avatar_url === '')) {
        updates.push('buyer_avatar_url = ?');
        updateParams.push(avatar);
        existing[0].buyer_avatar_url = avatar;
        needsUpdate = true;
      }

      if (resolvedName && resolvedName !== 'Buyer' && (existing[0].buyer_name === 'Buyer' || !existing[0].buyer_name)) {
        updates.push('buyer_name = ?');
        updateParams.push(resolvedName);
        existing[0].buyer_name = resolvedName;
        needsUpdate = true;
      }

      if (email && (!existing[0].buyer_email || existing[0].buyer_email === '')) {
        updates.push('buyer_email = ?');
        updateParams.push(email);
        existing[0].buyer_email = email;
        needsUpdate = true;
      }

      if (phone && (!existing[0].buyer_phone || existing[0].buyer_phone === '')) {
        updates.push('buyer_phone = ?');
        updateParams.push(phone);
        existing[0].buyer_phone = phone;
        needsUpdate = true;
      }

      if (needsUpdate) {
        updateParams.push(existing[0].id);
        await pool.query(`UPDATE buyer_support_conversations SET ${updates.join(', ')} WHERE id = ?`, updateParams);
      }
      return existing[0];
    }

    const newId = uuidv4();
    await pool.query(
      `INSERT INTO buyer_support_conversations 
       (id, buyer_id, buyer_name, buyer_phone, buyer_email, buyer_avatar_url, last_message_text, last_message_type, last_message_at, unread_admin_count, unread_buyer_count)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, NOW(), 0, 0)`,
      [newId, buyerId, resolvedName, phone, email, avatar, 'No messages yet', 'TEXT']
    );

    const [created] = await pool.query('SELECT * FROM buyer_support_conversations WHERE id = ?', [newId]);
    return created[0];
  }

  /**
   * Get conversations for Admin (Buyer-Only list)
   */
  async getConversations({ search = '', limit = 100, offset = 0 } = {}) {
    // 1. Auto-sync registered buyers from users table so Admin sees all registered buyers
    try {
      const [registeredBuyers] = await pool.query(`
        SELECT u.id, u.email, u.full_name, u.avatar_url, u.phone, u.created_at
        FROM users u
        WHERE u.role = 'BUYER' OR u.id IN (SELECT DISTINCT buyer_id FROM orders WHERE buyer_id IS NOT NULL)
      `);

      for (const b of registeredBuyers) {
        const [exists] = await pool.query(
          'SELECT id FROM buyer_support_conversations WHERE buyer_id = ? LIMIT 1',
          [b.id]
        );
        if (exists.length === 0) {
          const newId = uuidv4();
          const bName = b.full_name || b.email?.split('@')[0] || 'Buyer';
          await pool.query(
            `INSERT INTO buyer_support_conversations 
             (id, buyer_id, buyer_name, buyer_phone, buyer_email, buyer_avatar_url, last_message_text, last_message_type, last_message_at, unread_admin_count, unread_buyer_count, created_at)
             VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, 0, 0, ?)`,
            [newId, b.id, bName, b.phone || '', b.email || '', b.avatar_url || '', 'No messages yet', 'TEXT', b.created_at || new Date(), b.created_at || new Date()]
          );
        }
      }
    } catch (syncErr) {
      console.error('[BuyerChatService] Error auto-syncing buyers:', syncErr.message);
    }

    // 2. Fetch conversations
    let query = `
      SELECT c.*,
             COALESCE(NULLIF(NULLIF(c.buyer_name, 'Buyer'), ''), u.full_name, u.email, 'Buyer') as buyer_name,
             COALESCE(NULLIF(c.buyer_email, ''), u.email, '') as buyer_email,
             COALESCE(NULLIF(c.buyer_phone, ''), u.phone, '') as buyer_phone,
             COALESCE(NULLIF(c.buyer_avatar_url, ''), u.avatar_url) as buyer_avatar_url
      FROM buyer_support_conversations c
      LEFT JOIN users u ON u.id = c.buyer_id
    `;
    const params = [];

    if (search && search.trim()) {
      query += ` WHERE (c.buyer_name LIKE ? OR c.buyer_email LIKE ? OR c.buyer_phone LIKE ? OR c.buyer_id LIKE ? OR u.full_name LIKE ? OR u.email LIKE ?)`;
      const term = `%${search.trim()}%`;
      params.push(term, term, term, term, term, term);
    }

    query += ` ORDER BY c.last_message_at DESC, c.created_at DESC LIMIT ? OFFSET ?`;
    params.push(Number(limit) || 100, Number(offset) || 0);

    const [rows] = await pool.query(query, params);
    return rows;
  }

  /**
   * Get message history for a conversation
   */
  async getMessages(conversationId, { limit = 100, offset = 0 } = {}) {
    const [rows] = await pool.query(
      `SELECT * FROM buyer_support_messages 
       WHERE conversation_id = ? 
       ORDER BY created_at ASC 
       LIMIT ? OFFSET ?`,
      [conversationId, Number(limit) || 100, Number(offset) || 0]
    );
    return rows;
  }

  /**
   * Create a new message (from ADMIN or BUYER)
   */
  async createMessage({
    conversationId,
    buyerId,
    senderType,
    messageType = 'TEXT',
    content = '',
    mediaUrl = null,
    youtubeId = null,
    durationSeconds = 0,
  }) {
    let convId = conversationId;
    if (!convId && buyerId) {
      const conv = await this.getOrCreateConversation(buyerId);
      convId = conv.id;
    }

    const messageId = uuidv4();
    const finalYoutubeId = youtubeId || extractYouTubeId(content);

    await pool.query(
      `INSERT INTO buyer_support_messages 
       (id, conversation_id, buyer_id, sender_type, message_type, content, media_url, youtube_id, duration_seconds, is_read, created_at)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, 0, NOW())`,
      [
        messageId,
        convId,
        buyerId,
        senderType,
        messageType,
        content,
        mediaUrl,
        finalYoutubeId,
        durationSeconds || 0,
      ]
    );

    // Update conversation metadata & unread counters
    let previewText = content;
    if (messageType === 'AUDIO') previewText = '🎤 Voice message';
    else if (messageType === 'IMAGE') previewText = '📷 Photo';
    else if (messageType === 'YOUTUBE' || finalYoutubeId) previewText = '▶️ YouTube Video';

    if (senderType === 'BUYER') {
      await pool.query(
        `UPDATE buyer_support_conversations 
         SET last_message_text = ?, 
             last_message_type = ?, 
             last_message_at = NOW(), 
             unread_admin_count = unread_admin_count + 1 
         WHERE id = ?`,
        [previewText, messageType, convId]
      );
    } else {
      // Sent by ADMIN -> increment unread for Buyer
      await pool.query(
        `UPDATE buyer_support_conversations 
         SET last_message_text = ?, 
             last_message_type = ?, 
             last_message_at = NOW(), 
             unread_buyer_count = unread_buyer_count + 1 
         WHERE id = ?`,
        [previewText, messageType, convId]
      );
    }

    const [rows] = await pool.query('SELECT * FROM buyer_support_messages WHERE id = ?', [messageId]);
    const messageRecord = rows[0];

    // Trigger FCM notification if message was sent by ADMIN to BUYER
    if (senderType === 'ADMIN' && messageRecord) {
      sendBuyerChatNotification(buyerId, messageRecord).catch((err) => {
        console.warn('[BuyerChatService] FCM dispatch error:', err.message);
      });
    }

    return messageRecord;
  }

  /**
   * Update Buyer's FCM token for push notifications
   */
  async updateFcmToken(buyerId, fcmToken) {
    if (!buyerId || !fcmToken) return false;
    try {
      await this.getOrCreateConversation(buyerId);
      await pool.query(
        `UPDATE buyer_support_conversations SET fcm_token = ? WHERE buyer_id = ?`,
        [fcmToken, buyerId]
      );
      return true;
    } catch (e) {
      console.warn('[BuyerChatService] updateFcmToken error:', e.message);
      return false;
    }
  }

  /**
   * Get total unread message count for a buyer
   */
  async getBuyerUnreadCount(buyerId) {
    if (!buyerId) return 0;
    try {
      const [rows] = await pool.query(
        `SELECT unread_buyer_count FROM buyer_support_conversations WHERE buyer_id = ? LIMIT 1`,
        [buyerId]
      );
      if (rows && rows.length > 0) {
        return Number(rows[0].unread_buyer_count) || 0;
      }
    } catch (e) {
      console.warn('[BuyerChatService] getBuyerUnreadCount error:', e.message);
    }
    return 0;
  }

  /**
   * Mark messages as read
   */
  async markRead(conversationId, readerType = 'ADMIN') {
    if (readerType === 'ADMIN') {
      await pool.query(
        `UPDATE buyer_support_messages 
         SET is_read = 1 
         WHERE conversation_id = ? AND sender_type = 'BUYER' AND is_read = 0`,
        [conversationId]
      );
      await pool.query(
        `UPDATE buyer_support_conversations 
         SET unread_admin_count = 0 
         WHERE id = ?`,
        [conversationId]
      );
    } else {
      // Buyer read admin messages
      await pool.query(
        `UPDATE buyer_support_messages 
         SET is_read = 1 
         WHERE conversation_id = ? AND sender_type = 'ADMIN' AND is_read = 0`,
        [conversationId]
      );
      await pool.query(
        `UPDATE buyer_support_conversations 
         SET unread_buyer_count = 0 
         WHERE id = ?`,
        [conversationId]
      );
    }
  }

  /**
   * Delete messages by IDs and refresh conversation preview
   */
  async deleteMessages(messageIds, conversationId = null) {
    if (!messageIds || !Array.isArray(messageIds) || messageIds.length === 0) {
      return { success: false, count: 0, affectedBuyerIds: [], affectedConvIds: [] };
    }

    // 1. Find conversation_id & buyer_id for affected messages
    const [msgRows] = await pool.query(
      `SELECT conversation_id, buyer_id FROM buyer_support_messages WHERE id IN (?)`,
      [messageIds]
    );

    const affectedConvIds = new Set();
    const affectedBuyerIds = new Set();
    msgRows.forEach((r) => {
      if (r.conversation_id) affectedConvIds.add(r.conversation_id);
      if (r.buyer_id) affectedBuyerIds.add(r.buyer_id);
    });
    if (conversationId) affectedConvIds.add(conversationId);

    // 2. Delete messages
    const [res] = await pool.query(
      `DELETE FROM buyer_support_messages WHERE id IN (?)`,
      [messageIds]
    );

    // 3. Update preview for affected conversations
    for (const convId of affectedConvIds) {
      try {
        const [lastMsg] = await pool.query(
          `SELECT content, message_type, created_at FROM buyer_support_messages 
           WHERE conversation_id = ? ORDER BY created_at DESC LIMIT 1`,
          [convId]
        );
        if (lastMsg.length > 0) {
          await pool.query(
            `UPDATE buyer_support_conversations 
             SET last_message_text = ?, last_message_type = ?, last_message_at = ? 
             WHERE id = ?`,
            [lastMsg[0].content, lastMsg[0].message_type, lastMsg[0].created_at, convId]
          );
        } else {
          await pool.query(
            `UPDATE buyer_support_conversations 
             SET last_message_text = 'No messages', last_message_type = 'TEXT', unread_admin_count = 0, unread_buyer_count = 0 
             WHERE id = ?`,
            [convId]
          );
        }
      } catch (e) {
        console.warn(`[BuyerChatService] Failed to update preview for conv ${convId}:`, e.message);
      }
    }

    return {
      success: true,
      count: res.affectedRows,
      affectedBuyerIds: Array.from(affectedBuyerIds),
      affectedConvIds: Array.from(affectedConvIds),
    };
  }

  /**
   * Delete all messages for a specific buyer conversation
   */
  async deleteAllConversationMessages(conversationId) {
    if (!conversationId) return { success: false, count: 0, buyerId: null };

    const [convRows] = await pool.query(
      `SELECT buyer_id FROM buyer_support_conversations WHERE id = ?`,
      [conversationId]
    );
    const buyerId = convRows.length > 0 ? convRows[0].buyer_id : null;

    const [res] = await pool.query(
      `DELETE FROM buyer_support_messages WHERE conversation_id = ?`,
      [conversationId]
    );

    await pool.query(
      `UPDATE buyer_support_conversations 
       SET last_message_text = 'No messages', 
           last_message_type = 'TEXT',
           unread_admin_count = 0, 
           unread_buyer_count = 0 
       WHERE id = ?`,
      [conversationId]
    );

    return { success: true, count: res.affectedRows, buyerId };
  }

  /**
   * Delete entire buyer conversations and their messages
   */
  async deleteConversations(conversationIds = []) {
    if (!conversationIds || !Array.isArray(conversationIds) || conversationIds.length === 0) {
      return { success: false, deletedConversations: 0, deletedMessages: 0, affectedBuyerIds: [] };
    }

    // 1. Get buyer_ids for sockets
    const [convRows] = await pool.query(
      `SELECT id, buyer_id FROM buyer_support_conversations WHERE id IN (?)`,
      [conversationIds]
    );
    const affectedBuyerIds = convRows.map((r) => r.buyer_id).filter(Boolean);

    // 2. Delete all messages of these conversations
    const [msgRes] = await pool.query(
      `DELETE FROM buyer_support_messages WHERE conversation_id IN (?)`,
      [conversationIds]
    );

    // 3. Delete conversations
    const [convRes] = await pool.query(
      `DELETE FROM buyer_support_conversations WHERE id IN (?)`,
      [conversationIds]
    );

    return {
      success: true,
      deletedConversations: convRes.affectedRows,
      deletedMessages: msgRes.affectedRows,
      affectedBuyerIds,
    };
  }
}

module.exports = new BuyerChatService();
