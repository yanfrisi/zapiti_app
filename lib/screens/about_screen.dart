import 'dart:math';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/app_info.dart';
import '../l10n/zapiti_localizations.dart';
import '../services/account_privacy_service.dart';
import '../theme/zapiti_theme.dart';
import '../widgets/zapiti_action_button.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  Future<void> _openLink(BuildContext context, String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    final opened = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('linkOpenError'))),
      );
    }
  }

  void _openPrivacyPolicy(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _LegalTextScreen(
          title: context.tr('privacyPolicyTitle'),
          body: [
            for (var index = 1; index <= 6; index++)
              context.tr('privacyPolicyBody$index'),
          ],
        ),
      ),
    );
  }

  void _openAccountDeletion(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _AccountDeletionScreen(onOpenLink: _openLink),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final titleStyle = Theme.of(context).textTheme.headlineSmall?.copyWith(
          color: ZapitiColors.oldGold,
          fontWeight: FontWeight.w900,
        );
    final subtitleStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
          color: ZapitiColors.cardCream,
          fontWeight: FontWeight.w800,
        );
    final bodyStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: ZapitiColors.cardCream.withValues(alpha: 0.88),
          height: 1.25,
          fontWeight: FontWeight.w700,
        );

    return Scaffold(
      backgroundColor: ZapitiColors.woodDark,
      body: SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                ZapitiColors.woodDark,
                ZapitiColors.wood,
                ZapitiColors.woodDark,
              ],
              stops: [0, 0.55, 1],
            ),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final inset = min(18.0, constraints.maxWidth * 0.04);
              return SingleChildScrollView(
                padding: EdgeInsets.all(inset),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight - inset * 2,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 720),
                      child: Container(
                        padding: EdgeInsets.all(
                          min(22.0, constraints.maxWidth * 0.05),
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.38),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: ZapitiColors.oldGold,
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.28),
                              blurRadius: 18,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: FutureBuilder<String>(
                          future: AppInfo.versionLabel(),
                          builder: (context, snapshot) {
                            final version =
                                snapshot.data ?? context.tr('versionLoading');
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  AppInfo.appName,
                                  textAlign: TextAlign.center,
                                  style: titleStyle,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  version,
                                  textAlign: TextAlign.center,
                                  style: subtitleStyle,
                                ),
                                const SizedBox(height: 12),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: ZapitiActionButton(
                                    label: context.tr('back'),
                                    icon: Icons.arrow_back,
                                    onPressed: () => Navigator.of(context).pop(),
                                  ),
                                ),
                                const SizedBox(height: 18),
                                AboutInfoSection(
                                  title: context.tr('aboutAuthor'),
                                  children: [
                                    Text(
                                      'Juan Francisco Gutiérrez Vázquez',
                                      style: bodyStyle,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                AboutInfoSection(
                                  title: context.tr('aboutTesting'),
                                  children: [
                                    Text(
                                      'Juan Francisco Gutiérrez Vázquez',
                                      style: bodyStyle,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Miguel Mateos Borrego',
                                      style: bodyStyle,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Tabares',
                                      style: bodyStyle,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                AboutInfoSection(
                                  title: context.tr('aboutThanks'),
                                  children: [
                                    Text(
                                      context.tr('aboutThanksText'),
                                      style: bodyStyle,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                AboutInfoSection(
                                  title: context.tr('aboutAuthorLinks'),
                                  children: [
                                    Wrap(
                                      spacing: 10,
                                      runSpacing: 10,
                                      children: [
                                        _AboutLinkButton(
                                          label: 'Instagram',
                                          icon: Icons.camera_alt_outlined,
                                          onPressed: () => _openLink(
                                            context,
                                            AppLinks.instagram,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                AboutInfoSection(
                                  title: context.tr('privacyAccountSection'),
                                  children: [
                                    Wrap(
                                      spacing: 10,
                                      runSpacing: 10,
                                      children: [
                                        _AboutLinkButton(
                                          label:
                                              context.tr('privacyPolicyTitle'),
                                          icon: Icons.privacy_tip_outlined,
                                          onPressed: () =>
                                              _openPrivacyPolicy(context),
                                        ),
                                        _AboutLinkButton(
                                          label:
                                              context.tr('deleteAccountTitle'),
                                          icon: Icons.delete_outline,
                                          onPressed: () =>
                                              _openAccountDeletion(context),
                                        ),
                                        _AboutLinkButton(
                                          label:
                                              context.tr('webPrivacyButton'),
                                          icon: Icons.open_in_new,
                                          onPressed: () => _openLink(
                                            context,
                                            AppLinks.privacyPolicy,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            );
                          },
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

class _LegalTextScreen extends StatelessWidget {
  final String title;
  final List<String> body;
  final Widget? footer;

  const _LegalTextScreen({
    required this.title,
    required this.body,
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    final bodyStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: ZapitiColors.cardCream.withValues(alpha: 0.9),
          height: 1.32,
          fontWeight: FontWeight.w700,
        );

    return Scaffold(
      backgroundColor: ZapitiColors.woodDark,
      body: SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                ZapitiColors.woodDark,
                ZapitiColors.wood,
                ZapitiColors.woodDark,
              ],
              stops: [0, 0.55, 1],
            ),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final inset = min(18.0, constraints.maxWidth * 0.04);
              return SingleChildScrollView(
                padding: EdgeInsets.all(inset),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 760),
                    child: AboutInfoSection(
                      title: title,
                      children: [
                        for (final paragraph in body) ...[
                          Text(paragraph, style: bodyStyle),
                          const SizedBox(height: 10),
                        ],
                        if (footer != null)
                          footer!
                        else
                          Align(
                            alignment: Alignment.centerRight,
                            child: ZapitiActionButton(
                              label: context.tr('back'),
                              icon: Icons.arrow_back,
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                          ),
                      ],
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

class _AccountDeletionScreen extends StatefulWidget {
  final Future<void> Function(BuildContext context, String url) onOpenLink;

  const _AccountDeletionScreen({required this.onOpenLink});

  @override
  State<_AccountDeletionScreen> createState() => _AccountDeletionScreenState();
}

class _AccountDeletionScreenState extends State<_AccountDeletionScreen> {
  bool _clearing = false;

  Future<void> _clearLocalProfile() async {
    setState(() {
      _clearing = true;
    });
    await AccountPrivacyService.clearLocalMultiplayerProfile();
    if (!mounted) return;
    setState(() {
      _clearing = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Datos multijugador eliminados de este dispositivo.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _LegalTextScreen(
      title: 'Eliminar cuenta',
      body: const [
        'Desde aquí puedes iniciar la eliminación de tu cuenta multijugador de Zapiti.',
        'La solicitud debe eliminar usuario, nombre de jugador, credenciales, sesión y datos personales asociados al perfil online.',
        'El historial de partidas puede conservarse de forma anónima para mantener resultados y ranking sin identificarte.',
        'También puedes borrar de este dispositivo los datos locales de acceso al multijugador.',
      ],
      footer: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _AboutLinkButton(
                label: 'Abrir solicitud web',
                icon: Icons.open_in_new,
                onPressed: () => widget.onOpenLink(
                  context,
                  AppLinks.accountDeletion,
                ),
              ),
              _AboutLinkButton(
                label: _clearing ? 'Borrando...' : 'Borrar datos locales',
                icon: Icons.delete_sweep_outlined,
                onPressed: _clearing ? null : _clearLocalProfile,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: ZapitiActionButton(
              label: context.tr('back'),
              icon: Icons.arrow_back,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ],
      ),
    );
  }
}

class AboutInfoSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const AboutInfoSection({
    super.key,
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ZapitiColors.tableGreen.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: ZapitiColors.oldGold.withValues(alpha: 0.34),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: ZapitiColors.oldGold,
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }
}

class _AboutLinkButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;

  const _AboutLinkButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: ZapitiColors.cardCream,
        backgroundColor: ZapitiColors.darkBrown.withValues(alpha: 0.34),
        side: BorderSide(
          color: ZapitiColors.oldGold.withValues(alpha: 0.7),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }
}
