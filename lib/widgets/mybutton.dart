import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MyButton extends StatefulWidget {
  MyButton({
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
  double? width;
  double height;
  final Color color;
  Color textColor;
  double fontSize;
  FontWeight fontWeight;

  @override
  State<MyButton> createState() => _MyButtonState();
}

class _MyButtonState extends State<MyButton> {
  @override
  Widget build(BuildContext context) {
    final double buttonWidth =
        widget.width ?? MediaQuery.sizeOf(context).width * 0.9;

    return GestureDetector(
      onTap: widget.onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        width: buttonWidth,
        height: widget.height,
        decoration: BoxDecoration(
          color: widget.color,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Center(
          child: Text(
            widget.text,
            style: GoogleFonts.poppins(
              fontSize: widget.fontSize,
              color: widget.textColor,
              fontWeight: widget.fontWeight,
            ),
          ),
        ),
      ),
    );
  }
}
