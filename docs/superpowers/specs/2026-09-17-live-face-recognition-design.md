# Live Face Recognition — Design

## Goal

Register named faces, then use the live camera on the Face Recognition
screen to detect a face, compare it against all registered faces, and
overlay the best-matching name with a similarity percentage in
real time.

## Model

`assets/model/mobilefacenet.tflite` is already added to the project.
Input: a 112×112 RGB face crop (matches the size already produced by
`RegisterFaceScreen`). Output: an embedding vector (the loader reads
the actual output tensor shape at runtime rather than hardcoding
128 vs 192, so it works with whatever variant of the model is bundled).

## New dependencies

- `camera` — live preview + frame stream on the recognition screen.
- `google_mlkit_face_detection` — on-device face bounding-box
  detection, used both at registration time (to crop the face out of
  a picked/captured photo) and on each live camera frame.
- `tflite_flutter` — runs the bundled `.tflite` model.

`pubspec.yaml` must declare `assets/model/mobilefacenet.tflite` under
`flutter: assets:`.

## New shared services (`lib/services/face/`)

- `face_detector_service.dart` — wraps ML Kit's `FaceDetector`.
  `Future<Face?> detectLargestFace(InputImage image)` returns the
  largest detected face (by bounding-box area), or null.
- `face_embedder_service.dart` — loads the `.tflite` model once
  (singleton-style, created in `main.dart` and passed down via
  Riverpod provider). `List<double> embed(img.Image face112x112)`
  normalizes pixels to roughly [-1, 1] ((pixel - 127.5) / 128.0),
  runs the interpreter, and returns the output vector.
- `face_repository.dart` — persists enrolled faces as JSON at
  `<app documents dir>/assets/faces_index.json`:
  ```json
  [{"name": "Alice", "imagePath": "…/assets/face_123.png", "embedding": [0.1, ...]}]
  ```
  Exposes `Future<void> add(FaceEntry entry)` and
  `Future<List<FaceEntry>> loadAll()`.
- `face_match.dart` — `FaceEntry` model plus
  `FaceMatch? bestMatch(List<double> embedding, List<FaceEntry> entries)`
  using cosine similarity, mapped to a 0–100% score. Returns null (→
  "Unknown") if no entry's similarity clears 0.65.

## Register flow changes

`RegisterFaceScreen` adds a required name `TextField` above the
existing Camera/Gallery buttons. On pick:

1. Decode the picked image.
2. Run `detectLargestFace`; if none found, show an error and stop.
3. Crop to the face bounding box (with small padding), resize to
   112×112 (replacing the current whole-image `copyResizeCropSquare`
   call, which ignored where the face actually was).
4. Save the 112×112 PNG to `<app docs>/assets/` as today.
5. Compute the embedding via `face_embedder_service` and persist
   `{name, imagePath, embedding}` via `face_repository`.

## Recognition flow (live, continuous)

`FaceRecognitionScreen` becomes a `StatefulWidget` that:

1. Requests camera permission (reuses the `camera` permission already
   declared for Android/iOS) and opens the front camera via
   `CameraController`.
2. Loads all `FaceEntry`s from `face_repository` once on screen entry;
   if empty, shows "Register a face first" instead of starting the
   stream.
3. Starts `startImageStream`. On each frame, if a previous inference
   is still running, the frame is dropped (no queueing). Otherwise:
   - Convert the camera frame to ML Kit's `InputImage`.
   - `detectLargestFace` → if null, clear the overlay and show "No
     face detected".
   - Crop/resize the detected region to 112×112, embed it, call
     `bestMatch`.
   - Update overlay state: bounding box (scaled from image
     coordinates to the preview widget's size) + label
     `"$name — ${percentage.round()}%"` or `"Unknown — ${percentage.round()}%"`.
   - Throttle to roughly one inference per 700ms (a simple
     `DateTime` check is enough — no need for a Timer).
4. Overlay is drawn with a `CustomPainter` in a `Stack` above the
   `CameraPreview`.
5. Disposes the `CameraController` and face detector in `dispose()`.

## Error handling

- Camera permission denied → inline message + a button to retry the
  request (no deep link into system settings needed for v1).
- No camera available (e.g. desktop dev run without a webcam) → show
  a message rather than crashing.
- No face in frame → overlay clears, status text says so.
- No enrolled faces → skip inference entirely, show a prompt to go
  register one.

## Testing

Camera/ML Kit/tflite aren't unit-testable in this environment, but the
pure logic is: `face_match.dart`'s cosine similarity + best-match
selection gets unit tests with fixed embedding vectors (exact match,
no match, empty entry list, tie-breaking). `flutter analyze` covers
the rest; manual on-device verification is required for the actual
camera/recognition path since there's no simulator camera feed.

## Out of scope (v1)

- Editing/deleting a previously registered face.
- Switching between front/back camera.
- Anti-spoofing / liveness detection.
