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
  final VoidCallback onAbout;
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
    required this.onAbout,
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
                      onAbout: onAbout,
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
  final VoidCallback onAbout;
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
    required this.onAbout,
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
                                onAbout: onAbout,
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
  final Map<int, int> _selectedAnswers = {};

  static const _steps = [
    _TutorialStep(
      title: 'Mesa por parejas',
      body: '1. Juegas en pareja contra dos rivales.',
      icon: Icons.groups_outlined,
      prompt:
          'Tu aliado se sienta enfrente. Si gana tu equipo, no gastes carta.',
      options: ['Guardar fuerte', 'Tirar alta'],
      correctIndex: 0,
      answer:
          'Bien: cuando tu pareja ya domina, conservar cartas fuertes vale media partida.',
    ),
    _TutorialStep(
      title: 'Tres rondas',
      body:
          'Cada reparto tiene hasta tres rondas. Gana quien domina las cartas jugadas.',
      icon: Icons.style_outlined,
      prompt: 'Si el rival ya ganó una ronda, la siguiente pesa más.',
      options: ['Salvar ronda', 'Regalar carta'],
      correctIndex: 0,
      answer:
          'Exacto: con una ronda rival, la IA intenta salvar con la mínima carta útil.',
    ),
    _TutorialStep(
      title: 'Valor de cartas',
      body: '4 de bastos -> 7 de copas -> 7 de oros -> as de espadas -> '
          '3 -> 2 -> as -> 12 -> 11 -> 10 -> 7 -> 6 -> 5 -> 4.',
      icon: Icons.workspace_premium_outlined,
      prompt: 'El 4 de bastos es la carta máxima.',
      options: ['Verdadero', 'Falso'],
      correctIndex: 0,
      answer: 'Sí: el 4 de bastos manda sobre toda la baraja.',
    ),
    _TutorialStep(
      title: 'Truco y puntos',
      body:
          'Puedes cantar truco, aceptar, pasar o subir para aumentar el valor del reparto.',
      icon: Icons.campaign_outlined,
      prompt: 'Si ya no puedes ganar la ronda visible, lo prudente es...',
      options: ['Pasar', 'Aceptar'],
      correctIndex: 0,
      answer:
          'Eso es: aceptar sin opciones reales solo regala chinos al rival.',
    ),
    _TutorialStep(
      title: 'Señas',
      body:
          'Pide seña a tu pareja o usa las tuyas para comunicar cartas fuertes.',
      icon: Icons.visibility_outlined,
      prompt: 'Una seña fuerte ayuda a decidir carta y truco.',
      options: ['Pedir seña', 'Ignorar'],
      correctIndex: 0,
      answer: 'Buena lectura: la seña cambia cuánto arriesga tu equipo.',
    ),
    _TutorialStep(
      title: 'Voy a ti',
      body:
          'Sirve para pedir a tu pareja que intente ganar, pero sin quemar carta inútil.',
      icon: Icons.record_voice_over_outlined,
      prompt: 'Si tu pareja no puede ganar la mesa, debería...',
      options: ['Tirar menor', 'Tirar mayor'],
      correctIndex: 0,
      answer:
          'Correcto: si no puede ganar, guarda fuerza para la siguiente ronda.',
    ),
    _TutorialStep(
      title: 'Faroles',
      body:
          'La IA puede cantar o subir con historia de mesa, presión o cartas rivales gastadas.',
      icon: Icons.theater_comedy_outlined,
      prompt: 'Un farol funciona mejor cuando...',
      options: ['Hay contexto', 'No hay nada'],
      correctIndex: 0,
      answer:
          'Sí: una carta fuerte ya gastada o marcador en contra hace creíble el farol.',
    ),
    _TutorialStep(
      title: 'Dificultad',
      body:
          'Cada nivel cambia errores, lectura de señas, paciencia y agresividad con el truco.',
      icon: Icons.psychology_alt_outlined,
      prompt: 'En experto la IA...',
      options: ['Lee mejor', 'Acepta todo'],
      correctIndex: 0,
      answer:
          'Exacto: en niveles altos lee mesa y señales antes de comprometer chinos.',
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
        final showPrompt = maxHeight >= 430 && step.prompt != null;
        final visualHeight = max(
          compact ? 110.0 : 150.0,
          min(maxHeight * (showPrompt ? 0.42 : 0.62),
              showPrompt ? 210.0 : 260.0),
        );
        final cardWidth = min(
          shortest * 0.22,
          min(visualHeight * 0.74, 110.0),
        );
        final bodyMaxLines = compact ? 1 : 2;
        final selectedAnswer = _selectedAnswers[_stepIndex];

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
            if (showPrompt) ...[
              SizedBox(height: compact ? 2 : 6),
              _TutorialDecisionPrompt(
                step: step,
                selectedIndex: selectedAnswer,
                onSelected: (index) {
                  setState(() {
                    _selectedAnswers[_stepIndex] = index;
                  });
                },
              ),
            ],
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
  final String? prompt;
  final List<String> options;
  final int correctIndex;
  final String? answer;

  const _TutorialStep({
    required this.title,
    required this.body,
    required this.icon,
    this.prompt,
    this.options = const [],
    this.correctIndex = 0,
    this.answer,
  });
}

class _TutorialDecisionPrompt extends StatelessWidget {
  final _TutorialStep step;
  final int? selectedIndex;
  final ValueChanged<int> onSelected;

  const _TutorialDecisionPrompt({
    required this.step,
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final answerIsCorrect = selectedIndex == step.correctIndex;
    final bodyStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
          color: ZapitiColors.darkBrown.withValues(alpha: 0.82),
          fontWeight: FontWeight.w800,
          height: 1.1,
        );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.52),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: ZapitiColors.darkBrown.withValues(alpha: 0.10),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              step.prompt!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: bodyStyle,
            ),
            const SizedBox(height: 5),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                for (var index = 0; index < step.options.length; index++)
                  ChoiceChip(
                    label: Text(step.options[index]),
                    selected: selectedIndex == index,
                    onSelected: (_) => onSelected(index),
                    selectedColor:
                        answerIsCorrect ? ZapitiColors.oldGold : Colors.white,
                    backgroundColor: ZapitiColors.cardCream,
                    labelStyle: TextStyle(
                      color: selectedIndex == index
                          ? ZapitiColors.darkBrown
                          : ZapitiColors.darkBrown.withValues(alpha: 0.72),
                      fontWeight: FontWeight.w900,
                    ),
                    side: BorderSide(
                      color: selectedIndex == index
                          ? ZapitiColors.wineRed
                          : ZapitiColors.darkBrown.withValues(alpha: 0.12),
                    ),
                  ),
              ],
            ),
            if (selectedIndex != null && step.answer != null) ...[
              const SizedBox(height: 4),
              Text(
                answerIsCorrect ? step.answer! : 'Casi: ${step.answer!}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: bodyStyle?.copyWith(
                  color: answerIsCorrect
                      ? ZapitiColors.tableGreenDark
                      : ZapitiColors.wineRed,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
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
  static const _maxPlayerNameLength = 18;
  static const _maxUsernameLength = 24;
  static const _maxTeamNameLength = 22;

  final TextEditingController _serverController =
      TextEditingController(text: ServerConfig.websocketUrl);
  final TextEditingController _nameController =
      TextEditingController(text: 'Jugador');
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _teamNameController = TextEditingController();
  final TextEditingController _roomController = TextEditingController();
  GameSocket? _socket;
  String? _playerId;
  String? _sessionToken;
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
  bool _profileReady = false;
  bool _showCreateAccount = false;
  bool _teamModalShownForCurrentRoom = false;
  bool _teamDialogAutoClosed = false;
  String? _teamDialogTeammatePlayerId;
  BuildContext? _teamDialogContext;
  String? _pendingRoomAction;
  bool _roomActionRetriedWithoutCharacter = false;
  String _profileStatus = 'Configura tu perfil multijugador.';
  late String _selectedCharacterId;
  String? _confirmedCharacterId;
  Map<String, dynamic> _playerStats = const {};
  List<Map<String, dynamic>> _rankingPairs = const [];
  List<Map<String, dynamic>> _rankingMatches = const [];
  List<Map<String, dynamic>> _playerTeams = const [];
  String? _selectedPairId;
  bool _teamsLoaded = false;
  bool _rankingRequested = false;

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
        _setPlayerNameField(mySeat.name);
      }

      _socket!.onMessage = _handleSocketMessage;
      _socket!.onError = (error) {
        _clearSessionAfterConnectionLoss('Error de conexión: $error');
      };
      _socket!.onDone = () {
        _clearSessionAfterConnectionLoss('Servidor desconectado.');
      };
    } else {
      unawaited(_loadSavedPlayerProfile());
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
    _usernameController.dispose();
    _passwordController.dispose();
    _teamNameController.dispose();
    _roomController.dispose();
    super.dispose();
  }

  String get _playerName => _cleanPlayerName(_nameController.text);
  String get _username => _cleanUsername(_usernameController.text);
  String get _profilePassword => _passwordController.text.trim();
  String get _teamName => _cleanTeamName(_teamNameController.text);
  String get _selectedTeamName {
    final selected = _selectedTeam;
    if (selected != null) {
      final name = selected['teamName']?.toString().trim() ?? '';
      if (name.isNotEmpty) return _cleanTeamName(name);
    }
    return _teamName;
  }

  Map<String, dynamic>? get _selectedTeam {
    final pairId = _selectedPairId;
    if (pairId == null) return null;
    for (final team in _playerTeams) {
      if (team['pairId']?.toString() == pairId) return team;
    }
    return null;
  }

  String _cleanPlayerName(String value) {
    final normalized = value.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (normalized.length <= _maxPlayerNameLength) return normalized;
    return normalized.substring(0, _maxPlayerNameLength).trimRight();
  }

  void _setPlayerNameField(String value) {
    final cleaned = _cleanPlayerName(value);
    if (cleaned.isEmpty || _nameController.text == cleaned) return;
    _nameController.text = cleaned;
    _nameController.selection = TextSelection.collapsed(
      offset: _nameController.text.length,
    );
  }

  String _cleanUsername(String value) {
    final normalized = value.trim().toLowerCase();
    if (normalized.length <= _maxUsernameLength) return normalized;
    return normalized.substring(0, _maxUsernameLength);
  }

  void _setUsernameField(String value) {
    final cleaned = _cleanUsername(value);
    if (_usernameController.text == cleaned) return;
    _usernameController.text = cleaned;
    _usernameController.selection = TextSelection.collapsed(
      offset: _usernameController.text.length,
    );
  }

  String _cleanTeamName(String value) {
    final normalized = value.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (normalized.length <= _maxTeamNameLength) return normalized;
    return normalized.substring(0, _maxTeamNameLength).trimRight();
  }

  void _setTeamNameField(String value) {
    final cleaned = _cleanTeamName(value);
    if (_teamNameController.text == cleaned) return;
    _teamNameController.text = cleaned;
    _teamNameController.selection = TextSelection.collapsed(
      offset: _teamNameController.text.length,
    );
  }

  Future<void> _loadSavedPlayerProfile() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted || _roomSnapshot != null) return;
    _setPlayerNameField(
      prefs.getString(_GameScreenState._multiplayerPlayerNamePrefsKey) ??
          _nameController.text,
    );
    _setUsernameField(
      prefs.getString(_GameScreenState._multiplayerUsernamePrefsKey) ??
          _defaultUsernameFromName(_nameController.text),
    );
    _playerId = prefs.getString(_GameScreenState._multiplayerPlayerIdPrefsKey);
    _sessionToken = prefs.getString(
      _GameScreenState._multiplayerSessionTokenPrefsKey,
    );
    if (_playerId == null || _playerId!.isEmpty) {
      _playerId = _createPersistentPlayerId();
      await prefs.setString(
        _GameScreenState._multiplayerPlayerIdPrefsKey,
        _playerId!,
      );
    }
    final savedPin = prefs.getString(
      _GameScreenState._multiplayerPlayerPinPrefsKey,
    );
    _passwordController.text =
        prefs.getString(_GameScreenState._multiplayerPasswordPrefsKey) ??
            savedPin ??
            '';
    _setTeamNameField(
      prefs.getString(_GameScreenState._multiplayerTeamNamePrefsKey) ?? '',
    );
    if (mounted) {
      setState(() {
        _profileReady = _sessionToken != null && _sessionToken!.isNotEmpty;
        _profileStatus = _profileReady
            ? 'Sesion activa. Puedes entrar a salas.'
            : 'Inicia sesion para recuperar tus datos.';
      });
    }
  }

  String _defaultUsernameFromName(String name) {
    final normalized = name
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), '.')
        .replaceAll(RegExp(r'[^a-z0-9_.-]'), '');
    if (normalized.length >= 3) return _cleanUsername(normalized);
    return '';
  }

  Future<void> _savePlayerName(String playerName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _GameScreenState._multiplayerPlayerNamePrefsKey,
      playerName,
    );
  }

  Future<void> _savePlayerId(String playerId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _GameScreenState._multiplayerPlayerIdPrefsKey,
      playerId,
    );
  }

  Future<void> _saveUsername(String username) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _GameScreenState._multiplayerUsernamePrefsKey,
      username,
    );
  }

  Future<void> _saveSessionToken(String sessionToken) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _GameScreenState._multiplayerSessionTokenPrefsKey,
      sessionToken,
    );
  }

  Future<void> _clearSavedSessionToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_GameScreenState._multiplayerSessionTokenPrefsKey);
  }

  Future<void> _saveTeamName(String teamName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _GameScreenState._multiplayerTeamNamePrefsKey,
      teamName,
    );
  }

  String _createPersistentPlayerId() {
    final randomValue = Random().nextInt(0x7fffffff);
    return 'player_${DateTime.now().microsecondsSinceEpoch}_$randomValue';
  }

  bool get _serverUrlIsEditable => ServerConfig.useLocalServer;

  String get _serverUrl {
    if (_serverUrlIsEditable) {
      return _serverController.text.trim();
    }
    return ServerConfig.websocketUrl;
  }

  String get _localPlayerId =>
      _playerId ??= _createPersistentPlayerId();

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
    _closeCreateTeamDialog();
    setState(() {
      if (!preserveSocket) {
        _socket = null;
      }
      _keepSocketAliveOnDispose = false;
      _sessionStarted = false;
      _roomSnapshot = null;
      _connectedRoomId = null;
      _ready = false;
      _autoEnterQueued = false;
      _connectionState = connectionState;
      _connecting = false;
      _teamModalShownForCurrentRoom = false;
      _teamDialogTeammatePlayerId = null;
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
        status: 'Escribe la dirección del servidor.',
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
        'El servidor gratuito está arrancando. Esto puede tardar unos segundos...',
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
        _handleSocketDropped('Error de conexión: $error');
      };
      nextSocket.onDone = () {
        if (!mounted || generation != _connectionGeneration) return;
        _handleSocketDropped('Conexión cerrada.');
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
        status: 'La conexión se ha cerrado. Reintentando...',
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
      'Conexión restablecida. La partida anterior no se puede recuperar. Vuelve a crear o unirte de nuevo.',
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
          _pendingRoomAction = null;
          _roomActionRetriedWithoutCharacter = false;
          _roomSnapshot = snapshot;
          _connectedRoomId = snapshot.roomId;
          _roomController.text = snapshot.roomId;
          if (message.playerId != null && message.playerId!.isNotEmpty) {
            _playerId = message.playerId;
          }
          final localSeat = _localSeatFor(snapshot);
          if (localSeat != null) {
            _ready = localSeat.ready;
            if ((localSeat.pairId ?? '').isNotEmpty) {
              _selectedPairId = localSeat.pairId;
            }
            final localTeamName = localSeat.teamName?.trim() ?? '';
            if (localTeamName.isNotEmpty) {
              _setTeamNameField(localTeamName);
            }
          }
          _sessionStarted = snapshot.phase != 'lobby';
          _connectionState = _ServerConnectionState.connected;
          _status = switch (snapshot.phase) {
            'starting' => 'Todos listos. La partida está arrancando.',
            'playing' => 'Partida en curso.',
            _ => 'Sala ${snapshot.roomId} sincronizada.',
          };
        });
        MultiplayerSessionStore.instance.roomSnapshot = snapshot;
        _syncSelectedCharacterFromRoom();
        _resolveTeamForRoomSnapshot(snapshot);
        _maybeAutoEnterGame();
        break;
      case MultiplayerMessageType.error:
        setState(() {
          final code = message.payload['code']?.toString() ?? 'error';
          final text =
              message.payload['message']?.toString() ?? 'Error del servidor';
          if (code == 'profile_not_found') {
            _profileStatus = 'No hay cuenta con ese usuario y contrasena.';
            _showCreateAccount = true;
          } else if (code == 'auth_failed') {
            _sessionToken = null;
            unawaited(_clearSavedSessionToken());
            _profileReady = false;
            _showCreateAccount = false;
            _teamsLoaded = false;
            _playerTeams = const [];
            _selectedPairId = null;
            _profileStatus =
                'Sesion caducada. Inicia sesion con tu contrasena.';
          } else if (code == 'invalid_payload' && !_profileReady) {
            _profileStatus = 'Revisa usuario, nombre y contrasena.';
          }
          _status = switch (code) {
            'room_not_found' =>
              'La sala ya no existe. El servidor pudo haberse reiniciado.',
            'team_required' =>
              'Crea o selecciona el equipo antes de marcar listo.',
            'invalid_team_for_room' =>
              'Ese equipo no corresponde con tu companero en esta sala.',
            'auth_failed' =>
              'Sesion caducada. Vuelve a iniciar sesion con tu contrasena.',
            'character_taken' =>
              'Ese personaje ya esta ocupado en esta sala. Elige otro.',
            _ => 'Servidor: $code - $text',
          };
        });
        final errorCode = message.payload['code']?.toString();
        if (errorCode == 'character_taken') {
          if (_retryPendingRoomActionWithoutCharacter()) {
            break;
          }
          _revertSelectedCharacter();
        } else if (errorCode == 'room_in_progress') {
          _revertSelectedCharacter();
        } else if (errorCode == 'invalid_team_for_room') {
          setState(() {
            _selectedPairId = null;
          });
        }
        break;
      case MultiplayerMessageType.startGame:
        MultiplayerSessionStore.instance.localGamePlayerId = message.playerId;
        MultiplayerSessionStore.instance.matchStarted = true;
        MultiplayerSessionStore.instance.players =
            _parsePlayers(message.payload['players']);
        MultiplayerSessionStore.instance.characterIdsByPlayer =
            _parseCharacterIdsByPlayer(message.payload['players']);
        MultiplayerSessionStore.instance.botDifficulty =
            _parseBotDifficulty(message.payload['players']);
        MultiplayerSessionStore.instance.seed = message.payload['seed'] as int?;
        MultiplayerSessionStore.instance.controlledPlayerIds =
            message.playerId == null ? const [] : [message.playerId!];
        MultiplayerSessionStore.instance.fixedHands =
            _parseFixedHands(message.payload['fixedHands']);
        setState(() {
          _sessionStarted = true;
          _connectionState = _ServerConnectionState.connected;
          _status = 'La partida va a empezar. Abriendo la mesa...';
        });
        _maybeAutoEnterGame();
        break;
      case MultiplayerMessageType.ranking:
        setState(() {
          _rankingPairs = [
            for (final entry
                in (message.payload['pairs'] as List<dynamic>? ?? const []))
              if (entry is Map) Map<String, dynamic>.from(entry),
          ];
          _rankingMatches = [
            for (final entry
                in (message.payload['matches'] as List<dynamic>? ?? const []))
              if (entry is Map) Map<String, dynamic>.from(entry),
          ];
          final rankingPlayers = [
            for (final entry
                in (message.payload['players'] as List<dynamic>? ?? const []))
              if (entry is Map) Map<String, dynamic>.from(entry),
          ];
          final localPlayerId = _playerId;
          if (localPlayerId != null) {
            final playerStats = rankingPlayers.cast<Map<String, dynamic>?>()
                .firstWhere(
                  (entry) => entry?['playerId']?.toString() == localPlayerId,
                  orElse: () => null,
                );
            if (playerStats != null) {
              _playerStats = playerStats;
            }
          }
          _rankingRequested = true;
          _status = _rankingPairs.isEmpty && _rankingMatches.isEmpty
              ? 'Aun no hay partidas registradas.'
              : 'Ranking actualizado.';
        });
        break;
      case MultiplayerMessageType.teams:
        final teams = [
          for (final entry
              in (message.payload['teams'] as List<dynamic>? ?? const []))
            if (entry is Map) Map<String, dynamic>.from(entry),
        ];
        setState(() {
          _playerTeams = teams;
          _teamsLoaded = true;
          if (_selectedPairId == null ||
              !teams.any(
                (team) => team['pairId']?.toString() == _selectedPairId,
              )) {
            final snapshot = _roomSnapshot;
            final teammate = snapshot == null ? null : _teammateSeatFor(snapshot);
            _selectedPairId = teammate == null
                ? teams.isEmpty
                    ? null
                    : teams.first['pairId']?.toString()
                : _teamForTeammate(teammate.playerId)?['pairId']?.toString();
          }
          final selectedName = _selectedTeamName;
          if (selectedName.isNotEmpty) {
            _setTeamNameField(selectedName);
            unawaited(_saveTeamName(selectedName));
          }
          _status = teams.isEmpty
              ? 'Aun no tienes equipos. Crea uno con el usuario de tu pareja.'
              : 'Equipos actualizados.';
        });
        final snapshot = _roomSnapshot;
        if (snapshot != null) {
          _resolveTeamForRoomSnapshot(snapshot);
        }
        break;
      case MultiplayerMessageType.profile:
        final profilePlayerId =
            message.payload['playerId']?.toString() ?? message.playerId;
        final profileUsername = message.payload['username']?.toString();
        final profileName = message.payload['name']?.toString();
        final profileTeamName = message.payload['teamName']?.toString() ?? '';
        final profileSessionToken =
            message.payload['sessionToken']?.toString();
        if (profilePlayerId == null || profileName == null) {
          setState(() {
            _profileStatus = 'El servidor devolvio un perfil incompleto.';
          });
          break;
        }
        _playerId = profilePlayerId;
        _teamsLoaded = false;
        _playerTeams = const [];
        _selectedPairId = null;
        if (profileUsername != null && profileUsername.isNotEmpty) {
          _setUsernameField(profileUsername);
          unawaited(_saveUsername(profileUsername));
        }
        _setPlayerNameField(profileName);
        _setTeamNameField(profileTeamName);
        unawaited(_savePlayerName(profileName));
        unawaited(_savePlayerId(profilePlayerId));
        unawaited(_saveTeamName(profileTeamName));
        if (profileSessionToken != null && profileSessionToken.isNotEmpty) {
          _sessionToken = profileSessionToken;
          unawaited(_saveSessionToken(profileSessionToken));
        }
        _passwordController.clear();
        setState(() {
          _playerStats = Map<String, dynamic>.from(message.payload);
          _profileReady = true;
          _showCreateAccount = false;
          _profileStatus = 'Sesion iniciada.';
          _status = 'Perfil ${_cleanPlayerName(profileName)} sincronizado.';
        });
        _requestTeamsIfReady();
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
    final username = _username;
    if (playerName.isEmpty) {
      setState(() {
        _status = 'Escribe tu nombre antes de crear la sala.';
      });
      return;
    }
    if (!_hasUsableSessionOrCredentials()) {
      setState(() {
        _profileReady = false;
        _profileStatus = 'Inicia sesion antes de crear una sala.';
      });
      return;
    }
    _setPlayerNameField(playerName);
    _setUsernameField(username);
    _setTeamNameField(_selectedTeamName);
    unawaited(_savePlayerName(playerName));
    unawaited(_saveUsername(username));
    unawaited(_saveTeamName(_selectedTeamName));

    if (!await _ensureConnected()) {
      setState(() {
        _profileStatus =
            'Servidor sin respuesta. Intenta crear la sala de nuevo.';
        _status = 'Servidor sin respuesta. No se ha creado la sala.';
      });
      return;
    }

    final socket = _socket;
    if (socket == null) return;

    setState(() {
      _connectedRoomId = null;
      _ready = false;
      _teamModalShownForCurrentRoom = false;
      _teamDialogTeammatePlayerId = null;
      _status = 'Solicitando creacion de sala...';
    });

    try {
      final localPlayerId = _localPlayerId;
      unawaited(_savePlayerId(localPlayerId));
      _pendingRoomAction = 'create';
      _roomActionRetriedWithoutCharacter = false;
      socket.createRoom(
        playerId: localPlayerId,
        username: username,
        playerName: playerName,
        password: _sessionToken == null ? _profilePassword : null,
        teamName: _selectedTeamName,
        sessionToken: _sessionToken,
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
    final username = _username;

    if (roomCode.isEmpty) {
      setState(() {
        _status = 'Escribe un código de sala para unirte.';
      });
      return;
    }

    if (playerName.isEmpty) {
      setState(() {
        _status = 'Escribe tu nombre antes de unirte.';
      });
      return;
    }
    if (!_hasUsableSessionOrCredentials()) {
      setState(() {
        _profileReady = false;
        _profileStatus = 'Inicia sesion antes de unirte a una sala.';
      });
      return;
    }
    _setPlayerNameField(playerName);
    _setUsernameField(username);
    _setTeamNameField(_selectedTeamName);
    unawaited(_savePlayerName(playerName));
    unawaited(_saveUsername(username));
    unawaited(_saveTeamName(_selectedTeamName));

    if (!await _ensureConnected()) {
      setState(() {
        _profileStatus =
            'Servidor sin respuesta. Intenta unirte de nuevo.';
        _status = 'Servidor sin respuesta. No se ha unido a la sala.';
      });
      return;
    }

    final socket = _socket;
    if (socket == null) return;

    setState(() {
      _connectedRoomId = roomCode;
      _ready = false;
      _teamModalShownForCurrentRoom = false;
      _teamDialogTeammatePlayerId = null;
      _status = 'Intentando unirme a $roomCode...';
    });

    try {
      final localPlayerId = _localPlayerId;
      unawaited(_savePlayerId(localPlayerId));
      _pendingRoomAction = 'join';
      _roomActionRetriedWithoutCharacter = false;
      socket.joinRoom(
        roomId: roomCode,
        playerId: localPlayerId,
        username: username,
        playerName: playerName,
        password: _sessionToken == null ? _profilePassword : null,
        teamName: _selectedTeamName,
        sessionToken: _sessionToken,
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

  bool _retryPendingRoomActionWithoutCharacter() {
    if (_roomActionRetriedWithoutCharacter) return false;
    final action = _pendingRoomAction;
    final socket = _socket;
    if (action == null || socket == null || !socket.isConnected) return false;

    final playerName = _playerName;
    final username = _username;
    final localPlayerId = _localPlayerId;
    _roomActionRetriedWithoutCharacter = true;

    try {
      if (action == 'create') {
        socket.createRoom(
          playerId: localPlayerId,
          username: username,
          playerName: playerName,
          password: _sessionToken == null ? _profilePassword : null,
          teamName: _selectedTeamName,
          sessionToken: _sessionToken,
        );
        setState(() {
          _status =
              'Personaje ocupado. Reintentando sala con personaje libre...';
        });
        return true;
      }

      if (action == 'join') {
        final roomId = _connectedRoomId ?? _roomController.text.trim();
        if (roomId.isEmpty) return false;
        socket.joinRoom(
          roomId: roomId,
          playerId: localPlayerId,
          username: username,
          playerName: playerName,
          password: _sessionToken == null ? _profilePassword : null,
          teamName: _selectedTeamName,
          sessionToken: _sessionToken,
        );
        setState(() {
          _status =
              'Personaje ocupado. Reintentando union con personaje libre...';
        });
        return true;
      }
    } catch (error) {
      setState(() {
        _status = 'No se pudo reintentar sin personaje: $error';
      });
    }
    return false;
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
    final snapshot = _roomSnapshot;
    if (snapshot != null &&
        snapshot.seats.length >= 4 &&
        _teammateSeatFor(snapshot)?.playerId.isNotEmpty == true &&
        (_selectedPairId == null || _selectedPairId!.isEmpty)) {
      setState(() {
        _status = 'Crea o selecciona el equipo antes de marcar listo.';
      });
      _resolveTeamForRoomSnapshot(snapshot);
      return;
    }
    _sendTeamSelectionIfReady(roomId: roomId);

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

  Future<void> _requestRanking() async {
    if (!await _ensureConnected()) {
      return;
    }
    final socket = _socket;
    if (socket == null) return;
    setState(() {
      _rankingRequested = true;
      _status = 'Pidiendo ranking al servidor...';
    });
    try {
      socket.requestRanking();
    } catch (error) {
      setState(() {
        _status = 'No se pudo pedir el ranking: $error';
      });
    }
  }

  void _requestTeamsIfReady() {
    final socket = _socket;
    final playerId = _playerId;
    final sessionToken = _sessionToken;
    if (socket == null ||
        !socket.isConnected ||
        playerId == null ||
        sessionToken == null ||
        sessionToken.isEmpty) {
      return;
    }
    try {
      socket.requestTeams(playerId: playerId, sessionToken: sessionToken);
    } catch (error) {
      setState(() {
        _status = 'No se pudieron pedir los equipos: $error';
      });
    }
  }

  void _resolveTeamForRoomSnapshot(MultiplayerRoomSnapshot snapshot) {
    if (snapshot.phase != 'lobby') return;
    if (snapshot.seats.length < 4) return;
    final localSeat = _localSeatFor(snapshot);
    final teammate = _teammateSeatFor(snapshot);
    final teammateUsername = teammate?.username?.trim() ?? '';
    if (teammate == null || teammateUsername.isEmpty) return;
    if (_teamDialogContext != null &&
        _teamDialogTeammatePlayerId != null &&
        _teamDialogTeammatePlayerId != teammate.playerId) {
      _closeCreateTeamDialog();
      _teamModalShownForCurrentRoom = false;
    }
    final selectedTeam = _selectedTeam;
    if (selectedTeam != null &&
        _teamForTeammate(teammate.playerId)?['pairId']?.toString() !=
            selectedTeam['pairId']?.toString()) {
      setState(() {
        _selectedPairId = null;
      });
    }
    final teammatePairId = teammate.pairId?.trim() ?? '';
    if (teammatePairId.isNotEmpty) {
      final teammateTeamName = teammate.teamName?.trim() ?? '';
      final alreadySelected = _selectedPairId == teammatePairId;
      final alreadySynced = localSeat?.pairId == teammatePairId;
      if (!alreadySelected || !alreadySynced) {
        setState(() {
          _selectedPairId = teammatePairId;
          if (teammateTeamName.isNotEmpty) {
            _setTeamNameField(teammateTeamName);
            unawaited(_saveTeamName(teammateTeamName));
          }
          _status = teammateTeamName.isEmpty
              ? 'Equipo sincronizado con tu companero.'
              : 'Equipo $teammateTeamName sincronizado.';
        });
        _closeCreateTeamDialog();
        _requestTeamsIfReady();
        _sendTeamSelectionIfReady(roomId: snapshot.roomId);
      }
      return;
    }
    if (!_teamsLoaded) {
      _requestTeamsIfReady();
      return;
    }

    final existingTeam = _teamForTeammate(teammate.playerId);
    if (existingTeam != null) {
      final pairId = existingTeam['pairId']?.toString();
      final teamName = existingTeam['teamName']?.toString().trim() ?? '';
      if (pairId != null && pairId.isNotEmpty) {
        setState(() {
          _selectedPairId = pairId;
          if (teamName.isNotEmpty) {
            _setTeamNameField(teamName);
            unawaited(_saveTeamName(teamName));
          }
        });
        _sendTeamSelectionIfReady(roomId: snapshot.roomId);
        _closeCreateTeamDialog();
      }
      return;
    }

    if (_teamModalShownForCurrentRoom) return;
    _teamModalShownForCurrentRoom = true;
    _teamDialogTeammatePlayerId = teammate.playerId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _roomSnapshot?.roomId != snapshot.roomId) return;
      _showCreateTeamDialog(teammate);
    });
  }

  MultiplayerSeat? _localSeatFor(MultiplayerRoomSnapshot snapshot) {
    final localPlayerId = _playerId;
    if (localPlayerId == null) return null;
    final seat = snapshot.seats.firstWhere(
      (seat) => seat.playerId == localPlayerId,
      orElse: () => const MultiplayerSeat(
        playerId: '',
        name: '',
        seatIndex: -1,
        ready: false,
        connected: false,
      ),
    );
    return seat.playerId.isEmpty ? null : seat;
  }

  MultiplayerSeat? _teammateSeatFor(MultiplayerRoomSnapshot snapshot) {
    final localPlayerId = _playerId;
    if (localPlayerId == null) return null;
    final localSeat = _localSeatFor(snapshot);
    if (localSeat == null) return null;
    if (snapshot.seats.length == 2) {
      return snapshot.seats.firstWhere(
        (seat) => seat.playerId != localPlayerId,
        orElse: () => const MultiplayerSeat(
          playerId: '',
          name: '',
          seatIndex: -1,
          ready: false,
          connected: false,
        ),
      );
    }
    return snapshot.seats.firstWhere(
      (seat) =>
          seat.playerId != localPlayerId && seat.teamId == localSeat.teamId,
      orElse: () => const MultiplayerSeat(
        playerId: '',
        name: '',
        seatIndex: -1,
        ready: false,
        connected: false,
      ),
    );
  }

  Map<String, dynamic>? _teamForTeammate(String teammatePlayerId) {
    if (teammatePlayerId.isEmpty) return null;
    for (final team in _playerTeams) {
      final playerIds = team['playerIds'];
      if (playerIds is List &&
          playerIds.map((entry) => entry.toString()).contains(teammatePlayerId)) {
        return team;
      }
    }
    return null;
  }

  void _sendTeamSelectionIfReady({String? roomId}) {
    final socket = _socket;
    final playerId = _playerId;
    final sessionToken = _sessionToken;
    final pairId = _selectedPairId;
    final targetRoomId =
        roomId ?? _connectedRoomId ?? _roomController.text.trim();
    if (socket == null ||
        !socket.isConnected ||
        playerId == null ||
        sessionToken == null ||
        pairId == null ||
        targetRoomId.isEmpty) {
      return;
    }

    try {
      socket.selectTeam(
        roomId: targetRoomId,
        playerId: playerId,
        sessionToken: sessionToken,
        pairId: pairId,
      );
    } catch (error) {
      setState(() {
        _status = 'No se pudo seleccionar el equipo: $error';
      });
    }
  }

  void _closeCreateTeamDialog() {
    final dialogContext = _teamDialogContext;
    if (dialogContext == null) return;
    _teamDialogAutoClosed = true;
    _teamDialogContext = null;
    _teamDialogTeammatePlayerId = null;
    _teamModalShownForCurrentRoom = true;
    Navigator.of(dialogContext).pop(false);
  }

  Future<void> _showCreateTeamDialog(MultiplayerSeat teammate) async {
    final teamNameController = TextEditingController(
      text: '$_playerName / ${teammate.name}',
    );
    _teamDialogAutoClosed = false;
    final created = await showDialog<bool>(
      context: context,
      builder: (context) {
        _teamDialogContext = context;
        return AlertDialog(
          title: const Text('Crear equipo'),
          content: TextField(
            controller: teamNameController,
            inputFormatters: [
              LengthLimitingTextInputFormatter(_maxTeamNameLength),
            ],
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: 'Nombre del equipo',
              helperText: 'Companero: ${teammate.name}',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Ahora no'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Crear'),
            ),
          ],
        );
      },
    );
    final autoClosed = _teamDialogAutoClosed;
    _teamDialogAutoClosed = false;
    _teamDialogContext = null;
    _teamDialogTeammatePlayerId = null;
    if (created != true || !mounted) {
      if (!autoClosed) {
        _teamModalShownForCurrentRoom = false;
      }
      return;
    }
    await _createTeamForTeammate(
      teammateUsername: teammate.username!,
      teamName: _cleanTeamName(teamNameController.text),
    );
  }

  Future<void> _createTeamForTeammate({
    required String teammateUsername,
    required String teamName,
  }) async {
    final socket = _socket;
    final playerId = _playerId;
    final sessionToken = _sessionToken;
    if (socket == null || playerId == null || sessionToken == null) return;
    if (teamName.isEmpty) {
      setState(() {
        _status = 'Escribe un nombre para el equipo.';
      });
      return;
    }

    try {
      socket.createTeam(
        playerId: playerId,
        sessionToken: sessionToken,
        teammateUsername: teammateUsername,
        teamName: teamName,
      );
      setState(() {
        _setTeamNameField(teamName);
        _status = 'Creando equipo con $teammateUsername...';
      });
    } catch (error) {
      setState(() {
        _status = 'No se pudo crear el equipo: $error';
      });
    }
  }

  Future<void> _saveProfileAndContinue() async {
    final playerName = _playerName;
    final username = _username;
    final password = _profilePassword;
    if (playerName.isEmpty) {
      setState(() {
        _profileStatus = 'Escribe tu nombre para continuar.';
      });
      return;
    }
    if (!RegExp(r'^[a-z0-9_.-]{3,24}$').hasMatch(username)) {
      setState(() {
        _profileStatus =
            'El usuario debe tener 3-24 letras, numeros, punto o guion.';
      });
      return;
    }
    if (password.length < 6 || password.length > 72) {
      setState(() {
        _profileStatus = 'La contrasena debe tener entre 6 y 72 caracteres.';
      });
      return;
    }

    final localPlayerId = _localPlayerId;
    await Future.wait([
      _savePlayerName(playerName),
      _savePlayerId(localPlayerId),
      _saveUsername(username),
    ]);

    setState(() {
      _profileStatus = 'Creando usuario...';
      _status = 'Sincronizando usuario con el servidor...';
    });

    if (!await _ensureConnected()) {
      setState(() {
        _profileStatus = 'No se pudo conectar para crear el usuario.';
      });
      return;
    }

    final socket = _socket;
    if (socket == null) return;
    try {
      socket.updateProfile(
        playerId: localPlayerId,
        username: username,
        playerName: playerName,
        password: password,
        teamName: '',
        sessionToken: _sessionToken,
      );
    } catch (error) {
      setState(() {
        _profileStatus = 'No se pudo crear el usuario: $error';
      });
    }
  }

  Future<void> _recoverProfile() async {
    final username = _username;
    final password = _profilePassword;
    if (!RegExp(r'^[a-z0-9_.-]{3,24}$').hasMatch(username) ||
        password.length < 6 ||
        password.length > 72) {
      setState(() {
        _profileStatus = 'Escribe usuario y contrasena validos.';
      });
      return;
    }
    if (!await _ensureConnected()) {
      setState(() {
        _profileStatus =
            'Servidor sin respuesta. Intenta iniciar sesion de nuevo.';
      });
      return;
    }
    final socket = _socket;
    if (socket == null) return;
    setState(() {
      _profileStatus = 'Iniciando sesion...';
    });
    try {
      socket.recoverProfile(
        username: username,
        password: password,
      );
    } catch (error) {
      setState(() {
        _profileStatus = 'No se pudo iniciar sesion: $error';
      });
    }
  }

  bool _hasUsableSessionOrCredentials() {
    if (_sessionToken != null && _sessionToken!.isNotEmpty) return true;
    return RegExp(r'^[a-z0-9_.-]{3,24}$').hasMatch(_username) &&
        _profilePassword.length >= 6 &&
        _profilePassword.length <= 72;
  }

  Future<void> _copyRoomInvitation() async {
    final roomId = _connectedRoomId ?? _roomController.text.trim();
    if (roomId.isEmpty) {
      setState(() {
        _status = 'Crea o escribe una sala antes de copiar invitacion.';
      });
      return;
    }

    await Clipboard.setData(
      ClipboardData(text: 'Unete a mi sala de Zapiti: $roomId'),
    );
    if (!mounted) return;
    setState(() {
      _status = 'Invitacion copiada: $roomId.';
    });
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
      // Si el leave falla, cerramos igualmente la conexión local.
    }

    _closeSocketIntentionally();

    if (!mounted) return;
    setState(() {
      _socket = null;
      _connectedRoomId = null;
      _roomSnapshot = null;
      _sessionStarted = false;
      _ready = false;
      _teamModalShownForCurrentRoom = false;
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

  int? _parseBotDifficulty(dynamic rawPlayers) {
    if (rawPlayers is! List) return null;
    for (final rawPlayer in rawPlayers) {
      if (rawPlayer is! Map) continue;
      final rawDifficulty = rawPlayer['aiDifficulty'];
      final difficulty = rawDifficulty is int
          ? rawDifficulty
          : int.tryParse(rawDifficulty?.toString() ?? '');
      if (difficulty != null) {
        return difficulty.clamp(1, 5);
      }
    }
    return null;
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
    if (!_profileReady && !showSession) {
      if (_showCreateAccount) {
        return _MultiplayerCreateAccountView(
          usernameController: _usernameController,
          nameController: _nameController,
          passwordController: _passwordController,
          status: _profileStatus,
          onCreate: _saveProfileAndContinue,
          onBackToLogin: () {
            setState(() {
              _showCreateAccount = false;
              _profileStatus = 'Inicia sesion para recuperar tus datos.';
            });
          },
        );
      }
      return _MultiplayerLoginView(
        usernameController: _usernameController,
        passwordController: _passwordController,
        status: _profileStatus,
        onLogin: _recoverProfile,
        onCreateAccount: () {
          setState(() {
            _showCreateAccount = true;
            _profileStatus = 'Crea tu usuario para guardar estadisticas.';
          });
        },
      );
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 180),
      child: showSession
          ? _MultiplayerSessionView(
              key: const ValueKey('multiplayer-session'),
              snapshot: _roomSnapshot!,
              playerId: _playerId,
              status: _status,
              playerStats: _playerStats,
              fallbackPlayerName: _playerName,
              fallbackTeamName: _teamName,
              rankingPairs: _rankingPairs,
              rankingMatches: _rankingMatches,
              canEnterGame: _multiplayerSessionReadyForGame(),
              onEnterGame: _enterGame,
              onLeaveRoom: _leaveRoom,
              onCopyInvitation: _copyRoomInvitation,
              onRequestRanking: _requestRanking,
            )
          : Column(
              key: const ValueKey('multiplayer-lobby'),
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Lobby multijugador', style: titleStyle),
                const SizedBox(height: 8),
                Text(
                  'Crea una sala, comparte el código y jugad en la misma mesa por WebSocket.',
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
                            color:
                                ZapitiColors.darkBrown.withValues(alpha: 0.12),
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
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: ZapitiColors.darkBrown.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: ZapitiColors.darkBrown.withValues(alpha: 0.12),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.account_circle_outlined,
                          color: ZapitiColors.wineRed,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                _username.isEmpty
                                    ? _playerName
                                    : '$_playerName (@$_username)',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: bodyStyle.copyWith(
                                  color: ZapitiColors.darkBrown,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              if (_selectedTeamName.isNotEmpty)
                                Text(
                                  'Equipo: $_selectedTeamName',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: bodyStyle.copyWith(
                                    fontSize:
                                        ((bodyStyle.fontSize ?? 12) * 0.88),
                                    color: ZapitiColors.darkBrown.withValues(
                                      alpha: 0.66,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Editar usuario',
                          onPressed: () {
                            setState(() {
                              _profileReady = false;
                              _showCreateAccount = true;
                              _profileStatus =
                                  'Actualiza nombre o contrasena.';
                            });
                          },
                          icon: const Icon(Icons.manage_accounts_outlined),
                          color: ZapitiColors.darkBrown,
                          constraints: const BoxConstraints.tightFor(
                            width: 36,
                            height: 36,
                          ),
                          padding: EdgeInsets.zero,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _roomController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    isDense: true,
                    labelText: 'Código de sala',
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
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 42,
                        child: ZapitiActionButton(
                          label: 'RANKING',
                          icon: Icons.leaderboard_outlined,
                          onPressed: _connecting ? null : _requestRanking,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SizedBox(
                        height: 42,
                        child: ZapitiActionButton(
                          label: 'COPIAR INV.',
                          icon: Icons.ios_share_outlined,
                          onPressed: _copyRoomInvitation,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _PlayerStatsCard(
                  stats: _playerStats,
                  fallbackPlayerName: _playerName,
                  fallbackTeamName: _teamName,
                ),
                if (_rankingRequested) ...[
                  const SizedBox(height: 8),
                  _RankingPanel(
                    pairs: _rankingPairs,
                    matches: _rankingMatches,
                  ),
                ],
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

class _MultiplayerLoginView extends StatelessWidget {
  final TextEditingController usernameController;
  final TextEditingController passwordController;
  final String status;
  final VoidCallback onLogin;
  final VoidCallback onCreateAccount;

  const _MultiplayerLoginView({
    required this.usernameController,
    required this.passwordController,
    required this.status,
    required this.onLogin,
    required this.onCreateAccount,
  });

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

    return Column(
      key: const ValueKey('multiplayer-login'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Iniciar sesion', style: titleStyle),
        const SizedBox(height: 8),
        Text(
          'Entra con tu usuario para recuperar tu ficha, equipos y ranking.',
          style: bodyStyle,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: usernameController,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9_.-]')),
            LengthLimitingTextInputFormatter(
              _MainMenuMultiplayerContentState._maxUsernameLength,
            ),
          ],
          textCapitalization: TextCapitalization.none,
          autocorrect: false,
          decoration: const InputDecoration(
            isDense: true,
            labelText: 'Usuario',
            prefixIcon: Icon(Icons.alternate_email),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: passwordController,
          obscureText: true,
          enableSuggestions: false,
          autocorrect: false,
          inputFormatters: [LengthLimitingTextInputFormatter(72)],
          decoration: const InputDecoration(
            isDense: true,
            labelText: 'Contrasena',
            prefixIcon: Icon(Icons.lock_outline),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 42,
          child: ZapitiActionButton(
            label: 'ENTRAR',
            icon: Icons.login,
            onPressed: onLogin,
            primary: true,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 42,
          child: ZapitiActionButton(
            label: 'CREAR USUARIO',
            icon: Icons.person_add_alt_1_outlined,
            onPressed: onCreateAccount,
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
            child: Text(status, style: bodyStyle),
          ),
        ),
      ],
    );
  }
}

class _MultiplayerCreateAccountView extends StatelessWidget {
  final TextEditingController usernameController;
  final TextEditingController nameController;
  final TextEditingController passwordController;
  final String status;
  final VoidCallback onCreate;
  final VoidCallback onBackToLogin;

  const _MultiplayerCreateAccountView({
    required this.usernameController,
    required this.nameController,
    required this.passwordController,
    required this.status,
    required this.onCreate,
    required this.onBackToLogin,
  });

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

    return Column(
      key: const ValueKey('multiplayer-create-account'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Crear usuario', style: titleStyle),
        const SizedBox(height: 8),
        Text(
          'Crea tu ficha para guardar partidas y formar equipos.',
          style: bodyStyle,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: usernameController,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9_.-]')),
            LengthLimitingTextInputFormatter(
              _MainMenuMultiplayerContentState._maxUsernameLength,
            ),
          ],
          textCapitalization: TextCapitalization.none,
          autocorrect: false,
          decoration: const InputDecoration(
            isDense: true,
            labelText: 'Usuario',
            prefixIcon: Icon(Icons.alternate_email),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: nameController,
          inputFormatters: [
            LengthLimitingTextInputFormatter(
              _MainMenuMultiplayerContentState._maxPlayerNameLength,
            ),
          ],
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            isDense: true,
            labelText: 'Nombre de jugador',
            prefixIcon: Icon(Icons.person_outline),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: passwordController,
          obscureText: true,
          enableSuggestions: false,
          autocorrect: false,
          inputFormatters: [LengthLimitingTextInputFormatter(72)],
          decoration: const InputDecoration(
            isDense: true,
            labelText: 'Contrasena',
            prefixIcon: Icon(Icons.lock_outline),
            border: OutlineInputBorder(),
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
                  icon: Icons.check,
                  onPressed: onCreate,
                  primary: true,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: SizedBox(
                height: 42,
                child: ZapitiActionButton(
                  label: 'VOLVER',
                  icon: Icons.arrow_back,
                  onPressed: onBackToLogin,
                ),
              ),
            ),
          ],
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
            child: Text(status, style: bodyStyle),
          ),
        ),
      ],
    );
  }
}

class _MultiplayerSessionView extends StatelessWidget {
  final MultiplayerRoomSnapshot snapshot;
  final String? playerId;
  final String status;
  final Map<String, dynamic> playerStats;
  final String fallbackPlayerName;
  final String fallbackTeamName;
  final List<Map<String, dynamic>> rankingPairs;
  final List<Map<String, dynamic>> rankingMatches;
  final bool canEnterGame;
  final VoidCallback onEnterGame;
  final VoidCallback onLeaveRoom;
  final VoidCallback onCopyInvitation;
  final VoidCallback onRequestRanking;

  const _MultiplayerSessionView({
    super.key,
    required this.snapshot,
    required this.playerId,
    required this.status,
    required this.playerStats,
    required this.fallbackPlayerName,
    required this.fallbackTeamName,
    required this.rankingPairs,
    required this.rankingMatches,
    required this.canEnterGame,
    required this.onEnterGame,
    required this.onLeaveRoom,
    required this.onCopyInvitation,
    required this.onRequestRanking,
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
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 42,
                child: ZapitiActionButton(
                  label: 'COPIAR INV.',
                  icon: Icons.ios_share_outlined,
                  onPressed: onCopyInvitation,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: SizedBox(
                height: 42,
                child: ZapitiActionButton(
                  label: 'RANKING',
                  icon: Icons.leaderboard_outlined,
                  onPressed: onRequestRanking,
                ),
              ),
            ),
          ],
        ),
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
        _PlayerStatsCard(
          stats: playerStats,
          fallbackPlayerName: fallbackPlayerName,
          fallbackTeamName: fallbackTeamName,
        ),
        const SizedBox(height: 8),
        if (rankingPairs.isNotEmpty || rankingMatches.isNotEmpty) ...[
          _RankingPanel(
            pairs: rankingPairs,
            matches: rankingMatches,
          ),
          const SizedBox(height: 8),
        ],
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

class _PlayerStatsCard extends StatelessWidget {
  final Map<String, dynamic> stats;
  final String fallbackPlayerName;
  final String fallbackTeamName;

  const _PlayerStatsCard({
    required this.stats,
    required this.fallbackPlayerName,
    required this.fallbackTeamName,
  });

  @override
  Widget build(BuildContext context) {
    final name = (stats['name']?.toString().trim().isNotEmpty ?? false)
        ? stats['name'].toString()
        : fallbackPlayerName;
    final teamName = (stats['teamName']?.toString().trim().isNotEmpty ?? false)
        ? stats['teamName'].toString()
        : fallbackTeamName;
    final played = _readInt(stats['played']);
    final wins = _readInt(stats['wins']);
    final losses = _readInt(stats['losses']);
    final pointsFor = _readInt(stats['pointsFor']);
    final pointsAgainst = _readInt(stats['pointsAgainst']);
    final winRate = played == 0 ? 0 : ((wins / played) * 100).round();
    final diff = pointsFor - pointsAgainst;
    final favoritePair = stats['favoritePair']?.toString().trim() ?? '';
    final lastPlayedAt = _readInt(stats['lastPlayedAt']);
    final bodyStyle = Theme.of(context).textTheme.bodySmall!.copyWith(
          color: ZapitiColors.darkBrown.withValues(alpha: 0.82),
          fontWeight: FontWeight.w800,
        );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: ZapitiColors.darkBrown.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: ZapitiColors.darkBrown.withValues(alpha: 0.12),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.account_circle_outlined,
                  size: 16,
                  color: ZapitiColors.wineRed,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Ficha del jugador',
                    style: bodyStyle.copyWith(fontWeight: FontWeight.w900),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              teamName.isEmpty ? name : '$name - $teamName',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: bodyStyle.copyWith(
                color: ZapitiColors.darkBrown,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _PlayerStatPill(label: 'Partidas', value: '$played'),
                _PlayerStatPill(label: 'V/D', value: '$wins/$losses'),
                _PlayerStatPill(label: 'Victorias', value: '$winRate%'),
                _PlayerStatPill(
                  label: 'Chinos',
                  value: diff >= 0 ? '+$diff' : '$diff',
                ),
              ],
            ),
            if (favoritePair.isNotEmpty || lastPlayedAt > 0) ...[
              const SizedBox(height: 6),
              Text(
                [
                  if (favoritePair.isNotEmpty) 'Pareja habitual: $favoritePair',
                  if (lastPlayedAt > 0)
                    'Ultima partida: ${_formatMatchDate(lastPlayedAt)}',
                ].join(' - '),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: bodyStyle.copyWith(
                  fontSize: ((bodyStyle.fontSize ?? 12) * 0.9),
                  color: ZapitiColors.darkBrown.withValues(alpha: 0.66),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PlayerStatPill extends StatelessWidget {
  final String label;
  final String value;

  const _PlayerStatPill({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final labelStyle = Theme.of(context).textTheme.bodySmall!.copyWith(
          color: ZapitiColors.darkBrown.withValues(alpha: 0.62),
          fontWeight: FontWeight.w900,
          fontSize: 10,
        );
    final valueStyle = Theme.of(context).textTheme.bodySmall!.copyWith(
          color: ZapitiColors.wineRed,
          fontWeight: FontWeight.w900,
        );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.46),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: ZapitiColors.darkBrown.withValues(alpha: 0.08),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: labelStyle),
            Text(value, style: valueStyle),
          ],
        ),
      ),
    );
  }
}

class _RankingPanel extends StatelessWidget {
  final List<Map<String, dynamic>> pairs;
  final List<Map<String, dynamic>> matches;

  const _RankingPanel({
    required this.pairs,
    required this.matches,
  });

  @override
  Widget build(BuildContext context) {
    final bodyStyle = Theme.of(context).textTheme.bodySmall!.copyWith(
          color: ZapitiColors.darkBrown.withValues(alpha: 0.82),
          fontWeight: FontWeight.w800,
        );
    final visiblePairs = pairs.take(8).toList();
    final visibleMatches = matches.take(5).toList();
    final panelHeight = (MediaQuery.sizeOf(context).height * 0.34)
        .clamp(190.0, 340.0)
        .toDouble();

    return DecoratedBox(
      decoration: BoxDecoration(
        color: ZapitiColors.darkBrown.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: ZapitiColors.darkBrown.withValues(alpha: 0.12),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: SizedBox(
          height: panelHeight,
          child: ListView(
            children: [
            Row(
              children: [
                const Icon(
                  Icons.leaderboard_outlined,
                  size: 16,
                  color: ZapitiColors.wineRed,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Ranking de parejas',
                    style: bodyStyle.copyWith(fontWeight: FontWeight.w900),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            if (visiblePairs.isEmpty)
              Text('Aun no hay partidas registradas.', style: bodyStyle)
            else ...[
              _RankingHeader(style: bodyStyle),
              const SizedBox(height: 4),
              for (var index = 0; index < visiblePairs.length; index++)
                Padding(
                  padding: EdgeInsets.only(top: index == 0 ? 0 : 5),
                  child: _RankingRow(
                    position: index + 1,
                    pair: visiblePairs[index],
                  ),
                ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(
                  Icons.history_outlined,
                  size: 16,
                  color: ZapitiColors.wineRed,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Ultimas partidas',
                    style: bodyStyle.copyWith(fontWeight: FontWeight.w900),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            if (visibleMatches.isEmpty)
              Text('Todavia no hay historial.', style: bodyStyle)
            else
              for (var index = 0; index < visibleMatches.length; index++)
                Padding(
                  padding: EdgeInsets.only(top: index == 0 ? 0 : 5),
                  child: _MatchHistoryRow(match: visibleMatches[index]),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RankingHeader extends StatelessWidget {
  final TextStyle style;

  const _RankingHeader({required this.style});

  @override
  Widget build(BuildContext context) {
    final headerStyle = style.copyWith(
      color: ZapitiColors.darkBrown.withValues(alpha: 0.62),
      fontSize: ((style.fontSize ?? 12) * 0.86),
      fontWeight: FontWeight.w900,
    );

    return Row(
      children: [
        const SizedBox(width: 24),
        Expanded(child: Text('Pareja', style: headerStyle)),
        SizedBox(
          width: 48,
          child: Text('V/P', textAlign: TextAlign.right, style: headerStyle),
        ),
        SizedBox(
          width: 48,
          child: Text('%', textAlign: TextAlign.right, style: headerStyle),
        ),
        SizedBox(
          width: 62,
          child: Text('Chinos', textAlign: TextAlign.right, style: headerStyle),
        ),
      ],
    );
  }
}

class _RankingRow extends StatelessWidget {
  final int position;
  final Map<String, dynamic> pair;

  const _RankingRow({
    required this.position,
    required this.pair,
  });

  @override
  Widget build(BuildContext context) {
    final name = pair['teamName']?.toString() ?? 'Pareja';
    final played = _readInt(pair['played']);
    final wins = _readInt(pair['wins']);
    final losses = _readInt(pair['losses']);
    final pointsFor = _readInt(pair['pointsFor']);
    final pointsAgainst = _readInt(pair['pointsAgainst']);
    final winRate = played == 0 ? 0 : ((wins / played) * 100).round();
    final diff = pointsFor - pointsAgainst;
    final textStyle = Theme.of(context).textTheme.bodySmall!.copyWith(
          color: ZapitiColors.darkBrown,
          fontWeight: FontWeight.w800,
        );

    return Row(
      children: [
        SizedBox(
          width: 24,
          child: Text('$position.', style: textStyle),
        ),
        Expanded(
          child: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textStyle.copyWith(fontWeight: FontWeight.w900),
          ),
        ),
        SizedBox(
          width: 48,
          child: Text(
            '$wins/$losses',
            textAlign: TextAlign.right,
            style: textStyle.copyWith(color: ZapitiColors.wineRed),
          ),
        ),
        SizedBox(
          width: 48,
          child: Text(
            '$winRate%',
            textAlign: TextAlign.right,
            style: textStyle,
          ),
        ),
        SizedBox(
          width: 62,
          child: Text(
            diff >= 0 ? '+$diff' : '$diff',
            textAlign: TextAlign.right,
            style: textStyle.copyWith(
              color: diff >= 0
                  ? Colors.green.shade700
                  : ZapitiColors.darkBrown.withValues(alpha: 0.72),
            ),
          ),
        ),
      ],
    );
  }
}

class _MatchHistoryRow extends StatelessWidget {
  final Map<String, dynamic> match;

  const _MatchHistoryRow({required this.match});

  @override
  Widget build(BuildContext context) {
    final score = match['score'] is Map ? match['score'] as Map : const {};
    final scoreOne = _readInt(score['1']);
    final scoreTwo = _readInt(score['2']);
    final winnerTeamId = _readInt(match['winnerTeamId']);
    final teamOne = _matchTeamName(match, '1');
    final teamTwo = _matchTeamName(match, '2');
    final date = _formatMatchDate(_readInt(match['finishedAt']));
    final textStyle = Theme.of(context).textTheme.bodySmall!.copyWith(
          color: ZapitiColors.darkBrown,
          fontWeight: FontWeight.w800,
        );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.46),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: ZapitiColors.darkBrown.withValues(alpha: 0.08),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '$teamOne vs $teamTwo',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textStyle.copyWith(fontWeight: FontWeight.w900),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '$scoreOne-$scoreTwo',
                  style: textStyle.copyWith(color: ZapitiColors.wineRed),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              'Gana equipo $winnerTeamId - $date',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textStyle.copyWith(
                fontSize: ((textStyle.fontSize ?? 12) * 0.9),
                color: ZapitiColors.darkBrown.withValues(alpha: 0.66),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

int _readInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

String _matchTeamName(Map<String, dynamic> match, String teamId) {
  final teams = match['teams'];
  final rawPlayers = teams is Map ? teams[teamId] : null;
  if (rawPlayers is! List) return 'Equipo $teamId';
  final names = [
    for (final rawPlayer in rawPlayers)
      if (rawPlayer is Map &&
          rawPlayer['isBot'] != true &&
          (rawPlayer['name']?.toString().trim().isNotEmpty ?? false))
        rawPlayer['name'].toString().trim(),
  ];
  if (names.isEmpty) return 'Equipo $teamId';
  return names.join(' / ');
}

String _formatMatchDate(int millis) {
  if (millis <= 0) return 'sin fecha';
  final date = DateTime.fromMillisecondsSinceEpoch(millis).toLocal();
  String two(int value) => value.toString().padLeft(2, '0');
  return '${two(date.day)}/${two(date.month)} ${two(date.hour)}:${two(date.minute)}';
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
  final VoidCallback onAbout;

  const _MainMenuOptionsContent({
    required this.audioEnabled,
    required this.onAudioChanged,
    required this.audioVolume,
    required this.onAudioVolumeChanged,
    required this.botSpeed,
    required this.onBotSpeedChanged,
    required this.confirmCardPlay,
    required this.onConfirmCardPlayChanged,
    required this.onAbout,
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
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Más',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: ZapitiColors.darkBrown,
                    fontWeight: FontWeight.w900,
                  ),
            ),
          ),
          const SizedBox(height: 8),
          ZapitiActionButton(
            label: 'ACERCA DE',
            icon: Icons.badge_outlined,
            onPressed: onAbout,
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
