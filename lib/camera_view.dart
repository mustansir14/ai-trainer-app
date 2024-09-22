import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:flutter/foundation.dart';

import 'pose_painter.dart'; // Make sure to import the custom painter here

class CameraView extends StatefulWidget {
  final List<CameraDescription> cameras;
  const CameraView({Key? key, required this.cameras}) : super(key: key);

  @override
  _CameraViewState createState() => _CameraViewState();
}

class _CameraViewState extends State<CameraView> {
  CameraController? _cameraController;
  PoseDetector? _poseDetector;
  bool _isDetecting = false;
  List<Pose> _poses = [];
  Size? _imageSize;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _poseDetector = GoogleMlKit.vision.poseDetector();
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

      // Set detected poses and image size to state
      setState(() {
        _poses = poses;
        _imageSize =
            Size(cameraImage.width.toDouble(), cameraImage.height.toDouble());
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
        title: Text('Camera View'),
      ),
      body: Stack(
        fit: StackFit.expand, // Ensure the camera preview fills the screen
        children: [
          CameraPreview(_cameraController!),
          if (_imageSize != null && _poses.isNotEmpty)
            CustomPaint(
              painter: PosePainter(_poses, _imageSize!),
              child: Container(), // Use a container to provide size constraints
            ),
        ],
      ),
    );
  }
}
