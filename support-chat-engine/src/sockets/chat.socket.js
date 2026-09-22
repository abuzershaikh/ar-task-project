const chatService = require('../services/chat.service');

function setupSocketIO(io) {
  io.on('connection', (socket) => {
    console.log(`[Socket.IO] Client connected: ${socket.id}`);

    // Join room
    socket.on('join', async (data, callback) => {
      try {
        const { role, workerId } = data || {};
        if (role === 'ADMIN') {
          socket.join('admin_support');
          socket.data = { role: 'ADMIN' };
          console.log(`[Socket.IO] Admin joined support room (${socket.id})`);
        } else if (workerId) {
          const room = `worker_${workerId}`;
          socket.join(room);
          socket.data = { role: 'WORKER', workerId };
          console.log(`[Socket.IO] Worker ${workerId} joined room ${room}`);
        }

        if (typeof callback === 'function') {
          callback({ success: true, socketId: socket.id });
        }
      } catch (err) {
        console.error('[Socket.IO] Join error:', err);
        if (typeof callback === 'function') callback({ success: false, error: err.message });
      }
    });

    // Real-time message dispatch
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

        // Security check: Worker can ONLY send TEXT messages
        if (senderType === 'WORKER' && messageType !== 'TEXT') {
          throw new Error('Workers can send text messages only');
        }

        // Persist message in DB
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

        // 1. Emit to worker room
        io.to(`worker_${workerId}`).emit('new_message', message);

        // 2. Emit to all connected admins
        io.to('admin_support').emit('new_message', message);

        // 3. Emit conversation updated event to admin for updating chat list sorting & unread badge
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

    // Mark messages as read
    socket.on('mark_read', async (data, callback) => {
      try {
        const { conversationId, workerId, readerType } = data || {};
        if (conversationId) {
          await chatService.markRead(conversationId, readerType || 'ADMIN');

          // Notify sender of read status
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

    // Typing indicator
    socket.on('typing', (data) => {
      const { workerId, senderType, isTyping } = data || {};
      if (senderType === 'ADMIN' && workerId) {
        io.to(`worker_${workerId}`).emit('typing', { senderType: 'ADMIN', isTyping });
      } else if (senderType === 'WORKER' && workerId) {
        io.to('admin_support').emit('typing', { workerId, senderType: 'WORKER', isTyping });
      }
    });

    socket.on('disconnect', () => {
      console.log(`[Socket.IO] Client disconnected: ${socket.id}`);
    });
  });
}

module.exports = { setupSocketIO };
