import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:upgrader/upgrader.dart';
import 'package:url_launcher/url_launcher.dart';

class StoreUpdateInfo {
  const StoreUpdateInfo({
    required this.updateRequired,
    required this.installedVersion,
    this.storeVersion,
    this.storeListingUrl,
  });

  final bool updateRequired;
  final String installedVersion;
  final String? storeVersion;
  final String? storeListingUrl;
}

class AppVersionService {
  AppVersionService._();

  static final AppVersionService instance = AppVersionService._();

  static const _androidStoreUrl =
      'https://play.google.com/store/apps/details?id=com.bombaycastingcompany.app';

  Upgrader _createUpgrader() {
    return Upgrader(
      debugLogging: kDebugMode,
      durationUntilAlertAgain: Duration.zero,
      countryCode: 'IN',
    );
  }

  bool get _shouldCheck =>
      !kDebugMode && (Platform.isAndroid || Platform.isIOS);

  Future<StoreUpdateInfo> checkForUpdate() async {
    if (!_shouldCheck) {
      return const StoreUpdateInfo(
        updateRequired: false,
        installedVersion: '',
      );
    }

    final upgrader = _createUpgrader();

    try {
      await upgrader.initialize();
      final updateRequired =
          upgrader.isUpdateAvailable() || upgrader.blocked();

      return StoreUpdateInfo(
        updateRequired: updateRequired,
        installedVersion: upgrader.currentInstalledVersion ?? '',
        storeVersion: upgrader.currentAppStoreVersion,
        storeListingUrl: upgrader.currentAppStoreListingURL,
      );
    } catch (error, stackTrace) {
      debugPrint('Store version check failed: $error\n$stackTrace');
      return StoreUpdateInfo(
        updateRequired: false,
        installedVersion: upgrader.currentInstalledVersion ?? '',
      );
    }
  }

  Future<void> openStoreListing(StoreUpdateInfo info) async {
    final url = info.storeListingUrl?.trim();
    final target = (url != null && url.isNotEmpty)
        ? url
        : (Platform.isAndroid ? _androidStoreUrl : null);

    if (target == null) {
      final upgrader = _createUpgrader();
      await upgrader.initialize();
      await upgrader.sendUserToAppStore();
      return;
    }

    await launchUrl(
      Uri.parse(target),
      mode: LaunchMode.externalApplication,
    );
  }
}
