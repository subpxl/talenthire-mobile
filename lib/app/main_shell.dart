import 'package:flutter/material.dart';
import 'package:bombay_casting/features/creators/screens/creators_screen.dart';
import 'package:bombay_casting/features/jobs/screens/home_screen.dart';
import 'package:bombay_casting/features/messaging/screens/message_list_screen.dart';
import 'package:bombay_casting/features/messaging/screens/messages_list_screen.dart';
import 'package:bombay_casting/features/profile/screens/user_profile_screen.dart';
import 'package:bombay_casting/core/theme/app_theme.dart';
import 'package:bombay_casting/core/widgets/app_bottom_nav.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
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
        return const MessagesListScreen();
      case 3:
        return const MessageListScreen();
      default:
        return const UserProfileScreen();
    }
  }

  void _onTabTapped(int index) {
    if (_currentIndex == index) return;
    setState(() => _currentIndex = index);
    _pageController.animateToPage(
      index,
      duration: AppDurations.tabSwitch,
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: PageView.builder(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 5,
        onPageChanged: (index) => setState(() => _currentIndex = index),
        itemBuilder: (context, index) {
          return _KeepAlivePage(
            key: PageStorageKey<String>('main_tab_$index'),
            child: _screenFor(index),
          );
        },
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
      ),
    );
  }
}

class _KeepAlivePage extends StatefulWidget {
  const _KeepAlivePage({super.key, required this.child});

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
    return widget.child;
  }
}
