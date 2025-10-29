import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
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
  // Form key unused in this screen
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
    if (user == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    setState(() => _loading = true);
    final p = await _profileService.getProfile(user.id);
    _profile = p;
    _firstNameController.text = (p?['first_name'] ?? '') as String;
    _lastNameController.text = (p?['last_name'] ?? '') as String;
    _phoneController.text = (p?['phone_number'] ?? '') as String;
    if (mounted) setState(() => _loading = false);
  }

  // Save handled in ProfileDetailsScreen

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
          : (user == null
              ? Center(
                  child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.person_outline, size: 64),
                      const SizedBox(height: 12),
                      Text('You are not logged in', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      const Text('Please log in to view and edit your profile.'),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: () => GoRouter.of(context).go('/auth/pre'),
                        child: const Text('Log in'),
                      )
                    ],
                  ),
                ))
              
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Center(
                  child: Builder(builder: (context) {
                    final authMeta = user.userMetadata ?? {};
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
                        : (user.email ?? 'User'),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                const SizedBox(height: 24),
                ListTile(
                  leading: const Icon(Icons.card_giftcard),
                  title: const Text('My E-Invitations'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => GoRouter.of(context).push('/invites'),
                ),
                const Divider(),
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
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text('About'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('About'),
                        content: const Text('SaralEvents - Your complete event planning solution.'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('OK'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.edit_outlined),
                  title: const Text('Send feedback'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Send Feedback'),
                        content: const Text('We value your feedback! Please share your thoughts and suggestions to help us improve the app.'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('OK'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.warning_outlined),
                  title: const Text('Report a safety emergency'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Safety Emergency'),
                        content: const Text('If you are experiencing a safety emergency, please contact local emergency services immediately.'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('OK'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.star_outline),
                  title: const Text('Accessibility'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Accessibility'),
                        content: const Text('We are committed to making our app accessible to everyone. If you need assistance or have accessibility concerns, please contact our support team.'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('OK'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.settings_outlined),
                  title: const Text('Settings'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Settings'),
                        content: const Text('App settings and preferences will be available here.'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('OK'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const Divider(),
                const SizedBox(height: 24),
                FilledButton.icon(
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
                  icon: const Icon(Icons.power_settings_new),
                  label: const Text('Log out'),
                ),
              ],
            )),
    );
  }
}
