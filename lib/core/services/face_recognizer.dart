import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

class FaceRecognizer {
  Interpreter? _interpreter;
  final int inputSize = 112;

  Future<img.Image> loadNetworkImage(String imageUrl) async {
    try {
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode != 200) throw Exception("Failed to load network image");

      final image = img.decodeImage(response.bodyBytes);
      if (image == null) throw Exception("Unable to decode image from network");

      return img.copyResize(image, width: inputSize, height: inputSize);
    } catch (e) {
      throw Exception("loadNetworkImage error: $e");
    }
  }

  Future<void> loadModel() async {
    print("🔄 Loading TFLite model...");
    _interpreter = await Interpreter.fromAsset('assets/model/mobilefacenet.tflite');
    _interpreter!.allocateTensors();
    print("✅ TFLite model loaded");
    print("Input shape: ${_interpreter!.getInputTensor(0).shape}");
    print("Input type: ${_interpreter!.getInputTensor(0).type}");
    print("Output shape: ${_interpreter!.getOutputTensor(0).shape}");
    print("Output type: ${_interpreter!.getOutputTensor(0).type}");
  }

  bool get isReady => _interpreter != null;

  Future<img.Image> loadBase64Image(String base64Str) async {
    try {
      base64Str = base64Str.split(',').last; // ✅ Strip prefix
      final bytes = base64Decode(base64Str);
      final image = img.decodeImage(bytes);
      if (image == null) throw Exception('Failed to decode base64 image');

      return img.copyResize(image, width: inputSize, height: inputSize);
    } catch (e) {
      throw Exception('loadBase64Image error: $e');
    }
  }

  Future<img.Image> loadAssetImage(String assetPath) async {
    final data = await rootBundle.load(assetPath);
    final bytes = data.buffer.asUint8List();
    final image = img.decodeImage(bytes);
    if (image == null) throw Exception('Failed to decode asset image');
    return img.copyResize(image, width: inputSize, height: inputSize);
  }

  Future<img.Image> loadFileImage(String filePath) async {
    final bytes = await File(filePath).readAsBytes();
    final image = img.decodeImage(bytes);
    if (image == null) throw Exception('Failed to decode file image');
    return img.copyResize(image, width: inputSize, height: inputSize);
  }

  List<double> getEmbedding(img.Image image) {
    if (_interpreter == null) {
      throw Exception('Interpreter not initialized');
    }
    print("Input shape: ${_interpreter!.getInputTensor(0).shape}");
    final input = List.generate(
      1,
      (_) => List.generate(
        112,
        (y) => List.generate(112, (x) {
          final pixel = image.getPixel(x, y);
          return [(pixel.r - 128) / 128.0, (pixel.g - 128) / 128.0, (pixel.b - 128) / 128.0];
        }),
      ),
    );

    // final output = List<List<double>>.generate(1, (_) => List.filled(128, 0.0));

    final output = List<List<double>>.generate(1, (_) => List.filled(192, 0.0));

    _interpreter!.run(input, output);
    print("🔍 Embedding: ${output[0].take(5)}...");

    return List<double>.from(output[0]);
  }

  Float32List _imageToFloat32(img.Image image) {
    final Float32List floatList = Float32List(inputSize * inputSize * 3);
    int index = 0;

    for (int y = 0; y < inputSize; y++) {
      for (int x = 0; x < inputSize; x++) {
        final pixel = image.getPixel(x, y);
        floatList[index++] = (pixel.r - 128) / 128.0;
        floatList[index++] = (pixel.g - 128) / 128.0;
        floatList[index++] = (pixel.b - 128) / 128.0;
      }
    }
    return floatList;
  }

  double compareEmbeddings(List<double> e1, List<double> e2) {
    double dot = 0.0, normA = 0.0, normB = 0.0;
    for (int i = 0; i < e1.length; i++) {
      dot += e1[i] * e2[i];
      normA += e1[i] * e1[i];
      normB += e2[i] * e2[i];
    }
    final similarity = dot / (sqrt(normA) * sqrt(normB));
    print("📏 Cosine similarity: $similarity");
    return dot / (sqrt(normA) * sqrt(normB));
  }
}

class FaceMatch {
  final String name;
  final List<double> embedding;

  FaceMatch({required this.name, required this.embedding});
}

extension ReshapeList<T> on List<T> {
  List<List<T>> reshape(List<int> shape) {
    final outer = shape[0], inner = shape[1];
    return List.generate(outer, (i) => this.sublist(i * inner, (i + 1) * inner));
  }
}
