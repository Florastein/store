import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MyButton extends StatelessWidget {
  const MyButton({
    super.key,
    required this.onPressed,
    required this.text,
    this.width,
    this.height = 62,
    required this.color,
    this.textColor = Colors.white,
    this.fontSize = 17,
    this.fontWeight = FontWeight.normal,
  });

  final VoidCallback onPressed;
  final String text;
  final double? width;
  final double height;
  final Color color;
  final Color textColor;
  final double fontSize;
  final FontWeight fontWeight;

  @override
  Widget build(BuildContext context) {
    final double buttonWidth =
        width ?? MediaQuery.sizeOf(context).width * 0.9;

    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        width: buttonWidth,
        height: height,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Center(
          child: Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: fontSize,
              color: textColor,
              fontWeight: fontWeight,
            ),
          ),
        ),
      ),
    );
  }
}
