import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'scan_analysis_page.dart';

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
  File? _capturedImage;

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

  Future<void> _pickFromGallery() async {
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;
    setState(() => _capturedImage = File(image.path));
  }

  Future<void> _capturePhoto() async {
    if (_controller == null || !_isInitialized) return;
    try {
      final XFile photo = await _controller!.takePicture();
      setState(() => _capturedImage = File(photo.path));
    } catch (e) {
      debugPrint('Capture error: $e');
    }
  }

  void _retake() {
    setState(() => _capturedImage = null);
  }

  void _confirmImage() {
    if (_capturedImage == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ScanAnalysisPage(imageFile: _capturedImage!),
      ),
    );
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
            child: _capturedImage != null
                ? Image.file(_capturedImage!, fit: BoxFit.contain)
                : _isInitialized && _controller != null
                    ? CameraPreview(_controller!)
                    : const Center(
                        child: CircularProgressIndicator(color: white),
                      ),
          ),
          _capturedImage != null ? _buildConfirmBar() : _buildCameraBar(),
        ],
      ),
    );
  }

  Widget _buildCameraBar() {
    return Container(
      color: Colors.black,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 40),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.photo_library_outlined, color: white, size: 30),
            onPressed: _pickFromGallery,
          ),
          GestureDetector(
            onTap: _capturePhoto,
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
          IconButton(
            icon: const Icon(Icons.flip_camera_ios_outlined, color: white, size: 30),
            onPressed: _flipCamera,
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmBar() {
    return Container(
      color: Colors.black,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 40),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Retake
          GestureDetector(
            onTap: _retake,
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: white, width: 2.5),
              ),
              child: const Icon(Icons.close, color: white, size: 30),
            ),
          ),
          // Confirm
          GestureDetector(
            onTap: _confirmImage,
            child: Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: white,
              ),
              child: const Icon(Icons.check, color: Colors.black, size: 34),
            ),
          ),
        ],
      ),
    );
  }
}
