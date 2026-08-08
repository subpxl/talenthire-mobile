import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/notification_service.dart';
import '../providers/app_state.dart';
import '../utils/app_back_handler.dart';
import 'home_screen.dart';
import 'artists_screen.dart';
import 'jobs_screen.dart';
import 'messages_screen.dart';
import 'profile_screen.dart';
import '../widgets/app_bottom_nav_bar.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  static final GlobalKey<MainScreenState> mainKey = GlobalKey<MainScreenState>();

  @override
  State<MainScreen> createState() => MainScreenState();

  static void switchTab(int index) {
    mainKey.currentState?.switchToTab(index);
  }
}

class MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  static const List<Widget> _influencerPages = <Widget>[
    HomeScreen(),
    ArtistsScreen(),
    JobsScreen(),
    MessagesScreen(),
    ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  void switchToTab(int index) {
    setState(() => _selectedIndex = index);
  }

  int get selectedIndex => _selectedIndex;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationService().processPendingNavigation();
    });
  }

  void _goToHomeTab() {
    setState(() => _selectedIndex = 0);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        handleMainScreenBack(
          context,
          selectedTabIndex: _selectedIndex,
          goToHomeTab: _goToHomeTab,
        );
      },
      child: Scaffold(
        body: IndexedStack(
          index: _selectedIndex,
          children: _influencerPages,
        ),
        bottomNavigationBar: AppBottomNavBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: _onItemTapped,
        ),
      ),
    );
  }
}
