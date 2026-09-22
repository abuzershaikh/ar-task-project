const admin = require('../config/firebase');
const { pool } = require('../config/db');

/**
 * Sends FCM push notification to a specific worker
 */
async function sendWorkerChatNotification(workerId, messageData) {
  try {
    if (!admin.apps.length) {
      console.warn('[FCM] Firebase admin not initialized, skipping notification');
      return;
    }

    // Lookup worker token from users table
    const [rows] = await pool.query(
      'SELECT id, email, metadata FROM users WHERE id = ? LIMIT 1',
      [workerId]
    );

    let token = null;
    if (rows && rows.length > 0 && rows[0].metadata) {
      try {
        const meta = typeof rows[0].metadata === 'string' 
          ? JSON.parse(rows[0].metadata) 
          : rows[0].metadata;
        token = meta.fcmToken || meta.deviceToken || meta.pushToken;
      } catch (_) {}
    }

    let bodyText = messageData.content || 'New message from Support Team';
    if (messageData.message_type === 'YOUTUBE') {
      bodyText = '📹 Sent a video link';
    } else if (messageData.message_type === 'AUDIO') {
      bodyText = '🎙️ Sent a voice audio message';
    } else if (messageData.message_type === 'IMAGE') {
      bodyText = '📷 Sent an image';
    }

    const payload = {
      data: {
        type: 'SUPPORT_CHAT',
        click_action: 'FLUTTER_NOTIFICATION_CLICK',
        workerId: String(workerId),
        conversationId: String(messageData.conversation_id || ''),
        messageId: String(messageData.id || ''),
        senderType: 'ADMIN',
        title: 'Support Team',
        body: bodyText,
        created_at: new Date().toISOString(),
      },
      android: {
        priority: 'high',
        notification: {
          title: 'Support Team',
          body: bodyText,
          channelId: 'support_chat_notifications',
          priority: 'high',
          sound: 'default',
          clickAction: 'FLUTTER_NOTIFICATION_CLICK',
        },
      },
    };

    if (token) {
      payload.token = token;
      await admin.messaging().send(payload);
      console.log(`[FCM] Notification sent directly to token for worker ${workerId}`);
    } else {
      // Fallback to topic
      payload.topic = `worker_${workerId}`;
      await admin.messaging().send(payload);
      console.log(`[FCM] Notification sent to topic worker_${workerId}`);
    }
  } catch (err) {
    console.warn(`[FCM] Could not send push notification for worker ${workerId}:`, err.message);
  }
}

/**
 * Sends bulk notifications to multiple workers
 */
async function sendBulkWorkerChatNotifications(workerIds, messageData) {
  for (const wId of workerIds) {
    // Non-blocking asynchronous dispatch
    sendWorkerChatNotification(wId, messageData).catch(() => {});
  }
}

module.exports = {
  sendWorkerChatNotification,
  sendBulkWorkerChatNotifications,
};
