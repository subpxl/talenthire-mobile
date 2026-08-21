import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/app_avatar.dart';
import '../widgets/optimized_network_image.dart';
import '../widgets/empty_state.dart';
import '../widgets/app_bottom_nav_bar.dart';
import '../widgets/loading_dialog.dart';
import 'main_screen.dart';
import 'message_detail_screen.dart';
class AgencyDetailScreen extends StatefulWidget {
  final String agencyId;
  final String? fallbackName;

  const AgencyDetailScreen({
    super.key,
    required this.agencyId,
    this.fallbackName,
  });

  @override
  State<AgencyDetailScreen> createState() => _AgencyDetailScreenState();
}

class _AgencyDetailScreenState extends State<AgencyDetailScreen> {
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _agency;

  @override
  void initState() {
    super.initState();
    _loadAgency();
  }

  Future<void> _loadAgency() async {
    if (widget.agencyId.isEmpty) {
      setState(() {
        _loading = false;
        _error = 'Agency profile unavailable';
      });
      return;
    }

    try {
      final snap =
          await FirebaseFirestore.instance.collection('users').doc(widget.agencyId).get();
      if (!snap.exists) {
        setState(() {
          _loading = false;
          _error = 'Agency not found';
        });
        return;
      }

      final data = snap.data()!;
      final role = (data['role'] ?? '').toString();
      if (role.isNotEmpty && role != 'agency') {
        setState(() {
          _loading = false;
          _error = 'Agency not found';
        });
        return;
      }

      setState(() {
        _agency = data;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = 'Could not load agency';
      });
    }
  }

  String get _name {
    final fromDoc = (_agency?['agencyName'] ?? _agency?['agency_name'] ?? '').toString();
    if (fromDoc.isNotEmpty) return fromDoc;
    return widget.fallbackName?.isNotEmpty == true ? widget.fallbackName! : 'Agency';
  }

  String get _details =>
      (_agency?['profileDetails'] ?? _agency?['profile_details'] ?? '').toString();

  String get _logoUrl => (_agency?['logoUrl'] ?? _agency?['logo_url'] ?? '').toString();

  String get _email => (_agency?['email'] ?? '').toString();

  List<String> get _previousWorks {
    final raw = _agency?['previousWorks'] ?? _agency?['previous_works'];
    if (raw is List) {
      return raw.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
    }
    return const [];
  }

  String get _initials {
    final parts = _name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    if (_name.isNotEmpty) {
      return _name.substring(0, _name.length >= 2 ? 2 : 1).toUpperCase();
    }
    return 'AG';
  }

  void _startChat(BuildContext context) async {
    final state = context.read<AppState>();
    
    LoadingDialog.show(context, message: 'Starting chat...');
    final conversation = await state.getOrCreateConversation(_name, widget.agencyId);
    if (!context.mounted) return;
    LoadingDialog.hide(context);

    if (conversation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You cannot message yourself.')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MessageDetailScreen(conversation: conversation),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Agency')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? EmptyState(
                  icon: Icons.business_outlined,
                  title: _error!,
                  subtitle: widget.fallbackName,
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (_logoUrl.isNotEmpty)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(40),
                              child: OptimizedNetworkImage(
                                imageUrl: _logoUrl,
                                width: 72,
                                height: 72,
                                fit: BoxFit.cover,
                                borderRadius: BorderRadius.circular(40),
                                errorWidget: AppAvatar(radius: 36, initials: _initials),
                              ),
                            )
                          else
                            AppAvatar(radius: 36, initials: _initials),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _name,
                                  style: context.text.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (_email.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    _email,
                                    style: const TextStyle(color: AppColors.textSecondary),
                                  ),
                                ],
                                const SizedBox(height: 12),
                                ElevatedButton.icon(
                                  onPressed: () => _startChat(context),
                                  icon: const Icon(Icons.chat_bubble_outline, size: 20),
                                  label: const Text('Message'),
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'About',
                        style: context.text.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _details.isNotEmpty ? _details : 'No agency description provided.',
                        style: const TextStyle(height: 1.5),
                      ),
                      if (_previousWorks.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        Text(
                          'Previous Work',
                          style: context.text.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 140,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: _previousWorks.length,
                            separatorBuilder: (_, index) => const SizedBox(width: 12),
                            itemBuilder: (context, index) {
                              final url = _previousWorks[index];
                              return OptimizedNetworkImage(
                                imageUrl: url,
                                width: 140,
                                height: 140,
                                fit: BoxFit.cover,
                                borderRadius: BorderRadius.circular(12),
                                errorWidget: Container(
                                  width: 140,
                                  height: 140,
                                  color: AppColors.border,
                                  child: const Icon(Icons.broken_image_outlined),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
      bottomNavigationBar: AppBottomNavBar(
        selectedIndex: MainScreen.mainKey.currentState?.selectedIndex ?? 0,
      ),
    );
  }
}
