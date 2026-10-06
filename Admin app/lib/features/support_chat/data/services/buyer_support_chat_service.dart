import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../models/buyer_support_conversation_model.dart';
import '../models/buyer_support_message_model.dart';

class BuyerSupportChatService {
  static final BuyerSupportChatService instance = BuyerSupportChatService._internal();
  BuyerSupportChatService._internal();

  // Server Base URLs
  static const String _domainBase = 'https://reviewsgateway.in';
  static const String _apiBase = '$_domainBase/support-chat/api/support/buyer';
  static const String _rootSupportApiBase = '$_domainBase/support-chat/api/support';
  static const String _cloudflareChatMediaUrl =
      'https://earnpost-chat-media-worker.zestbizar.workers.dev/upload';

  IO.Socket? _socket;
  bool _isConnected = false;
  bool get isConnected => _isConnected;

  // Real-time Event Streams
  final _messageStreamController = StreamController<BuyerSupportMessageModel>.broadcast();
  final _conversationStreamController = StreamController<BuyerSupportConversationModel>.broadcast();
  final _readStreamController = StreamController<Map<String, dynamic>>.broadcast();
  final _typingStreamController = StreamController<Map<String, dynamic>>.broadcast();
  final _messagesDeletedController = StreamController<List<String>>.broadcast();
  final _allMessagesDeletedController = StreamController<String>.broadcast();
  final _conversationsDeletedController = StreamController<List<String>>.broadcast();

  Stream<BuyerSupportMessageModel> get onNewMessage => _messageStreamController.stream;
  Stream<BuyerSupportConversationModel> get onConversationUpdated => _conversationStreamController.stream;
  Stream<Map<String, dynamic>> get onMessagesRead => _readStreamController.stream;
  Stream<Map<String, dynamic>> get onTyping => _typingStreamController.stream;
  Stream<List<String>> get onMessagesDeleted => _messagesDeletedController.stream;
  Stream<String> get onAllMessagesDeleted => _allMessagesDeletedController.stream;
  Stream<List<String>> get onConversationsDeleted => _conversationsDeletedController.stream;

  /// Initialize Socket.IO connection for Buyer Admin Room
  void initSocket() {
    if (_socket != null && _isConnected) return;

    try {
      debugPrint('[AdminBuyerChatSocket] Connecting to $_domainBase...');
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
        debugPrint('[AdminBuyerChatSocket] Connected! Joining admin rooms...');
        _isConnected = true;
        _socket!.emit('join', {'role': 'ADMIN'});
      });

      _socket!.on('new_buyer_message', (data) {
        try {
          if (data is Map) {
            final msg = BuyerSupportMessageModel.fromJson(Map<String, dynamic>.from(data));
            _messageStreamController.add(msg);
          }
        } catch (e) {
          debugPrint('[AdminBuyerChatSocket] Error parsing new_buyer_message: $e');
        }
      });

      _socket!.on('buyer_conversation_updated', (data) {
        try {
          if (data is Map) {
            final conv = BuyerSupportConversationModel.fromJson(Map<String, dynamic>.from(data));
            _conversationStreamController.add(conv);
          }
        } catch (e) {
          debugPrint('[AdminBuyerChatSocket] Error parsing buyer_conversation_updated: $e');
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

      void handleMsgDel(dynamic data) {
        try {
          if (data is Map && data['messageIds'] != null) {
            final ids = (data['messageIds'] as List).map((e) => e.toString()).toList();
            _messagesDeletedController.add(ids);
          }
        } catch (e) {
          debugPrint('[AdminBuyerChatSocket] Error parsing messages_deleted: $e');
        }
      }
      _socket!.on('messages_deleted', handleMsgDel);
      _socket!.on('buyer_messages_deleted', handleMsgDel);

      void handleAllDel(dynamic data) {
        try {
          if (data is Map && data['conversationId'] != null) {
            _allMessagesDeletedController.add(data['conversationId'].toString());
          }
        } catch (e) {
          debugPrint('[AdminBuyerChatSocket] Error parsing all_messages_deleted: $e');
        }
      }
      _socket!.on('all_messages_deleted', handleAllDel);
      _socket!.on('buyer_all_messages_deleted', handleAllDel);

      void handleConvDel(dynamic data) {
        try {
          if (data is Map && data['conversationIds'] != null) {
            final ids = (data['conversationIds'] as List).map((e) => e.toString()).toList();
            _conversationsDeletedController.add(ids);
          }
        } catch (e) {
          debugPrint('[AdminBuyerChatSocket] Error parsing conversations_deleted: $e');
        }
      }
      _socket!.on('conversations_deleted', handleConvDel);
      _socket!.on('buyer_conversations_deleted', handleConvDel);

      _socket!.onDisconnect((_) {
        debugPrint('[AdminBuyerChatSocket] Disconnected');
        _isConnected = false;
      });

      _socket!.onError((err) {
        debugPrint('[AdminBuyerChatSocket] Socket Error: $err');
      });
    } catch (e) {
      debugPrint('[AdminBuyerChatSocket] initSocket Exception: $e');
    }
  }

  // ──────────────── REST API METHODS ────────────────

  /// Fetch all buyer conversations (Buyer-Only, with search)
  Future<List<BuyerSupportConversationModel>> getConversations({
    String search = '',
    int limit = 100,
    int offset = 0,
  }) async {
    try {
      final uri = Uri.parse('$_apiBase/conversations').replace(queryParameters: {
        'search': search,
        'limit': limit.toString(),
        'offset': offset.toString(),
      });

      final res = await http.get(uri).timeout(const Duration(seconds: 15));
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        if (body['success'] == true && body['data'] != null) {
          final list = (body['data'] as List)
              .map((item) => BuyerSupportConversationModel.fromJson(Map<String, dynamic>.from(item)))
              .toList();
          return list;
        }
      }
    } catch (e) {
      debugPrint('[BuyerChatService] getConversations error: $e');
    }
    return [];
  }

  /// Fetch messages for a specific buyer conversation
  Future<List<BuyerSupportMessageModel>> getMessages(
    String conversationId, {
    int limit = 100,
    int offset = 0,
  }) async {
    try {
      final uri = Uri.parse('$_apiBase/conversations/$conversationId/messages').replace(
        queryParameters: {
          'limit': limit.toString(),
          'offset': offset.toString(),
        },
      );

      final res = await http.get(uri).timeout(const Duration(seconds: 15));
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        if (body['success'] == true && body['data'] != null) {
          final list = (body['data'] as List)
              .map((item) => BuyerSupportMessageModel.fromJson(Map<String, dynamic>.from(item)))
              .toList();
          return list;
        }
      }
    } catch (e) {
      debugPrint('[BuyerChatService] getMessages error: $e');
    }
    return [];
  }

  /// Get or create conversation directly by buyerId
  Future<Map<String, dynamic>?> getBuyerChat(
    String buyerId, {
    String? name,
    String? email,
    String? phone,
    String? avatarUrl,
  }) async {
    try {
      final params = <String, String>{};
      if (name != null) params['name'] = name;
      if (email != null) params['email'] = email;
      if (phone != null) params['phone'] = phone;
      if (avatarUrl != null) params['avatarUrl'] = avatarUrl;

      final uri = Uri.parse('$_apiBase/$buyerId').replace(queryParameters: params);
      final res = await http.get(uri).timeout(const Duration(seconds: 15));
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        if (body['success'] == true && body['data'] != null) {
          final conv = BuyerSupportConversationModel.fromJson(body['data']['conversation']);
          final msgs = (body['data']['messages'] as List)
              .map((m) => BuyerSupportMessageModel.fromJson(Map<String, dynamic>.from(m)))
              .toList();
          return {'conversation': conv, 'messages': msgs};
        }
      }
    } catch (e) {
      debugPrint('[BuyerChatService] getBuyerChat error: $e');
    }
    return null;
  }

  /// Send message as Admin to a Buyer
  Future<BuyerSupportMessageModel?> sendMessage({
    required String buyerId,
    String? conversationId,
    required String content,
    String messageType = 'TEXT',
    String? mediaUrl,
    String? youtubeId,
    int durationSeconds = 0,
  }) async {
    final payload = {
      'conversationId': conversationId,
      'buyerId': buyerId,
      'senderType': 'ADMIN',
      'messageType': messageType,
      'content': content,
      'mediaUrl': mediaUrl,
      'youtubeId': youtubeId,
      'durationSeconds': durationSeconds,
    };

    // 1. Try real-time Socket.IO first
    if (_socket != null && _isConnected) {
      final completer = Completer<BuyerSupportMessageModel?>();
      _socket!.emitWithAck('send_buyer_message', payload, ack: (response) {
        if (response != null && response['success'] == true && response['data'] != null) {
          final msg = BuyerSupportMessageModel.fromJson(Map<String, dynamic>.from(response['data']));
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

    // 2. Fallback to REST API
    try {
      final res = await http
          .post(
            Uri.parse('$_apiBase/messages/send'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 15));

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        if (body['success'] == true && body['data'] != null) {
          final msg = BuyerSupportMessageModel.fromJson(body['data']);
          _messageStreamController.add(msg);
          return msg;
        }
      }
    } catch (e) {
      debugPrint('[BuyerChatService] sendMessage REST error: $e');
    }
    return null;
  }

  /// Mark conversation as read by Admin
  void markRead(String conversationId, String buyerId) {
    if (_socket != null && _isConnected) {
      _socket!.emit('mark_buyer_read', {
        'conversationId': conversationId,
        'buyerId': buyerId,
        'readerType': 'ADMIN',
      });
    }

    // Also call REST fallback silently
    try {
      http
          .post(
            Uri.parse('$_apiBase/conversations/$conversationId/read'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'readerType': 'ADMIN'}),
          )
          .catchError((_) => http.Response('', 500));
    } catch (_) {}
  }

  /// Send typing indicator
  void sendTyping(String buyerId, bool isTyping) {
    if (_socket != null && _isConnected) {
      _socket!.emit('buyer_typing', {
        'buyerId': buyerId,
        'senderType': 'ADMIN',
        'isTyping': isTyping,
      });
    }
  }

  /// Upload media (image / voice audio file) directly to Cloudflare R2 or server fallback
  Future<String?> uploadMedia(File file) async {
    // 1. Try dedicated Cloudflare Chat Media Worker first
    try {
      final uri = Uri.parse(_cloudflareChatMediaUrl);
      final request = http.MultipartRequest('POST', uri);
      request.files.add(await http.MultipartFile.fromPath('file', file.path));

      final streamedResponse = await request.send().timeout(const Duration(seconds: 30));
      final res = await http.Response.fromStream(streamedResponse);

      if (res.statusCode == 200 || res.statusCode == 201) {
        final body = jsonDecode(res.body);
        if (body['success'] == true && (body['url'] != null || body['publicUrl'] != null)) {
          final publicUrl = (body['url'] ?? body['publicUrl']) as String;
          debugPrint('[BuyerChatService] Cloudflare R2 Upload Success: $publicUrl');
          return publicUrl;
        }
      }
    } catch (e) {
      debugPrint('[BuyerChatService] Cloudflare Worker upload error: $e, falling back to server...');
    }

    // 2. Server fallback
    try {
      final uri = Uri.parse('$_rootSupportApiBase/upload');
      final request = http.MultipartRequest('POST', uri);
      request.files.add(await http.MultipartFile.fromPath('file', file.path));

      final streamedResponse = await request.send().timeout(const Duration(seconds: 30));
      final res = await http.Response.fromStream(streamedResponse);

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        if (body['success'] == true && body['url'] != null) {
          final serverUrl = body['url'] as String;
          final fullUrl = serverUrl.startsWith('http') ? serverUrl : '$_domainBase$serverUrl';
          return fullUrl;
        }
      }
    } catch (e) {
      debugPrint('[BuyerChatService] Server fallback upload error: $e');
    }
    return null;
  }

  /// Delete messages
  Future<bool> deleteMessages(List<String> messageIds, {String? conversationId}) async {
    try {
      final res = await http.post(
        Uri.parse('$_apiBase/messages/delete'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'messageIds': messageIds, 'conversationId': conversationId}),
      );
      if (res.statusCode == 200) {
        _messagesDeletedController.add(messageIds);
        return true;
      }
    } catch (e) {
      debugPrint('[BuyerChatService] deleteMessages error: $e');
    }
    return false;
  }

  /// Clear all messages in a conversation
  Future<bool> clearConversationMessages(String conversationId) async {
    try {
      final res = await http.delete(
        Uri.parse('$_apiBase/conversations/$conversationId/messages'),
      );
      if (res.statusCode == 200) {
        _allMessagesDeletedController.add(conversationId);
        return true;
      }
    } catch (e) {
      debugPrint('[BuyerChatService] clearConversationMessages error: $e');
    }
    return false;
  }

  /// Delete entire conversations
  Future<bool> deleteConversations(List<String> conversationIds) async {
    try {
      final res = await http.post(
        Uri.parse('$_apiBase/conversations/delete'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'conversationIds': conversationIds}),
      );
      if (res.statusCode == 200) {
        _conversationsDeletedController.add(conversationIds);
        return true;
      }
    } catch (e) {
      debugPrint('[BuyerChatService] deleteConversations error: $e');
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
