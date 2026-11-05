import 'package:flutter/material.dart';
import '../../services/localization_service.dart';
import '../../utils/secure_storage_helper.dart';

class OnboardingSheet extends StatefulWidget {
  final LocalizationService loc;

  const OnboardingSheet({super.key, required this.loc});

  static Future<void> show(BuildContext context, LocalizationService loc) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => OnboardingSheet(loc: loc),
    );
  }

  static Future<bool> shouldShow() async {
    final seen = await SecureStorageHelper.safeRead('segurcel_has_seen_onboarding');
    return seen != 'true';
  }

  static Future<void> setSeen() async {
    await SecureStorageHelper.safeWrite('segurcel_has_seen_onboarding', 'true');
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? const Color(0xFF1E2538) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF10141D);
    final textSubColor = isDark ? Colors.white70 : const Color(0xFF4A5568);

    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final bottomPadding = MediaQuery.of(context).viewPadding.bottom;

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
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.82,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: bottomPadding + bottomInset + 16,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle Bar
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header Row: Title & Skip Button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    widget.loc.text('onboarding_title'),
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                TextButton(
                  onPressed: _finish,
                  child: Text(
                    widget.loc.text('onboarding_skip'),
                    style: TextStyle(
                      color: isDark ? Colors.white54 : Colors.black54,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Carousel PageView
            Flexible(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (idx) => setState(() => _currentPage = idx),
                itemCount: slides.length,
                itemBuilder: (context, index) {
                  final slide = slides[index];
                  final Color iconColor = slide['color'] as Color;

                  return SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 12),
                        Container(
                          width: 88,
                          height: 88,
                          decoration: BoxDecoration(
                            color: iconColor.withAlpha(30),
                            shape: BoxShape.circle,
                            border: Border.all(color: iconColor.withAlpha(120), width: 2),
                          ),
                          child: Icon(
                            slide['icon'] as IconData,
                            size: 42,
                            color: iconColor,
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          slide['title'] as String,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: textColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            slide['desc'] as String,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: textSubColor,
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 12),

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
                    color: _currentPage == index ? const Color(0xFF6C63FF) : (isDark ? Colors.white24 : Colors.black12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Bottom Action Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C63FF),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
