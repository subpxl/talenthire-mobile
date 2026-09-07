import 'package:cloud_functions/cloud_functions.dart';

class AccountService {
  AccountService({FirebaseFunctions? functions})
      : _functions =
            functions ?? FirebaseFunctions.instanceFor(region: 'asia-south1');

  final FirebaseFunctions _functions;

  Future<void> deleteAccount() async {
    final callable = _functions.httpsCallable('deleteAccount');
    await callable.call();
  }
}
