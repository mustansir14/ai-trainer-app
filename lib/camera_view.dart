import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:flutter/foundation.dart';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'dart:convert';

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
  String _predictionText = 'No exercise';

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

      if (poses.isNotEmpty) {
        Pose pose = poses.first;

        // Check if all necessary landmarks are available
        if (pose.landmarks.containsKey(PoseLandmarkType.leftShoulder) &&
            pose.landmarks.containsKey(PoseLandmarkType.leftElbow) &&
            pose.landmarks.containsKey(PoseLandmarkType.leftWrist) &&
            pose.landmarks.containsKey(PoseLandmarkType.leftHip) &&
            pose.landmarks.containsKey(PoseLandmarkType.leftKnee) &&
            pose.landmarks.containsKey(PoseLandmarkType.leftAnkle)) {
          // Extract landmarks
          Offset leftShoulder = Offset(
              pose.landmarks[PoseLandmarkType.leftShoulder]!.x,
              pose.landmarks[PoseLandmarkType.leftShoulder]!.y);
          Offset leftElbow = Offset(
              pose.landmarks[PoseLandmarkType.leftElbow]!.x,
              pose.landmarks[PoseLandmarkType.leftElbow]!.y);
          Offset leftWrist = Offset(
              pose.landmarks[PoseLandmarkType.leftWrist]!.x,
              pose.landmarks[PoseLandmarkType.leftWrist]!.y);
          Offset leftHip = Offset(pose.landmarks[PoseLandmarkType.leftHip]!.x,
              pose.landmarks[PoseLandmarkType.leftHip]!.y);
          Offset leftKnee = Offset(pose.landmarks[PoseLandmarkType.leftKnee]!.x,
              pose.landmarks[PoseLandmarkType.leftKnee]!.y);
          Offset leftAnkle = Offset(
              pose.landmarks[PoseLandmarkType.leftAnkle]!.x,
              pose.landmarks[PoseLandmarkType.leftAnkle]!.y);

          // Calculate angles
          double shoulderAngle =
              calculateAngle(leftHip, leftShoulder, leftElbow);
          double elbowAngle =
              calculateAngle(leftShoulder, leftElbow, leftWrist);
          double hipAngle = calculateAngle(leftKnee, leftHip, leftShoulder);
          double kneeAngle = calculateAngle(leftAnkle, leftKnee, leftHip);
          double ankleAngle = calculateAngle(leftKnee, leftAnkle, leftWrist);

          // Prepare data for API
          Map<String, dynamic> data = {
            "shoulder_angle": shoulderAngle,
            "elbow_angle": elbowAngle,
            "hip_angle": hipAngle,
            "knee_angle": kneeAngle,
            "ankle_angle": ankleAngle,
            "shoulder_ground_angle": 90.0, // Adjust if needed
            "elbow_ground_angle": 90.0, // Adjust if needed
            "hip_ground_angle": 90.0, // Adjust if needed
            "knee_ground_angle": 90.0, // Adjust if needed
            "ankle_ground_angle": 90.0, // Adjust if needed
          };

          // Send data to the API
          await sendData(data);
        } else {
          setState(() {
            _predictionText = "No exercise";
          });
        }
      } else {
        setState(() {
          _predictionText = "No exercise";
        });
      }

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

  Future<void> sendData(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('http://10.0.2.2:8000/predict/'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(data),
    );

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      setState(() {
        _predictionText = responseData['prediction'];
      });
    } else {
      print('Failed to send data: ${response.statusCode}');
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

  double calculateAngle(Offset a, Offset b, Offset c) {
    var ab = Offset(b.dx - a.dx, b.dy - a.dy);
    var bc = Offset(c.dx - b.dx, c.dy - b.dy);

    var dotProduct = ab.dx * bc.dx + ab.dy * bc.dy;
    var magnitudeAB = sqrt(ab.dx * ab.dx + ab.dy * ab.dy);
    var magnitudeBC = sqrt(bc.dx * bc.dx + bc.dy * bc.dy);

    var cosTheta = dotProduct / (magnitudeAB * magnitudeBC);
    return acos(cosTheta) * (180 / pi); // Convert to degrees
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
          Positioned(
            top: 50, // Adjust vertical position as needed
            left: 0,
            right: 0, // This allows the container to stretch across the screen
            child: Center(
              child: Container(
                padding: EdgeInsets.all(8.0),
                color: Colors.black54,
                child: Text(
                  _predictionText,
                  style: TextStyle(color: Colors.white, fontSize: 20),
                ),
              ),
            ),
          ),
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
