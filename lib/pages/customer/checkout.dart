import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../models/products_model.dart';
import 'cart.dart';
import '../../providers/repositories.dart';
import '../../theme/app_colors.dart';
import '../../widgets/product_image.dart';

class _CheckoutConstants {
  static const double bottomRadius = 45;
  static const double previewHeightFactor = 0.80;
  static const double captureButtonSize = 84;
  static const double iconSize = 32;
  static const double appBarFontSize = 22;
  static const double cartButtonSize = 45;
  static const double cartIconSize = 28;
}

class _CameraControllerManager {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;
  CameraController? get controller => _controller;

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
    if (_controller!.value.isTakingPicture) {
      return null;
    }
    try {
      return await _controller!.takePicture();
    } catch (e) {
      debugPrint('Capture error: $e');
      return null;
    }
  }

  void handleLifecycleState(AppLifecycleState state) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return;
    }
    if (state == AppLifecycleState.inactive) {
      _controller?.dispose();
      _controller = null;
      _isInitialized = false;
    } else if (state == AppLifecycleState.resumed) {
      if (_cameras != null && _cameras!.isNotEmpty) {
        _initCamera(_cameras![0]);
      }
    }
  }
}

class _MaxValueFormatter extends TextInputFormatter {
  final int maxValue;

  _MaxValueFormatter(this.maxValue);

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }
    final int? value = int.tryParse(newValue.text);
    if (value != null && value > maxValue) {
      return TextEditingValue(
        text: maxValue.toString(),
        selection: TextSelection.collapsed(offset: maxValue.toString().length),
      );
    }
    return newValue;
  }
}

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen>
    with WidgetsBindingObserver {
  late _CameraControllerManager _cameraManager;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _cameraManager = _CameraControllerManager(
      onStateChanged: () {
        if (mounted) {
          setState(() {});
        }
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
      _showProductPicker(context);
    }
  }

  void _showProductPicker(BuildContext context) {
    final products = ref.read(productRepositoryProvider).products;
    final sourceContext = context;

    showModalBottomSheet(
      context: sourceContext,
      backgroundColor: AppColors.backgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            const SizedBox(height: 12),
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
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Row(
                children: [
                  Text(
                    'Select Product',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF2F2F2F),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${products.length} items',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: const Color(0xFF8E8E93),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.separated(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 18),
                itemCount: products.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final product = products[index];
                  return _ProductPickerItem(
                    product: product,
                    onTap: () {
                      Navigator.pop(ctx);
                      _showAddToCartSheet(sourceContext, product);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddToCartSheet(BuildContext context, StockItem product) {
    final quantityController = TextEditingController(text: '1');

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.backgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
      ),
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 10,
          bottom:
              MediaQuery.of(ctx).padding.bottom +
              MediaQuery.of(ctx).viewInsets.bottom +
              20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: ProductImage(product: product, width: 56, height: 56),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: AppColors.labelPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${product.quantity} in stock',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: const Color(0xFF8E8E93),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  width: 70,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFC7C7CC)),
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
                        _MaxValueFormatter(product.quantity),
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
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: quantityController,
              builder: (context, value, child) {
                final qty = int.tryParse(value.text.trim()) ?? 0;
                final isActive = qty > 0;

                return Semantics(
                  button: true,
                  label: 'Add item',
                  child: InkWell(
                    onTap: isActive
                        ? () {
                            final cappedQty = qty > product.quantity
                                ? product.quantity
                                : qty;
                            ref
                                .read(cartRepositoryProvider)
                                .addItem(product, cappedQty);
                            Navigator.pop(ctx);
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
                                      'Added $cappedQty x ${product.name} to cart',
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
                          'Add to Cart',
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
      ),
    ).whenComplete(() => quantityController.dispose());
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: Stack(
        children: [
          _CameraPreviewWidget(manager: _cameraManager),
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: _CustomAppBar(),
              ),
            ),
          ),
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

class _ProductPickerItem extends StatelessWidget {
  const _ProductPickerItem({required this.product, required this.onTap});

  final StockItem product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: ProductImage(
              product: product,
              width: 48,
              height: 48,
              iconSize: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF2F2F2F),
                  ),
                ),
                if (product.price != null)
                  Text(
                    '₵${product.price!.toStringAsFixed(2)}',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppColors.navigationActive,
                    ),
                  ),
              ],
            ),
          ),
          Text(
            '${product.quantity} in stock',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: const Color(0xFF8E8E93),
            ),
          ),
          const SizedBox(width: 8),
          Icon(Icons.chevron_right, color: Colors.grey[400]),
        ],
      ),
    ),
  );
}

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

class _CaptureButton extends StatelessWidget {
  const _CaptureButton({required this.isEnabled, required this.onPressed});

  final bool isEnabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: 'Take photo',
    enabled: isEnabled,
    child: InkWell(
      onTap: isEnabled ? onPressed : null,
      borderRadius: BorderRadius.circular(_CheckoutConstants.captureButtonSize),
      child: Container(
        height: _CheckoutConstants.captureButtonSize,
        width: _CheckoutConstants.captureButtonSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 4),
        ),
        child: Padding(
          padding: const EdgeInsets.all(4),
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

class _CustomAppBar extends StatelessWidget {
  const _CustomAppBar();

  @override
  Widget build(BuildContext context) => Row(
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
      const _CartButton(),
    ],
  );
}

class _CartButton extends ConsumerWidget {
  const _CartButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) => Padding(
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
            border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
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
