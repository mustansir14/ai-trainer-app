import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'camera_view.dart'; // CameraView widget
import 'video_view.dart'; // VideoView widget (for video selection)
import 'package:file_picker/file_picker.dart';
import 'dart:io';

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
  Future<void> _pickVideo(BuildContext context) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.video,
    );

    if (result != null) {
      File file = File(result.files.single.path!);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VideoView(
            file: file,
          ), // Navigate to VideoView
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('AI Trainer'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () async {
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
            SizedBox(height: 20),
            ElevatedButton(
              // onPressed: () {
              //   Navigator.push(
              //     context,
              //     MaterialPageRoute(
              //       builder: (context) => VideoView(), // Navigate to VideoView
              //     ),
              //   );
              // },
              onPressed: () {
                _pickVideo(context);
              },
              child: Text('Choose Video'),
            ),
          ],
        ),
      ),
    );
  }
}
