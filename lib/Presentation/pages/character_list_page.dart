import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/responsive_helper.dart';
import '../../core/widgets/animated_background.dart';
import '../../domain/entities/character.dart';
import '../../domain/entities/progress.dart';
import '../../domain/usecases/get_characters.dart';
import '../../injection_container.dart';
import '../blocs/progress/progress_bloc.dart';
import '../widgets/character_grid_card.dart';
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

  @override
  void initState() {
    super.initState();
    _loadCharacters();
  }

  Future<void> _loadCharacters() async {
    final chars = await sl<GetCharacters>()(
      GetCharactersParams(
        languageId: widget.languageId,
        category: _selectedCategory,
      ),
    );
    if (mounted) setState(() { _characters = chars; _loading = false; });
  }

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
    final isTablet = ResponsiveHelper.isTablet(context);

    return BlocProvider(
      create: (_) => sl<ProgressBloc>()
        ..add(ProgressLoad(widget.languageId)),
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
                      _loadCharacters();
                    },
                  ),

                const SizedBox(height: 8),

                // Grid
                Expanded(
                  child: _loading
                      ? const Center(child: CircularProgressIndicator())
                      : BlocBuilder<ProgressBloc, ProgressState>(
                    builder: (context, progressState) {
                      final progressMap =
                      progressState is ProgressLoaded
                          ? progressState.progressMap
                          : <String, Progress>{};

                      return GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate:
                        SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount:
                          ResponsiveHelper.gridCrossAxisCount(
                              context),
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 1,
                        ),
                        itemCount: _characters.length,
                        itemBuilder: (context, i) {
                          final char = _characters[i];
                          final prog = progressMap[char.id];
                          return CharacterGridCard(
                            character: char,
                            isMastered:
                            prog?.isMastered ?? false,
                            accentColor: _langColor,
                            languageId: widget.languageId,
                            onTap: () => context.push(
                              '/practice/${widget.languageId}/${char.id}',
                              extra: char,
                            ),
                          )
                              .animate(delay: (i * 30).ms)
                              .fadeIn(duration: 300.ms)
                              .scale(
                            begin: const Offset(0.85, 0.85),
                            end: const Offset(1, 1),
                            duration: 300.ms,
                            curve: Curves.easeOut,
                          );
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
