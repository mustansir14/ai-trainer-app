import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:flutter/foundation.dart';

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

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _poseDetector = GoogleMlKit.vision.poseDetector();
  }

  Future<void> _initializeCamera() async {
    _cameraController = CameraController(
      widget.cameras[1],
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
      // Convert the CameraImage to InputImage
      final InputImage inputImage = _convertCameraImage(cameraImage);

      // Perform pose detection
      final List<Pose> poses = await _poseDetector!.processImage(inputImage);

      // Process detected poses (for example, printing the pose data)
      for (Pose pose in poses) {
        final landmarks = pose.landmarks;
        print(landmarks);
      }
    } catch (e) {
      print('Error processing image: $e');
    } finally {
      _isDetecting = false;
    }
  }

  InputImage _convertCameraImage(CameraImage cameraImage) {
    // Combine the planes of the camera image into a single Uint8List
    final WriteBuffer allBytes = WriteBuffer();
    for (final Plane plane in cameraImage.planes) {
      allBytes.putUint8List(plane.bytes);
    }
    final bytes = allBytes.done().buffer.asUint8List();

    // Create an InputImageData object
    final Size imageSize = Size(
      cameraImage.width.toDouble(),
      cameraImage.height.toDouble(),
    );
    final InputImageRotation imageRotation = _rotationIntToImageRotation(
        _cameraController!.description.sensorOrientation);
    const InputImageFormat inputImageFormat = InputImageFormat.nv21;

    // Create an InputImageData instance
    final inputImageData = InputImageMetadata(
      size: imageSize,
      rotation: imageRotation,
      format: inputImageFormat,
      bytesPerRow: cameraImage.planes[0].bytesPerRow,
    );

    final inputImage = InputImage.fromBytes(
      bytes: bytes,
      metadata: inputImageData,
    );

    return inputImage;
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
      body: CameraPreview(_cameraController!),
    );
  }
}
