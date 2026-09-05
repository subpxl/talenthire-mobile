import 'package:flutter/material.dart';
import 'package:bombay_casting/app/app.dart';
import 'package:bombay_casting/core/services/app_version_service.dart';
import 'package:bombay_casting/features/app_update/screens/force_update_screen.dart';
import 'package:bombay_casting/features/auth/screens/splash_screen.dart';

class VersionGate extends StatefulWidget {
  const VersionGate({super.key});

  @override
  State<VersionGate> createState() => _VersionGateState();
}

class _VersionGateState extends State<VersionGate> with WidgetsBindingObserver {
  StoreUpdateInfo? _info;
  bool _minTimeElapsed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkForUpdate();
    Future<void>.delayed(const Duration(milliseconds: 1400), () {
      if (mounted) setState(() => _minTimeElapsed = true);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkForUpdate();
    }
  }

  Future<void> _checkForUpdate() async {
    final result = await AppVersionService.instance.checkForUpdate();
    if (!mounted) return;
    setState(() => _info = result);
  }

  @override
  Widget build(BuildContext context) {
    final info = _info;
    if (info == null || !_minTimeElapsed) {
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: SplashScreen(),
      );
    }

    if (info.updateRequired) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: ForceUpdateScreen(info: info),
      );
    }

    return const App();
  }
}
