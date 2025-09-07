class NotificationModel {
  final String id;
  final String userId;
  final String title;
  final String message;
  final String type;
  final bool isRead;
  final Map<String, dynamic>? data;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.type,
    required this.isRead,
    this.data,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      type: json['type'] ?? 'info',
      isRead: json['is_read'] ?? false,
      data: json['data'] != null ? Map<String, dynamic>.from(json['data']) : null,
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'message': message,
      'type': type,
      'is_read': isRead,
      'data': data,
      'created_at': createdAt.toIso8601String(),
    };
  }

  NotificationModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? message,
    String? type,
    bool? isRead,
    Map<String, dynamic>? data,
    DateTime? createdAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      isRead: isRead ?? this.isRead,
      data: data ?? this.data,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'NotificationModel(id: $id, title: $title, message: $message, type: $type, isRead: $isRead)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NotificationModel &&
        other.id == id &&
        other.userId == userId &&
        other.title == title &&
        other.message == message &&
        other.type == type &&
        other.isRead == isRead;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        userId.hashCode ^
        title.hashCode ^
        message.hashCode ^
        type.hashCode ^
        isRead.hashCode;
  }
}