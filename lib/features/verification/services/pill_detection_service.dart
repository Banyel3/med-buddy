import 'dart:io';

import 'package:flutter/foundation.dart';
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
///
/// Both expensive steps run off the UI isolate: JPEG decode + resize +
/// normalise (1.2M writes) via [compute], and inference via
/// [IsolateInterpreter]. Doing either inline drops frames on the capture
/// screen while the user is still looking at it.
class PillDetectionService {
  PillDetectionService();

  static const _modelAsset = 'assets/models/pills_detection.tflite';
  static const _inputSize = 640;
  static const _numClasses = 2;
  static const _numAnchors = 8400;

  Interpreter? _interpreter;
  IsolateInterpreter? _isolate;
  bool _loadFailed = false;

  Future<bool> ensureLoaded() async {
    if (_isolate != null) return true;
    if (_loadFailed) return false;
    Interpreter? interpreter;
    try {
      interpreter = await Interpreter.fromAsset(_modelAsset);
      _isolate = await IsolateInterpreter.create(address: interpreter.address);
      _interpreter = interpreter;
      return true;
    } catch (e) {
      // Don't leak the native handle if only the isolate hand-off failed.
      if (_interpreter == null) interpreter?.close();
      _loadFailed = true;
      debugPrint(
        'PillDetectionService: model not available ($e). '
        'Drop pills_detection.tflite into assets/models/ to enable.',
      );
      return false;
    }
  }

  Future<double> detectFromFile(String path) async {
    if (!await ensureLoaded()) return 0.0;
    try {
      final bytes = await File(path).readAsBytes();
      final input = await compute(_preprocess, bytes);
      if (input == null) return 0.0;

      const channels = 4 + _numClasses;
      final shaped = input.reshape([1, _inputSize, _inputSize, 3]);
      final flat = Float32List(channels * _numAnchors);
      final output = flat.reshape([1, channels, _numAnchors]);
      await _isolate!.run(shaped, output);
      return _bestClassConfidence(output);
    } catch (e, st) {
      debugPrint('PillDetectionService.detectFromFile error: $e\n$st');
      return 0.0;
    }
  }

  /// `reshape` hands back nested lists whose innermost type is `List<double>`,
  /// so index through `dynamic` — casting a row to `List<dynamic>` throws.
  static double _bestClassConfidence(List<dynamic> output) {
    var best = 0.0;
    for (var c = 4; c < 4 + _numClasses; c++) {
      final dynamic row = output[0][c];
      for (var a = 0; a < _numAnchors; a++) {
        final v = row[a] as double;
        if (v > best) best = v;
      }
    }
    return best.clamp(0.0, 1.0).toDouble();
  }

  Future<void> dispose() async {
    await _isolate?.close();
    _isolate = null;
    _interpreter?.close();
    _interpreter = null;
  }
}

/// Decode → 640x640 → RGB float32 [0,1], NHWC. Top-level so it can be handed
/// to [compute]. Returns null when the bytes are not a decodable image.
Float32List? _preprocess(Uint8List bytes) {
  final decoded = img.decodeImage(bytes);
  if (decoded == null) return null;
  final resized = img.copyResize(
    decoded,
    width: PillDetectionService._inputSize,
    height: PillDetectionService._inputSize,
    interpolation: img.Interpolation.linear,
  );

  const size = PillDetectionService._inputSize;
  final flat = Float32List(size * size * 3);
  var idx = 0;
  for (var y = 0; y < size; y++) {
    for (var x = 0; x < size; x++) {
      final p = resized.getPixel(x, y);
      flat[idx++] = p.r / 255.0;
      flat[idx++] = p.g / 255.0;
      flat[idx++] = p.b / 255.0;
    }
  }
  return flat;
}
