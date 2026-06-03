import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:store/theme/app_colors.dart';

class CustomerNotificationPage extends StatelessWidget {
  const CustomerNotificationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  InkWell(
                    borderRadius: BorderRadius.circular(999),
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      height: 34,
                      width: 34,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFF2F2F2F)),
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 16,
                        color: Color(0xFF2F2F2F),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Notification',
                    style: GoogleFonts.poppins(
                      fontSize: 26,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF2F2F2F),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {},
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.navigationActive,
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'Read all',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.navigationActive,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const _DashedDivider(),
              const SizedBox(height: 18),
              _NotificationItem(
                title: 'Hurrah 🎉',
                message:
                    'Your items are already out of stock with the past few days. Congratulations on your product selling faster.',
              ),
              const SizedBox(height: 18),
              const _DashedDivider(),
              const SizedBox(height: 18),
              _NotificationItem(
                title: 'Low on stock ❗',
                message:
                    'Some of your fast selling products are low on stock please check and restock',
              ),
              const SizedBox(height: 18),
              const _DashedDivider(),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotificationItem extends StatelessWidget {
  const _NotificationItem({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF2F2F2F),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          message,
          style: GoogleFonts.poppins(
            fontSize: 13.5,
            height: 1.45,
            color: const Color(0xFF5E5E5E),
          ),
        ),
      ],
    );
  }
}

class _DashedDivider extends StatelessWidget {
  const _DashedDivider();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 1,
      width: double.infinity,
      child: CustomPaint(painter: _DashedDividerPainter()),
    );
  }
}

class _DashedDividerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFB9B9B9)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    const dashWidth = 6.0;
    const dashGap = 6.0;

    double startX = 0;
    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, size.height / 2),
        Offset((startX + dashWidth).clamp(0, size.width), size.height / 2),
        paint,
      );
      startX += dashWidth + dashGap;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
