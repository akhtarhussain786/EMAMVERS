import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/constants.dart';

/// Educational Lottie Animation widget with graceful animated fallback
class EduLottie extends StatelessWidget {
  final String? url;
  final double size;
  final IconData fallbackIcon;
  final String? fallbackLabel;
  final Color? color;
  final bool repeat;

  const EduLottie({
    super.key,
    this.url,
    this.size = 120,
    this.fallbackIcon = Icons.school_rounded,
    this.fallbackLabel,
    this.color,
    this.repeat = true,
  });

  /// Preset: Study notes & book opening
  factory EduLottie.study({double size = 120}) {
    return EduLottie(
      url: 'https://assets10.lottiefiles.com/packages/lf20_1a8dx7zj.json',
      size: size,
      fallbackIcon: Icons.menu_book_rounded,
      fallbackLabel: 'Study Materials',
      color: AppConstants.accentBlue,
    );
  }

  /// Preset: Empty search / notes
  factory EduLottie.emptySearch({double size = 130}) {
    return EduLottie(
      url: 'https://assets9.lottiefiles.com/packages/lf20_m6cu935s.json',
      size: size,
      fallbackIcon: Icons.search_off_rounded,
      fallbackLabel: 'No Notes Found',
      color: AppConstants.accentCyan,
    );
  }

  /// Preset: Success / Purchase Complete
  factory EduLottie.celebration({double size = 120}) {
    return EduLottie(
      url: 'https://assets4.lottiefiles.com/packages/lf20_jbrw3hcz.json',
      size: size,
      fallbackIcon: Icons.verified_rounded,
      fallbackLabel: 'Success!',
      color: AppConstants.accentEmerald,
      repeat: false,
    );
  }

  /// Preset: Mentor / Teacher
  factory EduLottie.teacher({double size = 120}) {
    return EduLottie(
      url: 'https://assets8.lottiefiles.com/packages/lf20_qp1q7mct.json',
      size: size,
      fallbackIcon: Icons.psychology_rounded,
      fallbackLabel: 'Verified Educators',
      color: AppConstants.accentPurple,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (url == null || url!.isEmpty) {
      return _buildFallback();
    }

    return SizedBox(
      width: size,
      height: size,
      child: Lottie.network(
        url!,
        repeat: repeat,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => _buildFallback(),
        frameBuilder: (context, child, composition) {
          if (composition == null) {
            return Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: color ?? AppConstants.accentCyan,
                ),
              ),
            );
          }
          return child;
        },
      ),
    );
  }

  Widget _buildFallback() {
    final themeColor = color ?? AppConstants.accentCyan;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(size * 0.18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  themeColor.withValues(alpha: 0.15),
                  themeColor.withValues(alpha: 0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              border: Border.all(
                color: themeColor.withValues(alpha: 0.25),
                width: 1.5,
              ),
            ),
            child: Icon(
              fallbackIcon,
              size: size * 0.45,
              color: themeColor,
            ),
          )
              .animate(onPlay: (controller) => controller.repeat(reverse: true))
              .scale(
                duration: 1200.ms,
                begin: const Offset(0.95, 0.95),
                end: const Offset(1.05, 1.05),
                curve: Curves.easeInOut,
              ),
          if (fallbackLabel != null) ...[
            const SizedBox(height: 8),
            Text(
              fallbackLabel!,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: themeColor,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
