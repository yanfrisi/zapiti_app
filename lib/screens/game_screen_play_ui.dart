part of 'game_screen.dart';

class _CompactGameHeader extends StatelessWidget {
  final int roundNumber;
  final int handValue;
  final int? pendingTrucoValue;
  final int? trucoCallerTeamId;
  final bool isTrucoAccepted;
  final double visualScale;

  const _CompactGameHeader({
    required this.roundNumber,
    required this.handValue,
    required this.pendingTrucoValue,
    required this.trucoCallerTeamId,
    required this.isTrucoAccepted,
    this.visualScale = 1,
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
        color: const Color(0xCC2A170F),
        borderRadius: BorderRadius.circular(10 * visualScale),
        border: Border.all(
          color: const Color(0xFF9D7419),
          width: max(1, visualScale),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: 6 * visualScale,
            offset: Offset(0, 2 * visualScale),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final padding = EdgeInsets.symmetric(
            horizontal: 12 * visualScale,
            vertical: 7 * visualScale,
          );
          final titleSize = max(9.0, 11 * visualScale);
          final valueSize = max(13.0, 18 * visualScale);

          return DefaultTextStyle(
            style: Theme.of(context).textTheme.bodySmall!.copyWith(
                  color: ZapitiColors.cardCream,
                  fontWeight: FontWeight.w800,
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
                        style: TextStyle(
                          fontSize: titleSize,
                          color: ZapitiColors.cardCream.withValues(alpha: 0.9),
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(height: 4 * visualScale),
                      Text(
                        trucoText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: const Color(0xFFD5A928),
                          fontSize: valueSize,
                          fontWeight: FontWeight.w900,
                        ),
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
  final double visualScale;

  const _GameScorePanel({
    required this.scoreTeamOne,
    required this.scoreTeamTwo,
    required this.roundWinsTeamOne,
    required this.roundWinsTeamTwo,
    required this.targetScore,
    this.visualScale = 1,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final gap = 6 * visualScale;
        final labelStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
              color: ZapitiColors.cardCream.withValues(alpha: 0.88),
              fontWeight: FontWeight.w900,
              fontSize: max(9.0, 11 * visualScale),
              height: 1.02,
            );
        final valueStyle = labelStyle?.copyWith(
          color: const Color(0xFFD5A928),
          fontSize: max(10.5, 13 * visualScale),
        );
        final padding = EdgeInsets.symmetric(
          horizontal: 12 * visualScale,
          vertical: 8 * visualScale,
        );
        final contentWidth =
            max(0.0, constraints.maxWidth - padding.horizontal);

        return Container(
          width: double.infinity,
          padding: padding,
          decoration: BoxDecoration(
            color: const Color(0xCC2A170F),
            borderRadius: BorderRadius.circular(10 * visualScale),
            border: Border.all(
              color: const Color(0xFF9D7419),
              width: max(1, visualScale),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.28),
                blurRadius: 6 * visualScale,
                offset: Offset(0, 2 * visualScale),
              ),
            ],
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
                    labelStyle: labelStyle,
                    valueStyle: valueStyle,
                  ),
                  Divider(
                    height: gap * 1.6,
                    color: ZapitiColors.oldGold.withValues(alpha: 0.16),
                  ),
                  _ScoreLine(
                    label: 'Eq2',
                    value: '$scoreTeamTwo / $targetScore',
                    labelStyle: labelStyle,
                    valueStyle: valueStyle,
                  ),
                  SizedBox(height: gap * 0.7),
                  _ScoreLine(
                    label: 'Rondas',
                    value: '$roundWinsTeamOne - $roundWinsTeamTwo',
                    labelStyle: labelStyle,
                    valueStyle: valueStyle,
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
  final TextStyle? labelStyle;
  final TextStyle? valueStyle;

  const _ScoreLine({
    required this.label,
    required this.value,
    required this.labelStyle,
    required this.valueStyle,
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
            style: labelStyle,
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
              style: valueStyle,
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
  final double scale;
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
    required this.scale,
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
        final gap = max(4.0, 5 * scale);
        final actionWidth = min(
          constraints.maxWidth * 0.33,
          (270 * scale).clamp(220.0, 338.0),
        );
        final historyWidth = min(
          constraints.maxWidth * 0.34,
          (296 * scale).clamp(244.0, 370.0),
        );

        return Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            SizedBox(
              width: actionWidth,
              child: _LandscapeActionPanel(
                scale: scale,
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
              child: _LandscapeHumanPanel(
                scale: scale,
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
            SizedBox(
              width: historyWidth,
              child: _SignalsBar(
                enabled: signalsEnabled,
                compact: true,
                twoRows: true,
                scale: scale,
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
  final double scale;
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
    required this.scale,
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
    final primaryHeight = (50 * scale).clamp(40.0, 62.0);
    final secondaryHeight = (40 * scale).clamp(34.0, 52.0);

    return Container(
      padding: EdgeInsets.all(max(4.0, 5 * scale)),
      decoration: BoxDecoration(
        color: const Color(0x992A170F),
        borderRadius: BorderRadius.circular(10 * scale),
        border: Border.all(
          color: ZapitiColors.oldGold.withValues(alpha: 0.5),
          width: max(1, scale),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: primaryHeight, child: _primaryAction()),
          SizedBox(height: gap),
          SizedBox(
            height: secondaryHeight,
            child: Row(
              children: [
                Expanded(
                  child: ZapitiActionButton(
                    label: 'PEDIR SENA',
                    icon: Icons.visibility_outlined,
                    onPressed: signalsEnabled ? onAskCompanionSignal : null,
                  ),
                ),
                SizedBox(width: gap),
                Expanded(
                  child: ZapitiActionButton(
                    label: '¡VOY A TI!',
                    icon: Icons.record_voice_over_outlined,
                    onPressed: signalsEnabled ? onVoyATi : null,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: gap),
          SizedBox(
            height: secondaryHeight,
            child: Row(
              children: [
                Expanded(
                  child: _DarkUtilityButton(
                    label: 'OPCIONES',
                    icon: Icons.settings_outlined,
                    onPressed: onOptions,
                    scale: scale,
                  ),
                ),
                SizedBox(width: gap),
                Expanded(
                  child: _DarkUtilityButton(
                    label: 'VOLVER',
                    icon: Icons.arrow_back,
                    onPressed: onBack,
                    scale: scale,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
        ],
      ),
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

class _DarkUtilityButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final double scale;

  const _DarkUtilityButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    required this.scale,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xCC2A170F),
          foregroundColor: ZapitiColors.cardCream,
          disabledBackgroundColor:
              ZapitiColors.cardCream.withValues(alpha: 0.24),
          disabledForegroundColor:
              ZapitiColors.darkBrown.withValues(alpha: 0.46),
          padding: EdgeInsets.symmetric(horizontal: 7 * scale),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8 * scale),
            side: BorderSide(
              color: ZapitiColors.oldGold.withValues(alpha: 0.72),
              width: max(1, scale),
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: (17 * scale).clamp(14.0, 21.0)),
            SizedBox(width: 5 * scale),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: max(9.0, 10.5 * scale),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LandscapeHumanPanel extends StatelessWidget {
  final double scale;
  final List<SpanishCard> cards;
  final bool enabled;
  final bool isCurrent;
  final String? message;
  final String? companionMessage;
  final String characterId;
  final ValueChanged<SpanishCard> onPlayCard;

  const _LandscapeHumanPanel({
    required this.scale,
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
        const slots = 3;
        final gap = max(5.0, 7 * scale);
        final padding = EdgeInsets.only(top: 2 * scale);
        final usableWidth = max(0.0, constraints.maxWidth - padding.horizontal);
        final usableHeight = max(0.0, constraints.maxHeight - padding.vertical);
        const overlapFactor = 0.66;
        final localFactor = usableHeight < 150 ? 0.75 : 0.9;
        final avatarWidth = (96 * scale * localFactor).clamp(68.0, 108.0);
        final avatarHeight = min(
          usableHeight,
          (154 * scale * localFactor).clamp(104.0, 172.0),
        );
        final heightBound = usableHeight * 80 / 122;
        final widthBound = max(
          0.0,
          (usableWidth - avatarWidth - gap * 2) /
              (1 + overlapFactor * (slots - 1)),
        );
        final cardWidth = min(
          (118 * scale * localFactor).clamp(78.0, 132.0),
          min(widthBound, heightBound),
        );
        final cardHeight = cardWidth * 122 / 80;
        final cardOffset = cardWidth * overlapFactor;
        final handWidth = cardWidth + cardOffset * (slots - 1);
        final rowWidth = avatarWidth + gap * 1.6 + handWidth;
        final signalText = _signalStatusText(companionMessage);

        return Padding(
          padding: padding,
          child: Center(
            child: SizedBox(
              width: rowWidth,
              height: max(avatarHeight, cardHeight),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _LandscapeAvatarSlot(
                        isCurrent: isCurrent,
                        message: message,
                        characterId: characterId,
                        width: avatarWidth,
                        height: avatarHeight,
                        gap: gap,
                      ),
                      SizedBox(width: gap * 1.6),
                      SizedBox(
                        width: handWidth,
                        height: cardHeight + 10 * scale,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            for (var index = 0; index < slots; index++)
                              AnimatedPositioned(
                                key: ValueKey('landscape-card-$index'),
                                duration: const Duration(milliseconds: 160),
                                curve: Curves.easeOut,
                                left: cardOffset * index,
                                bottom: enabled && index < cards.length
                                    ? 6 * scale
                                    : 0,
                                child: _LandscapeCardSlot(
                                  card: index < cards.length
                                      ? cards[index]
                                      : null,
                                  enabled: enabled && index < cards.length,
                                  width: cardWidth,
                                  height: cardHeight,
                                  highlighted: enabled && index < cards.length,
                                  onTap: index < cards.length
                                      ? () => onPlayCard(cards[index])
                                      : null,
                                ),
                              ),
                          ],
                        ),
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
  final bool highlighted;
  final VoidCallback? onTap;

  const _LandscapeCardSlot({
    required this.card,
    required this.enabled,
    required this.width,
    required this.height,
    this.highlighted = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          boxShadow: highlighted
              ? [
                  BoxShadow(
                    color: ZapitiColors.oldGold.withValues(alpha: 0.32),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: ZapitiCardWidget(
          card: card,
          width: width,
          height: height,
          enabled: enabled,
          onTap: onTap,
        ),
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
                color: const Color(0xCC2A170F),
                borderRadius: BorderRadius.circular(gap * 0.9),
                border: Border.all(
                  color: isCurrent
                      ? ZapitiColors.oldGold
                      : ZapitiColors.oldGold.withValues(alpha: 0.48),
                  width: max(1.0, gap * (isCurrent ? 0.26 : 0.16)),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.28),
                    blurRadius: gap * 1.8,
                    offset: Offset(0, gap * 0.55),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(gap * 0.75),
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: AvatarWithSilhouette(
                    assetPath: avatarPath,
                    width: width,
                    height: height,
                    mirror: mirrorAvatar,
                    offset: Offset(0, avatarVerticalOffset),
                    alignment: Alignment.bottomCenter,
                    errorBuilder: (_, __, ___) {
                      return Icon(
                        Icons.person,
                        color: ZapitiColors.darkBrown.withValues(alpha: 0.7),
                      );
                    },
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
  final bool twoRows;
  final double scale;
  final ValueChanged<String> onSignalStart;
  final ValueChanged<String> onSignalEnd;

  const _SignalsBar({
    required this.enabled,
    required this.compact,
    this.twoRows = false,
    this.scale = 1,
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
          final gap = max(6.0, 7 * scale);
          if (!twoRows) {
            return Container(
              padding: EdgeInsets.all(gap),
              decoration: BoxDecoration(
                color: const Color(0xCC2A170F),
                borderRadius: BorderRadius.circular(10 * scale),
                border: Border.all(
                  color: ZapitiColors.oldGold.withValues(alpha: 0.58),
                  width: max(1, scale),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.26),
                    blurRadius: 6 * scale,
                    offset: Offset(0, 2 * scale),
                  ),
                ],
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: SizedBox(
                  width: max(0, constraints.maxWidth - gap * 2),
                  height: max(0, constraints.maxHeight - gap * 2),
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
              ),
            );
          }

          final horizontalGap = max(6.0, 8 * scale);
          final verticalGap = max(4.0, 6 * scale);
          final availableWidth = max(0.0, constraints.maxWidth - gap * 2);
          final availableHeight = max(0.0, constraints.maxHeight - gap * 2);
          final widthBound = (availableWidth - horizontalGap * 3) / 4;
          final heightBound = (availableHeight - verticalGap) / 2;
          final signalSize = min(
            52 * scale,
            min(widthBound, heightBound),
          ).clamp(42.0, 66.0).toDouble();
          final firstRow = _signals.take(4).toList();
          final secondRow = _signals.skip(4).toList();

          List<Widget> rowButtons(
            List<
                    ({
                      String label,
                      SpanishCard? card,
                      bool hiddenCard,
                    })>
                signals,
          ) {
            return [
              for (var index = 0; index < signals.length; index++) ...[
                if (index > 0) SizedBox(width: horizontalGap),
                SizedBox(
                  width: signalSize,
                  height: signalSize,
                  child: _SignalHoldButton(
                    label: signals[index].label,
                    card: signals[index].card,
                    hiddenCard: signals[index].hiddenCard,
                    enabled: enabled,
                    compact: true,
                    dense: true,
                    onStart: () => onSignalStart(signals[index].label),
                    onEnd: () => onSignalEnd(signals[index].label),
                  ),
                ),
              ],
            ];
          }

          return Container(
            padding: EdgeInsets.all(gap),
            decoration: BoxDecoration(
              color: const Color(0xCC2A170F),
              borderRadius: BorderRadius.circular(10 * scale),
              border: Border.all(
                color: ZapitiColors.oldGold.withValues(alpha: 0.58),
                width: max(1, scale),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.26),
                  blurRadius: 6 * scale,
                  offset: Offset(0, 2 * scale),
                ),
              ],
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: rowButtons(firstRow),
                  ),
                  SizedBox(height: verticalGap),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: rowButtons(secondRow),
                  ),
                ],
              ),
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
