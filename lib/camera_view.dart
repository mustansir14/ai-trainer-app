import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:flutter/foundation.dart';

import 'pose_painter.dart';
import 'exercise_prediction_client.dart';

class CameraView extends StatefulWidget {
  final List<CameraDescription> cameras;
  const CameraView({super.key, required this.cameras});

  @override
  _CameraViewState createState() => _CameraViewState();
}

class _CameraViewState extends State<CameraView> {
  CameraController? _cameraController;
  PoseDetector? _poseDetector;
  bool _isDetecting = false;
  List<Pose> _poses = [];
  Size? _imageSize;
  String _predictionText = 'No exercise';

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    final options = PoseDetectorOptions();
    _poseDetector = PoseDetector(options: options);
  }

  Future<void> _initializeCamera() async {
    _cameraController = CameraController(
      widget.cameras[1], // Choose the camera here (front or back)
      ResolutionPreset.high,
    );

    await _cameraController!.initialize();
    _cameraController!.startImageStream((CameraImage image) {
      if (!_isDetecting) {
        _isDetecting = true;
        _processImage(image);
      }
    });

    if (!mounted) return;

    setState(() {});
  }

  Future<void> _processImage(CameraImage cameraImage) async {
    try {
      final inputImage = _convertCameraImage(cameraImage);
      final poses = await _poseDetector!.processImage(inputImage);

      final predictionText =
          await ExercisePredictionClient.predictExercise(poses);

      // Set detected poses and image size to state
      setState(() {
        _poses = poses;
        _imageSize =
            Size(cameraImage.width.toDouble(), cameraImage.height.toDouble());
        _predictionText = predictionText;
      });
    } catch (e) {
      print('Error processing image: $e');
    } finally {
      _isDetecting = false;
    }
  }

  InputImage _convertCameraImage(CameraImage cameraImage) {
    final WriteBuffer allBytes = WriteBuffer();
    for (final Plane plane in cameraImage.planes) {
      allBytes.putUint8List(plane.bytes);
    }
    final bytes = allBytes.done().buffer.asUint8List();

    final Size imageSize = Size(
      cameraImage.width.toDouble(),
      cameraImage.height.toDouble(),
    );
    final InputImageRotation imageRotation = _rotationIntToImageRotation(
        _cameraController!.description.sensorOrientation);
    const InputImageFormat inputImageFormat = InputImageFormat.nv21;

    final inputImageData = InputImageMetadata(
      size: imageSize,
      rotation: imageRotation,
      format: inputImageFormat,
      bytesPerRow: cameraImage.planes[0].bytesPerRow,
    );

    return InputImage.fromBytes(
      bytes: bytes,
      metadata: inputImageData,
    );
  }

  InputImageRotation _rotationIntToImageRotation(int rotation) {
    switch (rotation) {
      case 90:
        return InputImageRotation.rotation90deg;
      case 180:
        return InputImageRotation.rotation180deg;
      case 270:
        return InputImageRotation.rotation270deg;
      default:
        return InputImageRotation.rotation0deg;
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _poseDetector?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Camera View'),
      ),
      body: Stack(
        fit: StackFit.expand, // Ensure the camera preview fills the screen
        children: [
          CameraPreview(_cameraController!),
          Positioned(
            top: 50, // Adjust vertical position as needed
            left: 0,
            right: 0, // This allows the container to stretch across the screen
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(8.0),
                color: Colors.black54,
                child: Text(
                  _predictionText,
                  style: const TextStyle(color: Colors.white, fontSize: 20),
                ),
              ),
            ),
          ),
          if (_imageSize != null && _poses.isNotEmpty)
            CustomPaint(
              painter: PosePainter(_poses, _imageSize!, const Offset(75, -200)),
              child: Container(), // Use a container to provide size constraints
            ),
        ],
      ),
    );
  }
}
