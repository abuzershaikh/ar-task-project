const buyerChatService = require('./buyer-chat.service');

class BuyerChatController {
  /**
   * GET /api/support/buyer/conversations
   * Admin fetches all buyer support conversations
   */
  async getConversations(req, res) {
    try {
      const { search = '', limit = 100, offset = 0 } = req.query;
      const conversations = await buyerChatService.getConversations({
        search,
        limit: Number(limit) || 100,
        offset: Number(offset) || 0,
      });
      res.json({ success: true, data: conversations });
    } catch (err) {
      console.error('[BuyerChatController] getConversations error:', err);
      res.status(500).json({ success: false, error: err.message });
    }
  }

  /**
   * GET /api/support/buyer/conversations/:conversationId/messages
   */
  async getMessages(req, res) {
    try {
      const { conversationId } = req.params;
      const { limit = 100, offset = 0 } = req.query;
      const messages = await buyerChatService.getMessages(conversationId, {
        limit: Number(limit) || 100,
        offset: Number(offset) || 0,
      });
      res.json({ success: true, data: messages });
    } catch (err) {
      console.error('[BuyerChatController] getMessages error:', err);
      res.status(500).json({ success: false, error: err.message });
    }
  }

  /**
   * GET /api/support/buyer/:buyerId
   * Buyer fetches or initializes their conversation & recent messages
   */
  async getBuyerChat(req, res) {
    try {
      const { buyerId } = req.params;
      const { name, email, phone, avatarUrl, photoUrl } = req.query;

      const conversation = await buyerChatService.getOrCreateConversation(buyerId, {
        name,
        email,
        phone,
        avatarUrl: avatarUrl || photoUrl,
      });

      const messages = await buyerChatService.getMessages(conversation.id, { limit: 100 });

      res.json({
        success: true,
        data: {
          conversation,
          messages,
        },
      });
    } catch (err) {
      console.error('[BuyerChatController] getBuyerChat error:', err);
      res.status(500).json({ success: false, error: err.message });
    }
  }

  /**
   * POST /api/support/buyer/messages/send
   * REST message send fallback
   */
  async sendMessage(req, res) {
    try {
      const {
        conversationId,
        buyerId,
        senderType,
        messageType = 'TEXT',
        content = '',
        mediaUrl = null,
        youtubeId = null,
        durationSeconds = 0,
      } = req.body;

      if (!buyerId || !senderType) {
        return res.status(400).json({ success: false, error: 'buyerId and senderType are required' });
      }

      const message = await buyerChatService.createMessage({
        conversationId,
        buyerId,
        senderType,
        messageType,
        content,
        mediaUrl,
        youtubeId,
        durationSeconds,
      });

      // Emit socket events
      const io = req.app.get('io');
      if (io) {
        // Emit to buyer
        io.to(`buyer_${buyerId}`).emit('new_buyer_message', message);
        // Emit to admin support
        io.to('admin_buyer_support').emit('new_buyer_message', message);
        io.to('admin_support').emit('new_buyer_message', message);

        const updatedConv = await buyerChatService.getOrCreateConversation(buyerId);
        io.to('admin_buyer_support').emit('buyer_conversation_updated', updatedConv);
      }

      res.json({ success: true, data: message });
    } catch (err) {
      console.error('[BuyerChatController] sendMessage error:', err);
      res.status(500).json({ success: false, error: err.message });
    }
  }

  /**
   * POST /api/support/buyer/conversations/:conversationId/read
   */
  async markRead(req, res) {
    try {
      const { conversationId } = req.params;
      const { readerType = 'ADMIN', buyerId } = req.body;

      await buyerChatService.markRead(conversationId, readerType);

      const io = req.app.get('io');
      if (io) {
        if (readerType === 'ADMIN' && buyerId) {
          io.to(`buyer_${buyerId}`).emit('buyer_messages_read', { conversationId });
        } else if (readerType === 'BUYER') {
          io.to('admin_buyer_support').emit('buyer_messages_read', { conversationId, buyerId });
        }
      }

      res.json({ success: true, message: 'Messages marked as read' });
    } catch (err) {
      console.error('[BuyerChatController] markRead error:', err);
      res.status(500).json({ success: false, error: err.message });
    }
  }

  /**
   * POST /api/support/buyer/messages/delete
   */
  async deleteMessages(req, res) {
    try {
      const { messageIds, conversationId } = req.body;
      const result = await buyerChatService.deleteMessages(messageIds, conversationId);

      const io = req.app.get('io');
      if (io) {
        // Broadcast to admin room (both event names for compatibility)
        io.to('admin_buyer_support').emit('messages_deleted', { messageIds });
        io.to('admin_buyer_support').emit('buyer_messages_deleted', { messageIds });
        io.to('admin_support').emit('messages_deleted', { messageIds });

        // Broadcast to affected buyer socket rooms so buyer UI deletes the message immediately
        if (result.affectedBuyerIds && result.affectedBuyerIds.length > 0) {
          result.affectedBuyerIds.forEach((bId) => {
            io.to(`buyer_${bId}`).emit('messages_deleted', { messageIds });
            io.to(`buyer_${bId}`).emit('buyer_messages_deleted', { messageIds });
          });
        }
      }

      res.json({ success: true, count: result.count });
    } catch (err) {
      console.error('[BuyerChatController] deleteMessages error:', err);
      res.status(500).json({ success: false, error: err.message });
    }
  }

  /**
   * DELETE /api/support/buyer/conversations/:conversationId/messages
   */
  async deleteAllConversationMessages(req, res) {
    try {
      const { conversationId } = req.params;
      const result = await buyerChatService.deleteAllConversationMessages(conversationId);

      const io = req.app.get('io');
      if (io) {
        io.to('admin_buyer_support').emit('all_messages_deleted', { conversationId });
        io.to('admin_buyer_support').emit('buyer_all_messages_deleted', { conversationId });
        io.to('admin_support').emit('all_messages_deleted', { conversationId });

        if (result.buyerId) {
          io.to(`buyer_${result.buyerId}`).emit('all_messages_deleted', { conversationId });
          io.to(`buyer_${result.buyerId}`).emit('buyer_all_messages_deleted', { conversationId });
        }
      }

      res.json({ success: true, count: result.count });
    } catch (err) {
      console.error('[BuyerChatController] deleteAllConversationMessages error:', err);
      res.status(500).json({ success: false, error: err.message });
    }
  }

  /**
   * POST /api/support/buyer/conversations/delete
   * Bulk delete buyer conversations
   */
  async deleteConversations(req, res) {
    try {
      const { conversationIds } = req.body;
      const result = await buyerChatService.deleteConversations(conversationIds);

      const io = req.app.get('io');
      if (io) {
        io.to('admin_buyer_support').emit('conversations_deleted', { conversationIds });
        io.to('admin_buyer_support').emit('buyer_conversations_deleted', { conversationIds });
        io.to('admin_support').emit('conversations_deleted', { conversationIds });

        if (result.affectedBuyerIds && result.affectedBuyerIds.length > 0) {
          result.affectedBuyerIds.forEach((bId) => {
            io.to(`buyer_${bId}`).emit('all_messages_deleted', { all: true });
          });
        }
      }

      res.json({
        success: true,
        deletedConversations: result.deletedConversations,
        deletedMessages: result.deletedMessages,
      });
    } catch (err) {
      console.error('[BuyerChatController] deleteConversations error:', err);
      res.status(500).json({ success: false, error: err.message });
    }
  }

  /**
   * POST /api/support/buyer/token
   * Register or update buyer's FCM device token
   */
  async updateToken(req, res) {
    try {
      const { buyerId, token, fcmToken } = req.body;
      const effectiveToken = token || fcmToken;
      if (!buyerId || !effectiveToken) {
        return res.status(400).json({ success: false, error: 'buyerId and token are required' });
      }
      await buyerChatService.updateFcmToken(buyerId, effectiveToken);
      res.json({ success: true, message: 'FCM token registered' });
    } catch (err) {
      console.error('[BuyerChatController] updateToken error:', err);
      res.status(500).json({ success: false, error: err.message });
    }
  }

  /**
   * GET /api/support/buyer/:buyerId/unread
   */
  async getUnreadCount(req, res) {
    try {
      const { buyerId } = req.params;
      const count = await buyerChatService.getBuyerUnreadCount(buyerId);
      res.json({ success: true, count });
    } catch (err) {
      console.error('[BuyerChatController] getUnreadCount error:', err);
      res.status(500).json({ success: false, error: err.message });
    }
  }
}

module.exports = new BuyerChatController();
