import 'dart:developer' as dev;
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChatService {
  ChatService._();
  static final ChatService instance = ChatService._();
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> getMessages(String chatId, {
    int limit = 50,
    DateTime? before,
  }) async {
    try {
      // تنظيف chat_id من البادئات المحتملة
      String cleanChatId = chatId;
      if (chatId.startsWith('booking_')) {
        cleanChatId = chatId.substring(8); // إزالة 'booking_'
      }
      
      PostgrestFilterBuilder query = _supabase
          .from('messages')
          .select()
          .eq('chat_id', cleanChatId);
      
      // إضافة فلتر التاريخ للتحميل التدريجي
      if (before != null) {
        query = query.lt('created_at', before.toIso8601String());
      }
      
      final res = await query
          .order('created_at', ascending: false)
          .limit(limit);
      final messages = (res as List).cast<Map<String, dynamic>>();
      
      return messages;
    } catch (e) {
      dev.log('getMessages error: $e', name: 'ChatService');
      return [];
    }
  }

  // تحميل المزيد من الرسائل القديمة
  Future<List<Map<String, dynamic>>> getOlderMessages(String chatId, DateTime before, {
    int limit = 50,
  }) async {
    return getMessages(chatId, limit: limit, before: before);
  }

  Future<bool> sendMessage({
    required String chatId,
    required String content,
  }) async {
    try {
      // تنظيف chat_id من البادئات المحتملة
      String cleanChatId = chatId;
      if (chatId.startsWith('booking_')) {
        cleanChatId = chatId.substring(8); // إزالة 'booking_'
      }
      
      debugPrint('🚀 [ChatService] Sending message to chat: $cleanChatId');
      
      // استخدام RPC endpoint الآمن بدلاً من insert مباشر
      final result = await _supabase.rpc('rpc_send_message', params: {
        'chat_id': cleanChatId,
        'content': content,
      });
      
      // فحص نتيجة الإرسال
      if (result != null && result['success'] == true) {
        debugPrint('✅ [ChatService] Message sent successfully: ${result['message_id']}');
        return true;
      } else {
        debugPrint('❌ [ChatService] Failed to send message: ${result?['error'] ?? 'Unknown error'}');
        return false;
      }
    } catch (e) {
      debugPrint('🔍 [ChatService] sendMessage error: $e');
      dev.log('sendMessage error: $e', name: 'ChatService');
      return false;
    }
  }

  RealtimeChannel? subscribeToMessages({
    required String chatId,
    required Function(Map<String, dynamic>) onInsert,
  }) {
    try {
      // تنظيف chat_id من البادئات المحتملة
      String cleanChatId = chatId;
      if (chatId.startsWith('booking_')) {
        cleanChatId = chatId.substring(8);
      }
      
      return _supabase
          .channel('messages:$cleanChatId')
          .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: 'messages',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'chat_id',
              value: cleanChatId,
            ),
            callback: (payload) {
              debugPrint('🔍 [Realtime] Message payload received: ${payload.newRecord}');
              final newRecord = payload.newRecord;
              if (newRecord.isNotEmpty) {
                onInsert(newRecord);
              }
            },
          )
          .subscribe((status, [ref]) {
            debugPrint('🔍 [Realtime] Channel status: $status');
          });
    } catch (e) {
      dev.log('subscribeToMessages error: $e', name: 'ChatService');
      return null;
    }
  }

  // تحديث آخر ظهور للمستخدم
  Future<bool> updateLastSeen() async {
    try {
      final response = await _supabase.rpc('rpc_update_last_seen');
      return response['success'] == true;
    } catch (e) {
      dev.log('updateLastSeen error: $e', name: 'ChatService');
      return false;
    }
  }

  // الحصول على معلومات المستخدم مع آخر ظهور
  Future<Map<String, dynamic>?> getUserInfo(String userId) async {
    try {
      final response = await _supabase.rpc('get_user_info', params: {
        'user_id': userId,
      });
      return response as Map<String, dynamic>?;
    } catch (e) {
      dev.log('getUserInfo error: $e', name: 'ChatService');
      return null;
    }
  }


  // الحصول على معلومات المشاركين في الدردشة
  Future<List<Map<String, dynamic>>> getChatParticipants(String chatId) async {
    try {
      // تنظيف chat_id من البادئات المحتملة
      String cleanChatId = chatId;
      if (chatId.startsWith('booking_')) {
        cleanChatId = chatId.substring(8);
      }

      final response = await _supabase.rpc('get_chat_participants_info', params: {
        'chat_id': cleanChatId,
      });
      
      if (response is List) {
        return response.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      dev.log('getChatParticipants error: $e', name: 'ChatService');
      return [];
    }
  }

  // اشتراك في تحديثات آخر ظهور للمستخدمين
  RealtimeChannel? subscribeToUserPresence({
    required Function(Map<String, dynamic>) onUserUpdate,
  }) {
    try {
      return _supabase
          .channel('user_presence')
          .onPostgresChanges(
            event: PostgresChangeEvent.update,
            schema: 'public',
            table: 'users',
            callback: (payload) {
              final newRecord = payload.newRecord;
              if (newRecord.isNotEmpty && newRecord.containsKey('last_seen')) {
                onUserUpdate(newRecord);
              }
            },
          )
          .subscribe();
    } catch (e) {
      dev.log('subscribeToUserPresence error: $e', name: 'ChatService');
      return null;
    }
  }

  void unsubscribe(RealtimeChannel channel) {
    try {
      _supabase.removeChannel(channel);
    } catch (_) {}
  }
}
