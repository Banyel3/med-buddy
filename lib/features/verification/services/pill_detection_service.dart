import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

/// Runs the seblful YOLOv8s pill model on a still image.
/// Returns the max class confidence across all anchors (0.0 if no
/// pill detected or model missing).
///
/// Model input: 640x640 RGB float32 [0,1].
/// Model output (Ultralytics YOLOv8 export): [1, 4 + num_classes, 8400]
/// where the first 4 channels are bbox (cx, cy, w, h) and the rest
/// are per-class confidences. seblful's model = 2 classes (capsules,
/// tablets), so shape = [1, 6, 8400].
class PillDetectionService {
  PillDetectionService();

  static const _modelAsset = 'assets/models/pills_detection.tflite';
  static const _inputSize = 640;
  static const _numClasses = 2;
  static const _numAnchors = 8400;

  Interpreter? _interpreter;
  bool _loadFailed = false;

  Future<bool> ensureLoaded() async {
    if (_interpreter != null) return true;
    if (_loadFailed) return false;
    try {
      // Verify the asset is present before attempting Interpreter.fromAsset.
      await rootBundle.load(_modelAsset);
      _interpreter = await Interpreter.fromAsset(_modelAsset);
      debugPrint('PillDetectionService: model loaded');
      return true;
    } catch (e) {
      _loadFailed = true;
      debugPrint(
          'PillDetectionService: model not available ($e). Drop pills_detection.tflite into assets/models/ to enable.');
      return false;
    }
  }

  Future<double> detectFromFile(String path) async {
    if (!await ensureLoaded()) return 0.0;
    try {
      final bytes = await File(path).readAsBytes();
      final decoded = img.decodeImage(bytes);
      if (decoded == null) return 0.0;
      return _runInference(decoded);
    } catch (e, st) {
      debugPrint('PillDetectionService.detectFromFile error: $e\n$st');
      return 0.0;
    }
  }

  double _runInference(img.Image image) {
    final resized = img.copyResize(image,
        width: _inputSize, height: _inputSize, interpolation: img.Interpolation.linear);

    // Build [1, 640, 640, 3] float input normalized to [0,1].
    final input = List.generate(
      1,
      (_) => List.generate(
        _inputSize,
        (y) => List.generate(
          _inputSize,
          (x) {
            final p = resized.getPixel(x, y);
            return [p.r / 255.0, p.g / 255.0, p.b / 255.0];
          },
        ),
      ),
    );

    // Output buffer for [1, 4+num_classes, num_anchors].
    final output = List.generate(
      1,
      (_) => List.generate(
        4 + _numClasses,
        (_) => List<double>.filled(_numAnchors, 0.0),
      ),
    );

    _interpreter!.run(input, output);

    // Take max confidence over class channels & anchors.
    double best = 0.0;
    for (var c = 4; c < 4 + _numClasses; c++) {
      for (var a = 0; a < _numAnchors; a++) {
        final v = output[0][c][a];
        if (v > best) best = v;
      }
    }
    // YOLOv8 outputs raw class logits with sigmoid-ish range in
    // ultralytics export when using --int8=false. Clamp 0..1.
    return best.clamp(0.0, 1.0).toDouble();
  }

  /// Quick single-shot helper using image bytes (e.g. CameraImage JPEG).
  Future<double> detectFromBytes(Uint8List bytes) async {
    if (!await ensureLoaded()) return 0.0;
    try {
      final decoded = img.decodeImage(bytes);
      if (decoded == null) return 0.0;
      return _runInference(decoded);
    } catch (e) {
      debugPrint('PillDetectionService.detectFromBytes error: $e');
      return 0.0;
    }
  }

  void dispose() {
    _interpreter?.close();
    _interpreter = null;
  }

  /// Returns a synthetic confidence when the model is missing — lets
  /// developers smoke-test the full verification flow before dropping
  /// pills_detection.tflite into assets/models. Debug builds only.
  static double devFallbackConfidence({double when = 0.85}) =>
      kDebugMode ? when : 0.0;
}
