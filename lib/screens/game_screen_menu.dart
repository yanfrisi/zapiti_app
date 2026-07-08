part of 'game_screen.dart';

class _WoodBackground extends StatelessWidget {
  final Widget child;

  const _WoodBackground({required this.child});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            ZapitiColors.woodDark,
            ZapitiColors.wood,
            ZapitiColors.woodDark,
          ],
          stops: [0, 0.52, 1],
        ),
      ),
      child: CustomPaint(
        painter: const _WoodGrainPainter(),
        child: child,
      ),
    );
  }
}

class _WoodGrainPainter extends CustomPainter {
  const _WoodGrainPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.045)
      ..strokeWidth = max(1, size.shortestSide * 0.003);
    final glowPaint = Paint()
      ..color = ZapitiColors.oldGold.withValues(alpha: 0.03)
      ..strokeWidth = max(1, size.shortestSide * 0.004);

    for (var i = -2; i < 16; i++) {
      final y = size.height * (i / 14);
      final wave = size.shortestSide * 0.025;
      final path = Path()
        ..moveTo(0, y)
        ..cubicTo(
          size.width * 0.28,
          y + wave,
          size.width * 0.62,
          y - wave,
          size.width,
          y + wave * 0.4,
        );
      canvas.drawPath(path, i.isEven ? linePaint : glowPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _MainMenuScreen extends StatelessWidget {
  final VoidCallback onPlay;
  final VoidCallback onTutorial;
  final VoidCallback onOptions;
  final VoidCallback onMultiplayer;
  final VoidCallback onEnterGame;
  final String selectedCharacterId;
  final ValueChanged<String> onSelectedCharacterChanged;
  final VoidCallback onBack;
  final _MainMenuPanel panel;
  final bool audioEnabled;
  final ValueChanged<bool> onAudioChanged;
  final double audioVolume;
  final ValueChanged<double> onAudioVolumeChanged;
  final _BotSpeed botSpeed;
  final ValueChanged<_BotSpeed> onBotSpeedChanged;
  final bool confirmCardPlay;
  final ValueChanged<bool> onConfirmCardPlayChanged;

  const _MainMenuScreen({
    required this.onPlay,
    required this.onTutorial,
    required this.onOptions,
    required this.onMultiplayer,
    required this.onEnterGame,
    required this.selectedCharacterId,
    required this.onSelectedCharacterChanged,
    required this.onBack,
    required this.panel,
    required this.audioEnabled,
    required this.onAudioChanged,
    required this.audioVolume,
    required this.onAudioVolumeChanged,
    required this.botSpeed,
    required this.onBotSpeedChanged,
    required this.confirmCardPlay,
    required this.onConfirmCardPlayChanged,
  });

  @override
  Widget build(BuildContext context) {
    return OrientationBuilder(
      builder: (context, orientation) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final shortest = min(constraints.maxWidth, constraints.maxHeight);
            final gap = shortest * 0.035;
            final padding = EdgeInsets.all(shortest * 0.055);
            final showingPanel = panel != _MainMenuPanel.home;
            final actions = AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: showingPanel
                  ? _MainMenuInfoPanel(
                      key: ValueKey(panel),
                      panel: panel,
                      audioEnabled: audioEnabled,
                      onAudioChanged: onAudioChanged,
                      audioVolume: audioVolume,
                      onAudioVolumeChanged: onAudioVolumeChanged,
                      botSpeed: botSpeed,
                      onBotSpeedChanged: onBotSpeedChanged,
                      confirmCardPlay: confirmCardPlay,
                      onConfirmCardPlayChanged: onConfirmCardPlayChanged,
                      onEnterGame: onEnterGame,
                      selectedCharacterId: selectedCharacterId,
                      onSelectedCharacterChanged: onSelectedCharacterChanged,
                      onBack: onBack,
                    )
                  : _MainMenuActions(
                      key: const ValueKey('main-menu-actions'),
                      onPlay: onPlay,
                      onTutorial: onTutorial,
                      onOptions: onOptions,
                      onMultiplayer: onMultiplayer,
                    ),
            );
            final panelContent = Center(
              child: SizedBox(
                width: min(
                  constraints.maxWidth - padding.horizontal,
                  orientation == Orientation.portrait ? 620.0 : 760.0,
                ),
                height: constraints.maxHeight - padding.vertical,
                child: Center(child: actions),
              ),
            );

            return DecoratedBox(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [ZapitiColors.tableGreen, ZapitiColors.darkBrown],
                ),
              ),
              child: Padding(
                padding: padding,
                child: showingPanel
                    ? panelContent
                    : orientation == Orientation.portrait
                        ? Column(
                            children: [
                              const Expanded(
                                flex: 48,
                                child: _MainMenuLogo(),
                              ),
                              SizedBox(height: gap),
                              Expanded(
                                flex: 52,
                                child: Center(child: actions),
                              ),
                            ],
                          )
                        : Row(
                            children: [
                              const Expanded(
                                flex: 52,
                                child: _MainMenuLogo(),
                              ),
                              SizedBox(width: gap),
                              Expanded(
                                flex: 48,
                                child: Center(child: actions),
                              ),
                            ],
                          ),
              ),
            );
          },
        );
      },
    );
  }
}

class _MainMenuLogo extends StatelessWidget {
  const _MainMenuLogo();

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      widthFactor: 1,
      heightFactor: 1,
      child: FittedBox(
        fit: BoxFit.contain,
        child: Image.asset(
          'assets/menu/portada.png',
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) {
            return Icon(
              Icons.style,
              color: ZapitiColors.oldGold,
              size: MediaQuery.sizeOf(context).shortestSide * 0.24,
            );
          },
        ),
      ),
    );
  }
}

class _MainMenuActions extends StatelessWidget {
  final VoidCallback onPlay;
  final VoidCallback onTutorial;
  final VoidCallback onOptions;
  final VoidCallback onMultiplayer;

  const _MainMenuActions({
    super.key,
    required this.onPlay,
    required this.onTutorial,
    required this.onOptions,
    required this.onMultiplayer,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final gap = min(constraints.maxWidth, constraints.maxHeight) * 0.045;
        final actions = [
          ZapitiActionButton(
            label: 'JUGAR',
            icon: Icons.play_arrow,
            onPressed: onPlay,
            primary: true,
          ),
          ZapitiActionButton(
            label: 'TUTORIAL',
            icon: Icons.menu_book_outlined,
            onPressed: onTutorial,
          ),
          ZapitiActionButton(
            label: 'MULTIJUGADOR',
            icon: Icons.groups_outlined,
            onPressed: onMultiplayer,
          ),
          ZapitiActionButton(
            label: 'OPCIONES',
            icon: Icons.settings_outlined,
            onPressed: onOptions,
          ),
        ];

        return FractionallySizedBox(
          widthFactor: 1,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var index = 0; index < actions.length; index++) ...[
                Flexible(child: actions[index]),
                if (index != actions.length - 1) SizedBox(height: gap),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _MainMenuInfoPanel extends StatelessWidget {
  final _MainMenuPanel panel;
  final bool audioEnabled;
  final ValueChanged<bool> onAudioChanged;
  final double audioVolume;
  final ValueChanged<double> onAudioVolumeChanged;
  final _BotSpeed botSpeed;
  final ValueChanged<_BotSpeed> onBotSpeedChanged;
  final bool confirmCardPlay;
  final ValueChanged<bool> onConfirmCardPlayChanged;
  final VoidCallback onEnterGame;
  final String selectedCharacterId;
  final ValueChanged<String> onSelectedCharacterChanged;
  final VoidCallback onBack;

  const _MainMenuInfoPanel({
    super.key,
    required this.panel,
    required this.audioEnabled,
    required this.onAudioChanged,
    required this.audioVolume,
    required this.onAudioVolumeChanged,
    required this.botSpeed,
    required this.onBotSpeedChanged,
    required this.confirmCardPlay,
    required this.onConfirmCardPlayChanged,
    required this.onEnterGame,
    required this.selectedCharacterId,
    required this.onSelectedCharacterChanged,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final isTutorial = panel == _MainMenuPanel.tutorial;
    final isMultiplayer = panel == _MainMenuPanel.multiplayer;
    final title = switch (panel) {
      _MainMenuPanel.tutorial => 'Tutorial',
      _MainMenuPanel.options => 'Opciones',
      _MainMenuPanel.multiplayer => 'Multijugador',
      _MainMenuPanel.home => '',
    };
    final icon = switch (panel) {
      _MainMenuPanel.tutorial => Icons.menu_book_outlined,
      _MainMenuPanel.options => Icons.settings_outlined,
      _MainMenuPanel.multiplayer => Icons.groups_outlined,
      _MainMenuPanel.home => Icons.play_arrow,
    };

    return LayoutBuilder(
      builder: (context, constraints) {
        final densePanel = constraints.maxHeight < 340;
        final panelPadding = EdgeInsets.symmetric(
          horizontal: densePanel ? 14 : 16,
          vertical: densePanel ? 10 : 16,
        );
        final panelGap = densePanel ? 5.0 : 8.0;

        return Container(
          padding: panelPadding,
          decoration: BoxDecoration(
            color: ZapitiColors.cardCream.withValues(alpha: 0.94),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: ZapitiColors.oldGold, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.32),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(
                    icon,
                    color: ZapitiColors.wineRed,
                    size: densePanel ? 18 : 22,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: ZapitiColors.darkBrown,
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Volver',
                    onPressed: onBack,
                    icon: const Icon(Icons.close),
                    color: ZapitiColors.darkBrown,
                    constraints: const BoxConstraints.tightFor(
                      width: 36,
                      height: 36,
                    ),
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
              SizedBox(height: panelGap),
              Expanded(
                child: isTutorial
                    ? const _MainMenuTutorialContent()
                    : isMultiplayer
                        ? SingleChildScrollView(
                            child: SizedBox(
                              width: double.infinity,
                              child: _MainMenuMultiplayerContent(
                                onEnterGame: onEnterGame,
                                selectedCharacterId: selectedCharacterId,
                                onSelectedCharacterChanged:
                                    onSelectedCharacterChanged,
                              ),
                            ),
                          )
                        : FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.topCenter,
                            child: SizedBox(
                              width: max(0, constraints.maxWidth - 32),
                              child: _MainMenuOptionsContent(
                                audioEnabled: audioEnabled,
                                onAudioChanged: onAudioChanged,
                                audioVolume: audioVolume,
                                onAudioVolumeChanged: onAudioVolumeChanged,
                                botSpeed: botSpeed,
                                onBotSpeedChanged: onBotSpeedChanged,
                                confirmCardPlay: confirmCardPlay,
                                onConfirmCardPlayChanged:
                                    onConfirmCardPlayChanged,
                              ),
                            ),
                          ),
              ),
              SizedBox(height: panelGap),
              ZapitiActionButton(
                label: 'VOLVER',
                icon: Icons.arrow_back,
                onPressed: onBack,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MainMenuTutorialContent extends StatefulWidget {
  const _MainMenuTutorialContent();

  @override
  State<_MainMenuTutorialContent> createState() =>
      _MainMenuTutorialContentState();
}

class _MainMenuTutorialContentState extends State<_MainMenuTutorialContent> {
  int _stepIndex = 0;

  static const _steps = [
    _TutorialStep(
      title: 'Mesa por parejas',
      body: '1. Juegas en pareja contra dos rivales.',
      icon: Icons.groups_outlined,
    ),
    _TutorialStep(
      title: 'Tres rondas',
      body:
          'Cada reparto tiene hasta tres rondas. Gana quien domina las cartas jugadas.',
      icon: Icons.style_outlined,
    ),
    _TutorialStep(
      title: 'Valor de cartas',
      body:
          '4 de bastos -> 7 de copas -> 7 de oros -> as de espadas -> tres -> dos -> as.',
      icon: Icons.workspace_premium_outlined,
    ),
    _TutorialStep(
      title: 'Truco y puntos',
      body:
          'Puedes cantar truco, aceptar, pasar o subir para aumentar el valor del reparto.',
      icon: Icons.campaign_outlined,
    ),
    _TutorialStep(
      title: 'Senas',
      body:
          'Pide sena a tu pareja o usa las tuyas para comunicar cartas fuertes.',
      icon: Icons.visibility_outlined,
    ),
  ];

  void _previousStep() {
    setState(() {
      _stepIndex = (_stepIndex - 1 + _steps.length) % _steps.length;
    });
  }

  void _nextStep() {
    setState(() {
      _stepIndex = (_stepIndex + 1) % _steps.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    final step = _steps[_stepIndex];
    final titleStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
          color: ZapitiColors.darkBrown,
          fontWeight: FontWeight.w900,
        );
    final bodyStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: ZapitiColors.darkBrown.withValues(alpha: 0.86),
          height: 1.2,
          fontWeight: FontWeight.w700,
        );

    return LayoutBuilder(
      builder: (context, constraints) {
        final shortest = MediaQuery.sizeOf(context).shortestSide;
        final maxHeight = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : shortest * 0.62;
        final compact = maxHeight < 300;
        final visualHeight = max(
          compact ? 110.0 : 150.0,
          min(maxHeight * (compact ? 0.55 : 0.72), 280.0),
        );
        final cardWidth = min(
          shortest * 0.22,
          min(visualHeight * 0.74, 110.0),
        );
        final bodyMaxLines = compact ? 1 : 3;

        return Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: ZapitiColors.tableGreen.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: ZapitiColors.oldGold.withValues(alpha: 0.72),
                ),
              ),
              child: SizedBox(
                height: visualHeight,
                width: double.infinity,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child: _TutorialVisual(
                    key: ValueKey(_stepIndex),
                    index: _stepIndex,
                    cardWidth: cardWidth,
                  ),
                ),
              ),
            ),
            SizedBox(height: compact ? 3 : 10),
            Row(
              children: [
                Icon(
                  step.icon,
                  color: ZapitiColors.wineRed,
                  size: compact ? 18 : 24,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    step.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: titleStyle,
                  ),
                ),
              ],
            ),
            SizedBox(height: compact ? 1 : 5),
            Expanded(
              child: Text(
                step.body,
                maxLines: bodyMaxLines,
                overflow: TextOverflow.ellipsis,
                style: bodyStyle,
              ),
            ),
            SizedBox(height: compact ? 6 : 10),
            Row(
              children: [
                IconButton(
                  tooltip: 'Anterior',
                  onPressed: _previousStep,
                  icon: const Icon(Icons.chevron_left),
                  color: ZapitiColors.darkBrown,
                  constraints: BoxConstraints.tightFor(
                    width: compact ? 30 : 44,
                    height: compact ? 26 : 40,
                  ),
                  padding: EdgeInsets.zero,
                ),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var index = 0; index < _steps.length; index++)
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          width: index == _stepIndex
                              ? (compact ? 15 : 18)
                              : (compact ? 6 : 8),
                          height: compact ? 6 : 8,
                          margin: EdgeInsets.symmetric(
                            horizontal: compact ? 2 : 3,
                          ),
                          decoration: BoxDecoration(
                            color: index == _stepIndex
                                ? ZapitiColors.wineRed
                                : ZapitiColors.darkBrown
                                    .withValues(alpha: 0.24),
                            borderRadius: BorderRadius.circular(99),
                          ),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Siguiente',
                  onPressed: _nextStep,
                  icon: const Icon(Icons.chevron_right),
                  color: ZapitiColors.darkBrown,
                  constraints: BoxConstraints.tightFor(
                    width: compact ? 30 : 44,
                    height: compact ? 26 : 40,
                  ),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _TutorialStep {
  final String title;
  final String body;
  final IconData icon;

  const _TutorialStep({
    required this.title,
    required this.body,
    required this.icon,
  });
}

class _TutorialVisual extends StatelessWidget {
  final int index;
  final double cardWidth;

  const _TutorialVisual({
    super.key,
    required this.index,
    required this.cardWidth,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: switch (index) {
          0 => _TutorialTeamsVisual(cardWidth: cardWidth),
          1 => _TutorialRoundsVisual(cardWidth: cardWidth),
          2 => _TutorialCardValueVisual(cardWidth: cardWidth),
          3 => _TutorialTrucoVisual(cardWidth: cardWidth),
          _ => _TutorialSignalsVisual(cardWidth: cardWidth),
        },
      ),
    );
  }
}

class _TutorialTeamsVisual extends StatelessWidget {
  final double cardWidth;

  const _TutorialTeamsVisual({required this.cardWidth});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _TutorialAvatar(
            path: CharacterAssets.neutral('p1'), size: cardWidth * 1.7),
        SizedBox(width: cardWidth * 0.32),
        Icon(Icons.favorite,
            color: ZapitiColors.oldGold, size: cardWidth * 0.52),
        SizedBox(width: cardWidth * 0.32),
        _TutorialAvatar(
            path: CharacterAssets.neutral('p3'), size: cardWidth * 1.7),
        SizedBox(width: cardWidth * 0.75),
        _TutorialAvatar(
            path: CharacterAssets.neutral('p2'), size: cardWidth * 1.45),
        SizedBox(width: cardWidth * 0.22),
        _TutorialAvatar(
            path: CharacterAssets.neutral('p4'), size: cardWidth * 1.45),
      ],
    );
  }
}

class _TutorialRoundsVisual extends StatelessWidget {
  final double cardWidth;

  const _TutorialRoundsVisual({required this.cardWidth});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        ZapitiCardWidget(
          card: const SpanishCard(value: 1, suit: Suit.espadas),
          width: cardWidth,
        ),
        SizedBox(width: cardWidth * 0.14),
        ZapitiCardWidget(
          card: const SpanishCard(value: 7, suit: Suit.oros),
          width: cardWidth,
        ),
        SizedBox(width: cardWidth * 0.14),
        ZapitiCardWidget(
          card: const SpanishCard(value: 3, suit: Suit.copas),
          width: cardWidth,
        ),
        SizedBox(width: cardWidth * 0.38),
        Icon(Icons.emoji_events_outlined,
            color: ZapitiColors.oldGold, size: cardWidth * 0.9),
      ],
    );
  }
}

class _TutorialTrucoVisual extends StatelessWidget {
  final double cardWidth;

  const _TutorialTrucoVisual({required this.cardWidth});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ZapitiCardWidget(
          card: const SpanishCard(value: 12, suit: Suit.copas),
          width: cardWidth,
        ),
        SizedBox(width: cardWidth * 0.38),
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: cardWidth * 0.28,
            vertical: cardWidth * 0.18,
          ),
          decoration: BoxDecoration(
            color: ZapitiColors.wineRed,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: ZapitiColors.oldGold, width: 2),
          ),
          child: Text(
            'TRUCO',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: ZapitiColors.cardCream,
                  fontWeight: FontWeight.w900,
                ),
          ),
        ),
        SizedBox(width: cardWidth * 0.25),
        Icon(Icons.arrow_upward,
            color: ZapitiColors.oldGold, size: cardWidth * 0.72),
      ],
    );
  }
}

class _TutorialCardValueVisual extends StatelessWidget {
  final double cardWidth;

  const _TutorialCardValueVisual({required this.cardWidth});

  @override
  Widget build(BuildContext context) {
    final labelStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
          color: ZapitiColors.cardCream,
          fontWeight: FontWeight.w900,
        );
    final cards = [
      const SpanishCard(value: 4, suit: Suit.bastos),
      const SpanishCard(value: 7, suit: Suit.copas),
      const SpanishCard(value: 7, suit: Suit.oros),
      const SpanishCard(value: 1, suit: Suit.espadas),
      const SpanishCard(value: 3, suit: Suit.copas),
      const SpanishCard(value: 2, suit: Suit.oros),
      const SpanishCard(value: 1, suit: Suit.bastos),
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var index = 0; index < cards.length; index++) ...[
                ZapitiCardWidget(
                  card: cards[index],
                  width: cardWidth,
                ),
                if (index != cards.length - 1)
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: cardWidth * 0.08),
                    child: Icon(
                      Icons.chevron_right,
                      color: ZapitiColors.oldGold,
                      size: cardWidth * 0.48,
                    ),
                  ),
              ],
            ],
          ),
        ),
        SizedBox(height: cardWidth * 0.18),
        Text('Orden principal', style: labelStyle),
        SizedBox(height: cardWidth * 0.12),
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: cardWidth * 0.22,
            vertical: cardWidth * 0.12,
          ),
          decoration: BoxDecoration(
            color: ZapitiColors.darkBrown.withValues(alpha: 0.22),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: ZapitiColors.oldGold.withValues(alpha: 0.36),
            ),
          ),
          child: Text(
            'Luego: 12 > 11 > 10 > 6 > 5 > 4',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: labelStyle,
          ),
        ),
      ],
    );
  }
}

class _TutorialSignalsVisual extends StatelessWidget {
  final double cardWidth;

  const _TutorialSignalsVisual({required this.cardWidth});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _TutorialAvatar(
          path: CharacterAssets.frontForSignal('p1', '7 Oros'),
          size: cardWidth * 1.75,
        ),
        SizedBox(width: cardWidth * 0.26),
        Icon(Icons.visibility_outlined,
            color: ZapitiColors.oldGold, size: cardWidth * 0.7),
        SizedBox(width: cardWidth * 0.26),
        ZapitiCardWidget(
          card: const SpanishCard(value: 7, suit: Suit.oros),
          width: cardWidth,
        ),
      ],
    );
  }
}

class _TutorialAvatar extends StatelessWidget {
  final String path;
  final double size;

  const _TutorialAvatar({
    required this.path,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size * 1.22,
      decoration: BoxDecoration(
        color: ZapitiColors.cardCream,
        borderRadius: BorderRadius.circular(8),
        border:
            Border.all(color: ZapitiColors.darkBrown.withValues(alpha: 0.22)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.asset(
        path,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Icon(
          Icons.person,
          color: ZapitiColors.darkBrown,
          size: size * 0.58,
        ),
      ),
    );
  }
}

class _MainMenuMultiplayerContent extends StatefulWidget {
  final VoidCallback onEnterGame;
  final String selectedCharacterId;
  final ValueChanged<String> onSelectedCharacterChanged;

  const _MainMenuMultiplayerContent({
    required this.onEnterGame,
    required this.selectedCharacterId,
    required this.onSelectedCharacterChanged,
  });

  @override
  State<_MainMenuMultiplayerContent> createState() =>
      _MainMenuMultiplayerContentState();
}

class _MainMenuMultiplayerContentState
    extends State<_MainMenuMultiplayerContent> {
  final TextEditingController _serverController =
      TextEditingController(text: ServerConfig.websocketUrl);
  final TextEditingController _nameController =
      TextEditingController(text: 'Jugador');
  final TextEditingController _roomController = TextEditingController();
  GameSocket? _socket;
  String? _playerId;
  String? _connectedRoomId;
  MultiplayerRoomSnapshot? _roomSnapshot;
  bool _keepSocketAliveOnDispose = false;
  bool _connecting = false;
  Future<bool>? _pendingConnection;
  int _connectionGeneration = 0;
  bool _sessionStarted = false;
  bool _autoEnterQueued = false;
  _ServerConnectionState _connectionState = _ServerConnectionState.idle;
  String _status = 'Prepara una sala para conectar a amigos.';
  bool _ready = false;
  late String _selectedCharacterId;
  String? _confirmedCharacterId;

  @override
  void initState() {
    super.initState();
    _selectedCharacterId = widget.selectedCharacterId;
    _confirmedCharacterId = widget.selectedCharacterId;

    final session = MultiplayerSessionStore.instance;
    if (session.socket != null && session.socket!.isConnected) {
      _socket = session.socket;
      _playerId = session.localGamePlayerId;
      _roomSnapshot = session.roomSnapshot;
      _connectedRoomId = session.roomSnapshot?.roomId;
      if (session.roomSnapshot?.roomId != null) {
        _roomController.text = session.roomSnapshot!.roomId;
      }
      _sessionStarted = session.roomSnapshot?.phase != 'lobby';
      _connectionState = _ServerConnectionState.connected;
      _status = 'Conectado a la sala.';

      final mySeat = session.roomSnapshot?.seats.firstWhere(
        (seat) => seat.playerId == session.localGamePlayerId,
        orElse: () => const MultiplayerSeat(
          playerId: '',
          name: '',
          seatIndex: -1,
          ready: false,
          connected: false,
        ),
      );
      if (mySeat != null && mySeat.playerId.isNotEmpty) {
        _ready = mySeat.ready;
      }

      _socket!.onMessage = _handleSocketMessage;
      _socket!.onError = (error) {
        _clearSessionAfterConnectionLoss('Error de conexion: $error');
      };
      _socket!.onDone = () {
        _clearSessionAfterConnectionLoss('Servidor desconectado.');
      };
    }
  }

  @override
  void didUpdateWidget(covariant _MainMenuMultiplayerContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedCharacterId != oldWidget.selectedCharacterId &&
        widget.selectedCharacterId != _selectedCharacterId) {
      _selectedCharacterId = widget.selectedCharacterId;
      _confirmedCharacterId = widget.selectedCharacterId;
    }
  }

  @override
  void dispose() {
    if (!_keepSocketAliveOnDispose) {
      _closeSocketIntentionally();
    }
    _serverController.dispose();
    _nameController.dispose();
    _roomController.dispose();
    super.dispose();
  }

  String get _playerName => _nameController.text.trim();

  bool get _serverUrlIsEditable => ServerConfig.useLocalServer;

  String get _serverUrl {
    if (_serverUrlIsEditable) {
      return _serverController.text.trim();
    }
    return ServerConfig.websocketUrl;
  }

  String get _localPlayerId =>
      _playerId ??= 'player_${DateTime.now().millisecondsSinceEpoch}';

  void _setConnectionState(
    _ServerConnectionState state, {
    required String status,
  }) {
    if (!mounted) return;
    setState(() {
      _connectionState = state;
      _status = status;
      _connecting = state == _ServerConnectionState.connecting ||
          state == _ServerConnectionState.wakingServer ||
          state == _ServerConnectionState.reconnecting;
    });
  }

  void _clearSessionAfterConnectionLoss(
    String status, {
    bool preserveSocket = false,
    _ServerConnectionState connectionState =
        _ServerConnectionState.disconnected,
  }) {
    setState(() {
      if (!preserveSocket) {
        _socket = null;
      }
      _keepSocketAliveOnDispose = false;
      _sessionStarted = false;
      _roomSnapshot = null;
      _connectedRoomId = null;
      _playerId = null;
      _ready = false;
      _autoEnterQueued = false;
      _connectionState = connectionState;
      _connecting = false;
      _status = status;
    });
  }

  void _closeSocketIntentionally() {
    final socket = _socket;
    if (socket == null) return;
    _connectionGeneration += 1;
    _pendingConnection = null;
    _socket = null;
    socket.close();
  }

  String? _localSeatCharacterId() {
    final roomId = _connectedRoomId ?? _roomController.text.trim();
    final snapshot = _roomSnapshot;
    if (roomId.isEmpty || snapshot == null) return null;
    final localId = _playerId;
    if (localId == null) return null;
    final seat = snapshot.seats.firstWhere(
      (entry) => entry.playerId == localId,
      orElse: () => const MultiplayerSeat(
        playerId: '',
        name: '',
        seatIndex: -1,
        ready: false,
        connected: false,
      ),
    );
    return seat.playerId.isEmpty ? null : seat.characterId;
  }

  void _syncSelectedCharacterFromRoom() {
    final characterId = _localSeatCharacterId();
    if (characterId == null) return;
    setState(() {
      _selectedCharacterId = characterId;
      _confirmedCharacterId = characterId;
    });
    widget.onSelectedCharacterChanged(characterId);
  }

  void _revertSelectedCharacter() {
    final confirmed = _confirmedCharacterId;
    if (confirmed == null || confirmed == _selectedCharacterId) return;
    setState(() {
      _selectedCharacterId = confirmed;
    });
    widget.onSelectedCharacterChanged(confirmed);
  }

  void _selectCharacter(String characterId) {
    setState(() {
      _selectedCharacterId = characterId;
    });
    widget.onSelectedCharacterChanged(characterId);
    unawaited(_sendCharacterSelection(characterId));
  }

  Future<void> _sendCharacterSelection(String characterId) async {
    final socket = _socket;
    final roomId = _connectedRoomId ?? _roomController.text.trim();
    if (socket == null ||
        !socket.isConnected ||
        roomId.isEmpty ||
        _playerId == null ||
        _roomSnapshot?.phase != 'lobby') {
      return;
    }

    try {
      socket.selectCharacter(
        roomId: roomId,
        playerId: _playerId!,
        characterId: characterId,
      );
      setState(() {
        _status =
            'Personaje enviado: ${CharacterAssets.displayNames[characterId] ?? characterId}.';
      });
    } catch (error) {
      setState(() {
        _status = 'No se pudo enviar el personaje: $error';
      });
    }
  }

  Future<bool> _ensureConnected() async {
    final socket = _socket;
    if (socket != null && socket.isConnected) {
      return true;
    }

    final pending = _pendingConnection;
    if (pending != null) {
      return pending;
    }

    final future = _connectWithRetries();
    _pendingConnection = future;
    try {
      return await future;
    } finally {
      if (identical(_pendingConnection, future)) {
        _pendingConnection = null;
      }
    }
  }

  Future<bool> _connectWithRetries({
    bool fromConnectionLoss = false,
  }) async {
    final serverUrl = _serverUrl;
    if (serverUrl.isEmpty) {
      _setConnectionState(
        _ServerConnectionState.error,
        status: 'Escribe la direccion del servidor.',
      );
      return false;
    }

    final attemptLabels = [
      _ServerConnectionState.connecting,
      if (ServerConfig.useLocalServer)
        _ServerConnectionState.reconnecting
      else
        _ServerConnectionState.wakingServer,
      _ServerConnectionState.reconnecting,
      _ServerConnectionState.reconnecting,
    ];
    final attemptStatuses = [
      'Conectando al servidor...',
      if (ServerConfig.useLocalServer)
        'Reconectando...'
      else
        'El servidor gratuito esta arrancando. Esto puede tardar unos segundos...',
      'Reconectando...',
      'Reconectando...',
    ];
    const attemptDelays = [
      Duration.zero,
      Duration(seconds: 2),
      Duration(seconds: 5),
      Duration(seconds: 10),
    ];
    const attemptTimeout = Duration(seconds: 18);

    final generation = ++_connectionGeneration;
    final previousSocket = _socket;
    _socket = null;
    previousSocket?.close();

    Object? lastError;
    for (var attempt = 0; attempt < attemptDelays.length; attempt++) {
      if (!mounted || generation != _connectionGeneration) {
        return false;
      }

      final delay = attemptDelays[attempt];
      if (delay > Duration.zero) {
        await Future<void>.delayed(delay);
        if (!mounted || generation != _connectionGeneration) {
          return false;
        }
      }

      _setConnectionState(
        attemptLabels[attempt],
        status: attemptStatuses[attempt],
      );

      final nextSocket = GameSocket(serverUrl);
      nextSocket.onMessage = _handleSocketMessage;
      nextSocket.onError = (error) {
        if (!mounted || generation != _connectionGeneration) return;
        _handleSocketDropped('Error de conexion: $error');
      };
      nextSocket.onDone = () {
        if (!mounted || generation != _connectionGeneration) return;
        _handleSocketDropped('Conexion cerrada.');
      };

      try {
        await nextSocket.connect(timeout: attemptTimeout);
        if (!mounted || generation != _connectionGeneration) {
          nextSocket.close();
          return false;
        }

        _socket = nextSocket;
        _setConnectionState(
          _ServerConnectionState.connected,
          status: fromConnectionLoss
              ? 'Conectado al servidor.'
              : 'Conectado al servidor. Esperando respuesta de la sala...',
        );
        return true;
      } catch (error) {
        lastError = error;
        nextSocket.close();
        if (attempt == attemptDelays.length - 1) {
          break;
        }
      }
    }

    if (!mounted || generation != _connectionGeneration) {
      return false;
    }

    _setConnectionState(
      _ServerConnectionState.error,
      status: lastError == null
          ? 'No se pudo conectar al servidor.'
          : 'No se pudo conectar al servidor: $lastError',
    );
    return false;
  }

  void _handleSocketDropped(String reason) {
    final hadSession = _sessionStarted || _roomSnapshot != null;
    if (hadSession) {
      _setConnectionState(
        _ServerConnectionState.reconnecting,
        status: 'La conexion se ha cerrado. Reintentando...',
      );
      unawaited(_recoverAfterConnectionLoss());
      return;
    }

    _clearSessionAfterConnectionLoss(reason);
  }

  Future<void> _recoverAfterConnectionLoss() async {
    final reconnected = await _connectWithRetries(fromConnectionLoss: true);
    if (!mounted) return;

    if (!reconnected) {
      _clearSessionAfterConnectionLoss(
        'No se pudo reconectar al servidor. La partida anterior no se puede recuperar.',
      );
      return;
    }

    _clearSessionAfterConnectionLoss(
      'Conexion restablecida. La partida anterior no se puede recuperar. Vuelve a crear o unirte de nuevo.',
      preserveSocket: true,
      connectionState: _ServerConnectionState.connected,
    );
  }

  void _handleSocketMessage(MultiplayerMessage message) {
    if (!mounted) return;

    switch (message.type) {
      case MultiplayerMessageType.roomSnapshot:
        final snapshot = MultiplayerRoomSnapshot.fromJson(message.payload);
        setState(() {
          _roomSnapshot = snapshot;
          _connectedRoomId = snapshot.roomId;
          _roomController.text = snapshot.roomId;
          if (message.playerId != null && message.playerId!.isNotEmpty) {
            _playerId = message.playerId;
          }
          _sessionStarted = snapshot.phase != 'lobby';
          _connectionState = _ServerConnectionState.connected;
          _status = switch (snapshot.phase) {
            'starting' => 'Todos listos. La partida esta arrancando.',
            'playing' => 'Partida en curso.',
            _ => 'Sala ${snapshot.roomId} sincronizada.',
          };
        });
        MultiplayerSessionStore.instance.roomSnapshot = snapshot;
        _syncSelectedCharacterFromRoom();
        _maybeAutoEnterGame();
        break;
      case MultiplayerMessageType.error:
        setState(() {
          final code = message.payload['code']?.toString() ?? 'error';
          final text =
              message.payload['message']?.toString() ?? 'Error del servidor';
          _status = switch (code) {
            'room_not_found' =>
              'La sala ya no existe. El servidor pudo haberse reiniciado.',
            _ => 'Servidor: $code - $text',
          };
        });
        if (message.payload['code']?.toString() == 'character_taken' ||
            message.payload['code']?.toString() == 'room_in_progress') {
          _revertSelectedCharacter();
        }
        break;
      case MultiplayerMessageType.startGame:
        MultiplayerSessionStore.instance.localGamePlayerId = message.playerId;
        MultiplayerSessionStore.instance.matchStarted = true;
        MultiplayerSessionStore.instance.players =
            _parsePlayers(message.payload['players']);
        MultiplayerSessionStore.instance.characterIdsByPlayer =
            _parseCharacterIdsByPlayer(message.payload['players']);
        MultiplayerSessionStore.instance.seed = message.payload['seed'] as int?;
        MultiplayerSessionStore.instance.controlledPlayerIds =
            _parseControlledPlayerIds(message.payload['controlledPlayerIds']);
        MultiplayerSessionStore.instance.fixedHands =
            _parseFixedHands(message.payload['fixedHands']);
        setState(() {
          _sessionStarted = true;
          _connectionState = _ServerConnectionState.connected;
          _status = 'La partida va a empezar. Abriendo la mesa...';
        });
        _maybeAutoEnterGame();
        break;
      default:
        setState(() {
          _status = 'Mensaje recibido: ${message.type.wireName}';
        });
        break;
    }
  }

  Future<void> _createRoom() async {
    final playerName = _playerName;
    if (playerName.isEmpty) {
      setState(() {
        _status = 'Escribe tu nombre antes de crear la sala.';
      });
      return;
    }

    if (!await _ensureConnected()) {
      return;
    }

    final socket = _socket;
    if (socket == null) return;

    setState(() {
      _connectedRoomId = null;
      _ready = false;
      _status = 'Solicitando creacion de sala...';
    });

    try {
      socket.createRoom(
        playerId: _localPlayerId,
        playerName: playerName,
        characterId: _selectedCharacterId,
      );
      setState(() {
        _status = 'Solicitud enviada. Esperando sala...';
      });
    } catch (error) {
      setState(() {
        _status = 'No se pudo crear la sala: $error';
      });
    }
  }

  Future<void> _joinRoom() async {
    final roomCode = _roomController.text.trim();
    final playerName = _playerName;

    if (roomCode.isEmpty) {
      setState(() {
        _status = 'Escribe un codigo de sala para unirte.';
      });
      return;
    }

    if (playerName.isEmpty) {
      setState(() {
        _status = 'Escribe tu nombre antes de unirte.';
      });
      return;
    }

    if (!await _ensureConnected()) {
      return;
    }

    final socket = _socket;
    if (socket == null) return;

    setState(() {
      _connectedRoomId = roomCode;
      _ready = false;
      _status = 'Intentando unirme a $roomCode...';
    });

    try {
      socket.joinRoom(
        roomId: roomCode,
        playerId: _localPlayerId,
        playerName: playerName,
        characterId: _selectedCharacterId,
      );
      setState(() {
        _status = 'Solicitud enviada a $roomCode.';
      });
    } catch (error) {
      setState(() {
        _status = 'No se pudo unir a la sala: $error';
      });
    }
  }

  Future<void> _toggleReady() async {
    final socket = _socket;
    final roomId = _connectedRoomId ?? _roomController.text.trim();
    if (socket == null || !socket.isConnected || roomId.isEmpty) {
      setState(() {
        _status = 'Conecta o entra en una sala antes de marcar listo.';
      });
      return;
    }

    final nextReady = !_ready;
    setState(() {
      _ready = nextReady;
      _status = nextReady
          ? 'Marcado como listo. Esperando al resto de jugadores.'
          : 'Listo cancelado.';
    });

    try {
      socket.setReady(
        roomId: roomId,
        playerId: _localPlayerId,
        ready: nextReady,
      );
    } catch (error) {
      setState(() {
        _status = 'No se pudo actualizar el estado listo: $error';
      });
    }
  }

  Future<void> _leaveRoom() async {
    final socket = _socket;
    final roomId = _connectedRoomId ?? _roomController.text.trim();
    final playerId = _playerId;

    try {
      if (socket != null &&
          socket.isConnected &&
          roomId.isNotEmpty &&
          playerId != null &&
          playerId.isNotEmpty) {
        socket.leaveRoom(roomId: roomId, playerId: playerId);
      }
    } catch (_) {
      // Si el leave falla, cerramos igualmente la conexion local.
    }

    _closeSocketIntentionally();

    if (!mounted) return;
    setState(() {
      _socket = null;
      _playerId = null;
      _connectedRoomId = null;
      _roomSnapshot = null;
      _sessionStarted = false;
      _ready = false;
      _connectionState = _ServerConnectionState.disconnected;
      _connecting = false;
      _status = 'Has salido de la sala.';
    });
    _autoEnterQueued = false;
    MultiplayerSessionStore.instance.clearAll();
  }

  void _maybeAutoEnterGame() {
    if (_autoEnterQueued || !_sessionStarted || _socket == null) {
      return;
    }
    if (!_multiplayerSessionReadyForGame()) {
      return;
    }
    if (_roomSnapshot == null || _keepSocketAliveOnDispose) {
      return;
    }

    _autoEnterQueued = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        _autoEnterQueued = false;
        return;
      }
      if (_keepSocketAliveOnDispose ||
          !_sessionStarted ||
          _socket == null ||
          _roomSnapshot == null) {
        _autoEnterQueued = false;
        return;
      }
      _enterGame();
    });
  }

  void _enterGame() {
    if (!_sessionStarted ||
        _socket == null ||
        !_multiplayerSessionReadyForGame()) {
      setState(() {
        _status = 'Esperando los datos de la partida...';
      });
      return;
    }

    setState(() {
      _keepSocketAliveOnDispose = true;
      _autoEnterQueued = false;
      MultiplayerSessionStore.instance.socket = _socket;
      MultiplayerSessionStore.instance.roomSnapshot = _roomSnapshot;
      _status = 'Abriendo la mesa...';
    });

    widget.onEnterGame();
  }

  bool _multiplayerSessionReadyForGame() {
    final session = MultiplayerSessionStore.instance;
    return session.matchStarted &&
        session.localGamePlayerId != null &&
        session.players.isNotEmpty;
  }

  Map<String, List<SpanishCard>>? _parseFixedHands(dynamic rawHands) {
    if (rawHands is! Map) return null;

    return {
      for (final entry in rawHands.entries)
        entry.key.toString(): [
          for (final rawCard in (entry.value as List<dynamic>? ?? const []))
            cardFromJson(rawCard as Map<String, dynamic>),
        ],
    };
  }

  List<String> _parseControlledPlayerIds(dynamic rawIds) {
    if (rawIds is! List) return const [];
    return [
      for (final rawId in rawIds)
        if (rawId != null) rawId.toString(),
    ];
  }

  List<Player> _parsePlayers(dynamic rawPlayers) {
    if (rawPlayers is! List) return const [];
    return [
      for (final rawPlayer in rawPlayers)
        if (rawPlayer is Map)
          Player(
            id: rawPlayer['playerId']?.toString() ?? '',
            name: rawPlayer['name']?.toString() ?? 'Jugador',
            teamId: rawPlayer['teamId'] as int? ?? 1,
          ),
    ].where((player) => player.id.isNotEmpty).toList();
  }

  Map<String, String> _parseCharacterIdsByPlayer(dynamic rawPlayers) {
    if (rawPlayers is! List) return const {};
    final parsed = <String, String>{};
    for (final rawPlayer in rawPlayers) {
      if (rawPlayer is! Map) continue;
      final playerId = rawPlayer['playerId']?.toString();
      final characterId = rawPlayer['characterId']?.toString();
      if (playerId == null ||
          playerId.isEmpty ||
          characterId == null ||
          characterId.isEmpty) {
        continue;
      }
      parsed[playerId] = characterId;
    }
    return parsed;
  }

  @override
  Widget build(BuildContext context) {
    final titleStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
          color: ZapitiColors.darkBrown,
          fontWeight: FontWeight.w900,
        );
    final bodyStyle = Theme.of(context).textTheme.bodyMedium!.copyWith(
          color: ZapitiColors.darkBrown.withValues(alpha: 0.82),
          height: 1.25,
          fontWeight: FontWeight.w700,
        );

    final showSession = _sessionStarted && _roomSnapshot != null;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 180),
      child: showSession
          ? _MultiplayerSessionView(
              key: const ValueKey('multiplayer-session'),
              snapshot: _roomSnapshot!,
              playerId: _playerId,
              status: _status,
              canEnterGame: _multiplayerSessionReadyForGame(),
              onEnterGame: _enterGame,
              onLeaveRoom: _leaveRoom,
            )
          : Column(
              key: const ValueKey('multiplayer-lobby'),
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Lobby multijugador', style: titleStyle),
                const SizedBox(height: 8),
                Text(
                  'Primer paso: preparar sala, codigo e intercambio de acciones por WebSocket.',
                  style: bodyStyle,
                ),
                const SizedBox(height: 10),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: ZapitiColors.darkBrown.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: ZapitiColors.darkBrown.withValues(alpha: 0.12),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _connectionState.icon,
                          size: 18,
                          color: ZapitiColors.wineRed,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _connectionState.label,
                          style: bodyStyle.copyWith(
                            color: ZapitiColors.darkBrown,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _status,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.right,
                            style: bodyStyle.copyWith(
                              fontSize: ((bodyStyle.fontSize ?? 12) * 0.9),
                              color: ZapitiColors.darkBrown.withValues(
                                alpha: 0.82,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                if (_serverUrlIsEditable)
                  TextField(
                    controller: _serverController,
                    decoration: const InputDecoration(
                      isDense: true,
                      labelText: 'Servidor',
                      prefixIcon: Icon(Icons.dns_outlined),
                      border: OutlineInputBorder(),
                    ),
                  )
                else
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('Servidor', style: bodyStyle),
                      const SizedBox(height: 4),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: ZapitiColors.darkBrown.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: ZapitiColors.darkBrown.withValues(alpha: 0.12),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 12,
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.cloud_outlined,
                                  color: ZapitiColors.wineRed),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  ServerConfig.websocketUrl,
                                  style: bodyStyle.copyWith(
                                    color: ZapitiColors.darkBrown,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 8),
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    isDense: true,
                    labelText: 'Nombre',
                    prefixIcon: Icon(Icons.person_outline),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _roomController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    isDense: true,
                    labelText: 'Codigo de sala',
                    prefixIcon: Icon(Icons.tag_outlined),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Personaje: ${CharacterAssets.displayNames[_selectedCharacterId] ?? _selectedCharacterId}',
                  style: bodyStyle.copyWith(
                    color: ZapitiColors.darkBrown,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                SizedBox(
                  height: 138,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return _CharacterChoiceGrid(
                        selectedCharacterId: _selectedCharacterId,
                        onSelected: _selectCharacter,
                        columns: constraints.maxWidth > 360 ? 4 : 2,
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 42,
                        child: ZapitiActionButton(
                          label: 'CREAR',
                          icon: Icons.add,
                          onPressed: _connecting ? null : _createRoom,
                          primary: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SizedBox(
                        height: 42,
                        child: ZapitiActionButton(
                          label: 'UNIRSE',
                          icon: Icons.login,
                          onPressed: _connecting ? null : _joinRoom,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 42,
                  child: ZapitiActionButton(
                    label: _ready ? 'LISTO' : 'MARCAR LISTO',
                    icon: _ready
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    onPressed: _toggleReady,
                    primary: _ready,
                  ),
                ),
                const SizedBox(height: 10),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: ZapitiColors.darkBrown.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: ZapitiColors.darkBrown.withValues(alpha: 0.12),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text(_status, style: bodyStyle),
                  ),
                ),
              ],
            ),
    );
  }
}

class _MultiplayerSessionView extends StatelessWidget {
  final MultiplayerRoomSnapshot snapshot;
  final String? playerId;
  final String status;
  final bool canEnterGame;
  final VoidCallback onEnterGame;
  final VoidCallback onLeaveRoom;

  const _MultiplayerSessionView({
    super.key,
    required this.snapshot,
    required this.playerId,
    required this.status,
    required this.canEnterGame,
    required this.onEnterGame,
    required this.onLeaveRoom,
  });

  @override
  Widget build(BuildContext context) {
    final titleStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
          color: ZapitiColors.darkBrown,
          fontWeight: FontWeight.w900,
        );
    final bodyStyle = Theme.of(context).textTheme.bodyMedium!.copyWith(
          color: ZapitiColors.darkBrown.withValues(alpha: 0.84),
          height: 1.22,
          fontWeight: FontWeight.w700,
        );
    final phaseLabel = switch (snapshot.phase) {
      'starting' => 'Arrancando',
      'playing' => 'En partida',
      'finished' => 'Finalizada',
      _ => 'Sala abierta',
    };
    final createdAt = DateTime.fromMillisecondsSinceEpoch(snapshot.createdAt)
        .toLocal()
        .toString();
    final listHeight = (MediaQuery.sizeOf(context).height * 0.22)
        .clamp(140.0, 240.0)
        .toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Icon(Icons.groups_outlined, color: ZapitiColors.wineRed),
            const SizedBox(width: 8),
            Expanded(
              child: Text('Partida multijugador', style: titleStyle),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text('Sala ${snapshot.roomId} - $phaseLabel', style: bodyStyle),
        const SizedBox(height: 4),
        Text('Creada: $createdAt', style: bodyStyle),
        const SizedBox(height: 4),
        Text(
          'Parejas fijas: asientos 1 y 3 juntos, asientos 2 y 4 juntos.',
          style: bodyStyle.copyWith(
            fontSize: ((bodyStyle.fontSize ?? 12) * 0.9),
            color: ZapitiColors.darkBrown.withValues(alpha: 0.72),
          ),
        ),
        const SizedBox(height: 8),
        DecoratedBox(
          decoration: BoxDecoration(
            color: ZapitiColors.darkBrown.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: ZapitiColors.darkBrown.withValues(alpha: 0.12),
            ),
          ),
          child: SizedBox(
            height: listHeight,
            child: ListView.separated(
              padding: const EdgeInsets.all(8),
              itemCount: snapshot.seats.length,
              separatorBuilder: (_, __) => const SizedBox(height: 6),
              itemBuilder: (context, index) {
                final seat = snapshot.seats[index];
                final isSelf = seat.playerId == playerId;
                final teamId = seat.teamId ?? (seat.seatIndex.isEven ? 1 : 2);
                return DecoratedBox(
                  decoration: BoxDecoration(
                    color: isSelf
                        ? ZapitiColors.oldGold.withValues(alpha: 0.22)
                        : Colors.white.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelf
                          ? ZapitiColors.wineRed.withValues(alpha: 0.35)
                          : ZapitiColors.darkBrown.withValues(alpha: 0.12),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 46,
                          child: Text(
                            '#${seat.seatIndex + 1}',
                            style: bodyStyle.copyWith(
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                seat.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: bodyStyle,
                              ),
                              Text(
                                CharacterAssets
                                        .displayNames[seat.characterId] ??
                                    'Sin personaje',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: bodyStyle.copyWith(
                                  fontSize: ((bodyStyle.fontSize ?? 12) * 0.86),
                                  color: ZapitiColors.wineRed.withValues(
                                    alpha: 0.86,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Equipo $teamId',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: bodyStyle.copyWith(
                                  fontSize: ((bodyStyle.fontSize ?? 12) * 0.82),
                                  color: teamId == 1
                                      ? ZapitiColors.wineRed.withValues(
                                          alpha: 0.84,
                                        )
                                      : ZapitiColors.darkBrown.withValues(
                                          alpha: 0.7,
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          seat.connected ? Icons.circle : Icons.circle_outlined,
                          size: 12,
                          color: seat.connected
                              ? Colors.green.shade700
                              : Colors.red.shade700,
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          seat.ready
                              ? Icons.check_circle
                              : Icons.radio_button_unchecked,
                          size: 18,
                          color: seat.ready
                              ? ZapitiColors.wineRed
                              : ZapitiColors.darkBrown.withValues(alpha: 0.35),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(status, style: bodyStyle),
        const SizedBox(height: 8),
        if (canEnterGame)
          SizedBox(
            height: 42,
            child: ZapitiActionButton(
              label: 'ENTRAR A JUGAR',
              icon: Icons.play_arrow,
              onPressed: onEnterGame,
              primary: true,
            ),
          ),
        const SizedBox(height: 8),
        SizedBox(
          height: 42,
          child: ZapitiActionButton(
            label: 'SALIR DE LA SALA',
            icon: Icons.logout,
            onPressed: onLeaveRoom,
            primary: true,
          ),
        ),
      ],
    );
  }
}

class _MainMenuOptionsContent extends StatelessWidget {
  final bool audioEnabled;
  final ValueChanged<bool> onAudioChanged;
  final double audioVolume;
  final ValueChanged<double> onAudioVolumeChanged;
  final _BotSpeed botSpeed;
  final ValueChanged<_BotSpeed> onBotSpeedChanged;
  final bool confirmCardPlay;
  final ValueChanged<bool> onConfirmCardPlayChanged;

  const _MainMenuOptionsContent({
    required this.audioEnabled,
    required this.onAudioChanged,
    required this.audioVolume,
    required this.onAudioVolumeChanged,
    required this.botSpeed,
    required this.onBotSpeedChanged,
    required this.confirmCardPlay,
    required this.onConfirmCardPlayChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _MainMenuSwitchOption(
            title: 'Audio',
            icon: audioEnabled
                ? Icons.volume_up_outlined
                : Icons.volume_off_outlined,
            value: audioEnabled,
            onChanged: onAudioChanged,
          ),
          Padding(
            padding: const EdgeInsets.only(left: 4, right: 4, bottom: 8),
            child: Row(
              children: [
                Icon(
                  Icons.volume_down_outlined,
                  color: ZapitiColors.wineRed.withValues(
                    alpha: audioEnabled ? 1 : 0.38,
                  ),
                ),
                Expanded(
                  child: Slider(
                    value: audioVolume,
                    onChanged: audioEnabled ? onAudioVolumeChanged : null,
                    activeColor: ZapitiColors.wineRed,
                    inactiveColor:
                        ZapitiColors.darkBrown.withValues(alpha: 0.18),
                  ),
                ),
                SizedBox(
                  width: 42,
                  child: Text(
                    '${(audioVolume * 100).round()}%',
                    textAlign: TextAlign.right,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: ZapitiColors.darkBrown.withValues(
                            alpha: audioEnabled ? 0.82 : 0.38,
                          ),
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                ),
              ],
            ),
          ),
          _MainMenuSwitchOption(
            title: 'Confirmar jugada',
            icon: Icons.touch_app_outlined,
            value: confirmCardPlay,
            onChanged: onConfirmCardPlayChanged,
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Velocidad de bots',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: ZapitiColors.darkBrown,
                    fontWeight: FontWeight.w900,
                  ),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final speed in _BotSpeed.values)
                ChoiceChip(
                  label: Text(speed.label),
                  selected: botSpeed == speed,
                  onSelected: (_) => onBotSpeedChanged(speed),
                  selectedColor: ZapitiColors.oldGold,
                  backgroundColor: Colors.white.withValues(alpha: 0.72),
                  labelStyle: TextStyle(
                    color: botSpeed == speed
                        ? ZapitiColors.darkBrown
                        : ZapitiColors.darkBrown.withValues(alpha: 0.78),
                    fontWeight: FontWeight.w900,
                  ),
                  side: BorderSide(
                    color: botSpeed == speed
                        ? ZapitiColors.wineRed
                        : ZapitiColors.darkBrown.withValues(alpha: 0.18),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MainMenuSwitchOption extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _MainMenuSwitchOption({
    required this.title,
    required this.icon,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile.adaptive(
      value: value,
      onChanged: onChanged,
      dense: true,
      contentPadding: EdgeInsets.zero,
      activeThumbColor: ZapitiColors.wineRed,
      activeTrackColor: ZapitiColors.oldGold.withValues(alpha: 0.46),
      title: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: ZapitiColors.darkBrown,
              fontWeight: FontWeight.w900,
            ),
      ),
      secondary: Icon(
        icon,
        color: ZapitiColors.wineRed,
      ),
    );
  }
}
