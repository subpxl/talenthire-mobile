import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationInboxService {
  NotificationInboxService(this.userId);

  final String userId;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<Map<String, dynamic>>> watchNotifications() {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final items = snapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .toList();
      items.sort((a, b) {
        return _dateMs(b['created_at'] ?? b['createdAt'])
            .compareTo(_dateMs(a['created_at'] ?? a['createdAt']));
      });
      return items;
    });
  }

  Future<void> markRead(String notificationId) {
    return _firestore.collection('notifications').doc(notificationId).update({
      'read': true,
    });
  }

  Future<void> markAllRead(Iterable<String> notificationIds) async {
    final ids = notificationIds.toList();
    if (ids.isEmpty) return;
    const chunkSize = 400;
    for (var i = 0; i < ids.length; i += chunkSize) {
      final end = i + chunkSize > ids.length ? ids.length : i + chunkSize;
      final batch = _firestore.batch();
      for (final id in ids.sublist(i, end)) {
        batch.update(_firestore.collection('notifications').doc(id), {
          'read': true,
        });
      }
      await batch.commit();
    }
  }

  int _dateMs(dynamic value) {
    if (value is Timestamp) return value.millisecondsSinceEpoch;
    if (value is DateTime) return value.millisecondsSinceEpoch;
    if (value is String) {
      return DateTime.tryParse(value)?.millisecondsSinceEpoch ?? 0;
    }
    if (value is num) {
      return value > 20000000000 ? value.toInt() : value.toInt() * 1000;
    }
    return 0;
  }
}
