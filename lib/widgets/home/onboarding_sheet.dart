import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../services/localization_service.dart';

class OnboardingSheet extends StatefulWidget {
  final LocalizationService loc;

  const OnboardingSheet({super.key, required this.loc});

  static Future<void> show(BuildContext context, LocalizationService loc) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => OnboardingSheet(loc: loc),
    );
  }

  static Future<bool> shouldShow() async {
    const storage = FlutterSecureStorage();
    final seen = await storage.read(key: 'segurcel_has_seen_onboarding');
    return seen != 'true';
  }

  static Future<void> setSeen() async {
    const storage = FlutterSecureStorage();
    await storage.write(key: 'segurcel_has_seen_onboarding', value: 'true');
  }

  @override
  State<OnboardingSheet> createState() => _OnboardingSheetState();
}

class _OnboardingSheetState extends State<OnboardingSheet> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _finish() async {
    await OnboardingSheet.setSeen();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final slides = [
      {
        'icon': Icons.shield_outlined,
        'color': const Color(0xFF00F0FF),
        'title': widget.loc.text('onboarding_sub1'),
        'desc': widget.loc.text('onboarding_desc1'),
      },
      {
        'icon': Icons.phonelink_lock_outlined,
        'color': const Color(0xFF6C63FF),
        'title': widget.loc.text('onboarding_sub2'),
        'desc': widget.loc.text('onboarding_desc2'),
      },
      {
        'icon': Icons.vpn_key_outlined,
        'color': Colors.amberAccent,
        'title': widget.loc.text('onboarding_sub3'),
        'desc': widget.loc.text('onboarding_desc3'),
      },
    ];

    return Container(
      height: MediaQuery.of(context).size.height * 0.72,
      decoration: const BoxDecoration(
        color: Color(0xFF1E2538),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        children: [
          // Header Indicator & Skip Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.loc.text('onboarding_title'),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              TextButton(
                onPressed: _finish,
                child: Text(
                  widget.loc.text('onboarding_skip'),
                  style: const TextStyle(color: Colors.white54, fontSize: 14),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Carousel PageView
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (idx) => setState(() => _currentPage = idx),
              itemCount: slides.length,
              itemBuilder: (context, index) {
                final slide = slides[index];
                final Color iconColor = slide['color'] as Color;

                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: iconColor.withAlpha(30),
                        shape: BoxShape.circle,
                        border: Border.all(color: iconColor.withAlpha(120), width: 2),
                      ),
                      child: Icon(
                        slide['icon'] as IconData,
                        size: 48,
                        color: iconColor,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      slide['title'] as String,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        slide['desc'] as String,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          // Dots Indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              slides.length,
              (index) => AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: _currentPage == index ? 24 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _currentPage == index ? const Color(0xFF6C63FF) : Colors.white24,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Bottom Action Button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C63FF),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () {
                if (_currentPage < slides.length - 1) {
                  _pageController.nextPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                } else {
                  _finish();
                }
              },
              child: Text(
                _currentPage == slides.length - 1
                    ? widget.loc.text('onboarding_start')
                    : widget.loc.text('onboarding_next'),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
