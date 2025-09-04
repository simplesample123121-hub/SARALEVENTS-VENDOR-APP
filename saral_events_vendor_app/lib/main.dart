import 'package:flutter/material.dart';
import 'package:saral_events_vendor_app/widgets/simple_update_widget.dart';
import 'package:saral_events_vendor_app/services/simple_app_update_service.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SimpleUpdateWidget(
      showOnInit: true,
      child: MaterialApp(
        title: 'Saral Events Vendor App',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: MyHomePage(),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  void initState() {
    super.initState();
    // Check for updates when the app starts
    WidgetsBinding.instance.addPostFrameCallback((_) {
      SimpleAppUpdateService.checkOnStartup(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Saral Events Vendor App'),
        actions: [
          // Add update check button in app bar
          IconButton(
            icon: Icon(Icons.system_update),
            onPressed: () {
              SimpleAppUpdateService.forceCheckForUpdates(context);
            },
            tooltip: 'Check for Updates',
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Welcome to Saral Events Vendor App',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            Text(
              'Your app content goes here',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 40),
            // Example of manual update check button
            ElevatedButton.icon(
              onPressed: () {
                SimpleAppUpdateService.forceCheckForUpdates(context);
              },
              icon: Icon(Icons.system_update),
              label: Text('Check for Updates'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
            SizedBox(height: 20),
            // Example of update banner
            SimpleUpdateBanner(
              onUpdatePressed: () {
                SimpleAppUpdateService.forceCheckForUpdates(context);
              },
              onDismiss: () {
                // Handle dismiss
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Update reminder dismissed')),
                );
              },
            ),
          ],
        ),
      ),
      // Add floating action button for updates
      floatingActionButton: SimpleUpdateFloatingActionButton(),
    );
  }
}
