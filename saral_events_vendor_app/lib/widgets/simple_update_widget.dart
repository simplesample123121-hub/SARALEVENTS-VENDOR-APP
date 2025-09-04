import 'package:flutter/material.dart';
import '../services/simple_app_update_service.dart';

class SimpleUpdateWidget extends StatefulWidget {
  final bool showOnInit;
  final Widget? child;
  final VoidCallback? onUpdatePressed;

  const SimpleUpdateWidget({
    Key? key,
    this.showOnInit = true,
    this.child,
    this.onUpdatePressed,
  }) : super(key: key);

  @override
  State<SimpleUpdateWidget> createState() => _SimpleUpdateWidgetState();
}

class _SimpleUpdateWidgetState extends State<SimpleUpdateWidget> {
  bool _isChecking = false;

  @override
  void initState() {
    super.initState();
    if (widget.showOnInit) {
      _checkForUpdates();
    }
  }

  Future<void> _checkForUpdates() async {
    setState(() {
      _isChecking = true;
    });

    try {
      await SimpleAppUpdateService.checkForUpdates(context);
    } finally {
      setState(() {
        _isChecking = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.child != null) {
      return Stack(
        children: [
          widget.child!,
          if (_isChecking)
            Positioned(
              top: MediaQuery.of(context).padding.top + 10,
              right: 10,
              child: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Checking for updates...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      );
    }

    return Container(); // Return empty container if no child
  }
}

/// A simple update banner that can be shown at the top of any screen
class SimpleUpdateBanner extends StatelessWidget {
  final VoidCallback? onUpdatePressed;
  final VoidCallback? onDismiss;

  const SimpleUpdateBanner({
    Key? key,
    this.onUpdatePressed,
    this.onDismiss,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue, Colors.blue.shade700],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.system_update,
            color: Colors.white,
            size: 20,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Update Available',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  'Get the latest features and improvements',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onUpdatePressed ?? () {
              SimpleAppUpdateService.forceCheckForUpdates(context);
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: Colors.white.withOpacity(0.2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Text(
              'Update',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          if (onDismiss != null) ...[
            SizedBox(width: 8),
            IconButton(
              onPressed: onDismiss,
              icon: Icon(
                Icons.close,
                color: Colors.white,
                size: 18,
              ),
              padding: EdgeInsets.zero,
              constraints: BoxConstraints(
                minWidth: 24,
                minHeight: 24,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// A floating action button for manual update checks
class SimpleUpdateFloatingActionButton extends StatelessWidget {
  final VoidCallback? onUpdatePressed;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const SimpleUpdateFloatingActionButton({
    Key? key,
    this.onUpdatePressed,
    this.backgroundColor,
    this.foregroundColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: onUpdatePressed ?? () {
        SimpleAppUpdateService.forceCheckForUpdates(context);
      },
      backgroundColor: backgroundColor ?? Colors.blue,
      foregroundColor: foregroundColor ?? Colors.white,
      tooltip: 'Check for Updates',
      child: Icon(Icons.system_update),
    );
  }
}

/// A settings tile for update information
class UpdateInfoTile extends StatelessWidget {
  final VoidCallback? onCheckForUpdates;

  const UpdateInfoTile({
    Key? key,
    this.onCheckForUpdates,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: SimpleAppUpdateService.getCurrentVersion(),
      builder: (context, snapshot) {
        return ListTile(
          leading: Icon(Icons.system_update, color: Colors.blue),
          title: Text('App Version'),
          subtitle: Text(snapshot.data ?? 'Loading...'),
          trailing: IconButton(
            icon: Icon(Icons.refresh),
            onPressed: onCheckForUpdates ?? () {
              SimpleAppUpdateService.forceCheckForUpdates(context);
            },
            tooltip: 'Check for Updates',
          ),
        );
      },
    );
  }
}
