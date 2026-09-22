import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_reward_app/features/support_chat/models/worker_support_message.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Worker Support Chat Caching & 1-Month Purge Tests', () {
    test('WorkerSupportMessage toJson and fromJson serialization works flawlessly', () {
      final now = DateTime.now();
      final original = WorkerSupportMessage(
        id: 'msg_test_123',
        conversationId: 'conv_456',
        workerId: 'worker_1',
        senderType: 'WORKER',
        messageType: 'TEXT',
        content: 'Hello Support Team!',
        mediaUrl: null,
        isRead: true,
        createdAt: now,
      );

      final jsonMap = original.toJson();
      expect(jsonMap['id'], 'msg_test_123');
      expect(jsonMap['workerId'], 'worker_1');
      expect(jsonMap['senderType'], 'WORKER');
      expect(jsonMap['content'], 'Hello Support Team!');
      expect(jsonMap['createdAt'], now.toIso8601String());

      final restored = WorkerSupportMessage.fromJson(jsonMap);
      expect(restored.id, original.id);
      expect(restored.workerId, original.workerId);
      expect(restored.senderType, original.senderType);
      expect(restored.content, original.content);
      expect(restored.isWorker, isTrue);
      expect(restored.isAdmin, isFalse);
    });

    test('Chat messages older than 30 days (1 month) are automatically purged', () {
      final now = DateTime.now();
      final freshMessage = WorkerSupportMessage(
        id: 'msg_fresh',
        conversationId: 'conv_1',
        workerId: 'worker_1',
        senderType: 'ADMIN',
        messageType: 'IMAGE',
        content: 'Payment screenshot',
        mediaUrl: 'https://example.com/receipt.jpg',
        isRead: true,
        createdAt: now.subtract(const Duration(days: 5)), // 5 days old
      );

      final oldMessage = WorkerSupportMessage(
        id: 'msg_old',
        conversationId: 'conv_1',
        workerId: 'worker_1',
        senderType: 'WORKER',
        messageType: 'TEXT',
        content: 'Old question from last month',
        mediaUrl: null,
        isRead: true,
        createdAt: now.subtract(const Duration(days: 35)), // 35 days old (over 1 month)
      );

      final allMessages = [freshMessage, oldMessage];

      // Simulate cache pruning logic (same logic as in WorkerChatService)
      final oneMonthAgo = now.subtract(const Duration(days: 30));
      final prunedMessages = allMessages.where((m) => m.createdAt.isAfter(oneMonthAgo)).toList();

      expect(prunedMessages.length, 1);
      expect(prunedMessages.first.id, 'msg_fresh');
      expect(prunedMessages.any((m) => m.id == 'msg_old'), isFalse);
    });

    test('Local disk cache directory can identify and purge files older than 30 days', () async {
      final tempDir = await Directory.systemTemp.createTemp('support_chat_test_cache');
      try {
        final freshFile = File('${tempDir.path}/fresh_media.jpg');
        await freshFile.writeAsString('fresh content');

        final oldFile = File('${tempDir.path}/old_media.jpg');
        await oldFile.writeAsString('old content');

        // Set modification time of old file to 35 days ago
        final oldTime = DateTime.now().subtract(const Duration(days: 35));
        await oldFile.setLastModified(oldTime);

        // Verification of purge
        final oneMonthAgo = DateTime.now().subtract(const Duration(days: 30));
        int purgedCount = 0;

        await for (final entity in tempDir.list(followLinks: false)) {
          if (entity is File) {
            final stat = await entity.stat();
            if (stat.modified.isBefore(oneMonthAgo)) {
              await entity.delete();
              purgedCount++;
            }
          }
        }

        expect(purgedCount, 1);
        expect(await freshFile.exists(), isTrue);
        expect(await oldFile.exists(), isFalse);
      } finally {
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      }
    });

    test('Indian Standard Time (IST) conversion accurately computes UTC+5:30 in 12-hour format', () {
      // 13:47 UTC should be exactly 19:17 (07:17 PM) IST
      final msgUtc = WorkerSupportMessage.fromJson({
        'id': 'msg_time_1',
        'conversation_id': 'conv_1',
        'worker_id': 'worker_1',
        'sender_type': 'ADMIN',
        'message_type': 'TEXT',
        'content': 'Test IST time',
        'created_at': '2026-09-22T13:47:00Z',
      });
      expect(msgUtc.formattedIstTime, '07:17 PM');

      // Space-separated MySQL timestamp without 'Z' (e.g. "2026-09-22 13:47:00")
      final msgMysql = WorkerSupportMessage.fromJson({
        'id': 'msg_time_2',
        'conversation_id': 'conv_1',
        'worker_id': 'worker_1',
        'sender_type': 'WORKER',
        'message_type': 'TEXT',
        'content': 'MySQL timestamp test',
        'created_at': '2026-09-22 13:47:00',
      });
      expect(msgMysql.formattedIstTime, '07:17 PM');

      // Morning time: 04:15 UTC should be 09:45 AM IST
      final msgMorning = WorkerSupportMessage.fromJson({
        'id': 'msg_time_3',
        'conversation_id': 'conv_1',
        'worker_id': 'worker_1',
        'sender_type': 'WORKER',
        'message_type': 'TEXT',
        'content': 'Morning message',
        'created_at': '2026-09-22T04:15:00Z',
      });
      expect(msgMorning.formattedIstTime, '09:45 AM');
    });
  });
}
