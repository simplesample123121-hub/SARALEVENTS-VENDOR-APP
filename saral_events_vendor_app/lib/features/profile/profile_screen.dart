import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/state/session.dart';
import '../../core/ui/app_icons.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
                     CircleAvatar(
             radius: 40,
             backgroundColor: Colors.grey[100],
             child: const SvgIcon(AppIcons.vendorSvg, size: 40, color: Colors.black),
           ),
          const SizedBox(height: 12),
          Center(
            child: Text('Vendor Name', style: Theme.of(context).textTheme.titleMedium),
          ),
          const SizedBox(height: 24),
          ListTile(
            leading: const SvgIcon(AppIcons.businessDetailsSvg, size: 22, color: Colors.black),
            title: const Text('Business Details'),
            trailing: const Icon(Icons.chevron_right),
          ),
          const Divider(),
          ListTile(
            leading: const SvgIcon(AppIcons.documentsSvg, size: 22, color: Colors.black),
            title: const Text('Documents'),
            trailing: const Icon(Icons.chevron_right),
          ),
          const Divider(),
          ListTile(
            leading: const SvgIcon(AppIcons.settingsSvg, size: 22, color: Colors.black),
            title: const Text('Settings'),
            trailing: const Icon(Icons.chevron_right),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () {
              context.read<AppSession>().signOut();
              context.go('/auth/pre');
            },
            child: const Text('Sign out'),
          )
        ],
      ),
    );
  }
}


