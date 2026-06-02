import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:store/theme/app_colors.dart';
import 'package:store/widgets/mybutton.dart';
import 'package:store/pages/onboarding/account_type.dart';

class OnboardSlideData {
  final String titleLine1;
  final String titleLine2Gray;
  final String titleLine2Primary;
  final String description;

  const OnboardSlideData({
    required this.titleLine1,
    required this.titleLine2Gray,
    required this.titleLine2Primary,
    required this.description,
  });
}

class OnboardOne extends StatefulWidget {
  const OnboardOne({super.key});

  @override
  State<OnboardOne> createState() => _OnboardOneState();
}

class _OnboardOneState extends State<OnboardOne> {
  final PageController _pageController = PageController();
  double _pageOffset = 0.0;
  int _currentPage = 0;

  static const List<OnboardSlideData> _slides = [
    OnboardSlideData(
      titleLine1: "Your Store,",
      titleLine2Gray: "under",
      titleLine2Primary: " your control.",
      description:
          "Track your stock, monitor what's selling, and always know what needs attention. Simple as that.",
    ),
    OnboardSlideData(
      titleLine1: "Everything at",
      titleLine2Gray: "",
      titleLine2Primary: "a glance",
      description:
          "See your total stock, value, top sellers and alerts. All on one screen the moment you open the app.",
    ),
    OnboardSlideData(
      titleLine1: "Add to stock",
      titleLine2Gray: "",
      titleLine2Primary: "in seconds.",
      description:
          "Take a picture of the product and add to stock. Keep your shelves updated without the paperwork.",
    ),
    OnboardSlideData(
      titleLine1: "Sell fast,",
      titleLine2Gray: "",
      titleLine2Primary: "track everything",
      description:
          "Process sales quickly and watch your stock update automatically. Every sale is recorded so you never lose track.",
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController.addListener(() {
      if (_pageController.hasClients) {
        setState(() {
          _pageOffset = _pageController.page ?? 0.0;
          _currentPage = _pageOffset.round();
        });
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 30.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PageIndicator(count: _slides.length, pageOffset: _pageOffset),
              // Swipeable PageView
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _slides.length,
                  itemBuilder: (context, index) {
                    final slide = _slides[index];
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title Line 1
                        Text(
                          slide.titleLine1,
                          textAlign: TextAlign.left,
                          style: GoogleFonts.poppins(
                            fontSize: 41,
                            fontWeight: FontWeight.bold,
                            color: AppColors.gray,
                          ),
                        ),
                        // Title Line 2 using RichText to prevent horizontal overflows
                        RichText(
                          text: TextSpan(
                            style: GoogleFonts.poppins(
                              fontSize: 41,
                              fontWeight: FontWeight.bold,
                              height: 1.2,
                            ),
                            children: [
                              if (slide.titleLine2Gray.isNotEmpty)
                                TextSpan(
                                  text: slide.titleLine2Gray,
                                  style: const TextStyle(color: AppColors.gray),
                                ),
                              TextSpan(
                                text: slide.titleLine2Primary,
                                style: const TextStyle(
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Description
                        Flexible(
                          child: Text(
                            slide.description,
                            textAlign: TextAlign.left,
                            softWrap: true,
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
              // Premium Animated Page Indicator
              Center(
                child: MyButton(
                  text: _currentPage == _slides.length - 1
                      ? "Get Started"
                      : "Next",
                  color: AppColors.buttonPrimary,
                  width: MediaQuery.sizeOf(context).width * 0.9,
                  height: 62,
                  onPressed: () {
                    if (_currentPage < _slides.length - 1) {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeInOutCubic,
                      );
                    } else {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (context) => const AccountType(),
                        ),
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PageIndicator extends StatelessWidget {
  final int count;
  final double pageOffset;

  const PageIndicator({
    required this.count,
    required this.pageOffset,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        final difference = (index - pageOffset).abs();
        final double factor = (1.0 - difference).clamp(0.0, 1.0);

        final double width = 8.0 + (16.0 * factor); // 8.0 to 24.0
        final double opacity = 0.25 + (0.75 * factor); // 0.25 to 1.0

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 4.0),
          height: 8.0,
          width: width,
          decoration: BoxDecoration(
            color: Color.fromRGBO(51, 51, 51, opacity),
            borderRadius: BorderRadius.circular(999),
          ),
        );
      }),
    );
  }
}
