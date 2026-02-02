import 'package:flutter/material.dart';
import 'package:proballdev/models/pet_mood.dart';

/// Pet mood indicator with icon + label. Color-coded by mood.
/// Dark mode ready.
class PetMoodIndicator extends StatelessWidget {
  const PetMoodIndicator({super.key, required this.mood});

  final PetMood mood;

  Color _moodColor() {
    switch (mood) {
      case PetMood.happy:
        return const Color(0xFF10B981); // Emerald
      case PetMood.excited:
        return const Color(0xFFF59E0B); // Amber
      case PetMood.calm:
        return const Color(0xFF3B82F6); // Blue
      case PetMood.lazy:
        return const Color(0xFF8B5CF6); // Violet
      case PetMood.aggressive:
        return const Color(0xFFEF4444); // Red
    }
  }

  IconData _moodIcon() {
    switch (mood) {
      case PetMood.happy:
        return Icons.sentiment_satisfied_alt_rounded;
      case PetMood.excited:
        return Icons.bolt_rounded;
      case PetMood.calm:
        return Icons.spa_rounded;
      case PetMood.lazy:
        return Icons.nightlight_round;
      case PetMood.aggressive:
        return Icons.flash_on_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final color = _moodColor();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.2 : 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withValues(alpha: isDark ? 0.4 : 0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: isDark ? 0.3 : 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: color.withValues(alpha: isDark ? 0.35 : 0.25),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              _moodIcon(),
              size: 28,
              color: color,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pet Mood',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  mood.displayName,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
