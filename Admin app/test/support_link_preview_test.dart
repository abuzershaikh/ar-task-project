import 'package:flutter_test/flutter_test.dart';

import '../lib/features/support_chat/data/models/buyer_support_message_model.dart';
import '../lib/features/support_chat/data/models/support_message_model.dart';

void main() {
  test('worker support messages detect WhatsApp links and keep caption', () {
    final message = SupportMessageModel(
      id: '1',
      conversationId: 'conversation',
      workerId: 'worker',
      senderType: 'ADMIN',
      messageType: 'TEXT',
      content: 'Contact us https://wa.me/919876543210?text=Hello',
      isRead: false,
      createdAt: DateTime.utc(2026),
    );

    expect(message.hasWebLink, isTrue);
    expect(
      message.effectiveWebUrl,
      'https://wa.me/919876543210?text=Hello',
    );
    expect(message.textWithoutLink, 'Contact us');
  });

  test('buyer support messages normalize www links for launching', () {
    final message = BuyerSupportMessageModel(
      id: '1',
      conversationId: 'conversation',
      buyerId: 'buyer',
      senderType: 'BUYER',
      messageType: 'TEXT',
      content: 'Open www.example.com/support.',
      isRead: false,
      createdAt: DateTime.utc(2026),
    );

    expect(message.hasWebLink, isTrue);
    expect(message.effectiveWebUrl, 'https://www.example.com/support');
    expect(message.textWithoutLink, 'Open');
  });
}
