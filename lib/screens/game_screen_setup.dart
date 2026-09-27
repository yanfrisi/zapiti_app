part of 'game_screen.dart';

String _difficultySummary(BuildContext context, int level) {
  return switch (level) {
    1 => context.tr('difficultySummary1'),
    2 => context.tr('difficultySummary2'),
    3 => context.tr('difficultySummary3'),
    4 => context.tr('difficultySummary4'),
    5 => context.tr('difficultySummary5'),
    _ => context.tr('difficultySummary3'),
  };
}

String _difficultyCardPlay(BuildContext context, int level) {
  return switch (level) {
    1 => context.tr('difficultyCard1'),
    2 => context.tr('difficultyCard2'),
    3 => context.tr('difficultyCard3'),
    4 => context.tr('difficultyCard4'),
    5 => context.tr('difficultyCard5'),
    _ => context.tr('difficultyCard3'),
  };
}

String _difficultyTrucoPlay(BuildContext context, int level) {
  return switch (level) {
    1 => context.tr('difficultyTruco1'),
    2 => context.tr('difficultyTruco2'),
    3 => context.tr('difficultyTruco3'),
    4 => context.tr('difficultyTruco4'),
    5 => context.tr('difficultyTruco5'),
    _ => context.tr('difficultyTruco3'),
  };
}

class _CharacterSelectionScreen extends StatelessWidget {
  final String selectedCharacterId;
  final ValueChanged<String> onSelected;
  final VoidCallback onBack;
  final VoidCallback onStart;

  const _CharacterSelectionScreen({
    required this.selectedCharacterId,
    required this.onSelected,
    required this.onBack,
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
              title: context.tr('chooseCharacter'),
              subtitle: context.tr(
                'selectedCharacter',
                params: {'name': selectedName},
              ),
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
                label: context.tr('startMatch'),
                icon: Icons.play_arrow,
                onPressed: onStart,
                primary: true,
              ),
            );
            final backButton = FractionallySizedBox(
              widthFactor: orientation == Orientation.portrait ? 1 : 0.86,
              child: ZapitiActionButton(
                label: context.tr('back'),
                icon: Icons.arrow_back,
                onPressed: onBack,
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
                    Flexible(
                      flex: 16,
                      child: Column(
                        children: [
                          Expanded(child: Center(child: button)),
                          SizedBox(height: gap * 0.5),
                          Expanded(child: Center(child: backButton)),
                        ],
                      ),
                    ),
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
                        Flexible(
                          flex: 22,
                          child: Column(
                            children: [
                              Expanded(child: Center(child: button)),
                              SizedBox(height: gap * 0.5),
                              Expanded(child: Center(child: backButton)),
                            ],
                          ),
                        ),
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
  final Set<String> disabledCharacterIds;
  final Map<String, String> characterBadges;

  const _CharacterChoiceGrid({
    required this.selectedCharacterId,
    required this.onSelected,
    required this.columns,
    this.disabledCharacterIds = const {},
    this.characterBadges = const {},
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
                disabled: disabledCharacterIds.contains(characterId),
                badgeLabel: characterBadges[characterId],
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
          context.tr('yourCharacter'),
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
  final bool disabled;
  final String? badgeLabel;
  final VoidCallback onTap;

  const _CharacterChoice({
    required this.characterId,
    required this.selected,
    this.disabled = false,
    this.badgeLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final name = CharacterAssets.displayNames[characterId] ?? characterId;

    return Semantics(
      button: true,
      selected: selected,
      enabled: !disabled,
      label: name,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: disabled ? null : onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 130),
          padding:
              EdgeInsets.all(MediaQuery.sizeOf(context).shortestSide * 0.012),
          decoration: BoxDecoration(
            color: selected
                ? ZapitiColors.oldGold.withValues(alpha: 0.94)
                : disabled
                    ? ZapitiColors.darkBrown.withValues(alpha: 0.42)
                    : ZapitiColors.tableGreenDark.withValues(alpha: 0.74),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected
                  ? ZapitiColors.cardCream
                  : disabled
                      ? ZapitiColors.darkBrown.withValues(alpha: 0.26)
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
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.asset(
                        CharacterAssets.selection(characterId),
                        fit: BoxFit.contain,
                        color: disabled
                            ? Colors.black.withValues(alpha: 0.42)
                            : null,
                        colorBlendMode: disabled ? BlendMode.saturation : null,
                        errorBuilder: (_, __, ___) {
                          return Icon(
                            Icons.person,
                            size:
                                MediaQuery.sizeOf(context).shortestSide * 0.12,
                            color:
                                ZapitiColors.darkBrown.withValues(alpha: 0.7),
                          );
                        },
                      ),
                      if (disabled)
                        DecoratedBox(
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.34),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.lock_outline,
                              color: ZapitiColors.cardCream,
                            ),
                          ),
                        ),
                      if (badgeLabel != null)
                        Positioned(
                          top: 4,
                          right: 4,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: selected
                                  ? ZapitiColors.oldGold
                                  : ZapitiColors.wineRed,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: ZapitiColors.cardCream.withValues(
                                  alpha: 0.7,
                                ),
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5,
                                vertical: 2,
                              ),
                              child: Text(
                                badgeLabel!,
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(
                                      color: selected
                                          ? ZapitiColors.darkBrown
                                          : ZapitiColors.cardCream,
                                      fontWeight: FontWeight.w900,
                                    ),
                              ),
                            ),
                          ),
                        ),
                    ],
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
                              : disabled
                                  ? ZapitiColors.cardCream.withValues(
                                      alpha: 0.56,
                                    )
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
  final VoidCallback onBack;
  final VoidCallback onStart;

  const _DifficultySelectionScreen({
    required this.selectedDifficulty,
    required this.onSelected,
    required this.onBack,
    required this.onStart,
  });

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
              title: context.tr('chooseDifficulty'),
              subtitle: context.tr(
                'difficultyLevelShort',
                params: {'level': selectedDifficulty},
              ),
            );
            final columns = orientation == Orientation.portrait
                ? (constraints.maxWidth > constraints.maxHeight * 0.72 ? 3 : 2)
                : 3;
            final choices = _DifficultyChoiceGrid(
              selectedDifficulty: selectedDifficulty,
              onSelected: onSelected,
              columns: columns,
            );
            final button = FractionallySizedBox(
              widthFactor: orientation == Orientation.portrait ? 1 : 0.72,
              child: ZapitiActionButton(
                label: context.tr('play'),
                icon: Icons.play_arrow,
                onPressed: onStart,
                primary: true,
              ),
            );
            final backButton = FractionallySizedBox(
              widthFactor: orientation == Orientation.portrait ? 1 : 0.72,
              child: ZapitiActionButton(
                label: context.tr('back'),
                icon: Icons.arrow_back,
                onPressed: onBack,
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
                    Expanded(flex: 40, child: choices),
                    SizedBox(height: gap),
                    Flexible(
                      flex: 20,
                      child: Column(
                        children: [
                          Expanded(child: Center(child: button)),
                          SizedBox(height: gap * 0.5),
                          Expanded(child: Center(child: backButton)),
                        ],
                      ),
                    ),
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
                          flex: 46,
                          child: _SelectedDifficultySummary(profile: profile),
                        ),
                        SizedBox(height: gap),
                        Flexible(
                          flex: 26,
                          child: Column(
                            children: [
                              Expanded(child: Center(child: button)),
                              SizedBox(height: gap * 0.5),
                              Expanded(child: Center(child: backButton)),
                            ],
                          ),
                        ),
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
  const _DifficultyChoiceGrid({
    required this.selectedDifficulty,
    required this.onSelected,
    required this.columns,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final gap = min(constraints.maxWidth, constraints.maxHeight) * 0.035;
        const difficultyCount = 5;
        final rows = (difficultyCount / columns).ceil();
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
            for (var difficulty = 1; difficulty <= difficultyCount; difficulty++)
              _DifficultyChoice(
                difficulty: difficulty,
                selected: difficulty == selectedDifficulty,
                label: _difficultyLabel(context, difficulty),
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
                  context.tr('difficultyLevel', params: {'level': difficulty}),
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
                  _difficultySummary(context, profile.level),
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
                  text: _difficultyCardPlay(context, profile.level),
                ),
                _DifficultySummaryLine(
                  icon: Icons.campaign_outlined,
                  text: _difficultyTrucoPlay(context, profile.level),
                ),
                _DifficultySummaryLine(
                  icon: Icons.visibility_outlined,
                  text: profile.readsOpponentSignals
                      ? context.tr('readsOpponentSignals')
                      : context.tr('ignoresOpponentSignals'),
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
