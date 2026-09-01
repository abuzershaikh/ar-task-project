import { Injectable, OnModuleInit, Logger } from '@nestjs/common';
import * as admin from 'firebase-admin';

const serviceAccount: admin.ServiceAccount = {
  projectId: 'taskz-87679',
  clientEmail: 'firebase-adminsdk-fbsvc@taskz-87679.iam.gserviceaccount.com',
  privateKey:
    '-----BEGIN PRIVATE KEY-----\nMIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQDF8/ApjOVJ3UFM\n69V4PIx126TIAIyxjGNqX+S05FqKWffISMEDWXxF40Toajbg5ycynPxa32jyonSH\n4vmchbB1PURb+0W4IpbkGhVJkCurbu/LBrvauPN4xCTOZbd7bK7h9MHnqxODqxHH\nIVj8s22Hc/8xtzk6MXsUrB4tF2gLSKsx4xvBc/ywQtdRazj3z0wVE5EJ/oq3xrAg\nAr3IbwyPbdc3a5qg0CV5gQjbcyONJypVF1regKgki3jeTA9nFV/FsQvBmzD/CI1S\nXW5ZTD7E6ciyv6uTnsWxlqxOVaJ6kuYEx8mUPqc5k44mx5jm/AiEK3sTfK25xazH\nHdLqPhyLAgMBAAECggEAFDpmO0i7kX27k4mx6bR+Qfjs8MclmWsYKaGc9GM1YVfq\nOxw8JQR674VW4E0iSH82gTSLkRmtVsYFFHG8QiNjMcfN+XxG1pcqRiroK/lAjScr\n99o7ThGCR7/7Zt/8DO/BOzPQsMTJnLXZfjjJKCGJusK+vCzV+z1dL3KbLs5qgmR/\nUjerQR2cvcGByCo8ZRLydflCYk6D1I454vKYivMlyiJVo8etcEgmmyJeDrN+8/iy\nsrB06BoA3bb2VoLRo8PK8hOBcpcUQNo0dXGVWt/corSDorJvSU/l+UXEu7NuXwt3\nnRPFlGAgiR/ScaL9EdfTaKhkvmcYjaIP2Eo8zBJh8QKBgQD8g2PaHayel1ZlEwVJ\nZydfn9dAbTAUJbSfjjwn1v9FjqACHr2t/AmcBUbEWOD4MnpJhGUIcOqvETPGHbyM\nEWed1mJ6LCY2EQI4xf4WGmdTpd23Whi+XynnyKrlog9hvdAnbmpCvSGc1BLwrgzj\nFGyDLEQwLAGNColvXZgswDWduQKBgQDIr663FBeSQwoNCJ0JUU1iRhNI3oVeo2xM\nsUFs8aO8joDajvBQkXLnDwtRlKtCRaBGtgwN1EO2MNJJiTQIQzy78DUDfmy6tm0v\nSpVxOmAQN5UiKF6uEKt7IIy+7u81mGn1WDHshBj99qIUVk8xCBTEb6ZBM9zfmIsy\nWfX9/vIOYwKBgQCReymGOt5/KHXwGbtMBRBcOX0Mc1vl36tm2c2yrl24N2ncjtV9\nbd4jc67H5OUIWhy2Sn7jFBtB7clEdVFx6X0nJKLr/I+vSrFbAEdZeLDbMo7A2jmz\nRKSiE6zSTEJMb82DSkwSU2EQN+cJn11xXwz9rf1DO7dRCScRcH0CG2NIkQKBgB8W\nV9I0YpJdoCj0tJ7E4V/fywz2q2JFnnki3CesJtkGmh9BFSjl3w673dz9UqopbvKF\nMMjToMmQNoL9pfnBsJ7MTuoDo4QozjENNKkdidP5SDjKWCBOpMGmASdyi8uZmJBQ\n4SrqK5Trp5/O3uWRguYLBY4EIqrgTm+2T8zQuV5RAoGAUcKd5uS51HKj2dLofgWY\n6La/TwMSvpuxhf9ysq1WduCt54/hXAhuU9uRGPTDwfi3q7PiCd7sgS8HdBkMY+D/\nCifUklpxWwlYynnTT6rrlNVbLnMpkyy+TM2/NZUXv4UhqnUIuVsC2CoUsFwUDw9+\nYn5YnkjDjmTC6EJTTmvmEJY=\n-----END PRIVATE KEY-----\n',
};

@Injectable()
export class FirebaseAdminService implements OnModuleInit {
  private readonly logger = new Logger(FirebaseAdminService.name);
  private firebaseApp: admin.app.App;

  onModuleInit() {
    if (!admin.apps.length) {
      try {
        this.firebaseApp = admin.initializeApp({
          credential: admin.credential.cert(serviceAccount),
          storageBucket: 'taskz-87679.firebasestorage.app',
        });
        this.logger.log('Firebase Admin SDK with Service Account Credentials initialized successfully');
      } catch (error) {
        this.logger.error('Failed to initialize Firebase Admin SDK', error);
      }
    } else {
      this.firebaseApp = admin.app();
    }
  }

  get firestore(): admin.firestore.Firestore {
    return admin.firestore();
  }

  get auth(): admin.auth.Auth {
    return admin.auth();
  }

  get messaging(): admin.messaging.Messaging {
    return admin.messaging();
  }

  /// Get user document from Firestore by UID or Email
  async getFirestoreUser(uidOrEmail: string): Promise<any> {
    try {
      const db = this.firestore;

      // Try by UID document first
      const docSnap = await db.collection('users').doc(uidOrEmail).get();
      if (docSnap.exists) {
        return { id: docSnap.id, ...docSnap.data() };
      }

      // Query by email
      const querySnap = await db
        .collection('users')
        .where('email', '==', uidOrEmail)
        .limit(1)
        .get();

      if (!querySnap.empty) {
        const doc = querySnap.docs[0];
        return { id: doc.id, ...doc.data() };
      }

      return null;
    } catch (error) {
      this.logger.error(`Error fetching Firestore user for ${uidOrEmail}`, error);
      return null;
    }
  }

  /// Verify Firebase ID token if provided
  async verifyIdToken(idToken: string): Promise<admin.auth.DecodedIdToken | null> {
    try {
      return await this.auth.verifyIdToken(idToken);
    } catch (error) {
      this.logger.warn(`Firebase ID Token verification failed: ${error.message}`);
      return null;
    }
  }

  /// Broadcast New Task Push Notification to all workers
  async sendTaskBroadcastNotification(params: {
    title?: string;
    body?: string;
    taskId?: string;
    orderId?: string;
    reward?: number;
    serviceCode?: string;
  }): Promise<void> {
    try {
      const rewardFormatted = params.reward ? `₹${params.reward}` : 'Cash Reward';
      const notificationTitle = params.title || `🎉 New Task Available! Earn ${rewardFormatted}`;
      const notificationBody =
        params.body ||
        `A new ${params.serviceCode || 'reward'} task is ready. Accept now before slots fill up!`;

      const dataPayload: Record<string, string> = {
        type: 'NEW_TASK',
        click_action: 'FLUTTER_NOTIFICATION_CLICK',
        taskId: params.taskId || '',
        orderId: params.orderId || '',
        reward: String(params.reward || '0'),
        serviceCode: params.serviceCode || '',
        createdAt: new Date().toISOString(),
      };

      // 1. Send broadcast to FCM Topic 'workers' and 'all_workers'
      try {
        const topicMessage: admin.messaging.Message = {
          topic: 'workers',
          notification: {
            title: notificationTitle,
            body: notificationBody,
          },
          data: dataPayload,
          android: {
            priority: 'high',
            notification: {
              channelId: 'task_notifications',
              priority: 'high',
              sound: 'default',
              clickAction: 'FLUTTER_NOTIFICATION_CLICK',
            },
          },
        };
        await this.messaging.send(topicMessage);
        this.logger.log(`📢 [FCM BROADCAST] Push sent to topic 'workers': ${notificationTitle}`);
      } catch (topicErr) {
        this.logger.warn(`FCM Topic push warning: ${topicErr.message}`);
      }

      // 2. Also send direct push to all worker device tokens registered in Firestore
      try {
        const usersSnap = await this.firestore
          .collection('users')
          .get();

        const tokens: string[] = [];
        usersSnap.forEach((doc) => {
          const d = doc.data();
          if (d.fcmToken && typeof d.fcmToken === 'string' && d.fcmToken.length > 20) {
            tokens.push(d.fcmToken);
          }
        });

        if (tokens.length > 0) {
          const uniqueTokens = Array.from(new Set(tokens));
          const multicastRes = await this.messaging.sendEachForMulticast({
            tokens: uniqueTokens,
            notification: {
              title: notificationTitle,
              body: notificationBody,
            },
            data: dataPayload,
            android: {
              priority: 'high',
              notification: {
                channelId: 'task_notifications',
                priority: 'high',
                sound: 'default',
                clickAction: 'FLUTTER_NOTIFICATION_CLICK',
              },
            },
          });
          this.logger.log(
            `📱 [FCM DIRECT MULTICAST] Dispatched to ${uniqueTokens.length} registered worker devices (Success: ${multicastRes.successCount}, Failed: ${multicastRes.failureCount})`
          );
        }
      } catch (directErr) {
        this.logger.warn(`Direct worker multicast warning: ${directErr.message}`);
      }

      // 3. Persist notification to Firestore for worker notification history
      try {
        await this.firestore.collection('notifications').add({
          type: 'NEW_TASK',
          target: 'ALL_WORKERS',
          title: notificationTitle,
          body: notificationBody,
          data: dataPayload,
          isRead: false,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      } catch (storeErr) {
        this.logger.warn(`Failed to store notification history: ${storeErr.message}`);
      }
    } catch (error) {
      this.logger.error('Failed to send task broadcast push notification', error);
    }
  }

  /// Send Direct Push Notification to a specific worker
  async sendDirectPushNotification(
    fcmToken: string,
    title: string,
    body: string,
    data: Record<string, string> = {}
  ): Promise<boolean> {
    try {
      if (!fcmToken || fcmToken.length < 20) return false;

      const message: admin.messaging.Message = {
        token: fcmToken,
        notification: { title, body },
        data: {
          ...data,
          click_action: 'FLUTTER_NOTIFICATION_CLICK',
        },
        android: {
          priority: 'high',
          notification: {
            channelId: 'task_notifications',
            priority: 'high',
            sound: 'default',
            clickAction: 'FLUTTER_NOTIFICATION_CLICK',
          },
        },
      };

      await this.messaging.send(message);
      this.logger.log(`📱 [FCM DIRECT PUSH] Sent to device: ${title}`);
      return true;
    } catch (error) {
      this.logger.error(`Error sending direct push to token: ${error.message}`);
      return false;
    }
  }
}
