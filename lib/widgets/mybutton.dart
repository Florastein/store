import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:store/theme/app_colors.dart';

class MyButton extends StatefulWidget {
  const MyButton({super.key, required this.onPressed, required this.text});

  final VoidCallback onPressed;
  final String text;

  @override
  State<MyButton> createState() => _MyButtonState();
}

class _MyButtonState extends State<MyButton> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onPressed,
      child: Container(
        width: MediaQuery.sizeOf(context).width * 0.95,
        height: 64,
        decoration: BoxDecoration(
          color: AppColors.buttonPrimary,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Center(
          child: Text(
            widget.text,
            style: GoogleFonts.poppins(fontSize: 17, color: Colors.white),
          ),
        ),
      ),
    );
  }
}
