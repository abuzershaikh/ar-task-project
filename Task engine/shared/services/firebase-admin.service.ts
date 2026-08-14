import { Injectable, OnModuleInit, Logger } from '@nestjs/common';
import * as admin from 'firebase-admin';

const serviceAccount: admin.ServiceAccount = {
  projectId: 'taskz-87679',
  clientEmail: 'firebase-adminsdk-fbsvc@taskz-87679.iam.gserviceaccount.com',
  privateKey:
    '-----BEGIN PRIVATE KEY-----\nMIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQDnSvtjcrN41qpH\nTQtmypStQIiPA/e6xP7UhFg+OYNaLTM8oJ2ick3jhRWYzJkmSjqCJQi66XJJstHD\nIOZWNh1H7MzDFRR+7zg1ZWCM2Mz1gNHvKKsGfEQHjxmRxw79/mppsA5qyeDnpSwk\nG8Fp8ielLDd/shLl7X0Ov4ZxF1w2ZckdEeUVTH7ZajJKY4dGSJaB2OoQ1u2SU1UG\nceIUGbUru0wCu6fRhZtrREJwnF7RvzJAYh4ZBKm+fRRuMlhZlLekQiShOOx98c1k\nlSoyU3BJMVfa6gCufwzriDuqFMKwOPY1zFDTh1Cxhc4wiVkmjTFHhdATL9ZV3Bxb\n/7FO4rUhAgMBAAECggEABcusgs59iiktXz/iSbEo8nIt9dD0cr3z0XsPO8Bsztw3\n9uSCrK7S7jEAFHoIeqPUpV0Uk9vshuWb4VkEQovkthAcRaVkJAXeJYLgvWjDkoGH\nySeOiQkhOoQCwNMRSGqpC5TLeLAuMjnColU+dodYiFhUO+84L2Ig/ocMsS3j2/JK\n6pZ8tcexws+u8xckmIamcr1NYrfvj2pyC6aW175+nlhiH+6/tFM7HI2GxdTRXEiH\n/tNs39vww+Ml4GVfUY8Ii7PGBkNyQUoc+4ljWMxLKsawQMaENPZi06mDem0cj3sK\nPvgZXjZlbx3fyuhi1WMpEFNaY3fLTtGbpNdDZ+OPcQKBgQD2tKqnUbD0WQc6T5Ce\nw3ZODj6SnCESmqXVSE+xts8GwzrRGsvLp+JcD2LP7Jnb8tcnO4MdLErUud7fUKAi\nlTRiE3L9+UMCPFB7KkB+c3lYTrPL0xzUqNNEawyWTGFbKBf3BMydPBrcg6yOVd78\ny518M3jlZ65358Rn0seXV04lcQKBgQDwAarmTq0P/amORe3Cq/UZYV+cNbDLUGDH\nMYAGl62iV4xwh3EFvpIye6agTRphkpENWbT4SXXaxhmt/ceRm0iS8w689Qh5CLPH\n669jN9RhQVXl1Bn9RK9GXZGxNBpuGA7M5WWjx1GKPsXnbjdkvYmY9j/g8etjp3ub\naCLkJtbysQKBgQCuwOVNZlF5lILJLEkeHQj1W6O5SH0o54DmprVFBmB5wtsr+dY4\nabCvU3rEHC4Unl0HfmFuzcwoCY21FDCKrrQPcQV4oBN2RvEffZt3tyZShlVX4TA/\n92LHySh+YpZn8uue37hs/IFuiJs3q94rpbPlobRWk+4DI5p9jNIzAvXpEQKBgBPP\n722nnP2u8Oo/t4rUax03Po9El12ROwv2eB0TNFAsbfl0FM5mlub38h9VfhID6Vly\nyE+esM3ogIIuauUILouC6PqMN7DWGREt0YKdPzjwDck1IxgXLWjfnIFGTdA8yCv9\n29ATShXhbLDYFlaIlu07lrZZAhdt4fRIOmkfE6thAoGASKjdp1H1/+CV1KMHYv3z\nMben83pR4sShv57ZXNV6LYEVWWJ2lJrX4PArxMwpeGSzV9kcEP1+4ZLD+x9GXpGq\njFf0ESfYBbQkAJMjCjaGh4wRB3ecjmUum5ZWAxlxnxW+Iu6E+UIXcNUpBwtkDW7a\nySatOVGaupU9x6kALWNAdlg=\n-----END PRIVATE KEY-----\n',
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
}
