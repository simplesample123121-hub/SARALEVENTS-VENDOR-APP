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
    if (uri.scheme == 'io.supabase.flutter' && uri.host == 'login-callback') {
      if (!mounted) return;
      // Mark recovery and navigate immediately; some providers omit the 'type' query
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


