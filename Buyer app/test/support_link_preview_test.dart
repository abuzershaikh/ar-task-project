import 'package:flutter_test/flutter_test.dart';

import '../lib/features/support/data/buyer_chat_service.dart';

void main() {
  test('buyer chat detects WhatsApp link as previewable web content', () {
    final message = BuyerChatMessage(
      id: '1',
      conversationId: 'conversation',
      buyerId: 'buyer',
      senderType: 'ADMIN',
      messageType: 'TEXT',
      content: 'Message us: https://wa.me/919876543210?text=Support',
      isRead: false,
      createdAt: DateTime.utc(2026),
    );

    expect(message.hasWebLink, isTrue);
    expect(
      message.effectiveWebUrl,
      'https://wa.me/919876543210?text=Support',
    );
    expect(message.textWithoutLink, 'Message us:');
  });
}
