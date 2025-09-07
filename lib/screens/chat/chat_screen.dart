import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:godarna/services/chat_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:godarna/theme/app_dimensions.dart';
import 'package:godarna/constants/app_colors.dart';
import 'package:godarna/widgets/common/app_app_bar.dart';
import 'package:godarna/widgets/common/app_button.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:godarna/services/notifications_service.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, required this.chatId, this.title});

  final String chatId;
  final String? title;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<_Message> _messages = <_Message>[];
  RealtimeChannel? _channel;
  RealtimeChannel? _presenceChannel;
  String? _currentUserId;
  Map<String, dynamic>? _otherUserInfo;
  bool _isLoadingOlderMessages = false;
  bool _hasMoreMessages = true;

  @override
  void initState() {
    super.initState();
    _currentUserId = Supabase.instance.client.auth.currentUser?.id;
    _loadMessages();
    _setupRealtimeSubscription();
    _loadParticipants();
    _subscribeToPresence();
    _updateLastSeen();
    _setupScrollListener();
  }

  void _setupScrollListener() {
    _scrollController.addListener(() {
      // مع reverse: true، نحتاج للتحقق من maxScrollExtent بدلاً من 0
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 100 && 
          !_isLoadingOlderMessages && 
          _hasMoreMessages) {
        _loadOlderMessages();
      }
    });
  }

  @override
  void dispose() {
    if (_channel != null) {
      ChatService.instance.unsubscribe(_channel!);
    }
    if (_presenceChannel != null) {
      ChatService.instance.unsubscribe(_presenceChannel!);
    }
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    final rows = await ChatService.instance.getMessages(widget.chatId);
    if (!mounted) return;
    setState(() {
      _messages
        ..clear()
        ..addAll(rows.map((r) => _fromRow(r)).toList().reversed); // عكس الترتيب لأن قاعدة البيانات ترسل الأحدث أولاً
      _hasMoreMessages = rows.length >= 50; // إذا كان العدد أقل من الحد الأقصى، فلا توجد رسائل أكثر
    });
    _jumpToBottom();
  }

  Future<void> _loadOlderMessages() async {
    if (_isLoadingOlderMessages || !_hasMoreMessages || _messages.isEmpty) return;
    
    setState(() {
      _isLoadingOlderMessages = true;
    });

    try {
      final oldestMessage = _messages.first;
      final olderMessages = await ChatService.instance.getOlderMessages(
        widget.chatId, 
        oldestMessage.time
      );
      
      if (!mounted) return;
      
      setState(() {
        if (olderMessages.isNotEmpty) {
          // إضافة الرسائل الأقدم في بداية القائمة مع عكس الترتيب
          _messages.insertAll(0, olderMessages.map((r) => _fromRow(r)).toList().reversed);
          _hasMoreMessages = olderMessages.length >= 50;
        } else {
          _hasMoreMessages = false;
        }
        _isLoadingOlderMessages = false;
      });
    } catch (e) {
      debugPrint('🔍 [DEBUG] Error loading older messages: $e');
      if (mounted) {
        setState(() {
          _isLoadingOlderMessages = false;
        });
      }
    }
  }

  void _setupRealtimeSubscription() {
    debugPrint('🔄 [Chat] Setting up realtime subscription for chat: ${widget.chatId}');
    _channel = ChatService.instance.subscribeToMessages(
      chatId: widget.chatId,
      onInsert: (data) {
        if (!mounted) return;
        
        debugPrint('🔍 [Realtime] New message received: ${data['content']}');
        
        // تجنب الرسائل المكررة
        final existingMessage = _messages.any((msg) => 
          msg.text == data['content'] && 
          msg.time.difference(DateTime.parse(data['created_at'])).abs().inSeconds < 5
        );
        
        if (!existingMessage) {
          final newMessage = _Message(
            text: data['content'] as String,
            isMe: data['sender_id'] == _currentUserId,
            time: DateTime.parse(data['created_at'] as String),
            isSent: true, // الرسائل القادمة من الخادم مرسلة بالفعل
          );
          
          // استخدام addPostFrameCallback لتجنب setState أثناء build
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                // إزالة الرسالة المحلية المطابقة إذا وجدت
                _messages.removeWhere((msg) => 
                  msg.text == newMessage.text && 
                  msg.isMe == newMessage.isMe && 
                  (msg.isPending || msg.isFailed)
                );
                
                _messages.add(newMessage);
                _messages.sort((a, b) => a.time.compareTo(b.time));
              });
              
              _jumpToBottom(animated: false);
            }
          });
        }
      },
    );
    
    if (_channel != null) {
      debugPrint('✅ [Chat] Realtime subscription established');
    } else {
      debugPrint('❌ [Chat] Failed to establish realtime subscription');
    }
  }

  // تحميل معلومات المشاركين في الدردشة
  Future<void> _loadParticipants() async {
    try {
      final participants = await ChatService.instance.getChatParticipants(widget.chatId);
      if (!mounted) return;
      
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            // العثور على المستخدم الآخر (ليس المستخدم الحالي)
            _otherUserInfo = participants.firstWhere(
              (user) => user['id'] != _currentUserId,
              orElse: () => {},
            );
          });
        }
      });
    } catch (e) {
      debugPrint('🔍 [DEBUG] Error loading participants: $e');
    }
  }

  // الاشتراك في تحديثات حضور المستخدمين
  void _subscribeToPresence() {
    _presenceChannel = ChatService.instance.subscribeToUserPresence(
      onUserUpdate: (userData) {
        if (!mounted) return;
        
        // تحديث معلومات المستخدم الآخر إذا كان هو المحدث
        if (_otherUserInfo != null && userData['id'] == _otherUserInfo!['id']) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                _otherUserInfo = {..._otherUserInfo!, ...userData};
              });
            }
          });
        }
      },
    );
  }

  // تحديث آخر ظهور للمستخدم الحالي
  Future<void> _updateLastSeen() async {
    await ChatService.instance.updateLastSeen();
  }

  // تنسيق وقت آخر ظهور
  String _formatLastSeen(String? lastSeenStr, bool? isOnline) {
    if (isOnline == true) {
      return 'متصل الآن';
    }
    
    if (lastSeenStr == null) return 'غير متاح';
    
    try {
      final lastSeen = DateTime.parse(lastSeenStr);
      final now = DateTime.now();
      final difference = now.difference(lastSeen);
      
      if (difference.inMinutes < 1) {
        return 'متصل الآن';
      } else if (difference.inMinutes < 60) {
        return 'آخر ظهور منذ ${difference.inMinutes} دقيقة';
      } else if (difference.inHours < 24) {
        return 'آخر ظهور منذ ${difference.inHours} ساعة';
      } else if (difference.inDays < 7) {
        return 'آخر ظهور منذ ${difference.inDays} يوم';
      } else {
        return 'آخر ظهور منذ أسبوع';
      }
    } catch (e) {
      return 'غير متاح';
    }
  }

  // تحديد ما إذا كان يجب عرض فاصل التاريخ
  bool _shouldShowDateSeparator(_Message current, _Message? previous) {
    if (previous == null) return true;
    
    final currentDate = DateTime(current.time.year, current.time.month, current.time.day);
    final previousDate = DateTime(previous.time.year, previous.time.month, previous.time.day);
    
    return !currentDate.isAtSameMomentAs(previousDate);
  }

  // بناء فاصل التاريخ
  Widget _buildDateSeparator(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(date.year, date.month, date.day);
    
    String dateText;
    if (messageDate.isAtSameMomentAs(today)) {
      dateText = 'اليوم';
    } else if (messageDate.isAtSameMomentAs(today.subtract(const Duration(days: 1)))) {
      dateText = 'أمس';
    } else {
      dateText = '${date.day}/${date.month}/${date.year}';
    }
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.grey200,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            dateText,
            style: GoogleFonts.cairo(
              fontSize: 12,
              color: AppColors.grey600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  _Message _fromRow(Map<String, dynamic> r) {
    final senderId = r['sender_id']?.toString();
    final content = r['content']?.toString() ?? '';
    final createdAt = r['created_at']?.toString();
    DateTime time;
    try {
      time = createdAt != null ? DateTime.parse(createdAt) : DateTime.now();
    } catch (_) {
      time = DateTime.now();
    }
    return _Message(
      text: content,
      isMe: senderId != null && senderId == _currentUserId,
      time: time,
      isSent: true, // الرسائل القادمة من قاعدة البيانات مرسلة بالفعل
    );
  }

  void _jumpToBottom({bool animated = false}) {
    if (!_scrollController.hasClients) return;
    // التمرير الفوري بدون تأخير للحصول على تجربة WhatsApp
    _scrollController.jumpTo(0);
  }

  void _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    
    HapticFeedback.lightImpact();
    _controller.clear();
    
    // فحص حالة المصادقة أولاً
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser == null) return;
    
    // إضافة الرسالة محلياً فوراً (مثل WhatsApp)
    final tempMessage = _Message(
      text: text,
      isMe: true,
      time: DateTime.now(),
      isPending: true, // مؤشر أن الرسالة قيد الإرسال
    );
    
    setState(() {
      _messages.add(tempMessage);
      _messages.sort((a, b) => a.time.compareTo(b.time));
    });
    _jumpToBottom(animated: false); // إزالة الحركة للسرعة
    
    // إرسال الرسالة في الخلفية بدون انتظار
    ChatService.instance.sendMessage(chatId: widget.chatId, content: text).then((success) {
      if (mounted) {
        setState(() {
          final index = _messages.indexWhere((msg) => 
            msg.text == text && msg.isMe && msg.isPending);
          if (index != -1) {
            if (success) {
              // تحديث الرسالة المحلية لإظهار النجاح
              _messages[index] = _Message(
                text: text,
                isMe: true,
                time: _messages[index].time, // الحفاظ على الوقت الأصلي
                isPending: false,
                isSent: true,
              );
              // إرسال الإشعار للطرف الآخر
              _sendMessageNotification(text);
            } else {
              // تحديث الرسالة المحلية لإظهار الفشل
              _messages[index] = _Message(
                text: text,
                isMe: true,
                time: _messages[index].time, // الحفاظ على الوقت الأصلي
                isPending: false,
                isFailed: true,
              );
            }
          }
        });
      }
    });
  }

  Future<void> _sendMessageNotification(String messageText) async {
    try {
      debugPrint('🔔 [Notification] Attempting to send notification for message: $messageText');
      final notificationService = NotificationsService();
      final currentUserId = _currentUserId;
      
      if (currentUserId == null) {
        debugPrint('❌ [Notification] No current user ID');
        return;
      }
      
      // استخدام معلومات المشارك الآخر المحملة مسبقاً
      if (_otherUserInfo == null) {
        debugPrint('❌ [Notification] No other user info available');
        return;
      }
      
      final receiverId = _otherUserInfo!['id'] as String;
      debugPrint('🎯 [Notification] Sending to user: $receiverId');
      
      await notificationService.sendNotification(
        userId: receiverId,
        title: '💬 رسالة جديدة من ${_otherUserInfo!['email'] ?? 'مستخدم'}',
        message: messageText.length > 50 
            ? '${messageText.substring(0, 50)}...' 
            : messageText,
        type: 'new_message',
        data: {
          'chat_id': widget.chatId,
          'sender_id': currentUserId,
          'sender_name': _otherUserInfo!['email'] ?? 'مستخدم',
          'message_preview': messageText,
        },
      );
      
      debugPrint('✅ [Notification] Notification sent successfully');
    } catch (e) {
      // لا نعرض خطأ للمستخدم لأن الرسالة تم إرسالها بنجاح
      debugPrint('خطأ في إرسال إشعار الرسالة: $e');
    }
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppAppBar(
        title: widget.title ?? 'المحادثة',
        subtitle: _otherUserInfo != null 
          ? _formatLastSeen(
              _otherUserInfo!['last_seen']?.toString(),
              _otherUserInfo!['is_online'] as bool?
            )
          : null,
        showBackButton: true,
        onBackPressed: () => Navigator.of(context).pop(),
        backgroundColor: cs.surface,
        titleColor: cs.onSurface,
        iconColor: cs.onSurface,
      ),
      body: Column(
        children: [
          // Header mini info
          Container(
            width: double.infinity,
            padding: AppDimensions.paddingSymmetric16x10,
            decoration: BoxDecoration(
              color: cs.surface,
              border: Border(
                  bottom: BorderSide(color: cs.outlineVariant, width: 0.5)),
            ),
            child: Row(
              children: [
                const Icon(Icons.chat_bubble_outline,
                    color: AppColors.primaryRed, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Chat ID: ${widget.chatId}',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: cs.onSurface.withAlpha((0.7 * 255).round()),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          // Messages list
          Expanded(
            child: _messages.isEmpty
                ? _buildEmptyState(context)
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                    reverse: true, // عكس الترتيب مثل واتساب
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      // عكس الفهرس لأن القائمة معكوسة
                      final reversedIndex = _messages.length - 1 - index;
                      final msg = _messages[reversedIndex];
                      final nextMsg = reversedIndex < _messages.length - 1 ? _messages[reversedIndex + 1] : null;
                      final showDateSeparator = _shouldShowDateSeparator(msg, nextMsg);
                      
                      return Column(
                        children: [
                          _MessageBubble(
                            message: msg,
                            colorScheme: cs,
                            animationController: AnimationController(
                              duration: const Duration(milliseconds: 300),
                              vsync: this,
                            )..forward(),
                          ),
                          if (showDateSeparator) _buildDateSeparator(msg.time),
                        ],
                      );
                    },
                  ),
          ),

          // Input bar
          SafeArea(
            top: false,
            child: Container(
              padding: AppDimensions.paddingFromLTRB12x10x12x12,
              decoration: BoxDecoration(
                color: cs.surface,
                border: Border(
                    top: BorderSide(color: cs.outlineVariant, width: 0.5)),
                boxShadow: [
                  BoxShadow(
                    color: cs.shadow.withAlpha((0.1 * 255).round()),
                    blurRadius: 6,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.newline,
                      style:
                          GoogleFonts.inter(fontSize: 16, color: cs.onSurface),
                      decoration: InputDecoration(
                        hintText: 'اكتب رسالة...',
                        hintStyle: GoogleFonts.inter(
                          fontSize: 14,
                          color: cs.onSurface.withAlpha((0.6 * 255).round()),
                        ),
                        isDense: true,
                        contentPadding: AppDimensions.paddingSymmetric12x16,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(color: cs.outlineVariant),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(
                              color: AppColors.primaryRed, width: 1.5),
                        ),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ValueListenableBuilder<TextEditingValue>(
                    valueListenable: _controller,
                    builder: (context, value, child) {
                      return AppButton(
                        text: 'إرسال',
                        icon: Icons.send_rounded,
                        onPressed: value.text.trim().isNotEmpty ? _sendMessage : null,
                        type: AppButtonType.primary,
                        size: AppButtonSize.medium,
                        isEnabled: value.text.trim().isNotEmpty,
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 80,
            color: cs.onSurface.withAlpha((0.5 * 255).round()),
          ),
          const SizedBox(height: 12),
          Text(
            'لا توجد رسائل بعد',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'ابدأ المحادثة بإرسال أول رسالة',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: cs.onSurface.withAlpha((0.7 * 255).round()),
            ),
          ),
        ],
      ),
    );
  }
}

class _Message {
  final String text;
  final bool isMe;
  final DateTime time;
  final bool isPending;
  final bool isSent;
  final bool isFailed;

  _Message({
    required this.text, 
    required this.isMe, 
    required this.time,
    this.isPending = false,
    this.isSent = false,
    this.isFailed = false,
  });
}

class _MessageBubble extends StatelessWidget {
  final _Message message;
  final ColorScheme colorScheme;
  final AnimationController animationController;

  const _MessageBubble({
    required this.message,
    required this.colorScheme,
    required this.animationController,
  });

  String _formatTime(DateTime time) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    final isMe = message.isMe;
    final bubbleColor = isMe ? AppColors.primaryRed : colorScheme.surface;
    final textColor = isMe ? Colors.white : colorScheme.onSurface;

    return FadeTransition(
      opacity: animationController,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: Offset(isMe ? 0.2 : -0.2, 0),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: animationController,
          curve: Curves.easeOut,
        )),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
          child: Align(
            alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 280),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: isMe 
                    ? const LinearGradient(
                        colors: [
                          AppColors.primaryRed,
                          AppColors.primaryRedLight,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                  color: isMe ? null : bubbleColor,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(18),
                    topRight: const Radius.circular(18),
                    bottomLeft: Radius.circular(isMe ? 18 : 4),
                    bottomRight: Radius.circular(isMe ? 4 : 18),
                  ),
                  border: isMe 
                    ? null 
                    : Border.all(color: colorScheme.outlineVariant, width: 0.5),
                  boxShadow: [
                    BoxShadow(
                      color: isMe 
                        ? AppColors.primaryRed.withAlpha((0.15 * 255).round())
                        : Colors.black.withAlpha((0.05 * 255).round()),
                      blurRadius: isMe ? 8 : 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        message.text,
                        style: GoogleFonts.cairo(
                          fontSize: 15,
                          color: textColor,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Align(
                        alignment: AlignmentDirectional.centerEnd,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _formatTime(message.time),
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: isMe
                                    ? Colors.white.withAlpha((0.7 * 255).round())
                                    : colorScheme.onSurface.withAlpha((0.6 * 255).round()),
                              ),
                            ),
                            if (isMe) ...[
                              const SizedBox(width: 4),
                              _buildMessageStatusIcon(),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMessageStatusIcon() {
    if (message.isPending) {
      return SizedBox(
        width: 12,
        height: 12,
        child: CircularProgressIndicator(
          strokeWidth: 1.5,
          valueColor: AlwaysStoppedAnimation<Color>(
            Colors.white.withAlpha((0.7 * 255).round()),
          ),
        ),
      );
    } else if (message.isFailed) {
      return Icon(
        Icons.error_outline,
        size: 14,
        color: Colors.red.shade300,
      );
    } else if (message.isSent) {
      return Icon(
        Icons.done_all,
        size: 14,
        color: Colors.white.withAlpha((0.7 * 255).round()),
      );
    }
    return const SizedBox.shrink();
  }
}
