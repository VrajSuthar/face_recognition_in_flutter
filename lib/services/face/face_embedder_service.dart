import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

class FaceEmbedderService {
  FaceEmbedderService._(this._interpreter, this._outputSize);

  final Interpreter _interpreter;
  final int _outputSize;

  static const modelAsset = 'assets/model/mobilefacenet.tflite';
  static const inputSize = 112;

  static Future<FaceEmbedderService> load() async {
    final interpreter = await Interpreter.fromAsset(
      modelAsset,
      options: InterpreterOptions()..threads = 4,
    );
    final outputSize = interpreter.getOutputTensor(0).shape.last;
    return FaceEmbedderService._(interpreter, outputSize);
  }

  List<double> embed(img.Image face) {
    final resized = face.width == inputSize && face.height == inputSize
        ? face
        : img.copyResize(face, width: inputSize, height: inputSize);

    final input = [
      List.generate(
        inputSize,
        (y) => List.generate(inputSize, (x) {
          final pixel = resized.getPixel(x, y);
          return [
            (pixel.r - 127.5) / 128.0,
            (pixel.g - 127.5) / 128.0,
            (pixel.b - 127.5) / 128.0,
          ];
        }),
      ),
    ];

    final output = [List.filled(_outputSize, 0.0)];
    _interpreter.run(input, output);
    return output.first;
  }

  void close() => _interpreter.close();
}
