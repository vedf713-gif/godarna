class PaymentModel {
  final String id;
  final String bookingId;
  final double amount;
  final String paymentMethod;
  final String status;
  final String? transactionId;
  final String? message;
  final Map<String, dynamic>? details;
  final DateTime createdAt;
  final DateTime? updatedAt;

  PaymentModel({
    required this.id,
    required this.bookingId,
    required this.amount,
    required this.paymentMethod,
    required this.status,
    this.transactionId,
    this.message,
    this.details,
    required this.createdAt,
    this.updatedAt,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      id: json['id'] ?? '',
      bookingId: json['booking_id'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      paymentMethod: json['payment_method'] ?? '',
      status: json['status'] ?? '',
      transactionId: json['transaction_id'],
      message: json['message'],
      details: json['details'] != null ? Map<String, dynamic>.from(json['details']) : null,
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'booking_id': bookingId,
      'amount': amount,
      'payment_method': paymentMethod,
      'status': status,
      'transaction_id': transactionId,
      'message': message,
      'details': details,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  PaymentModel copyWith({
    String? id,
    String? bookingId,
    double? amount,
    String? paymentMethod,
    String? status,
    String? transactionId,
    String? message,
    Map<String, dynamic>? details,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PaymentModel(
      id: id ?? this.id,
      bookingId: bookingId ?? this.bookingId,
      amount: amount ?? this.amount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      status: status ?? this.status,
      transactionId: transactionId ?? this.transactionId,
      message: message ?? this.message,
      details: details ?? this.details,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'PaymentModel(id: $id, amount: $amount, method: $paymentMethod, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PaymentModel &&
        other.id == id &&
        other.bookingId == bookingId &&
        other.amount == amount &&
        other.paymentMethod == paymentMethod &&
        other.status == status;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        bookingId.hashCode ^
        amount.hashCode ^
        paymentMethod.hashCode ^
        status.hashCode;
  }

  // Helper methods
  bool get isPending => status == 'pending';
  bool get isPaid => status == 'paid';
  bool get isFailed => status == 'failed';
  bool get isRefunded => status == 'refunded';
  bool get isCancelled => status == 'cancelled';

  String get statusText {
    switch (status) {
      case 'pending':
        return 'قيد المعالجة';
      case 'paid':
        return 'مدفوع';
      case 'failed':
        return 'فشل';
      case 'refunded':
        return 'مسترد';
      case 'cancelled':
        return 'ملغي';
      default:
        return status;
    }
  }

  String get methodText {
    switch (paymentMethod) {
      case 'cash_on_delivery':
        return 'نقداً عند التسليم';
      default:
        return paymentMethod;
    }
  }

  String get formattedAmount {
    return '${amount.toStringAsFixed(2)} درهم';
  }

  String get shortId {
    return id.length > 8 ? '${id.substring(0, 8)}...' : id;
  }
}

class RefundModel {
  final String id;
  final String paymentId;
  final double amount;
  final String reason;
  final String status;
  final String? adminNotes;
  final DateTime createdAt;
  final DateTime? processedAt;

  RefundModel({
    required this.id,
    required this.paymentId,
    required this.amount,
    required this.reason,
    required this.status,
    this.adminNotes,
    required this.createdAt,
    this.processedAt,
  });

  factory RefundModel.fromJson(Map<String, dynamic> json) {
    return RefundModel(
      id: json['id'] ?? '',
      paymentId: json['payment_id'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      reason: json['reason'] ?? '',
      status: json['status'] ?? '',
      adminNotes: json['admin_notes'],
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      processedAt: json['processed_at'] != null ? DateTime.parse(json['processed_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'payment_id': paymentId,
      'amount': amount,
      'reason': reason,
      'status': status,
      'admin_notes': adminNotes,
      'created_at': createdAt.toIso8601String(),
      'processed_at': processedAt?.toIso8601String(),
    };
  }

  RefundModel copyWith({
    String? id,
    String? paymentId,
    double? amount,
    String? reason,
    String? status,
    String? adminNotes,
    DateTime? createdAt,
    DateTime? processedAt,
  }) {
    return RefundModel(
      id: id ?? this.id,
      paymentId: paymentId ?? this.paymentId,
      amount: amount ?? this.amount,
      reason: reason ?? this.reason,
      status: status ?? this.status,
      adminNotes: adminNotes ?? this.adminNotes,
      createdAt: createdAt ?? this.createdAt,
      processedAt: processedAt ?? this.processedAt,
    );
  }

  @override
  String toString() {
    return 'RefundModel(id: $id, amount: $amount, reason: $reason, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RefundModel &&
        other.id == id &&
        other.paymentId == paymentId &&
        other.amount == amount &&
        other.reason == reason &&
        other.status == status;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        paymentId.hashCode ^
        amount.hashCode ^
        reason.hashCode ^
        status.hashCode;
  }

  // Helper methods
  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';
  bool get isProcessed => status == 'processed';

  String get statusText {
    switch (status) {
      case 'pending':
        return 'قيد المراجعة';
      case 'approved':
        return 'موافق عليه';
      case 'rejected':
        return 'مرفوض';
      case 'processed':
        return 'تم المعالجة';
      default:
        return status;
    }
  }

  String get formattedAmount {
    return '${amount.toStringAsFixed(2)} درهم';
  }

  String get shortId {
    return id.length > 8 ? '${id.substring(0, 8)}...' : id;
  }
}