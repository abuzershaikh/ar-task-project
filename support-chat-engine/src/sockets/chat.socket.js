const chatService = require('../services/chat.service');
const buyerChatService = require('../buyer/buyer-chat.service');

function setupSocketIO(io) {
  io.on('connection', (socket) => {
    console.log(`[Socket.IO] Client connected: ${socket.id}`);

    // Join room
    socket.on('join', async (data, callback) => {
      try {
        const { role, workerId, buyerId } = data || {};
        if (role === 'ADMIN') {
          socket.join('admin_support');
          socket.join('admin_buyer_support');
          socket.data = { role: 'ADMIN' };
          console.log(`[Socket.IO] Admin joined support rooms (${socket.id})`);
        } else if (role === 'BUYER' || buyerId) {
          const bId = buyerId || data.userId;
          if (bId) {
            const room = `buyer_${bId}`;
            socket.join(room);
            socket.data = { role: 'BUYER', buyerId: bId };
            console.log(`[Socket.IO] Buyer ${bId} joined room ${room}`);
          }
        } else if (workerId) {
          const room = `worker_${workerId}`;
          socket.join(room);
          socket.data = { role: 'WORKER', workerId };
          console.log(`[Socket.IO] Worker ${workerId} joined room ${room}`);
          // Ensure conversation exists and worker metadata is synced
          chatService.getOrCreateConversation(workerId, data).catch((e) => {
            console.error('[Socket.IO] Worker auto-sync error:', e.message);
          });
        }

        if (typeof callback === 'function') {
          callback({ success: true, socketId: socket.id });
        }
      } catch (err) {
        console.error('[Socket.IO] Join error:', err);
        if (typeof callback === 'function') callback({ success: false, error: err.message });
      }
    });

    // ──────────────── WORKER CHAT EVENTS ────────────────
    socket.on('send_message', async (data, callback) => {
      try {
        const {
          conversationId,
          workerId,
          senderType,
          messageType = 'TEXT',
          content = '',
          mediaUrl = null,
          youtubeId = null,
          durationSeconds = 0,
        } = data || {};

        if (!workerId || !senderType) {
          throw new Error('workerId and senderType are required');
        }

        if (senderType === 'WORKER' && messageType !== 'TEXT') {
          throw new Error('Workers can send text messages only');
        }

        const message = await chatService.createMessage({
          conversationId,
          workerId,
          senderType,
          messageType: senderType === 'WORKER' ? 'TEXT' : messageType,
          content,
          mediaUrl,
          youtubeId,
          durationSeconds,
        });

        io.to(`worker_${workerId}`).emit('new_message', message);
        io.to('admin_support').emit('new_message', message);

        const updatedConv = await chatService.getOrCreateConversation(workerId);
        io.to('admin_support').emit('conversation_updated', updatedConv);

        if (typeof callback === 'function') {
          callback({ success: true, data: message });
        }
      } catch (err) {
        console.error('[Socket.IO] send_message error:', err);
        if (typeof callback === 'function') {
          callback({ success: false, error: err.message });
        }
      }
    });

    socket.on('mark_read', async (data, callback) => {
      try {
        const { conversationId, workerId, readerType } = data || {};
        if (conversationId) {
          await chatService.markRead(conversationId, readerType || 'ADMIN');
          if (readerType === 'ADMIN' && workerId) {
            io.to(`worker_${workerId}`).emit('messages_read', { conversationId });
          } else if (readerType === 'WORKER') {
            io.to('admin_support').emit('messages_read', { conversationId, workerId });
          }
        }

        if (typeof callback === 'function') callback({ success: true });
      } catch (err) {
        console.error('[Socket.IO] mark_read error:', err);
        if (typeof callback === 'function') callback({ success: false, error: err.message });
      }
    });

    socket.on('typing', (data) => {
      const { workerId, senderType, isTyping } = data || {};
      if (senderType === 'ADMIN' && workerId) {
        io.to(`worker_${workerId}`).emit('typing', { senderType: 'ADMIN', isTyping });
      } else if (senderType === 'WORKER' && workerId) {
        io.to('admin_support').emit('typing', { workerId, senderType: 'WORKER', isTyping });
      }
    });

    // ──────────────── BUYER CHAT EVENTS ────────────────
    socket.on('send_buyer_message', async (data, callback) => {
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
        } = data || {};

        if (!buyerId || !senderType) {
          throw new Error('buyerId and senderType are required');
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

        // 1. Emit to buyer room
        io.to(`buyer_${buyerId}`).emit('new_buyer_message', message);

        // 2. Emit to admin buyer support room
        io.to('admin_buyer_support').emit('new_buyer_message', message);
        io.to('admin_support').emit('new_buyer_message', message);

        // 3. Emit updated conversation to admin for real-time list reordering & unread counts
        const updatedConv = await buyerChatService.getOrCreateConversation(buyerId);
        io.to('admin_buyer_support').emit('buyer_conversation_updated', updatedConv);

        if (typeof callback === 'function') {
          callback({ success: true, data: message });
        }
      } catch (err) {
        console.error('[Socket.IO] send_buyer_message error:', err);
        if (typeof callback === 'function') {
          callback({ success: false, error: err.message });
        }
      }
    });

    socket.on('mark_buyer_read', async (data, callback) => {
      try {
        const { conversationId, buyerId, readerType } = data || {};
        if (conversationId) {
          await buyerChatService.markRead(conversationId, readerType || 'ADMIN');

          if (readerType === 'ADMIN' && buyerId) {
            io.to(`buyer_${buyerId}`).emit('buyer_messages_read', { conversationId });
          } else if (readerType === 'BUYER') {
            io.to('admin_buyer_support').emit('buyer_messages_read', { conversationId, buyerId });
          }
        }

        if (typeof callback === 'function') callback({ success: true });
      } catch (err) {
        console.error('[Socket.IO] mark_buyer_read error:', err);
        if (typeof callback === 'function') callback({ success: false, error: err.message });
      }
    });

    socket.on('buyer_typing', (data) => {
      const { buyerId, senderType, isTyping } = data || {};
      if (senderType === 'ADMIN' && buyerId) {
        io.to(`buyer_${buyerId}`).emit('buyer_typing', { senderType: 'ADMIN', isTyping });
      } else if (buyerId) {
        io.to('admin_buyer_support').emit('buyer_typing', { buyerId, senderType: 'BUYER', isTyping });
      }
    });

    socket.on('register_buyer_token', async (data) => {
      const { buyerId, fcmToken, token } = data || {};
      const finalToken = fcmToken || token;
      if (buyerId && finalToken) {
        await buyerChatService.updateFcmToken(buyerId, finalToken);
        console.log(`[Socket.IO] Registered FCM token for buyer ${buyerId}`);
      }
    });

    socket.on('disconnect', () => {
      console.log(`[Socket.IO] Client disconnected: ${socket.id}`);
    });
  });
}

module.exports = { setupSocketIO };
