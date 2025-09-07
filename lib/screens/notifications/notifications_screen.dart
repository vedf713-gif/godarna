import 'package:flutter/material.dart';
import 'package:godarna/mixins/realtime_mixin.dart';
import 'package:godarna/constants/app_icons.dart';
import 'package:godarna/constants/app_strings.dart';
import 'package:godarna/models/notification_model.dart';
import 'package:godarna/screens/booking/booking_details_screen.dart';
import 'package:godarna/services/notifications_service.dart';
import 'package:godarna/theme/app_theme.dart';
import 'package:godarna/theme/app_dimensions.dart';
import 'package:godarna/widgets/common/app_app_bar.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> with RealtimeMixin {
  final NotificationsService _notificationsService = NotificationsService();
  List<NotificationModel> _notifications = [];
  bool _isLoading = true;
  String? _tappedId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadNotifications();
      _setupRealtimeSubscriptions();
    });
  }

  @override
  void dispose() {
    unsubscribeAll();
    super.dispose();
  }

  void _setupRealtimeSubscriptions() {
    // اشتراك في تحديثات الإشعارات
    subscribeToTable(
      table: 'notifications',
      filter: 'user_id',
      filterValue: null, // سيتم تحديده بالمستخدم الحالي
      onInsert: (payload) {
        if (mounted) {
          _loadNotifications();
        }
      },
      onUpdate: (payload) {
        if (mounted) {
          _loadNotifications();
        }
      },
      onDelete: (payload) {
        if (mounted) {
          _loadNotifications();
        }
      },
    );
  }

  Future<void> _loadNotifications() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final notifications = await _notificationsService.getUserNotifications();
      if (mounted) {
        setState(() {
          _notifications = notifications;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '${AppStrings.getString('notificationsLoadError', context)}: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _markAsRead(String notificationId) async {
    try {
      await _notificationsService.markAsRead(notificationId);
      if (mounted) {
        setState(() {
          final index =
              _notifications.indexWhere((n) => n.id == notificationId);
          if (index != -1) {
            _notifications[index] =
                _notifications[index].copyWith(isRead: true);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '${AppStrings.getString('notificationUpdateError', context)}: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      await _notificationsService.markAllAsRead();
      if (mounted) {
        setState(() {
          _notifications =
              _notifications.map((n) => n.copyWith(isRead: true)).toList();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(AppStrings.getString('notificationsUpdated', context)),
            backgroundColor:
                Theme.of(context).extension<CustomColors>()!.success!,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '${AppStrings.getString('notificationsUpdateError', context)}: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _deleteNotification(String notificationId) async {
    try {
      await _notificationsService.deleteNotification(notificationId);
      if (mounted) {
        setState(() {
          _notifications.removeWhere((n) => n.id == notificationId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppStrings.getString('notificationDeleted', context)),
            backgroundColor:
                Theme.of(context).extension<CustomColors>()!.success!,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '${AppStrings.getString('notificationDeleteError', context)}: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _clearAllNotifications() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppStrings.getString('deleteAllNotifications', context)),
        content: Text(
            AppStrings.getString('confirmDeleteAllNotifications', context)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(
              minimumSize: const Size.fromHeight(56),
              shape: const RoundedRectangleBorder(
                  borderRadius: AppDimensions.borderRadiusLarge),
            ),
            child: Text(AppStrings.getString('cancel', context)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              minimumSize: const Size.fromHeight(56),
              shape: const RoundedRectangleBorder(
                  borderRadius: AppDimensions.borderRadiusLarge),
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(
              AppStrings.getString('delete', context),
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _notificationsService.clearAllNotifications();
        if (mounted) {
          setState(() => _notifications.clear());
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  AppStrings.getString('notificationsAllDeleted', context)),
              backgroundColor:
                  Theme.of(context).extension<CustomColors>()!.success!,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  '${AppStrings.getString('notificationsDeleteAllError', context)}: $e'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }

  Color _getNotificationTypeColor(BuildContext context, String type) {
    final customColors = Theme.of(context).extension<CustomColors>()!;
    return switch (type) {
      'success' => customColors.success!,
      'warning' => customColors.warning!,
      'error' => Theme.of(context).colorScheme.error,
      'info' || _ => customColors.info!,
    };
  }

  IconData _getNotificationTypeIcon(String type) {
    return switch (type) {
      'success' => AppIcons.checkCircle,
      'warning' => AppIcons.warning,
      'error' => AppIcons.error,
      'info' || _ => AppIcons.info,
    };
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppAppBar(
        title: AppStrings.getString('notifications', context),
        actions: [
          if (_notifications.any((n) => !n.isRead))
            IconButton(
              tooltip: AppStrings.getString('markAllAsRead', context),
              onPressed: _markAllAsRead,
              icon: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(AppIcons.notifications, size: 24),
                  Positioned(
                    top: -2,
                    right: -2,
                    child: Container(
                      padding: AppDimensions.paddingSymmetric6x2,
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        borderRadius: AppDimensions.borderRadiusCircular,
                      ),
                      child: Text(
                        _notifications
                            .where((n) => !n.isRead)
                            .length
                            .toString(),
                        style: TextStyle(
                          color: colorScheme.onPrimary,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (_notifications.isNotEmpty)
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'mark_all_read') {
                  _markAllAsRead();
                } else if (value == 'clear_all') {
                  _clearAllNotifications();
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'mark_all_read',
                  child: Row(
                    children: [
                      const Icon(AppIcons.markEmailRead, size: 20),
                      const SizedBox(width: AppDimensions.space8),
                      Text(AppStrings.getString('markAllAsRead', context)),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'clear_all',
                  child: Row(
                    children: [
                      Icon(AppIcons.clearAll,
                          size: 20, color: colorScheme.error),
                      const SizedBox(width: AppDimensions.space8),
                      Text(
                        AppStrings.getString('clearAll', context),
                        style: TextStyle(color: colorScheme.error),
                      ),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadNotifications,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _notifications.isEmpty
                ? _buildEmptyState(context)
                : ListView.separated(
                    padding: AppDimensions.paddingAll16,
                    itemCount: _notifications.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final notification = _notifications[index];
                      return _buildNotificationCard(context, notification);
                    },
                  ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            AppIcons.notificationsNone,
            size: 80,
            color: colorScheme.onSurface.withAlpha((0.5 * 255).toInt()),
          ),
          const SizedBox(height: AppDimensions.space20),
          Text(
            AppStrings.getString('noNotifications', context),
            style: textTheme.headlineSmall,
          ),
          const SizedBox(height: AppDimensions.space8),
          Text(
            AppStrings.getString('notificationsEmptySubtitle', context),
            style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withAlpha((0.7 * 255).toInt())),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(
      BuildContext context, NotificationModel notification) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final typeColor = _getNotificationTypeColor(context, notification.type);
    final isRead = notification.isRead;

    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: AppDimensions.paddingRight20,
        decoration: BoxDecoration(
          color: colorScheme.error,
          borderRadius: AppDimensions.borderRadiusLarge,
        ),
        child: const Icon(AppIcons.delete, color: Colors.white, size: 24),
      ),
      onDismissed: (_) => _deleteNotification(notification.id),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: isRead ? 0.85 : 1.0,
        child: GestureDetector(
          onTap: () async {
            setState(() => _tappedId = notification.id);
            if (!isRead) {
              _markAsRead(notification.id);
            }

            if (notification.data != null) {
              final data = notification.data!;
              final bookingId = data['booking_id'];
              if (bookingId is String && bookingId.isNotEmpty) {
                if (!mounted) return;
                Navigator.of(context)
                    .push(
                  MaterialPageRoute(
                    builder: (_) => BookingDetailsScreen(bookingId: bookingId),
                  ),
                )
                    .then((_) {
                  if (mounted) setState(() => _tappedId = null);
                });
                return;
              }

              final propertyId = data['property_id'];
              if (propertyId is String && propertyId.isNotEmpty) {
                if (!mounted) return;
                context.pushNamed('propertyById',
                    pathParameters: {'id': propertyId}).then((_) {
                  if (mounted) setState(() => _tappedId = null);
                });
                return;
              }

              final chatId = data['chat_id'];
              if (chatId is String && chatId.isNotEmpty) {
                if (!mounted) return;
                context.pushNamed('chat', pathParameters: {'id': chatId}).then(
                    (_) {
                  if (mounted) setState(() => _tappedId = null);
                });
                return;
              }
            }

            if (mounted) setState(() => _tappedId = null);
          },
          child: Container(
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: AppDimensions.borderRadiusLarge,
              border: Border.all(
                color: isRead
                    ? colorScheme.outlineVariant
                    : colorScheme.primary.withAlpha((0.35 * 255).toInt()),
              ),
              boxShadow: [
                BoxShadow(
                  color: isRead
                      ? Colors.black.withAlpha((0.04 * 255).toInt())
                      : Colors.black.withAlpha((0.08 * 255).toInt()),
                  blurRadius: isRead ? 8 : 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ListTile(
              contentPadding: AppDimensions.paddingAll16,
              leading: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: typeColor.withAlpha((0.1 * 255).toInt()),
                  shape: BoxShape.circle,
                ),
                child: Icon(_getNotificationTypeIcon(notification.type),
                    color: typeColor, size: 24),
              ),
              title: Row(
                children: [
                  Expanded(
                    child: Text(
                      notification.title,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                      ),
                    ),
                  ),
                  if (_tappedId == notification.id)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                ],
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: AppDimensions.space8),
                  Text(notification.message, style: textTheme.bodyMedium),
                  const SizedBox(height: AppDimensions.space8),
                  Text(
                    DateFormat('dd/MM/yyyy HH:mm')
                        .format(notification.createdAt),
                    style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface
                            .withAlpha((0.7 * 255).toInt())),
                  ),
                ],
              ),
              trailing: isRead
                  ? null
                  : Container(
                      width: 12,
                      height: 12,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
