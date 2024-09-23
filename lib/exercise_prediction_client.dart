import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ExercisePredictionClient {
  static Future<String> predictExercise(List<Pose> poses) async {
    if (poses.isEmpty) {
      return "No exercise";
    }
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
      Offset leftElbow = Offset(pose.landmarks[PoseLandmarkType.leftElbow]!.x,
          pose.landmarks[PoseLandmarkType.leftElbow]!.y);
      Offset leftWrist = Offset(pose.landmarks[PoseLandmarkType.leftWrist]!.x,
          pose.landmarks[PoseLandmarkType.leftWrist]!.y);
      Offset leftHip = Offset(pose.landmarks[PoseLandmarkType.leftHip]!.x,
          pose.landmarks[PoseLandmarkType.leftHip]!.y);
      Offset leftKnee = Offset(pose.landmarks[PoseLandmarkType.leftKnee]!.x,
          pose.landmarks[PoseLandmarkType.leftKnee]!.y);
      Offset leftAnkle = Offset(pose.landmarks[PoseLandmarkType.leftAnkle]!.x,
          pose.landmarks[PoseLandmarkType.leftAnkle]!.y);

      // Calculate angles
      double shoulderAngle = calculateAngle(leftHip, leftShoulder, leftElbow);
      double elbowAngle = calculateAngle(leftShoulder, leftElbow, leftWrist);
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
      return await sendDataAndGetPrediction(data);
    } else {
      return "No exercise";
    }
  }

  static Future<String> sendDataAndGetPrediction(
      Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('http://10.0.2.2:8000/predict/'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(data),
    );

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      return responseData['prediction'];
    } else {
      print('Failed to send data: ${response.statusCode}');
      return "No exercise";
    }
  }

  static double calculateAngle(Offset a, Offset b, Offset c) {
    var ab = Offset(b.dx - a.dx, b.dy - a.dy);
    var bc = Offset(c.dx - b.dx, c.dy - b.dy);

    var dotProduct = ab.dx * bc.dx + ab.dy * bc.dy;
    var magnitudeAB = sqrt(ab.dx * ab.dx + ab.dy * ab.dy);
    var magnitudeBC = sqrt(bc.dx * bc.dx + bc.dy * bc.dy);

    var cosTheta = dotProduct / (magnitudeAB * magnitudeBC);
    return acos(cosTheta) * (180 / pi); // Convert to degrees
  }
}
