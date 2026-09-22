import 'dart:async';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
// ignore: library_prefixes
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../models/worker_support_message.dart';
import 'support_media_cache.dart';

class WorkerChatService {
  static final WorkerChatService instance = WorkerChatService._internal();
  WorkerChatService._internal();

  static const String _domainBase = 'https://reviewsgateway.in';
  static const String _apiBase = '$_domainBase/support-chat/api/support';

  IO.Socket? _socket;
  bool _isConnected = false;
  bool get isConnected => _isConnected;

  String? _workerId;
  String? _conversationId;
  String? get conversationId => _conversationId;

  int _unreadCount = 0;
  int get unreadCount => _unreadCount;
  final _unreadCountController = StreamController<int>.broadcast();
  Stream<int> get onUnreadCountChanged => _unreadCountController.stream;

  final _messageStreamController = StreamController<WorkerSupportMessage>.broadcast();
  final _readStreamController = StreamController<void>.broadcast();
  final _messagesDeletedController = StreamController<List<String>>.broadcast();
  final _allMessagesDeletedController = StreamController<String>.broadcast();

  Stream<WorkerSupportMessage> get onNewMessage => _messageStreamController.stream;
  Stream<void> get onMessagesRead => _readStreamController.stream;
  Stream<List<String>> get onMessagesDeleted => _messagesDeletedController.stream;
  Stream<String> get onAllMessagesDeleted => _allMessagesDeletedController.stream;

  void clearUnreadCount() {
    _unreadCount = 0;
    _unreadCountController.add(0);
  }

  Future<String?> getWorkerId() async {
    if (_workerId != null && _workerId!.isNotEmpty) return _workerId;

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        _workerId = user.uid;
        return _workerId;
      }
    } catch (_) {}

    final prefs = await SharedPreferences.getInstance();
    _workerId = prefs.getString('user_id');
    return _workerId;
  }

  /// Initialize Socket.IO connection for Worker
  Future<void> initSocket() async {
    final workerId = await getWorkerId();
    if (workerId == null || workerId.isEmpty) return;
    if (_socket != null && _isConnected) return;

    try {
      debugPrint('[WorkerChatSocket] Connecting to $_domainBase for worker $workerId...');
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
        debugPrint('[WorkerChatSocket] Connected! Joining worker_$workerId room...');
        _isConnected = true;
        _socket!.emit('join', {'role': 'WORKER', 'workerId': workerId});
      });

      _socket!.on('new_message', (data) {
        try {
          if (data is Map) {
            final msg = WorkerSupportMessage.fromJson(Map<String, dynamic>.from(data));
            if (msg.senderType == 'ADMIN') {
              _unreadCount++;
              _unreadCountController.add(_unreadCount);
            }
            _messageStreamController.add(msg);
          }
        } catch (e) {
          debugPrint('[WorkerChatSocket] Error parsing new_message: $e');
        }
      });

      _socket!.on('messages_read', (_) {
        _readStreamController.add(null);
      });

      _socket!.on('messages_deleted', (data) {
        try {
          if (data is Map && data['messageIds'] != null) {
            final ids = (data['messageIds'] as List).map((e) => e.toString()).toList();
            _messagesDeletedController.add(ids);
          }
        } catch (e) {
          debugPrint('[WorkerChatSocket] Error parsing messages_deleted: $e');
        }
      });

      _socket!.on('all_messages_deleted', (data) {
        try {
          if (data is Map && data['conversationId'] != null) {
            _unreadCount = 0;
            _unreadCountController.add(0);
            _allMessagesDeletedController.add(data['conversationId'].toString());
          }
        } catch (e) {
          debugPrint('[WorkerChatSocket] Error parsing all_messages_deleted: $e');
        }
      });

      _socket!.onDisconnect((_) {
        debugPrint('[WorkerChatSocket] Disconnected.');
        _isConnected = false;
      });

      _socket!.onError((err) {
        debugPrint('[WorkerChatSocket] Error: $err');
      });
    } catch (e) {
      debugPrint('[WorkerChatSocket] Init error: $e');
    }
  }

  void disposeSocket() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _isConnected = false;
  }

  /// Fetch worker's conversation & messages
  /// Fetch cached messages locally from SharedPreferences (auto-prunes > 30 days old)
  Future<List<WorkerSupportMessage>> getCachedMessages() async {
    final workerId = await getWorkerId();
    if (workerId == null) return [];

    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedJson = prefs.getString('support_chat_cache_$workerId');
      if (cachedJson != null && cachedJson.isNotEmpty) {
        final List list = jsonDecode(cachedJson);
        final oneMonthAgo = DateTime.now().subtract(const Duration(days: 30));
        final validMsgs = <WorkerSupportMessage>[];

        for (final item in list) {
          final msg = WorkerSupportMessage.fromJson(Map<String, dynamic>.from(item));
          if (msg.createdAt.isAfter(oneMonthAgo)) {
            validMsgs.add(msg);
          }
        }
        debugPrint('[WorkerChatService] Loaded ${validMsgs.length} messages from local cache');
        return validMsgs;
      }
    } catch (e) {
      debugPrint('[WorkerChatService] getCachedMessages error: $e');
    }
    return [];
  }

  /// Save messages to SharedPreferences cache (auto-prunes > 30 days old)
  Future<void> saveMessagesToCache(List<WorkerSupportMessage> messages) async {
    final workerId = await getWorkerId();
    if (workerId == null) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final oneMonthAgo = DateTime.now().subtract(const Duration(days: 30));
      final recentMsgs = messages.where((m) => m.createdAt.isAfter(oneMonthAgo)).toList();
      final list = recentMsgs.map((m) => m.toJson()).toList();
      await prefs.setString('support_chat_cache_$workerId', jsonEncode(list));
    } catch (e) {
      debugPrint('[WorkerChatService] saveMessagesToCache error: $e');
    }
  }

  /// Fetch worker's conversation & messages from server, then update cache
  Future<List<WorkerSupportMessage>> getChatHistory() async {
    final workerId = await getWorkerId();
    if (workerId == null) return [];

    // Trigger media cache purge in background (> 30 days old)
    SupportMediaCache.instance.purgeExpiredCache().ignore();

    try {
      final uri = Uri.parse('$_apiBase/worker/$workerId');
      final res = await http.get(uri).timeout(const Duration(seconds: 8));

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        if (body['success'] == true && body['data'] != null) {
          _conversationId = body['data']['conversation']?['id']?.toString();
          final count = int.tryParse(body['data']['conversation']?['unread_worker_count']?.toString() ?? '0') ?? 0;
          _unreadCount = count;
          _unreadCountController.add(_unreadCount);
          final List rawMsgs = body['data']['messages'] ?? [];
          final msgs = rawMsgs.map((j) => WorkerSupportMessage.fromJson(j)).toList();

          // Persist fresh messages to cache
          await saveMessagesToCache(msgs);
          return msgs;
        }
      }
    } catch (e) {
      debugPrint('[WorkerChatService] getChatHistory error: $e');
    }

    // If network error, fallback to local cache
    return getCachedMessages();
  }

  /// Send text message (Worker can ONLY send text messages)
  Future<WorkerSupportMessage?> sendTextMessage(String text) async {
    final workerId = await getWorkerId();
    if (workerId == null || text.trim().isEmpty) return null;

    final payload = {
      'conversationId': _conversationId,
      'workerId': workerId,
      'senderType': 'WORKER',
      'messageType': 'TEXT',
      'content': text.trim(),
    };

    // Try Socket emit first
    if (_socket != null && _isConnected) {
      final completer = Completer<WorkerSupportMessage?>();
      _socket!.emitWithAck('send_message', payload, ack: (response) {
        if (response != null && response['success'] == true && response['data'] != null) {
          completer.complete(WorkerSupportMessage.fromJson(response['data']));
        } else {
          completer.complete(null);
        }
      });

      try {
        final result = await completer.future.timeout(const Duration(milliseconds: 1500));
        if (result != null) return result;
      } catch (_) {}
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
          final msg = WorkerSupportMessage.fromJson(body['data']);
          _messageStreamController.add(msg);
          return msg;
        }
      }
    } catch (e) {
      debugPrint('[WorkerChatService] sendTextMessage REST error: $e');
    }
    return null;
  }

  /// Fetch current unread messages count for worker
  Future<int> fetchUnreadCount() async {
    final workerId = await getWorkerId();
    if (workerId == null || workerId.isEmpty) return _unreadCount;

    try {
      final uri = Uri.parse('$_apiBase/worker/$workerId');
      final res = await http.get(uri).timeout(const Duration(seconds: 6));

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        if (body['success'] == true && body['data'] != null) {
          _conversationId = body['data']['conversation']?['id']?.toString();
          final count = int.tryParse(body['data']['conversation']?['unread_worker_count']?.toString() ?? '0') ?? 0;
          _unreadCount = count;
          _unreadCountController.add(_unreadCount);
          return _unreadCount;
        }
      }
    } catch (e) {
      debugPrint('[WorkerChatService] fetchUnreadCount error: $e');
    }
    return _unreadCount;
  }

  /// Mark messages as read
  Future<void> markRead() async {
    _unreadCount = 0;
    _unreadCountController.add(0);

    if (_conversationId == null) return;
    final workerId = await getWorkerId();

    if (_socket != null && _isConnected) {
      _socket!.emit('mark_read', {
        'conversationId': _conversationId,
        'workerId': workerId,
        'readerType': 'WORKER',
      });
    }

    try {
      final uri = Uri.parse('$_apiBase/conversations/$_conversationId/read');
      await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'readerType': 'WORKER'}),
      );
    } catch (_) {}
  }
}
