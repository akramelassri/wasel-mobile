class DriverNotification {
  final String id;
  final String type;
  final String title;
  final String body;
  final String status;
  final DateTime sentAt;

  const DriverNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.status,
    required this.sentAt,
  });

  bool get isUnread => status == 'UNREAD';

  factory DriverNotification.fromJson(Map<String, dynamic> json) {
    final createdAt = json['createdAt'];
    DateTime sentAt;

    if (createdAt is String) {
      sentAt = DateTime.tryParse(createdAt) ?? DateTime.now();
    } else if (createdAt is int) {
      sentAt = DateTime.fromMillisecondsSinceEpoch(createdAt);
    } else {
      sentAt = DateTime.now();
    }

    return DriverNotification(
      id: json['id'].toString(),
      type: json['type'] as String? ?? 'UNKNOWN',
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      status: json['status'] as String? ?? 'UNREAD',
      sentAt: sentAt,
    );
  }
}
