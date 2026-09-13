import 'package:cloud_firestore/cloud_firestore.dart';

class HomeBanner {
  const HomeBanner({
    required this.id,
    required this.imageUrl,
    this.targetUrl,
    required this.isActive,
  });

  final String id;
  final String imageUrl;
  final String? targetUrl;
  final bool isActive;

  factory HomeBanner.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return HomeBanner(
      id: doc.id,
      imageUrl: data['imageUrl'] as String? ?? '',
      targetUrl: data['targetUrl'] as String?,
      isActive: data['isActive'] as bool? ?? false,
    );
  }
}
