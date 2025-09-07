import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// مدير التحديث المتفائل للواجهة
/// يوفر إمكانية تحديث الواجهة فوراً مع إمكانية التراجع عند الفشل
class OptimisticUIManager {
  static OptimisticUIManager? _instance;
  static OptimisticUIManager get instance =>
      _instance ??= OptimisticUIManager._internal();

  OptimisticUIManager._internal();

  final Map<String, OptimisticOperation> _pendingOperations = {};
  final StreamController<OptimisticUIEvent> _eventStream =
      StreamController.broadcast();

  Stream<OptimisticUIEvent> get eventStream => _eventStream.stream;

  /// تنفيذ عملية متفائلة
  Future<T> executeOperation<T>({
    required String operationId,
    required VoidCallback optimisticUpdate,
    required Future<T> Function() serverOperation,
    required VoidCallback rollbackUpdate,
    VoidCallback? onSuccess,
    VoidCallback? onError,
    Duration timeout = const Duration(seconds: 30),
  }) async {
    // تنفيذ التحديث المتفائل فوراً
    optimisticUpdate();
    HapticFeedback.lightImpact();

    final operation = OptimisticOperation(
      id: operationId,
      rollback: rollbackUpdate,
      timestamp: DateTime.now(),
    );

    _pendingOperations[operationId] = operation;
    _eventStream.add(OptimisticUIEvent.started(operationId));

    try {
      // تنفيذ العملية على الخادم مع timeout
      final result = await serverOperation().timeout(timeout);

      // نجحت العملية
      _pendingOperations.remove(operationId);
      onSuccess?.call();
      HapticFeedback.selectionClick();
      _eventStream.add(OptimisticUIEvent.success(operationId));

      return result;
    } catch (error) {
      // فشلت العملية - تراجع عن التحديث
      rollbackUpdate();
      _pendingOperations.remove(operationId);
      onError?.call();
      HapticFeedback.heavyImpact();
      _eventStream.add(OptimisticUIEvent.error(operationId, error.toString()));

      rethrow;
    }
  }

  /// تراجع عن جميع العمليات المعلقة
  void rollbackAllPending() {
    for (final operation in _pendingOperations.values) {
      operation.rollback();
    }
    _pendingOperations.clear();
    _eventStream.add(OptimisticUIEvent.rollbackAll());
  }

  /// التحقق من وجود عمليات معلقة
  bool hasPendingOperations() => _pendingOperations.isNotEmpty;

  /// الحصول على عدد العمليات المعلقة
  int get pendingOperationsCount => _pendingOperations.length;

  /// التحقق من كون عملية معينة معلقة
  bool isOperationPending(String operationId) =>
      _pendingOperations.containsKey(operationId);

  /// إلغاء عملية معينة
  void cancelOperation(String operationId) {
    final operation = _pendingOperations.remove(operationId);
    if (operation != null) {
      operation.rollback();
      _eventStream.add(OptimisticUIEvent.cancelled(operationId));
    }
  }

  /// تنظيف العمليات القديمة (أكثر من 5 دقائق)
  void cleanupOldOperations() {
    final cutoff = DateTime.now().subtract(const Duration(minutes: 5));
    final expiredIds = <String>[];

    _pendingOperations.forEach((id, operation) {
      if (operation.timestamp.isBefore(cutoff)) {
        expiredIds.add(id);
        operation.rollback();
      }
    });

    for (final id in expiredIds) {
      _pendingOperations.remove(id);
      _eventStream.add(OptimisticUIEvent.expired(id));
    }
  }

  void dispose() {
    _eventStream.close();
    _pendingOperations.clear();
  }
}

/// كلاس العملية المتفائلة
class OptimisticOperation {
  final String id;
  final VoidCallback rollback;
  final DateTime timestamp;

  OptimisticOperation({
    required this.id,
    required this.rollback,
    required this.timestamp,
  });
}

/// أحداث التحديث المتفائل
class OptimisticUIEvent {
  final String operationId;
  final OptimisticUIEventType type;
  final String? error;

  OptimisticUIEvent._(this.operationId, this.type, this.error);

  factory OptimisticUIEvent.started(String operationId) =>
      OptimisticUIEvent._(operationId, OptimisticUIEventType.started, null);

  factory OptimisticUIEvent.success(String operationId) =>
      OptimisticUIEvent._(operationId, OptimisticUIEventType.success, null);

  factory OptimisticUIEvent.error(String operationId, String error) =>
      OptimisticUIEvent._(operationId, OptimisticUIEventType.error, error);

  factory OptimisticUIEvent.cancelled(String operationId) =>
      OptimisticUIEvent._(operationId, OptimisticUIEventType.cancelled, null);

  factory OptimisticUIEvent.expired(String operationId) =>
      OptimisticUIEvent._(operationId, OptimisticUIEventType.expired, null);

  factory OptimisticUIEvent.rollbackAll() =>
      OptimisticUIEvent._('', OptimisticUIEventType.rollbackAll, null);
}

enum OptimisticUIEventType {
  started,
  success,
  error,
  cancelled,
  expired,
  rollbackAll,
}

/// مزين للعمليات المتفائلة
mixin OptimisticOperationsMixin on ChangeNotifier {
  final OptimisticUIManager _optimisticManager = OptimisticUIManager.instance;

  /// تنفيذ عملية متفائلة مع تحديث الحالة
  Future<R> performOptimisticOperation<R>({
    required String operationId,
    required VoidCallback optimisticUpdate,
    required Future<R> Function() serverOperation,
    required VoidCallback rollbackUpdate,
    String? successMessage,
    String? errorMessage,
  }) async {
    return await _optimisticManager.executeOperation<R>(
      operationId: operationId,
      optimisticUpdate: () {
        optimisticUpdate();
        notifyListeners();
      },
      serverOperation: serverOperation,
      rollbackUpdate: () {
        rollbackUpdate();
        notifyListeners();
      },
      onSuccess: () {
        if (successMessage != null) {
          debugPrint('✅ $successMessage');
        }
      },
      onError: () {
        if (errorMessage != null) {
          debugPrint('❌ $errorMessage');
        }
      },
    );
  }

  /// الحصول على حالة العملية
  bool isOperationPending(String operationId) {
    return _optimisticManager.isOperationPending(operationId);
  }

  /// إلغاء عملية معينة
  void cancelOperation(String operationId) {
    _optimisticManager.cancelOperation(operationId);
  }
}

/// ويدجت لعرض حالة العمليات المتفائلة
class OptimisticUIIndicator extends StatefulWidget {
  final Widget child;
  final bool showPendingOperations;

  const OptimisticUIIndicator({
    super.key,
    required this.child,
    this.showPendingOperations = true,
  });

  @override
  State<OptimisticUIIndicator> createState() => _OptimisticUIIndicatorState();
}

class _OptimisticUIIndicatorState extends State<OptimisticUIIndicator> {
  late StreamSubscription<OptimisticUIEvent> _subscription;
  int _pendingCount = 0;

  @override
  void initState() {
    super.initState();
    _pendingCount = OptimisticUIManager.instance.pendingOperationsCount;
    _subscription = OptimisticUIManager.instance.eventStream.listen((event) {
      if (mounted) {
        setState(() {
          switch (event.type) {
            case OptimisticUIEventType.started:
              _pendingCount++;
              break;
            case OptimisticUIEventType.success:
            case OptimisticUIEventType.error:
            case OptimisticUIEventType.cancelled:
            case OptimisticUIEventType.expired:
              _pendingCount = math.max(0, _pendingCount - 1);
              break;
            case OptimisticUIEventType.rollbackAll:
              _pendingCount = 0;
              break;
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (widget.showPendingOperations && _pendingCount > 0)
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orange,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$_pendingCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
