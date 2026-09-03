import 'package:flutter/material.dart';
import '../core/constants.dart';

/// 1. EXAMVERSE CARD
class ExamVerseCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final Color? backgroundColor;
  final Border? border;
  final LinearGradient? gradient;
  final VoidCallback? onTap;

  const ExamVerseCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppConstants.space16),
    this.margin,
    this.borderRadius = AppConstants.radiusCard,
    this.backgroundColor,
    this.border,
    this.gradient,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Widget cardContent = Container(
      padding: padding,
      margin: margin,
      decoration: BoxDecoration(
        color: gradient == null ? (backgroundColor ?? AppConstants.cardDark) : null,
        gradient: gradient,
        borderRadius: BorderRadius.circular(borderRadius),
        border: border ?? Border.all(color: AppConstants.cardBorder),
        boxShadow: AppConstants.cardShadow,
      ),
      child: child,
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(borderRadius),
        child: cardContent,
      );
    }
    return cardContent;
  }
}

/// 2. PRIMARY & SECONDARY BUTTONS
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final double height;
  final LinearGradient? gradient;

  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.height = 50.0,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: height,
      decoration: BoxDecoration(
        gradient: onPressed == null ? null : (gradient ?? AppConstants.primaryGradient),
        borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
        boxShadow: onPressed == null ? [] : AppConstants.glowShadow(AppConstants.accentCyan),
      ),
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.radiusMedium)),
        ),
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(color: AppConstants.textPrimary, strokeWidth: 2.5),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, color: AppConstants.textPrimary, size: 18),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    label,
                    style: const TextStyle(
                      color: AppConstants.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class SecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color color;

  const SecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.color = AppConstants.accentCyan,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color.withValues(alpha: 0.6), width: 1.2),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.radiusMedium)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
          ],
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }
}

/// 3. CUSTOM TEXT FIELD
class CustomTextField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final IconData prefixIcon;
  final bool isPassword;
  final TextInputType keyboardType;
  final String? errorText;

  const CustomTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    required this.prefixIcon,
    this.isPassword = false,
    this.keyboardType = TextInputType.text,
    this.errorText,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: const TextStyle(color: AppConstants.textSecondary, fontSize: 12.5, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: widget.controller,
          obscureText: widget.isPassword ? _obscureText : false,
          keyboardType: widget.keyboardType,
          style: const TextStyle(color: AppConstants.textPrimary, fontSize: 14.5),
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: const TextStyle(color: AppConstants.textMuted, fontSize: 13.5),
            prefixIcon: Icon(widget.prefixIcon, color: AppConstants.accentCyan, size: 20),
            suffixIcon: widget.isPassword
                ? IconButton(
                    icon: Icon(
                      _obscureText ? Icons.visibility_off : Icons.visibility,
                      color: AppConstants.textMuted,
                      size: 20,
                    ),
                    onPressed: () => setState(() => _obscureText = !_obscureText),
                  )
                : null,
            filled: true,
            fillColor: AppConstants.surfaceElevated,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
              borderSide: const BorderSide(color: AppConstants.cardBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
              borderSide: const BorderSide(color: AppConstants.cardBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
              borderSide: const BorderSide(color: AppConstants.accentCyan, width: 1.5),
            ),
            errorText: widget.errorText,
          ),
        ),
      ],
    );
  }
}

/// 4. STAT CARD
class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String? trend;
  final IconData icon;
  final Color color;

  const StatCard({
    super.key,
    required this.label,
    required this.value,
    this.trend,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ExamVerseCard(
      padding: const EdgeInsets.all(AppConstants.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              if (trend != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppConstants.accentEmerald.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    trend!,
                    style: const TextStyle(color: AppConstants.accentEmerald, fontSize: 10.5, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppConstants.space12),
          Text(
            value,
            style: const TextStyle(color: AppConstants.textPrimary, fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(color: AppConstants.textSecondary, fontSize: 11.5),
          ),
        ],
      ),
    );
  }
}

/// 5. LARGE RANK CARD
class RankCard extends StatelessWidget {
  final int rank;
  final double percentile;
  final String rankImprovementText;
  final int bestRank;
  final VoidCallback? onTapViewDetails;

  const RankCard({
    super.key,
    required this.rank,
    this.percentile = 96.8,
    this.rankImprovementText = '↑ 18 positions this week',
    this.bestRank = 89,
    this.onTapViewDetails,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppConstants.space20),
      decoration: BoxDecoration(
        gradient: AppConstants.aiGradient,
        borderRadius: BorderRadius.circular(AppConstants.radiusHero),
        boxShadow: AppConstants.glowShadow(AppConstants.accentPurple),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'YOUR EXAMVERSE RANK',
                style: TextStyle(color: AppConstants.onAccent, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.8),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.28), borderRadius: BorderRadius.circular(10)),
                child: Text('Top ${(100 - percentile).toStringAsFixed(1)}%', style: const TextStyle(color: AppConstants.onAccent, fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.space16),
          Text('#$rank', style: const TextStyle(color: AppConstants.onAccent, fontSize: 44, fontWeight: FontWeight.w800, height: 1.0)),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.arrow_upward, color: AppConstants.accentEmerald, size: 14),
              const SizedBox(width: 4),
              Text(rankImprovementText, style: const TextStyle(color: AppConstants.onAccent, fontSize: 12.5, fontWeight: FontWeight.bold)),
              const SizedBox(width: 12),
              Text('• Best Rank: #$bestRank', style: const TextStyle(color: AppConstants.onAccent, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}

/// 6. SECTION HEADER
class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onActionTap;

  const SectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onActionTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(color: AppConstants.textPrimary, fontSize: 17, fontWeight: FontWeight.bold),
        ),
        if (actionLabel != null && onActionTap != null)
          TextButton(
            onPressed: onActionTap,
            child: Text(
              actionLabel!,
              style: const TextStyle(color: AppConstants.accentCyan, fontSize: 13, fontWeight: FontWeight.w700),
            ),
          ),
      ],
    );
  }
}

/// 7. EMPTY STATE WIDGET
class EmptyStateWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String? buttonLabel;
  final VoidCallback? onButtonPressed;

  const EmptyStateWidget({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.buttonLabel,
    this.onButtonPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppConstants.space32),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: AppConstants.cardDark, shape: BoxShape.circle, border: Border.all(color: AppConstants.cardBorder)),
              child: Icon(icon, size: 40, color: AppConstants.textMuted),
            ),
            const SizedBox(height: AppConstants.space16),
            Text(title, style: const TextStyle(color: AppConstants.textPrimary, fontSize: 17, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(description, textAlign: TextAlign.center, style: const TextStyle(color: AppConstants.textSecondary, fontSize: 13, height: 1.4)),
            if (buttonLabel != null && onButtonPressed != null) ...[
              const SizedBox(height: AppConstants.space20),
              SecondaryButton(label: buttonLabel!, onPressed: onButtonPressed!),
            ],
          ],
        ),
      ),
    );
  }
}
