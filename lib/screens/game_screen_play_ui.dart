part of 'game_screen.dart';

class _CompactGameHeader extends StatelessWidget {
  final int roundNumber;
  final int handValue;
  final int? pendingTrucoValue;
  final int? trucoCallerTeamId;
  final bool isTrucoAccepted;

  const _CompactGameHeader({
    required this.roundNumber,
    required this.handValue,
    required this.pendingTrucoValue,
    required this.trucoCallerTeamId,
    required this.isTrucoAccepted,
  });

  @override
  Widget build(BuildContext context) {
    final chinoText = handValue == 1 ? 'chino' : 'chinos';
    final trucoText = isTrucoAccepted
        ? '$handValue $chinoText'
            : trucoCallerTeamId == null
                ? '$handValue $chinoText'
                : 'Equipo $trucoCallerTeamId sube a $pendingTrucoValue';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: ZapitiColors.woodDark.withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: ZapitiColors.oldGold.withValues(alpha: 0.38)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final shortest = min(constraints.maxWidth, constraints.maxHeight);
          final fontSize =
              (constraints.maxHeight * 0.26).clamp(11.0, 22.0).toDouble();
          final padding = EdgeInsets.symmetric(
            horizontal: shortest * 0.14,
            vertical: shortest * 0.09,
          );

          return DefaultTextStyle(
            style: Theme.of(context).textTheme.bodySmall!.copyWith(
                  color: ZapitiColors.cardCream,
                  fontWeight: FontWeight.w800,
                  fontSize: fontSize,
                  height: 1.02,
                ),
            child: Padding(
              padding: padding,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: SizedBox(
                  width: constraints.maxWidth - padding.horizontal,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Ronda $roundNumber/3',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: shortest * 0.035),
                      Text(
                        trucoText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: ZapitiColors.oldGold),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _GameScorePanel extends StatelessWidget {
  final int scoreTeamOne;
  final int scoreTeamTwo;
  final int roundWinsTeamOne;
  final int roundWinsTeamTwo;
  final int targetScore;

  const _GameScorePanel({
    required this.scoreTeamOne,
    required this.scoreTeamTwo,
    required this.roundWinsTeamOne,
    required this.roundWinsTeamTwo,
    required this.targetScore,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final shortest = min(constraints.maxWidth, constraints.maxHeight);
        final gap = shortest * 0.04;
        final fontSize =
            (constraints.maxHeight * 0.22).clamp(10.5, 20.0).toDouble();
        final textStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
              color: ZapitiColors.darkBrown,
              fontWeight: FontWeight.w900,
              fontSize: fontSize,
              height: 1.02,
            );
        final padding = EdgeInsets.symmetric(
          horizontal: gap * 0.9,
          vertical: gap * 0.7,
        );
        final contentWidth =
            max(0.0, constraints.maxWidth - padding.horizontal);

        return Container(
          width: double.infinity,
          padding: padding,
          decoration: BoxDecoration(
            color: ZapitiColors.cardCream.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(gap * 0.75),
            border: Border.all(
              color: ZapitiColors.oldGold.withValues(alpha: 0.42),
            ),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.center,
            child: SizedBox(
              width: contentWidth,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _ScoreLine(
                    label: 'Eq1',
                    value: '$scoreTeamOne / $targetScore',
                    style: textStyle,
                  ),
                  Divider(
                    height: gap,
                    color: ZapitiColors.darkBrown.withValues(alpha: 0.18),
                  ),
                  _ScoreLine(
                    label: 'Eq2',
                    value: '$scoreTeamTwo / $targetScore',
                    style: textStyle,
                  ),
                  SizedBox(height: gap * 0.45),
                  _ScoreLine(
                    label: 'Rondas Eq1',
                    value: '$roundWinsTeamOne / 3',
                    style: textStyle,
                  ),
                  _ScoreLine(
                    label: 'Rondas Eq2',
                    value: '$roundWinsTeamTwo / 3',
                    style: textStyle,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ScoreLine extends StatelessWidget {
  final String label;
  final String value;
  final TextStyle? style;

  const _ScoreLine({
    required this.label,
    required this.value,
    required this.style,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.max,
      children: [
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: style,
          ),
        ),
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: style,
            ),
          ),
        ),
      ],
    );
  }
}

class _TrucoResponseOverlay extends StatefulWidget {
  final int pendingTrucoValue;
  final List<int> raiseOptions;
  final VoidCallback onAskCompanionSignal;
  final VoidCallback onAccept;
  final VoidCallback onPass;
  final ValueChanged<int> onRaise;

  const _TrucoResponseOverlay({
    required this.pendingTrucoValue,
    required this.raiseOptions,
    required this.onAskCompanionSignal,
    required this.onAccept,
    required this.onPass,
    required this.onRaise,
  });

  @override
  State<_TrucoResponseOverlay> createState() => _TrucoResponseOverlayState();
}

class _TrucoResponseOverlayState extends State<_TrucoResponseOverlay> {
  int _selectedRaiseIndex = 0;

  @override
  void didUpdateWidget(covariant _TrucoResponseOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_selectedRaiseIndex >= widget.raiseOptions.length) {
      _selectedRaiseIndex = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final canRaise = widget.raiseOptions.isNotEmpty;
    final selectedRaise =
        canRaise ? widget.raiseOptions[_selectedRaiseIndex] : null;

    return Positioned.fill(
      child: ColoredBox(
        color: Colors.black.withValues(alpha: 0.20),
        child: Align(
          alignment: Alignment.center,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final shortest = min(constraints.maxWidth, constraints.maxHeight);
              final isNarrow = constraints.maxWidth < 560;
              final gap = shortest * (isNarrow ? 0.022 : 0.018);
              final panelWidth = min(
                constraints.maxWidth * (isNarrow ? 0.86 : 0.54),
                isNarrow ? 420.0 : 460.0,
              );

              return Material(
                color: Colors.transparent,
                child: Padding(
                  padding: EdgeInsets.all(gap),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.center,
                    child: SizedBox(
                      width: panelWidth,
                      child: Container(
                        padding: EdgeInsets.all(gap),
                        decoration: BoxDecoration(
                          color: ZapitiColors.cardCream.withValues(alpha: 0.92),
                          borderRadius: BorderRadius.circular(gap),
                          border: Border.all(
                            color: ZapitiColors.oldGold,
                            width: max(gap * 0.12, 1),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.32),
                              blurRadius: gap * 2,
                              offset: Offset(0, gap * 0.7),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Te cantan ${widget.pendingTrucoValue}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          color: ZapitiColors.darkBrown,
                                          fontWeight: FontWeight.w900,
                                        ),
                                  ),
                                ),
                                SizedBox(width: gap),
                                SizedBox(
                                  width: panelWidth * 0.30,
                                  child: ZapitiActionButton(
                                    label: 'PEDIR SENA',
                                    icon: Icons.visibility_outlined,
                                    onPressed: widget.onAskCompanionSignal,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: gap),
                            Row(
                              children: [
                                Expanded(
                                  child: ZapitiActionButton(
                                    label: 'RECHAZAR',
                                    icon: Icons.block,
                                    onPressed: widget.onPass,
                                  ),
                                ),
                                SizedBox(width: gap),
                                Expanded(
                                  child: ZapitiActionButton(
                                    label: 'ACEPTAR',
                                    icon: Icons.check,
                                    onPressed: widget.onAccept,
                                    primary: true,
                                  ),
                                ),
                                SizedBox(width: gap),
                                Expanded(
                                  child: ZapitiActionButton(
                                    label: selectedRaise == null
                                        ? 'SUBIR'
                                        : 'SUBIR A $selectedRaise',
                                    icon: Icons.trending_up,
                                    onPressed: selectedRaise == null
                                        ? null
                                        : () => widget.onRaise(selectedRaise),
                                    primary: true,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: gap * 0.8),
                            Text(
                              selectedRaise == null
                                  ? 'No hay subida legal disponible'
                                  : 'Subida: $selectedRaise',
                              textAlign: TextAlign.center,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    color: ZapitiColors.darkBrown,
                                    fontWeight: FontWeight.w900,
                                  ),
                            ),
                            Slider(
                              value: _selectedRaiseIndex.toDouble(),
                              min: 0,
                              max: max(widget.raiseOptions.length - 1, 0)
                                  .toDouble(),
                              divisions: widget.raiseOptions.length > 1
                                  ? widget.raiseOptions.length - 1
                                  : null,
                              label: selectedRaise?.toString(),
                              activeColor: ZapitiColors.wineRed,
                              inactiveColor: ZapitiColors.darkBrown
                                  .withValues(alpha: 0.18),
                              onChanged: canRaise
                                  ? (value) {
                                      setState(() {
                                        _selectedRaiseIndex = value.round();
                                      });
                                    }
                                  : null,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _VisibleGameControls extends StatelessWidget {
  final bool compact;
  final bool signalsEnabled;
  final bool isGameFinished;
  final bool isHandFinished;
  final bool isRoundAwaitingContinue;
  final bool isWaitingHumanResponse;
  final bool canCallTruco;
  final int handValue;
  final int? pendingTrucoValue;
  final int? trucoCallerTeamId;
  final bool isTrucoAccepted;
  final List<int> raiseOptions;
  final ValueChanged<String> onSignalStart;
  final ValueChanged<String> onSignalEnd;
  final VoidCallback onAskCompanionSignal;
  final VoidCallback onVoyATi;
  final VoidCallback onCallTruco;
  final VoidCallback onAcceptTruco;
  final VoidCallback onPassTruco;
  final ValueChanged<int> onRaiseTruco;
  final VoidCallback onContinueRound;
  final VoidCallback onNewHand;
  final VoidCallback onRestart;
  final VoidCallback onOptions;
  final VoidCallback onBack;

  const _VisibleGameControls({
    required this.compact,
    required this.signalsEnabled,
    required this.isGameFinished,
    required this.isHandFinished,
    required this.isRoundAwaitingContinue,
    required this.isWaitingHumanResponse,
    required this.canCallTruco,
    required this.handValue,
    required this.pendingTrucoValue,
    required this.trucoCallerTeamId,
    required this.isTrucoAccepted,
    required this.raiseOptions,
    required this.onSignalStart,
    required this.onSignalEnd,
    required this.onAskCompanionSignal,
    required this.onVoyATi,
    required this.onCallTruco,
    required this.onAcceptTruco,
    required this.onPassTruco,
    required this.onRaiseTruco,
    required this.onContinueRound,
    required this.onNewHand,
    required this.onRestart,
    required this.onOptions,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final signals = _SignalsBar(
      enabled: signalsEnabled,
      compact: compact,
      onSignalStart: onSignalStart,
      onSignalEnd: onSignalEnd,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final gap = min(constraints.maxWidth, constraints.maxHeight) * 0.035;
        final primaryAction = _primaryAction();
        final askSignal = ZapitiActionButton(
          label: 'PEDIR SENA',
          icon: Icons.visibility_outlined,
          onPressed: signalsEnabled ? onAskCompanionSignal : null,
        );
        final voyATi = ZapitiActionButton(
          label: '¡VOY A TI!',
          icon: Icons.record_voice_over_outlined,
          onPressed: signalsEnabled ? onVoyATi : null,
        );
        final options = ZapitiActionButton(
          label: 'OPCIONES',
          icon: Icons.settings_outlined,
          onPressed: onOptions,
          primary: false,
        );
        if (compact) {
          return Row(
            children: [
              SizedBox(
                width: constraints.maxWidth * 0.31,
                child: Column(
                  children: [
                    Expanded(child: primaryAction),
                    SizedBox(height: gap),
                    Expanded(child: askSignal),
                    SizedBox(height: gap),
                    Expanded(child: voyATi),
                    SizedBox(height: gap),
                    Expanded(child: options),
                    SizedBox(height: gap),
                    Expanded(child: _backButton()),
                  ],
                ),
              ),
              SizedBox(width: gap),
              Expanded(child: signals),
            ],
          );
        }

        // Landscape / non-compact: primary controls at left, signals at right,
        // and a wide centered VOLVER button below the row to match the screenshot.
        return Column(
          children: [
            Row(
              children: [
                SizedBox(
                  width: constraints.maxWidth * 0.46,
                  child: Row(
                    children: [
                      Expanded(child: primaryAction),
                      SizedBox(width: gap),
                      Expanded(child: askSignal),
                      SizedBox(width: gap),
                      Expanded(child: voyATi),
                      SizedBox(width: gap),
                      Expanded(child: options),
                    ],
                  ),
                ),
                SizedBox(width: gap),
                SizedBox(
                  width: constraints.maxWidth * 0.36,
                  height:
                      min(constraints.maxHeight, constraints.maxWidth) * 0.12,
                  child: signals,
                ),
              ],
            ),
            SizedBox(height: gap * 0.7),
            Center(
              child: SizedBox(
                width: constraints.maxWidth * 0.48,
                height: min(constraints.maxHeight, constraints.maxWidth) * 0.12,
                child: _backButton(),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _backButton() {
    return ZapitiActionButton(
      label: 'VOLVER',
      icon: Icons.arrow_back,
      onPressed: onBack,
      primary: false,
    );
  }

  Widget _primaryAction() {
    if (isGameFinished) {
      return _button('OTRA PARTIDA', Icons.restart_alt, onRestart, true);
    }
    if (isHandFinished) {
      return _button('REPARTIR', Icons.add, onNewHand, true);
    }
    if (isRoundAwaitingContinue) {
      return _button(
          'SIGUIENTE RONDA', Icons.arrow_forward, onContinueRound, true);
    }
    return _button('CANTAR TRUCO', Icons.campaign,
        canCallTruco && !isWaitingHumanResponse ? onCallTruco : null, true);
  }

  Widget _button(
    String label,
    IconData icon,
    VoidCallback? onPressed,
    bool primary,
  ) {
    return ZapitiActionButton(
      label: label,
      icon: icon,
      onPressed: onPressed,
      primary: primary,
    );
  }
}

class _GameOptionsOverlay extends StatelessWidget {
  final bool audioEnabled;
  final ValueChanged<bool> onAudioChanged;
  final double audioVolume;
  final ValueChanged<double> onAudioVolumeChanged;
  final _BotSpeed botSpeed;
  final ValueChanged<_BotSpeed> onBotSpeedChanged;
  final bool confirmCardPlay;
  final ValueChanged<bool> onConfirmCardPlayChanged;
  final VoidCallback onClose;

  const _GameOptionsOverlay({
    required this.audioEnabled,
    required this.onAudioChanged,
    required this.audioVolume,
    required this.onAudioVolumeChanged,
    required this.botSpeed,
    required this.onBotSpeedChanged,
    required this.confirmCardPlay,
    required this.onConfirmCardPlayChanged,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: ColoredBox(
        color: Colors.black.withValues(alpha: 0.28),
        child: Center(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final panelWidth = min(constraints.maxWidth * 0.86, 420.0);
              final panelHeight = min(constraints.maxHeight * 0.86, 360.0);

              return Material(
                color: Colors.transparent,
                child: Container(
                  width: panelWidth,
                  height: panelHeight,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: ZapitiColors.cardCream.withValues(alpha: 0.96),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: ZapitiColors.oldGold,
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.34),
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
                          const Icon(
                            Icons.settings_outlined,
                            color: ZapitiColors.wineRed,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Opciones',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    color: ZapitiColors.darkBrown,
                                    fontWeight: FontWeight.w900,
                                  ),
                            ),
                          ),
                          IconButton(
                            tooltip: 'Cerrar',
                            onPressed: onClose,
                            icon: const Icon(Icons.close),
                            color: ZapitiColors.darkBrown,
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Expanded(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.topCenter,
                          child: SizedBox(
                            width: panelWidth - 28,
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
                      const SizedBox(height: 8),
                      ZapitiActionButton(
                        label: 'VOLVER',
                        icon: Icons.arrow_back,
                        onPressed: onClose,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _LandscapeBottomBoard extends StatelessWidget {
  final List<SpanishCard> cards;
  final bool enabled;
  final bool isCurrent;
  final String? message;
  final String? companionMessage;
  final String characterId;
  final bool signalsEnabled;
  final bool isGameFinished;
  final bool isHandFinished;
  final bool isRoundAwaitingContinue;
  final bool isWaitingHumanResponse;
  final bool canCallTruco;
  final ValueChanged<SpanishCard> onPlayCard;
  final ValueChanged<String> onSignalStart;
  final ValueChanged<String> onSignalEnd;
  final VoidCallback onAskCompanionSignal;
  final VoidCallback onVoyATi;
  final VoidCallback onCallTruco;
  final VoidCallback onContinueRound;
  final VoidCallback onNewHand;
  final VoidCallback onRestart;
  final VoidCallback onOptions;
  final VoidCallback onBack;

  const _LandscapeBottomBoard({
    required this.cards,
    required this.enabled,
    required this.isCurrent,
    required this.message,
    required this.companionMessage,
    required this.characterId,
    required this.signalsEnabled,
    required this.isGameFinished,
    required this.isHandFinished,
    required this.isRoundAwaitingContinue,
    required this.isWaitingHumanResponse,
    required this.canCallTruco,
    required this.onPlayCard,
    required this.onSignalStart,
    required this.onSignalEnd,
    required this.onAskCompanionSignal,
    required this.onVoyATi,
    required this.onCallTruco,
    required this.onContinueRound,
    required this.onNewHand,
    required this.onRestart,
    required this.onOptions,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final shortest = min(constraints.maxWidth, constraints.maxHeight);
        final gap = shortest * 0.055;

        return Row(
          children: [
            Expanded(
              flex: 20,
              child: _LandscapeActionPanel(
                gap: gap,
                signalsEnabled: signalsEnabled,
                isGameFinished: isGameFinished,
                isHandFinished: isHandFinished,
                isRoundAwaitingContinue: isRoundAwaitingContinue,
                isWaitingHumanResponse: isWaitingHumanResponse,
                canCallTruco: canCallTruco,
                onAskCompanionSignal: onAskCompanionSignal,
                onVoyATi: onVoyATi,
                onCallTruco: onCallTruco,
                onContinueRound: onContinueRound,
                onNewHand: onNewHand,
                onRestart: onRestart,
                onOptions: onOptions,
                onBack: onBack,
              ),
            ),
            SizedBox(width: gap),
            Expanded(
              flex: 40,
              child: _LandscapeHumanPanel(
                cards: cards,
                enabled: enabled,
                isCurrent: isCurrent,
                message: message,
                companionMessage: companionMessage,
                characterId: characterId,
                onPlayCard: onPlayCard,
              ),
            ),
            SizedBox(width: gap),
            Expanded(
              flex: 40,
              child: _SignalsBar(
                enabled: signalsEnabled,
                compact: true,
                onSignalStart: onSignalStart,
                onSignalEnd: onSignalEnd,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _LandscapeActionPanel extends StatelessWidget {
  final double gap;
  final bool signalsEnabled;
  final bool isGameFinished;
  final bool isHandFinished;
  final bool isRoundAwaitingContinue;
  final bool isWaitingHumanResponse;
  final bool canCallTruco;
  final VoidCallback onAskCompanionSignal;
  final VoidCallback onVoyATi;
  final VoidCallback onCallTruco;
  final VoidCallback onContinueRound;
  final VoidCallback onNewHand;
  final VoidCallback onRestart;
  final VoidCallback onOptions;
  final VoidCallback onBack;

  const _LandscapeActionPanel({
    required this.gap,
    required this.signalsEnabled,
    required this.isGameFinished,
    required this.isHandFinished,
    required this.isRoundAwaitingContinue,
    required this.isWaitingHumanResponse,
    required this.canCallTruco,
    required this.onAskCompanionSignal,
    required this.onVoyATi,
    required this.onCallTruco,
    required this.onContinueRound,
    required this.onNewHand,
    required this.onRestart,
    required this.onOptions,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(child: _primaryAction()),
        SizedBox(height: gap),
        Expanded(
          child: ZapitiActionButton(
            label: 'PEDIR SENA',
            icon: Icons.visibility_outlined,
            onPressed: signalsEnabled ? onAskCompanionSignal : null,
          ),
        ),
        SizedBox(height: gap),
        Expanded(
          child: ZapitiActionButton(
            label: '¡VOY A TI!',
            icon: Icons.record_voice_over_outlined,
            onPressed: signalsEnabled ? onVoyATi : null,
          ),
        ),
        SizedBox(height: gap),
        Expanded(
          child: ZapitiActionButton(
            label: 'OPCIONES',
            icon: Icons.settings_outlined,
            onPressed: onOptions,
            primary: false,
          ),
        ),
        SizedBox(height: gap),
        Expanded(
          child: ZapitiActionButton(
            label: 'VOLVER',
            icon: Icons.arrow_back,
            onPressed: onBack,
            primary: false,
          ),
        ),
      ],
    );
  }

  Widget _primaryAction() {
    if (isGameFinished) {
      return _button('OTRA PARTIDA', Icons.restart_alt, onRestart, true);
    }
    if (isHandFinished) {
      return _button('REPARTIR', Icons.add, onNewHand, true);
    }
    if (isRoundAwaitingContinue) {
      return _button(
          'SIGUIENTE RONDA', Icons.arrow_forward, onContinueRound, true);
    }
    return _button('CANTAR TRUCO', Icons.campaign,
        canCallTruco && !isWaitingHumanResponse ? onCallTruco : null, true);
  }

  Widget _button(
    String label,
    IconData icon,
    VoidCallback? onPressed,
    bool primary,
  ) {
    return ZapitiActionButton(
      label: label,
      icon: icon,
      onPressed: onPressed,
      primary: primary,
    );
  }
}

class _LandscapeHumanPanel extends StatelessWidget {
  final List<SpanishCard> cards;
  final bool enabled;
  final bool isCurrent;
  final String? message;
  final String? companionMessage;
  final String characterId;
  final ValueChanged<SpanishCard> onPlayCard;

  const _LandscapeHumanPanel({
    required this.cards,
    required this.enabled,
    required this.isCurrent,
    required this.message,
    required this.companionMessage,
    required this.characterId,
    required this.onPlayCard,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const slots = 4;
        final shortest = min(constraints.maxWidth, constraints.maxHeight);
        final gap = shortest * 0.055;
        final padding = EdgeInsets.symmetric(
          horizontal: gap * 0.5,
          vertical: gap * 0.35,
        );
        final usableWidth = max(0.0, constraints.maxWidth - padding.horizontal);
        final usableHeight = max(0.0, constraints.maxHeight - padding.vertical);
        final widthBound = max(0.0, (usableWidth - gap * (slots - 1)) / slots);
        final heightBound = usableHeight * 80 / 122;
        final slotWidth = min(widthBound, heightBound);
        final slotHeight = slotWidth * 122 / 80;
        final rowWidth = slotWidth * slots + gap * (slots - 1);
        final signalText = _signalStatusText(companionMessage);

        return Padding(
          padding: padding,
          child: Center(
            child: SizedBox(
              width: rowWidth,
              height: slotHeight,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Row(
                    children: [
                      for (var index = 0; index < 3; index++) ...[
                        _LandscapeCardSlot(
                          card: index < cards.length ? cards[index] : null,
                          enabled: enabled && index < cards.length,
                          width: slotWidth,
                          height: slotHeight,
                          onTap: index < cards.length
                              ? () => onPlayCard(cards[index])
                              : null,
                        ),
                        SizedBox(width: gap),
                      ],
                      _LandscapeAvatarSlot(
                        isCurrent: isCurrent,
                        message: message,
                        characterId: characterId,
                        width: slotWidth,
                        height: slotHeight,
                        gap: gap,
                      ),
                    ],
                  ),
                  if (signalText != null)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: max(2.0, gap * 0.35),
                      child: IgnorePointer(
                        child: Center(
                          child: _LandscapeSignalBadge(
                            text: signalText,
                            maxWidth: rowWidth,
                            gap: gap,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String? _signalStatusText(String? value) {
    if (value == null || value.isEmpty) return null;
    if (value.startsWith('Compa')) return value;
    if (value == 'Mirando...') return 'Compa mira...';
    if (value == 'No llevo sena.') return 'Compa: sin sena';
    const signalPrefix = 'Sena: ';
    if (value.startsWith(signalPrefix)) {
      return 'Compa: ${value.substring(signalPrefix.length)}';
    }
    const carriesPrefix = 'Lleva ';
    if (value.startsWith(carriesPrefix)) return 'Compa: ${value.substring(6)}';
    return value;
  }
}

class _LandscapeSignalBadge extends StatelessWidget {
  final String text;
  final double maxWidth;
  final double gap;

  const _LandscapeSignalBadge({
    required this.text,
    required this.maxWidth,
    required this.gap,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: ZapitiColors.cardCream.withValues(alpha: 0.96),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: ZapitiColors.oldGold.withValues(alpha: 0.75),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.22),
              blurRadius: gap * 1.4,
              offset: Offset(0, gap * 0.38),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: gap * 1.2,
            vertical: max(2.0, gap * 0.35),
          ),
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: ZapitiColors.darkBrown,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
          ),
        ),
      ),
    );
  }
}

class _LandscapeCardSlot extends StatelessWidget {
  final SpanishCard? card;
  final bool enabled;
  final double width;
  final double height;
  final VoidCallback? onTap;

  const _LandscapeCardSlot({
    required this.card,
    required this.enabled,
    required this.width,
    required this.height,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: ZapitiCardWidget(
        card: card,
        width: width,
        height: height,
        enabled: enabled,
        onTap: onTap,
      ),
    );
  }
}

class _LandscapeAvatarSlot extends StatelessWidget {
  final bool isCurrent;
  final String? message;
  final String characterId;
  final double width;
  final double height;
  final double gap;

  const _LandscapeAvatarSlot({
    required this.isCurrent,
    required this.message,
    required this.characterId,
    required this.width,
    required this.height,
    required this.gap,
  });

  @override
  Widget build(BuildContext context) {
    final signal = _signalFromMessage(message);
    final avatarPath = CharacterAssets.frontForSignal(characterId, signal);
    final visibleMessage = signal == null ? message : null;
    final mirrorAvatar = signal == '7 Oros';
    final avatarVerticalOffset = height * _signalVerticalOffset(signal);

    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(gap * 0.9),
                border: Border.all(
                  color: isCurrent
                      ? ZapitiColors.oldGold
                      : ZapitiColors.darkBrown.withValues(alpha: 0.2),
                  width: max(1.0, gap * (isCurrent ? 0.26 : 0.16)),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.18),
                    blurRadius: gap * 1.8,
                    offset: Offset(0, gap * 0.55),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(gap * 0.75),
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.diagonal3Values(
                      mirrorAvatar ? -1 : 1,
                      1,
                      1,
                    ),
                    child: Transform.translate(
                      offset: Offset(0, avatarVerticalOffset),
                      child: Image.asset(
                        avatarPath,
                        key: ValueKey(avatarPath),
                        width: width,
                        height: height,
                        fit: BoxFit.contain,
                        gaplessPlayback: true,
                        alignment: Alignment.bottomCenter,
                        errorBuilder: (_, __, ___) {
                          return Icon(
                            Icons.person,
                            color:
                                ZapitiColors.darkBrown.withValues(alpha: 0.7),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (visibleMessage != null)
            Positioned(
              bottom: height + gap * 0.45,
              child: ZapitiSpeechBubble(
                text: visibleMessage,
                alignment: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }

  String? _signalFromMessage(String? message) {
    const prefix = 'Sena: ';

    if (message == null || !message.startsWith(prefix)) {
      return null;
    }

    return message.substring(prefix.length);
  }

  double _signalVerticalOffset(String? signal) {
    return switch (signal) {
      null => 0,
      '4 Bastos' => 0,
      '7 Copas' => 0,
      '7 Oros' => 0,
      'As Espadas' => 0.13,
      'Treses' => 0.15,
      'Doses' => 0.15,
      'Mala' => 0.13,
      _ => 0,
    };
  }
}

class _SignalsBar extends StatelessWidget {
  final bool enabled;
  final bool compact;
  final ValueChanged<String> onSignalStart;
  final ValueChanged<String> onSignalEnd;

  const _SignalsBar({
    required this.enabled,
    required this.compact,
    required this.onSignalStart,
    required this.onSignalEnd,
  });

  static const List<
      ({
        String label,
        SpanishCard? card,
        bool hiddenCard,
      })> _signals = [
    (
      label: '4 Bastos',
      card: SpanishCard(value: 4, suit: Suit.bastos),
      hiddenCard: false,
    ),
    (
      label: '7 Copas',
      card: SpanishCard(value: 7, suit: Suit.copas),
      hiddenCard: false,
    ),
    (
      label: '7 Oros',
      card: SpanishCard(value: 7, suit: Suit.oros),
      hiddenCard: false,
    ),
    (
      label: 'As Espadas',
      card: SpanishCard(value: 1, suit: Suit.espadas),
      hiddenCard: false,
    ),
    (
      label: 'Treses',
      card: SpanishCard(value: 3, suit: Suit.oros),
      hiddenCard: false,
    ),
    (
      label: 'Doses',
      card: SpanishCard(value: 2, suit: Suit.oros),
      hiddenCard: false,
    ),
    (label: 'Mala', card: null, hiddenCard: true),
  ];

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final shortest = min(constraints.maxWidth, constraints.maxHeight);
          final gap = shortest * 0.045;

          return Container(
            padding: EdgeInsets.all(gap),
            decoration: BoxDecoration(
              color: ZapitiColors.woodDark.withValues(alpha: 0.64),
              borderRadius: BorderRadius.circular(gap),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      for (final signal in _signals)
                        Expanded(
                          child: _SignalHoldButton(
                            label: signal.label,
                            card: signal.card,
                            hiddenCard: signal.hiddenCard,
                            enabled: enabled,
                            compact: true,
                            dense: true,
                            onStart: () => onSignalStart(signal.label),
                            onEnd: () => onSignalEnd(signal.label),
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
    }

    // Non-compact: present as a cream card with a title and the signal icons
    // inside to match the screenshot layout.
    final padding = EdgeInsets.all(compact ? 8 : 6);
    return Container(
      padding: padding,
      constraints: BoxConstraints(
          minHeight: compact ? 0 : 48,
          maxHeight: compact ? double.infinity : 72),
      decoration: BoxDecoration(
        color: ZapitiColors.cardCream.withValues(alpha: 0.98),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: ZapitiColors.oldGold.withValues(alpha: 0.28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              'Señas',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: ZapitiColors.darkBrown,
                    fontWeight: FontWeight.w900,
                  ),
            ),
          ),
          Row(
            children: [
              for (final signal in _signals)
                Expanded(
                  child: _SignalHoldButton(
                    label: signal.label,
                    card: signal.card,
                    hiddenCard: signal.hiddenCard,
                    enabled: enabled,
                    compact: compact,
                    dense: !compact,
                    onStart: () => onSignalStart(signal.label),
                    onEnd: () => onSignalEnd(signal.label),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SignalHoldButton extends StatefulWidget {
  final String label;
  final SpanishCard? card;
  final bool hiddenCard;
  final bool enabled;
  final bool compact;
  final bool dense;
  final VoidCallback onStart;
  final VoidCallback onEnd;

  const _SignalHoldButton({
    required this.label,
    required this.card,
    required this.hiddenCard,
    required this.enabled,
    required this.compact,
    this.dense = false,
    required this.onStart,
    required this.onEnd,
  });

  @override
  State<_SignalHoldButton> createState() => _SignalHoldButtonState();
}

class _SignalHoldButtonState extends State<_SignalHoldButton> {
  bool _pressed = false;

  void _start() {
    if (!widget.enabled) return;
    setState(() {
      _pressed = true;
    });
    widget.onStart();
  }

  void _end() {
    if (!_pressed) return;
    setState(() {
      _pressed = false;
    });
    widget.onEnd();
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = _pressed
        ? ZapitiColors.oldGold
        : ZapitiColors.cardCream
            .withValues(alpha: widget.enabled ? 0.95 : 0.28);
    return LayoutBuilder(
      builder: (context, constraints) {
        final bounded = constraints.maxWidth.isFinite &&
            constraints.maxHeight.isFinite &&
            constraints.maxWidth > 0 &&
            constraints.maxHeight > 0;
        final fallback = MediaQuery.sizeOf(context).shortestSide *
            (widget.dense ? 0.16 : 0.18);
        final size = bounded
            ? min(constraints.maxWidth, constraints.maxHeight)
            : fallback;
        final cardWidth = size * 0.52;

        return GestureDetector(
          onTapDown: widget.enabled ? (_) => _start() : null,
          onTapUp: widget.enabled ? (_) => _end() : null,
          onTapCancel: widget.enabled ? _end : null,
          child: Tooltip(
            message: widget.label,
            child: Semantics(
              button: true,
              label: widget.label,
              enabled: widget.enabled,
              child: Center(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 90),
                  width: size,
                  height: size,
                  padding: EdgeInsets.all(size * 0.14),
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _pressed
                          ? ZapitiColors.wineRed
                          : ZapitiColors.darkBrown.withValues(alpha: 0.18),
                      width: size * (_pressed ? 0.08 : 0.05),
                    ),
                    boxShadow: _pressed
                        ? [
                            BoxShadow(
                              color:
                                  ZapitiColors.oldGold.withValues(alpha: 0.25),
                              blurRadius: size * 0.24,
                              offset: Offset(0, size * 0.08),
                            ),
                          ]
                        : null,
                  ),
                  child: IgnorePointer(
                    child: Center(
                      child: ZapitiCardWidget(
                        card: widget.card,
                        hidden: widget.hiddenCard,
                        enabled: widget.enabled,
                        width: cardWidth,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
