import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/constants/app_colors.dart';
import 'package:kid_write/Core/data/letter_words.dart';
import '../../domain/entities/character.dart';

/// The reward a child sees the moment a letter is finished: the letter, a
/// picture, and the word — "A for Apple", "അ … അമ്മ".
///
/// Shows the emoji from [LetterWord] unless real artwork exists at
/// `assets/words/<id>.png`, in which case that is used instead. The check
/// runs once per card and falls back silently, so artwork can be added a
/// letter at a time with no code change.
class LetterRewardCard extends StatefulWidget {
  final Character character;
  final LetterWord entry;

  /// Font for the letter itself — Indic scripts need their own.
  final String? fontFamily;
  final Color accentColor;
  final VoidCallback onDismiss;

  const LetterRewardCard({
    super.key,
    required this.character,
    required this.entry,
    required this.accentColor,
    required this.onDismiss,
    this.fontFamily,
  });

  @override
  State<LetterRewardCard> createState() => _LetterRewardCardState();
}

class _LetterRewardCardState extends State<LetterRewardCard> {
  ImageProvider? _artwork;

  @override
  void initState() {
    super.initState();
    _loadArtwork();
  }

  Future<void> _loadArtwork() async {
    final path = LetterWords.assetFor(widget.character);
    try {
      await rootBundle.load(path);
      if (mounted) setState(() => _artwork = AssetImage(path));
    } catch (_) {
      // No artwork for this letter — the emoji stands in.
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final entry = widget.entry;

    return Positioned.fill(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onDismiss,
        child: ColoredBox(
          color: Colors.black.withValues(alpha: 0.35),
          child: Center(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 32),
              padding: const EdgeInsets.fromLTRB(28, 24, 28, 26),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: widget.accentColor.withValues(alpha: 0.35),
                    blurRadius: 30,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Picture
                  SizedBox(
                    height: 132,
                    child: _artwork != null
                        ? Image(image: _artwork!, fit: BoxFit.contain)
                        : FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              entry.emoji,
                              style: const TextStyle(fontSize: 96),
                            ),
                          ),
                  ),
                  const SizedBox(height: 14),

                  // Letter + word on one line: "A  —  Apple"
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        widget.character.symbol,
                        style: theme.textTheme.displaySmall?.copyWith(
                          fontFamily: widget.fontFamily,
                          color: widget.accentColor,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Flexible(
                        child: Text(
                          entry.word,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontFamily: widget.fontFamily,
                            color: AppColors.textDark,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Roman spelling, for scripts a parent may not read.
                  if (entry.roman != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      entry.roman!,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: AppColors.textLight,
                      ),
                    ),
                  ],
                ],
              ),
            )
                .animate()
                .fadeIn(duration: 220.ms)
                .scale(
                  begin: const Offset(0.7, 0.7),
                  end: const Offset(1, 1),
                  duration: 420.ms,
                  curve: Curves.easeOutBack,
                ),
          ),
        ),
      ),
    );
  }
}
