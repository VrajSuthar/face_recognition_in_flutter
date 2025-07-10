// import 'package:camera/camera.dart';
// import 'package:eduwrx/core/common_widgets/hole_painter.dart';
// import 'package:eduwrx/features/view/main_view/face_recognition_screen/bloc/face_recognition_bloc.dart';
// import 'package:eduwrx/features/view/main_view/face_recognition_screen/bloc/face_recognition_state.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';

// class FaceRecognitionWidgets {
//   static const double ovalWidth = 300;
//   static const double ovalHeight = 400;

//   Widget body(BuildContext context) {
//     return BlocBuilder<FaceRecognitionBloc, FaceRecognitionState>(
//       buildWhen: (prev, curr) => curr is! FaceRecognitionError,
//       builder: (context, state) {
//         if (state is CameraLoading || state is FaceRecognitionInitial) {
//           return const Center(child: CircularProgressIndicator());
//         }

//         if (state is CameraReady) {
//           final controller = state.controller;

//           return Stack(
//             children: [
//               SizedBox.expand(child: CameraPreview(controller)),

//               // Oval overlay
//               IgnorePointer(
//                 child: Center(
//                   child: CustomPaint(
//                     size: MediaQuery.of(context).size,
//                     painter: HolePainter(ovalWidth: ovalWidth, ovalHeight: ovalHeight),
//                   ),
//                 ),
//               ),

//               // Oval border
//               Center(
//                 child: Container(
//                   width: ovalWidth,
//                   height: ovalHeight,
//                   decoration: BoxDecoration(
//                     color: Colors.transparent,
//                     border: Border.all(color: Colors.white, width: 3),
//                     borderRadius: BorderRadius.all(Radius.elliptical(ovalWidth, ovalHeight)),
//                   ),
//                 ),
//               ),

//               // Status message
//               Positioned(
//                 top: 60,
//                 left: 0,
//                 right: 0,
//                 child: BlocSelector<FaceRecognitionBloc, FaceRecognitionState, String>(
//                   selector: (state) {
//                     if (state is NoFaceDetected) return "No face detected";
//                     if (state is FaceNotMatched) return "Face not recognized";
//                     if (state is FaceMatched) return "Welcome, ${state.name}";
//                     if (state is FaceOutsideOval) return "Align face inside the oval";
//                     if (state is FaceRecognitionError) return "Error: ${state.message}";
//                     return '';
//                   },
//                   builder: (_, message) {
//                     if (message.isEmpty) return const SizedBox.shrink();
//                     return Center(
//                       child: Container(
//                         padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
//                         decoration: BoxDecoration(color: Colors.black.withOpacity(0.6), borderRadius: BorderRadius.circular(8)),
//                         child: Text(message, style: const TextStyle(color: Colors.white, fontSize: 16)),
//                       ),
//                     );
//                   },
//                 ),
//               ),
//             ],
//           );
//         }

//         return const Center(child: Text("Something went wrong"));
//       },
//     );
//   }
// }
