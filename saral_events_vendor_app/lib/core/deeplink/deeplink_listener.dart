import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import '../state/session.dart';

class DeepLinkListener extends StatefulWidget {
  final Widget child;
  const DeepLinkListener({super.key, required this.child});

  @override
  State<DeepLinkListener> createState() => _DeepLinkListenerState();
}

class _DeepLinkListenerState extends State<DeepLinkListener> {
  StreamSubscription<Uri>? _sub;

  @override
  void initState() {
    super.initState();
    final appLinks = AppLinks();
    // Initial link (cold start)
    appLinks.getInitialLink().then((uri) => _handleUri(uri));
    // Stream (warm start)
    _sub = appLinks.uriLinkStream.listen(_handleUri, onError: (_) {});
  }

  void _handleUri(Uri? uri) {
    if (uri == null) return;
    
    // Debug logging
    print('Deep link received: $uri');
    print('Scheme: ${uri.scheme}, Host: ${uri.host}');
    print('Query parameters: ${uri.queryParameters}');
    
    // Handle Supabase auth callbacks (primary method)
    if (uri.scheme == 'io.supabase.flutter' && uri.host == 'login-callback') {
      print('Handling Supabase auth callback');
      if (!mounted) return;
      
      // Check for password recovery
      final code = uri.queryParameters['code'];
      final error = uri.queryParameters['error'];
      
      if (error != null) {
        print('Auth error: $error');
        return;
      }
      
      if (code != null) {
        print('Auth code received: $code');
        // This is a password recovery flow - mark user for recovery
        context.read<AppSession>().markPasswordRecovery();
      }
    }
    
    // Handle custom deep links (fallback)
    if (uri.scheme == 'saralevents' && uri.host == 'reset-password') {
      print('Handling custom password reset deep link');
      if (!mounted) return;
      context.read<AppSession>().markPasswordRecovery();
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}


