import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'camera_view.dart'; // We'll create this file next

void main() {
  runApp(AITrainerApp());
}

class AITrainerApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Trainer App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('AI Trainer'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            // Navigate to CameraView
            final cameras = await availableCameras();
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CameraView(cameras: cameras),
              ),
            );
          },
          child: Text('Start Camera'),
        ),
      ),
    );
  }
}
