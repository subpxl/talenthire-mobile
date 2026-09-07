import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:bombay_casting/core/theme/app_theme.dart';

class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.read,
    required this.createdAt,
    this.conversationId = '',
    this.jobId = '',
    this.senderId = '',
  });

  final String id;
  final String title;
  final String body;
  final String type;
  final bool read;
  final DateTime? createdAt;
  final String conversationId;
  final String jobId;
  final String senderId;

  bool get isMessage => type == 'new_message' && conversationId.isNotEmpty;
  bool get isJob => jobId.isNotEmpty || type == 'job' || type == 'new_job';
  bool get isApplication =>
      type == 'application' || type == 'application_viewed';
  bool get isProfile => type == 'profile';

  String get timeLabel => _formatNotificationTime(createdAt);

  IconData get icon {
    if (isMessage) return Icons.chat_bubble_outline;
    if (isJob) return Icons.work_outline;
    if (isApplication) return Icons.visibility_outlined;
    if (isProfile) return Icons.person_outline;
    return Icons.campaign_outlined;
  }

  Color get iconColor {
    if (isMessage) return AppColors.chatGreen;
    if (isJob) return AppColors.primary;
    if (isApplication) return const Color(0xFF1565C0);
    if (isProfile) return const Color(0xFF6A1B9A);
    return AppColors.primary;
  }

  AppNotification copyWith({bool? read}) {
    return AppNotification(
      id: id,
      title: title,
      body: body,
      type: type,
      read: read ?? this.read,
      createdAt: createdAt,
      conversationId: conversationId,
      jobId: jobId,
      senderId: senderId,
    );
  }

  factory AppNotification.fromFirestore(
    String id,
    Map<String, dynamic> data,
  ) {
    return AppNotification(
      id: id,
      title: (data['title'] ?? '').toString(),
      body: (data['body'] ?? data['message'] ?? '').toString(),
      type: (data['type'] ?? 'admin').toString(),
      read: data['read'] == true,
      createdAt: _parseDate(data['created_at'] ?? data['createdAt']),
      conversationId: (data['conversationId'] ?? data['conversation_id'] ?? '')
          .toString(),
      jobId: (data['jobId'] ?? data['job_id'] ?? '').toString(),
      senderId: (data['senderId'] ?? data['sender_id'] ?? '').toString(),
    );
  }
}

DateTime? _parseDate(dynamic value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value);
  if (value is num) {
    final millis = value > 20000000000 ? value.toInt() : value.toInt() * 1000;
    return DateTime.fromMillisecondsSinceEpoch(millis);
  }
  return null;
}

String _formatNotificationTime(DateTime? date) {
  if (date == null) return '';
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(date.year, date.month, date.day);
  if (day == today) {
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }
  if (day == today.subtract(const Duration(days: 1))) {
    return 'Yesterday';
  }
  return '${date.day}/${date.month}/${date.year}';
}
