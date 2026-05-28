import 'dart:io';
import 'dart:ui' show Size;

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

/// Wraps MediaPipe / MLKit face detection. Returns face confidence as
/// "presence + frame-area-ratio" since MLKit does not expose a direct
/// probability. A face that fills > ~22% of the frame area is treated
/// as high confidence (~0.9). No face → 0.0.
class FaceDetectionService {
  FaceDetectionService();

  final _detector = FaceDetector(
    options: FaceDetectorOptions(
      enableContours: false,
      enableClassification: true,
      enableLandmarks: false,
      enableTracking: false,
      minFaceSize: 0.15,
      performanceMode: FaceDetectorMode.fast,
    ),
  );

  Future<double> detectFromFile(String path) async {
    try {
      final input = InputImage.fromFile(File(path));
      final faces = await _detector.processImage(input);
      if (faces.isEmpty) return 0.0;
      return _scoreFromFaces(faces, fallbackImageSize: null);
    } catch (e, st) {
      debugPrint('FaceDetectionService.detectFromFile error: $e\n$st');
      return 0.0;
    }
  }

  Future<double> detectFromCameraImage(
    CameraImage image,
    CameraDescription camera,
  ) async {
    try {
      final input = _toInputImage(image, camera);
      if (input == null) return 0.0;
      final faces = await _detector.processImage(input);
      if (faces.isEmpty) return 0.0;
      return _scoreFromFaces(
        faces,
        fallbackImageSize: Size(
          image.width.toDouble(),
          image.height.toDouble(),
        ),
      );
    } catch (e) {
      debugPrint('FaceDetectionService.detectFromCameraImage error: $e');
      return 0.0;
    }
  }

  double _scoreFromFaces(List<Face> faces, {Size? fallbackImageSize}) {
    final face = faces.first;
    final bbox = face.boundingBox;
    final faceArea = bbox.width * bbox.height;
    final frameArea = fallbackImageSize == null
        ? null
        : fallbackImageSize.width * fallbackImageSize.height;
    final coverageRatio = (frameArea == null || frameArea == 0)
        ? 0.25
        : faceArea / frameArea;

    // Smile / open-eye signals bump score (model is more confident on
    // engaged faces). All optional — fall back to coverage-only.
    final smile = (face.smilingProbability ?? 0.5);
    final leftEye = (face.leftEyeOpenProbability ?? 0.8);
    final rightEye = (face.rightEyeOpenProbability ?? 0.8);
    final engagement = (smile * 0.3 + leftEye * 0.35 + rightEye * 0.35);

    final coverageScore = (coverageRatio * 4.0).clamp(0.0, 1.0);
    final score = (coverageScore * 0.7 + engagement * 0.3).clamp(0.0, 1.0);
    return score;
  }

  InputImage? _toInputImage(CameraImage image, CameraDescription camera) {
    if (image.planes.isEmpty) return null;
    final WriteBuffer buffer = WriteBuffer();
    for (final p in image.planes) {
      buffer.putUint8List(p.bytes);
    }
    final bytes = buffer.done().buffer.asUint8List();
    final rotation =
        InputImageRotationValue.fromRawValue(camera.sensorOrientation) ??
        InputImageRotation.rotation0deg;
    final format =
        InputImageFormatValue.fromRawValue(image.format.raw) ??
        InputImageFormat.nv21;
    return InputImage.fromBytes(
      bytes: bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: image.planes.first.bytesPerRow,
      ),
    );
  }

  Future<void> dispose() async {
    await _detector.close();
  }
}
