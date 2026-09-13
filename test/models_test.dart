import 'package:flutter/material.dart';
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
      expect(job.collabTypeLabel, 'Paid');
      expect(job.roleLabel, 'Beauty');
      expect(job.payLabel, '₹8,000');
      expect(job.payMin, 8000);
      expect(job.payMax, 8000);
    });

    test('parses application_deadline from firestore fields', () {
      final job = Job.fromJson({
        'id': 'job-deadline',
        'title': 'Casting call',
        'posted_at': '2026-09-10T10:00:00.000Z',
        'application_deadline': '2026-10-10T18:29:59.999Z',
      });

      expect(job.applicationDeadline, DateTime.parse('2026-10-10T18:29:59.999Z'));
      expect(
        job.toJson()['application_deadline'],
        DateTime.parse('2026-10-10T18:29:59.999Z').toIso8601String(),
      );
    });

    test('parses firestore timestamp maps and job-post aliases', () {
      final deadline = DateTime.utc(2026, 11, 2, 18, 29, 59);
      final job = Job.fromJson({
        'id': 'job-post-fields',
        'title': 'Lead Actor',
        'artist_type': 'Actor',
        'locationType': 'onsite',
        'location': 'Mumbai, Maharashtra',
        'gender_required': 'female',
        'createdAt': {'_seconds': 1757491200, '_nanoseconds': 0},
        'application_deadline': {
          'seconds': deadline.millisecondsSinceEpoch ~/ 1000,
          'nanoseconds': 0,
        },
      });

      expect(job.category, 'Actor');
      expect(job.locationType, LocationType.onsite);
      expect(job.location, 'Mumbai, Maharashtra');
      expect(job.gender, 'female');
      expect(
        job.applicationDeadline?.toUtc(),
        DateTime.utc(2026, 11, 2, 18, 29, 59),
      );

      final listing = JobListing.fromJob(job, 0);
      expect(jobArtistTypeLabel(listing), 'Actor');
      expect(jobWorkTypeLabel(listing), 'Onsite');
      expect(jobGenderLabel(listing.gender), 'Female');
      expect(shortJobCity(listing.location), 'Mumbai');
      expect(
        jobApplyByLabel(job.postedAt, deadline: job.applicationDeadline),
        isNot('24 Sep'),
      );
    });

    test('reads Timestamp.toDate style application deadlines', () {
      final job = Job.fromJson({
        'id': 'job-timestamp',
        'title': 'Onsite model call',
        'posted_at': '2026-09-10T10:00:00.000Z',
        'application_deadline': _FakeTimestamp(
          DateTime.utc(2026, 12, 1, 18, 29, 59),
        ),
      });

      expect(job.applicationDeadline, DateTime.utc(2026, 12, 1, 18, 29, 59));
      expect(
        jobApplyByLabel(job.postedAt, deadline: job.applicationDeadline),
        isNot('24 Sep'),
      );
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

    test('parses plain numeric pay ranges from compensation text', () {
      final job = Job.fromJson({
        'id': 'job-pay-text',
        'title': 'Lead role',
        'compensation': '600000-800000',
      });

      expect(job.payMin, 600000);
      expect(job.payMax, 800000);
      expect(jobPayCompactLabel(JobListing.fromJob(job, 0)), '6L–8L');
    });
  });

  group('jobPayCompactLabel', () {
    JobListing sampleListing({
      String pay = '',
      int payMin = 0,
      int payMax = 0,
    }) {
      return JobListing(
        title: 'Campaign',
        details: 'Paid · Lifestyle',
        location: 'Mumbai, Maharashtra',
        seenStatus: 'Posted 1 hr ago',
        avatarColor: const Color(0xFF7986CB),
        imageIndex: 1,
        pay: pay,
        payMin: payMin,
        payMax: payMax,
      );
    }

    test('prefers pay bounds over descriptive compensation text', () {
      expect(
        jobPayCompactLabel(
          sampleListing(
            pay: 'Paid collaboration',
            payMin: 600000,
            payMax: 800000,
          ),
        ),
        '6L–8L',
      );
    });

    test('shortens undisclosed descriptive pay text', () {
      expect(
        jobPayCompactLabel(
          sampleListing(pay: 'To be disclosed based on experience'),
        ),
        'Undisclosed',
      );
    });

    test('parses numeric pay text without rupee symbol', () {
      expect(
        jobPayCompactLabel(sampleListing(pay: '600000-800000')),
        '6L–8L',
      );
    });
  });

  group('Job apply-by date', () {
    test('uses the stored application deadline instead of postedAt + 14 days', () {
      final postedAt = DateTime(2026, 9, 10);
      final deadline = DateTime(2026, 10, 10, 23, 59, 59);

      expect(jobApplyBy(postedAt, deadline: deadline), deadline);
      expect(jobApplyByLabel(postedAt, deadline: deadline), '10 Oct');
      expect(
        jobApplyByLabel(postedAt),
        isNot('24 Sep'),
      );
    });

    test('falls back to 30 days after posting when no deadline is stored', () {
      final postedAt = DateTime(2026, 9, 10);

      expect(jobApplyBy(postedAt), DateTime(2026, 10, 10));
      expect(jobApplyByLabel(postedAt), '10 Oct');
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
      expect(
        filter.matchesJob(
          job(collaborationType: 'paid', payMin: 20000, payMax: 30000),
        ),
        isTrue,
      );
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

class _FakeTimestamp {
  const _FakeTimestamp(this._date);

  final DateTime _date;

  DateTime toDate() => _date;
}
