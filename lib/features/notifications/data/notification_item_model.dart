class NotificationItem {
  const NotificationItem({
    required this.id,
    required this.responseKey,
    required this.titleKey,
    required this.subtitleKey,
    required this.iconCodePoint,
    required this.createdTime,
    required this.isRead,
    this.subtitleName,
    this.subtitleDate,
    this.payload = const <String, dynamic>{},
  });

  final String id;
  final String responseKey;
  final String titleKey;
  final String subtitleKey;
  final int iconCodePoint;
  final DateTime createdTime;
  final bool isRead;
  final String? subtitleName;
  final DateTime? subtitleDate;
  final Map<String, dynamic> payload;
}

class NotificationsData {
  const NotificationsData({
    required this.items,
    required this.totalCount,
    required this.hasMore,
  });

  final List<NotificationItem> items;
  final int totalCount;
  final bool hasMore;
}
