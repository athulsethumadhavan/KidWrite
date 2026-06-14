import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:kid_write/Core/Constants/app_constants.dart';

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

  @override
  void initState() {
    super.initState();
    _confetti = ConfettiController(
        duration: AppConstants.celebrationDuration);
    _writingBloc = sl<WritingBloc>()
      ..add(WritingLoadCharacter(widget.character));
    _progressBloc = sl<ProgressBloc>()
      ..add(ProgressLoad(widget.languageId));
  }

  @override
  void dispose() {
    _confetti.dispose();
    _writingBloc.close();
    _progressBloc.close();
    super.dispose();
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
                children: [
                  isTablet
                      ? _TabletLayout(
                    character: widget.character,
                    languageId: widget.languageId,
                    langColor: _langColor,
                  )
                      : _PhoneLayout(
                    character: widget.character,
                    languageId: widget.languageId,
                    langColor: _langColor,
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
      _confetti.play();
      sl<MusicBloc>().add(const MusicPlaySuccess());
      _progressBloc.add(ProgressRecord(
        characterId: widget.character.id,
        languageId: widget.languageId,
        success: true,
        accuracy: state.accuracy,
      ));
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

  const _PhoneLayout({
    required this.character,
    required this.languageId,
    required this.langColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _TopBar(character: character, languageId: languageId),
        const SizedBox(height: 8),
        _CharacterInfo(character: character, langColor: langColor),
        const SizedBox(height: 16),
        Expanded(
          child: Center(
            child: _CanvasSection(
                character: character, langColor: langColor),
          ),
        ),
        _BottomControls(langColor: langColor),
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

  const _TabletLayout({
    required this.character,
    required this.languageId,
    required this.langColor,
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
                          character: character, langColor: langColor),
                      const SizedBox(height: 32),
                      _BottomControls(langColor: langColor),
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
  const _CharacterInfo({required this.character, required this.langColor});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color: langColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
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
        ),
        const SizedBox(height: 12),
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
    return BlocBuilder<WritingBloc, WritingState>(
      builder: (context, state) => DrawingCanvas(
        character: character,
        canvasSize: size,
        strokes: state.strokes,
        currentStroke: state.currentStroke,
        isSuccess: state.status == WritingStatus.success,
        accentColor: langColor,
        onStrokeStart: (p) =>
            context.read<WritingBloc>().add(WritingStrokeStarted(p)),
        onStrokeUpdate: (p) =>
            context.read<WritingBloc>().add(WritingStrokeUpdated(p)),
        onStrokeEnd: () {
          // Only record the stroke — accuracy is checked when the kid taps "Done ✓"
          context.read<WritingBloc>().add(const WritingStrokeEnded());
        },
      ),
    );
  }
}

class _BottomControls extends StatelessWidget {
  final Color langColor;
  const _BottomControls({required this.langColor});

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

              // Done ✓ — shown while tracing or after failure; disabled while checking
              if (hasStrokes && !isSuccess)
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

              // Next → shown only on success
              if (isSuccess)
                _ControlButton(
                  icon: Icons.arrow_forward_rounded,
                  label: 'Next',
                  color: AppColors.successColor,
                  onTap: () => context.pop(),
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

