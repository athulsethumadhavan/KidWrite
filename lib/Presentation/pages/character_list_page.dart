import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/widgets/animated_background.dart';
import '../../domain/entities/character.dart';
import '../../domain/entities/progress.dart';
import '../../domain/usecases/get_characters.dart';
import '../../injection_container.dart';
import '../blocs/progress/progress_bloc.dart';
import '../widgets/music_toggle_button.dart';
import '../blocs/music/music_bloc.dart';

class CharacterListPage extends StatefulWidget {
  final String languageId;
  const CharacterListPage({super.key, required this.languageId});

  @override
  State<CharacterListPage> createState() => _CharacterListPageState();
}

class _CharacterListPageState extends State<CharacterListPage> {
  List<Character> _characters = [];
  bool _loading = true;
  String? _selectedCategory;
  late final ProgressBloc _progressBloc;

  @override
  void initState() {
    super.initState();
    _progressBloc = sl<ProgressBloc>()
      ..add(ProgressLoad(widget.languageId));
    _loadCharacters();
  }

  @override
  void dispose() {
    _progressBloc.close();
    super.dispose();
  }

  Future<void> _loadCharacters() async {
    // Load the full set; category filtering happens locally so the filter
    // chips stay visible after a category is selected.
    final chars = await sl<GetCharacters>()(
      GetCharactersParams(languageId: widget.languageId),
    );
    if (mounted) setState(() { _characters = chars; _loading = false; });
  }

  List<Character> get _visibleCharacters => _selectedCategory == null
      ? _characters
      : _characters
      .where((c) => c.category.name == _selectedCategory)
      .toList();

  List<String> get _categories {
    final cats = _characters.map((c) => c.category.name).toSet().toList();
    cats.sort();
    return cats;
  }

  Color get _langColor =>
      AppColors.languageColors[widget.languageId] ?? AppColors.primary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocProvider.value(
      value: _progressBloc,
      child: Scaffold(
        body: AnimatedBackground(
          primaryColor: _langColor,
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // App bar row
                Padding(
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
                          _languageTitle(),
                          style: theme.textTheme.headlineMedium,
                        ),
                      ),
                      BlocBuilder<MusicBloc, MusicState>(
                        bloc: sl<MusicBloc>(),
                        builder: (_, s) => MusicToggleButton(
                          isEnabled: s.isMusicEnabled,
                          onTap: () =>
                              sl<MusicBloc>().add(const MusicToggle()),
                        ),
                      ),
                    ],
                  ),
                ),

                // Category filter chips
                if (!_loading && _categories.length > 1)
                  _CategoryFilter(
                    categories: _categories,
                    selected: _selectedCategory,
                    accentColor: _langColor,
                    onSelect: (cat) {
                      setState(() => _selectedCategory = cat);
                    },
                  ),

                const SizedBox(height: 8),

                // Level map — winding path of letter "stages"
                Expanded(
                  child: _loading
                      ? const Center(child: CircularProgressIndicator())
                      : BlocBuilder<ProgressBloc, ProgressState>(
                    builder: (context, progressState) {
                      final progressMap =
                      progressState is ProgressLoaded
                          ? progressState.progressMap
                          : <String, Progress>{};

                      // Sequential unlocking over the FULL letter order:
                      // a letter opens once the previous one has 3 stars.
                      final unlockedIds = <String>{};
                      for (int i = 0; i < _characters.length; i++) {
                        if (i == 0) {
                          unlockedIds.add(_characters[i].id);
                          continue;
                        }
                        final prev =
                            progressMap[_characters[i - 1].id];
                        if ((prev?.successCount ?? 0) >= 3) {
                          unlockedIds.add(_characters[i].id);
                        }
                      }

                      return _LevelPathMap(
                        characters: _visibleCharacters,
                        progressMap: progressMap,
                        unlockedIds: unlockedIds,
                        accentColor: _langColor,
                        languageId: widget.languageId,
                        onTap: (char) {
                          context
                              .push(
                            '/practice/${widget.languageId}/${char.id}',
                            extra: char,
                          )
                              .then((_) {
                            // Coming back — refresh earned stars.
                            if (mounted) {
                              _progressBloc
                                  .add(ProgressLoad(widget.languageId));
                            }
                          });
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _languageTitle() {
    const titles = {
      'english': 'English ✨',
      'numbers': 'Numbers 🔢',
      'malayalam': 'Malayalam മ',
      'hindi': 'Hindi क',
      'tamil': 'Tamil அ',
    };
    return titles[widget.languageId] ?? widget.languageId;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Candy-Crush-style level map: letters as round stages on a winding trail
// ─────────────────────────────────────────────────────────────────────────────

class _LevelPathMap extends StatelessWidget {
  final List<Character> characters;
  final Map<String, Progress> progressMap;
  final Set<String> unlockedIds;
  final Color accentColor;
  final String languageId;
  final void Function(Character) onTap;

  const _LevelPathMap({
    required this.characters,
    required this.progressMap,
    required this.unlockedIds,
    required this.accentColor,
    required this.languageId,
    required this.onTap,
  });

  static const double _spacingY = 128;
  static const double _nodeSize = 92;
  static const double _topPad = 52; // room for the star row of node 1
  static const double _bottomPad = 40;

  /// Serpentine x-position (fraction of width) for node [i].
  double _xFrac(int i) => 0.5 + 0.34 * math.sin(i * math.pi / 2);

  @override
  Widget build(BuildContext context) {
    if (characters.isEmpty) {
      return const Center(child: Text('No letters here yet!'));
    }
    final mapHeight =
        _topPad + (characters.length - 1) * _spacingY + _bottomPad + _nodeSize;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final centers = <Offset>[
          for (int i = 0; i < characters.length; i++)
            Offset(
              _xFrac(i) * width,
              _topPad + _nodeSize / 2 + i * _spacingY,
            ),
        ];

        return SingleChildScrollView(
          child: SizedBox(
            width: width,
            height: mapHeight,
            child: Stack(
              children: [
                // The winding trail behind the nodes.
                CustomPaint(
                  size: Size(width, mapHeight),
                  painter: _TrailPainter(
                    centers: centers,
                    color: accentColor,
                  ),
                ),
                for (int i = 0; i < characters.length; i++)
                  Positioned(
                    left: centers[i].dx - _nodeSize / 2,
                    top: centers[i].dy - _nodeSize / 2,
                    child: _LevelNode(
                      character: characters[i],
                      stars: (progressMap[characters[i].id]
                          ?.successCount ??
                          0)
                          .clamp(0, 3)
                          .toInt(),
                      isLocked:
                      !unlockedIds.contains(characters[i].id),
                      accentColor: accentColor,
                      languageId: languageId,
                      size: _nodeSize,
                      onTap: () => onTap(characters[i]),
                    )
                    // Gentle idle bobbing, each bubble slightly out of
                    // phase so the path feels alive.
                        .animate(onPlay: (c) => c.repeat(reverse: true))
                        .moveY(
                      begin: -3.5,
                      end: 3.5,
                      duration:
                      Duration(milliseconds: 1400 + (i % 5) * 180),
                      curve: Curves.easeInOut,
                    )
                    // One-time pop-in entrance.
                        .animate(
                        delay: Duration(
                            milliseconds: math.min(i * 40, 600)))
                        .fadeIn(duration: 300.ms)
                        .scale(
                      begin: const Offset(0.7, 0.7),
                      end: const Offset(1, 1),
                      duration: 350.ms,
                      curve: Curves.easeOutBack,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Soft wide trail with white "footstep" dashes, like a board-game path.
class _TrailPainter extends CustomPainter {
  final List<Offset> centers;
  final Color color;

  _TrailPainter({required this.centers, required this.color});

  Path _smoothPath() {
    final path = Path()..moveTo(centers.first.dx, centers.first.dy);
    for (int i = 1; i < centers.length; i++) {
      if (i < centers.length - 1) {
        final mid = Offset(
          (centers[i].dx + centers[i + 1].dx) / 2,
          (centers[i].dy + centers[i + 1].dy) / 2,
        );
        path.quadraticBezierTo(
            centers[i].dx, centers[i].dy, mid.dx, mid.dy);
      } else {
        path.lineTo(centers[i].dx, centers[i].dy);
      }
    }
    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (centers.length < 2) return;
    final path = _smoothPath();

    // Wide soft band.
    canvas.drawPath(
      path,
      Paint()
        ..color = color.withValues(alpha: 0.18)
        ..strokeWidth = 26
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke,
    );

    // White dashes along the middle of the band.
    final metrics = path.computeMetrics();
    final dashPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.9)
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    for (final metric in metrics) {
      double d = 10;
      while (d < metric.length) {
        final extract = metric.extractPath(d, math.min(d + 10, metric.length));
        canvas.drawPath(extract, dashPaint);
        d += 24;
      }
    }
  }

  @override
  bool shouldRepaint(_TrailPainter old) =>
      old.centers != centers || old.color != color;
}

class _LevelNode extends StatelessWidget {
  final Character character;
  final int stars; // 0..3 earned
  final bool isLocked;
  final Color accentColor;
  final String languageId;
  final double size;
  final VoidCallback onTap;

  const _LevelNode({
    required this.character,
    required this.stars,
    required this.isLocked,
    required this.accentColor,
    required this.languageId,
    required this.size,
    required this.onTap,
  });

  String? _fontFamily() {
    const map = {
      'malayalam': 'NotoSansMalayalam',
      'hindi': 'NotoSansDevanagari',
      'tamil': 'NotoSansTamil',
      'english': 'Andika',
      'numbers': 'Andika',
    };
    return map[languageId];
  }

  bool get _complete => stars >= 3;

  @override
  Widget build(BuildContext context) {
    final bubbleColor = isLocked
        ? Colors.blueGrey.shade300
        : _complete
        ? AppColors.successColor
        : accentColor;

    return GestureDetector(
      onTap: isLocked ? null : onTap,
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // 3 stars above the bubble.
            Positioned(
              top: -24,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (int i = 0; i < 3; i++)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 1),
                      child: Icon(
                        Icons.star_rounded,
                        size: i == 1 ? 26 : 22,
                        color: !isLocked && i < stars
                            ? const Color(0xFFFFB300)
                            : Colors.black.withValues(alpha: 0.22),
                      ),
                    ),
                ],
              ),
            ),
            // Bubble
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    bubbleColor,
                    bubbleColor.withValues(alpha: 0.72),
                  ],
                ),
                border: Border.all(color: Colors.white, width: 4),
                boxShadow: [
                  BoxShadow(
                    color: bubbleColor.withValues(alpha: 0.45),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Glossy bubble shine.
                  Align(
                    alignment: const Alignment(-0.45, -0.62),
                    child: Container(
                      width: size * 0.30,
                      height: size * 0.17,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.all(
                          Radius.elliptical(size * 0.15, size * 0.085),
                        ),
                      ),
                    ),
                  ),
                  Center(
                    child: Text(
                      character.symbol,
                      style: TextStyle(
                        fontSize: size * 0.52,
                        fontWeight: FontWeight.w900,
                        color: Colors.white
                            .withValues(alpha: isLocked ? 0.5 : 1.0),
                        fontFamily: _fontFamily(),
                        height: 1.0,
                      ),
                    ),
                  ),
                  // Lock sits ON TOP of the (dimmed) letter.
                  if (isLocked)
                    Center(
                      child: Icon(
                        Icons.lock_rounded,
                        color: Colors.white,
                        size: size * 0.34,
                        shadows: const [
                          Shadow(color: Colors.black45, blurRadius: 6),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryFilter extends StatelessWidget {
  final List<String> categories;
  final String? selected;
  final Color accentColor;
  final void Function(String?) onSelect;

  const _CategoryFilter({
    required this.categories,
    required this.selected,
    required this.accentColor,
    required this.onSelect,
  });

  String _label(String cat) {
    const labels = {
      'vowel': 'Vowels',
      'consonant': 'Consonants',
      'uppercase': 'UPPER',
      'lowercase': 'lower',
      'number': 'Numbers',
    };
    return labels[cat] ?? cat;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // "All" chip
          _Chip(
            label: 'All',
            selected: selected == null,
            color: accentColor,
            onTap: () => onSelect(null),
          ),
          ...categories.map(
                (cat) => _Chip(
              label: _label(cat),
              selected: selected == cat,
              color: accentColor,
              onTap: () => onSelect(cat == selected ? null : cat),
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _Chip({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? color : color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(50),
            boxShadow: selected
                ? [
              BoxShadow(
                color: color.withValues(alpha: 0.4),
                blurRadius: 8,
                offset: const Offset(0, 3),
              )
            ]
                : [],
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : color,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}
