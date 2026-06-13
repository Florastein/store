import 'dart:ui';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:store/theme/app_colors.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
  }

  // Find available cameras and spin up the rear camera
  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras != null && _cameras!.isNotEmpty) {
        // Index 0 is typically the primary rear camera
        _onNewCameraSelected(_cameras![0]);
      }
    } catch (e) {
      debugPrint('Error finding cameras: $e');
    }
  }

  Future<void> _onNewCameraSelected(CameraDescription cameraDescription) async {
    final CameraController cameraController = CameraController(
      cameraDescription,
      ResolutionPreset.high,
      enableAudio: false, // Set to false if you only need photos
    );

    _controller = cameraController;

    try {
      await cameraController.initialize();
      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });
      }
    } catch (e) {
      debugPrint('Error initializing camera: $e');
    }
  }

  // Handle application lifecycle to pause/resume camera feed gracefully
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = _controller;

    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _onNewCameraSelected(cameraController.description);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  // Execute image capture action
  Future<void> _takePicture() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      return;
    }

    if (_controller!.value.isTakingPicture) {
      return; // A capture process is already running
    }

    try {
      final XFile file = await _controller!.takePicture();

      // Successfully captured! The file path is file.path
      debugPrint('Picture saved to: ${file.path}');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Image captured! Location: ${file.path}')),
        );
      }
    } catch (e) {
      debugPrint('Error capturing photo: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: Stack(
        children: [
          // 1. Background Layer: Fullscreen Camera Stream
          // 1. Background Layer: Fullscreen Camera Stream with Rounded Bottom
          Container(
            decoration: const BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(45),
                bottomRight: Radius.circular(45),
              ),
            ),
            width: double.infinity,
            height: MediaQuery.of(context).size.height * 0.85,
            child: _buildCameraPreview(),
          ),

          // 2. Top Layer: Glassmorphic Custom App Bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                child: _customAppBar(),
              ),
            ),
          ),

          // 3. Bottom Layer: Capture Shutter Button
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(child: _buildCaptureButton()),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraPreview() {
    if (!_isCameraInitialized || _controller == null) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    // Clip the video stream to match the outer container's bottom border radius
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(45),
        bottomRight: Radius.circular(45),
      ),
      child: SizedBox.expand(
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: _controller!.value.previewSize!.height,
            height: _controller!.value.previewSize!.width,
            child: CameraPreview(_controller!),
          ),
        ),
      ),
    );
  }

  Widget _buildCaptureButton() {
    return InkWell(
      onTap: _isCameraInitialized ? _takePicture : null,
      child: Container(
        height: 84,
        width: 84,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 4),
        ),
        child: Padding(
          padding: const EdgeInsets.all(4.0),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _isCameraInitialized
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.4),
            ),
          ),
        ),
      ),
    );
  }

  Widget _customAppBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Checkout',
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 8),
          child: ClipOval(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: InkWell(
                onTap: () {
                  // Handle cart tap
                },
                customBorder: const CircleBorder(),
                child: Container(
                  height: 36,
                  width: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      center: const Alignment(-0.45, -0.55),
                      radius: 1.18,
                      colors: [
                        Colors.white.withValues(alpha: 0.78),
                        Colors.white.withValues(alpha: 0.32),
                        Colors.white.withValues(alpha: 0.10),
                      ],
                      stops: const [0.0, 0.46, 1.0],
                    ),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.72),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.20),
                        blurRadius: 20,
                        spreadRadius: -2,
                        offset: const Offset(0, 10),
                      ),
                      BoxShadow(
                        color: Colors.white.withValues(alpha: 0.42),
                        blurRadius: 8,
                        spreadRadius: -3,
                        offset: const Offset(-4, -4),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: SweepGradient(
                              startAngle: -0.7,
                              endAngle: 5.7,
                              colors: [
                                Colors.white.withValues(alpha: 0.00),
                                Colors.white.withValues(alpha: 0.34),
                                Colors.white.withValues(alpha: 0.02),
                                Colors.black.withValues(alpha: 0.07),
                                Colors.white.withValues(alpha: 0.00),
                              ],
                              stops: const [0.0, 0.20, 0.48, 0.74, 1.0],
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 5,
                        left: 7,
                        child: Container(
                          height: 12,
                          width: 18,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(999),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.white.withValues(alpha: 0.82),
                                Colors.white.withValues(alpha: 0.18),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        right: 5,
                        bottom: 6,
                        child: Container(
                          height: 12,
                          width: 5,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(999),
                            color: Colors.white.withValues(alpha: 0.18),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 8,
                        right: 8,
                        bottom: 3,
                        child: Container(
                          height: 4,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(999),
                            color: Colors.black.withValues(alpha: 0.08),
                          ),
                        ),
                      ),
                      Center(
                        child: HugeIcon(
                          icon: HugeIcons.strokeRoundedShoppingCartCheckOut02,
                          size: 15,
                          color: Colors.black.withValues(alpha: 0.80),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
