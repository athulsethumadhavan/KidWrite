import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

class MusicToggleButton extends StatelessWidget {
  final bool isEnabled;
  final VoidCallback onTap;

  const MusicToggleButton({
    super.key,
    required this.isEnabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: isEnabled
              ? AppColors.primary.withValues(alpha: 0.12)
              : Colors.grey.withValues(alpha: 0.12),
          shape: BoxShape.circle,
        ),
        child: Icon(
          isEnabled ? Icons.music_note_rounded : Icons.music_off_rounded,
          color: isEnabled ? AppColors.primary : AppColors.textLight,
          size: 26,
        ),
      ),
    );
  }
}
