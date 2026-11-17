import 'package:flutter_test/flutter_test.dart';

import '../lib/features/support_chat/models/worker_support_message.dart';

void main() {
  test('worker chat detects and cleans a WhatsApp web link', () {
    final message = WorkerSupportMessage(
      id: '1',
      conversationId: 'conversation',
      workerId: 'worker',
      senderType: 'ADMIN',
      messageType: 'TEXT',
      content: 'Chat now https://wa.me/919876543210.',
      isRead: false,
      createdAt: DateTime.utc(2026),
    );

    expect(message.hasWebLink, isTrue);
    expect(message.effectiveWebUrl, 'https://wa.me/919876543210');
    expect(message.textWithoutLink, 'Chat now');
  });
}
