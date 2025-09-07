import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/session.dart';
import '../services/profile_service.dart';
import 'profile_details_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final ProfileService _profileService;
  Map<String, dynamic>? _profile;
  bool _loading = true;

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _profileService = ProfileService(Supabase.instance.client);
    _load();
  }

  Future<void> _load() async {
    final user = context.read<UserSession>().currentUser;
    if (user == null) return;
    setState(() => _loading = true);
    final p = await _profileService.getProfile(user.id);
    _profile = p;
    _firstNameController.text = (p?['first_name'] ?? '') as String;
    _lastNameController.text = (p?['last_name'] ?? '') as String;
    _phoneController.text = (p?['phone_number'] ?? '') as String;
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final user = context.read<UserSession>().currentUser;
    if (user == null) return;
    setState(() => _loading = true);
    await _profileService.upsertProfile(
      userId: user.id,
      email: user.email ?? '',
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      phoneNumber: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
    );
    await _load();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<UserSession>();
    final user = session.currentUser;
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Center(
                  child: Builder(builder: (context) {
                    final authMeta = user?.userMetadata ?? {};
                    final fallbackAvatar = (authMeta['avatar_url'] ?? authMeta['picture']) as String?;
                    final imageUrl = (_profile?['image_url'] as String?) ?? fallbackAvatar;
                    return CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.grey[100],
                      backgroundImage: (imageUrl != null && imageUrl.isNotEmpty) ? NetworkImage(imageUrl) : null,
                      child: (imageUrl == null || imageUrl.isEmpty)
                          ? const Icon(Icons.person, size: 40, color: Colors.black87)
                          : null,
                    );
                  }),
                ),
                const SizedBox(height: 12),
                Center(
                  child: Text(
                    (_profile != null && ((_profile?['first_name'] ?? '').toString().isNotEmpty || (_profile?['last_name'] ?? '').toString().isNotEmpty))
                        ? '${_profile?['first_name'] ?? ''} ${_profile?['last_name'] ?? ''}'.trim()
                        : (user?.email ?? 'User'),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                const SizedBox(height: 24),
                ListTile(
                  leading: const Icon(Icons.badge_outlined),
                  title: const Text('Profile Details'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    final changed = await Navigator.of(context).push<bool>(
                      MaterialPageRoute(builder: (_) => const ProfileDetailsScreen()),
                    );
                    if (changed == true) {
                      _load();
                    }
                  },
                ),
                const Divider(),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () async {
                    final shouldLogout = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Logout'),
                        content: const Text('Are you sure you want to logout?'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Logout')),
                        ],
                      ),
                    );
                    if (shouldLogout == true) {
                      await context.read<UserSession>().signOut();
                      if (context.mounted) {
                        Navigator.of(context).popUntil((r) => r.isFirst);
                      }
                    }
                  },
                  child: const Text('Sign out'),
                ),
              ],
            ),
    );
  }
}
