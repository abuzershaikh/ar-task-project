import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
// ignore: library_prefixes
import 'package:socket_io_client/socket_io_client.dart' as IO;

class BuyerChatMessage {
  final String id;
  final String conversationId;
  final String buyerId;
  final String senderType; // 'BUYER' | 'ADMIN'
  final String messageType; // 'TEXT' | 'IMAGE' | 'AUDIO' | 'YOUTUBE'
  final String content;
  final String? mediaUrl;
  final String? youtubeId;
  final int durationSeconds;
  final bool isRead;
  final DateTime createdAt;

  const BuyerChatMessage({
    required this.id,
    required this.conversationId,
    required this.buyerId,
    required this.senderType,
    required this.messageType,
    required this.content,
    this.mediaUrl,
    this.youtubeId,
    this.durationSeconds = 0,
    required this.isRead,
    required this.createdAt,
  });

  bool get isAdmin => senderType == 'ADMIN';
  bool get isBuyer => senderType == 'BUYER';

  static String? extractYoutubeId(String text) {
    if (text.isEmpty) return null;
    final regExp = RegExp(
      r'(?:https?:\/\/)?(?:www\.|m\.)?(?:youtube\.com\/(?:watch\?v=|embed\/|v\/|shorts\/)|youtu\.be\/)([a-zA-Z0-9_-]{11})',
      caseSensitive: false,
    );
    final match = regExp.firstMatch(text);
    return match?.group(1);
  }

  String? get effectiveYoutubeId {
    if (youtubeId != null && youtubeId!.isNotEmpty) return youtubeId;
    return extractYoutubeId(content);
  }

  bool get isYoutube =>
      messageType == 'YOUTUBE' ||
      (youtubeId != null && youtubeId!.isNotEmpty) ||
      effectiveYoutubeId != null;

  bool get isAudio =>
      messageType == 'AUDIO' ||
      (mediaUrl != null &&
          (mediaUrl!.toLowerCase().endsWith('.m4a') ||
              mediaUrl!.toLowerCase().endsWith('.mp3') ||
              mediaUrl!.toLowerCase().endsWith('.aac') ||
              mediaUrl!.toLowerCase().endsWith('.wav') ||
              mediaUrl!.toLowerCase().endsWith('.ogg')));

  bool get isImage =>
      messageType == 'IMAGE' ||
      (mediaUrl != null &&
          !isAudio &&
          (mediaUrl!.toLowerCase().endsWith('.jpg') ||
              mediaUrl!.toLowerCase().endsWith('.jpeg') ||
              mediaUrl!.toLowerCase().endsWith('.png') ||
              mediaUrl!.toLowerCase().endsWith('.webp')));

  String? get youtubeThumbnailUrl {
    final yId = effectiveYoutubeId;
    if (yId != null && yId.isNotEmpty) {
      return 'https://img.youtube.com/vi/$yId/hqdefault.jpg';
    }
    return null;
  }

  String get formattedTime {
    final ist = createdAt.toUtc().add(const Duration(hours: 5, minutes: 30));
    final hour = ist.hour;
    final minute = ist.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour % 12 == 0 ? 12 : hour % 12;
    return '$displayHour:$minute $period';
  }

  factory BuyerChatMessage.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic val) {
      if (val == null) return DateTime.now().toUtc();
      if (val is DateTime) return val.toUtc();
      final str = val.toString().trim();
      final parsed = DateTime.tryParse(str.replaceAll(' ', 'T'));
      return parsed?.toUtc() ?? DateTime.now().toUtc();
    }

    final rawContent = json['content']?.toString() ?? '';
    final rawYt = (json['youtube_id'] ?? json['youtubeId'])?.toString();
    final finalYt = (rawYt != null && rawYt.isNotEmpty) ? rawYt : BuyerChatMessage.extractYoutubeId(rawContent);

    return BuyerChatMessage(
      id: json['id']?.toString() ?? '',
      conversationId: json['conversation_id']?.toString() ?? json['conversationId']?.toString() ?? '',
      buyerId: json['buyer_id']?.toString() ?? json['buyerId']?.toString() ?? '',
      senderType: json['sender_type']?.toString().toUpperCase() ?? json['senderType']?.toString().toUpperCase() ?? 'BUYER',
      messageType: json['message_type']?.toString().toUpperCase() ?? json['messageType']?.toString().toUpperCase() ?? 'TEXT',
      content: rawContent,
      mediaUrl: json['media_url']?.toString() ?? json['mediaUrl']?.toString(),
      youtubeId: finalYt,
      durationSeconds: int.tryParse((json['duration_seconds'] ?? json['durationSeconds'])?.toString() ?? '0') ?? 0,
      isRead: json['is_read'] == 1 || json['is_read'] == true || json['isRead'] == 1 || json['isRead'] == true,
      createdAt: parseDate(json['created_at'] ?? json['createdAt']),
    );
  }

  BuyerChatMessage copyWith({
    bool? isRead,
    String? content,
    String? mediaUrl,
    String? youtubeId,
    int? durationSeconds,
  }) {
    return BuyerChatMessage(
      id: id,
      conversationId: conversationId,
      buyerId: buyerId,
      senderType: senderType,
      messageType: messageType,
      content: content ?? this.content,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      youtubeId: youtubeId ?? this.youtubeId,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
    );
  }
}

class BuyerChatService {
  static final BuyerChatService instance = BuyerChatService._internal();
  BuyerChatService._internal();

  static const String _domainBase = 'https://reviewsgateway.in';
  static const String _apiBase = '$_domainBase/support-chat/api/support/buyer';

  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 15),
  ));

  IO.Socket? _socket;
  bool _isConnected = false;
  bool get isConnected => _isConnected;

  final _messageStreamController = StreamController<BuyerChatMessage>.broadcast();
  final _readStreamController = StreamController<Map<String, dynamic>>.broadcast();
  final _typingStreamController = StreamController<Map<String, dynamic>>.broadcast();
  final _messagesDeletedController = StreamController<List<String>>.broadcast();
  final _allMessagesDeletedController = StreamController<String>.broadcast();

  Stream<BuyerChatMessage> get onNewMessage => _messageStreamController.stream;
  Stream<Map<String, dynamic>> get onMessagesRead => _readStreamController.stream;
  Stream<Map<String, dynamic>> get onTyping => _typingStreamController.stream;
  Stream<List<String>> get onMessagesDeleted => _messagesDeletedController.stream;
  Stream<String> get onAllMessagesDeleted => _allMessagesDeletedController.stream;

  void initSocket(String buyerId) {
    if (_socket != null && _isConnected) return;

    try {
      debugPrint('[BuyerChatSocket] Connecting to $_domainBase for buyer: $buyerId...');
      _socket = IO.io(
        _domainBase,
        IO.OptionBuilder()
            .setTransports(['websocket', 'polling'])
            .setPath('/socket.io/')
            .enableAutoConnect()
            .enableReconnection()
            .setReconnectionDelay(2000)
            .setReconnectionAttempts(10)
            .build(),
      );

      _socket!.onConnect((_) {
        debugPrint('[BuyerChatSocket] Connected! Joining buyer room buyer_$buyerId');
        _isConnected = true;
        _socket!.emit('join', {'role': 'BUYER', 'buyerId': buyerId});
      });

      _socket!.on('new_buyer_message', (data) {
        try {
          if (data is Map) {
            final msg = BuyerChatMessage.fromJson(Map<String, dynamic>.from(data));
            _messageStreamController.add(msg);
          }
        } catch (e) {
          debugPrint('[BuyerChatSocket] Error parsing new_buyer_message: $e');
        }
      });

      _socket!.on('buyer_messages_read', (data) {
        if (data is Map) {
          _readStreamController.add(Map<String, dynamic>.from(data));
        }
      });

      _socket!.on('buyer_typing', (data) {
        if (data is Map) {
          _typingStreamController.add(Map<String, dynamic>.from(data));
        }
      });

      _socket!.on('messages_deleted', (data) {
        try {
          if (data is Map && data['messageIds'] != null) {
            final ids = (data['messageIds'] as List).map((e) => e.toString()).toList();
            _messagesDeletedController.add(ids);
          }
        } catch (e) {
          debugPrint('[BuyerChatSocket] Error parsing messages_deleted: $e');
        }
      });

      _socket!.on('all_messages_deleted', (data) {
        try {
          if (data is Map && data['conversationId'] != null) {
            _allMessagesDeletedController.add(data['conversationId'].toString());
          } else {
            _allMessagesDeletedController.add('ALL');
          }
        } catch (e) {
          debugPrint('[BuyerChatSocket] Error parsing all_messages_deleted: $e');
        }
      });

      _socket!.onDisconnect((_) {
        debugPrint('[BuyerChatSocket] Disconnected');
        _isConnected = false;
      });
    } catch (e) {
      debugPrint('[BuyerChatSocket] initSocket Exception: $e');
    }
  }

  Future<Map<String, dynamic>?> getChat(
    String buyerId, {
    String? name,
    String? email,
    String? phone,
    String? avatarUrl,
  }) async {
    try {
      final params = <String, dynamic>{};
      if (name != null) params['name'] = name;
      if (email != null) params['email'] = email;
      if (phone != null) params['phone'] = phone;
      if (avatarUrl != null) params['avatarUrl'] = avatarUrl;

      final res = await _dio.get('$_apiBase/$buyerId', queryParameters: params);
      if (res.statusCode == 200 && res.data != null) {
        final body = res.data is Map ? res.data : {};
        if (body['success'] == true && body['data'] != null) {
          final convId = body['data']['conversation']?['id']?.toString() ?? '';
          final msgs = (body['data']['messages'] as List)
              .map((m) => BuyerChatMessage.fromJson(Map<String, dynamic>.from(m)))
              .toList();
          return {'conversationId': convId, 'messages': msgs};
        }
      }
    } catch (e) {
      debugPrint('[BuyerChatService] getChat error: $e');
    }
    return null;
  }

  Future<BuyerChatMessage?> sendMessage({
    required String buyerId,
    String? conversationId,
    required String content,
  }) async {
    final payload = {
      'conversationId': conversationId,
      'buyerId': buyerId,
      'senderType': 'BUYER',
      'messageType': 'TEXT',
      'content': content,
    };

    if (_socket != null && _isConnected) {
      final completer = Completer<BuyerChatMessage?>();
      _socket!.emitWithAck('send_buyer_message', payload, ack: (response) {
        if (response != null && response['success'] == true && response['data'] != null) {
          final msg = BuyerChatMessage.fromJson(Map<String, dynamic>.from(response['data']));
          _messageStreamController.add(msg);
          if (!completer.isCompleted) completer.complete(msg);
        } else {
          if (!completer.isCompleted) completer.complete(null);
        }
      });

      try {
        final msg = await completer.future.timeout(const Duration(seconds: 4));
        if (msg != null) return msg;
      } catch (_) {}
    }

    // REST fallback
    try {
      final res = await _dio.post('$_apiBase/messages/send', data: payload);
      if (res.statusCode == 200 && res.data != null) {
        final body = res.data is Map ? res.data : {};
        if (body['success'] == true && body['data'] != null) {
          final msg = BuyerChatMessage.fromJson(body['data']);
          _messageStreamController.add(msg);
          return msg;
        }
      }
    } catch (e) {
      debugPrint('[BuyerChatService] sendMessage REST error: $e');
    }
    return null;
  }

  void markRead(String conversationId, String buyerId) {
    if (_socket != null && _isConnected) {
      _socket!.emit('mark_buyer_read', {
        'conversationId': conversationId,
        'buyerId': buyerId,
        'readerType': 'BUYER',
      });
    }

    try {
      _dio.post(
        '$_apiBase/conversations/$conversationId/read',
        data: {'readerType': 'BUYER'},
      ).catchError((_) => Response(requestOptions: RequestOptions()));
    } catch (_) {}
  }

  void sendTyping(String buyerId, bool isTyping) {
    if (_socket != null && _isConnected) {
      _socket!.emit('buyer_typing', {
        'buyerId': buyerId,
        'senderType': 'BUYER',
        'isTyping': isTyping,
      });
    }
  }

  Future<bool> registerFcmToken(String buyerId, String fcmToken) async {
    try {
      final res = await _dio.post(
        '$_apiBase/token',
        data: {
          'buyerId': buyerId,
          'token': fcmToken,
          'fcmToken': fcmToken,
        },
      );
      if (res.statusCode == 200) {
        debugPrint('[BuyerChatService] ✅ Registered FCM token with support-chat-engine for buyer $buyerId');
        return true;
      }
    } catch (e) {
      debugPrint('[BuyerChatService] ⚠️ registerFcmToken error: $e');
    }
    return false;
  }

  void dispose() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _isConnected = false;
  }
}

