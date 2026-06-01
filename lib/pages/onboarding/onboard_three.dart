import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:store/pages/onboarding/onboard_four.dart';
import 'package:store/theme/app_colors.dart';
import 'package:store/widgets/mybutton.dart';

class OnboardThree extends StatelessWidget {
  const OnboardThree({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              //page indicator
              Row(
                mainAxisAlignment: .center,
                children: [
                  Container(
                    height: 4,
                    width: 33,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  SizedBox(width: 4),
                  Container(
                    height: 4,
                    width: 33,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  SizedBox(width: 4),
                  Container(
                    height: 4,
                    width: 33,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ],
              ),
              Placeholder(fallbackHeight: 200, fallbackWidth: double.infinity),
              Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Add to stock",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 41,
                      fontWeight: FontWeight.bold,
                      color: AppColors.gray,
                    ),
                  ),
                  //const SizedBox(height: 8),
                  Text(
                    "in seconds.",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      height: 1.2,
                      fontSize: 41,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Flexible(
                    child: Text(
                      "Take a picture of the product and add to stock. Keep your shelves updated without the paperwork.",
                      textAlign: TextAlign.left,
                      softWrap: true,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  Center(
                    child: MyButton(
                      text: "Next",
                      onPressed: () {
                        Navigator.of(context).push(
                          CupertinoPageRoute(
                            builder: (context) => const OnboardFour(),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
