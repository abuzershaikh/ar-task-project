import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../models/support_conversation_model.dart';
import '../models/support_message_model.dart';

class SupportChatService {
  static final SupportChatService instance = SupportChatService._internal();
  SupportChatService._internal();

  // Server Base URLs
  static const String _domainBase = 'https://reviewsgateway.in';
  static const String _apiBase = '$_domainBase/support-chat/api/support';

  IO.Socket? _socket;
  bool _isConnected = false;
  bool get isConnected => _isConnected;

  // Event streams for real-time reactive UI
  final _messageStreamController = StreamController<SupportMessageModel>.broadcast();
  final _conversationStreamController = StreamController<SupportConversationModel>.broadcast();
  final _readStreamController = StreamController<Map<String, dynamic>>.broadcast();
  final _messagesDeletedController = StreamController<List<String>>.broadcast();
  final _allMessagesDeletedController = StreamController<String>.broadcast();
  final _conversationsDeletedController = StreamController<List<String>>.broadcast();
  final _allConversationsDeletedController = StreamController<void>.broadcast();

  Stream<SupportMessageModel> get onNewMessage => _messageStreamController.stream;
  Stream<SupportConversationModel> get onConversationUpdated => _conversationStreamController.stream;
  Stream<Map<String, dynamic>> get onMessagesRead => _readStreamController.stream;
  Stream<List<String>> get onMessagesDeleted => _messagesDeletedController.stream;
  Stream<String> get onAllMessagesDeleted => _allMessagesDeletedController.stream;
  Stream<List<String>> get onConversationsDeleted => _conversationsDeletedController.stream;
  Stream<void> get onAllConversationsDeleted => _allConversationsDeletedController.stream;

  /// Initialize Socket.IO connection
  void initSocket() {
    if (_socket != null && _isConnected) return;

    try {
      debugPrint('[AdminChatSocket] Connecting to $_domainBase...');
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
        debugPrint('[AdminChatSocket] Connected! Joining admin_support room...');
        _isConnected = true;
        _socket!.emit('join', {'role': 'ADMIN'});
      });

      _socket!.on('new_message', (data) {
        try {
          if (data is Map) {
            final msg = SupportMessageModel.fromJson(Map<String, dynamic>.from(data));
            _messageStreamController.add(msg);
          }
        } catch (e) {
          debugPrint('[AdminChatSocket] Error parsing new_message: $e');
        }
      });

      _socket!.on('conversation_updated', (data) {
        try {
          if (data is Map) {
            final conv = SupportConversationModel.fromJson(Map<String, dynamic>.from(data));
            _conversationStreamController.add(conv);
          }
        } catch (e) {
          debugPrint('[AdminChatSocket] Error parsing conversation_updated: $e');
        }
      });

      _socket!.on('messages_read', (data) {
        if (data is Map) {
          _readStreamController.add(Map<String, dynamic>.from(data));
        }
      });

      _socket!.on('messages_deleted', (data) {
        try {
          if (data is Map && data['messageIds'] != null) {
            final ids = (data['messageIds'] as List).map((e) => e.toString()).toList();
            _messagesDeletedController.add(ids);
          }
        } catch (e) {
          debugPrint('[AdminChatSocket] Error parsing messages_deleted: $e');
        }
      });

      _socket!.on('all_messages_deleted', (data) {
        try {
          if (data is Map && data['conversationId'] != null) {
            _allMessagesDeletedController.add(data['conversationId'].toString());
          }
        } catch (e) {
          debugPrint('[AdminChatSocket] Error parsing all_messages_deleted: $e');
        }
      });

      _socket!.on('conversations_deleted', (data) {
        try {
          if (data is Map && data['conversationIds'] != null) {
            final ids = (data['conversationIds'] as List).map((e) => e.toString()).toList();
            _conversationsDeletedController.add(ids);
          }
        } catch (e) {
          debugPrint('[AdminChatSocket] Error parsing conversations_deleted: $e');
        }
      });

      _socket!.on('all_conversations_deleted', (_) {
        _allConversationsDeletedController.add(null);
      });

      _socket!.onDisconnect((_) {
        debugPrint('[AdminChatSocket] Disconnected.');
        _isConnected = false;
      });

      _socket!.onError((err) {
        debugPrint('[AdminChatSocket] Socket Error: $err');
      });
    } catch (e) {
      debugPrint('[AdminChatSocket] Initialization error: $e');
    }
  }

  /// Disconnect socket
  void disposeSocket() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _isConnected = false;
  }

  /// Fetch WhatsApp-like conversations list
  Future<Map<String, dynamic>> getConversations({String search = '', int limit = 50}) async {
    try {
      final uri = Uri.parse('$_apiBase/conversations?search=${Uri.encodeComponent(search)}&limit=$limit');
      final res = await http.get(uri).timeout(const Duration(seconds: 8));

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        if (body['success'] == true && body['data'] != null) {
          final List rawList = body['data']['conversations'] ?? [];
          final convs = rawList.map((j) => SupportConversationModel.fromJson(j)).toList();
          final totalUnread = body['data']['totalUnread'] ?? 0;
          return {
            'conversations': convs,
            'totalUnread': totalUnread,
          };
        }
      }
    } catch (e) {
      debugPrint('[AdminChatService] getConversations error: $e');
    }
    return {'conversations': <SupportConversationModel>[], 'totalUnread': 0};
  }

  /// Fetch messages for a conversation
  Future<List<SupportMessageModel>> getMessages(String conversationId, {int limit = 100}) async {
    try {
      final uri = Uri.parse('$_apiBase/conversations/$conversationId/messages?limit=$limit');
      final res = await http.get(uri).timeout(const Duration(seconds: 8));

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        if (body['success'] == true && body['data'] is List) {
          return (body['data'] as List).map((j) => SupportMessageModel.fromJson(j)).toList();
        }
      }
    } catch (e) {
      debugPrint('[AdminChatService] getMessages error: $e');
    }
    return [];
  }

  /// Send message via Socket or REST fallback
  Future<SupportMessageModel?> sendMessage({
    required String conversationId,
    required String workerId,
    required String messageType, // 'TEXT' | 'IMAGE' | 'AUDIO' | 'YOUTUBE'
    required String content,
    String? mediaUrl,
    String? youtubeId,
    int durationSeconds = 0,
  }) async {
    final payload = {
      'conversationId': conversationId,
      'workerId': workerId,
      'senderType': 'ADMIN',
      'messageType': messageType,
      'content': content,
      if (mediaUrl != null) 'mediaUrl': mediaUrl,
      if (youtubeId != null) 'youtubeId': youtubeId,
      'durationSeconds': durationSeconds,
    };

    // Try Socket emit first for real-time speed
    if (_socket != null && _isConnected) {
      final completer = Completer<SupportMessageModel?>();
      _socket!.emitWithAck('send_message', payload, ack: (response) {
        if (response != null && response['success'] == true && response['data'] != null) {
          completer.complete(SupportMessageModel.fromJson(response['data']));
        } else {
          completer.complete(null);
        }
      });

      try {
        final result = await completer.future.timeout(const Duration(milliseconds: 1500));
        if (result != null) return result;
      } catch (_) {
        // Fallback to REST
      }
    }

    // REST fallback
    try {
      final uri = Uri.parse('$_apiBase/messages/send');
      final res = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 8));

      if (res.statusCode == 200 || res.statusCode == 201) {
        final body = jsonDecode(res.body);
        if (body['success'] == true && body['data'] != null) {
          final msg = SupportMessageModel.fromJson(body['data']);
          _messageStreamController.add(msg);
          return msg;
        }
      }
    } catch (e) {
      debugPrint('[AdminChatService] sendMessage REST error: $e');
    }
    return null;
  }

  static const String _cloudflareChatMediaUrl =
      'https://earnpost-chat-media-worker.zestbizar.workers.dev/upload';

  /// Upload media (image / voice audio file) directly to Cloudflare R2
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
          debugPrint('[AdminChatService] Cloudflare R2 Upload Success: $publicUrl');
          return publicUrl;
        }
      }
    } catch (e) {
      debugPrint('[AdminChatService] Cloudflare Worker upload error: $e, falling back to server...');
    }

    // 2. Server fallback
    try {
      final uri = Uri.parse('$_apiBase/upload');
      final request = http.MultipartRequest('POST', uri);
      request.files.add(await http.MultipartFile.fromPath('file', file.path));

      final streamedResponse = await request.send().timeout(const Duration(seconds: 30));
      final res = await http.Response.fromStream(streamedResponse);

      if (res.statusCode == 200 || res.statusCode == 201) {
        final body = jsonDecode(res.body);
        if (body['success'] == true && body['data']?['url'] != null) {
          return body['data']['url'] as String;
        }
      }
    } catch (e) {
      debugPrint('[AdminChatService] uploadMedia server fallback error: $e');
    }
    return null;
  }

  /// Mark conversation as read
  Future<void> markRead(String conversationId, String workerId) async {
    if (_socket != null && _isConnected) {
      _socket!.emit('mark_read', {
        'conversationId': conversationId,
        'workerId': workerId,
        'readerType': 'ADMIN',
      });
    }

    try {
      final uri = Uri.parse('$_apiBase/conversations/$conversationId/read');
      await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'readerType': 'ADMIN'}),
      );
    } catch (_) {}
  }

  /// Bulk Broadcast to segment
  Future<Map<String, dynamic>> sendBulkMessage({
    required String segment, // 'ALL' | 'NEW' | 'ACTIVE' | 'CUSTOM'
    List<String>? customWorkerIds,
    required String messageType,
    required String content,
    String? mediaUrl,
    String? youtubeId,
    int durationSeconds = 0,
  }) async {
    try {
      final uri = Uri.parse('$_apiBase/messages/bulk');
      final res = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'segment': segment,
          'customWorkerIds': customWorkerIds,
          'messageType': messageType,
          'content': content,
          'mediaUrl': mediaUrl,
          'youtubeId': youtubeId,
          'durationSeconds': durationSeconds,
        }),
      ).timeout(const Duration(seconds: 20));

      if (res.statusCode == 200 || res.statusCode == 201) {
        final body = jsonDecode(res.body);
        if (body['success'] == true) {
          return body['data'] ?? {'success': true};
        }
      }
    } catch (e) {
      debugPrint('[AdminChatService] sendBulkMessage error: $e');
    }
    return {'success': false};
  }

  /// Get filterable worker list for sorting & selection
  Future<Map<String, dynamic>> getFilterableWorkers({
    String search = '',
    String segment = 'ALL',
    int limit = 100,
  }) async {
    // Retry up to 2 times on failure for resilience
    for (int attempt = 0; attempt < 2; attempt++) {
      try {
        final uri = Uri.parse('$_apiBase/workers/filterable?search=${Uri.encodeComponent(search)}&segment=$segment&limit=$limit');
        final res = await http.get(uri).timeout(const Duration(seconds: 12));

        if (res.statusCode == 200) {
          final body = jsonDecode(res.body);
          if (body['success'] == true && body['data'] != null) {
            debugPrint('[AdminChatService] getFilterableWorkers SUCCESS: ${(body['data']['workers'] as List?)?.length ?? 0} workers');
            return body['data'];
          }
        }
        debugPrint('[AdminChatService] getFilterableWorkers attempt ${attempt + 1} failed: status=${res.statusCode}');
      } catch (e) {
        debugPrint('[AdminChatService] getFilterableWorkers attempt ${attempt + 1} error: $e');
        if (attempt < 1) {
          await Future.delayed(const Duration(milliseconds: 500)); // Brief delay before retry
        }
      }
    }
    return {'workers': [], 'counts': {'total_count': 0, 'new_count': 0, 'active_count': 0}};
  }

  /// Delete specific messages by IDs (single or bulk) — permanently from SQL
  Future<Map<String, dynamic>> deleteMessages(List<String> messageIds) async {
    try {
      final uri = Uri.parse('$_apiBase/messages/delete');
      final res = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'messageIds': messageIds}),
      ).timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        if (body['success'] == true) {
          debugPrint('[AdminChatService] Deleted ${messageIds.length} messages successfully');
          return body['data'] ?? {'success': true, 'deleted': messageIds.length};
        }
      }
    } catch (e) {
      debugPrint('[AdminChatService] deleteMessages error: $e');
    }
    return {'success': false, 'deleted': 0};
  }

  /// Delete ALL messages in a conversation — permanently from SQL
  Future<Map<String, dynamic>> deleteAllConversationMessages(String conversationId) async {
    try {
      final uri = Uri.parse('$_apiBase/conversations/$conversationId/messages');
      final res = await http.delete(uri).timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        if (body['success'] == true) {
          debugPrint('[AdminChatService] Deleted all messages from conversation $conversationId');
          return body['data'] ?? {'success': true};
        }
      }
    } catch (e) {
      debugPrint('[AdminChatService] deleteAllConversationMessages error: $e');
    }
    return {'success': false, 'deleted': 0};
  }

  /// Delete multiple conversations & their messages (bulk delete from chat list)
  Future<Map<String, dynamic>> deleteConversations(List<String> conversationIds) async {
    try {
      final uri = Uri.parse('$_apiBase/conversations/delete-bulk');
      final res = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'conversationIds': conversationIds}),
      ).timeout(const Duration(seconds: 12));

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        if (body['success'] == true) {
          debugPrint('[AdminChatService] Bulk deleted ${conversationIds.length} conversations');
          return body['data'] ?? {'success': true};
        }
      }
    } catch (e) {
      debugPrint('[AdminChatService] deleteConversations error: $e');
    }
    return {'success': false};
  }

  /// Delete ALL messages and conversations for ALL workers (complete wipe from SQL)
  Future<Map<String, dynamic>> deleteAllWorkersChats() async {
    try {
      final uri = Uri.parse('$_apiBase/conversations/delete-all');
      final res = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 15));

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        if (body['success'] == true) {
          debugPrint('[AdminChatService] Deleted ALL chats for ALL workers successfully');
          return body['data'] ?? {'success': true};
        }
      }
    } catch (e) {
      debugPrint('[AdminChatService] deleteAllWorkersChats error: $e');
    }
    return {'success': false};
  }

}
