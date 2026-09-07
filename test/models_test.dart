import 'package:flutter_test/flutter_test.dart';
import 'package:bombay_casting/core/models/models.dart';
import 'package:bombay_casting/features/creators/models/creator_profile.dart';
import 'package:bombay_casting/features/jobs/models/job_listing.dart';
import 'package:bombay_casting/features/jobs/screens/job_detail_screen.dart';

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

    // Removed test: 'uses job fields for role type and pay instead of placeholders'

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
        'min_followers': ?minFollowers,
        'pay_min': ?payMin,
        'pay_max': ?payMax,
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

    test('search matches title, agency, and location', () {
      final job = Job.fromJson({
        'id': 'job-search',
        'title': 'Beauty reel campaign',
        'company': 'Glow Labs',
        'location': 'Mumbai, Maharashtra',
        'location_type': 'onsite',
        'category': 'Beauty',
      });
      expect(
        const HomeJobFilter(searchQuery: 'glow mumbai').matchesJob(job),
        isTrue,
      );
      expect(
        const HomeJobFilter(searchQuery: 'delhi').matchesJob(job),
        isFalse,
      );
    });

    test('city chips filter jobs by posted city', () {
      final mumbai = Job.fromJson({
        'id': 'job-mumbai',
        'title': 'Studio shoot',
        'location': 'Mumbai, Maharashtra',
        'location_type': 'onsite',
        'category': 'Model',
      });
      final delhi = Job.fromJson({
        'id': 'job-delhi',
        'title': 'Casting call',
        'location': 'Delhi NCR',
        'location_type': 'onsite',
        'category': 'Actor',
      });
      final remote = Job.fromJson({
        'id': 'job-remote',
        'title': 'Voice over',
        'location': 'Open nationwide',
        'location_type': 'remote',
        'category': 'Musician',
      });

      expect(const HomeJobFilter(location: 'Mumbai').matchesJob(mumbai), isTrue);
      expect(const HomeJobFilter(location: 'Mumbai').matchesJob(delhi), isFalse);
      expect(const HomeJobFilter(location: 'Mumbai').matchesJob(remote), isFalse);
      expect(const HomeJobFilter(location: 'Delhi').matchesJob(delhi), isTrue);
      expect(
        postedJobCities([mumbai, delhi, remote]),
        ['Mumbai', 'Delhi'],
      );
    });

    test('category chips filter jobs by talent type', () {
      expect(
        const HomeJobFilter(categories: {'Influencer'}).matchesJob(
          job(category: 'Influencer'),
        ),
        isTrue,
      );
      expect(
        const HomeJobFilter(categories: {'Influencer'}).matchesJob(
          job(category: 'Actor'),
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

  group('CreatorProfile filters', () {
    CreatorProfile creator({
      String name = 'Asha Khan',
      String title = 'Actor',
      String location = 'Mumbai, Maharashtra',
    }) {
      return CreatorProfile(
        id: 'c-1',
        name: name,
        title: title,
        location: location,
        photos: const [CreatorPhoto()],
        workInfo: [MapEntry('Role', title)],
      );
    }

    test('search matches name, location, and talent', () {
      final profile = creator();
      expect(profile.matchesSearch('asha mumbai actor'), isTrue);
      expect(profile.matchesSearch('delhi'), isFalse);
    });

    test('talent chip matches role', () {
      expect(creator().matchesTalent('All'), isTrue);
      expect(creator().matchesTalent('Actor'), isTrue);
      expect(creator(title: 'Dancer').matchesTalent('Actor'), isFalse);
    });
  });
}
