import 'dart:async';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:kid_write/Core/Constants/app_constants.dart';
import 'package:kid_write/Core/services/letter_audio_service.dart';
import 'package:kid_write/Core/services/tts_service.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/responsive_helper.dart';
import '../../core/widgets/animated_background.dart';
import '../../domain/entities/character.dart';
import '../../injection_container.dart';
import '../blocs/music/music_bloc.dart';
import '../blocs/progress/progress_bloc.dart';
import '../blocs/writing/writing_bloc.dart';
import '../widgets/drawing_canvas.dart';
import '../widgets/music_toggle_button.dart';

class WritingPracticePage extends StatefulWidget {
  final String languageId;
  final Character character;

  const WritingPracticePage({
    super.key,
    required this.languageId,
    required this.character,
  });

  @override
  State<WritingPracticePage> createState() => _WritingPracticePageState();
}

class _WritingPracticePageState extends State<WritingPracticePage> {
  late final ConfettiController _confetti;
  late final WritingBloc _writingBloc;
  late final ProgressBloc _progressBloc;

  // Star-reward animation state.
  final GlobalKey _stackKey = GlobalKey();
  final List<GlobalKey> _starKeys = [GlobalKey(), GlobalKey(), GlobalKey()];
  bool _showFlyStar = false;
  int? _flyTargetIndex;
  Offset _flyFrom = Offset.zero;
  Offset _flyTo = Offset.zero;
  Timer? _redrawTimer;

  @override
  void initState() {
    super.initState();
    _confetti = ConfettiController(
        duration: AppConstants.celebrationDuration);
    _writingBloc = sl<WritingBloc>()
      ..add(WritingLoadCharacter(widget.character));
    _progressBloc = sl<ProgressBloc>()
      ..add(ProgressLoad(widget.languageId));

    // Say the letter aloud when the page opens.
    Timer(const Duration(milliseconds: 600), () {
      if (mounted) sl<LetterAudioService>().playLetter(widget.character);
    });
  }

  @override
  void dispose() {
    _redrawTimer?.cancel();
    _confetti.dispose();
    _writingBloc.close();
    _progressBloc.close();
    super.dispose();
  }

  /// Big star pops at the canvas, then flies up into star slot [index].
  void _launchStarFly(int index) {
    final stackBox =
    _stackKey.currentContext?.findRenderObject() as RenderBox?;
    if (stackBox == null) return;
    final size = stackBox.size;
    final slotBox =
    _starKeys[index].currentContext?.findRenderObject() as RenderBox?;
    final to = slotBox != null
        ? stackBox.globalToLocal(
        slotBox.localToGlobal(slotBox.size.center(Offset.zero)))
        : Offset(size.width / 2, 60);
    setState(() {
      _flyFrom = Offset(size.width / 2, size.height * 0.55);
      _flyTo = to;
      _flyTargetIndex = index;
      _showFlyStar = true;
    });
  }

  Color get _langColor =>
      AppColors.languageColors[widget.languageId] ?? AppColors.primary;

  @override
  Widget build(BuildContext context) {
    final isTablet = ResponsiveHelper.isTablet(context);

    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _writingBloc),
        BlocProvider.value(value: _progressBloc),
      ],
      child: BlocListener<WritingBloc, WritingState>(
        listener: _handleWritingStateChange,
        child: Scaffold(
          body: AnimatedBackground(
            primaryColor: _langColor,
            child: SafeArea(
              child: Stack(
                key: _stackKey,
                children: [
                  isTablet
                      ? _TabletLayout(
                    character: widget.character,
                    languageId: widget.languageId,
                    langColor: _langColor,
                    starKeys: _starKeys,
                    hiddenStar: _showFlyStar ? _flyTargetIndex : null,
                  )
                      : _PhoneLayout(
                    character: widget.character,
                    languageId: widget.languageId,
                    langColor: _langColor,
                    starKeys: _starKeys,
                    hiddenStar: _showFlyStar ? _flyTargetIndex : null,
                  ),

                  // Big star flying up into the star row.
                  if (_showFlyStar)
                    _FlyingStar(
                      from: _flyFrom,
                      to: _flyTo,
                      onDone: () {
                        if (mounted) {
                          setState(() => _showFlyStar = false);
                        }
                      },
                    ),

                  // Confetti
                  Align(
                    alignment: Alignment.topCenter,
                    child: ConfettiWidget(
                      confettiController: _confetti,
                      blastDirectionality:
                      BlastDirectionality.explosive,
                      numberOfParticles: 30,
                      colors: const [
                        AppColors.primary,
                        AppColors.secondary,
                        AppColors.accent,
                        AppColors.purple,
                        AppColors.green,
                      ],
                      shouldLoop: false,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _handleWritingStateChange(BuildContext context, WritingState state) {
    if (state.status == WritingStatus.success) {
      // Stars earned so far (before this success).
      final ps = _progressBloc.state;
      final prior = ps is ProgressLoaded
          ? (ps.progressMap[widget.character.id]?.successCount ?? 0)
          : 0;

      _progressBloc.add(ProgressRecord(
        characterId: widget.character.id,
        languageId: widget.languageId,
        success: true,
        accuracy: state.accuracy,
      ));

      _launchStarFly(prior.clamp(0, 2).toInt());

      if (prior + 1 >= 3) {
        // Third star (or replay of a completed letter): full celebration.
        _confetti.play();
        sl<MusicBloc>().add(const MusicPlaySuccess());
        Future.delayed(const Duration(milliseconds: 1200), () {
          if (!mounted) return;
          sl<LetterAudioService>().playLetter(widget.character);
        });
      } else {
        // Star 1 or 2: pop sound, then reset the canvas for another go.
        sl<MusicBloc>().add(const MusicPlayTap());
        _redrawTimer?.cancel();
        _redrawTimer = Timer(const Duration(milliseconds: 1700), () {
          if (mounted) _writingBloc.add(const WritingClear());
        });
      }
    } else if (state.status == WritingStatus.failure) {
      _progressBloc.add(ProgressRecord(
        characterId: widget.character.id,
        languageId: widget.languageId,
        success: false,
        accuracy: state.accuracy,
      ));
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Phone layout — vertical
// ─────────────────────────────────────────────────────────────────────────────

class _PhoneLayout extends StatelessWidget {
  final Character character;
  final String languageId;
  final Color langColor;
  final List<GlobalKey> starKeys;
  final int? hiddenStar;

  const _PhoneLayout({
    required this.character,
    required this.languageId,
    required this.langColor,
    required this.starKeys,
    required this.hiddenStar,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _TopBar(character: character, languageId: languageId),
        const SizedBox(height: 8),
        _CharacterInfo(
            character: character,
            langColor: langColor,
            starKeys: starKeys,
            hiddenStar: hiddenStar),
        const SizedBox(height: 16),
        Expanded(
          child: Center(
            child: _CanvasSection(
                character: character, langColor: langColor),
          ),
        ),
        _BottomControls(langColor: langColor, character: character),
        const SizedBox(height: 16),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tablet layout — side by side
// ─────────────────────────────────────────────────────────────────────────────

class _TabletLayout extends StatelessWidget {
  final Character character;
  final String languageId;
  final Color langColor;
  final List<GlobalKey> starKeys;
  final int? hiddenStar;

  const _TabletLayout({
    required this.character,
    required this.languageId,
    required this.langColor,
    required this.starKeys,
    required this.hiddenStar,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _TopBar(character: character, languageId: languageId),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Left: info panel
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _CharacterInfo(
                          character: character,
                          langColor: langColor,
                          starKeys: starKeys,
                          hiddenStar: hiddenStar),
                      const SizedBox(height: 32),
                      _BottomControls(langColor: langColor, character: character),
                    ],
                  ),
                ),
              ),
              // Right: canvas
              Expanded(
                flex: 3,
                child: Center(
                  child: _CanvasSection(
                      character: character, langColor: langColor),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  final Character character;
  final String languageId;
  const _TopBar({required this.character, required this.languageId});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            color: AppColors.textDark,
          ),
          Expanded(
            child: Text(
              'Trace & Write',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          BlocBuilder<MusicBloc, MusicState>(
            bloc: sl<MusicBloc>(),
            builder: (_, s) => MusicToggleButton(
              isEnabled: s.isMusicEnabled,
              onTap: () => sl<MusicBloc>().add(const MusicToggle()),
            ),
          ),
        ],
      ),
    );
  }
}

class _CharacterInfo extends StatelessWidget {
  final Character character;
  final Color langColor;
  final List<GlobalKey> starKeys;
  final int? hiddenStar; // slot kept unfilled while its star is flying in
  const _CharacterInfo({
    required this.character,
    required this.langColor,
    required this.starKeys,
    required this.hiddenStar,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: langColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Column(
                children: [
                  Text(
                    character.name,
                    style: theme.textTheme.titleLarge,
                  ),
                  Text(
                    '"${character.pronunciation}"',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: langColor,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              // Speaker — says the letter sound aloud.
              GestureDetector(
                onTap: () =>
                    sl<LetterAudioService>().playLetter(character),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: langColor.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.volume_up_rounded,
                    color: langColor,
                    size: 26,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        // Earned stars for this letter (fills as the kid succeeds).
        BlocBuilder<ProgressBloc, ProgressState>(
          builder: (_, ps) {
            final stars = ps is ProgressLoaded
                ? (ps.progressMap[character.id]?.successCount ?? 0)
                .clamp(0, 3)
                : 0;
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (int i = 0; i < 3; i++)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Icon(
                      Icons.star_rounded,
                      key: starKeys[i],
                      size: i == 1 ? 34 : 28,
                      color: i < stars && i != hiddenStar
                          ? const Color(0xFFFFB300)
                          : Colors.black.withValues(alpha: 0.22),
                    ),
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: 8),
        BlocBuilder<WritingBloc, WritingState>(
          builder: (_, state) => _StatusBadge(state: state, langColor: langColor),
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final WritingState state;
  final Color langColor;
  const _StatusBadge({required this.state, required this.langColor});

  @override
  Widget build(BuildContext context) {
    if (state.status == WritingStatus.success) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.successColor,
          borderRadius: BorderRadius.circular(50),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.star_rounded, color: Colors.white, size: 20),
            SizedBox(width: 6),
            Text('Great job! ⭐',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 16)),
          ],
        ),
      ).animate().scale(duration: 400.ms, curve: Curves.elasticOut);
    }
    if (state.status == WritingStatus.failure) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.orange.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(50),
        ),
        child: const Text(
          'Try again! You can do it 💪',
          style: TextStyle(
              color: AppColors.orange,
              fontWeight: FontWeight.w700,
              fontSize: 15),
        ),
      );
    }
    if (state.status == WritingStatus.checking) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
                strokeWidth: 2.5, color: langColor),
          ),
          const SizedBox(width: 10),
          Text(
            'Checking your trace…',
            style: TextStyle(
                color: langColor, fontWeight: FontWeight.w600, fontSize: 15),
          ),
        ],
      );
    }
    // Guided mode (English & numbers): stroke-by-stroke messages.
    if (state.isGuided) {
      if (state.strokeMissed) {
        return Text(
          'Oops! Watch the hand and try again 💪',
          style: TextStyle(
              color: AppColors.orange,
              fontWeight: FontWeight.w700,
              fontSize: 15),
        );
      }
      return Text(
        'Stroke ${state.targetStrokeIndex + 1} of '
            '${state.guideStrokes.length} — follow the hand! 👆',
        style: TextStyle(
            color: langColor, fontWeight: FontWeight.w600, fontSize: 15),
      );
    }
    if (state.status == WritingStatus.drawing ||
        (state.strokes.isNotEmpty &&
            state.status == WritingStatus.idle)) {
      return Text(
        'Tap "Done!" when you finish ✏️',
        style: TextStyle(
            color: langColor, fontWeight: FontWeight.w600, fontSize: 15),
      );
    }
    return Text(
      'Trace the letter with your finger!',
      style: TextStyle(color: langColor, fontWeight: FontWeight.w500),
    );
  }
}

class _CanvasSection extends StatelessWidget {
  final Character character;
  final Color langColor;
  const _CanvasSection({required this.character, required this.langColor});

  @override
  Widget build(BuildContext context) {
    final size = ResponsiveHelper.canvasSize(context);
    // Third-star attempt (2 stars earned): hand and dots are OFF — the
    // child traces the letter from memory. The letter body stays visible
    // and every stroke is still validated.
    final ps = context.watch<ProgressBloc>().state;
    final stars = ps is ProgressLoaded
        ? (ps.progressMap[character.id]?.successCount ?? 0)
        : 0;
    final showGuides = stars < 2;

    return BlocBuilder<WritingBloc, WritingState>(
      builder: (context, state) => DrawingCanvas(
        character: character,
        canvasSize: size,
        strokes: state.strokes,
        currentStroke: state.currentStroke,
        isSuccess: state.status == WritingStatus.success,
        accentColor: langColor,
        // Fraction of the letter's own path thickness (fallback while
        // measuring) — tune via AppConstants.inkWidthFactor.
        strokeWidth: state.glyphStrokeWidth > 0
            ? (state.glyphStrokeWidth * size * AppConstants.inkWidthFactor)
            .clamp(12.0, size * 0.14)
            .toDouble()
            : AppConstants.strokeWidth,
        guideStrokes: state.guideStrokes,
        targetStrokeIndex: state.targetStrokeIndex,
        showGuideDots: showGuides,
        // Hand demo shows while waiting for the child to draw; hides while
        // drawing and after success.
        showHand: showGuides &&
            state.isGuided &&
            state.status != WritingStatus.drawing &&
            state.status != WritingStatus.success,
        onStrokeStart: (p) =>
            context.read<WritingBloc>().add(WritingStrokeStarted(p, size)),
        onStrokeUpdate: (p) =>
            context.read<WritingBloc>().add(WritingStrokeUpdated(p, size)),
        onStrokeEnd: () {
          // Guided mode validates the stroke immediately; free mode just
          // records it until the kid taps "Done ✓".
          context
              .read<WritingBloc>()
              .add(WritingStrokeEnded(Size(size, size)));
        },
      ),
    );
  }
}

class _BottomControls extends StatelessWidget {
  final Color langColor;
  final Character character;
  const _BottomControls({required this.langColor, required this.character});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: BlocBuilder<WritingBloc, WritingState>(
        builder: (context, state) {
          final hasStrokes = state.strokes.isNotEmpty;
          final isSuccess = state.status == WritingStatus.success;
          final isFailure = state.status == WritingStatus.failure;

          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Clear — always visible
              _ControlButton(
                icon: Icons.refresh_rounded,
                label: 'Clear',
                color: AppColors.orange,
                onTap: () {
                  context.read<WritingBloc>().add(const WritingClear());
                  sl<MusicBloc>().add(const MusicPlayTap());
                },
              ),

              // Done ✓ — free mode only (guided mode advances automatically
              // after each stroke); disabled while checking
              if (hasStrokes && !isSuccess && !state.isGuided)
                _ControlButton(
                  icon: state.status == WritingStatus.checking
                      ? Icons.hourglass_top_rounded
                      : Icons.check_circle_rounded,
                  label: 'Done!',
                  color: state.status == WritingStatus.checking
                      ? AppColors.textLight
                      : langColor,
                  onTap: state.status == WritingStatus.checking
                      ? () {} // no-op while async check runs
                      : () {
                    final size = ResponsiveHelper.canvasSize(context);
                    context.read<WritingBloc>().add(
                      WritingCheckAccuracy(Size(size, size)),
                    );
                  },
                ),

              // Next → back to the map, but only once all 3 stars are in
              // (stars 1–2 auto-reset the canvas for another go).
              if (isSuccess)
                BlocBuilder<ProgressBloc, ProgressState>(
                  builder: (context, ps) {
                    final stars = ps is ProgressLoaded
                        ? (ps.progressMap[character.id]?.successCount ??
                        0)
                        : 0;
                    if (stars < 3) return const SizedBox.shrink();
                    return _ControlButton(
                      icon: Icons.arrow_forward_rounded,
                      label: 'Next',
                      color: AppColors.successColor,
                      onTap: () => context.pop(),
                    );
                  },
                ),

              // Try Again — shown after failure, no strokes required message
              if (isFailure && !hasStrokes) const SizedBox.shrink(),
            ],
          );
        },
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ControlButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(50),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.4),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 22),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Big golden star: pops in at the canvas, then flies up into the star row.
class _FlyingStar extends StatelessWidget {
  final Offset from;
  final Offset to;
  final VoidCallback onDone;

  const _FlyingStar({
    required this.from,
    required this.to,
    required this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    const double starSize = 110;
    return Positioned.fill(
      child: IgnorePointer(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 1300),
          onEnd: onDone,
          builder: (context, t, _) {
            // Phase 1 (0–0.35): star pops in at the canvas.
            // Phase 2 (0.35–1): star flies to the row while shrinking.
            final popT = (t / 0.35).clamp(0.0, 1.0);
            final moveT = Curves.easeInOutCubic
                .transform(((t - 0.35) / 0.65).clamp(0.0, 1.0));
            final pos = Offset.lerp(from, to, moveT)!;
            final scale = t < 0.35
                ? Curves.elasticOut.transform(popT)
                : 1.0 - 0.72 * moveT;
            return Stack(
              children: [
                Positioned(
                  left: pos.dx - starSize / 2,
                  top: pos.dy - starSize / 2,
                  child: Transform.scale(
                    scale: scale,
                    child: const Icon(
                      Icons.star_rounded,
                      size: starSize,
                      color: Color(0xFFFFB300),
                      shadows: [
                        Shadow(color: Colors.black38, blurRadius: 16),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
