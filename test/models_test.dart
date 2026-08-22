import 'package:flutter_test/flutter_test.dart';
import 'package:bombay_casting/data/job_assets.dart';
import 'package:bombay_casting/models/models.dart';
import 'package:bombay_casting/screens/job_detail_screen.dart';

void main() {
  group('Job', () {
    test('parses influencer marketplace fields and legacy aliases', () {
      final job = Job.fromJson({
        'id': 'job-001',
        'title': 'Beauty reel campaign',
        'description': 'Create a short product reel.',
        'company': 'Glow Labs',
        'status': 'open',
        'location_type': 'remote',
        'image_url': 'https://example.com/poster.jpeg',
        'image_path': 'job-images/job-001/poster.jpeg',
        'category': 'Beauty',
        'platforms': ['Instagram'],
        'collaboration_type': 'paid',
        'compensation': '₹8,000',
        'deliverables': ['1 Reel', '2 Stories'],
        'is_verified': true,
      });

      expect(job.status, JobStatus.published);
      expect(job.imagePath, 'job-images/job-001/poster.jpeg');
      expect(job.platforms, ['Instagram']);
      expect(job.deliverables, hasLength(2));
      expect(job.isVerified, isTrue);
      expect(job.collabTypeLabel, 'Paid collab');
      expect(job.roleLabel, 'Beauty');
      expect(job.payLabel, '₹8,000');
      expect(job.payMin, 8000);
      expect(job.payMax, 8000);
    });

    test('uses job fields for role type and pay instead of placeholders', () {
      final job = Job.fromJson({
        'id': 'job-002',
        'title': 'FTII Casting Call',
        'category': 'Actor',
        'platforms': ['Film'],
        'collaboration_type': 'audition',
        'compensation': 'Project-based',
        'deliverables': ['Acting self-tape', 'Current profile'],
        'tags': ['Actor', 'Film', 'audition'],
      });
      final detail = JobDetailData.fromJob(job);

      expect(
        Map.fromEntries(detail.roleInfo),
        {
          'Role': 'Actor',
          'Platform': 'Film',
          'Type': 'Audition',
          'Followers': 'Open to creators',
        },
      );
      expect(
        Map.fromEntries(detail.payInfo),
        {
          'Category': 'Film',
          'Duration': 'Acting self-tape, Current profile',
          'Pay': 'Project-based',
        },
      );
    });

    test('reads explicit follower and pay bounds from json', () {
      final job = Job.fromJson({
        'id': 'job-003',
        'title': 'Paid reel',
        'category': 'Influencer',
        'collaboration_type': 'paid',
        'compensation': 'Paid collaboration',
        'min_followers': 25000,
        'pay_min': 20000,
        'pay_max': 60000,
      });

      expect(job.minFollowers, 25000);
      expect(job.followersLabel, '25K+ preferred');
      expect(job.payMin, 20000);
      expect(job.payMax, 60000);
    });
  });

  group('HomeJobFilter', () {
    Job job({
      String category = 'Actor',
      String collaborationType = 'audition',
      String compensation = 'Project-based',
      int? minFollowers,
      int? payMin,
      int? payMax,
    }) {
      return Job.fromJson({
        'id': 'job-$category-$collaborationType',
        'title': '$category role',
        'category': category,
        'collaboration_type': collaborationType,
        'compensation': compensation,
        if (minFollowers != null) 'min_followers': minFollowers,
        if (payMin != null) 'pay_min': payMin,
        if (payMax != null) 'pay_max': payMax,
      });
    }

    test('follower slider excludes jobs outside the selected range', () {
      const filter = HomeJobFilter(followerStart: 10, followerEnd: 50);
      expect(filter.matchesJob(job(category: 'Influencer')), isTrue);
      expect(filter.matchesJob(job(category: 'Actor')), isFalse);
      expect(
        filter.matchesJob(job(category: 'Influencer', minFollowers: 80000)),
        isFalse,
      );
    });

    test('pay slider excludes jobs outside the selected range', () {
      const filter = HomeJobFilter(payStart: 15000, payEnd: 40000);
      expect(filter.matchesJob(job(collaborationType: 'paid')), isTrue);
      expect(filter.matchesJob(job(collaborationType: 'audition')), isFalse);
      expect(
        filter.matchesJob(
          job(collaborationType: 'paid', payMin: 80000, payMax: 120000),
        ),
        isFalse,
      );
    });

    test('default slider values do not hide jobs', () {
      const filter = HomeJobFilter();
      expect(filter.isActive, isFalse);
      expect(filter.matchesJob(job(category: 'Influencer')), isTrue);
      expect(filter.matchesJob(job(collaborationType: 'paid')), isTrue);
    });
  });

  group('Profile', () {
    test('parses creator niches and platform metrics', () {
      final profile = Profile.fromJson({
        'user_id': 'creator-1',
        'niches': ['Tech', 'Gaming'],
        'platform_metrics': [
          {
            'platform': 'YouTube',
            'handle': '@creator',
            'followers': 125000,
            'url': 'https://youtube.com/@creator',
          },
        ],
      });

      expect(profile.niches, ['Tech', 'Gaming']);
      expect(profile.platformMetrics.single.followers, 125000);
      expect(profile.platformMetrics.single.handle, '@creator');
    });
  });
}
