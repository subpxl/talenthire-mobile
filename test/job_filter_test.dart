import 'package:flutter_test/flutter_test.dart';
import 'package:bombay_casting/features/jobs/models/job_listing.dart';
import 'package:bombay_casting/features/jobs/models/job_model.dart';

void main() {
  group('Home job chips', () {
    test('postedJobCities uses cities from jobs and skips remote', () {
      final mumbai = Job.fromJson({
        'id': 'job-mumbai',
        'title': 'Studio shoot',
        'location': 'Mumbai, Maharashtra',
        'location_type': 'onsite',
      });
      final delhi = Job.fromJson({
        'id': 'job-delhi',
        'title': 'Casting call',
        'location': 'Delhi NCR',
        'location_type': 'onsite',
      });
      final remote = Job.fromJson({
        'id': 'job-remote',
        'title': 'Voice over',
        'location': 'Open nationwide',
        'location_type': 'remote',
      });

      expect(postedJobCities([mumbai, delhi, remote]), ['Mumbai', 'Delhi']);
      expect(shortJobCity('Bengaluru, Karnataka'), 'Bengaluru');
    });

    test('city filter keeps matching city jobs only', () {
      final mumbai = Job.fromJson({
        'id': 'job-mumbai',
        'title': 'Studio shoot',
        'location': 'Mumbai, Maharashtra',
        'category': 'Model',
      });
      final delhi = Job.fromJson({
        'id': 'job-delhi',
        'title': 'Casting call',
        'location': 'Delhi NCR',
        'category': 'Actor',
      });
      final remote = Job.fromJson({
        'id': 'job-remote',
        'title': 'Voice over',
        'location': 'Open nationwide',
        'category': 'Musician',
      });

      expect(const HomeJobFilter(location: 'Mumbai').matchesJob(mumbai), isTrue);
      expect(const HomeJobFilter(location: 'Mumbai').matchesJob(delhi), isFalse);
      expect(const HomeJobFilter(location: 'Mumbai').matchesJob(remote), isFalse);
      expect(const HomeJobFilter(location: 'Delhi').matchesJob(delhi), isTrue);
    });

    test('category filter keeps matching talent types only', () {
      final influencer = Job.fromJson({
        'id': 'job-inf',
        'title': 'Brand reel',
        'category': 'Influencer',
      });
      final actor = Job.fromJson({
        'id': 'job-actor',
        'title': 'Casting',
        'category': 'Actor',
      });

      expect(
        const HomeJobFilter(categories: {'Influencer'}).matchesJob(influencer),
        isTrue,
      );
      expect(
        const HomeJobFilter(categories: {'Influencer'}).matchesJob(actor),
        isFalse,
      );
    });
  });
}
