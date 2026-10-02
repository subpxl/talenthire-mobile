import 'package:bombay_casting/features/creators/models/creator_profile.dart';

/// Premium first, then completed profiles with photos (more photos rank higher),
/// then partially filled profiles, then the rest. [id] breaks ties so equal
/// rows do not swap on every merge.
int compareCreatorsForFeed(CreatorProfile a, CreatorProfile b) {
  final scoreDiff = b.profileScore.compareTo(a.profileScore);
  if (scoreDiff != 0) return scoreDiff;

  final aTime = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
  final bTime = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
  final timeDiff = bTime.compareTo(aTime);
  if (timeDiff != 0) return timeDiff;

  return a.id.compareTo(b.id);
}

void sortCreatorsForFeed(List<CreatorProfile> creators) {
  creators.sort(compareCreatorsForFeed);
}

/// Places [candidate] in [feed] using the same rules as everyone else.
List<CreatorProfile> integrateRankedCreator({
  required List<CreatorProfile> feed,
  required CreatorProfile candidate,
}) {
  final others = feed.where((c) => c.id != candidate.id).toList();
  if (others.isEmpty) return [candidate];
  final insertAt = insertIndexForCreator(candidate, others);
  others.insert(insertAt, candidate);
  return others;
}

int insertIndexForCreator(
  CreatorProfile creator,
  List<CreatorProfile> sorted,
) {
  var low = 0;
  var high = sorted.length;
  while (low < high) {
    final mid = low + ((high - low) >> 1);
    if (compareCreatorsForFeed(creator, sorted[mid]) < 0) {
      high = mid;
    } else {
      low = mid + 1;
    }
  }
  return low;
}
