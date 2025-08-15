import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

class InterpreterServices {
  static const String _modelPath = 'assets/model_unquant.tflite';
  static const String _labelPath = 'assets/labels.txt';
  late final Interpreter _interpreter;
  late final List<String> labels;

  // Load the TFLite model
  Future<void> loadModel() async {
    try {
      final interpreterOptions = InterpreterOptions();

      _interpreter = await Interpreter.fromAsset(
        _modelPath,
        options: interpreterOptions,
      );
      await _loadLabels();
    } catch (e) {
      debugPrint("Error loading model: $e");
    }
  }

  // Load the labels
  Future<void> _loadLabels() async {
    final labelsRaw = await rootBundle.loadString(_labelPath);
    labels = labelsRaw
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();
    debugPrint('Loaded ${labels.length} labels');
  }

  // Preprocess the image to match model input requirements
  List _preprocessImage(img.Image image) {
    Float32List input = Float32List(224 * 224 * 3);
    int index = 0;

    for (int y = 0; y < 224; y++) {
      for (int x = 0; x < 224; x++) {
        img.Pixel pixel = image.getPixel(x, y);

        num red = pixel.r;
        num green = pixel.g;
        num blue = pixel.b;

        // Normalize to [0, 1]
        input[index++] = red / 255.0;
        input[index++] = green / 255.0;
        input[index++] = blue / 255.0;
      }
    }
    return input;
  }

  Future<void> classifyImage(File image, Function(List<dynamic>) onResult,
      VoidCallback onError) async {
    try {
      img.Image? imageInput = img.decodeImage(image.readAsBytesSync());
      img.Image resizedImage =
          img.copyResize(imageInput!, width: 224, height: 224);
      var input = _preprocessImage(resizedImage);

      // Create output buffer based on label count
      var output = _createOutputBuffer();

      // Run the interpreter
      _interpreter.run(input.reshape([1, 224, 224, 3]), output);

      // Post-process the output
      List<dynamic> result = _postprocess(output);
      onResult(result);
    } catch (e) {
      debugPrint("Error running model on image: $e");
      onError();
    }
  }

  List<dynamic> _postprocess(List<List<double>> output) {
    debugPrint("Raw output: $output");
    final scores = output[0];
    final maxScore = scores.reduce((a, b) => a > b ? a : b);
    final maxIndex = scores.indexOf(maxScore);
    final predictedLabel = labels[maxIndex];

    if (output[0][0] >= 0.60 && output[0][1] >= 0.30) {
      return ["Unknown", maxScore];
    } else {
      return [predictedLabel, maxScore];
    }
  }

  List<List<double>> _createOutputBuffer() {
    return List.generate(1, (_) => List.filled(labels.length, 0.0));
  }
}
