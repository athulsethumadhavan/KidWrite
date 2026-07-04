import 'package:flutter/material.dart';
import 'package:kid_write/Core/Constants/app_constants.dart';

import '../../core/constants/app_colors.dart';
import '../../domain/entities/character.dart';

class CharacterGridCard extends StatelessWidget {
  final Character character;
  final bool isMastered;
  final Color accentColor;
  final String languageId;
  final VoidCallback onTap;

  const CharacterGridCard({
    super.key,
    required this.character,
    required this.isMastered,
    required this.accentColor,
    required this.languageId,
    required this.onTap,
  });

  String? _fontFamily() {
    const map = {
      'malayalam': 'NotoSansMalayalam',
      'hindi': 'NotoSansDevanagari',
      'tamil': 'NotoSansTamil',
      // School-style print letterforms for beginners (single-story a, g).
      'english': 'Andika',
      'numbers': 'Andika',
    };
    return map[languageId];
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isMastered
              ? AppColors.successColor.withValues(alpha: 0.12)
              : AppColors.cardBg,
          borderRadius:
          BorderRadius.circular(AppConstants.cardBorderRadius),
          border: Border.all(
            color: isMastered
                ? AppColors.successColor
                : accentColor.withValues(alpha: 0.25),
            width: isMastered ? 2 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: accentColor.withValues(alpha: 0.10),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            Center(
              child: Text(
                character.symbol,
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.w900,
                  color: accentColor,
                  fontFamily: _fontFamily(),
                ),
              ),
            ),
            if (isMastered)
              const Positioned(
                top: 6,
                right: 6,
                child: Icon(
                  Icons.star_rounded,
                  color: AppColors.successColor,
                  size: 18,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
