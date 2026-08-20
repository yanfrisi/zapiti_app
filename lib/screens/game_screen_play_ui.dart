part of 'game_screen.dart';

String _difficultyLabel(BuildContext context, int level) {
  return switch (level) {
    1 => context.tr('difficultyVeryEasy'),
    2 => context.tr('difficultyEasy'),
    3 => context.tr('difficultyNormal'),
    4 => context.tr('difficultyHard'),
    5 => context.tr('difficultyExpert'),
    _ => context.tr('difficultyNormal'),
  };
}

class _MultiplayerConnectionOverlay extends StatelessWidget {
  final bool reconnecting;
  final VoidCallback? onReturnToMenu;

  const _MultiplayerConnectionOverlay({
    required this.reconnecting,
    required this.onReturnToMenu,
  });

  @override
  Widget build(BuildContext context) {
    final title = reconnecting
        ? context.tr('multiplayerRecoveringConnection')
        : context.tr('connectionLostMatch');
    final body = reconnecting
        ? context.tr('multiplayerConnectionActionsPaused')
        : context.tr('multiplayerConnectionFailedReturn');

    return Positioned.fill(
      child: AbsorbPointer(
        absorbing: reconnecting,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.34),
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 390),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: ZapitiColors.darkBrown.withValues(alpha: 0.94),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: reconnecting
                        ? ZapitiColors.oldGold
                        : ZapitiColors.wineRed.withValues(alpha: 0.85),
                    width: 1.4,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.34),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (reconnecting) ...[
                        const SizedBox(
                          width: 30,
                          height: 30,
                          child: CircularProgressIndicator(strokeWidth: 3),
                        ),
                        const SizedBox(height: 14),
                      ] else ...[
                        const Icon(
                          Icons.wifi_off_rounded,
                          color: ZapitiColors.oldGold,
                          size: 34,
                        ),
                        const SizedBox(height: 12),
                      ],
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: ZapitiColors.cardCream,
                                  fontWeight: FontWeight.w900,
                                ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        body,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: ZapitiColors.cardCream
                                  .withValues(alpha: 0.86),
                              fontWeight: FontWeight.w700,
                              height: 1.22,
                            ),
                      ),
                      if (onReturnToMenu != null) ...[
                        const SizedBox(height: 16),
                        ZapitiActionButton(
                          label: context.tr('returnToMenu'),
                          icon: Icons.home_outlined,
                          onPressed: onReturnToMenu,
                          primary: true,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MultiplayerMatchCanceledOverlay extends StatelessWidget {
  final VoidCallback onReturnToMenu;

  const _MultiplayerMatchCanceledOverlay({
    required this.onReturnToMenu,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.38),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 390),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: ZapitiColors.darkBrown.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: ZapitiColors.oldGold,
                  width: 1.4,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.34),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.person_off_outlined,
                      color: ZapitiColors.oldGold,
                      size: 36,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      context.tr('multiplayerMatchCanceledByLeave'),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: ZapitiColors.cardCream,
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      context.tr('multiplayerMatchCanceledByLeaveBody'),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color:
                                ZapitiColors.cardCream.withValues(alpha: 0.86),
                            fontWeight: FontWeight.w700,
                            height: 1.22,
                          ),
                    ),
                    const SizedBox(height: 16),
                    ZapitiActionButton(
                      label: context.tr('returnToMenu'),
                      icon: Icons.home_outlined,
                      onPressed: onReturnToMenu,
                      primary: true,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GuidedTutorialOverlay extends StatelessWidget {
  final _TutorialTableScenario scenario;
  final int index;
  final int total;
  final bool completed;

  const _GuidedTutorialOverlay({
    required this.scenario,
    required this.index,
    required this.total,
    this.completed = false,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isCompact = size.height < 520 || size.width < 420;
    final titleStyle = Theme.of(context).textTheme.titleSmall?.copyWith(
          color: ZapitiColors.cardCream,
          fontWeight: FontWeight.w900,
        );
    final bodyStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
          color: ZapitiColors.cardCream.withValues(alpha: 0.92),
          fontWeight: FontWeight.w800,
          height: 1.12,
        );
    final badge = completed ? 'OK' : '${index + 1}/$total';
    final title = completed
        ? context.tr('guidedCompleteTitle')
        : context.tr(scenario.titleKey);
    final instruction = completed
        ? context.tr('guidedCompleteInstruction')
        : context.tr(scenario.instructionKey);

    return Positioned(
      left: 10,
      right: 10,
      top: 8,
      child: SafeArea(
        bottom: false,
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: isCompact ? 420 : 560,
            ),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: ZapitiColors.darkBrown.withValues(alpha: 0.90),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: ZapitiColors.oldGold.withValues(alpha: 0.78),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.28),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isCompact ? 8 : 12,
                  vertical: isCompact ? 6 : 8,
                ),
                child: Row(
                  children: [
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: ZapitiColors.wineRed,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 5,
                        ),
                        child: Text(
                          badge,
                          style: titleStyle,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: titleStyle,
                          ),
                          Text(
                            instruction,
                            maxLines: isCompact ? 1 : 2,
                            overflow: TextOverflow.ellipsis,
                            style: bodyStyle,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CompactGameHeader extends StatelessWidget {
  final int roundNumber;
  final int handValue;
  final BetState betState;
  final DifficultyProfile difficultyProfile;
  final double visualScale;

  const _CompactGameHeader({
    required this.roundNumber,
    required this.handValue,
    required this.betState,
    required this.difficultyProfile,
    this.visualScale = 1,
  });

  @override
  Widget build(BuildContext context) {
    final chinoText =
        handValue == 1 ? context.tr('chino') : context.tr('chinos');
    final trucoText = !betState.responsePending
        ? '$handValue $chinoText'
        : betState.proposingTeam == null
            ? '$handValue $chinoText'
            : context.tr(
                'teamRaises',
                params: {
                  'team': betState.proposingTeam,
                  'value': betState.proposedLevel?.value,
                },
              );

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
                        context
                            .tr('roundHeader', params: {'round': roundNumber}),
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
                      SizedBox(height: 3 * visualScale),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.psychology_alt_outlined,
                            size: max(9.0, 11 * visualScale),
                            color:
                                ZapitiColors.cardCream.withValues(alpha: 0.74),
                          ),
                          SizedBox(width: 4 * visualScale),
                          Flexible(
                            child: Text(
                              context.tr(
                                'aiDifficulty',
                                params: {
                                  'level': difficultyProfile.level,
                                  'label': _difficultyLabel(
                                    context,
                                    difficultyProfile.level,
                                  ),
                                },
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: max(8.0, 10 * visualScale),
                                color: ZapitiColors.cardCream
                                    .withValues(alpha: 0.76),
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ],
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
                    label: context.tr('teamShort', params: {'team': 1}),
                    value: '$scoreTeamOne / $targetScore',
                    labelStyle: labelStyle,
                    valueStyle: valueStyle,
                  ),
                  Divider(
                    height: gap * 1.6,
                    color: ZapitiColors.oldGold.withValues(alpha: 0.16),
                  ),
                  _ScoreLine(
                    label: context.tr('teamShort', params: {'team': 2}),
                    value: '$scoreTeamTwo / $targetScore',
                    labelStyle: labelStyle,
                    valueStyle: valueStyle,
                  ),
                  SizedBox(height: gap * 0.7),
                  _ScoreLine(
                    label: context.tr('rounds'),
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
  final ValueChanged<String> onSignalStart;
  final ValueChanged<String> onSignalEnd;
  final VoidCallback onAccept;
  final VoidCallback onPass;
  final ValueChanged<int> onRaise;

  const _TrucoResponseOverlay({
    required this.pendingTrucoValue,
    required this.raiseOptions,
    required this.onAskCompanionSignal,
    required this.onSignalStart,
    required this.onSignalEnd,
    required this.onAccept,
    required this.onPass,
    required this.onRaise,
  });

  @override
  State<_TrucoResponseOverlay> createState() => _TrucoResponseOverlayState();
}

class _TrucoResponseOverlayState extends State<_TrucoResponseOverlay> {
  static const _incomingBetCardPreviewDuration = Duration(milliseconds: 3500);

  int _selectedRaiseIndex = 0;
  bool _initialCardPreviewActive = true;
  bool _manualPeekThroughOverlay = false;
  Timer? _initialCardPreviewTimer;

  bool get _peekThroughOverlay =>
      _initialCardPreviewActive || _manualPeekThroughOverlay;

  void _startInitialCardPreview() {
    _initialCardPreviewTimer?.cancel();
    _initialCardPreviewActive = true;
    _initialCardPreviewTimer = Timer(_incomingBetCardPreviewDuration, () {
      if (!mounted) return;
      setState(() {
        _initialCardPreviewActive = false;
      });
    });
  }

  void _setManualPeekThroughOverlay(bool value) {
    if (_manualPeekThroughOverlay == value) return;
    setState(() {
      _manualPeekThroughOverlay = value;
    });
  }

  @override
  void initState() {
    super.initState();
    _startInitialCardPreview();
  }

  @override
  void didUpdateWidget(covariant _TrucoResponseOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_selectedRaiseIndex >= widget.raiseOptions.length) {
      _selectedRaiseIndex = 0;
    }
    if (oldWidget.pendingTrucoValue != widget.pendingTrucoValue) {
      setState(_startInitialCardPreview);
    }
  }

  @override
  void dispose() {
    _initialCardPreviewTimer?.cancel();
    _initialCardPreviewTimer = null;
    super.dispose();
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
              final signalHeight = (isNarrow ? 44.0 : 50.0).clamp(
                shortest * 0.11,
                shortest * 0.16,
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
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          AnimatedOpacity(
                            key: const ValueKey('truco-response-panel-opacity'),
                            opacity: _peekThroughOverlay ? 0.16 : 1,
                            duration: const Duration(milliseconds: 90),
                            child: Container(
                              padding: EdgeInsets.all(gap),
                              decoration: BoxDecoration(
                                color: ZapitiColors.cardCream
                                    .withValues(alpha: 0.92),
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
                                          context.tr(
                                            'calledValue',
                                            params: {
                                              'value': widget.pendingTrucoValue,
                                            },
                                          ),
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium
                                              ?.copyWith(
                                                color: ZapitiColors.darkBrown,
                                                fontWeight: FontWeight.w900,
                                              ),
                                        ),
                                      ),
                                      SizedBox(width: max(42.0, gap * 4.0)),
                                    ],
                                  ),
                                  SizedBox(height: gap),
                                  Align(
                                    alignment: Alignment.center,
                                    child: SizedBox(
                                      width: min(panelWidth * 0.56, 230.0),
                                      child: ZapitiActionButton(
                                        label: context.tr('askSignalUpper'),
                                        icon: Icons.visibility_outlined,
                                        onPressed: widget.onAskCompanionSignal,
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: gap),
                                  SizedBox(
                                    height: signalHeight,
                                    child: _SignalsBar(
                                      enabled: true,
                                      compact: true,
                                      scale: isNarrow ? 0.68 : 0.78,
                                      onSignalStart: widget.onSignalStart,
                                      onSignalEnd: widget.onSignalEnd,
                                    ),
                                  ),
                                  SizedBox(height: gap),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: ZapitiActionButton(
                                          label: context.tr('rejectUpper'),
                                          icon: Icons.block,
                                          onPressed: widget.onPass,
                                        ),
                                      ),
                                      SizedBox(width: gap),
                                      Expanded(
                                        child: ZapitiActionButton(
                                          label: context.tr('acceptUpper'),
                                          icon: Icons.check,
                                          onPressed: widget.onAccept,
                                          primary: true,
                                        ),
                                      ),
                                      SizedBox(width: gap),
                                      Expanded(
                                        child: ZapitiActionButton(
                                          label: selectedRaise == null
                                              ? context.tr('raiseUpper')
                                              : context.tr(
                                                  'raiseToUpper',
                                                  params: {
                                                    'value': selectedRaise,
                                                  },
                                                ),
                                          icon: Icons.trending_up,
                                          onPressed: selectedRaise == null
                                              ? null
                                              : () =>
                                                  widget.onRaise(selectedRaise),
                                          primary: true,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: gap * 0.8),
                                  Text(
                                    selectedRaise == null
                                        ? context.tr('noLegalRaise')
                                        : context.tr(
                                            'raiseValue',
                                            params: {'value': selectedRaise},
                                          ),
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
                                              _selectedRaiseIndex =
                                                  value.round();
                                            });
                                          }
                                        : null,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Positioned(
                            top: max(4.0, gap * 0.55),
                            right: max(4.0, gap * 0.55),
                            child: GestureDetector(
                              key: const ValueKey(
                                'truco-response-card-peek-button',
                              ),
                              onTapDown: (_) =>
                                  _setManualPeekThroughOverlay(true),
                              onTapUp: (_) =>
                                  _setManualPeekThroughOverlay(false),
                              onTapCancel: () =>
                                  _setManualPeekThroughOverlay(false),
                              child: Tooltip(
                                message: context.tr('holdToViewCards'),
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: ZapitiColors.darkBrown
                                        .withValues(alpha: 0.90),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: ZapitiColors.oldGold,
                                      width: 1,
                                    ),
                                  ),
                                  child: SizedBox.square(
                                    dimension: max(34.0, gap * 3.3),
                                    child: Icon(
                                      Icons.visibility_outlined,
                                      color: ZapitiColors.cardCream,
                                      size: max(18.0, gap * 1.55),
                                    ),
                                  ),
                                ),
                              ),
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
  final bool isHumanTurn;
  final bool canPassHand;
  final bool canCallTruco;
  final int handValue;
  final BetState betState;
  final List<int> raiseOptions;
  final ValueChanged<String> onSignalStart;
  final ValueChanged<String> onSignalEnd;
  final VoidCallback? onShowSignalHelp;
  final VoidCallback onAskCompanionSignal;
  final VoidCallback onPassHand;
  final VoidCallback onVoyATi;
  final VoidCallback onComeToMe;
  final VoidCallback onKill;
  final VoidCallback onCallTruco;
  final VoidCallback onAcceptTruco;
  final VoidCallback onPassTruco;
  final ValueChanged<int> onRaiseTruco;
  final VoidCallback onContinueRound;
  final VoidCallback onNewHand;
  final VoidCallback onRestart;
  final VoidCallback? onOptions;
  final VoidCallback onBack;

  const _VisibleGameControls({
    required this.compact,
    required this.signalsEnabled,
    required this.isGameFinished,
    required this.isHandFinished,
    required this.isRoundAwaitingContinue,
    required this.isWaitingHumanResponse,
    required this.isHumanTurn,
    required this.canPassHand,
    required this.canCallTruco,
    required this.handValue,
    required this.betState,
    required this.raiseOptions,
    required this.onSignalStart,
    required this.onSignalEnd,
    required this.onShowSignalHelp,
    required this.onAskCompanionSignal,
    required this.onPassHand,
    required this.onVoyATi,
    required this.onComeToMe,
    required this.onKill,
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
        final primaryAction = _primaryAction(context);
        final passHand = ZapitiActionButton(
          label: context.tr('passHandUpper'),
          icon: Icons.swap_horiz_outlined,
          onPressed: canPassHand ? onPassHand : null,
          primary: true,
        );
        final askSignal = ZapitiActionButton(
          label: context.tr('askSignalUpper'),
          icon: Icons.visibility_outlined,
          onPressed: signalsEnabled ? onAskCompanionSignal : null,
        );
        final companionCommand = ZapitiActionButton(
          label: context.tr('voyATiUpper'),
          icon: Icons.record_voice_over_outlined,
          onPressed: signalsEnabled ? onVoyATi : null,
        );
        final comeToMeCommand = ZapitiActionButton(
          label: context.tr('comeToMeUpper'),
          icon: Icons.keyboard_double_arrow_down_outlined,
          onPressed: signalsEnabled ? onComeToMe : null,
        );
        final killCommand = ZapitiActionButton(
          label: context.tr('killUpper'),
          icon: Icons.local_fire_department_outlined,
          onPressed: signalsEnabled ? onKill : null,
        );
        final options = ZapitiActionButton(
          label: context.tr('options'),
          icon: Icons.settings_outlined,
          onPressed: onOptions,
          primary: false,
        );
        final signalHelp = ZapitiActionButton(
          label: context.tr('signalHelpUpper'),
          icon: Icons.help_outline,
          onPressed: onShowSignalHelp,
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
                    if (canPassHand) ...[
                      Expanded(child: passHand),
                      SizedBox(height: gap),
                    ],
                    Expanded(child: askSignal),
                    SizedBox(height: gap),
                    if (isHumanTurn) ...[
                      Expanded(child: companionCommand),
                      SizedBox(height: gap),
                    ] else ...[
                      Expanded(child: comeToMeCommand),
                      SizedBox(height: gap),
                      Expanded(child: killCommand),
                      SizedBox(height: gap),
                    ],
                    Expanded(child: options),
                    SizedBox(height: gap),
                    Expanded(child: _backButton(context)),
                  ],
                ),
              ),
              SizedBox(width: gap),
              Expanded(
                child: Column(
                  children: [
                    SizedBox(
                      height: max(36.0, constraints.maxHeight * 0.18),
                      child: signalHelp,
                    ),
                    SizedBox(height: gap),
                    Expanded(child: signals),
                  ],
                ),
              ),
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
                  width: constraints.maxWidth * (canPassHand ? 0.56 : 0.46),
                  child: Row(
                    children: [
                      Expanded(child: primaryAction),
                      SizedBox(width: gap),
                      if (canPassHand) ...[
                        Expanded(child: passHand),
                        SizedBox(width: gap),
                      ],
                      Expanded(child: askSignal),
                      SizedBox(width: gap),
                      if (isHumanTurn) ...[
                        Expanded(child: companionCommand),
                        SizedBox(width: gap),
                      ] else ...[
                        Expanded(child: comeToMeCommand),
                        SizedBox(width: gap),
                        Expanded(child: killCommand),
                        SizedBox(width: gap),
                      ],
                      Expanded(child: options),
                    ],
                  ),
                ),
                SizedBox(width: gap),
                SizedBox(
                  width: constraints.maxWidth * (canPassHand ? 0.26 : 0.36),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        height:
                            min(constraints.maxHeight, constraints.maxWidth) *
                                0.11,
                        child: signalHelp,
                      ),
                      SizedBox(height: gap * 0.6),
                      SizedBox(
                        height:
                            min(constraints.maxHeight, constraints.maxWidth) *
                                0.12,
                        child: signals,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: gap * 0.7),
            Center(
              child: SizedBox(
                width: constraints.maxWidth * 0.48,
                height: min(constraints.maxHeight, constraints.maxWidth) * 0.12,
                child: _backButton(context),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _backButton(BuildContext context) {
    return ZapitiActionButton(
      label: context.tr('back'),
      icon: Icons.arrow_back,
      onPressed: onBack,
      primary: false,
    );
  }

  Widget _primaryAction(BuildContext context) {
    if (isGameFinished) {
      return _button(
          context.tr('newMatchUpper'), Icons.restart_alt, onRestart, true);
    }
    if (isHandFinished) {
      return _button(context.tr('newHandUpper'), Icons.add, onNewHand, true);
    }
    if (isRoundAwaitingContinue) {
      return _button(context.tr('nextRoundUpper'), Icons.arrow_forward,
          onContinueRound, true);
    }
    return _button(context.tr('callTrucoUpper'), Icons.campaign,
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
  final ZapitiLanguage language;
  final ValueChanged<ZapitiLanguage> onLanguageChanged;
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
    required this.language,
    required this.onLanguageChanged,
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
                              context.tr('options'),
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
                            tooltip: context.tr('close'),
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
                              language: language,
                              onLanguageChanged: onLanguageChanged,
                              onBack: onClose,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      ZapitiActionButton(
                        label: context.tr('back'),
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

class _AlVerDecisionOverlay extends StatefulWidget {
  final int teamId;
  final VoidCallback onAskCompanionSignal;
  final ValueChanged<String> onSignalStart;
  final ValueChanged<String> onSignalEnd;
  final ValueChanged<int> onPlay;
  final ValueChanged<int> onGoHome;

  const _AlVerDecisionOverlay({
    required this.teamId,
    required this.onAskCompanionSignal,
    required this.onSignalStart,
    required this.onSignalEnd,
    required this.onPlay,
    required this.onGoHome,
  });

  @override
  State<_AlVerDecisionOverlay> createState() => _AlVerDecisionOverlayState();
}

class _AlVerDecisionOverlayState extends State<_AlVerDecisionOverlay> {
  bool _peekThroughOverlay = false;

  void _setPeekThroughOverlay(bool value) {
    if (_peekThroughOverlay == value) return;
    setState(() {
      _peekThroughOverlay = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final titleStyle = Theme.of(context).textTheme.titleLarge?.copyWith(
          color: ZapitiColors.oldGold,
          fontWeight: FontWeight.w900,
        );
    final bodyStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: ZapitiColors.cardCream.withValues(alpha: 0.92),
          height: 1.25,
          fontWeight: FontWeight.w700,
        );

    return Positioned.fill(
      child: Align(
        alignment: const Alignment(0, -0.12),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final shortest = min(constraints.maxWidth, constraints.maxHeight);
            final isNarrow = constraints.maxWidth < 560;
            final gap = shortest * (isNarrow ? 0.015 : 0.014);
            final panelWidth = min(
              constraints.maxWidth * (isNarrow ? 0.78 : 0.46),
              isNarrow ? 360.0 : 390.0,
            );
            final signalHeight = (isNarrow ? 44.0 : 50.0).clamp(
              shortest * 0.11,
              shortest * 0.16,
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
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        AnimatedOpacity(
                          opacity: _peekThroughOverlay ? 0.16 : 1,
                          duration: const Duration(milliseconds: 90),
                          child: Container(
                            padding: EdgeInsets.all(gap),
                            decoration: BoxDecoration(
                              color: const Color(0xDD2A170F),
                              borderRadius: BorderRadius.circular(8),
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
                                Text(context.tr('alVerTitle'),
                                    style: titleStyle),
                                SizedBox(height: gap * 0.75),
                                Text(
                                  context.tr('alVerBody'),
                                  style: bodyStyle,
                                ),
                                SizedBox(height: gap),
                                ZapitiActionButton(
                                  label: context.tr('askSignalUpper'),
                                  icon: Icons.visibility_outlined,
                                  onPressed: widget.onAskCompanionSignal,
                                ),
                                SizedBox(height: gap),
                                SizedBox(
                                  height: signalHeight,
                                  child: _SignalsBar(
                                    enabled: true,
                                    compact: true,
                                    scale: isNarrow ? 0.68 : 0.78,
                                    onSignalStart: widget.onSignalStart,
                                    onSignalEnd: widget.onSignalEnd,
                                  ),
                                ),
                                SizedBox(height: gap),
                                Row(
                                  children: [
                                    Expanded(
                                      child: ZapitiActionButton(
                                        label: context.tr('play'),
                                        icon: Icons.check,
                                        onPressed: () =>
                                            widget.onPlay(widget.teamId),
                                        primary: true,
                                      ),
                                    ),
                                    SizedBox(width: gap),
                                    Expanded(
                                      child: ZapitiActionButton(
                                        label: context.tr('goHomeUpper'),
                                        icon: Icons.block,
                                        onPressed: () =>
                                            widget.onGoHome(widget.teamId),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          top: max(4.0, gap * 0.55),
                          right: max(4.0, gap * 0.55),
                          child: GestureDetector(
                            onTapDown: (_) => _setPeekThroughOverlay(true),
                            onTapUp: (_) => _setPeekThroughOverlay(false),
                            onTapCancel: () => _setPeekThroughOverlay(false),
                            child: Tooltip(
                              message: context.tr('holdToViewCards'),
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: ZapitiColors.cardCream
                                      .withValues(alpha: 0.92),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: ZapitiColors.oldGold,
                                    width: 1,
                                  ),
                                ),
                                child: SizedBox.square(
                                  dimension: max(34.0, gap * 3.3),
                                  child: Icon(
                                    Icons.visibility_outlined,
                                    color: ZapitiColors.darkBrown,
                                    size: max(18.0, gap * 1.55),
                                  ),
                                ),
                              ),
                            ),
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
      ),
    );
  }
}

class _GameFinishedOverlay extends StatelessWidget {
  final int winningTeamId;
  final List<Player> winningPlayers;
  final int scoreTeamOne;
  final int scoreTeamTwo;
  final VoidCallback onRestart;
  final VoidCallback onExit;
  final String Function(Player) playerNameBuilder;

  const _GameFinishedOverlay({
    required this.winningTeamId,
    required this.winningPlayers,
    required this.scoreTeamOne,
    required this.scoreTeamTwo,
    required this.onRestart,
    required this.onExit,
    required this.playerNameBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final names =
        winningPlayers.map((player) => playerNameBuilder(player)).join(' y ');
    final titleStyle = Theme.of(context).textTheme.titleLarge?.copyWith(
          color: ZapitiColors.oldGold,
          fontWeight: FontWeight.w900,
        );
    final bodyStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: ZapitiColors.cardCream.withValues(alpha: 0.92),
          height: 1.25,
          fontWeight: FontWeight.w800,
        );

    return Positioned.fill(
      child: ColoredBox(
        color: Colors.black.withValues(alpha: 0.32),
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
                          color: const Color(0xDD2A170F),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: ZapitiColors.oldGold,
                            width: max(gap * 0.12, 1),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.34),
                              blurRadius: gap * 2,
                              offset: Offset(0, gap * 0.7),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              context.tr(
                                'winningTeamTitle',
                                params: {'team': winningTeamId},
                              ),
                              textAlign: TextAlign.center,
                              style: titleStyle,
                            ),
                            SizedBox(height: gap * 0.75),
                            Text(
                              names,
                              textAlign: TextAlign.center,
                              style: bodyStyle,
                            ),
                            SizedBox(height: gap * 0.75),
                            Text(
                              context.tr(
                                'finalScore',
                                params: {
                                  'teamOne': scoreTeamOne,
                                  'teamTwo': scoreTeamTwo,
                                },
                              ),
                              textAlign: TextAlign.center,
                              style: bodyStyle,
                            ),
                            SizedBox(height: gap),
                            LayoutBuilder(
                              builder: (context, buttonConstraints) {
                                final stackButtons =
                                    buttonConstraints.maxWidth < 320;
                                final exitButton = ZapitiActionButton(
                                  label: context.tr('exit'),
                                  icon: Icons.exit_to_app,
                                  onPressed: onExit,
                                );
                                final restartButton = ZapitiActionButton(
                                  label: context.tr('newMatchUpper'),
                                  icon: Icons.restart_alt,
                                  onPressed: onRestart,
                                  primary: true,
                                );
                                if (stackButtons) {
                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      exitButton,
                                      SizedBox(height: gap * 0.65),
                                      restartButton,
                                    ],
                                  );
                                }
                                return Row(
                                  children: [
                                    Expanded(child: exitButton),
                                    SizedBox(width: gap * 0.65),
                                    Expanded(child: restartButton),
                                  ],
                                );
                              },
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

class _LandscapeBottomBoard extends StatelessWidget {
  final double scale;
  final String playerName;
  final List<SpanishCard> cards;
  final bool enabled;
  final bool isCurrent;
  final int? turnSecondsRemaining;
  final String? message;
  final String? companionMessage;
  final String characterId;
  final bool signalsEnabled;
  final bool isGameFinished;
  final bool isHandFinished;
  final bool isRoundAwaitingContinue;
  final bool isWaitingHumanResponse;
  final bool isHumanTurn;
  final bool canPassHand;
  final bool canCallTruco;
  final ValueChanged<SpanishCard> onPlayCard;
  final ValueChanged<String> onSignalStart;
  final ValueChanged<String> onSignalEnd;
  final VoidCallback? onShowSignalHelp;
  final VoidCallback onAskCompanionSignal;
  final VoidCallback onPassHand;
  final VoidCallback onVoyATi;
  final VoidCallback onComeToMe;
  final VoidCallback onKill;
  final VoidCallback onCallTruco;
  final VoidCallback onContinueRound;
  final VoidCallback onNewHand;
  final VoidCallback onRestart;
  final VoidCallback? onOptions;
  final VoidCallback onBack;

  const _LandscapeBottomBoard({
    required this.scale,
    required this.playerName,
    required this.cards,
    required this.enabled,
    required this.isCurrent,
    required this.turnSecondsRemaining,
    required this.message,
    required this.companionMessage,
    required this.characterId,
    required this.signalsEnabled,
    required this.isGameFinished,
    required this.isHandFinished,
    required this.isRoundAwaitingContinue,
    required this.isWaitingHumanResponse,
    required this.isHumanTurn,
    required this.canPassHand,
    required this.canCallTruco,
    required this.onPlayCard,
    required this.onSignalStart,
    required this.onSignalEnd,
    required this.onShowSignalHelp,
    required this.onAskCompanionSignal,
    required this.onPassHand,
    required this.onVoyATi,
    required this.onComeToMe,
    required this.onKill,
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
        final gap = max(3.0, 4 * scale);
        final actionWidth = min(
          constraints.maxWidth * 0.27,
          (230 * scale).clamp(194.0, 286.0),
        );
        final historyWidth = min(
          constraints.maxWidth * 0.26,
          (238 * scale).clamp(196.0, 300.0),
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
                isHumanTurn: isHumanTurn,
                canPassHand: canPassHand,
                canCallTruco: canCallTruco,
                onAskCompanionSignal: onAskCompanionSignal,
                onPassHand: onPassHand,
                onVoyATi: onVoyATi,
                onComeToMe: onComeToMe,
                onKill: onKill,
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
                playerName: playerName,
                cards: cards,
                enabled: enabled,
                isCurrent: isCurrent,
                turnSecondsRemaining: turnSecondsRemaining,
                message: message,
                companionMessage: companionMessage,
                characterId: characterId,
                onPlayCard: onPlayCard,
              ),
            ),
            SizedBox(width: gap),
            SizedBox(
              width: historyWidth,
              child: Column(
                children: [
                  SizedBox(
                    height: (30 * scale).clamp(26.0, 38.0),
                    child: ZapitiActionButton(
                      label: context.tr('signalHelpUpper'),
                      icon: Icons.help_outline,
                      onPressed: onShowSignalHelp,
                    ),
                  ),
                  SizedBox(height: gap),
                  Expanded(
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
  final bool isHumanTurn;
  final bool canPassHand;
  final bool canCallTruco;
  final VoidCallback onAskCompanionSignal;
  final VoidCallback onPassHand;
  final VoidCallback onVoyATi;
  final VoidCallback onComeToMe;
  final VoidCallback onKill;
  final VoidCallback onCallTruco;
  final VoidCallback onContinueRound;
  final VoidCallback onNewHand;
  final VoidCallback onRestart;
  final VoidCallback? onOptions;
  final VoidCallback onBack;

  const _LandscapeActionPanel({
    required this.scale,
    required this.gap,
    required this.signalsEnabled,
    required this.isGameFinished,
    required this.isHandFinished,
    required this.isRoundAwaitingContinue,
    required this.isWaitingHumanResponse,
    required this.isHumanTurn,
    required this.canPassHand,
    required this.canCallTruco,
    required this.onAskCompanionSignal,
    required this.onPassHand,
    required this.onVoyATi,
    required this.onComeToMe,
    required this.onKill,
    required this.onCallTruco,
    required this.onContinueRound,
    required this.onNewHand,
    required this.onRestart,
    required this.onOptions,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final primaryHeight = (44 * scale).clamp(36.0, 56.0);
    final secondaryHeight = (34 * scale).clamp(30.0, 44.0);

    return Container(
      padding: EdgeInsets.all(max(3.0, 4 * scale)),
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
          SizedBox(height: primaryHeight, child: _primaryAction(context)),
          SizedBox(height: gap),
          SizedBox(
            height: secondaryHeight,
            child: Row(
              children: [
                if (canPassHand) ...[
                  Expanded(
                    child: ZapitiActionButton(
                      label: context.tr('passHandUpper'),
                      icon: Icons.swap_horiz_outlined,
                      onPressed: onPassHand,
                      primary: true,
                    ),
                  ),
                  SizedBox(width: gap),
                ],
                Expanded(
                  child: ZapitiActionButton(
                    label: context.tr('askSignalUpper'),
                    icon: Icons.visibility_outlined,
                    onPressed: signalsEnabled ? onAskCompanionSignal : null,
                  ),
                ),
                SizedBox(width: gap),
                if (isHumanTurn)
                  Expanded(
                    child: ZapitiActionButton(
                      label: context.tr('voyATiUpper'),
                      icon: Icons.record_voice_over_outlined,
                      onPressed: signalsEnabled ? onVoyATi : null,
                    ),
                  )
                else ...[
                  Expanded(
                    child: ZapitiActionButton(
                      label: context.tr('comeToMeUpper'),
                      icon: Icons.keyboard_double_arrow_down_outlined,
                      onPressed: signalsEnabled ? onComeToMe : null,
                    ),
                  ),
                  SizedBox(width: gap),
                  Expanded(
                    child: ZapitiActionButton(
                      label: context.tr('killUpper'),
                      icon: Icons.local_fire_department_outlined,
                      onPressed: signalsEnabled ? onKill : null,
                    ),
                  ),
                ],
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
                    label: context.tr('options'),
                    icon: Icons.settings_outlined,
                    onPressed: onOptions,
                    scale: scale,
                  ),
                ),
                SizedBox(width: gap),
                Expanded(
                  child: _DarkUtilityButton(
                    label: context.tr('back'),
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

  Widget _primaryAction(BuildContext context) {
    if (isGameFinished) {
      return _button(
          context.tr('newMatchUpper'), Icons.restart_alt, onRestart, true);
    }
    if (isHandFinished) {
      return _button(context.tr('newHandUpper'), Icons.add, onNewHand, true);
    }
    if (isRoundAwaitingContinue) {
      return _button(context.tr('nextRoundUpper'), Icons.arrow_forward,
          onContinueRound, true);
    }
    return _button(context.tr('callTrucoUpper'), Icons.campaign,
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
  final String playerName;
  final List<SpanishCard> cards;
  final bool enabled;
  final bool isCurrent;
  final int? turnSecondsRemaining;
  final String? message;
  final String? companionMessage;
  final String characterId;
  final ValueChanged<SpanishCard> onPlayCard;

  const _LandscapeHumanPanel({
    required this.scale,
    required this.playerName,
    required this.cards,
    required this.enabled,
    required this.isCurrent,
    required this.turnSecondsRemaining,
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
        final gap = max(5.0, 8 * scale);
        final padding = EdgeInsets.only(top: 2 * scale);
        final usableWidth = max(0.0, constraints.maxWidth - padding.horizontal);
        final usableHeight = max(0.0, constraints.maxHeight - padding.vertical);
        const overlapFactor = 0.66;
        final localFactor = usableHeight < 124 ? 0.88 : 0.96;
        final avatarWidth = (90 * scale * localFactor).clamp(62.0, 104.0);
        final avatarHeight = min(
          usableHeight,
          (144 * scale * localFactor).clamp(92.0, 160.0),
        );
        final heightBound = usableHeight * 80 / 122;
        final widthBound = max(
          0.0,
          (usableWidth - avatarWidth - gap * 2) /
              (1 + overlapFactor * (slots - 1)),
        );
        final cardWidth = min(
          (116 * scale * localFactor).clamp(78.0, 128.0),
          min(widthBound, heightBound),
        );
        final cardHeight = cardWidth * 122 / 80;
        final cardOffset = cardWidth * overlapFactor;
        final handWidth = cardWidth + cardOffset * (slots - 1);
        final rowWidth = avatarWidth + gap * 1.6 + handWidth;
        final signalText = _signalStatusText(context, companionMessage);

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
                        turnSecondsRemaining: turnSecondsRemaining,
                        playerName: playerName,
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

  String? _signalStatusText(BuildContext context, String? value) {
    if (value == null || value.isEmpty) return null;
    if (value.startsWith('Compa')) return value;
    if (value == 'Mirando...') return context.tr('companionLooking');
    if (value == 'No llevo seña.') return context.tr('companionNoSignal');
    const signalPrefix = 'SENAL: ';
    if (value.startsWith(signalPrefix)) {
      return context.tr('companionSignal',
          params: {'signal': value.substring(signalPrefix.length)});
    }
    const carriesPrefix = 'Lleva ';
    if (value.startsWith(carriesPrefix)) {
      return context
          .tr('companionSignal', params: {'signal': value.substring(6)});
    }
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
  final int? turnSecondsRemaining;
  final String playerName;
  final String? message;
  final String characterId;
  final double width;
  final double height;
  final double gap;

  const _LandscapeAvatarSlot({
    required this.isCurrent,
    required this.turnSecondsRemaining,
    required this.playerName,
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
          if (turnSecondsRemaining != null)
            Positioned(
              right: -max(4.0, gap * 0.35),
              bottom: max(4.0, gap * 0.45),
              child: _LandscapeTurnTimerBadge(
                seconds: turnSecondsRemaining!,
                gap: gap,
                scale: width / 90,
              ),
            ),
          ZapitiPlayerNameBadge(
            playerName: playerName,
            avatarWidth: width,
            gap: gap,
            compact: true,
          ),
        ],
      ),
    );
  }

  String? _signalFromMessage(String? message) {
    const prefix = 'SENAL: ';

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
      'Ases' => 0,
      'Mala' => 0.13,
      _ => 0,
    };
  }
}

class _LandscapeTurnTimerBadge extends StatelessWidget {
  final int seconds;
  final double gap;
  final double scale;

  const _LandscapeTurnTimerBadge({
    required this.seconds,
    required this.gap,
    required this.scale,
  });

  @override
  Widget build(BuildContext context) {
    final urgent = seconds <= 5;
    final fontSize = (11 * scale).clamp(9.0, 13.0);
    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: urgent
              ? ZapitiColors.wineRed.withValues(alpha: 0.94)
              : const Color(0xE62A170F),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: urgent ? ZapitiColors.oldGold : ZapitiColors.cardCream,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.30),
              blurRadius: max(4.0, gap * 0.8),
              offset: Offset(0, max(1.0, gap * 0.25)),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: max(5.0, gap * 0.75),
            vertical: max(2.5, gap * 0.35),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.timer_outlined,
                size: (fontSize + 2).clamp(11.0, 16.0),
                color: ZapitiColors.cardCream,
              ),
              SizedBox(width: max(2.0, gap * 0.28)),
              Text(
                '${seconds}s',
                style: TextStyle(
                  color: ZapitiColors.cardCream,
                  fontSize: fontSize,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SignalHelpDialog extends StatelessWidget {
  final VoidCallback onClose;

  const _SignalHelpDialog({required this.onClose});

  static const _rows = [
    _SignalHelpRowData(
      card: SpanishCard(value: 4, suit: Suit.bastos),
      labelKey: 'signalCard4Bastos',
      signal: '4 Bastos',
    ),
    _SignalHelpRowData(
      card: SpanishCard(value: 7, suit: Suit.copas),
      labelKey: 'signalCard7Copas',
      signal: '7 Copas',
    ),
    _SignalHelpRowData(
      card: SpanishCard(value: 7, suit: Suit.oros),
      labelKey: 'signalCard7Oros',
      signal: '7 Oros',
    ),
    _SignalHelpRowData(
      card: SpanishCard(value: 1, suit: Suit.espadas),
      labelKey: 'signalCardAsEspadas',
      signal: 'As Espadas',
    ),
    _SignalHelpRowData(
      card: SpanishCard(value: 3, suit: Suit.oros),
      labelKey: 'signalCardTreses',
      signal: 'Treses',
    ),
    _SignalHelpRowData(
      card: SpanishCard(value: 2, suit: Suit.oros),
      labelKey: 'signalCardDoses',
      signal: 'Doses',
    ),
    _SignalHelpRowData(
      card: SpanishCard(value: 1, suit: Suit.oros),
      labelKey: 'signalCardAses',
      signal: 'Ases',
    ),
    _SignalHelpRowData(
      card: null,
      labelKey: 'badHand',
      signal: 'Mala',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isNarrow = size.width < 560;
    final titleStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
          color: ZapitiColors.darkBrown,
          fontWeight: FontWeight.w900,
        );
    final width = min(size.width * (isNarrow ? 0.92 : 0.72), 620.0);
    final height = min(size.height * 0.86, 640.0);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.all(isNarrow ? 12 : 20),
      child: Container(
        width: width,
        height: height,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: ZapitiColors.cardCream.withValues(alpha: 0.97),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: ZapitiColors.oldGold, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.34),
              blurRadius: 22,
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
                  Icons.help_outline,
                  color: ZapitiColors.wineRed,
                ),
                const SizedBox(width: 8),
                Expanded(
                    child:
                        Text(context.tr('signalHelpTitle'), style: titleStyle)),
                IconButton(
                  tooltip: context.tr('close'),
                  onPressed: onClose,
                  icon: const Icon(Icons.close),
                  color: ZapitiColors.darkBrown,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.separated(
                itemCount: _rows.length,
                separatorBuilder: (_, __) => Divider(
                  height: 8,
                  color: ZapitiColors.darkBrown.withValues(alpha: 0.10),
                ),
                itemBuilder: (context, index) {
                  return _SignalHelpRow(row: _rows[index]);
                },
              ),
            ),
            const SizedBox(height: 8),
            ZapitiActionButton(
              label: context.tr('closeUpper'),
              icon: Icons.check,
              onPressed: onClose,
              primary: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _SignalHelpRowData {
  final SpanishCard? card;
  final String labelKey;
  final String? signal;

  const _SignalHelpRowData({
    required this.card,
    required this.labelKey,
    required this.signal,
  });
}

class _SignalHelpRow extends StatelessWidget {
  final _SignalHelpRowData row;

  const _SignalHelpRow({required this.row});

  @override
  Widget build(BuildContext context) {
    final bodyStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
          color: ZapitiColors.darkBrown,
          fontWeight: FontWeight.w800,
          height: 1.08,
        );

    return SizedBox(
      height: 92,
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: row.card == null
                ? const ZapitiCardWidget(
                    card: null,
                    hidden: true,
                    width: 24,
                    enabled: false,
                  )
                : ZapitiCardWidget(
                    card: row.card,
                    width: 24,
                    enabled: false,
                  ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 5,
            child: Text(
              context.tr(row.labelKey),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: bodyStyle,
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 138,
            height: 86,
            child: row.signal == null
                ? Center(
                    child: Text(
                      context.tr('from12To4'),
                      textAlign: TextAlign.center,
                      style: bodyStyle?.copyWith(
                        color: ZapitiColors.darkBrown.withValues(alpha: 0.62),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  )
                : ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: const Color(0x332A170F),
                        border: Border.all(
                          color: ZapitiColors.oldGold.withValues(alpha: 0.42),
                        ),
                      ),
                      child: AvatarWithSilhouette(
                        assetPath: CharacterAssets.frontForSignal(
                          'p1',
                          row.signal,
                        ),
                        width: 138,
                        height: 86,
                        mirror: row.signal == '7 Oros',
                        alignment: Alignment.topCenter,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.person,
                          color: ZapitiColors.darkBrown,
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
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
        String signal,
        String labelKey,
        SpanishCard? card,
        bool hiddenCard,
      })> _signals = [
    (
      signal: '4 Bastos',
      labelKey: 'signalCard4Bastos',
      card: SpanishCard(value: 4, suit: Suit.bastos),
      hiddenCard: false,
    ),
    (
      signal: '7 Copas',
      labelKey: 'signalCard7Copas',
      card: SpanishCard(value: 7, suit: Suit.copas),
      hiddenCard: false,
    ),
    (
      signal: '7 Oros',
      labelKey: 'signalCard7Oros',
      card: SpanishCard(value: 7, suit: Suit.oros),
      hiddenCard: false,
    ),
    (
      signal: 'As Espadas',
      labelKey: 'signalCardAsEspadas',
      card: SpanishCard(value: 1, suit: Suit.espadas),
      hiddenCard: false,
    ),
    (
      signal: 'Treses',
      labelKey: 'signalCardTreses',
      card: SpanishCard(value: 3, suit: Suit.oros),
      hiddenCard: false,
    ),
    (
      signal: 'Doses',
      labelKey: 'signalCardDoses',
      card: SpanishCard(value: 2, suit: Suit.oros),
      hiddenCard: false,
    ),
    (
      signal: 'Ases',
      labelKey: 'signalCardAses',
      card: SpanishCard(value: 1, suit: Suit.oros),
      hiddenCard: false,
    ),
    (signal: 'Mala', labelKey: 'badHand', card: null, hiddenCard: true),
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
                            label: context.tr(signal.labelKey),
                            card: signal.card,
                            hiddenCard: signal.hiddenCard,
                            enabled: enabled,
                            compact: true,
                            dense: true,
                            onStart: () => onSignalStart(signal.signal),
                            onEnd: () => onSignalEnd(signal.signal),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          }

          final panelPadding = max(2.0, 3 * scale);
          final horizontalGap = max(4.0, 5 * scale);
          final verticalGap = max(2.0, 4 * scale);
          final availableWidth =
              max(0.0, constraints.maxWidth - panelPadding * 2);
          final availableHeight =
              max(0.0, constraints.maxHeight - panelPadding * 2);
          final widthBound = max(0.0, (availableWidth - horizontalGap * 3) / 4);
          final heightBound = (availableHeight - verticalGap) / 2;
          final signalSize = min(
            widthBound,
            min(52 * scale, max(0.0, heightBound)),
          );
          final firstRow = _signals.take(4).toList();
          final secondRow = _signals.skip(4).toList();

          List<Widget> rowButtons(
            List<
                    ({
                      String signal,
                      String labelKey,
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
                    label: context.tr(signals[index].labelKey),
                    card: signals[index].card,
                    hiddenCard: signals[index].hiddenCard,
                    enabled: enabled,
                    compact: true,
                    dense: true,
                    onStart: () => onSignalStart(signals[index].signal),
                    onEnd: () => onSignalEnd(signals[index].signal),
                  ),
                ),
              ],
            ];
          }

          return Container(
            padding: EdgeInsets.all(panelPadding),
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
            child: Column(
              children: [
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: rowButtons(firstRow),
                    ),
                  ),
                ),
                SizedBox(height: verticalGap),
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: rowButtons(secondRow),
                    ),
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
              context.tr('signals'),
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
                    label: context.tr(signal.labelKey),
                    card: signal.card,
                    hiddenCard: signal.hiddenCard,
                    enabled: enabled,
                    compact: compact,
                    dense: !compact,
                    onStart: () => onSignalStart(signal.signal),
                    onEnd: () => onSignalEnd(signal.signal),
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
