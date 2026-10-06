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
 * Sends FCM push notification to a specific Buyer
 */
async function sendBuyerChatNotification(buyerId, messageData) {
  try {
    if (!admin.apps.length) {
      console.warn('[FCM] Firebase admin not initialized, skipping buyer notification');
      return;
    }

    let token = null;

    // 1. Try to get token from buyer_support_conversations
    try {
      const [convRows] = await pool.query(
        'SELECT fcm_token FROM buyer_support_conversations WHERE buyer_id = ? LIMIT 1',
        [buyerId]
      );
      if (convRows.length > 0 && convRows[0].fcm_token) {
        token = convRows[0].fcm_token;
      }
    } catch (_) {}

    // 2. Fallback to users table metadata
    if (!token) {
      try {
        const [uRows] = await pool.query(
          'SELECT metadata FROM users WHERE id = ? OR email = ? LIMIT 1',
          [buyerId, buyerId]
        );
        if (uRows.length > 0 && uRows[0].metadata) {
          const meta = typeof uRows[0].metadata === 'string'
            ? JSON.parse(uRows[0].metadata)
            : uRows[0].metadata;
          token = meta.fcmToken || meta.deviceToken || meta.pushToken;
        }
      } catch (_) {}
    }

    let bodyText = messageData.content || 'New message from Support Desk';
    if (messageData.message_type === 'YOUTUBE') {
      bodyText = '📹 Sent a video link';
    } else if (messageData.message_type === 'AUDIO') {
      bodyText = '🎙️ Sent a voice audio message';
    } else if (messageData.message_type === 'IMAGE') {
      bodyText = '📷 Sent an image';
    }

    const payload = {
      data: {
        type: 'BUYER_SUPPORT_CHAT',
        click_action: 'FLUTTER_NOTIFICATION_CLICK',
        buyerId: String(buyerId),
        conversationId: String(messageData.conversation_id || ''),
        messageId: String(messageData.id || ''),
        senderType: 'ADMIN',
        title: 'Support Desk',
        body: bodyText,
        created_at: new Date().toISOString(),
      },
      android: {
        priority: 'high',
        notification: {
          title: 'Support Desk',
          body: bodyText,
          channelId: 'buyer_support_chat',
          priority: 'high',
          sound: 'default',
          clickAction: 'FLUTTER_NOTIFICATION_CLICK',
        },
      },
    };

    // If token exists, send direct to token
    if (token) {
      try {
        const directPayload = { ...payload, token };
        await admin.messaging().send(directPayload);
        console.log(`[FCM] Notification sent directly to token for buyer ${buyerId}`);
      } catch (tokenErr) {
        console.warn(`[FCM] Direct token send failed for buyer ${buyerId}:`, tokenErr.message);
      }
    }

    // Also send to topic buyer_${cleanBuyerId} for 100% reliable multi-device / background delivery
    try {
      const cleanTopic = `buyer_${String(buyerId).replace(/[^a-zA-Z0-9-_.~%]/g, '_')}`;
      const topicPayload = { ...payload, topic: cleanTopic };
      await admin.messaging().send(topicPayload);
      console.log(`[FCM] Notification sent to topic ${cleanTopic}`);
    } catch (topicErr) {
      console.warn(`[FCM] Topic send failed for buyer ${buyerId}:`, topicErr.message);
    }
  } catch (err) {
    console.warn(`[FCM] Error in sendBuyerChatNotification for buyer ${buyerId}:`, err.message);
  }
}

/**
 * Sends bulk notifications to multiple workers
 */
async function sendBulkWorkerChatNotifications(workerIds, messageData) {
  for (const wId of workerIds) {
    sendWorkerChatNotification(wId, messageData).catch(() => {});
  }
}

module.exports = {
  sendWorkerChatNotification,
  sendBuyerChatNotification,
  sendBulkWorkerChatNotifications,
};
