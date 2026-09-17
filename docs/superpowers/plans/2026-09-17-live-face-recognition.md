# Live Face Recognition Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Let a user register a named face (already partially built) and then see, live on the Face Recognition camera screen, a bounding box + name + match percentage for whoever is in frame, by comparing a MobileFaceNet embedding of the live face against all registered embeddings.

**Architecture:** A small set of pure, unit-testable services (`FaceEntry`/`cosineSimilarity`/`bestMatch`, `cropFaceSquare`, `scaleRect`, `FaceRepository`) sit underneath two device-dependent wrappers (`FaceDetectorService` over ML Kit, `FaceEmbedderService` over tflite_flutter) that cannot be unit tested in this environment and must be verified on a real device. `RegisterFaceScreen` and `FaceRecognitionScreen` are the only UI consumers.

**Tech Stack:** Flutter, Riverpod (`flutter_riverpod`), `camera`, `google_mlkit_face_detection`, `tflite_flutter`, `image` (already present), `path_provider` (already present).

**Spec:** `docs/superpowers/specs/2026-09-17-live-face-recognition-design.md`

## Global Constraints

- Face crops/embeddings use exactly **112×112** input (matches the bundled `mobilefacenet.tflite`).
- Embedding pixel normalization: `(channel - 127.5) / 128.0` per the spec.
- Match threshold: cosine similarity **>= 0.65** counts as a match; percentage shown is always `similarity.clamp(0,1) * 100`, even for "Unknown".
- Persisted index file: `<app documents dir>/assets/faces_index.json`; face crop PNGs live alongside it in `<app documents dir>/assets/`.
- No git repository exists in this project yet (user will add one later) — every task's "Commit" step is replaced with a no-op note; do not run `git` commands.
- This project has no working camera/device in this session — Tasks 6-8 are implemented and statically verified (`flutter analyze`) but **must be manually exercised on a real device** before being considered done; say so explicitly rather than claiming they work.

---

### Task 1: Add dependencies and bundle the model asset

**Files:**
- Modify: `pubspec.yaml`

**Interfaces:**
- Produces: working `camera`, `google_mlkit_face_detection`, `tflite_flutter` imports for later tasks; `assets/model/mobilefacenet.tflite` loadable via `rootBundle`/`Interpreter.fromAsset`.

- [ ] **Step 1: Add the packages**

Run: `cd /Volumes/HardDrive1/Vraj/face_recognition_app_1 && flutter pub add camera google_mlkit_face_detection tflite_flutter`

Expected: resolves without version-solving errors (report and stop if it conflicts, the same way earlier riverpod/meta conflicts were diagnosed — read the solver output before changing anything).

- [ ] **Step 2: Declare the model asset**

In `pubspec.yaml`, under the existing `flutter:` section, add (create the `assets:` key if it isn't already there under `flutter:`):

```yaml
flutter:
  uses-material-design: true
  assets:
    - assets/model/mobilefacenet.tflite
```

- [ ] **Step 3: Verify**

Run: `flutter pub get && flutter analyze`
Expected: `Got dependencies!` and `No issues found!`.

- [ ] **Step 4: Commit**

(Skipped — no git repository in this project yet.)

---

### Task 2: Face data model + similarity/match logic (TDD)

**Files:**
- Create: `lib/services/face/face_entry.dart`
- Create: `lib/services/face/face_similarity.dart`
- Test: `test/services/face/face_similarity_test.dart`

**Interfaces:**
- Produces:
  - `class FaceEntry { const FaceEntry({required String name, required String imagePath, required List<double> embedding}); factory FaceEntry.fromJson(Map<String, dynamic>); Map<String, dynamic> toJson(); }`
  - `double cosineSimilarity(List<double> a, List<double> b)`
  - `const double matchThreshold = 0.65;`
  - `class FaceMatch { const FaceMatch({required String name, required double percentage, required bool isMatch}); }`
  - `FaceMatch? bestMatch(List<double> embedding, List<FaceEntry> entries)` — returns `null` only when `entries` is empty; otherwise always returns the closest entry's name + percentage, with `isMatch` telling the caller whether it cleared `matchThreshold`.

- [ ] **Step 1: Write the failing test**

Create `test/services/face/face_similarity_test.dart`:

```dart
import 'package:face_recognition_app_1/services/face/face_entry.dart';
import 'package:face_recognition_app_1/services/face/face_similarity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('cosineSimilarity', () {
    test('identical vectors have similarity 1', () {
      expect(cosineSimilarity([1, 0, 0], [1, 0, 0]), closeTo(1.0, 1e-9));
    });

    test('orthogonal vectors have similarity 0', () {
      expect(cosineSimilarity([1, 0], [0, 1]), closeTo(0.0, 1e-9));
    });

    test('returns 0 for empty vectors', () {
      expect(cosineSimilarity([], []), 0);
    });

    test('returns 0 when either vector is all zeros', () {
      expect(cosineSimilarity([0, 0], [1, 1]), 0);
    });
  });

  group('bestMatch', () {
    const alice = FaceEntry(name: 'Alice', imagePath: 'a.png', embedding: [1, 0, 0]);
    const bob = FaceEntry(name: 'Bob', imagePath: 'b.png', embedding: [0, 1, 0]);

    test('returns null when there are no registered entries', () {
      expect(bestMatch([1, 0, 0], []), isNull);
    });

    test('picks the closest entry and marks it a match above threshold', () {
      final match = bestMatch([1, 0, 0], [alice, bob]);
      expect(match, isNotNull);
      expect(match!.name, 'Alice');
      expect(match.isMatch, isTrue);
      expect(match.percentage, closeTo(100, 1e-6));
    });

    test('still returns the closest entry but marks isMatch false below threshold', () {
      final farVector = [0.0, 0.0, 1.0]; // orthogonal to both alice and bob
      final match = bestMatch(farVector, [alice, bob]);
      expect(match, isNotNull);
      expect(match!.isMatch, isFalse);
      expect(match.percentage, closeTo(0, 1e-6));
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/services/face/face_similarity_test.dart`
Expected: FAIL — `face_entry.dart`/`face_similarity.dart` don't exist yet (import errors).

- [ ] **Step 3: Implement**

Create `lib/services/face/face_entry.dart`:

```dart
class FaceEntry {
  const FaceEntry({
    required this.name,
    required this.imagePath,
    required this.embedding,
  });

  final String name;
  final String imagePath;
  final List<double> embedding;

  factory FaceEntry.fromJson(Map<String, dynamic> json) {
    return FaceEntry(
      name: json['name'] as String,
      imagePath: json['imagePath'] as String,
      embedding: (json['embedding'] as List)
          .map((e) => (e as num).toDouble())
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'imagePath': imagePath,
        'embedding': embedding,
      };
}
```

Create `lib/services/face/face_similarity.dart`:

```dart
import 'dart:math';

import 'face_entry.dart';

class FaceMatch {
  const FaceMatch({
    required this.name,
    required this.percentage,
    required this.isMatch,
  });

  final String name;
  final double percentage;
  final bool isMatch;
}

const matchThreshold = 0.65;

double cosineSimilarity(List<double> a, List<double> b) {
  if (a.length != b.length || a.isEmpty) return 0;

  var dot = 0.0;
  var normA = 0.0;
  var normB = 0.0;
  for (var i = 0; i < a.length; i++) {
    dot += a[i] * b[i];
    normA += a[i] * a[i];
    normB += b[i] * b[i];
  }
  if (normA == 0 || normB == 0) return 0;
  return dot / (sqrt(normA) * sqrt(normB));
}

FaceMatch? bestMatch(List<double> embedding, List<FaceEntry> entries) {
  if (entries.isEmpty) return null;

  var best = entries.first;
  var bestSimilarity = cosineSimilarity(embedding, best.embedding);
  for (final entry in entries.skip(1)) {
    final similarity = cosineSimilarity(embedding, entry.embedding);
    if (similarity > bestSimilarity) {
      bestSimilarity = similarity;
      best = entry;
    }
  }

  final percentage = bestSimilarity.clamp(0.0, 1.0) * 100;
  return FaceMatch(
    name: best.name,
    percentage: percentage,
    isMatch: bestSimilarity >= matchThreshold,
  );
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/services/face/face_similarity_test.dart`
Expected: PASS (all tests green).

- [ ] **Step 5: Commit**

(Skipped — no git repository in this project yet.)

---

### Task 3: Face crop geometry helper (TDD)

**Files:**
- Create: `lib/services/face/face_crop.dart`
- Test: `test/services/face/face_crop_test.dart`

**Interfaces:**
- Consumes: `package:image` `img.Image`, `dart:ui` `Rect` (the type ML Kit's `Face.boundingBox` uses).
- Produces: `img.Image cropFaceSquare(img.Image source, Rect boundingBox, {required int size, double padding = 0.25})` — crops a padded square around `boundingBox`, clamped to the source bounds, and resizes to `size`x`size`.

- [ ] **Step 1: Write the failing test**

Create `test/services/face/face_crop_test.dart`:

```dart
import 'dart:ui';

import 'package:face_recognition_app_1/services/face/face_crop.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

void main() {
  test('crops and resizes to the requested square size', () {
    final source = img.Image(width: 200, height: 200);
    const box = Rect.fromLTWH(50, 50, 60, 60);

    final result = cropFaceSquare(source, box, size: 112);

    expect(result.width, 112);
    expect(result.height, 112);
  });

  test('clamps the crop to the source image bounds near an edge', () {
    final source = img.Image(width: 100, height: 100);
    const box = Rect.fromLTWH(0, 0, 20, 20);

    final result = cropFaceSquare(source, box, size: 112);

    expect(result.width, 112);
    expect(result.height, 112);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/services/face/face_crop_test.dart`
Expected: FAIL — `face_crop.dart` doesn't exist.

- [ ] **Step 3: Implement**

Create `lib/services/face/face_crop.dart`:

```dart
import 'dart:math';
import 'dart:ui';

import 'package:image/image.dart' as img;

img.Image cropFaceSquare(
  img.Image source,
  Rect boundingBox, {
  required int size,
  double padding = 0.25,
}) {
  final padX = boundingBox.width * padding;
  final padY = boundingBox.height * padding;

  final left = (boundingBox.left - padX).clamp(0, source.width.toDouble());
  final top = (boundingBox.top - padY).clamp(0, source.height.toDouble());
  final right = (boundingBox.right + padX).clamp(0, source.width.toDouble());
  final bottom = (boundingBox.bottom + padY).clamp(0, source.height.toDouble());

  final maxWidth = source.width - left;
  final maxHeight = source.height - top;
  final side = min(max(right - left, bottom - top), min(maxWidth, maxHeight));
  final safeSide = side < 1 ? 1.0 : side;

  final cropped = img.copyCrop(
    source,
    x: left.round(),
    y: top.round(),
    width: safeSide.round(),
    height: safeSide.round(),
  );

  return img.copyResize(cropped, width: size, height: size);
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/services/face/face_crop_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

(Skipped — no git repository in this project yet.)

---

### Task 4: Overlay scaling geometry helper (TDD)

**Files:**
- Create: `lib/features/face_recognition/face_overlay_geometry.dart`
- Test: `test/features/face_recognition/face_overlay_geometry_test.dart`

**Interfaces:**
- Produces: `Rect scaleRect(Rect source, Size fromSize, Size toSize)` — linearly scales a rect from one coordinate space to another (used to map a face box from camera-sensor pixels to the on-screen preview widget's pixels).

- [ ] **Step 1: Write the failing test**

Create `test/features/face_recognition/face_overlay_geometry_test.dart`:

```dart
import 'dart:ui';

import 'package:face_recognition_app_1/features/face_recognition/face_overlay_geometry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('scales a rect proportionally between two sizes', () {
    const source = Rect.fromLTWH(10, 20, 30, 40);
    const fromSize = Size(100, 200);
    const toSize = Size(200, 400);

    final result = scaleRect(source, fromSize, toSize);

    expect(result.left, 20);
    expect(result.top, 40);
    expect(result.width, 60);
    expect(result.height, 80);
  });

  test('handles non-uniform scale factors', () {
    const source = Rect.fromLTWH(0, 0, 10, 10);
    const fromSize = Size(10, 10);
    const toSize = Size(50, 20);

    final result = scaleRect(source, fromSize, toSize);

    expect(result.width, 50);
    expect(result.height, 20);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/face_recognition/face_overlay_geometry_test.dart`
Expected: FAIL — file doesn't exist.

- [ ] **Step 3: Implement**

Create `lib/features/face_recognition/face_overlay_geometry.dart`:

```dart
import 'dart:ui';

Rect scaleRect(Rect source, Size fromSize, Size toSize) {
  final scaleX = toSize.width / fromSize.width;
  final scaleY = toSize.height / fromSize.height;
  return Rect.fromLTRB(
    source.left * scaleX,
    source.top * scaleY,
    source.right * scaleX,
    source.bottom * scaleY,
  );
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/face_recognition/face_overlay_geometry_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

(Skipped — no git repository in this project yet.)

---

### Task 5: FaceRepository persistence (TDD)

**Files:**
- Create: `lib/services/face/face_repository.dart`
- Test: `test/services/face/face_repository_test.dart`

**Interfaces:**
- Consumes: `FaceEntry` (Task 2).
- Produces:
  - `class FaceRepository { FaceRepository(Directory assetsDir); static Future<FaceRepository> forAppDocuments(); Directory get assetsDir; Future<List<FaceEntry>> loadAll(); Future<void> add(FaceEntry entry); }`
  - The constructor takes the assets directory directly (dependency injection) so tests never touch `path_provider`; `forAppDocuments()` is the only thing that calls `getApplicationDocumentsDirectory()`, used by app code.

- [ ] **Step 1: Write the failing test**

Create `test/services/face/face_repository_test.dart`:

```dart
import 'dart:io';

import 'package:face_recognition_app_1/services/face/face_entry.dart';
import 'package:face_recognition_app_1/services/face/face_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory tempDir;
  late FaceRepository repository;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('face_repo_test');
    repository = FaceRepository(tempDir);
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('loadAll returns an empty list when no index file exists', () async {
    expect(await repository.loadAll(), isEmpty);
  });

  test('add persists an entry that loadAll returns', () async {
    const entry = FaceEntry(
      name: 'Alice',
      imagePath: '/tmp/alice.png',
      embedding: [0.1, 0.2, 0.3],
    );

    await repository.add(entry);
    final loaded = await repository.loadAll();

    expect(loaded, hasLength(1));
    expect(loaded.first.name, 'Alice');
    expect(loaded.first.embedding, [0.1, 0.2, 0.3]);
  });

  test('add appends to existing entries in order', () async {
    await repository.add(
      const FaceEntry(name: 'Alice', imagePath: 'a', embedding: [1]),
    );
    await repository.add(
      const FaceEntry(name: 'Bob', imagePath: 'b', embedding: [2]),
    );

    final loaded = await repository.loadAll();
    expect(loaded.map((e) => e.name), ['Alice', 'Bob']);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/services/face/face_repository_test.dart`
Expected: FAIL — file doesn't exist.

- [ ] **Step 3: Implement**

Create `lib/services/face/face_repository.dart`:

```dart
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'face_entry.dart';

class FaceRepository {
  FaceRepository(this.assetsDir);

  final Directory assetsDir;

  static Future<FaceRepository> forAppDocuments() async {
    final documentsDir = await getApplicationDocumentsDirectory();
    return FaceRepository(Directory(p.join(documentsDir.path, 'assets')));
  }

  File get _indexFile => File(p.join(assetsDir.path, 'faces_index.json'));

  Future<List<FaceEntry>> loadAll() async {
    if (!await _indexFile.exists()) return [];
    final contents = await _indexFile.readAsString();
    if (contents.trim().isEmpty) return [];
    final list = jsonDecode(contents) as List;
    return list
        .map((e) => FaceEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> add(FaceEntry entry) async {
    if (!await assetsDir.exists()) {
      await assetsDir.create(recursive: true);
    }
    final entries = await loadAll();
    entries.add(entry);
    await _indexFile.writeAsString(
      jsonEncode(entries.map((e) => e.toJson()).toList()),
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/services/face/face_repository_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

(Skipped — no git repository in this project yet.)

---

### Task 6: Device-dependent services — face detection, embedding, camera frame conversion, providers

**Files:**
- Create: `lib/services/face/face_detector_service.dart`
- Create: `lib/services/face/face_embedder_service.dart`
- Create: `lib/services/face/camera_image_converter.dart`
- Create: `lib/services/face/providers.dart`

**Interfaces:**
- Consumes: `FaceRepository` (Task 5).
- Produces:
  - `class FaceDetectorService { FaceDetectorService(); Future<mlkit.Face?> detectLargestFace(mlkit.InputImage image); void close(); }`
  - `class FaceEmbedderService { static Future<FaceEmbedderService> load(); List<double> embed(img.Image face); void close(); static const inputSize = 112; }`
  - `mlkit.InputImage? inputImageFromCameraImage(CameraImage image, CameraDescription camera)`
  - `img.Image imageFromCameraImage(CameraImage image)`
  - `final faceDetectorServiceProvider = Provider<FaceDetectorService>(...)`
  - `final faceEmbedderServiceProvider = FutureProvider<FaceEmbedderService>(...)`
  - `final faceRepositoryProvider = FutureProvider<FaceRepository>(...)`

No unit tests: this task is entirely wrappers around platform plugins (ML Kit, tflite_flutter's FFI interpreter, raw camera pixel buffers) that don't run under `flutter test` in this environment. Verify with `flutter analyze` only; functional correctness is confirmed on-device in Task 8's manual check.

- [ ] **Step 1: Face detector wrapper**

Create `lib/services/face/face_detector_service.dart`:

```dart
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class FaceDetectorService {
  FaceDetectorService()
      : _detector = FaceDetector(
          options: FaceDetectorOptions(performanceMode: FaceDetectorMode.fast),
        );

  final FaceDetector _detector;

  Future<Face?> detectLargestFace(InputImage image) async {
    final faces = await _detector.processImage(image);
    if (faces.isEmpty) return null;

    var largest = faces.first;
    var largestArea = largest.boundingBox.width * largest.boundingBox.height;
    for (final face in faces.skip(1)) {
      final area = face.boundingBox.width * face.boundingBox.height;
      if (area > largestArea) {
        largest = face;
        largestArea = area;
      }
    }
    return largest;
  }

  void close() => _detector.close();
}
```

- [ ] **Step 2: Embedder wrapper**

Create `lib/services/face/face_embedder_service.dart`:

```dart
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

class FaceEmbedderService {
  FaceEmbedderService._(this._interpreter, this._outputSize);

  final Interpreter _interpreter;
  final int _outputSize;

  static const modelAsset = 'assets/model/mobilefacenet.tflite';
  static const inputSize = 112;

  static Future<FaceEmbedderService> load() async {
    final interpreter = await Interpreter.fromAsset(modelAsset);
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
```

- [ ] **Step 3: Camera frame conversion**

Create `lib/services/face/camera_image_converter.dart`:

```dart
import 'dart:io';
import 'dart:ui';

import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;

/// Builds an ML Kit [InputImage] from a raw camera frame. Requires the
/// [CameraController] to have been created with
/// `imageFormatGroup: ImageFormatGroup.bgra8888` on iOS or
/// `ImageFormatGroup.nv21` on Android — both formats hand back a single
/// image plane, which is what this function assumes.
InputImage? inputImageFromCameraImage(
  CameraImage image,
  CameraDescription camera,
) {
  final rotation = InputImageRotationValue.fromRawValue(camera.sensorOrientation);
  if (rotation == null) return null;

  final format = InputImageFormatValue.fromRawValue(image.format.raw);
  if (format == null) return null;
  if (Platform.isAndroid && format != InputImageFormat.nv21) return null;
  if (Platform.isIOS && format != InputImageFormat.bgra8888) return null;
  if (image.planes.length != 1) return null;

  final plane = image.planes.first;
  return InputImage.fromBytes(
    bytes: plane.bytes,
    metadata: InputImageMetadata(
      size: Size(image.width.toDouble(), image.height.toDouble()),
      rotation: rotation,
      format: format,
      bytesPerRow: plane.bytesPerRow,
    ),
  );
}

/// Decodes a raw camera frame into a [img.Image] in the *same,
/// un-rotated* pixel coordinate space that ML Kit's [Face.boundingBox]
/// is reported in, so a box from [inputImageFromCameraImage]'s result can
/// be used directly against this image (e.g. via `cropFaceSquare`).
img.Image imageFromCameraImage(CameraImage image) {
  return Platform.isIOS ? _bgra8888ToImage(image) : _nv21ToImage(image);
}

img.Image _bgra8888ToImage(CameraImage image) {
  final plane = image.planes.first;
  return img.Image.fromBytes(
    width: image.width,
    height: image.height,
    bytes: plane.bytes.buffer,
    order: img.ChannelOrder.bgra,
  );
}

img.Image _nv21ToImage(CameraImage image) {
  final width = image.width;
  final height = image.height;
  final bytes = image.planes.first.bytes;
  final frameSize = width * height;
  final out = img.Image(width: width, height: height);

  for (var row = 0; row < height; row++) {
    for (var col = 0; col < width; col++) {
      final y = bytes[row * width + col] & 0xff;
      final uvRow = row ~/ 2;
      final uvCol = col ~/ 2;
      final uvIndex = frameSize + uvRow * width + uvCol * 2;
      final v = bytes[uvIndex] & 0xff;
      final u = bytes[uvIndex + 1] & 0xff;

      final r = (y + 1.370705 * (v - 128)).round().clamp(0, 255);
      final g =
          (y - 0.337633 * (u - 128) - 0.698001 * (v - 128)).round().clamp(0, 255);
      final b = (y + 1.732446 * (u - 128)).round().clamp(0, 255);

      out.setPixelRgb(col, row, r, g, b);
    }
  }
  return out;
}
```

- [ ] **Step 4: Riverpod providers**

Create `lib/services/face/providers.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'face_detector_service.dart';
import 'face_embedder_service.dart';
import 'face_repository.dart';

final faceDetectorServiceProvider = Provider<FaceDetectorService>((ref) {
  final service = FaceDetectorService();
  ref.onDispose(service.close);
  return service;
});

final faceEmbedderServiceProvider =
    FutureProvider<FaceEmbedderService>((ref) async {
  final service = await FaceEmbedderService.load();
  ref.onDispose(service.close);
  return service;
});

final faceRepositoryProvider = FutureProvider<FaceRepository>((ref) {
  return FaceRepository.forAppDocuments();
});
```

- [ ] **Step 5: Verify**

Run: `flutter analyze`
Expected: `No issues found!`. (There is no automated test for this task — see the note above.)

- [ ] **Step 6: Commit**

(Skipped — no git repository in this project yet.)

---

### Task 7: Wire face detection + embedding into RegisterFaceScreen

**Files:**
- Modify: `lib/features/register_face/register_face_screen.dart` (full rewrite of the existing file)

**Interfaces:**
- Consumes: `cropFaceSquare` (Task 3), `FaceEntry` (Task 2), `faceDetectorServiceProvider`/`faceEmbedderServiceProvider`/`faceRepositoryProvider` (Task 6).
- Produces: a screen that, given a name and a picked/captured photo, saves a 112×112 face crop + its embedding under that name.

- [ ] **Step 1: Rewrite the screen**

Replace the full contents of `lib/features/register_face/register_face_screen.dart` with:

```dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;

import '../../services/face/face_crop.dart';
import '../../services/face/face_entry.dart';
import '../../services/face/providers.dart';

const _faceImageSize = 112;

class RegisterFaceScreen extends ConsumerStatefulWidget {
  const RegisterFaceScreen({super.key});

  @override
  ConsumerState<RegisterFaceScreen> createState() =>
      _RegisterFaceScreenState();
}

class _RegisterFaceScreenState extends ConsumerState<RegisterFaceScreen> {
  final _nameController = TextEditingController();
  File? _savedImage;
  String? _error;
  bool _isProcessing = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickAndSaveImage(ImageSource source) async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Enter a name before picking an image.');
      return;
    }

    setState(() {
      _isProcessing = true;
      _error = null;
    });

    try {
      final picked = await ImagePicker().pickImage(source: source);
      if (picked == null) {
        setState(() => _isProcessing = false);
        return;
      }

      final bytes = await picked.readAsBytes();
      final decoded = img.decodeImage(bytes);
      if (decoded == null) {
        throw Exception('Could not decode the selected image.');
      }

      final detector = ref.read(faceDetectorServiceProvider);
      final face = await detector
          .detectLargestFace(InputImage.fromFilePath(picked.path));
      if (face == null) {
        throw Exception('No face detected in the selected image.');
      }

      final cropped =
          cropFaceSquare(decoded, face.boundingBox, size: _faceImageSize);

      final repository = await ref.read(faceRepositoryProvider.future);
      if (!await repository.assetsDir.exists()) {
        await repository.assetsDir.create(recursive: true);
      }
      final fileName = 'face_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File(p.join(repository.assetsDir.path, fileName));
      await file.writeAsBytes(img.encodePng(cropped));

      final embedder = await ref.read(faceEmbedderServiceProvider.future);
      final embedding = embedder.embed(cropped);

      await repository.add(
        FaceEntry(name: name, imagePath: file.path, embedding: embedding),
      );

      if (!mounted) return;
      setState(() {
        _savedImage = file;
        _isProcessing = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to save image: $e';
        _isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register Face')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              const SizedBox(height: 16),
              if (_savedImage != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    _savedImage!,
                    width: _faceImageSize.toDouble(),
                    height: _faceImageSize.toDouble(),
                    fit: BoxFit.cover,
                  ),
                )
              else
                const Icon(Icons.person_add_alt_1, size: 64),
              const SizedBox(height: 16),
              if (_savedImage != null)
                Text(
                  'Saved to:\n${_savedImage!.path}',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    _error!,
                    style:
                        TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                ),
              const SizedBox(height: 24),
              if (_isProcessing)
                const CircularProgressIndicator()
              else
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => _pickAndSaveImage(ImageSource.camera),
                      icon: const Icon(Icons.camera_alt_outlined),
                      label: const Text('Camera'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: () => _pickAndSaveImage(ImageSource.gallery),
                      icon: const Icon(Icons.photo_library_outlined),
                      label: const Text('Gallery'),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Verify**

Run: `flutter analyze`
Expected: `No issues found!`.

- [ ] **Step 3: Manual on-device check**

Run the app on a real device (`flutter run`), enter a name, pick/capture a clear face photo, and confirm: a 112×112 preview appears, a file shows up under the app's documents `assets/` folder, and `faces_index.json` in that same folder gains an entry with a non-empty `embedding` array. Report this explicitly as either verified-on-device or not-yet-verified — do not claim it works without having run it.

- [ ] **Step 4: Commit**

(Skipped — no git repository in this project yet.)

---

### Task 8: Live camera recognition on FaceRecognitionScreen

**Files:**
- Create: `lib/features/face_recognition/face_overlay_painter.dart`
- Modify: `lib/features/face_recognition/face_recognition_screen.dart` (full rewrite of the existing file)

**Interfaces:**
- Consumes: `scaleRect` (Task 4), `cropFaceSquare` (Task 3), `bestMatch`/`FaceMatch` (Task 2), `inputImageFromCameraImage`/`imageFromCameraImage` (Task 6), `faceDetectorServiceProvider`/`faceEmbedderServiceProvider`/`faceRepositoryProvider` (Task 6).
- Produces: the finished feature — a live camera screen with a bounding box + `Name — NN%` (or `Unknown — NN%`) overlay.

- [ ] **Step 1: Overlay painter**

Create `lib/features/face_recognition/face_overlay_painter.dart`:

```dart
import 'package:flutter/material.dart';

class FaceOverlayPainter extends CustomPainter {
  const FaceOverlayPainter({required this.box, this.label});

  final Rect box;
  final String? label;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.greenAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawRect(box, paint);

    final label = this.label;
    if (label != null) {
      final textPainter = TextPainter(
        text: TextSpan(
          text: label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            backgroundColor: Colors.black54,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(
        canvas,
        Offset(box.left, (box.top - textPainter.height - 4).clamp(0, size.height)),
      );
    }
  }

  @override
  bool shouldRepaint(covariant FaceOverlayPainter oldDelegate) {
    return oldDelegate.box != box || oldDelegate.label != label;
  }
}
```

- [ ] **Step 2: Rewrite the screen**

Replace the full contents of `lib/features/face_recognition/face_recognition_screen.dart` with:

```dart
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/face/camera_image_converter.dart';
import '../../services/face/face_crop.dart';
import '../../services/face/face_similarity.dart';
import '../../services/face/providers.dart';
import 'face_overlay_geometry.dart';
import 'face_overlay_painter.dart';

const _throttle = Duration(milliseconds: 700);
const _embedSize = 112;

class FaceRecognitionScreen extends ConsumerStatefulWidget {
  const FaceRecognitionScreen({super.key});

  @override
  ConsumerState<FaceRecognitionScreen> createState() =>
      _FaceRecognitionScreenState();
}

class _FaceRecognitionScreenState extends ConsumerState<FaceRecognitionScreen> {
  CameraController? _controller;
  String? _statusMessage = 'Starting camera…';
  bool _isBusy = false;
  DateTime _lastRun = DateTime.fromMillisecondsSinceEpoch(0);
  Rect? _boxSensorSpace;
  Size _sensorSize = Size.zero;
  String? _label;

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    final repository = await ref.read(faceRepositoryProvider.future);
    final entries = await repository.loadAll();
    if (!mounted) return;
    if (entries.isEmpty) {
      setState(() => _statusMessage = 'Register a face first.');
      return;
    }

    final cameras = await availableCameras();
    if (cameras.isEmpty) {
      if (!mounted) return;
      setState(() => _statusMessage = 'No camera available on this device.');
      return;
    }
    final frontCamera = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );

    final controller = CameraController(
      frontCamera,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup:
          Platform.isIOS ? ImageFormatGroup.bgra8888 : ImageFormatGroup.nv21,
    );

    try {
      await controller.initialize();
    } catch (e) {
      if (!mounted) return;
      setState(() => _statusMessage = 'Could not start the camera: $e');
      return;
    }

    if (!mounted) {
      await controller.dispose();
      return;
    }

    setState(() {
      _controller = controller;
      _statusMessage = null;
    });

    await controller.startImageStream((image) => _onFrame(image, frontCamera));
  }

  Future<void> _onFrame(CameraImage image, CameraDescription camera) async {
    if (_isBusy || !mounted) return;
    final now = DateTime.now();
    if (now.difference(_lastRun) < _throttle) return;
    _isBusy = true;
    _lastRun = now;

    try {
      final inputImage = inputImageFromCameraImage(image, camera);
      if (inputImage == null) return;

      final detector = ref.read(faceDetectorServiceProvider);
      final face = await detector.detectLargestFace(inputImage);
      if (!mounted) return;

      if (face == null) {
        setState(() {
          _boxSensorSpace = null;
          _label = null;
          _statusMessage = 'No face detected';
        });
        return;
      }

      final rawImage = imageFromCameraImage(image);
      final cropped = cropFaceSquare(rawImage, face.boundingBox, size: _embedSize);

      final embedder = await ref.read(faceEmbedderServiceProvider.future);
      final embedding = embedder.embed(cropped);

      final repository = await ref.read(faceRepositoryProvider.future);
      final entries = await repository.loadAll();
      final match = bestMatch(embedding, entries);
      if (!mounted) return;

      setState(() {
        _boxSensorSpace = face.boundingBox;
        _sensorSize = Size(image.width.toDouble(), image.height.toDouble());
        _statusMessage = null;
        _label = match == null
            ? null
            : '${match.isMatch ? match.name : 'Unknown'} — ${match.percentage.round()}%';
      });
    } finally {
      _isBusy = false;
    }
  }

  @override
  void dispose() {
    _controller?.stopImageStream();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    return Scaffold(
      appBar: AppBar(title: const Text('Face Recognition')),
      body: controller == null || !controller.value.isInitialized
          ? Center(child: Text(_statusMessage ?? 'Loading…'))
          : LayoutBuilder(
              builder: (context, constraints) {
                final previewSize =
                    Size(constraints.maxWidth, constraints.maxHeight);
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    CameraPreview(controller),
                    // NOTE: verify on device — if the box appears rotated
                    // 90 degrees relative to the visible face, swap
                    // `_sensorSize`'s width/height here to match how
                    // CameraPreview rotates the raw sensor frame for display.
                    if (_boxSensorSpace != null && _sensorSize != Size.zero)
                      CustomPaint(
                        painter: FaceOverlayPainter(
                          box: scaleRect(
                              _boxSensorSpace!, _sensorSize, previewSize),
                          label: _label,
                        ),
                      ),
                    if (_statusMessage != null)
                      Positioned(
                        bottom: 24,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            color: Colors.black54,
                            child: Text(
                              _statusMessage!,
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
    );
  }
}
```

- [ ] **Step 3: Verify statically**

Run: `flutter analyze`
Expected: `No issues found!`.

- [ ] **Step 4: Manual on-device check**

Run on a real device with at least one face already registered (Task 7). Point the front camera at that person: confirm a green box appears around the face with `Name — NN%` where NN is high (>65). Point it at someone unregistered: confirm `Unknown — NN%` with a lower NN. Check the box's position roughly tracks the face; if it's rotated or offset, adjust the `_sensorSize` swap noted in the code comment above and re-check. Report the outcome explicitly (worked / didn't work / needed the rotation fix) rather than assuming success.

- [ ] **Step 5: Commit**

(Skipped — no git repository in this project yet.)

---

## Self-Review Notes

- **Spec coverage:** model input size (112×112) — Tasks 2/3/6/7/8; new dependencies — Task 1; `FaceRepository` JSON persistence — Task 5; register-flow name capture + crop + embed + save — Task 7; live continuous recognition with throttling, overlay, and edge cases (no camera, no face, no enrolled faces) — Task 8; unit tests for the testable pure logic — Tasks 2-4; out-of-scope items (editing/deleting faces, camera switch, liveness) intentionally have no task.
- **Type consistency checked:** `FaceEntry`, `FaceMatch`, `bestMatch`, `cropFaceSquare`, `scaleRect`, `FaceDetectorService`, `FaceEmbedderService`, `inputImageFromCameraImage`, `imageFromCameraImage`, and all three providers are used with identical names/signatures across Tasks 6-8.
- **No placeholders:** every step has real, complete code — the only caveats called out (sensor-rotation calibration, on-device verification) are genuine environment limitations (no camera/device available in this session), not deferred work.
