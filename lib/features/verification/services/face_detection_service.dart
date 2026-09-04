import 'dart:io';
import 'dart:ui' as ui show ImageDescriptor, ImmutableBuffer;
import 'dart:ui' show Size;

import 'package:flutter/foundation.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

/// Wraps MLKit face detection. MLKit exposes no direct "is this a face"
/// probability, so the score combines two things it *does* report:
///
///   * **coverage** — how much of the frame the face bounding box fills.
///     A dose selfie is held close, so a small face means the shot is not
///     the one we asked for. Saturates at 25% of frame area.
///   * **engagement** — smile / open-eye probabilities, which rise on a
///     face pointed at the camera rather than caught in profile.
///
/// The frame size is read from the image header, not assumed. If it cannot
/// be read the coverage term is dropped rather than invented, which pulls
/// the score below the pass threshold — a verification we cannot actually
/// measure must fail, not sail through on a placeholder. No face → 0.0.
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
      return scoreFromFaces(faces, imageSize: await _imageSize(path));
    } catch (e, st) {
      debugPrint('FaceDetectionService.detectFromFile error: $e\n$st');
      return 0.0;
    }
  }

  /// Pixel dimensions straight from the encoded header — no full raster
  /// decode, and no second copy of the image in memory.
  Future<Size?> _imageSize(String path) async {
    ui.ImmutableBuffer? buffer;
    ui.ImageDescriptor? descriptor;
    try {
      buffer = await ui.ImmutableBuffer.fromFilePath(path);
      descriptor = await ui.ImageDescriptor.encoded(buffer);
      final w = descriptor.width.toDouble();
      final h = descriptor.height.toDouble();
      return Size(w, h);
    } catch (e) {
      debugPrint('FaceDetectionService._imageSize error: $e');
      return null;
    } finally {
      descriptor?.dispose();
      buffer?.dispose();
    }
  }

  @visibleForTesting
  static double scoreFromFaces(List<Face> faces, {required Size? imageSize}) {
    final face = faces.first;
    final bbox = face.boundingBox;

    final smile = face.smilingProbability ?? 0.5;
    final leftEye = face.leftEyeOpenProbability ?? 0.8;
    final rightEye = face.rightEyeOpenProbability ?? 0.8;
    final engagement = smile * 0.3 + leftEye * 0.35 + rightEye * 0.35;

    final frameArea = imageSize == null
        ? 0.0
        : imageSize.width * imageSize.height;
    if (frameArea <= 0) {
      // Coverage unmeasurable — report engagement alone. Deliberately below
      // VerificationResult.faceThreshold so the user is asked to retake.
      return (engagement * 0.3).clamp(0.0, 1.0);
    }

    final coverageRatio = (bbox.width * bbox.height) / frameArea;
    final coverageScore = (coverageRatio * 4.0).clamp(0.0, 1.0);
    return (coverageScore * 0.7 + engagement * 0.3).clamp(0.0, 1.0);
  }

  Future<void> dispose() async {
    await _detector.close();
  }
}
