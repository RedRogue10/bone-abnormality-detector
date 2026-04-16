import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';

class CameraCapturePage extends StatefulWidget {
  const CameraCapturePage({super.key});

  @override
  State<CameraCapturePage> createState() => _CameraCapturePageState();
}

class _CameraCapturePageState extends State<CameraCapturePage> {
  static const Color darkNavy = Color(0xFF0B2545);
  static const Color white    = Colors.white;
  final ImagePicker picker = ImagePicker();
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  int _selectedCameraIndex = 0;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) return;
      await _startCamera(_selectedCameraIndex);
    } catch (e) {
      debugPrint('Camera init error: $e');
    }
  }

  Future<void> _startCamera(int index) async {
    final controller = CameraController(
      _cameras[index],
      ResolutionPreset.high,
      enableAudio: false,
    );
    await controller.initialize();
    if (!mounted) return;
    setState(() {
      _controller = controller;
      _isInitialized = true;
    });
  }

  Future<void> _flipCamera() async {
    if (_cameras.length < 2) return;
    _selectedCameraIndex = (_selectedCameraIndex + 1) % _cameras.length;
    await _controller?.dispose();
    setState(() => _isInitialized = false);
    await _startCamera(_selectedCameraIndex);
  }
  Future<File> pickImage() async{
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    return File(image!.path);
  }
  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: darkNavy,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: white),
          onPressed: () {},
        ),
        title: Text(
          'CAMERA',
          style: GoogleFonts.oswald(
            color: white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
            letterSpacing: 2,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle_outlined, color: white),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _isInitialized && _controller != null
                ? CameraPreview(_controller!)
                : const Center(
                    child: CircularProgressIndicator(color: white),
                  ),
          ),
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      color: Colors.black,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 40),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Gallery / last photo
          IconButton(
            icon: const Icon(Icons.pan_tool_outlined, color: white, size: 30),
            onPressed: () {},
          ),
          // Shutter button
          GestureDetector(
            onTap: () {},
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: white, width: 3.5),
              ),
              alignment: Alignment.center,
              child: Container(
                width: 58,
                height: 58,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: white,
                ),
              ),
            ),
          ),
          // Flip camera
          IconButton(
            icon: const Icon(Icons.flip_camera_ios_outlined, color: white, size: 30),
            onPressed: _flipCamera,
          ),
        ],
      ),
    );
  }
}
