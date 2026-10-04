import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class FirestoreService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Sync user profile to Firestore on login
  static Future<Map<String, dynamic>> syncUserProfile({
    required String uid,
    required String email,
    String? displayName,
    required String role,
  }) async {
    try {
      final userDocRef = _db.collection('users').doc(uid);
      final docSnap = await userDocRef.get();

      final String finalName = (displayName != null && displayName.isNotEmpty)
          ? displayName
          : email.split('@').first;

      if (!docSnap.exists) {
        final newUserData = {
          'uid': uid,
          'name': finalName,
          'email': email,
          'phone': '',
          'role': role,
          'isOnline': true,
          'lastLogin': FieldValue.serverTimestamp(),
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        };
        await userDocRef.set(newUserData);
        debugPrint('[FIRESTORE] Created new buyer user profile for $email ($uid)');
        return newUserData;
      } else {
        final existingData = docSnap.data() ?? {};
        final updateData = <String, dynamic>{
          'isOnline': true,
          'lastLogin': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        };

        if ((existingData['name'] == null || (existingData['name'] as String).isEmpty) && finalName.isNotEmpty) {
          updateData['name'] = finalName;
        }

        await userDocRef.update(updateData);
        debugPrint('[FIRESTORE] Updated buyer user login status for $email ($uid)');

        final merged = Map<String, dynamic>.from(existingData)..addAll(updateData);
        return merged;
      }
    } catch (e) {
      debugPrint('[FIRESTORE ERROR] Failed to sync user profile: $e');
      rethrow;
    }
  }

  /// Update user phone number and optionally name in Firestore
  static Future<void> updatePhoneAndDetails({
    required String uid,
    required String phone,
    String? name,
  }) async {
    try {
      final userDocRef = _db.collection('users').doc(uid);
      final updateData = <String, dynamic>{
        'phone': phone,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (name != null && name.trim().isNotEmpty) {
        updateData['name'] = name.trim();
      }

      await userDocRef.update(updateData);
      debugPrint('[FIRESTORE] Updated phone & details for $uid');
    } catch (e) {
      debugPrint('[FIRESTORE ERROR] Failed to update phone: $e');
      rethrow;
    }
  }

  /// Update logout status in Firestore
  static Future<void> updateLogoutStatus(String uid) async {
    try {
      final userDocRef = _db.collection('users').doc(uid);
      await userDocRef.update({
        'isOnline': false,
        'lastLogout': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      debugPrint('[FIRESTORE] Updated logout status for $uid');
    } catch (e) {
      debugPrint('[FIRESTORE ERROR] Failed to update logout status: $e');
    }
  }

  /// Fetch user profile from Firestore
  static Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    try {
      final docSnap = await _db.collection('users').doc(uid).get();
      return docSnap.data();
    } catch (e) {
      debugPrint('[FIRESTORE ERROR] Failed to fetch user profile: $e');
      return null;
    }
  }
}
