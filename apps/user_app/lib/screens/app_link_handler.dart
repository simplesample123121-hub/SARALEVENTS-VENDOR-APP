import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppLinkHandler extends StatefulWidget {
  final Widget child;
  
  const AppLinkHandler({super.key, required this.child});

  @override
  State<AppLinkHandler> createState() => _AppLinkHandlerState();
}

class _AppLinkHandlerState extends State<AppLinkHandler> {
  @override
  void initState() {
    super.initState();
    _handleInitialLink();
  }

  void _handleInitialLink() {
    // Handle app links when app is opened from a link
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForPendingLink();
    });
  }

  void _checkForPendingLink() {
    // This would be implemented with a deep link package like app_links
    // For now, we'll handle it in the main app initialization
  }

  void handleAppLink(String link) {
    final uri = Uri.parse(link);
    
    // Handle custom scheme: saralevents://invite/{slug}
    if (uri.scheme == 'saralevents' && uri.host == 'invite') {
      final slug = uri.pathSegments.isNotEmpty ? uri.pathSegments.first : '';
      if (slug.isNotEmpty && mounted) {
        context.push('/invite/$slug');
      }
      return;
    }
    
    // Handle HTTPS scheme: https://saralevents.vercel.app/invite/{slug}
    if (uri.scheme == 'https' && uri.host == 'saralevents.vercel.app' && uri.path.startsWith('/invite/')) {
      final slug = uri.path.substring('/invite/'.length);
      if (mounted) {
        context.push('/invite/$slug');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
