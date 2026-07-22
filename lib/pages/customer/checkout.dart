import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:store/theme/app_colors.dart';
import 'package:store/pages/customer/cart.dart';

// ---------------------------------------------------------------------
// 1.  CONSTANTS – all dimensions and durations in one place
// ---------------------------------------------------------------------
class _CheckoutConstants {
  static const double bottomRadius = 45.0;
  static const double previewHeightFactor = 0.80;
  static const double captureButtonSize = 84.0;
  static const double iconSize = 32.0;
  static const double appBarFontSize = 22.0;
  static const double cartButtonSize = 45.0;
  static const double cartIconSize = 28.0;
}

// ---------------------------------------------------------------------
// 2.  CAMERA MANAGER – handles all camera logic, lifecycle, and state
// ---------------------------------------------------------------------
class _CameraControllerManager {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;
  CameraController? get controller => _controller;

  // Callback to notify the UI when initialization state changes
  final VoidCallback? onStateChanged;

  _CameraControllerManager({this.onStateChanged});

  Future<void> initialize() async {
    try {
      _cameras = await availableCameras();
      if (_cameras != null && _cameras!.isNotEmpty) {
        await _initCamera(_cameras![0]);
      }
    } catch (e) {
      debugPrint('Camera error: $e');
      _isInitialized = false;
      onStateChanged?.call();
    }
  }

  Future<void> _initCamera(CameraDescription description) async {
    final controller = CameraController(
      description,
      ResolutionPreset.high,
      enableAudio: false,
    );
    _controller = controller;
    try {
      await controller.initialize();
      _isInitialized = true;
      onStateChanged?.call();
    } catch (e) {
      debugPrint('Camera init error: $e');
      _isInitialized = false;
      onStateChanged?.call();
    }
  }

  Future<void> dispose() async {
    await _controller?.dispose();
    _controller = null;
    _isInitialized = false;
  }

  Future<XFile?> takePicture() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      return null;
    }
    if (_controller!.value.isTakingPicture) return null;
    try {
      return await _controller!.takePicture();
    } catch (e) {
      debugPrint('Capture error: $e');
      return null;
    }
  }

  // Lifecycle: pause when inactive, resume when active
  void handleLifecycleState(AppLifecycleState state) {
    if (_controller == null || !_controller!.value.isInitialized) return;
    if (state == AppLifecycleState.inactive) {
      _controller?.dispose();
      _controller = null;
      _isInitialized = false;
    } else if (state == AppLifecycleState.resumed) {
      // Re-initialize with the same description
      if (_cameras != null && _cameras!.isNotEmpty) {
        _initCamera(_cameras![0]);
      }
    }
  }
}

// ---------------------------------------------------------------------
// 3.  MAIN SCREEN – becomes a thin wrapper that composes child widgets
// ---------------------------------------------------------------------
class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen>
    with WidgetsBindingObserver {
  late _CameraControllerManager _cameraManager;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _cameraManager = _CameraControllerManager(
      onStateChanged: () {
        if (mounted) setState(() {});
      },
    );
    _cameraManager.initialize();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _cameraManager.handleLifecycleState(state);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraManager.dispose();
    super.dispose();
  }

  Future<void> _onCapturePressed() async {
    final file = await _cameraManager.takePicture();
    if (file != null && mounted) {
      _showCheckoutBottomSheet(context, file);
    }
  }

  Future<void> _showCheckoutBottomSheet(BuildContext context, XFile file) {
    final quantityController = TextEditingController(text: '1');
    return showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.backgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
      ),
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 10,
            bottom:
                MediaQuery.of(context).padding.bottom +
                MediaQuery.of(context).viewInsets.bottom +
                20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag Handle
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Content Row
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Product Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Lay’s Potato Chips",
                          style: GoogleFonts.poppins(
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                            color: AppColors.labelPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "80 in stock",
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: const Color(0xFF8E8E93),
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Quantity Input TextField
                  Container(
                    width: 70,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFC7C7CC),
                        width: 1,
                      ),
                    ),
                    child: Center(
                      child: TextField(
                        controller: quantityController,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppColors.labelPrimary,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                          hintText: '1',
                          hintStyle: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF8E8E93),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              // Add Button
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: quantityController,
                builder: (context, value, child) {
                  final qtyText = value.text.trim();
                  final qty = int.tryParse(qtyText) ?? 0;
                  final isActive = qty > 0;

                  return Semantics(
                    button: true,
                    label: 'Add item',
                    child: InkWell(
                      onTap: isActive
                          ? () {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  backgroundColor: AppColors.success,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  content: Row(
                                    children: [
                                      const Icon(
                                        Icons.check_circle,
                                        color: Colors.white,
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        "Added $qty x Lay’s Potato Chips to checkout",
                                        style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }
                          : null,
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        height: 56,
                        decoration: BoxDecoration(
                          color: isActive
                              ? AppColors.labelPrimary
                              : const Color(0xFFE5E5EA),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Center(
                          child: Text(
                            "Add",
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color: isActive
                                  ? Colors.white
                                  : const Color(0xFF8E8E93),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    ).whenComplete(() => quantityController.dispose());
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: AppColors.backgroundColor,
        body: Stack(
          children: [
            // Background camera preview (rounded bottom)
            _CameraPreviewWidget(manager: _cameraManager),
            // Top glass‑morphic app bar
            const Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: _CustomAppBar(),
                ),
              ),
            ),
            // Bottom capture button centered in the space under the camera view area
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height:
                  MediaQuery.of(context).size.height *
                  (1.0 - _CheckoutConstants.previewHeightFactor),
              child: Center(
                child: _CaptureButton(
                  isEnabled: _cameraManager.isInitialized,
                  onPressed: _onCapturePressed,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------
// 4.  CAMERA PREVIEW WIDGET – handles the actual preview rendering
// ---------------------------------------------------------------------
class _CameraPreviewWidget extends StatelessWidget {
  const _CameraPreviewWidget({required this.manager});

  final _CameraControllerManager manager;

  @override
  Widget build(BuildContext context) {
    final controller = manager.controller;
    final isInit = manager.isInitialized;

    return Container(
      width: double.infinity,
      height:
          MediaQuery.of(context).size.height *
          _CheckoutConstants.previewHeightFactor,
      decoration: const BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(_CheckoutConstants.bottomRadius),
          bottomRight: Radius.circular(_CheckoutConstants.bottomRadius),
        ),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(_CheckoutConstants.bottomRadius),
          bottomRight: Radius.circular(_CheckoutConstants.bottomRadius),
        ),
        child: RepaintBoundary(
          child: isInit && controller != null
              ? FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: controller.value.previewSize!.height,
                    height: controller.value.previewSize!.width,
                    child: CameraPreview(controller),
                  ),
                )
              : const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------
// 5.  CAPTURE BUTTON (shutter) – stateless, with semantics
// ---------------------------------------------------------------------
class _CaptureButton extends StatelessWidget {
  const _CaptureButton({required this.isEnabled, required this.onPressed});

  final bool isEnabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Take photo',
      enabled: isEnabled,
      child: InkWell(
        onTap: isEnabled ? onPressed : null,
        borderRadius: BorderRadius.circular(
          _CheckoutConstants.captureButtonSize,
        ),
        child: Container(
          height: _CheckoutConstants.captureButtonSize,
          width: _CheckoutConstants.captureButtonSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 4),
          ),
          child: Padding(
            padding: const EdgeInsets.all(4.0),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isEnabled
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.4),
              ),
              child: Center(
                child: Icon(
                  Icons.camera_alt,
                  color: isEnabled ? Colors.black : Colors.grey[700],
                  size: _CheckoutConstants.iconSize,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------
// 6.  CUSTOM APP BAR – glassmorphic effect with the cart icon
// ---------------------------------------------------------------------
class _CustomAppBar extends StatelessWidget {
  const _CustomAppBar();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Checkout',
          style: GoogleFonts.poppins(
            fontSize: _CheckoutConstants.appBarFontSize,
            fontWeight: FontWeight.w600,
            color: AppColors.labelPrimary,
          ),
        ),
        _CartButton(),
      ],
    );
  }
}

// ---------------------------------------------------------------------
// 7.  CART BUTTON – fully glass‑morphic, extracted for clarity
// ---------------------------------------------------------------------
class _CartButton extends StatelessWidget {
  const _CartButton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: Semantics(
        button: true,
        label: 'Open cart',
        child: InkWell(
          onTap: () {
            Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (context) => const CartPage()));
          },
          customBorder: const CircleBorder(),
          child: Container(
            height: _CheckoutConstants.cartButtonSize,
            width: _CheckoutConstants.cartButtonSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.white,
              border: Border.all(
                color: Colors.black.withValues(alpha: 0.08),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 12,
                  spreadRadius: -2,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Center(
              child: HugeIcon(
                icon: HugeIcons.strokeRoundedShoppingCartCheckOut02,
                size: _CheckoutConstants.cartIconSize,
                color: Colors.black.withValues(alpha: 0.80),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
