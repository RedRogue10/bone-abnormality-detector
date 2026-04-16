import 'dart:io';
import 'package:ultralytics_yolo/ultralytics_yolo.dart';
import 'package:ultralytics_yolo/widgets/yolo_controller.dart';

class ObjectDetector{
  late final YOLO yolo;
  final controller = YOLOViewController();
  static String classificationModelPath ="D:\Projects\bone_abnormality_detector\assets\models\mura_yolov8_categorical_model.pt";
  Future<void> initializeClassification() async {
    yolo = YOLO(modelPath:classificationModelPath, task:YOLOTask.classify);
    await yolo.loadModel();
  }

  Future <List<dynamic>> classifyBoneImage(File imageFile) async{
    await controller.switchModel(classificationModelPath,YOLOTask.classify);
    final imageBytes = await imageFile.readAsBytes();
    final results = await yolo.predict(imageBytes);
    return results['classifications'];
  }
}