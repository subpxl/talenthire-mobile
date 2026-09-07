import 'package:cloud_functions/cloud_functions.dart';
import 'package:bombay_casting/core/models/models.dart';
import 'package:bombay_casting/features/jobs/models/application_model.dart';

enum SubmitApplicationFailure {
  dailyLimit,
  trialEnded,
  alreadyApplied,
  notFound,
  unauthenticated,
  other,
}

class SubmitApplicationResult {
  const SubmitApplicationResult._({
    this.application,
    this.failure,
  });

  const SubmitApplicationResult.success(Application application)
      : this._(application: application);

  const SubmitApplicationResult.failure(SubmitApplicationFailure failure)
      : this._(failure: failure);

  final Application? application;
  final SubmitApplicationFailure? failure;

  bool get isSuccess => application != null;
}

class ApplicationService {
  ApplicationService({FirebaseFunctions? functions})
      : _functions =
            functions ?? FirebaseFunctions.instanceFor(region: 'asia-south1');

  final FirebaseFunctions _functions;

  Future<SubmitApplicationResult> submit({
    required String jobId,
    String script = '',
    String youtubeShortUrl = '',
  }) async {
    try {
      final callable = _functions.httpsCallable('submitJobApplication');
      final response = await callable.call<Map<String, dynamic>>({
        'jobId': jobId,
        'script': script,
        'youtubeShortUrl': youtubeShortUrl,
      });
      final raw = response.data['application'];
      if (raw is! Map) {
        return const SubmitApplicationResult.failure(
          SubmitApplicationFailure.other,
        );
      }
      return SubmitApplicationResult.success(
        Application.fromJson(Map<String, dynamic>.from(raw)),
      );
    } on FirebaseFunctionsException catch (error) {
      return SubmitApplicationResult.failure(_mapFailure(error));
    } catch (_) {
      return const SubmitApplicationResult.failure(
        SubmitApplicationFailure.other,
      );
    }
  }

  SubmitApplicationFailure _mapFailure(FirebaseFunctionsException error) {
    if (error.code == 'unauthenticated') {
      return SubmitApplicationFailure.unauthenticated;
    }
    if (error.code == 'already-exists') {
      return SubmitApplicationFailure.alreadyApplied;
    }
    if (error.code == 'not-found') {
      return SubmitApplicationFailure.notFound;
    }
    if (error.code == 'resource-exhausted') {
      final details = error.details;
      if (details is Map) {
        final reason = details['reason']?.toString();
        if (reason == 'daily_limit') {
          return SubmitApplicationFailure.dailyLimit;
        }
        if (reason == 'trial_ended') {
          return SubmitApplicationFailure.trialEnded;
        }
      }
      return SubmitApplicationFailure.dailyLimit;
    }
    return SubmitApplicationFailure.other;
  }
}
