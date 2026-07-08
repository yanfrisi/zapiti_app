part of 'game_screen.dart';

class _CharacterSelectionScreen extends StatelessWidget {
  final String selectedCharacterId;
  final ValueChanged<String> onSelected;
  final VoidCallback onStart;

  const _CharacterSelectionScreen({
    required this.selectedCharacterId,
    required this.onSelected,
    required this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    return OrientationBuilder(
      builder: (context, orientation) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final selectedName =
                CharacterAssets.displayNames[selectedCharacterId] ??
                    selectedCharacterId;
            final shortest = min(constraints.maxWidth, constraints.maxHeight);
            final gap = shortest * 0.026;
            final padding = EdgeInsets.all(shortest * 0.04);
            final title = _SelectionTitle(
              title: 'Elige tu personaje',
              subtitle: 'Seleccionado: $selectedName',
            );
            final grid = _CharacterChoiceGrid(
              selectedCharacterId: selectedCharacterId,
              onSelected: onSelected,
              columns: orientation == Orientation.portrait
                  ? (constraints.maxWidth > constraints.maxHeight * 0.72
                      ? 4
                      : 2)
                  : 2,
            );
            final button = FractionallySizedBox(
              widthFactor: orientation == Orientation.portrait ? 1 : 0.86,
              child: ZapitiActionButton(
                label: 'EMPEZAR PARTIDA',
                icon: Icons.play_arrow,
                onPressed: onStart,
                primary: true,
              ),
            );

            if (orientation == Orientation.portrait) {
              return Padding(
                padding: padding,
                child: Column(
                  children: [
                    Flexible(flex: 12, child: title),
                    SizedBox(height: gap),
                    Expanded(
                      flex: 34,
                      child: _SelectedCharacterShowcase(
                        characterId: selectedCharacterId,
                        name: selectedName,
                        compact: true,
                      ),
                    ),
                    SizedBox(height: gap),
                    Expanded(flex: 40, child: grid),
                    SizedBox(height: gap),
                    Flexible(flex: 10, child: Center(child: button)),
                  ],
                ),
              );
            }

            return Padding(
              padding: padding,
              child: Row(
                children: [
                  Expanded(
                    flex: 48,
                    child: _SelectedCharacterShowcase(
                      characterId: selectedCharacterId,
                      name: selectedName,
                      compact: false,
                    ),
                  ),
                  SizedBox(width: gap),
                  Expanded(
                    flex: 52,
                    child: Column(
                      children: [
                        Flexible(flex: 18, child: title),
                        SizedBox(height: gap),
                        Expanded(flex: 68, child: grid),
                        SizedBox(height: gap),
                        Flexible(flex: 14, child: Center(child: button)),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _SelectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SelectionTitle({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: ZapitiColors.cardCream,
                  fontWeight: FontWeight.w900,
                ),
          ),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: ZapitiColors.cardCream.withValues(alpha: 0.76),
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

class _CharacterChoiceGrid extends StatelessWidget {
  final String selectedCharacterId;
  final ValueChanged<String> onSelected;
  final int columns;

  const _CharacterChoiceGrid({
    required this.selectedCharacterId,
    required this.onSelected,
    required this.columns,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final gap = min(constraints.maxWidth, constraints.maxHeight) * 0.035;
        final rows = (CharacterAssets.characterIds.length / columns).ceil();
        final tileWidth =
            (constraints.maxWidth - gap * (columns - 1)) / columns;
        final tileHeight = (constraints.maxHeight - gap * (rows - 1)) / rows;

        return GridView.count(
          padding: EdgeInsets.zero,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: columns,
          mainAxisSpacing: gap,
          crossAxisSpacing: gap,
          childAspectRatio: tileWidth / tileHeight,
          children: [
            for (final characterId in CharacterAssets.characterIds)
              _CharacterChoice(
                characterId: characterId,
                selected: characterId == selectedCharacterId,
                onTap: () => onSelected(characterId),
              ),
          ],
        );
      },
    );
  }
}

class _SelectedCharacterShowcase extends StatelessWidget {
  final String characterId;
  final String name;
  final bool compact;

  const _SelectedCharacterShowcase({
    required this.characterId,
    required this.name,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final gap = min(constraints.maxWidth, constraints.maxHeight) * 0.035;
        return DecoratedBox(
          decoration: BoxDecoration(
            color: ZapitiColors.tableGreenDark.withValues(alpha: 0.68),
            borderRadius: BorderRadius.circular(gap),
            border: Border.all(
              color: ZapitiColors.oldGold.withValues(alpha: 0.42),
              width: max(gap * 0.16, 1),
            ),
          ),
          child: Padding(
            padding: EdgeInsets.all(gap),
            child: compact
                ? Column(
                    children: [
                      Expanded(
                        child: _SelectedCharacterImage(
                          characterId: characterId,
                        ),
                      ),
                      SizedBox(height: gap),
                      Flexible(child: _SelectedCharacterLabel(name: name)),
                    ],
                  )
                : Row(
                    children: [
                      Expanded(
                        flex: 62,
                        child: _SelectedCharacterImage(
                          characterId: characterId,
                        ),
                      ),
                      SizedBox(width: gap),
                      Expanded(
                        flex: 38,
                        child: _SelectedCharacterLabel(name: name),
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }
}

class _SelectedCharacterImage extends StatelessWidget {
  final String characterId;

  const _SelectedCharacterImage({
    required this.characterId,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: FractionallySizedBox(
        widthFactor: 1,
        heightFactor: 1,
        child: Image.asset(
          CharacterAssets.selection(characterId),
          fit: BoxFit.contain,
          alignment: Alignment.center,
          errorBuilder: (_, __, ___) {
            return Icon(
              Icons.person,
              size: MediaQuery.sizeOf(context).shortestSide * 0.22,
              color: ZapitiColors.darkBrown.withValues(alpha: 0.7),
            );
          },
        ),
      ),
    );
  }
}

class _SelectedCharacterLabel extends StatelessWidget {
  final String name;

  const _SelectedCharacterLabel({required this.name});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          name,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: ZapitiColors.cardCream,
                fontWeight: FontWeight.w900,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Tu personaje',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: ZapitiColors.oldGold,
                fontWeight: FontWeight.w900,
              ),
        ),
      ],
    );
  }
}

class _CharacterChoice extends StatelessWidget {
  final String characterId;
  final bool selected;
  final VoidCallback onTap;

  const _CharacterChoice({
    required this.characterId,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final name = CharacterAssets.displayNames[characterId] ?? characterId;

    return Semantics(
      button: true,
      selected: selected,
      label: name,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 130),
          padding:
              EdgeInsets.all(MediaQuery.sizeOf(context).shortestSide * 0.012),
          decoration: BoxDecoration(
            color: selected
                ? ZapitiColors.oldGold.withValues(alpha: 0.94)
                : ZapitiColors.tableGreenDark.withValues(alpha: 0.74),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected
                  ? ZapitiColors.cardCream
                  : ZapitiColors.oldGold.withValues(alpha: 0.28),
              width: selected ? 3 : 1,
            ),
          ),
          child: Column(
            children: [
              Expanded(
                child: Container(
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Image.asset(
                    CharacterAssets.selection(characterId),
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) {
                      return Icon(
                        Icons.person,
                        size: MediaQuery.sizeOf(context).shortestSide * 0.12,
                        color: ZapitiColors.darkBrown.withValues(alpha: 0.7),
                      );
                    },
                  ),
                ),
              ),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: selected
                              ? ZapitiColors.darkBrown
                              : ZapitiColors.cardCream,
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DifficultySelectionScreen extends StatelessWidget {
  final int selectedDifficulty;
  final ValueChanged<int> onSelected;
  final VoidCallback onStart;

  const _DifficultySelectionScreen({
    required this.selectedDifficulty,
    required this.onSelected,
    required this.onStart,
  });

  static const _labels = {
    1: 'Muy facil',
    2: 'Facil',
    3: 'Normal',
    4: 'Dificil',
    5: 'Experto',
  };

  @override
  Widget build(BuildContext context) {
    return OrientationBuilder(
      builder: (context, orientation) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final profile = DifficultyProfiles.byLevel(selectedDifficulty);
            final shortest = min(constraints.maxWidth, constraints.maxHeight);
            final gap = shortest * 0.028;
            final padding = EdgeInsets.all(shortest * 0.045);
            final title = _SelectionTitle(
              title: 'Elige dificultad',
              subtitle: 'Nivel $selectedDifficulty/5',
            );
            final columns = orientation == Orientation.portrait
                ? (constraints.maxWidth > constraints.maxHeight * 0.72 ? 3 : 2)
                : 3;
            final choices = _DifficultyChoiceGrid(
              selectedDifficulty: selectedDifficulty,
              onSelected: onSelected,
              columns: columns,
              labels: _labels,
            );
            final button = FractionallySizedBox(
              widthFactor: orientation == Orientation.portrait ? 1 : 0.72,
              child: ZapitiActionButton(
                label: 'JUGAR',
                icon: Icons.play_arrow,
                onPressed: onStart,
                primary: true,
              ),
            );

            if (orientation == Orientation.portrait) {
              return Padding(
                padding: padding,
                child: Column(
                  children: [
                    Flexible(flex: 14, child: title),
                    SizedBox(height: gap),
                    Flexible(
                      flex: 24,
                      child: _SelectedDifficultySummary(profile: profile),
                    ),
                    SizedBox(height: gap),
                    Expanded(flex: 48, child: choices),
                    SizedBox(height: gap),
                    Flexible(flex: 12, child: Center(child: button)),
                  ],
                ),
              );
            }

            return Padding(
              padding: padding,
              child: Row(
                children: [
                  Expanded(
                    flex: 36,
                    child: Column(
                      children: [
                        Flexible(flex: 28, child: title),
                        SizedBox(height: gap),
                        Expanded(
                          flex: 58,
                          child: _SelectedDifficultySummary(profile: profile),
                        ),
                        SizedBox(height: gap),
                        Flexible(flex: 14, child: Center(child: button)),
                      ],
                    ),
                  ),
                  SizedBox(width: gap),
                  Expanded(flex: 64, child: choices),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _DifficultyChoiceGrid extends StatelessWidget {
  final int selectedDifficulty;
  final ValueChanged<int> onSelected;
  final int columns;
  final Map<int, String> labels;

  const _DifficultyChoiceGrid({
    required this.selectedDifficulty,
    required this.onSelected,
    required this.columns,
    required this.labels,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final gap = min(constraints.maxWidth, constraints.maxHeight) * 0.035;
        final rows = (labels.length / columns).ceil();
        final tileWidth =
            (constraints.maxWidth - gap * (columns - 1)) / columns;
        final tileHeight = (constraints.maxHeight - gap * (rows - 1)) / rows;

        return GridView.count(
          padding: EdgeInsets.zero,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: columns,
          mainAxisSpacing: gap,
          crossAxisSpacing: gap,
          childAspectRatio: tileWidth / tileHeight,
          children: [
            for (var difficulty = 1; difficulty <= labels.length; difficulty++)
              _DifficultyChoice(
                difficulty: difficulty,
                selected: difficulty == selectedDifficulty,
                label: labels[difficulty]!,
                onTap: () => onSelected(difficulty),
              ),
          ],
        );
      },
    );
  }
}

class _DifficultyChoice extends StatelessWidget {
  final int difficulty;
  final bool selected;
  final String label;
  final VoidCallback onTap;

  const _DifficultyChoice({
    required this.difficulty,
    required this.selected,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final shortest = min(constraints.maxWidth, constraints.maxHeight);
        final gap = shortest * 0.08;
        final iconSize = shortest * 0.24;
        return InkWell(
          borderRadius: BorderRadius.circular(gap),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 130),
            padding: EdgeInsets.all(gap),
            decoration: BoxDecoration(
              color: selected
                  ? ZapitiColors.oldGold
                  : ZapitiColors.tableGreenDark.withValues(alpha: 0.74),
              borderRadius: BorderRadius.circular(gap),
              border: Border.all(
                color: selected
                    ? ZapitiColors.cardCream
                    : ZapitiColors.oldGold.withValues(alpha: 0.3),
                width: selected ? max(gap * 0.22, 1) : max(gap * 0.08, 1),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Flexible(
                  flex: 28,
                  child: Row(
                    children: [
                      Icon(
                        Icons.psychology_alt_outlined,
                        size: iconSize,
                        color: selected
                            ? ZapitiColors.darkBrown
                            : ZapitiColors.oldGold,
                      ),
                      SizedBox(width: gap * 0.55),
                      Expanded(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  color: selected
                                      ? ZapitiColors.darkBrown
                                      : ZapitiColors.cardCream,
                                  fontWeight: FontWeight.w900,
                                ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Text(
                  'Nivel $difficulty',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: selected
                            ? ZapitiColors.wineRed
                            : ZapitiColors.oldGold,
                        fontWeight: FontWeight.w900,
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

class _SelectedDifficultySummary extends StatelessWidget {
  final DifficultyProfile profile;

  const _SelectedDifficultySummary({required this.profile});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final gap = min(constraints.maxWidth, constraints.maxHeight) * 0.065;
        final panel = DecoratedBox(
          decoration: BoxDecoration(
            color: ZapitiColors.tableGreenDark.withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(gap),
            border: Border.all(
              color: ZapitiColors.oldGold.withValues(alpha: 0.38),
            ),
          ),
          child: Padding(
            padding: EdgeInsets.all(gap),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.summary,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: ZapitiColors.cardCream,
                        fontWeight: FontWeight.w900,
                      ),
                ),
                SizedBox(height: gap * 0.7),
                _DifficultySummaryLine(
                  icon: Icons.style_outlined,
                  text: profile.cardPlay,
                ),
                _DifficultySummaryLine(
                  icon: Icons.campaign_outlined,
                  text: profile.trucoPlay,
                ),
                _DifficultySummaryLine(
                  icon: Icons.visibility_outlined,
                  text: profile.readsOpponentSignals
                      ? 'Lee senas rivales vistas.'
                      : 'No interpreta senas rivales.',
                ),
              ],
            ),
          ),
        );

        return Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: SizedBox(
              width: constraints.maxWidth,
              child: panel,
            ),
          ),
        );
      },
    );
  }
}

class _DifficultySummaryLine extends StatelessWidget {
  final IconData icon;
  final String text;

  const _DifficultySummaryLine({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: ZapitiColors.oldGold),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: ZapitiColors.cardCream.withValues(alpha: 0.78),
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
