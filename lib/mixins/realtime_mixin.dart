import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:developer' as dev;

/// Mixin لإضافة قدرات Realtime لأي Widget أو Provider
mixin RealtimeMixin<T extends StatefulWidget> on State<T> {
  final List<RealtimeChannel> _channels = [];

  /// اشتراك في جدول معين
  RealtimeChannel? subscribeToTable({
    required String table,
    String? filter,
    String? filterValue,
    Function(Map<String, dynamic>)? onInsert,
    Function(Map<String, dynamic>)? onUpdate,
    Function(Map<String, dynamic>)? onDelete,
  }) {
    try {
      final channelName = filter != null 
          ? '${table}_${filter}_$filterValue'
          : '${table}_global';
      
      var channel = Supabase.instance.client.channel(channelName);

      if (onInsert != null) {
        channel = channel.onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: table,
          filter: filter != null ? PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: filter,
            value: filterValue,
          ) : null,
          callback: (payload) {
            if (mounted) {
              onInsert(payload.newRecord);
            }
          },
        );
      }

      if (onUpdate != null) {
        channel = channel.onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: table,
          filter: filter != null ? PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: filter,
            value: filterValue,
          ) : null,
          callback: (payload) {
            if (mounted) {
              onUpdate(payload.newRecord);
            }
          },
        );
      }

      if (onDelete != null) {
        channel = channel.onPostgresChanges(
          event: PostgresChangeEvent.delete,
          schema: 'public',
          table: table,
          filter: filter != null ? PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: filter,
            value: filterValue,
          ) : null,
          callback: (payload) {
            if (mounted) {
              onDelete(payload.oldRecord);
            }
          },
        );
      }

      final subscribedChannel = channel.subscribe((status, [ref]) {
        dev.log('🔍 [Realtime] $table status: $status', name: 'RealtimeMixin');
      });

      _channels.add(subscribedChannel);
      return subscribedChannel;
    } catch (e) {
      dev.log('subscribeToTable error: $e', name: 'RealtimeMixin');
      return null;
    }
  }

  /// إلغاء جميع الاشتراكات
  void unsubscribeAll() {
    for (final channel in _channels) {
      Supabase.instance.client.removeChannel(channel);
    }
    _channels.clear();
  }

  @override
  void dispose() {
    unsubscribeAll();
    super.dispose();
  }
}

/// Mixin للـ Providers
mixin RealtimeProviderMixin on ChangeNotifier {
  final List<RealtimeChannel> _channels = [];

  /// اشتراك في جدول معين للـ Provider
  RealtimeChannel? subscribeToTable({
    required String table,
    String? filter,
    String? filterValue,
    Function(Map<String, dynamic>)? onInsert,
    Function(Map<String, dynamic>)? onUpdate,
    Function(Map<String, dynamic>)? onDelete,
  }) {
    try {
      final channelName = filter != null 
          ? '${table}_${filter}_$filterValue'
          : '${table}_global';
      
      var channel = Supabase.instance.client.channel(channelName);

      if (onInsert != null) {
        channel = channel.onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: table,
          filter: filter != null ? PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: filter,
            value: filterValue,
          ) : null,
          callback: (payload) {
            onInsert(payload.newRecord);
          },
        );
      }

      if (onUpdate != null) {
        channel = channel.onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: table,
          filter: filter != null ? PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: filter,
            value: filterValue,
          ) : null,
          callback: (payload) {
            onUpdate(payload.newRecord);
          },
        );
      }

      if (onDelete != null) {
        channel = channel.onPostgresChanges(
          event: PostgresChangeEvent.delete,
          schema: 'public',
          table: table,
          filter: filter != null ? PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: filter,
            value: filterValue,
          ) : null,
          callback: (payload) {
            onDelete(payload.oldRecord);
          },
        );
      }

      final subscribedChannel = channel.subscribe((status, [ref]) {
        dev.log('🔍 [Realtime] $table status: $status', name: 'RealtimeProviderMixin');
      });

      _channels.add(subscribedChannel);
      return subscribedChannel;
    } catch (e) {
      dev.log('subscribeToTable error: $e', name: 'RealtimeProviderMixin');
      return null;
    }
  }

  /// إلغاء جميع الاشتراكات
  void unsubscribeAll() {
    for (final channel in _channels) {
      Supabase.instance.client.removeChannel(channel);
    }
    _channels.clear();
  }

  @override
  void dispose() {
    unsubscribeAll();
    super.dispose();
  }
}
