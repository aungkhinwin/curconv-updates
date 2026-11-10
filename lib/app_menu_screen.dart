import 'package:flutter/material.dart';

import 'app_version.dart';
import 'curconv_3d.dart';

enum AppMenuAction { account, payment, themes, settings, about }

class AppMenuScreen extends StatelessWidget {
  const AppMenuScreen({super.key, required this.onAction});

  final ValueChanged<AppMenuAction> onAction;

  static const List<_MenuItem> _items = <_MenuItem>[
    _MenuItem(
      AppMenuAction.account,
      Icons.account_circle_rounded,
      'Account',
      Color(0xFF3F51E8),
      Color(0xFFE3E8FF),
    ),
    _MenuItem(
      AppMenuAction.payment,
      Icons.receipt_long_rounded,
      'ငွေပေးချေ / သက်တမ်းတိုး',
      Color(0xFF008F84),
      Color(0xFFDAF8F0),
    ),
    _MenuItem(
      AppMenuAction.themes,
      Icons.palette_rounded,
      'Theme Studio',
      Color(0xFF8151E8),
      Color(0xFFF0E6FF),
    ),
    _MenuItem(
      AppMenuAction.settings,
      Icons.settings_rounded,
      'Settings',
      Color(0xFF008F84),
      Color(0xFFDAF8F0),
    ),
    _MenuItem(
      AppMenuAction.about,
      Icons.auto_awesome_rounded,
      'About App',
      Color(0xFFEF9C27),
      Color(0xFFFFF0D4),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: curconvScaffoldColor(context),
      appBar: AppBar(
        backgroundColor: const Color(0xFF00796B),
        foregroundColor: Colors.white,
        title: const Text('Menu'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Container(
        decoration: curconvBackground(context),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 22, 18, 28),
            children: <Widget>[
              Padding(
                padding: EdgeInsets.fromLTRB(6, 0, 6, 16),
                child: Text(
                  'Choose what you would like to do',
                  style: TextStyle(
                    color: curconvSubtitleColor(context),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              for (final _MenuItem item in _items) ...<Widget>[
                _RaisedMenuCard(
                  item: item,
                  onTap: () => onAction(item.action),
                  version: item.action == AppMenuAction.about
                      ? 'Version $curconvAppVersion'
                      : null,
                ),
                const SizedBox(height: 15),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuItem {
  const _MenuItem(this.action, this.icon, this.title, this.accent, this.tint);
  final AppMenuAction action;
  final IconData icon;
  final String title;
  final Color accent;
  final Color tint;
}

class _RaisedMenuCard extends StatelessWidget {
  const _RaisedMenuCard({
    required this.item,
    required this.onTap,
    this.version,
  });

  final _MenuItem item;
  final VoidCallback onTap;
  final String? version;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            color: curconvCardColor(context),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
                color: curconvBorderColor(context, item.accent, item.tint), width: 1.4),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: item.accent.withValues(alpha: 0.14),
                blurRadius: 18,
                offset: const Offset(0, 9),
              ),
              const BoxShadow(
                color: Color(0xFFFFFFFF),
                blurRadius: 1,
                offset: Offset(-2, -2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 10),
            child: Row(
              children: <Widget>[
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: <Color>[curconvCardColor(context), item.tint],
                    ),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: item.accent.withValues(alpha: 0.24),
                        blurRadius: 9,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(item.icon, size: 30, color: item.accent),
                ),
                const SizedBox(width: 17),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        item.title,
                        style: TextStyle(
                          color: curconvTitleColor(context),
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (version != null) ...<Widget>[
                        const SizedBox(height: 4),
                        Text(
                          version!,
                          style: TextStyle(
                            color: item.accent,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: item.tint,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.arrow_forward_rounded,
                      color: item.accent, size: 20),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
