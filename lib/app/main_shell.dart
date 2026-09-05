import 'package:bombay_casting/core/widgets/app_success_toast.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bombay_casting/app/app_state.dart';
import 'package:bombay_casting/core/deep_links/deep_link_target.dart';
import 'package:bombay_casting/core/navigation/app_navigation.dart';
import 'package:bombay_casting/core/theme/app_theme.dart';
import 'package:bombay_casting/core/widgets/app_bottom_nav.dart';
import 'package:bombay_casting/features/creators/screens/creators_screen.dart';
import 'package:bombay_casting/features/jobs/screens/home_screen.dart';
import 'package:bombay_casting/features/jobs/screens/job_detail_screen.dart';
import 'package:bombay_casting/features/jobs/screens/jobs_screen.dart';
import 'package:bombay_casting/features/messaging/screens/message_list_screen.dart';
import 'package:bombay_casting/features/profile/screens/user_profile_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;
  late final PageController _pageController;
  bool _openingDeepLink = false;
  bool _openingPendingMessage = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
    WidgetsBinding.instance.addPostFrameCallback((_) => _openPendingDeepLink());
  }

  Future<void> _openPendingDeepLink() async {
    if (!mounted || _openingDeepLink) return;
    final appState = context.read<AppState>();
    final target = appState.pendingDeepLink;
    if (target == null) return;
    appState.clearPendingDeepLink();
    _openingDeepLink = true;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
    );

    try {
      switch (target.kind) {
        case DeepLinkKind.creator:
          final creator = await appState.fetchCreatorById(target.id);
          if (!mounted) return;
          Navigator.of(context, rootNavigator: true).pop();
          if (creator == null) {
            _showMissing('Creator not found.');
            return;
          }
          AppNavigation.openCreatorProfile(context, creator);
          return;
        case DeepLinkKind.job:
          final job = await appState.fetchJobById(target.id);
          if (!mounted) return;
          Navigator.of(context, rootNavigator: true).pop();
          if (job == null) {
            _showMissing('Job not found.');
            return;
          }
          AppNavigation.openJobDetail(context, JobDetailData.fromJob(job));
          return;
        case DeepLinkKind.agency:
          final agency = await appState.fetchAgencyById(target.id);
          if (!mounted) return;
          Navigator.of(context, rootNavigator: true).pop();
          if (agency == null) {
            _showMissing('Agency not found.');
            return;
          }
          AppNavigation.openAgencyDetail(context, agency);
      }
    } catch (_) {
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      _showMissing('Could not open this link.');
    } finally {
      _openingDeepLink = false;
    }
  }

  void _showMissing(String message) {
    if (!mounted) return;
    showAppToast(context, message, type: AppToastType.error);
  }

  Future<void> _openPendingMessage() async {
    if (!mounted || _openingPendingMessage) return;
    _openingPendingMessage = true;
    try {
      final appState = context.read<AppState>();
      final thread = await appState.messaging?.consumePendingConversation();
      if (!mounted || thread == null) return;
      AppNavigation.openMessageDetail(context, thread);
    } finally {
      _openingPendingMessage = false;
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Widget _screenFor(int index) {
    switch (index) {
      case 0:
        return const HomeScreen();
      case 1:
        return const CreatorsScreen();
      case 2:
        return const JobsScreen();
      case 3:
        return const MessageListScreen();
      default:
        return const UserProfileScreen();
    }
  }

  void _onTabTapped(int index) {
    if (_currentIndex == index) return;
    FocusManager.instance.primaryFocus?.unfocus();
    context.read<AppState>().onMainShellTabSelected(index);
    setState(() => _currentIndex = index);
    _pageController.animateToPage(
      index,
      duration: AppDurations.tabSwitch,
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final pending = context.watch<AppState>().pendingDeepLink;
    if (pending != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _openPendingDeepLink());
    }
    final requestedTab = context.watch<AppState>().requestedMainShellTab;
    if (requestedTab != null && requestedTab != _currentIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final tab = context.read<AppState>().requestedMainShellTab;
        if (tab == null || tab == _currentIndex) return;
        _onTabTapped(tab);
        context.read<AppState>().clearRequestedMainShellTab();
      });
    }

    final pendingConversation =
        context.watch<AppState>().messaging?.pendingConversationId;
    if (pendingConversation != null && !_openingPendingMessage) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _openPendingMessage());
    }

    final unreadCount = context.watch<AppState>().unreadMessageCount;

    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: false,
      body: PageView.builder(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 5,
        onPageChanged: (index) => setState(() => _currentIndex = index),
        itemBuilder: (context, index) {
          return _KeepAlivePage(
            key: PageStorageKey<String>('main_tab_$index'),
            active: index == _currentIndex,
            child: _screenFor(index),
          );
        },
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        messageBadgeCount: unreadCount > 0 ? unreadCount : 3,
      ),
    );
  }
}

class _KeepAlivePage extends StatefulWidget {
  const _KeepAlivePage({
    super.key,
    required this.active,
    required this.child,
  });

  final bool active;
  final Widget child;

  @override
  State<_KeepAlivePage> createState() => _KeepAlivePageState();
}

class _KeepAlivePageState extends State<_KeepAlivePage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return ExcludeFocus(
      excluding: !widget.active,
      child: widget.child,
    );
  }
}
