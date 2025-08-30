import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'core/state/session.dart';
import 'core/router/app_router.dart';
import 'core/deeplink/deeplink_listener.dart';

class SaralEventsApp extends StatelessWidget {
  const SaralEventsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppSession(),
      builder: (context, _) {
        final session = context.read<AppSession>();
        final router = AppRouter.create(session);
        return DeepLinkListener(
          child: MaterialApp.router(
            title: 'SaralEvents Vendor App',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            routerConfig: router,
          ),
        );
      },
    );
  }
}


