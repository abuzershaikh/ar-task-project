class BuyerSupportConversationModel {
  final String id;
  final String buyerId;
  final String buyerName;
  final String buyerPhone;
  final String buyerEmail;
  final String lastMessageText;
  final String lastMessageType;
  final DateTime lastMessageAt;
  final int unreadAdminCount;
  final int unreadBuyerCount;
  final String? buyerAvatarUrl;

  const BuyerSupportConversationModel({
    required this.id,
    required this.buyerId,
    required this.buyerName,
    required this.buyerPhone,
    required this.buyerEmail,
    required this.lastMessageText,
    required this.lastMessageType,
    required this.lastMessageAt,
    required this.unreadAdminCount,
    required this.unreadBuyerCount,
    this.buyerAvatarUrl,
  });

  factory BuyerSupportConversationModel.fromJson(Map<String, dynamic> json) {
    String rawName = json['buyer_name']?.toString().trim() ?? '';
    final rawEmail = json['buyer_email']?.toString().trim() ?? '';
    final rawPhone = json['buyer_phone']?.toString().trim() ?? '';

    String resolvedName = rawName;
    if (resolvedName.isEmpty || resolvedName.toLowerCase() == 'buyer') {
      if (rawEmail.isNotEmpty) {
        resolvedName = rawEmail.split('@')[0];
      } else if (rawPhone.isNotEmpty) {
        resolvedName = rawPhone;
      } else {
        final bId = json['buyer_id']?.toString() ?? '';
        resolvedName = bId.length > 6 ? 'Buyer #${bId.substring(0, 6)}' : 'Buyer';
      }
    }

    return BuyerSupportConversationModel(
      id: json['id']?.toString() ?? '',
      buyerId: json['buyer_id']?.toString() ?? '',
      buyerName: resolvedName,
      buyerPhone: rawPhone,
      buyerEmail: rawEmail,
      lastMessageText: json['last_message_text']?.toString() ?? '',
      lastMessageType: json['last_message_type']?.toString() ?? 'TEXT',
      lastMessageAt: json['last_message_at'] != null
          ? DateTime.tryParse(json['last_message_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      unreadAdminCount: int.tryParse(json['unread_admin_count']?.toString() ?? '0') ?? 0,
      unreadBuyerCount: int.tryParse(json['unread_buyer_count']?.toString() ?? '0') ?? 0,
      buyerAvatarUrl: json['buyer_avatar_url']?.toString() ??
          json['avatar_url']?.toString() ??
          json['avatarUrl']?.toString(),
    );
  }

  BuyerSupportConversationModel copyWith({
    String? lastMessageText,
    String? lastMessageType,
    DateTime? lastMessageAt,
    int? unreadAdminCount,
    int? unreadBuyerCount,
  }) {
    return BuyerSupportConversationModel(
      id: id,
      buyerId: buyerId,
      buyerName: buyerName,
      buyerPhone: buyerPhone,
      buyerEmail: buyerEmail,
      lastMessageText: lastMessageText ?? this.lastMessageText,
      lastMessageType: lastMessageType ?? this.lastMessageType,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      unreadAdminCount: unreadAdminCount ?? this.unreadAdminCount,
      unreadBuyerCount: unreadBuyerCount ?? this.unreadBuyerCount,
      buyerAvatarUrl: buyerAvatarUrl,
    );
  }
}
