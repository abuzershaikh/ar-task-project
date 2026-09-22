const chatService = require('../services/chat.service');

class ChatController {
  async getConversations(req, res) {
    try {
      const { search, limit, offset } = req.query;
      const data = await chatService.getConversations({ search, limit, offset });
      return res.json({ success: true, data });
    } catch (err) {
      console.error('[ChatController] getConversations error:', err);
      return res.status(500).json({ success: false, error: err.message });
    }
  }

  async getMessages(req, res) {
    try {
      const { conversationId } = req.params;
      const { limit, offset } = req.query;
      const messages = await chatService.getMessages(conversationId, { limit, offset });
      return res.json({ success: true, data: messages });
    } catch (err) {
      console.error('[ChatController] getMessages error:', err);
      return res.status(500).json({ success: false, error: err.message });
    }
  }

  async getWorkerChat(req, res) {
    try {
      const { workerId } = req.params;
      const { limit, offset } = req.query;
      const data = await chatService.getMessagesByWorkerId(workerId, { limit, offset });
      return res.json({ success: true, data });
    } catch (err) {
      console.error('[ChatController] getWorkerChat error:', err);
      return res.status(500).json({ success: false, error: err.message });
    }
  }

  async sendMessage(req, res) {
    try {
      const {
        conversationId,
        workerId,
        senderType, // 'WORKER' | 'ADMIN'
        messageType, // 'TEXT' | 'IMAGE' | 'AUDIO' | 'YOUTUBE'
        content,
        mediaUrl,
        youtubeId,
        durationSeconds,
      } = req.body;

      if (!senderType || (!content && !mediaUrl && !youtubeId)) {
        return res.status(400).json({ success: false, error: 'Missing required parameters' });
      }

      // Security check: Worker can ONLY send TEXT messages
      if (senderType === 'WORKER' && messageType && messageType !== 'TEXT') {
        return res.status(403).json({ success: false, error: 'Workers are restricted to text messages only' });
      }

      const message = await chatService.createMessage({
        conversationId,
        workerId,
        senderType,
        messageType: senderType === 'WORKER' ? 'TEXT' : (messageType || 'TEXT'),
        content: content || '',
        mediaUrl,
        youtubeId,
        durationSeconds: durationSeconds ? parseInt(durationSeconds, 10) : 0,
      });

      // Real-time Socket.IO dispatch to worker and admin rooms
      const io = req.app.get('io');
      if (io) {
        const targetWorkerId = workerId || message.worker_id;
        if (targetWorkerId) {
          io.to(`worker_${targetWorkerId}`).emit('new_message', message);
        }
        io.to('admin_support').emit('new_message', message);
        chatService.getOrCreateConversation(targetWorkerId).then(conv => {
          io.to('admin_support').emit('conversation_updated', conv);
        }).catch(() => {});
      }

      return res.status(201).json({ success: true, data: message });
    } catch (err) {
      console.error('[ChatController] sendMessage error:', err);
      return res.status(500).json({ success: false, error: err.message });
    }
  }

  async sendBulkMessage(req, res) {
    try {
      const {
        segment, // 'ALL' | 'NEW' | 'ACTIVE' | 'CUSTOM'
        customWorkerIds,
        messageType,
        content,
        mediaUrl,
        youtubeId,
        durationSeconds,
      } = req.body;

      if (!content && !mediaUrl && !youtubeId) {
        return res.status(400).json({ success: false, error: 'Message content or media required' });
      }

      const result = await chatService.sendBulkMessage({
        segment: segment || 'ALL',
        customWorkerIds: customWorkerIds || [],
        messageType: messageType || 'TEXT',
        content: content || '',
        mediaUrl,
        youtubeId,
        durationSeconds: durationSeconds ? parseInt(durationSeconds, 10) : 0,
      });

      // Real-time Socket.IO dispatch for each targeted worker
      const io = req.app.get('io');
      if (io && result && result.messages) {
        for (const msg of result.messages) {
          if (msg.worker_id) {
            io.to(`worker_${msg.worker_id}`).emit('new_message', msg);
          }
        }
        io.to('admin_support').emit('bulk_messages_sent', result);
      }

      return res.json({ success: true, data: result });
    } catch (err) {
      console.error('[ChatController] sendBulkMessage error:', err);
      return res.status(500).json({ success: false, error: err.message });
    }
  }

  async markRead(req, res) {
    try {
      const { conversationId } = req.params;
      const { readerType } = req.body; // 'ADMIN' | 'WORKER'
      const result = await chatService.markRead(conversationId, readerType || 'ADMIN');
      return res.json({ success: true, data: result });
    } catch (err) {
      console.error('[ChatController] markRead error:', err);
      return res.status(500).json({ success: false, error: err.message });
    }
  }

  async getFilterableWorkers(req, res) {
    try {
      const { search, segment, limit } = req.query;
      const data = await chatService.getFilterableWorkers({ search, segment, limit });
      return res.json({ success: true, data });
    } catch (err) {
      console.error('[ChatController] getFilterableWorkers error:', err);
      return res.status(500).json({ success: false, error: err.message });
    }
  }

  async uploadMedia(req, res) {
    try {
      if (!req.file) {
        return res.status(400).json({ success: false, error: 'No file uploaded' });
      }

      // 1. Forward directly to Cloudflare Chat Media Worker
      try {
        const fs = require('fs');
        const fileData = fs.readFileSync(req.file.path);
        const blob = new Blob([fileData], { type: req.file.mimetype });
        const formData = new FormData();
        formData.append('file', blob, req.file.originalname || req.file.filename);

        const cfRes = await fetch('https://earnpost-chat-media-worker.zestbizar.workers.dev/upload', {
          method: 'POST',
          body: formData,
        });

        if (cfRes.ok) {
          const cfData = await cfRes.json();
          if (cfData.success && (cfData.url || cfData.publicUrl)) {
            const cfUrl = cfData.url || cfData.publicUrl;
            // Clean up local temp file
            try { fs.unlinkSync(req.file.path); } catch (_) {}
            return res.json({
              success: true,
              data: {
                filename: cfData.filename || req.file.filename,
                mimetype: req.file.mimetype,
                size: req.file.size,
                url: cfUrl,
                storage: 'Cloudflare R2',
              },
            });
          }
        }
      } catch (cfErr) {
        console.warn('[ChatController] Cloudflare upload forward failed, using local storage:', cfErr.message);
      }

      // 2. Fallback to public VPS URL
      const fileUrl = `https://reviewsgateway.in/support-chat/uploads/${req.file.filename}`;

      return res.json({
        success: true,
        data: {
          filename: req.file.filename,
          originalName: req.file.originalname,
          mimetype: req.file.mimetype,
          size: req.file.size,
          url: fileUrl,
          storage: 'VPS Local',
        },
      });
    } catch (err) {
      console.error('[ChatController] uploadMedia error:', err);
      return res.status(500).json({ success: false, error: err.message });
    }
  }
  /**
   * Delete specific messages by IDs (single or bulk)
   * POST /api/support/messages/delete
   * Body: { messageIds: ['id1', 'id2', ...] }
   */
  async deleteMessages(req, res) {
    try {
      const { messageIds } = req.body;
      if (!messageIds || !Array.isArray(messageIds) || messageIds.length === 0) {
        return res.status(400).json({ success: false, error: 'messageIds array is required' });
      }
      const result = await chatService.deleteMessages(messageIds);

      // Real-time broadcast to Admin and Worker rooms
      const io = req.app.get('io');
      if (io) {
        io.to('admin_support').emit('messages_deleted', { messageIds });
        if (result.affectedWorkerIds && Array.isArray(result.affectedWorkerIds)) {
          result.affectedWorkerIds.forEach((wId) => {
            io.to(`worker_${wId}`).emit('messages_deleted', { messageIds });
          });
        }
      }

      return res.json({ success: true, data: result });
    } catch (err) {
      console.error('[ChatController] deleteMessages error:', err);
      return res.status(500).json({ success: false, error: err.message });
    }
  }

  /**
   * Delete ALL messages in a conversation
   * DELETE /api/support/conversations/:conversationId/messages
   */
  async deleteAllConversationMessages(req, res) {
    try {
      const { conversationId } = req.params;
      if (!conversationId) {
        return res.status(400).json({ success: false, error: 'conversationId is required' });
      }
      const result = await chatService.deleteAllConversationMessages(conversationId);

      // Real-time broadcast to Admin and Worker rooms
      const io = req.app.get('io');
      if (io) {
        io.to('admin_support').emit('all_messages_deleted', { conversationId });
        if (result.workerId) {
          io.to(`worker_${result.workerId}`).emit('all_messages_deleted', { conversationId });
        }
      }

      return res.json({ success: true, data: result });
    } catch (err) {
      console.error('[ChatController] deleteAllConversationMessages error:', err);
      return res.status(500).json({ success: false, error: err.message });
    }
  }

  /**
   * Delete multiple conversations & their messages (bulk delete from chat list)
   * POST /api/support/conversations/delete-bulk
   * Body: { conversationIds: ['id1', 'id2', ...] }
   */
  async deleteConversationsBulk(req, res) {
    try {
      const { conversationIds } = req.body;
      if (!conversationIds || !Array.isArray(conversationIds) || conversationIds.length === 0) {
        return res.status(400).json({ success: false, error: 'conversationIds array is required' });
      }
      const result = await chatService.deleteConversationsBulk(conversationIds);

      // Real-time broadcast to Admin and Worker rooms
      const io = req.app.get('io');
      if (io) {
        io.to('admin_support').emit('conversations_deleted', { conversationIds });
        if (result.affectedWorkerIds && Array.isArray(result.affectedWorkerIds)) {
          result.affectedWorkerIds.forEach((wId) => {
            io.to(`worker_${wId}`).emit('all_messages_deleted', { all: true });
          });
        }
      }

      return res.json({ success: true, data: result });
    } catch (err) {
      console.error('[ChatController] deleteConversationsBulk error:', err);
      return res.status(500).json({ success: false, error: err.message });
    }
  }

  /**
   * Delete ALL messages & conversations for ALL workers (complete wipe)
   * POST /api/support/conversations/delete-all
   */
  async deleteAllWorkersChats(req, res) {
    try {
      const result = await chatService.deleteAllWorkersChats();

      // Real-time broadcast to all connected admins & workers
      const io = req.app.get('io');
      if (io) {
        io.to('admin_support').emit('all_conversations_deleted', {});
        io.emit('all_messages_deleted', { all: true });
      }

      return res.json({ success: true, data: result });
    } catch (err) {
      console.error('[ChatController] deleteAllWorkersChats error:', err);
      return res.status(500).json({ success: false, error: err.message });
    }
  }
}

module.exports = new ChatController();

