import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DebugScreen extends StatefulWidget {
  const DebugScreen({super.key});

  @override
  State<DebugScreen> createState() => _DebugScreenState();
}

class _DebugScreenState extends State<DebugScreen> {
  String _debugInfo = '';

  Future<void> _checkTables() async {
    final supabase = Supabase.instance.client;
    String info = '';

    try {
      // Check if user_roles table exists
      await supabase.from('user_roles').select('count').limit(1);
      info += '✅ user_roles table exists\n';
      
      // Check which profile table exists
      try {
        await supabase.from('profiles').select('count').limit(1);
        info += '✅ profiles table exists\n';
      } catch (_) {
        info += '❌ profiles table missing\n';
      }
      try {
        await supabase.from('user_profiles').select('count').limit(1);
        info += '✅ user_profiles table exists\n';
      } catch (_) {
        info += '❌ user_profiles table missing\n';
      }
      
      // Check current user
      final user = supabase.auth.currentUser;
      info += 'Current user: ${user?.id ?? 'None'}\n';
      info += 'Current user email: ${user?.email ?? 'None'}\n';
      
      if (user != null) {
        // Check user roles
        final userRoles = await supabase.from('user_roles').select('*').eq('user_id', user.id);
        info += 'User roles: $userRoles\n';
        
        // Check user profile in whichever table exists
        try {
          final p1 = await supabase.from('profiles').select('*').eq('user_id', user.id);
          info += 'profiles row: $p1\n';
        } catch (_) {}
        try {
          final p2 = await supabase.from('user_profiles').select('*').eq('user_id', user.id);
          info += 'user_profiles row: $p2\n';
        } catch (_) {}
      }
      
    } catch (e) {
      info += '❌ Error: $e\n';
    }

    setState(() {
      _debugInfo = info;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Debug Info')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: _checkTables,
              child: const Text('Check Tables & Data'),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  _debugInfo.isEmpty ? 'Click button to check tables' : _debugInfo,
                  style: const TextStyle(fontFamily: 'monospace'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
