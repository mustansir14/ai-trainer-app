import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:ffmpeg_kit_flutter_min_gpl/ffmpeg_kit.dart';
import 'dart:io';
import 'pose_painter.dart';
import 'package:path_provider/path_provider.dart';
import 'exercise_prediction_client.dart';
import 'package:permission_handler/permission_handler.dart';

class VideoView extends StatefulWidget {
  const VideoView({super.key, required this.file});

  final File file;

  @override
  _VideoViewState createState() => _VideoViewState();
}

class _VideoViewState extends State<VideoView> {
  VideoPlayerController? _videoController;
  PoseDetector? _poseDetector;
  List<Pose> _poses = [];
  bool _isDetecting = false;
  String? videoPath;
  String _predictionText =
      "Waiting for prediction..."; // This will hold the prediction text

  @override
  @override
  void initState() {
    super.initState();
    videoPath = widget.file.path;
    final options = PoseDetectorOptions();
    _poseDetector = PoseDetector(options: options);

    // Initialize the video controller and set up listener for video end
    _videoController = VideoPlayerController.file(widget.file)
      ..initialize().then((_) {
        setState(() {});
        _videoController!.play();
        _processVideoFrames();
      });

    // Add a listener to handle replay when the video finishes
    _videoController!.addListener(() {
      if (_videoController!.value.position ==
          _videoController!.value.duration) {
        // When the video ends, reset the position and replay
        _videoController!.seekTo(Duration.zero);
        _videoController!.play();
      }
    });
  }

  Future<void> _processVideoFrames() async {
    while (_videoController != null && _videoController!.value.isPlaying) {
      if (!_isDetecting) {
        _isDetecting = true;

        // Get current video frame from the VideoPlayerController
        final currentFrame = await _getCurrentVideoFrame();
        if (currentFrame != null) {
          // Process the frame with Google ML Kit's PoseDetector
          final poses = await _poseDetector!.processImage(currentFrame);

          setState(() {
            _poses = poses;
          });

          // Send poses to API and get prediction
          final predictionText =
              await ExercisePredictionClient.predictExercise(poses);

          // Update the UI with poses and prediction text
          setState(() {
            _predictionText = predictionText;
          });
        }

        _isDetecting = false;
      }

      // Add a slight delay to avoid processing every frame (adjust as needed)
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }

  Future<InputImage?> _getCurrentVideoFrame() async {
    if (videoPath == null) return null;

    try {
      // Get a temporary directory to save the frame image
      final tempDir = await getTemporaryDirectory();
      final position = _videoController!.value.position.inSeconds;
      final framePath = '${tempDir.path}/frame$position.jpg';

      // Extract a single frame at the current position using FFmpeg

      await FFmpegKit.execute(
          '-i $videoPath -vf "select=eq(n\\,${position * 30})" -vsync vfr $framePath');

      // Check if frame extraction succeeded
      File frameFile = File(framePath);
      if (!frameFile.existsSync()) return null;

      // Load the extracted frame as an InputImage
      final inputImage = InputImage.fromFile(frameFile);

      return inputImage;
    } catch (e) {
      print('Error extracting video frame: $e');
      return null;
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _poseDetector?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Video View'),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Make the video full screen with proper aspect ratio
          if (_videoController != null && _videoController!.value.isInitialized)
            AspectRatio(
              aspectRatio: _videoController!.value.aspectRatio,
              child: VideoPlayer(_videoController!),
            ),
          if (_poses.isNotEmpty)
            CustomPaint(
              painter: PosePainter(
                _poses,
                Size(_videoController!.value.size.width,
                    _videoController!.value.size.height),
                const Offset(0, 0),
              ),
              child: Container(),
            ),
          Positioned(
            top: 30,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(10),
                color: Colors.black.withOpacity(0.5),
                child: Text(
                  _predictionText, // Display the prediction text
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
