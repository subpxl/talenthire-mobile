import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/app_state.dart';
import '../services/storage_service.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../widgets/loading_dialog.dart';
import '../widgets/optimized_network_image.dart';

const List<String> _indianLanguages = [
  'English',
  'Hindi',
  'Bengali',
  'Telugu',
  'Marathi',
  'Tamil',
  'Urdu',
  'Gujarati',
  'Kannada',
  'Odia',
  'Malayalam',
  'Punjabi',
  'Assamese',
  'Maithili',
  'Other',
];

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final StorageService _storageService = StorageService();
  final ImagePicker _picker = ImagePicker();

  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _bioController;
  late TextEditingController _cityController;
  late TextEditingController _stateController;
  late TextEditingController _addressController;
  late TextEditingController _contactController;
  late TextEditingController _shortIntroVideoController;
  late TextEditingController _achievementsVideoController;
  late TextEditingController _previousWorksVideoController;
  late TextEditingController _ageController;
  String? _selectedHeight;

  String _selectedTalent = 'Other';
  String _experienceLevel = 'fresher';
  String _gender = '';
  String? _bodyType;
  String? _ethnicity;
  List<SocialLink> _socialLinks = [];
  List<String> _selectedLanguages = [];
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final appState = context.read<AppState>();
    final user = appState.user;
    final profile = appState.profile;
    
    _nameController = TextEditingController(text: user?.name ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
    _phoneController = TextEditingController(text: user?.mobile ?? '');
    _bioController = TextEditingController(text: profile?.bio ?? '');
    _cityController = TextEditingController(text: profile?.city ?? '');
    _stateController = TextEditingController(text: profile?.state ?? '');
    _addressController = TextEditingController(text: profile?.address ?? '');
    _contactController = TextEditingController(text: profile?.contact ?? '');

    String initialTalent = profile?.talent ?? 'Other';
    if (initialTalent.isEmpty || initialTalent == 'other') {
      initialTalent = 'Other';
    }
    _selectedTalent = appState.categories.firstWhere(
      (c) => c.toLowerCase() == initialTalent.toLowerCase(),
      orElse: () => appState.categories.isNotEmpty ? appState.categories.first : 'Other',
    );
    _experienceLevel = profile?.experienceLevel.isNotEmpty == true
        ? profile!.experienceLevel
        : 'fresher';
    
    _shortIntroVideoController = TextEditingController(text: profile?.shortIntroVideoLink ?? '');
    _achievementsVideoController = TextEditingController(text: profile?.achievementsVideoLink ?? '');
    _previousWorksVideoController = TextEditingController(text: profile?.previousWorksVideoLink ?? '');
    _ageController = TextEditingController(text: profile?.age?.toString() ?? '');
    _selectedHeight = profile?.height;

    _gender = profile?.gender ?? '';
    _bodyType = profile?.bodyType;
    _ethnicity = profile?.ethnicity;

    if (profile?.socialLinks != null) {
      _socialLinks = List.from(profile!.socialLinks);
    }
    if (profile?.languages != null) {
      _selectedLanguages = List.from(profile!.languages);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _addressController.dispose();
    _contactController.dispose();
    _shortIntroVideoController.dispose();
    _achievementsVideoController.dispose();
    _previousWorksVideoController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  Future<void> _selectDateOfBirth() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      final now = DateTime.now();
      int age = now.year - picked.year;
      if (now.month < picked.month || (now.month == picked.month && now.day < picked.day)) {
        age--;
      }
      setState(() {
        _ageController.text = age.toString();
      });
    }
  }

  Future<void> _pickAndUploadPhoto() async {
    final appState = context.read<AppState>();
    if (appState.profile == null || appState.user == null) return;
    if (appState.profile!.photos.length >= 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maximum 4 photos allowed.')),
      );
      return;
    }

    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
      maxWidth: 1080,
      maxHeight: 1080,
    );
    if (image == null) return;

    if (context.mounted) {
      LoadingDialog.show(context, message: 'Uploading photo...');
    }
    setState(() => _isSaving = true);
    final downloadUrl = await _storageService.uploadImage(File(image.path), appState.user!.id);
    setState(() => _isSaving = false);
    if (context.mounted) {
      LoadingDialog.hide(context);
    }

    if (!mounted) return;
    if (downloadUrl != null) {
      appState.addPhoto(downloadUrl);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Photo uploaded successfully!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to upload photo.')),
      );
    }
  }

  Future<void> _removePhoto(String url) async {
    final appState = context.read<AppState>();
    if (context.mounted) {
      LoadingDialog.show(context, message: 'Removing photo...');
    }
    setState(() => _isSaving = true);
    await _storageService.deleteImage(url);
    appState.removePhoto(url);
    setState(() => _isSaving = false);
    if (context.mounted) {
      LoadingDialog.hide(context);
    }
  }

  IconData _getPlatformIcon(String platformName) {
    switch (platformName.toLowerCase()) {
      case 'instagram': return Icons.camera_alt_outlined;
      case 'facebook': return Icons.facebook;
      case 'linkedin': return Icons.work_outline;
      case 'x.com':
      case 'x': return Icons.close;
      case 'youtube': return Icons.play_circle_outline;
      default: return Icons.link;
    }
  }

  void _addSocialLink() {
    String selectedPlatform = 'Instagram';
    final usernameOrUrlController = TextEditingController();
    final customNameController = TextEditingController();
    final customUrlController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Add Social Link'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      value: selectedPlatform,
                      decoration: const InputDecoration(labelText: 'Platform'),
                      items: ['Instagram', 'Facebook', 'LinkedIn', 'X.com', 'YouTube', 'Custom Link']
                          .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                          .toList(),
                      onChanged: (v) => setDialogState(() => selectedPlatform = v!),
                    ),
                    const SizedBox(height: 16),
                    if (selectedPlatform == 'Custom Link') ...[
                      TextField(
                        controller: customNameController,
                        decoration: const InputDecoration(labelText: 'Platform Name'),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: customUrlController,
                        decoration: const InputDecoration(labelText: 'URL (e.g., https://...)'),
                      ),
                    ] else ...[
                      TextField(
                        controller: usernameOrUrlController,
                        decoration: const InputDecoration(
                          labelText: 'Username or Link',
                          hintText: 'e.g., your_username or https://...',
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                TextButton(
                  onPressed: () {
                    if (selectedPlatform == 'Custom Link') {
                      if (customNameController.text.isNotEmpty && customUrlController.text.isNotEmpty) {
                        setState(() {
                          _socialLinks.add(SocialLink(name: customNameController.text.trim(), url: customUrlController.text.trim()));
                        });
                        Navigator.pop(context);
                      }
                    } else {
                      if (usernameOrUrlController.text.isNotEmpty) {
                        String input = usernameOrUrlController.text.trim();
                        String finalUrl = input;
                        
                        if (!input.startsWith('http://') && !input.startsWith('https://')) {
                          if (input.startsWith('@')) input = input.substring(1);
                          
                          switch (selectedPlatform) {
                            case 'Instagram': finalUrl = 'https://instagram.com/$input'; break;
                            case 'Facebook': finalUrl = 'https://facebook.com/$input'; break;
                            case 'LinkedIn': finalUrl = 'https://linkedin.com/in/$input'; break;
                            case 'X.com': finalUrl = 'https://x.com/$input'; break;
                            case 'YouTube': finalUrl = 'https://youtube.com/@$input'; break;
                          }
                        }
                        setState(() {
                          _socialLinks.add(SocialLink(name: selectedPlatform, url: finalUrl));
                        });
                        Navigator.pop(context);
                      }
                    }
                  },
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showLanguageSelector() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Select Languages'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: _indianLanguages.map((lang) {
                    final isSelected = _selectedLanguages.contains(lang);
                    return CheckboxListTile(
                      title: Text(lang),
                      value: isSelected,
                      onChanged: (checked) {
                        setDialogState(() {
                          if (checked == true) {
                            _selectedLanguages.add(lang);
                          } else {
                            _selectedLanguages.remove(lang);
                          }
                        });
                        setState(() {}); // Update main screen UI
                      },
                    );
                  }).toList(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Done'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isSaving = true);

    context.read<AppState>().updateProfile(
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          phone: _phoneController.text.trim(),
          bio: _bioController.text.trim(),
          city: _cityController.text.trim(),
          state: _stateController.text.trim(),
          address: _addressController.text.trim(),
          contact: _contactController.text.trim(),
          talent: _selectedTalent,
          languages: _selectedLanguages,
          experienceLevel: _experienceLevel,
          shortIntroVideoLink: _shortIntroVideoController.text.trim(),
          achievementsVideoLink: _achievementsVideoController.text.trim(),
          previousWorksVideoLink: _previousWorksVideoController.text.trim(),
          socialLinks: _socialLinks,
          age: int.tryParse(_ageController.text.trim()),
          gender: _gender,
          height: _selectedHeight,
          bodyType: _bodyType,
          ethnicity: _ethnicity,
        );

    setState(() => _isSaving = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Profile updated successfully!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<AppState>().profile;
    final photos = profile?.photos ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        actions: [
          if (_isSaving)
            Center(child: Padding(padding: EdgeInsets.only(right: 16.0), child: CircularProgressIndicator(strokeWidth: 2, color: context.colors.primary))),
          if (!_isSaving)
            TextButton(
              onPressed: _save,
              child: const Text('Save'),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Photos Section
              const Text('Profile Photos (Max 4)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ...photos.map((url) => Stack(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          image: DecorationImage(
                            image: OptimizedNetworkImage.provider(
                              url,
                              context: context,
                              width: 80,
                              height: 80,
                            ),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Positioned(
                        top: -4,
                        right: -4,
                        child: IconButton(
                          icon: const Icon(Icons.cancel, color: AppColors.error),
                          onPressed: () => _removePhoto(url),
                          constraints: const BoxConstraints(),
                          padding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  )),
                  if (photos.length < 4)
                    GestureDetector(
                      onTap: _isSaving ? null : _pickAndUploadPhoto,
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: AppColors.divider,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.outline),
                        ),
                        child: const Icon(Icons.add_a_photo, color: AppColors.textMuted),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),

              const Text('YouTube Shorts Links', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(
                profile?.canPostYoutubeLinks == true
                    ? 'These appear on your public profile.'
                    : 'Premium members can display these on their profile.',
                style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _shortIntroVideoController,
                label: 'Short Intro (About Me)',
                icon: Icons.ondemand_video,
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _achievementsVideoController,
                label: 'Achievements',
                icon: Icons.emoji_events_outlined,
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _previousWorksVideoController,
                label: 'Recent/Previous Works',
                icon: Icons.work_outline,
                keyboardType: TextInputType.url,
              ),

              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),

              const Text('Basic Information', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _nameController,
                label: 'Full Name',
                icon: Icons.person_outline,
                validator: (v) => v == null || v.trim().isEmpty ? 'Name is required' : null,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _emailController,
                label: 'Email',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _phoneController,
                label: 'Phone',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: context.read<AppState>().categories.contains(_selectedTalent) 
                    ? _selectedTalent 
                    : (context.read<AppState>().categories.isNotEmpty ? context.read<AppState>().categories.first : null),
                decoration: InputDecoration(
                  labelText: 'Talent Type *',
                  prefixIcon: const Icon(Icons.star_outline),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                ),
                items: context.read<AppState>().categories.map((t) {
                  return DropdownMenuItem(value: t, child: Text(t));
                }).toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _selectedTalent = v);
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _experienceLevel,
                decoration: InputDecoration(
                  labelText: 'Experience Level',
                  prefixIcon: const Icon(Icons.timeline),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                ),
                items: const [
                  DropdownMenuItem(value: 'fresher', child: Text('Fresher')),
                  DropdownMenuItem(value: 'intermediate', child: Text('Intermediate')),
                  DropdownMenuItem(value: 'experienced', child: Text('Experienced')),
                ],
                onChanged: (v) {
                  if (v != null) setState(() => _experienceLevel = v);
                },
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _bioController,
                label: 'Description / Bio',
                icon: Icons.info_outline,
                maxLines: 4,
              ),

              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),

              const Text('Physical Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _ageController,
                      label: 'Age',
                      icon: Icons.cake_outlined,
                      keyboardType: TextInputType.number,
                      readOnly: true,
                      onTap: _selectDateOfBirth,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedHeight,
                      decoration: InputDecoration(
                        labelText: 'Height',
                        prefixIcon: const Icon(Icons.height),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                      ),
                      items: (() {
                        List<String> heights = [];
                        for (int f = 4; f <= 7; f++) {
                          for (int i = 0; i < 12; i++) {
                            heights.add("$f'$i\"");
                          }
                        }
                        if (_selectedHeight != null && !heights.contains(_selectedHeight!) && _selectedHeight!.isNotEmpty) {
                          heights.insert(0, _selectedHeight!);
                        }
                        return heights.map((h) => DropdownMenuItem<String>(
                          value: h,
                          child: Text(h),
                        )).toList();
                      })(),
                      onChanged: (v) {
                        if (v != null) setState(() => _selectedHeight = v);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _gender.isEmpty ? null : _gender,
                decoration: InputDecoration(
                  labelText: 'Gender',
                  prefixIcon: const Icon(Icons.wc_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                ),
                items: const [
                  DropdownMenuItem(value: 'male', child: Text('Male')),
                  DropdownMenuItem(value: 'female', child: Text('Female')),
                  DropdownMenuItem(value: 'other', child: Text('Other')),
                ],
                onChanged: (v) => setState(() => _gender = v ?? ''),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _bodyType,
                decoration: InputDecoration(
                  labelText: 'Body Type',
                  prefixIcon: const Icon(Icons.accessibility_new_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                ),
                items: const [
                  DropdownMenuItem(value: 'slim', child: Text('Slim')),
                  DropdownMenuItem(value: 'athletic', child: Text('Athletic')),
                  DropdownMenuItem(value: 'average', child: Text('Average')),
                  DropdownMenuItem(value: 'heavy', child: Text('Heavy')),
                ],
                onChanged: (v) => setState(() => _bodyType = v),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _ethnicity,
                decoration: InputDecoration(
                  labelText: 'Ethnicity / Region',
                  prefixIcon: const Icon(Icons.public_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                ),
                items: const [
                  DropdownMenuItem(value: 'north_indian', child: Text('North Indian')),
                  DropdownMenuItem(value: 'south_indian', child: Text('South Indian')),
                  DropdownMenuItem(value: 'east_indian', child: Text('East Indian')),
                  DropdownMenuItem(value: 'west_indian', child: Text('West Indian')),
                  DropdownMenuItem(value: 'central_indian', child: Text('Central Indian')),
                  DropdownMenuItem(value: 'northeast_indian', child: Text('Northeast Indian')),
                  DropdownMenuItem(value: 'other', child: Text('Other')),
                ],
                onChanged: (v) => setState(() => _ethnicity = v),
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: _showLanguageSelector,
                borderRadius: BorderRadius.circular(12),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Languages',
                    prefixIcon: const Icon(Icons.language_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                  ),
                  child: Text(
                    _selectedLanguages.isEmpty
                        ? 'Select Languages'
                        : _selectedLanguages.join(', '),
                    style: TextStyle(
                      color: _selectedLanguages.isEmpty ? Colors.grey[600] : null,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),

              const Text('Location', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _cityController,
                      label: 'City',
                      icon: Icons.location_city,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTextField(
                      controller: _stateController,
                      label: 'State',
                      icon: Icons.map_outlined,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _addressController,
                label: 'Full Address',
                icon: Icons.location_on_outlined,
                maxLines: 2,
              ),
              _buildTextField(
                controller: _contactController,
                label: 'Alternate Phone Number',
                icon: Icons.phone_android_outlined,
                keyboardType: TextInputType.phone,
              ),

              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Social Links', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  IconButton(icon: Icon(Icons.add_circle, color: context.colors.primary), onPressed: _addSocialLink),
                ],
              ),
              if (_socialLinks.isEmpty)
                const Text('No social links added.', style: TextStyle(color: AppColors.textMuted)),
              ..._socialLinks.asMap().entries.map((entry) {
                int idx = entry.key;
                SocialLink link = entry.value;
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(_getPlatformIcon(link.name)),
                  title: Text(link.name),
                  subtitle: Text(link.url, maxLines: 1, overflow: TextOverflow.ellipsis),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: AppColors.error),
                    onPressed: () {
                      setState(() {
                        _socialLinks.removeAt(idx);
                      });
                    },
                  ),
                );
              }),

            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    int maxLines = 1,
    bool readOnly = false,
    VoidCallback? onTap,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      readOnly: readOnly,
      onTap: onTap,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
      ),
    );
  }
}
