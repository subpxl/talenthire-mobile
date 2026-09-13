import 'dart:io';

import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class StoreUpdateInfo {
  const StoreUpdateInfo({
    required this.updateRequired,
    required this.installedVersion,
    this.storeVersion,
    this.storeListingUrl,
    this.message,
  });

  final bool updateRequired;
  final String installedVersion;
  final String? storeVersion;
  final String? storeListingUrl;
  final String? message;
}

class AppVersionService {
  AppVersionService._();

  static final AppVersionService instance = AppVersionService._();

  /// Current production APK on device / Play: versionName 1.0.0, versionCode 22.
  static const currentMinBuild = 22;
  static const currentMinVersion = '1.0.0';

  static const minAndroidBuildKey = 'min_android_build';
  static const minIosBuildKey = 'min_ios_build';
  static const minVersionKey = 'min_version';
  static const androidStoreUrlKey = 'android_store_url';
  static const iosStoreUrlKey = 'ios_store_url';
  static const forceUpdateMessageKey = 'force_update_message';

  static const _androidStoreUrl =
      'https://play.google.com/store/apps/details?id=com.bombaycastingcompany.app';
  static const _defaultMessage =
      'A new version is available on the app store. Please update to continue using the app.';

  bool get _shouldCheck => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  Future<StoreUpdateInfo> checkForUpdate() async {
    if (!_shouldCheck) {
      return const StoreUpdateInfo(
        updateRequired: false,
        installedVersion: '',
      );
    }

    final packageInfo = await PackageInfo.fromPlatform();
    final installedBuild = int.tryParse(packageInfo.buildNumber) ?? 0;
    final installedVersion = '${packageInfo.version}+$installedBuild';

    try {
      final remoteConfig = FirebaseRemoteConfig.instance;
      await remoteConfig.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 10),
          minimumFetchInterval:
              kDebugMode ? Duration.zero : const Duration(hours: 1),
        ),
      );
      await remoteConfig.setDefaults({
        minAndroidBuildKey: currentMinBuild,
        minIosBuildKey: currentMinBuild,
        minVersionKey: currentMinVersion,
        androidStoreUrlKey: _androidStoreUrl,
        iosStoreUrlKey: '',
        forceUpdateMessageKey: _defaultMessage,
      });
      await remoteConfig.fetchAndActivate();

      final minBuild = Platform.isIOS
          ? remoteConfig.getInt(minIosBuildKey)
          : remoteConfig.getInt(minAndroidBuildKey);
      final minVersion = remoteConfig.getString(minVersionKey);
      final storeUrl = Platform.isIOS
          ? remoteConfig.getString(iosStoreUrlKey)
          : remoteConfig.getString(androidStoreUrlKey);
      final message = remoteConfig.getString(forceUpdateMessageKey);

      return StoreUpdateInfo(
        updateRequired: installedBuild < minBuild,
        installedVersion: installedVersion,
        storeVersion: minVersion.isEmpty
            ? minBuild.toString()
            : '$minVersion+$minBuild',
        storeListingUrl: (storeUrl.trim().isNotEmpty)
            ? storeUrl.trim()
            : (Platform.isAndroid ? _androidStoreUrl : null),
        message: message.trim().isEmpty ? _defaultMessage : message.trim(),
      );
    } catch (error, stackTrace) {
      debugPrint('Remote Config version check failed: $error\n$stackTrace');
      return StoreUpdateInfo(
        updateRequired: installedBuild < currentMinBuild,
        installedVersion: installedVersion,
        storeVersion: '$currentMinVersion+$currentMinBuild',
        storeListingUrl: Platform.isAndroid ? _androidStoreUrl : null,
        message: _defaultMessage,
      );
    }
  }

  Future<void> openStoreListing(StoreUpdateInfo info) async {
    final url = info.storeListingUrl?.trim();
    final target = (url != null && url.isNotEmpty)
        ? url
        : (Platform.isAndroid ? _androidStoreUrl : null);

    if (target == null) return;

    await launchUrl(
      Uri.parse(target),
      mode: LaunchMode.externalApplication,
    );
  }
}
