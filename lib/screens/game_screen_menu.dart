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
  final VoidCallback onExit;
  final VoidCallback onStartTableTutorial;
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
  final ZapitiLanguage language;
  final ValueChanged<ZapitiLanguage> onLanguageChanged;
  final AppVersionCheckResult versionCheck;

  const _MainMenuScreen({
    required this.onPlay,
    required this.onTutorial,
    required this.onOptions,
    required this.onMultiplayer,
    required this.onAbout,
    required this.onExit,
    required this.onStartTableTutorial,
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
    required this.language,
    required this.onLanguageChanged,
    required this.versionCheck,
  });

  @override
  Widget build(BuildContext context) {
    return OrientationBuilder(
      builder: (context, orientation) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final shortest = min(constraints.maxWidth, constraints.maxHeight);
            final basePadding = shortest * 0.055;
            final safePadding = MediaQuery.paddingOf(context);
            final padding = EdgeInsets.fromLTRB(
              max(basePadding, safePadding.left + basePadding * 0.45),
              max(basePadding, safePadding.top + basePadding * 0.45),
              max(basePadding, safePadding.right + basePadding * 0.45),
              max(basePadding, safePadding.bottom + basePadding * 0.45),
            );
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
                      language: language,
                      onLanguageChanged: onLanguageChanged,
                      versionCheck: versionCheck,
                      onStartTableTutorial: onStartTableTutorial,
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
                      onAbout: onAbout,
                      onExit: onExit,
                      versionCheck: versionCheck,
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
            return Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  'assets/menu/portada.png',
                  fit: BoxFit.cover,
                  alignment: orientation == Orientation.portrait
                      ? Alignment.center
                      : const Alignment(0, -0.34),
                  errorBuilder: (_, __, ___) {
                    return const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            ZapitiColors.tableGreen,
                            ZapitiColors.darkBrown,
                          ],
                        ),
                      ),
                    );
                  },
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.black
                        .withValues(alpha: showingPanel ? 0.34 : 0.06),
                  ),
                ),
                Padding(
                  padding: padding,
                  child: showingPanel ? panelContent : actions,
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _MainMenuActions extends StatelessWidget {
  final VoidCallback onPlay;
  final VoidCallback onTutorial;
  final VoidCallback onOptions;
  final VoidCallback onMultiplayer;
  final VoidCallback onAbout;
  final VoidCallback onExit;
  final AppVersionCheckResult versionCheck;

  const _MainMenuActions({
    super.key,
    required this.onPlay,
    required this.onTutorial,
    required this.onOptions,
    required this.onMultiplayer,
    required this.onAbout,
    required this.onExit,
    required this.versionCheck,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final shortest = min(constraints.maxWidth, constraints.maxHeight);
        final gap = max(8.0, shortest * 0.032);
        final centerWidth =
            min(constraints.maxWidth * 0.52, shortest < 430 ? 220.0 : 260.0);
        final cornerWidth =
            min(constraints.maxWidth * 0.34, shortest < 430 ? 170.0 : 210.0);
        final centerActions = [
          ZapitiActionButton(
            label: context.tr('play'),
            icon: Icons.play_arrow,
            onPressed: onPlay,
            primary: true,
          ),
          ZapitiActionButton(
            label: context.tr('multiplayer'),
            icon: Icons.groups_outlined,
            onPressed: versionCheck.status == AppVersionCheckStatus.checking
                ? null
                : onMultiplayer,
          ),
          if (versionCheck.status == AppVersionCheckStatus.checking)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                versionCheck.multiplayerStatusMessage,
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: ZapitiColors.cardCream,
                  fontWeight: FontWeight.w900,
                  shadows: const [
                    Shadow(
                      color: Colors.black,
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
            ),
          ZapitiActionButton(
            label: context.tr('exit'),
            icon: Icons.logout,
            onPressed: onExit,
          ),
        ];
        final rightActions = [
          ZapitiActionButton(
            label: context.tr('tutorial'),
            icon: Icons.menu_book_outlined,
            onPressed: onTutorial,
          ),
          ZapitiActionButton(
            label: context.tr('options'),
            icon: Icons.settings_outlined,
            onPressed: onOptions,
          ),
        ];

        Widget verticalButtons(List<Widget> buttons, double width) {
          return SizedBox(
            width: width,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var index = 0; index < buttons.length; index++) ...[
                  buttons[index],
                  if (index != buttons.length - 1) SizedBox(height: gap),
                ],
              ],
            ),
          );
        }

        return Stack(
          fit: StackFit.expand,
          children: [
            Center(child: verticalButtons(centerActions, centerWidth)),
            Align(
              alignment: Alignment.bottomLeft,
              child: verticalButtons(
                [
                  ZapitiActionButton(
                    label: context.tr('about'),
                    icon: Icons.badge_outlined,
                    onPressed: onAbout,
                  ),
                ],
                cornerWidth,
              ),
            ),
            Align(
              alignment: Alignment.bottomRight,
              child: verticalButtons(rightActions, cornerWidth),
            ),
          ],
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
  final ZapitiLanguage language;
  final ValueChanged<ZapitiLanguage> onLanguageChanged;
  final AppVersionCheckResult versionCheck;
  final VoidCallback onStartTableTutorial;
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
    required this.language,
    required this.onLanguageChanged,
    required this.versionCheck,
    required this.onStartTableTutorial,
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
      _MainMenuPanel.tutorial => context.tr('tutorial'),
      _MainMenuPanel.options => context.tr('options'),
      _MainMenuPanel.multiplayer => context.tr('multiplayer'),
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
                    tooltip: context.tr('back'),
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
                    ? _MainMenuTutorialContent(
                        onStartTableTutorial: onStartTableTutorial,
                      )
                    : isMultiplayer
                        ? SingleChildScrollView(
                            child: SizedBox(
                              width: double.infinity,
                              child: _MainMenuMultiplayerContent(
                                onEnterGame: onEnterGame,
                                selectedCharacterId: selectedCharacterId,
                                onSelectedCharacterChanged:
                                    onSelectedCharacterChanged,
                                versionCheck: versionCheck,
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
                                language: language,
                                onLanguageChanged: onLanguageChanged,
                                onBack: onBack,
                              ),
                            ),
                          ),
              ),
              SizedBox(height: panelGap),
              ZapitiActionButton(
                label: context.tr('back'),
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
  final VoidCallback onStartTableTutorial;

  const _MainMenuTutorialContent({
    required this.onStartTableTutorial,
  });

  @override
  State<_MainMenuTutorialContent> createState() =>
      _MainMenuTutorialContentState();
}

class _MainMenuTutorialContentState extends State<_MainMenuTutorialContent> {
  _TutorialMode _mode = _TutorialMode.lessons;
  int _stepIndex = 0;
  int _practiceIndex = 0;
  final Map<int, int> _selectedAnswers = {};
  final Map<int, int> _practiceAnswers = {};

  static const _lessonSections = [
    _TutorialLessonSection(
      title: 'tutorialGuideIntroTitle',
      body: [
        'tutorialGuideIntroBody1',
        'tutorialGuideIntroBody2',
      ],
      icon: Icons.school_outlined,
    ),
    _TutorialLessonSection(
      title: 'tutorialGuideOriginTitle',
      body: [
        'tutorialGuideOriginBody1',
        'tutorialGuideOriginBody2',
      ],
      icon: Icons.auto_stories_outlined,
    ),
    _TutorialLessonSection(
      title: 'tutorialGuideObjectiveTitle',
      body: [
        'tutorialGuideObjectiveBody1',
        'tutorialGuideObjectiveBody2',
      ],
      icon: Icons.emoji_events_outlined,
    ),
    _TutorialLessonSection(
      title: 'tutorialGuideTurnsTitle',
      body: [
        'tutorialGuideTurnsBody1',
        'tutorialGuideTurnsBody2',
        'tutorialGuideTurnsBody3',
      ],
      icon: Icons.sync_alt_outlined,
    ),
    _TutorialLessonSection(
      title: 'tutorialGuideCardsTitle',
      body: [
        'tutorialGuideCardsBody1',
        'tutorialGuideCardsBody2',
      ],
      icon: Icons.style_outlined,
    ),
    _TutorialLessonSection(
      title: 'tutorialGuideTeamplayTitle',
      body: [
        'tutorialGuideTeamplayBody1',
        'tutorialGuideTeamplayBody2',
      ],
      icon: Icons.groups_2_outlined,
    ),
    _TutorialLessonSection(
      title: 'tutorialGuideSignalsTitle',
      body: [
        'tutorialGuideSignalsBody1',
        'tutorialGuideSignalsBody2',
      ],
      icon: Icons.visibility_outlined,
    ),
    _TutorialLessonSection(
      title: 'tutorialGuideTrucoTitle',
      body: [
        'tutorialGuideTrucoBody1',
        'tutorialGuideTrucoBody2',
      ],
      icon: Icons.campaign_outlined,
    ),
    _TutorialLessonSection(
      title: 'tutorialGuideBluffTitle',
      body: [
        'tutorialGuideBluffBody1',
        'tutorialGuideBluffBody2',
      ],
      icon: Icons.psychology_alt_outlined,
    ),
    _TutorialLessonSection(
      title: 'tutorialGuideAlVerTitle',
      body: [
        'tutorialGuideAlVerBody1',
        'tutorialGuideAlVerBody2',
      ],
      icon: Icons.flag_outlined,
    ),
    _TutorialLessonSection(
      title: 'tutorialGuideFirstStepsTitle',
      body: [
        'tutorialGuideFirstStepsBody1',
        'tutorialGuideFirstStepsBody2',
      ],
      icon: Icons.checklist_outlined,
    ),
  ];

  static const _steps = [
    _TutorialStep(
      title: 'tutorialObjectiveTitle',
      body: 'tutorialObjectiveBody',
      icon: Icons.groups_outlined,
      prompt: 'tutorialObjectivePrompt',
      options: ['tutorialObjectiveOption1', 'tutorialObjectiveOption2'],
      correctIndex: 0,
      answer: 'tutorialObjectiveAnswer',
    ),
    _TutorialStep(
      title: 'tutorialHandsTitle',
      body: 'tutorialHandsBody',
      icon: Icons.style_outlined,
      prompt: 'tutorialHandsPrompt',
      options: ['tutorialHandsOption1', 'tutorialHandsOption2'],
      correctIndex: 0,
      answer: 'tutorialHandsAnswer',
    ),
    _TutorialStep(
      title: 'tutorialCardsTitle',
      body: 'tutorialCardsBody',
      icon: Icons.workspace_premium_outlined,
      prompt: 'tutorialCardsPrompt',
      options: ['tutorialCardsOption1', 'tutorialCardsOption2'],
      correctIndex: 0,
      answer: 'tutorialCardsAnswer',
    ),
    _TutorialStep(
      title: 'tutorialFinePlayTitle',
      body: 'tutorialFinePlayBody',
      icon: Icons.psychology_alt_outlined,
      prompt: 'tutorialFinePlayPrompt',
      options: ['tutorialFinePlayOption1', 'tutorialFinePlayOption2'],
      correctIndex: 0,
      answer: 'tutorialFinePlayAnswer',
    ),
    _TutorialStep(
      title: 'tutorialTrucoTitle',
      body: 'tutorialTrucoBody',
      icon: Icons.campaign_outlined,
      prompt: 'tutorialTrucoPrompt',
      options: ['tutorialTrucoOption1', 'tutorialTrucoOption2'],
      correctIndex: 0,
      answer: 'tutorialTrucoAnswer',
    ),
    _TutorialStep(
      title: 'tutorialSignalsTitle',
      body: 'tutorialSignalsBody',
      icon: Icons.visibility_outlined,
      prompt: 'tutorialSignalsPrompt',
      options: ['tutorialSignalsOption1', 'tutorialSignalsOption2'],
      correctIndex: 0,
      answer: 'tutorialSignalsAnswer',
    ),
    _TutorialStep(
      title: 'tutorialVoyMataTitle',
      body: 'tutorialVoyMataBody',
      icon: Icons.record_voice_over_outlined,
      prompt: 'tutorialVoyMataPrompt',
      options: ['tutorialVoyMataOption1', 'tutorialVoyMataOption2'],
      correctIndex: 0,
      answer: 'tutorialVoyMataAnswer',
    ),
    _TutorialStep(
      title: 'tutorialAlVerTitle',
      body: 'tutorialAlVerBody',
      icon: Icons.flag_outlined,
      prompt: 'tutorialAlVerPrompt',
      options: ['tutorialAlVerOption1', 'tutorialAlVerOption2'],
      correctIndex: 0,
      answer: 'tutorialAlVerAnswer',
    ),
  ];

  static const _practiceChallenges = [
    _PracticeChallenge(
      title: 'practiceSaveStrongTitle',
      situation: 'practiceSaveStrongSituation',
      icon: Icons.savings_outlined,
      tableCards: [
        SpanishCard(value: 7, suit: Suit.oros),
        SpanishCard(value: 3, suit: Suit.copas),
      ],
      handCards: [
        SpanishCard(value: 4, suit: Suit.copas),
        SpanishCard(value: 1, suit: Suit.espadas),
      ],
      options: ['practiceSaveStrongOption1', 'practiceSaveStrongOption2'],
      correctIndex: 0,
      feedback: 'practiceSaveStrongFeedback',
    ),
    _PracticeChallenge(
      title: 'practiceSaveRoundTitle',
      situation: 'practiceSaveRoundSituation',
      icon: Icons.shield_outlined,
      tableCards: [
        SpanishCard(value: 2, suit: Suit.copas),
      ],
      handCards: [
        SpanishCard(value: 3, suit: Suit.bastos),
        SpanishCard(value: 7, suit: Suit.copas),
      ],
      options: ['practiceSaveRoundOption1', 'practiceSaveRoundOption2'],
      correctIndex: 0,
      feedback: 'practiceSaveRoundFeedback',
    ),
    _PracticeChallenge(
      title: 'practiceBadTrucoTitle',
      situation: 'practiceBadTrucoSituation',
      icon: Icons.campaign_outlined,
      tableCards: [
        SpanishCard(value: 7, suit: Suit.copas),
        SpanishCard(value: 5, suit: Suit.oros),
      ],
      handCards: [
        SpanishCard(value: 12, suit: Suit.copas),
        SpanishCard(value: 6, suit: Suit.bastos),
      ],
      options: ['practiceBadTrucoOption1', 'practiceBadTrucoOption2'],
      correctIndex: 0,
      feedback: 'practiceBadTrucoFeedback',
    ),
    _PracticeChallenge(
      title: 'practiceReadSignalTitle',
      situation: 'practiceReadSignalSituation',
      icon: Icons.visibility_outlined,
      tableCards: [
        SpanishCard(value: 6, suit: Suit.espadas),
      ],
      handCards: [
        SpanishCard(value: 4, suit: Suit.oros),
        SpanishCard(value: 1, suit: Suit.bastos),
      ],
      options: ['practiceReadSignalOption1', 'practiceReadSignalOption2'],
      correctIndex: 0,
      feedback: 'practiceReadSignalFeedback',
    ),
    _PracticeChallenge(
      title: 'practiceAlVerTitle',
      situation: 'practiceAlVerSituation',
      icon: Icons.flag_outlined,
      tableCards: [],
      handCards: [
        SpanishCard(value: 12, suit: Suit.oros),
        SpanishCard(value: 6, suit: Suit.copas),
        SpanishCard(value: 4, suit: Suit.espadas),
      ],
      options: ['practiceAlVerOption1', 'practiceAlVerOption2'],
      correctIndex: 0,
      feedback: 'practiceAlVerFeedback',
    ),
  ];

  void _previousStep() {
    setState(() {
      _stepIndex = (_stepIndex - 1 + _steps.length) % _steps.length;
    });
  }

  void _nextStep() {
    final step = _steps[_stepIndex];
    final selectedAnswer = _selectedAnswers[_stepIndex];
    if (step.prompt != null && selectedAnswer != step.correctIndex) {
      return;
    }
    setState(() {
      _stepIndex = (_stepIndex + 1) % _steps.length;
    });
  }

  void _previousPractice() {
    setState(() {
      _practiceIndex = (_practiceIndex - 1 + _practiceChallenges.length) %
          _practiceChallenges.length;
    });
  }

  void _nextPractice() {
    final challenge = _practiceChallenges[_practiceIndex];
    final selectedAnswer = _practiceAnswers[_practiceIndex];
    if (selectedAnswer != challenge.correctIndex) {
      return;
    }
    setState(() {
      _practiceIndex = (_practiceIndex + 1) % _practiceChallenges.length;
    });
  }

  Widget _modeSelector(bool compact) {
    return SegmentedButton<_TutorialMode>(
      segments: [
        ButtonSegment(
          value: _TutorialMode.lessons,
          icon: const Icon(Icons.menu_book_outlined),
          label: Text(context.tr('tutorialLessons')),
        ),
        ButtonSegment(
          value: _TutorialMode.practice,
          icon: const Icon(Icons.touch_app_outlined),
          label: Text(context.tr('tutorialPracticeTab')),
        ),
      ],
      selected: {_mode},
      onSelectionChanged: (selected) {
        setState(() {
          _mode = selected.first;
        });
      },
      showSelectedIcon: false,
      style: ButtonStyle(
        visualDensity: compact ? VisualDensity.compact : VisualDensity.standard,
        textStyle: WidgetStatePropertyAll(
          TextStyle(
            fontSize: compact ? 10 : 12,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
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
        final modeSelectorHeight = compact ? 36.0 : 46.0;
        final contentHeight = max(0.0, maxHeight - modeSelectorHeight);
        final showPrompt = contentHeight >= 390 && step.prompt != null;
        final visualHeight = max(
          compact ? 96.0 : 128.0,
          min(
            contentHeight * (showPrompt ? 0.34 : 0.50),
            showPrompt ? 180.0 : 220.0,
          ),
        );
        final cardWidth = min(
          shortest * 0.22,
          min(visualHeight * 0.74, 110.0),
        );
        final selectedAnswer = _selectedAnswers[_stepIndex];

        if (_mode == _TutorialMode.practice) {
          final challenge = _practiceChallenges[_practiceIndex];
          final selectedPracticeAnswer = _practiceAnswers[_practiceIndex];
          final answerIsCorrect =
              selectedPracticeAnswer == challenge.correctIndex;
          final showPracticePrompt = contentHeight >= 330;
          final practiceVisualHeight = max(
            compact ? 82.0 : 96.0,
            min(contentHeight * 0.30, 124.0),
          );

          return Column(
            children: [
              _modeSelector(compact),
              SizedBox(height: compact ? 4 : 8),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.only(bottom: compact ? 8 : 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color:
                              ZapitiColors.tableGreen.withValues(alpha: 0.92),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: ZapitiColors.oldGold.withValues(alpha: 0.72),
                          ),
                        ),
                        child: SizedBox(
                          height: practiceVisualHeight,
                          width: double.infinity,
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 180),
                            child: _PracticeVisual(
                              key: ValueKey(_practiceIndex),
                              challenge: challenge,
                              cardWidth: cardWidth,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: compact ? 6 : 10),
                      Row(
                        children: [
                          Icon(
                            challenge.icon,
                            color: ZapitiColors.wineRed,
                            size: compact ? 18 : 24,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              context.tr(challenge.title),
                              maxLines: compact ? 2 : 1,
                              overflow: TextOverflow.ellipsis,
                              style: titleStyle,
                            ),
                          ),
                          SizedBox(
                            width: compact ? 76 : 94,
                            height: compact ? 28 : 32,
                            child: ZapitiActionButton(
                              label: context.tr('tutorialTableUpper'),
                              icon: Icons.table_bar_outlined,
                              onPressed: widget.onStartTableTutorial,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: compact ? 4 : 6),
                      Text(
                        context.tr(challenge.situation),
                        style: bodyStyle,
                      ),
                      if (showPracticePrompt) ...[
                        SizedBox(height: compact ? 6 : 10),
                        _PracticeDecisionPrompt(
                          challenge: challenge,
                          selectedIndex: selectedPracticeAnswer,
                          onSelected: (index) {
                            setState(() {
                              _practiceAnswers[_practiceIndex] = index;
                            });
                          },
                        ),
                      ],
                      SizedBox(height: compact ? 8 : 12),
                      Row(
                        children: [
                          IconButton(
                            tooltip: 'Anterior',
                            onPressed: _previousPractice,
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
                                for (var index = 0;
                                    index < _practiceChallenges.length;
                                    index++)
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 160),
                                    width: index == _practiceIndex
                                        ? (compact ? 15 : 18)
                                        : (compact ? 6 : 8),
                                    height: compact ? 6 : 8,
                                    margin: EdgeInsets.symmetric(
                                      horizontal: compact ? 2 : 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: index == _practiceIndex
                                          ? (selectedPracticeAnswer == null
                                              ? ZapitiColors.wineRed
                                              : answerIsCorrect
                                                  ? ZapitiColors.tableGreenDark
                                                  : ZapitiColors.wineRed)
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
                            onPressed: _nextPractice,
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
                  ),
                ),
              ),
            ],
          );
        }
        return Column(
          children: [
            _modeSelector(compact),
            SizedBox(height: compact ? 4 : 8),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.only(bottom: compact ? 8 : 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
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
                    SizedBox(height: compact ? 8 : 12),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: ZapitiColors.wineRed.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: ZapitiColors.oldGold.withValues(alpha: 0.46),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.tr('tutorialGuideTitle'),
                              style: titleStyle,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              context.tr('tutorialGuideSubtitle'),
                              style: bodyStyle,
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: compact ? 8 : 12),
                    for (final section in _lessonSections) ...[
                      _TutorialLessonCard(section: section),
                      SizedBox(height: compact ? 8 : 12),
                    ],
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.56),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: ZapitiColors.darkBrown.withValues(alpha: 0.12),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  step.icon,
                                  color: ZapitiColors.wineRed,
                                  size: compact ? 18 : 22,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    context.tr(step.title),
                                    style: titleStyle,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              context.tr(step.body),
                              style: bodyStyle,
                            ),
                            if (showPrompt) ...[
                              const SizedBox(height: 10),
                              _TutorialDecisionPrompt(
                                step: step,
                                selectedIndex: selectedAnswer,
                                onSelected: (index) {
                                  setState(() {
                                    _selectedAnswers[_stepIndex] = index;
                                  });
                                },
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  IconButton(
                                    tooltip: 'Anterior',
                                    onPressed: _previousStep,
                                    icon: const Icon(Icons.chevron_left),
                                    color: ZapitiColors.darkBrown,
                                  ),
                                  Expanded(
                                    child: Center(
                                      child: Text(
                                        context.tr(
                                          'tutorialQuestion',
                                          params: {
                                            'current': _stepIndex + 1,
                                            'total': _steps.length,
                                          },
                                        ),
                                        style: bodyStyle,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    tooltip: 'Siguiente',
                                    onPressed: _nextStep,
                                    icon: const Icon(Icons.chevron_right),
                                    color: ZapitiColors.darkBrown,
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: compact ? 8 : 12),
                    ZapitiActionButton(
                      label: context.tr('tutorialStartPractice'),
                      icon: Icons.table_bar_outlined,
                      onPressed: widget.onStartTableTutorial,
                      primary: true,
                    ),
                  ],
                ),
              ),
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

class _TutorialLessonSection {
  final String title;
  final List<String> body;
  final IconData icon;

  const _TutorialLessonSection({
    required this.title,
    required this.body,
    required this.icon,
  });
}

enum _TutorialMode { lessons, practice }

class _PracticeChallenge {
  final String title;
  final String situation;
  final IconData icon;
  final List<SpanishCard> tableCards;
  final List<SpanishCard> handCards;
  final List<String> options;
  final int correctIndex;
  final String feedback;

  const _PracticeChallenge({
    required this.title,
    required this.situation,
    required this.icon,
    required this.tableCards,
    required this.handCards,
    required this.options,
    required this.correctIndex,
    required this.feedback,
  });
}

class _TutorialLessonCard extends StatelessWidget {
  final _TutorialLessonSection section;

  const _TutorialLessonCard({
    required this.section,
  });

  @override
  Widget build(BuildContext context) {
    final titleStyle = Theme.of(context).textTheme.titleSmall?.copyWith(
          color: ZapitiColors.darkBrown,
          fontWeight: FontWeight.w900,
        );
    final bodyStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: ZapitiColors.darkBrown.withValues(alpha: 0.86),
          height: 1.28,
          fontWeight: FontWeight.w700,
        );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.56),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: ZapitiColors.darkBrown.withValues(alpha: 0.12),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  section.icon,
                  color: ZapitiColors.wineRed,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    context.tr(section.title),
                    style: titleStyle,
                  ),
                ),
              ],
            ),
            for (final bodyKey in section.body) ...[
              const SizedBox(height: 6),
              Text(
                context.tr(bodyKey),
                style: bodyStyle,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PracticeDecisionPrompt extends StatelessWidget {
  final _PracticeChallenge challenge;
  final int? selectedIndex;
  final ValueChanged<int> onSelected;

  const _PracticeDecisionPrompt({
    required this.challenge,
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final answerIsCorrect = selectedIndex == challenge.correctIndex;
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
              context.tr('chooseBestMove'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: bodyStyle,
            ),
            const SizedBox(height: 5),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                for (var index = 0; index < challenge.options.length; index++)
                  ChoiceChip(
                    label: Text(context.tr(challenge.options[index])),
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
            if (selectedIndex != null) ...[
              const SizedBox(height: 4),
              Text(
                answerIsCorrect
                    ? context.tr(challenge.feedback)
                    : context.tr(
                        'guidedAlmost',
                        params: {'message': context.tr(challenge.feedback)},
                      ),
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
              context.tr(step.prompt!),
              maxLines: 2,
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
                    label: Text(context.tr(step.options[index])),
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
                answerIsCorrect
                    ? context.tr(step.answer!)
                    : context.tr(
                        'guidedAlmost',
                        params: {'message': context.tr(step.answer!)},
                      ),
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

class _PracticeVisual extends StatelessWidget {
  final _PracticeChallenge challenge;
  final double cardWidth;

  const _PracticeVisual({
    super.key,
    required this.challenge,
    required this.cardWidth,
  });

  @override
  Widget build(BuildContext context) {
    final labelStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
          color: ZapitiColors.cardCream,
          fontWeight: FontWeight.w900,
        );
    final tableCards = challenge.tableCards;
    final handCards = challenge.handCards;

    Widget cardRow(List<SpanishCard> cards, String emptyLabel) {
      if (cards.isEmpty) {
        return Container(
          width: cardWidth * 1.45,
          height: cardWidth * 1.25,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: ZapitiColors.darkBrown.withValues(alpha: 0.20),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: ZapitiColors.oldGold.withValues(alpha: 0.38),
            ),
          ),
          child: Text(
            emptyLabel,
            textAlign: TextAlign.center,
            style: labelStyle,
          ),
        );
      }

      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var index = 0; index < cards.length; index++) ...[
            ZapitiCardWidget(
              card: cards[index],
              width: cardWidth * (cards.length > 2 ? 0.82 : 0.92),
            ),
            if (index != cards.length - 1) SizedBox(width: cardWidth * 0.08),
          ],
        ],
      );
    }

    return Center(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(context.tr('table'), style: labelStyle),
                const SizedBox(height: 5),
                cardRow(tableCards, context.tr('noCards')),
              ],
            ),
            SizedBox(width: cardWidth * 0.34),
            Icon(
              challenge.icon,
              color: ZapitiColors.oldGold,
              size: cardWidth * 0.72,
            ),
            SizedBox(width: cardWidth * 0.34),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(context.tr('yourHand'), style: labelStyle),
                const SizedBox(height: 5),
                cardRow(handCards, context.tr('decide')),
              ],
            ),
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
          3 => _TutorialSmartPlayVisual(cardWidth: cardWidth),
          4 => _TutorialTrucoVisual(cardWidth: cardWidth),
          5 => _TutorialSignalsVisual(cardWidth: cardWidth),
          6 => _TutorialCommandVisual(cardWidth: cardWidth),
          _ => _TutorialAlVerVisual(cardWidth: cardWidth),
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
            context.tr('trucoUpper'),
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

class _TutorialSmartPlayVisual extends StatelessWidget {
  final double cardWidth;

  const _TutorialSmartPlayVisual({required this.cardWidth});

  @override
  Widget build(BuildContext context) {
    final labelStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
          color: ZapitiColors.cardCream,
          fontWeight: FontWeight.w900,
        );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(context.tr('partnerWins'), style: labelStyle),
            const SizedBox(height: 4),
            ZapitiCardWidget(
              card: const SpanishCard(value: 7, suit: Suit.oros),
              width: cardWidth,
            ),
          ],
        ),
        SizedBox(width: cardWidth * 0.28),
        Icon(
          Icons.keyboard_double_arrow_right,
          color: ZapitiColors.oldGold,
          size: cardWidth * 0.72,
        ),
        SizedBox(width: cardWidth * 0.28),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(context.tr('playLow'), style: labelStyle),
            const SizedBox(height: 4),
            ZapitiCardWidget(
              card: const SpanishCard(value: 4, suit: Suit.copas),
              width: cardWidth,
            ),
          ],
        ),
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
        Text(context.tr('mainOrder'), style: labelStyle),
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
            context.tr('thenCardOrder'),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: labelStyle,
          ),
        ),
      ],
    );
  }
}

class _TutorialCommandVisual extends StatelessWidget {
  final double cardWidth;

  const _TutorialCommandVisual({required this.cardWidth});

  @override
  Widget build(BuildContext context) {
    final labelStyle = Theme.of(context).textTheme.titleSmall?.copyWith(
          color: ZapitiColors.cardCream,
          fontWeight: FontWeight.w900,
        );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _TutorialAvatar(
          path: CharacterAssets.neutral('p1'),
          size: cardWidth * 1.45,
        ),
        SizedBox(width: cardWidth * 0.22),
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: cardWidth * 0.22,
            vertical: cardWidth * 0.14,
          ),
          decoration: BoxDecoration(
            color: ZapitiColors.wineRed,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: ZapitiColors.oldGold, width: 2),
          ),
          child: Text(context.tr('voyATiUpper'), style: labelStyle),
        ),
        SizedBox(width: cardWidth * 0.22),
        _TutorialAvatar(
          path: CharacterAssets.neutral('p3'),
          size: cardWidth * 1.45,
        ),
      ],
    );
  }
}

class _TutorialAlVerVisual extends StatelessWidget {
  final double cardWidth;

  const _TutorialAlVerVisual({required this.cardWidth});

  @override
  Widget build(BuildContext context) {
    final scoreStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
          color: ZapitiColors.cardCream,
          fontWeight: FontWeight.w900,
        );
    final labelStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
          color: ZapitiColors.oldGold,
          fontWeight: FontWeight.w900,
        );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('29', style: scoreStyle),
            Text(context.tr('alVerShort'), style: labelStyle),
          ],
        ),
        SizedBox(width: cardWidth * 0.25),
        Icon(
          Icons.visibility_outlined,
          color: ZapitiColors.oldGold,
          size: cardWidth * 0.76,
        ),
        SizedBox(width: cardWidth * 0.25),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ZapitiCardWidget(
              card: const SpanishCard(value: 5, suit: Suit.copas),
              width: cardWidth * 0.86,
            ),
            const SizedBox(height: 4),
            Text(context.tr('playOrHome'), style: labelStyle),
          ],
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
  final AppVersionCheckResult versionCheck;

  const _MainMenuMultiplayerContent({
    required this.onEnterGame,
    required this.selectedCharacterId,
    required this.onSelectedCharacterChanged,
    required this.versionCheck,
  });

  @override
  State<_MainMenuMultiplayerContent> createState() =>
      _MainMenuMultiplayerContentState();
}

class _MainMenuMultiplayerContentState
    extends State<_MainMenuMultiplayerContent> {
  static const _maxPlayerNameLength = 18;
  static const _maxUsernameLength = 20;
  static const _maxTeamNameLength = 22;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _teamNameController = TextEditingController();
  final TextEditingController _roomController = TextEditingController();
  GameSocket? _socket;
  String? _playerId;
  String? _sessionToken;
  String? _profilePasswordFallback;
  String? _connectedRoomId;
  MultiplayerRoomSnapshot? _roomSnapshot;
  bool _keepSocketAliveOnDispose = false;
  bool _connecting = false;
  Future<bool>? _pendingConnection;
  int _connectionGeneration = 0;
  bool _sessionStarted = false;
  bool _autoEnterQueued = false;
  _ServerConnectionState _connectionState = _ServerConnectionState.idle;
  String _status = '';
  bool _ready = false;
  bool _profileReady = false;
  bool _showCreateAccount = false;
  bool _profileLoginInProgress = false;
  bool _teamModalShownForCurrentRoom = false;
  bool _teamDialogAutoClosed = false;
  bool _allowPassHandForRoom = false;
  String? _teamDialogTeammatePlayerId;
  BuildContext? _teamDialogContext;
  String? _pendingRoomAction;
  bool _roomActionRetriedWithoutCharacter = false;
  bool _roomActionRetriedWithoutSession = false;
  String _profileStatus = '';
  late String _selectedCharacterId;
  String? _confirmedCharacterId;
  bool _characterSelectionReleased = false;
  String? _teamPromptConfirmedCharacterId;
  String? _teamPromptDismissedCharacterId;
  BuildContext? _characterConfirmDialogContext;
  Map<String, dynamic> _playerStats = const {};
  List<Map<String, dynamic>> _rankingPairs = const [];
  List<Map<String, dynamic>> _rankingMatches = const [];
  List<Map<String, dynamic>> _playerTeams = const [];
  String? _selectedPairId;
  bool _teamsLoaded = false;
  bool _rankingRequested = false;
  bool _didInitializeLocalizedTexts = false;
  static const bool _teamSelectionFlowEnabled = false;

  String _tr(String key, {Map<String, Object?> params = const {}}) {
    return context.tr(key, params: params);
  }

  void _logTeamFlow(String event, Map<String, Object?> fields) {
    ZapitiLogger.debug('team_flow', event, fields: fields);
  }

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
      _connectedRoomId = session.activeRoomId;
      if (session.activeRoomId != null) {
        _roomController.text = session.activeRoomId!;
      }
      _sessionStarted = _snapshotStartsGame(session.roomSnapshot);
      _connectionState = _ServerConnectionState.connected;
      _status = _tr('multiplayerConnectedToRoom');

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
        _clearSessionAfterConnectionLoss(_tr('multiplayerConnectionLost'));
      };
      _socket!.onDone = () {
        _clearSessionAfterConnectionLoss(_tr('multiplayerConnectionLost'));
      };
    } else {
      unawaited(_loadSavedPlayerProfile());
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didInitializeLocalizedTexts) return;
    _didInitializeLocalizedTexts = true;
    _status = _tr('multiplayerReadyToConnect');
    _profileStatus = _tr('multiplayerProfileSetup');
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
  String? get _usableProfilePassword {
    final password = _profilePassword;
    if (password.isNotEmpty) return password;
    return _profilePasswordFallback;
  }

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
    if (_nameController.text == cleaned) return;
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
    await AccountPrivacyService.clearLocalMultiplayerProfile();
    if (!mounted || _roomSnapshot != null) return;
    _playerId = null;
    _sessionToken = null;
    _setUsernameField('');
    _passwordController.clear();
    _setTeamNameField('');
    if (mounted) {
      setState(() {
        _profileReady = false;
        _profileStatus = _tr('multiplayerProfileRecover');
      });
    }
  }

  Future<void> _savePlayerName(String playerName) async {
    return;
  }

  Future<void> _savePlayerId(String playerId) async {
    return;
  }

  Future<void> _saveUsername(String username) async {
    return;
  }

  Future<void> _saveSessionToken(String sessionToken) async {
    return;
  }

  Future<void> _clearSavedSessionToken() async {
    return;
  }

  Future<void> _saveTeamName(String teamName) async {
    return;
  }

  String _createPersistentPlayerId() {
    final randomValue = Random().nextInt(0x7fffffff);
    return 'player_${DateTime.now().microsecondsSinceEpoch}_$randomValue';
  }

  String get _serverUrl => ServerConfig.websocketUrl;

  String get _localPlayerId => _playerId ??= _createPersistentPlayerId();

  void _setConnectionState(
    _ServerConnectionState state, {
    required String status,
  }) {
    ZapitiLogger.info('lobby', 'connection_state_changed', fields: {
      'state': state.name,
      'status': status,
      'roomId': _connectedRoomId,
      'sessionStarted': _sessionStarted,
    });
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
    ZapitiLogger.warn('lobby', 'session_cleared_after_connection_loss',
        fields: {
          'status': status,
          'preserveSocket': preserveSocket,
          'connectionState': connectionState.name,
          'roomId': _connectedRoomId,
          'sessionStarted': _sessionStarted,
        });
    if (!preserveSocket) {
      final socket = _socket;
      socket?.onMessage = null;
      socket?.onError = null;
      socket?.onDone = null;
      MultiplayerSessionStore.instance.clearAll();
    } else {
      MultiplayerSessionStore.instance.socket = _socket;
      MultiplayerSessionStore.instance.roomSnapshot = _roomSnapshot;
    }
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
    ZapitiLogger.info('lobby', 'socket_close_intentional', fields: {
      'roomId': _connectedRoomId,
      'sessionStarted': _sessionStarted,
    });
    _connectionGeneration += 1;
    _pendingConnection = null;
    _socket = null;
    socket.close();
  }

  Set<String> _occupiedCharacterIdsByOtherPlayers() {
    final snapshot = _roomSnapshot;
    final localId = _playerId;
    if (snapshot == null || localId == null) return const {};
    return {
      for (final seat in snapshot.seats)
        if (seat.playerId != localId &&
            seat.characterId != null &&
            seat.characterId!.isNotEmpty)
          seat.characterId!,
    };
  }

  Map<String, String> _characterTeamBadges() {
    return {
      for (final characterId in CharacterAssets.characterIds)
        characterId: switch (characterId) {
          'p1' || 'p3' => 'Eq1',
          'p2' || 'p4' => 'Eq2',
          _ => '',
        },
    };
  }

  String _phaseLabel(String phase) {
    return switch (phase) {
      'starting' => _tr('multiplayerPhaseStarting'),
      'playing' => _tr('multiplayerPhasePlaying'),
      'finished' => _tr('multiplayerPhaseFinished'),
      _ => _tr('multiplayerPhaseOpen'),
    };
  }

  void _syncSelectedCharacterFromRoom() {
    final snapshot = _roomSnapshot;
    if (snapshot == null) return;
    final localSeat = _localSeatFor(snapshot);
    if (localSeat == null) return;
    final characterId = localSeat.characterId;
    if (characterId == null ||
        characterId.isEmpty ||
        !CharacterAssets.characterIds.contains(characterId)) {
      setState(() {
        _characterSelectionReleased = true;
        _confirmedCharacterId = null;
        _teamPromptConfirmedCharacterId = null;
        _teamPromptDismissedCharacterId = null;
      });
      return;
    }
    setState(() {
      _selectedCharacterId = characterId;
      _confirmedCharacterId = characterId;
      _characterSelectionReleased = false;
    });
    widget.onSelectedCharacterChanged(characterId);
  }

  void _revertSelectedCharacter() {
    final confirmed = _confirmedCharacterId;
    if (confirmed == null) {
      setState(() {
        _characterSelectionReleased = true;
      });
      return;
    }
    if (confirmed == _selectedCharacterId && !_characterSelectionReleased) {
      return;
    }
    setState(() {
      _selectedCharacterId = confirmed;
      _characterSelectionReleased = false;
    });
    widget.onSelectedCharacterChanged(confirmed);
  }

  void _selectCharacter(String characterId) {
    if (_occupiedCharacterIdsByOtherPlayers().contains(characterId)) {
      setState(() {
        _status = _tr(
          'multiplayerCharacterOccupied',
          params: {
            'name': CharacterAssets.displayNames[characterId] ?? characterId,
          },
        );
      });
      return;
    }
    setState(() {
      _selectedCharacterId = characterId;
      _characterSelectionReleased = false;
      _teamPromptConfirmedCharacterId = null;
      _teamPromptDismissedCharacterId = null;
    });
    widget.onSelectedCharacterChanged(characterId);
    unawaited(_sendCharacterSelection(characterId));
  }

  Future<void> _releaseCharacterSelection() async {
    final socket = _socket;
    final roomId = _connectedRoomId ?? _roomController.text.trim();
    if (socket == null ||
        !socket.isConnected ||
        roomId.isEmpty ||
        _playerId == null ||
        _roomSnapshot?.phase != 'lobby') {
      setState(() {
        _characterSelectionReleased = true;
        _confirmedCharacterId = null;
        _teamPromptConfirmedCharacterId = null;
        _teamPromptDismissedCharacterId = null;
        _status = _tr('multiplayerCharacterReleasedNextRoom');
      });
      return;
    }

    try {
      socket.releaseCharacter(roomId: roomId, playerId: _playerId!);
      setState(() {
        _characterSelectionReleased = true;
        _confirmedCharacterId = null;
        _teamPromptConfirmedCharacterId = null;
        _teamPromptDismissedCharacterId = null;
        _status = _tr('multiplayerCharacterReleasedWaitingSync');
      });
    } catch (error) {
      setState(() {
        _status = _tr('multiplayerCharacterReleaseFailed');
      });
    }
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
        _status = _tr(
          'multiplayerCharacterSent',
          params: {
            'name': CharacterAssets.displayNames[characterId] ?? characterId,
          },
        );
      });
    } catch (error) {
      setState(() {
        _status = _tr('multiplayerCharacterSendFailed');
      });
    }
  }

  Future<bool> _ensureConnected() async {
    final socket = _socket;
    if (socket != null && socket.isConnected) {
      ZapitiLogger.debug('lobby', 'ensure_connected_reuse_socket', fields: {
        'roomId': _connectedRoomId,
      });
      return true;
    }

    final pending = _pendingConnection;
    if (pending != null) {
      ZapitiLogger.debug('lobby', 'ensure_connected_wait_pending', fields: {
        'roomId': _connectedRoomId,
      });
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
    ZapitiLogger.info('lobby', 'connect_with_retries_begin', fields: {
      'serverUrl': serverUrl,
      'fromConnectionLoss': fromConnectionLoss,
      'roomId': _connectedRoomId,
    });
    if (serverUrl.isEmpty) {
      _setConnectionState(
        _ServerConnectionState.error,
        status: _tr('multiplayerConnectionPrepareFailed'),
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
      _tr('multiplayerConnectingToMatch'),
      if (ServerConfig.useLocalServer)
        _tr('multiplayerRecoveringConnection')
      else
        _tr('multiplayerPreparingService'),
      _tr('multiplayerRecoveringConnection'),
      _tr('multiplayerRecoveringConnection'),
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

    for (var attempt = 0; attempt < attemptDelays.length; attempt++) {
      if (!mounted || generation != _connectionGeneration) {
        return false;
      }

      final delay = attemptDelays[attempt];
      ZapitiLogger.info('lobby', 'connect_attempt_begin', fields: {
        'attempt': attempt + 1,
        'delayMs': delay.inMilliseconds,
        'timeoutMs': attemptTimeout.inMilliseconds,
        'generation': generation,
        'fromConnectionLoss': fromConnectionLoss,
      });
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
        _handleSocketDropped(_tr('multiplayerConnectionLost'));
      };
      nextSocket.onDone = () {
        if (!mounted || generation != _connectionGeneration) return;
        _handleSocketDropped(_tr('multiplayerConnectionLost'));
      };

      try {
        await nextSocket.connect(timeout: attemptTimeout);
        if (!mounted || generation != _connectionGeneration) {
          nextSocket.close();
          return false;
        }

        _socket = nextSocket;
        ZapitiLogger.info('lobby', 'connect_attempt_success', fields: {
          'attempt': attempt + 1,
          'generation': generation,
          'fromConnectionLoss': fromConnectionLoss,
        });
        _setConnectionState(
          _ServerConnectionState.connected,
          status: fromConnectionLoss
              ? _tr('multiplayerConnectedToMatch')
              : _tr('multiplayerConnectedWaitingRoom'),
        );
        return true;
      } catch (error, stackTrace) {
        ZapitiLogger.error(
          'lobby',
          'connect_attempt_failed',
          error: error,
          stackTrace: stackTrace,
          fields: {
            'attempt': attempt + 1,
            'generation': generation,
            'fromConnectionLoss': fromConnectionLoss,
          },
        );
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
      status: _tr('multiplayerCouldNotConnect'),
    );
    return false;
  }

  void _handleSocketDropped(String reason) {
    final hadSession = _sessionStarted || _roomSnapshot != null;
    ZapitiLogger.warn('lobby', 'socket_dropped', fields: {
      'reason': reason,
      'hadSession': hadSession,
      'roomId': _connectedRoomId,
    });
    if (hadSession) {
      _setConnectionState(
        _ServerConnectionState.reconnecting,
        status: _tr('multiplayerConnectionLost'),
      );
      unawaited(_recoverAfterConnectionLoss());
      return;
    }

    _clearSessionAfterConnectionLoss(reason);
  }

  Future<void> _recoverAfterConnectionLoss() async {
    ZapitiLogger.info('lobby', 'recover_after_connection_loss_begin', fields: {
      'roomId': _connectedRoomId,
    });
    final reconnected = await _connectWithRetries(fromConnectionLoss: true);
    if (!mounted) return;

    if (!reconnected) {
      ZapitiLogger.warn('lobby', 'recover_after_connection_loss_failed',
          fields: {
            'roomId': _connectedRoomId,
          });
      _clearSessionAfterConnectionLoss(
        _tr('multiplayerCouldNotRecoverConnection'),
      );
      return;
    }

    ZapitiLogger.info('lobby', 'recover_after_connection_loss_success',
        fields: {
          'roomId': _connectedRoomId,
        });
    _clearSessionAfterConnectionLoss(
      _tr('multiplayerConnectionRestored'),
      preserveSocket: true,
      connectionState: _ServerConnectionState.connected,
    );
  }

  void _handleSocketMessage(MultiplayerMessage message) {
    if (!mounted) return;
    ZapitiLogger.info('lobby', 'message_received', fields: {
      'type': message.type.wireName,
      'roomId': message.roomId,
      'playerId': message.playerId,
      'payloadKeys': message.payload.keys.toList(),
    });

    switch (message.type) {
      case MultiplayerMessageType.roomSnapshot:
        final snapshot = MultiplayerRoomSnapshot.fromJson(message.payload);
        setState(() {
          _pendingRoomAction = null;
          _roomActionRetriedWithoutCharacter = false;
          _roomActionRetriedWithoutSession = false;
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
          _sessionStarted = _snapshotStartsGame(snapshot);
          _connectionState = _ServerConnectionState.connected;
          _status = switch (snapshot.phase) {
            'starting' => _tr('multiplayerReadyToStart'),
            'playing' => _tr('multiplayerPhasePlaying'),
            _ => _tr('roomWithPhase', params: {
                'room': snapshot.roomId,
                'phase': _phaseLabel(snapshot.phase)
              }),
          };
        });
        _hydrateMultiplayerSessionFromSnapshot(snapshot);
        if (message.playerId != null && message.playerId!.isNotEmpty) {
          MultiplayerSessionStore.instance.localGamePlayerId = message.playerId;
        }
        final reconnectPlayerId = message.playerId ?? _playerId;
        if (reconnectPlayerId != null && reconnectPlayerId.isNotEmpty) {
          _rememberReconnectCredentials(
            playerId: reconnectPlayerId,
            roomId: snapshot.roomId,
          );
        }
        final allowPassHand = snapshot.match?['allowPassHand'];
        if (allowPassHand is bool) {
          MultiplayerSessionStore.instance.allowPassHand = allowPassHand;
        }
        _syncSelectedCharacterFromRoom();
        if (_teamSelectionFlowEnabled) {
          _resolveTeamForRoomSnapshot(snapshot);
        }
        if (_snapshotStartsGame(snapshot) &&
            MultiplayerSessionStore.instance.localGamePlayerId != null &&
            MultiplayerSessionStore.instance.players.isNotEmpty) {
          MultiplayerSessionStore.instance.controlledPlayerIds = [
            MultiplayerSessionStore.instance.localGamePlayerId!,
          ];
        }
        _maybeAutoEnterGame();
        break;
      case MultiplayerMessageType.error:
        var shouldRetryRoomActionWithoutSession = false;
        setState(() {
          final code = message.payload['code']?.toString() ?? 'error';
          final text = message.payload['message']?.toString() ??
              _tr('multiplayerConnectionError');
          if (code == 'profile_not_found') {
            if (_profileLoginInProgress) {
              _profileReady = false;
              _showCreateAccount = false;
              _profileStatus = _tr('multiplayerProfilePasswordIncorrect');
            } else {
              _profileStatus = _tr('multiplayerProfileRecover');
              _showCreateAccount = true;
            }
            _profileLoginInProgress = false;
          } else if (code == 'auth_failed') {
            _sessionToken = null;
            _profileLoginInProgress = false;
            unawaited(_clearSavedSessionToken());
            shouldRetryRoomActionWithoutSession = _pendingRoomAction != null &&
                !_roomActionRetriedWithoutSession &&
                _usableProfilePassword != null;
            if (shouldRetryRoomActionWithoutSession) {
              _profileReady = true;
              _showCreateAccount = false;
              _profileStatus = _tr('multiplayerRetrySessionJoin');
            } else {
              _profileReady = false;
              _showCreateAccount = false;
              _teamsLoaded = false;
              _playerTeams = const [];
              _selectedPairId = null;
              _profileStatus = _tr('multiplayerProfilePasswordIncorrect');
            }
          } else if (code == 'invalid_payload' && !_profileReady) {
            _profileLoginInProgress = false;
            _profileStatus = _tr('multiplayerProfileReviewCredentials');
          }
          _status = switch (code) {
            'room_not_found' => _tr('multiplayerJoinFailed'),
            'team_required' => _tr('multiplayerTeamSelectionFailed'),
            'invalid_team_for_room' => _tr('multiplayerRemoteErrorTeamUpdate'),
            'auth_failed' => _tr('multiplayerProfilePasswordIncorrect'),
            'character_taken' => _tr('multiplayerCharacterOccupied',
                params: {'name': _selectedCharacterId}),
            'player_already_in_room' => _tr('multiplayerJoinFailed'),
            _ => _friendlyRemoteError(code, text),
          };
        });
        final errorCode = message.payload['code']?.toString();
        if (errorCode == 'auth_failed' && shouldRetryRoomActionWithoutSession) {
          if (_retryPendingRoomActionWithoutSession()) {
            break;
          }
        } else if (errorCode == 'character_taken') {
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
        if (message.playerId != null && message.playerId!.isNotEmpty) {
          MultiplayerSessionStore.instance.localGamePlayerId = message.playerId;
        }
        MultiplayerSessionStore.instance.matchStarted = true;
        final parsedPlayers = _parsePlayers(message.payload['players']);
        if (parsedPlayers.isNotEmpty) {
          MultiplayerSessionStore.instance.players = parsedPlayers;
        }
        final parsedCharacterIds =
            _parseCharacterIdsByPlayer(message.payload['players']);
        if (parsedCharacterIds.isNotEmpty) {
          MultiplayerSessionStore.instance.characterIdsByPlayer =
              parsedCharacterIds;
        }
        MultiplayerSessionStore.instance.botDifficulty =
            _parseBotDifficulty(message.payload['players']);
        MultiplayerSessionStore.instance.seed = message.payload['seed'] as int?;
        final rawControlledPlayerIds = message.payload['controlledPlayerIds'];
        final controlledPlayerIds = rawControlledPlayerIds is List
            ? [
                for (final rawPlayerId in rawControlledPlayerIds)
                  if (rawPlayerId.toString().isNotEmpty) rawPlayerId.toString(),
              ]
            : const <String>[];
        MultiplayerSessionStore.instance.controlledPlayerIds =
            controlledPlayerIds.isNotEmpty
                ? controlledPlayerIds
                : message.playerId == null
                    ? const []
                    : [message.playerId!];
        MultiplayerSessionStore.instance.fixedHands =
            _parseFixedHands(message.payload['fixedHands']);
        setState(() {
          _sessionStarted = true;
          _connectionState = _ServerConnectionState.connected;
          _status = _tr('multiplayerOpeningTable');
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
            final playerStats =
                rankingPlayers.cast<Map<String, dynamic>?>().firstWhere(
                      (entry) =>
                          entry?['playerId']?.toString() == localPlayerId,
                      orElse: () => null,
                    );
            if (playerStats != null) {
              _playerStats = playerStats;
            }
          }
          _rankingRequested = true;
          _status = _rankingPairs.isEmpty && _rankingMatches.isEmpty
              ? _tr('noMatchesRegistered')
              : _tr('pairsRanking');
        });
        break;
      case MultiplayerMessageType.teams:
        final teams = [
          for (final entry
              in (message.payload['teams'] as List<dynamic>? ?? const []))
            if (entry is Map) Map<String, dynamic>.from(entry),
        ];
        _logTeamFlow('teams_message_received', {
          'teamCount': teams.length,
          'selectedPairId': _selectedPairId,
          'roomId': _roomSnapshot?.roomId,
          'localPlayerId': _playerId,
          'pairs': [
            for (final team in teams)
              {
                'pairId': team['pairId'],
                'teamName': team['teamName'],
                'teammateIds': team['teammateIds'],
                'teammateUsernames': team['teammateUsernames'],
              },
          ],
        });
        setState(() {
          _playerTeams = teams;
          _teamsLoaded = true;
          if (_selectedPairId == null ||
              !teams.any(
                (team) => team['pairId']?.toString() == _selectedPairId,
              )) {
            final snapshot = _roomSnapshot;
            final teammate =
                snapshot == null ? null : _teammateSeatFor(snapshot);
            final teammatePairId = teammate == null
                ? null
                : _teamForTeammate(teammate.playerId)?['pairId']?.toString();
            _selectedPairId =
                teammatePairId != null && teammatePairId.isNotEmpty
                    ? teammatePairId
                    : null;
          }
          final selectedTeam = _selectedTeam;
          if (selectedTeam != null) {
            final selectedName =
                selectedTeam['teamName']?.toString().trim() ?? '';
            if (selectedName.isNotEmpty) {
              _setTeamNameField(selectedName);
              unawaited(_saveTeamName(selectedName));
            }
          }
          _status = teams.isEmpty
              ? _tr('multiplayerTeamsLoadingFailed')
              : _tr('multiplayerTeamSynced');
        });
        final snapshot = _roomSnapshot;
        if (_teamSelectionFlowEnabled && snapshot != null) {
          _resolveTeamForRoomSnapshot(snapshot);
        }
        break;
      case MultiplayerMessageType.profile:
        final profilePlayerId =
            message.payload['playerId']?.toString() ?? message.playerId;
        final profileUsername = message.payload['username']?.toString();
        final profileName = message.payload['name']?.toString();
        final profileTeamName = message.payload['teamName']?.toString() ?? '';
        final profileSessionToken = message.payload['sessionToken']?.toString();
        if (profilePlayerId == null || profileName == null) {
          setState(() {
            _profileStatus = _tr('multiplayerProfileRecoverFailed');
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
          _passwordController.clear();
        }
        setState(() {
          _profileLoginInProgress = false;
          _playerStats = Map<String, dynamic>.from(message.payload);
          _profileReady = _hasUsableSessionOrCredentials();
          _showCreateAccount = false;
          _profileStatus = _profileReady
              ? _tr('multiplayerProfileSessionStarted')
              : _tr('multiplayerProfileSessionStartedCredentials');
          _status = _profileReady
              ? _tr('multiplayerProfileSynced',
                  params: {'name': _cleanPlayerName(profileName)})
              : _tr('multiplayerProfileSyncedNeedsLogin');
        });
        if (_teamSelectionFlowEnabled) {
          _requestTeamsIfReady();
        }
        break;
      default:
        setState(() {
          _status = _tr('multiplayerRoomUpdated');
        });
        break;
    }
  }

  String _friendlyRemoteError(String code, String text) {
    if (code.contains('auth')) {
      return _tr('multiplayerRemoteErrorExpired');
    }
    if (code.contains('room')) {
      return _tr('multiplayerRemoteErrorRoomUpdate');
    }
    if (code.contains('team')) {
      return _tr('multiplayerRemoteErrorTeamUpdate');
    }
    return _tr('multiplayerRemoteErrorServiceUnavailable');
  }

  Future<void> _createRoom() async {
    final playerName = _playerName;
    final username = _username;
    ZapitiLogger.info('lobby', 'create_room_requested', fields: {
      'playerId': _playerId,
      'playerName': playerName,
      'username': username,
      'teamName': _selectedTeamName,
      'characterId': _characterSelectionReleased ? null : _selectedCharacterId,
      'allowPassHand': _allowPassHandForRoom,
      'hasSessionToken': _sessionToken != null && _sessionToken!.isNotEmpty,
      'hasPassword': _usableProfilePassword != null,
    });
    if (playerName.isEmpty) {
      setState(() {
        _status = _tr('multiplayerProfileNameRequired');
      });
      return;
    }
    if (!_hasUsableSessionOrCredentials()) {
      setState(() {
        _profileReady = false;
        _profileStatus = _tr('multiplayerProfileLoginRequiredCreate');
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
        _profileStatus = _tr('multiplayerProfileServiceUnavailableCreate');
        _status = _tr('multiplayerCreateRoomFailed');
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
      _status = _tr('multiplayerCreateRoomPending');
    });

    try {
      final localPlayerId = _localPlayerId;
      unawaited(_savePlayerId(localPlayerId));
      _pendingRoomAction = 'create';
      _roomActionRetriedWithoutCharacter = false;
      _roomActionRetriedWithoutSession = false;
      MultiplayerSessionStore.instance.allowPassHand = _allowPassHandForRoom;
      _rememberReconnectCredentials(
        playerId: localPlayerId,
        roomId: _connectedRoomId,
      );
      socket.createRoom(
        playerId: localPlayerId,
        username: username,
        playerName: playerName,
        password: _sessionToken == null ? _usableProfilePassword : null,
        teamName: _selectedTeamName,
        sessionToken: _sessionToken,
        characterId: _characterSelectionReleased ? null : _selectedCharacterId,
        allowPassHand: _allowPassHandForRoom,
      );
      setState(() {
        _status = _tr('multiplayerCreateRoomRequested');
      });
    } catch (error, stackTrace) {
      ZapitiLogger.error(
        'lobby',
        'create_room_failed',
        error: error,
        stackTrace: stackTrace,
        fields: {
          'playerId': _playerId,
          'teamName': _selectedTeamName,
        },
      );
      setState(() {
        _status = _tr('multiplayerCreateRoomFailed');
      });
    }
  }

  Future<void> _joinRoom() async {
    final roomCode = _roomController.text.trim();
    final playerName = _playerName;
    final username = _username;
    ZapitiLogger.info('lobby', 'join_room_requested', fields: {
      'roomId': roomCode,
      'playerId': _playerId,
      'playerName': playerName,
      'username': username,
      'teamName': _selectedTeamName,
      'characterId': _characterSelectionReleased ? null : _selectedCharacterId,
      'hasSessionToken': _sessionToken != null && _sessionToken!.isNotEmpty,
      'hasPassword': _usableProfilePassword != null,
    });

    if (roomCode.isEmpty) {
      setState(() {
        _status = _tr('multiplayerJoinRoomPrompt');
      });
      return;
    }

    if (playerName.isEmpty) {
      setState(() {
        _status = _tr('multiplayerJoinNameRequired');
      });
      return;
    }
    if (!_hasUsableSessionOrCredentials()) {
      setState(() {
        _profileReady = false;
        _profileStatus = _tr('multiplayerProfileLoginRequiredJoin');
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
        _profileStatus = _tr('multiplayerJoinServiceUnavailable');
        _status = _tr('multiplayerJoinFailed');
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
      _status = _tr('multiplayerJoinPending', params: {'room': roomCode});
    });

    try {
      final localPlayerId = _localPlayerId;
      unawaited(_savePlayerId(localPlayerId));
      _pendingRoomAction = 'join';
      _roomActionRetriedWithoutCharacter = false;
      _roomActionRetriedWithoutSession = false;
      _rememberReconnectCredentials(
        playerId: localPlayerId,
        roomId: roomCode,
      );
      socket.joinRoom(
        roomId: roomCode,
        playerId: localPlayerId,
        username: username,
        playerName: playerName,
        password: _sessionToken == null ? _usableProfilePassword : null,
        teamName: _selectedTeamName,
        sessionToken: _sessionToken,
        characterId: _characterSelectionReleased ? null : _selectedCharacterId,
      );
      setState(() {
        _status = _tr('multiplayerJoinRequested', params: {'room': roomCode});
      });
    } catch (error, stackTrace) {
      ZapitiLogger.error(
        'lobby',
        'join_room_failed',
        error: error,
        stackTrace: stackTrace,
        fields: {
          'roomId': roomCode,
          'playerId': _playerId,
        },
      );
      setState(() {
        _status = _tr('multiplayerJoinFailed');
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
          password: _sessionToken == null ? _usableProfilePassword : null,
          teamName: _selectedTeamName,
          sessionToken: _sessionToken,
          allowPassHand: _allowPassHandForRoom,
        );
        setState(() {
          _status = _tr('multiplayerRetryOccupiedCreate');
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
          password: _sessionToken == null ? _usableProfilePassword : null,
          teamName: _selectedTeamName,
          sessionToken: _sessionToken,
        );
        setState(() {
          _status = _tr('multiplayerRetryOccupiedJoin');
        });
        return true;
      }
    } catch (error) {
      setState(() {
        _status = _tr('multiplayerRetryFailed');
      });
    }
    return false;
  }

  void _rememberReconnectCredentials({
    required String playerId,
    String? roomId,
  }) {
    final selectedCharacterId =
        _characterSelectionReleased ? null : _selectedCharacterId;
    MultiplayerSessionStore.instance.rememberReconnectCredentials(
      roomId: roomId ?? _connectedRoomId ?? _roomSnapshot?.roomId ?? '',
      playerId: playerId,
      username: _username,
      playerName: _playerName,
      teamName: _selectedTeamName,
      password: _sessionToken == null ? _usableProfilePassword : null,
      sessionToken: _sessionToken,
      pairId: _selectedPairId,
      characterId: selectedCharacterId,
    );
  }

  bool _retryPendingRoomActionWithoutSession() {
    if (_roomActionRetriedWithoutSession) return false;
    final action = _pendingRoomAction;
    final socket = _socket;
    final password = _usableProfilePassword;
    if (action == null ||
        socket == null ||
        !socket.isConnected ||
        password == null) {
      return false;
    }

    final playerName = _playerName;
    final username = _username;
    final localPlayerId = _localPlayerId;
    _roomActionRetriedWithoutSession = true;

    try {
      if (action == 'create') {
        socket.createRoom(
          playerId: localPlayerId,
          username: username,
          playerName: playerName,
          password: password,
          teamName: _selectedTeamName,
          characterId:
              _characterSelectionReleased ? null : _selectedCharacterId,
          allowPassHand: _allowPassHandForRoom,
        );
        setState(() {
          _status = _tr('multiplayerRetrySessionCreate');
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
          password: password,
          teamName: _selectedTeamName,
          characterId:
              _characterSelectionReleased ? null : _selectedCharacterId,
        );
        setState(() {
          _status = _tr('multiplayerRetrySessionJoin');
        });
        return true;
      }
    } catch (error) {
      setState(() {
        _status = _tr('multiplayerRemoteErrorExpired');
      });
    }
    return false;
  }

  Future<void> _toggleReady() async {
    final socket = _socket;
    final roomId = _connectedRoomId ?? _roomController.text.trim();
    if (socket == null || !socket.isConnected || roomId.isEmpty) {
      setState(() {
        _status = _tr('multiplayerProfileLoginRequiredJoin');
      });
      return;
    }
    final snapshot = _roomSnapshot;
    if (_teamSelectionFlowEnabled && snapshot != null) {
      _resolveTeamForRoomSnapshot(snapshot);
    }
    if (_teamSelectionFlowEnabled &&
        snapshot != null &&
        snapshot.seats.length >= 4 &&
        _teammateSeatFor(snapshot)?.playerId.isNotEmpty == true &&
        (_selectedPairId == null || _selectedPairId!.isEmpty)) {
      setState(() {
        _status = _tr('multiplayerTeamSelectionFailed');
      });
      _resolveTeamForRoomSnapshot(snapshot);
      return;
    }
    final syncedPairId =
        snapshot == null ? null : _localSeatFor(snapshot)?.pairId;
    if (_teamSelectionFlowEnabled &&
        (_selectedPairId ?? '').isNotEmpty &&
        syncedPairId != _selectedPairId) {
      _logTeamFlow('ready_requires_select_team_first', {
        'roomId': roomId,
        'selectedPairId': _selectedPairId,
        'syncedPairId': syncedPairId,
      });
      _sendTeamSelectionIfReady(roomId: roomId);
    } else {
      _logTeamFlow('ready_select_team_not_needed', {
        'roomId': roomId,
        'selectedPairId': _selectedPairId,
        'syncedPairId': syncedPairId,
      });
    }

    final nextReady = !_ready;
    setState(() {
      _ready = nextReady;
      _status = nextReady
          ? _tr('multiplayerReadyToStart')
          : _tr('multiplayerReadyCanceled');
    });

    try {
      socket.setReady(
        roomId: roomId,
        playerId: _localPlayerId,
        ready: nextReady,
      );
    } catch (error) {
      setState(() {
        _status = _tr('multiplayerReadyToggleFailed');
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
      _status = _tr('multiplayerRankingUpdating');
    });
    try {
      socket.requestRanking();
    } catch (error) {
      setState(() {
        _status = _tr('multiplayerRankingUpdateFailed');
      });
    }
  }

  void _requestTeamsIfReady() {
    if (!_teamSelectionFlowEnabled) return;
    final socket = _socket;
    final playerId = _playerId;
    final sessionToken = _sessionToken;
    if (socket == null ||
        !socket.isConnected ||
        playerId == null ||
        sessionToken == null ||
        sessionToken.isEmpty) {
      _logTeamFlow('request_teams_skipped', {
        'socketConnected': socket?.isConnected,
        'hasPlayerId': playerId != null,
        'hasSessionToken': sessionToken != null && sessionToken.isNotEmpty,
      });
      return;
    }
    try {
      _logTeamFlow('request_teams_sent', {
        'playerId': playerId,
        'roomId': _connectedRoomId ?? _roomController.text.trim(),
      });
      socket.requestTeams(playerId: playerId, sessionToken: sessionToken);
    } catch (error) {
      setState(() {
        _status = _tr('multiplayerTeamsLoadingFailed');
      });
    }
  }

  void _resolveTeamForRoomSnapshot(MultiplayerRoomSnapshot snapshot) {
    if (!_teamSelectionFlowEnabled) {
      _closeCreateTeamDialog();
      return;
    }
    if (snapshot.phase != 'lobby') return;
    if (snapshot.seats.length < 4) return;
    final localSeat = _localSeatFor(snapshot);
    final teammate = _teammateSeatFor(snapshot);
    final teammateUsername = teammate?.username?.trim() ?? '';
    _logTeamFlow('resolve_team_start', {
      'roomId': snapshot.roomId,
      'localPlayerId': _playerId,
      'localSeat': localSeat == null
          ? null
          : {
              'seatIndex': localSeat.seatIndex,
              'username': localSeat.username,
              'pairId': localSeat.pairId,
              'teamName': localSeat.teamName,
              'teamId': localSeat.teamId,
            },
      'teammate': teammate == null
          ? null
          : {
              'playerId': teammate.playerId,
              'seatIndex': teammate.seatIndex,
              'username': teammate.username,
              'pairId': teammate.pairId,
              'teamName': teammate.teamName,
              'teamId': teammate.teamId,
            },
      'teamsLoaded': _teamsLoaded,
      'teamCount': _playerTeams.length,
      'selectedPairId': _selectedPairId,
    });
    if (teammate == null || teammateUsername.isEmpty) {
      _logTeamFlow('resolve_team_stop', {
        'reason':
            teammate == null ? 'missing_teammate' : 'missing_teammate_username',
      });
      return;
    }
    if (_teamDialogContext != null &&
        _teamDialogTeammatePlayerId != null &&
        _teamDialogTeammatePlayerId != teammate.playerId) {
      _closeCreateTeamDialog();
      _teamModalShownForCurrentRoom = false;
    }
    final localPairId = localSeat?.pairId?.trim() ?? '';
    if (localPairId.isNotEmpty) {
      final localTeamName = localSeat?.teamName?.trim() ?? '';
      _logTeamFlow('resolve_team_room_pair', {
        'pairId': localPairId,
        'teamName': localTeamName,
        'selectedPairId': _selectedPairId,
      });
      if (_selectedPairId != localPairId) {
        setState(() {
          _selectedPairId = localPairId;
          if (localTeamName.isNotEmpty) {
            _setTeamNameField(localTeamName);
            unawaited(_saveTeamName(localTeamName));
          }
          _status = localTeamName.isEmpty
              ? _tr('multiplayerTeamSynced')
              : _tr('multiplayerTeamNamedSynced',
                  params: {'name': localTeamName});
        });
      }
      return;
    }

    final currentTeam = _teamForCurrentPair(snapshot);
    if (currentTeam != null) {
      final pairId = currentTeam['pairId']?.toString() ?? '';
      final teamName = currentTeam['teamName']?.toString().trim() ?? '';
      _logTeamFlow('resolve_team_existing_current_pair', {
        'pairId': pairId,
        'teamName': teamName,
        'selectedPairId': _selectedPairId,
      });
      if (pairId.isNotEmpty && _selectedPairId != pairId) {
        setState(() {
          _selectedPairId = pairId;
          if (teamName.isNotEmpty) {
            _setTeamNameField(teamName);
            unawaited(_saveTeamName(teamName));
          }
          _status = teamName.isEmpty
              ? _tr('multiplayerTeamSynced')
              : _tr('multiplayerTeamNamedSynced', params: {'name': teamName});
        });
        _sendTeamSelectionIfReady(roomId: snapshot.roomId);
      }
      return;
    }

    final teammateTeam = _teamForTeammate(teammate.playerId);
    if (!_teamsLoaded) {
      _logTeamFlow('resolve_team_waiting_teams', {
        'teammatePlayerId': teammate.playerId,
      });
      _requestTeamsIfReady();
      return;
    }

    if (teammateTeam != null) {
      final pairId = teammateTeam['pairId']?.toString();
      final teamName = teammateTeam['teamName']?.toString().trim() ?? '';
      _logTeamFlow('resolve_team_existing_teammate', {
        'pairId': pairId,
        'teamName': teamName,
        'teammatePlayerId': teammate.playerId,
      });
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

    final localCharacterId = localSeat?.characterId;
    if (localCharacterId == null || localCharacterId.isEmpty) {
      _logTeamFlow('resolve_team_stop', {'reason': 'missing_character'});
      setState(() {
        _status =
            'Elige y confirma personaje antes de crear equipo con tu companero.';
      });
      return;
    }
    if (_teamPromptConfirmedCharacterId != localCharacterId) {
      _logTeamFlow('resolve_team_confirm_character_first', {
        'characterId': localCharacterId,
        'confirmedCharacterId': _teamPromptConfirmedCharacterId,
        'dismissedCharacterId': _teamPromptDismissedCharacterId,
      });
      if (_teamPromptDismissedCharacterId != localCharacterId &&
          _characterConfirmDialogContext == null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted || _roomSnapshot?.roomId != snapshot.roomId) return;
          _showConfirmCharacterDialog(localCharacterId);
        });
      }
      return;
    }

    if (_teamModalShownForCurrentRoom &&
        _teamDialogTeammatePlayerId == teammate.playerId) {
      _logTeamFlow('create_team_modal_skip', {
        'reason': 'already_shown_for_teammate',
        'teammatePlayerId': teammate.playerId,
      });
      return;
    }
    if (_teamModalShownForCurrentRoom &&
        _teamDialogTeammatePlayerId != teammate.playerId) {
      _teamModalShownForCurrentRoom = false;
      _teamDialogTeammatePlayerId = null;
    }
    _teamModalShownForCurrentRoom = true;
    _teamDialogTeammatePlayerId = teammate.playerId;
    _logTeamFlow('create_team_modal_schedule', {
      'roomId': snapshot.roomId,
      'teammatePlayerId': teammate.playerId,
      'teammateUsername': teammate.username,
      'teammateName': teammate.name,
    });
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
          playerIds
              .map((entry) => entry.toString())
              .contains(teammatePlayerId)) {
        return team;
      }
    }
    return null;
  }

  Map<String, dynamic>? _teamForCurrentPair(MultiplayerRoomSnapshot snapshot) {
    final localSeat = _localSeatFor(snapshot);
    final teammateSeat = _teammateSeatFor(snapshot);
    final localUsername = localSeat?.username?.trim() ?? '';
    final teammateUsername = teammateSeat?.username?.trim() ?? '';
    if (localUsername.isEmpty || teammateUsername.isEmpty) return null;
    for (final team in _playerTeams) {
      final teammateUsernames = team['teammateUsernames'];
      if (teammateUsernames is! List) continue;
      final usernames =
          teammateUsernames.map((entry) => entry.toString()).toSet();
      if (usernames.contains(teammateUsername) &&
          usernames.contains(localUsername)) {
        return team;
      }
    }
    return null;
  }

  void _sendTeamSelectionIfReady({String? roomId}) {
    if (!_teamSelectionFlowEnabled) return;
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
      _logTeamFlow('select_team_skipped', {
        'socketConnected': socket?.isConnected,
        'hasPlayerId': playerId != null,
        'hasSessionToken': sessionToken != null,
        'pairId': pairId,
        'roomId': targetRoomId,
      });
      return;
    }

    try {
      _logTeamFlow('select_team_sent', {
        'roomId': targetRoomId,
        'playerId': playerId,
        'pairId': pairId,
      });
      socket.selectTeam(
        roomId: targetRoomId,
        playerId: playerId,
        sessionToken: sessionToken,
        pairId: pairId,
      );
    } catch (error) {
      setState(() {
        _status = _tr('multiplayerTeamSelectionFailed');
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

  Future<void> _showConfirmCharacterDialog(String characterId) async {
    final characterName =
        CharacterAssets.displayNames[characterId] ?? characterId;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        _characterConfirmDialogContext = context;
        return AlertDialog(
          title: Text(_tr('confirmCharacterTitle')),
          content: Text(
              _tr('confirmCharacterBody', params: {'name': characterName})),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(_tr('keepChoosing')),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(_tr('confirmUpper')),
            ),
          ],
        );
      },
    );
    _characterConfirmDialogContext = null;
    if (!mounted) return;
    if (confirmed == true) {
      setState(() {
        _teamPromptConfirmedCharacterId = characterId;
        _teamPromptDismissedCharacterId = null;
        _status = _tr('multiplayerCharacterConfirmed',
            params: {'name': characterName});
      });
      final snapshot = _roomSnapshot;
      if (snapshot != null) {
        _resolveTeamForRoomSnapshot(snapshot);
      }
      return;
    }

    setState(() {
      _teamPromptDismissedCharacterId = characterId;
      _status = _tr('multiplayerCharacterChangeAllowed');
    });
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
          title: Text(_tr('createTeamTitle')),
          content: TextField(
            controller: teamNameController,
            inputFormatters: [
              LengthLimitingTextInputFormatter(_maxTeamNameLength),
            ],
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: _tr('teamNameLabel'),
              helperText:
                  _tr('teammateNameHelper', params: {'name': teammate.name}),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(_tr('notNow')),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(_tr('createUpper')),
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
        _status = _tr('multiplayerTeamNameRequired');
      });
      return;
    }

    try {
      _logTeamFlow('create_team_sent', {
        'playerId': playerId,
        'teammateUsername': teammateUsername,
        'teamName': teamName,
      });
      socket.createTeam(
        playerId: playerId,
        sessionToken: sessionToken,
        teammateUsername: teammateUsername,
        teamName: teamName,
      );
      setState(() {
        _setTeamNameField(teamName);
        _status = _tr('multiplayerCreateTeamInProgress',
            params: {'username': teammateUsername});
      });
      _requestTeamsIfReady();
      final snapshot = _roomSnapshot;
      if (snapshot != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted || _roomSnapshot?.roomId != snapshot.roomId) return;
          _resolveTeamForRoomSnapshot(snapshot);
        });
      }
    } catch (error) {
      setState(() {
        _status = _tr('multiplayerCreateTeamFailed');
      });
    }
  }

  Future<void> _saveProfileAndContinue() async {
    final playerName = _playerName;
    final username = _username;
    final password = _profilePassword;
    if (playerName.isEmpty) {
      setState(() {
        _profileStatus = _tr('multiplayerProfileNameRequiredCreate');
      });
      return;
    }
    if (!RegExp(r'^[a-z0-9_.-]{3,24}$').hasMatch(username)) {
      setState(() {
        _profileStatus = _tr('multiplayerProfileUsernameInvalid');
      });
      return;
    }
    if (password.length < 6 || password.length > 72) {
      setState(() {
        _profileStatus = _tr('multiplayerProfilePasswordInvalid');
      });
      return;
    }

    final localPlayerId = _localPlayerId;
    _profilePasswordFallback = password;
    await Future.wait([
      _savePlayerName(playerName),
      _savePlayerId(localPlayerId),
      _saveUsername(username),
    ]);

    setState(() {
      _profileLoginInProgress = false;
      _profileStatus = _tr('multiplayerProfileCreatingUser');
      _status = _tr('multiplayerProfileSyncingUser');
    });

    if (!await _ensureConnected()) {
      setState(() {
        _profileStatus = _tr('multiplayerProfileCreateFailed');
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
        _profileStatus = _tr('multiplayerProfileCreateFailed');
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
        _profileStatus = _tr('multiplayerProfileUsernameInvalid');
      });
      return;
    }
    if (!await _ensureConnected()) {
      setState(() {
        _profileStatus = _tr('multiplayerJoinServiceUnavailable');
      });
      return;
    }
    final socket = _socket;
    if (socket == null) return;
    _profilePasswordFallback = password;
    setState(() {
      _profileLoginInProgress = true;
      _profileStatus = _tr('multiplayerProfileLoginInProgress');
    });
    try {
      socket.recoverProfile(
        username: username,
        password: password,
      );
    } catch (error) {
      setState(() {
        _profileLoginInProgress = false;
        _profileStatus = _tr('multiplayerProfileLoginFailed');
      });
    }
  }

  bool _hasUsableSessionOrCredentials() {
    if (_sessionToken != null && _sessionToken!.isNotEmpty) return true;
    final password = _usableProfilePassword;
    return RegExp(r'^[a-z0-9_.-]{3,24}$').hasMatch(_username) &&
        password != null &&
        password.length >= 6 &&
        password.length <= 72;
  }

  Future<void> _copyRoomInvitation() async {
    final roomId = _connectedRoomId ?? _roomController.text.trim();
    if (roomId.isEmpty) {
      setState(() {
        _status = _tr('multiplayerCopyInvitationPrompt');
      });
      return;
    }

    await Clipboard.setData(
      ClipboardData(text: 'Unete a mi sala de Zapiti: $roomId'),
    );
    if (!mounted) return;
    setState(() {
      _status = _tr('multiplayerInvitationCopied', params: {'room': roomId});
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
      _status = _tr('multiplayerLeftRoom');
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
    if (_keepSocketAliveOnDispose) {
      return;
    }

    _autoEnterQueued = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        _autoEnterQueued = false;
        return;
      }
      if (_keepSocketAliveOnDispose || !_sessionStarted || _socket == null) {
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
        _status = _tr('multiplayerAwaitingMatchData');
      });
      return;
    }

    setState(() {
      _keepSocketAliveOnDispose = true;
      _autoEnterQueued = false;
      MultiplayerSessionStore.instance.socket = _socket;
      MultiplayerSessionStore.instance.roomSnapshot = _roomSnapshot;
      _status = _tr('multiplayerOpeningTable');
    });

    widget.onEnterGame();
  }

  bool _multiplayerSessionReadyForGame() {
    final session = MultiplayerSessionStore.instance;
    _hydrateMultiplayerSessionFromSnapshot(_roomSnapshot);
    return session.matchStarted &&
        session.localGamePlayerId != null &&
        session.players.length >= 2;
  }

  bool _snapshotStartsGame(MultiplayerRoomSnapshot? snapshot) {
    if (snapshot == null) return false;
    return snapshot.phase == 'playing' || snapshot.match != null;
  }

  void _hydrateMultiplayerSessionFromSnapshot(
    MultiplayerRoomSnapshot? snapshot,
  ) {
    if (snapshot == null) return;

    final session = MultiplayerSessionStore.instance;
    session.roomSnapshot = snapshot;
    session.matchStarted = _snapshotStartsGame(snapshot);

    final match = snapshot.match;
    if (match == null) return;

    final matchPlayers = _parsePlayers(match['players']);
    if (matchPlayers.isNotEmpty &&
        (session.players.isEmpty ||
            matchPlayers.length > session.players.length)) {
      session.players = _playersStartingWithLocal(matchPlayers);
    }

    final matchCharacterIds = _parseCharacterIdsByPlayer(match['players']);
    if (matchCharacterIds.isNotEmpty) {
      session.characterIdsByPlayer = matchCharacterIds;
    }

    final seed = match['seed'];
    if (seed is int) {
      session.seed = seed;
    }

    final allowPassHand = match['allowPassHand'];
    if (allowPassHand is bool) {
      session.allowPassHand = allowPassHand;
    }

    session.botDifficulty = _parseBotDifficulty(match['players']);

    final localPlayerId = session.localGamePlayerId ?? _playerId;
    if (localPlayerId != null &&
        localPlayerId.isNotEmpty &&
        session.players.any((player) => player.id == localPlayerId)) {
      session.localGamePlayerId = localPlayerId;
      session.controlledPlayerIds = [localPlayerId];
    }
  }

  List<Player> _playersStartingWithLocal(List<Player> players) {
    final localPlayerId =
        MultiplayerSessionStore.instance.localGamePlayerId ?? _playerId;
    if (localPlayerId == null || localPlayerId.isEmpty) {
      return List<Player>.unmodifiable(players);
    }
    final localIndex =
        players.indexWhere((player) => player.id == localPlayerId);
    if (localIndex <= 0) {
      return List<Player>.unmodifiable(players);
    }
    return List<Player>.unmodifiable([
      ...players.skip(localIndex),
      ...players.take(localIndex),
    ]);
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
          characterId.isEmpty ||
          !CharacterAssets.characterIds.contains(characterId)) {
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
    if (!widget.versionCheck.multiplayerEnabled) {
      return _MultiplayerVersionBlockedView(
        status: widget.versionCheck.status,
        message: widget.versionCheck.multiplayerStatusMessage,
      );
    }

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
              _profileStatus = _tr('multiplayerProfileRecover');
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
            _setPlayerNameField('');
            _profileStatus = _tr('multiplayerProfileNameRequiredCreate');
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
                Text(context.tr('multiplayerLobbyTitle'), style: titleStyle),
                const SizedBox(height: 8),
                Text(
                  context.tr('multiplayerLobbyBody'),
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
                          _connectionState.label(context),
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
                                  _tr('multiplayerTeamDisplay',
                                      params: {'name': _selectedTeamName}),
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
                          tooltip: context.tr('editUser'),
                          onPressed: () {
                            setState(() {
                              _profileReady = false;
                              _showCreateAccount = true;
                              _profileStatus =
                                  context.tr('multiplayerEditUserPrompt');
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
                  decoration: InputDecoration(
                    isDense: true,
                    labelText: context.tr('roomCodeLabel'),
                    prefixIcon: const Icon(Icons.tag_outlined),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _characterSelectionReleased
                      ? context.tr('characterSelectionUnset')
                      : context.tr('characterSelectionValue', params: {
                          'name': CharacterAssets
                                  .displayNames[_selectedCharacterId] ??
                              _selectedCharacterId
                        }),
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
                        selectedCharacterId: _characterSelectionReleased
                            ? ''
                            : _selectedCharacterId,
                        onSelected: _selectCharacter,
                        columns: constraints.maxWidth > 360 ? 4 : 2,
                        disabledCharacterIds:
                            _occupiedCharacterIdsByOtherPlayers(),
                        characterBadges: _characterTeamBadges(),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 42,
                  child: ZapitiActionButton(
                    label: context.tr('releaseCharacterUpper'),
                    icon: Icons.lock_open_outlined,
                    onPressed: _connecting || _characterSelectionReleased
                        ? null
                        : _releaseCharacterSelection,
                  ),
                ),
                const SizedBox(height: 8),
                if (_roomSnapshot == null)
                  _MainMenuSwitchOption(
                    title: context.tr('allowPassHand'),
                    icon: Icons.swap_horiz_outlined,
                    value: _allowPassHandForRoom,
                    onChanged: _connecting
                        ? (_) {}
                        : (enabled) {
                            setState(() {
                              _allowPassHandForRoom = enabled;
                            });
                          },
                  ),
                if (_roomSnapshot == null) const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 42,
                        child: ZapitiActionButton(
                          label: context.tr('createUpper'),
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
                          label: context.tr('joinUpper'),
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
                          label: context.tr('rankingUpper'),
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
                          label: context.tr('copyInviteUpper'),
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
                    label: _ready
                        ? context.tr('readyUpper')
                        : context.tr('markReadyUpper'),
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
        Text(context.tr('loginTitle'), style: titleStyle),
        const SizedBox(height: 8),
        Text(
          context.tr('multiplayerLoginHelp'),
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
          decoration: InputDecoration(
            isDense: true,
            labelText: context.tr('usernameLabel'),
            prefixIcon: const Icon(Icons.alternate_email),
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: passwordController,
          obscureText: true,
          enableSuggestions: false,
          autocorrect: false,
          inputFormatters: [LengthLimitingTextInputFormatter(72)],
          decoration: InputDecoration(
            isDense: true,
            labelText: context.tr('passwordLabel'),
            prefixIcon: const Icon(Icons.lock_outline),
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 42,
          child: ZapitiActionButton(
            label: context.tr('enterUpper'),
            icon: Icons.login,
            onPressed: onLogin,
            primary: true,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 42,
          child: ZapitiActionButton(
            label: context.tr('createUserUpper'),
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
        Text(context.tr('createUserTitle'), style: titleStyle),
        const SizedBox(height: 8),
        Text(
          context.tr('multiplayerCreateAccountHelp'),
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
          decoration: InputDecoration(
            isDense: true,
            labelText: context.tr('usernameLabel'),
            prefixIcon: const Icon(Icons.alternate_email),
            border: const OutlineInputBorder(),
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
          decoration: InputDecoration(
            isDense: true,
            labelText: context.tr('playerNameLabel'),
            prefixIcon: const Icon(Icons.person_outline),
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: passwordController,
          obscureText: true,
          enableSuggestions: false,
          autocorrect: false,
          inputFormatters: [LengthLimitingTextInputFormatter(72)],
          decoration: InputDecoration(
            isDense: true,
            labelText: context.tr('passwordLabel'),
            prefixIcon: const Icon(Icons.lock_outline),
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 42,
                child: ZapitiActionButton(
                  label: context.tr('createUpper'),
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
                  label: context.tr('back'),
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
      'starting' => context.tr('multiplayerPhaseStarting'),
      'playing' => context.tr('multiplayerPhasePlaying'),
      'finished' => context.tr('multiplayerPhaseFinished'),
      _ => context.tr('multiplayerPhaseOpen'),
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
              child:
                  Text(context.tr('multiplayerMatchTitle'), style: titleStyle),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          context.tr(
            'roomWithPhase',
            params: {'room': snapshot.roomId, 'phase': phaseLabel},
          ),
          style: bodyStyle,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 42,
                child: ZapitiActionButton(
                  label: context.tr('copyInviteUpper'),
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
                  label: context.tr('rankingUpper'),
                  icon: Icons.leaderboard_outlined,
                  onPressed: onRequestRanking,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          context.tr('createdAt', params: {'date': createdAt}),
          style: bodyStyle,
        ),
        const SizedBox(height: 4),
        Text(
          context.tr('fixedPairsHint'),
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
                                    context.tr('noCharacter'),
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
                                context
                                    .tr('teamLabel', params: {'team': teamId}),
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
              label: context.tr('enterToPlayUpper'),
              icon: Icons.play_arrow,
              onPressed: onEnterGame,
              primary: true,
            ),
          ),
        const SizedBox(height: 8),
        SizedBox(
          height: 42,
          child: ZapitiActionButton(
            label: context.tr('leaveRoomUpper'),
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
                _PlayerStatPill(
                  label: context.tr('playerStatsMatches'),
                  value: '$played',
                ),
                _PlayerStatPill(
                  label: context.tr('playerStatsWinsLosses'),
                  value: '$wins/$losses',
                ),
                _PlayerStatPill(
                  label: context.tr('playerStatsVictories'),
                  value: '$winRate%',
                ),
                _PlayerStatPill(
                  label: context.tr('playerStatsChinos'),
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
                Text(context.tr('noMatchesRegistered'), style: bodyStyle)
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
                Text(context.tr('noHistory'), style: bodyStyle)
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
        Expanded(child: Text(context.tr('pair'), style: headerStyle)),
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
          child: Text(
            context.tr('playerStatsChinos'),
            textAlign: TextAlign.right,
            style: headerStyle,
          ),
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

class _MultiplayerVersionBlockedView extends StatelessWidget {
  final AppVersionCheckStatus status;
  final String message;

  const _MultiplayerVersionBlockedView({
    required this.status,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final checking = status == AppVersionCheckStatus.checking ||
        status == AppVersionCheckStatus.notChecked;
    final titleStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
          color: ZapitiColors.darkBrown,
          fontWeight: FontWeight.w900,
        );
    final bodyStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: ZapitiColors.darkBrown.withValues(alpha: 0.78),
          fontWeight: FontWeight.w800,
          height: 1.22,
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
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              checking ? Icons.sync_outlined : Icons.system_update_alt_outlined,
              color: ZapitiColors.wineRed,
              size: 30,
            ),
            const SizedBox(height: 8),
            Text(
              checking
                  ? context.tr('checkingMultiplayer')
                  : context.tr('multiplayerUnavailable'),
              textAlign: TextAlign.center,
              style: titleStyle,
            ),
            const SizedBox(height: 6),
            Text(
              message.isEmpty ? context.tr('preparingVersionCheck') : message,
              textAlign: TextAlign.center,
              style: bodyStyle,
            ),
          ],
        ),
      ),
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
              context.tr(
                'winnerTeamDate',
                params: {'team': winnerTeamId, 'date': date},
              ),
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
  final ZapitiLanguage language;
  final ValueChanged<ZapitiLanguage> onLanguageChanged;
  final VoidCallback onBack;

  const _MainMenuOptionsContent({
    required this.audioEnabled,
    required this.onAudioChanged,
    required this.audioVolume,
    required this.onAudioVolumeChanged,
    required this.botSpeed,
    required this.onBotSpeedChanged,
    required this.confirmCardPlay,
    required this.onConfirmCardPlayChanged,
    required this.language,
    required this.onLanguageChanged,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _MainMenuSwitchOption(
            title: context.tr('audio'),
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
            title: context.tr('confirmMove'),
            icon: Icons.touch_app_outlined,
            value: confirmCardPlay,
            onChanged: onConfirmCardPlayChanged,
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              context.tr('botSpeed'),
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
                  label: Text(speed.label(context)),
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
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              context.tr('language'),
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
              for (final option in ZapitiLanguage.values)
                ChoiceChip(
                  avatar: const Icon(Icons.language, size: 16),
                  label: Text(option.nativeName),
                  selected: language == option,
                  onSelected: (_) {
                    onLanguageChanged(option);
                    onBack();
                  },
                  selectedColor: ZapitiColors.oldGold,
                  backgroundColor: Colors.white.withValues(alpha: 0.72),
                  labelStyle: TextStyle(
                    color: language == option
                        ? ZapitiColors.darkBrown
                        : ZapitiColors.darkBrown.withValues(alpha: 0.78),
                    fontWeight: FontWeight.w900,
                  ),
                  side: BorderSide(
                    color: language == option
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
