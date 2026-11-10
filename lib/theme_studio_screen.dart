import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'curconv_3d.dart';
import 'settings_screen.dart';

class ThemeStudioScreen extends StatefulWidget {
  const ThemeStudioScreen({
    super.key,
    required this.initialMode,
    required this.initialKeyboardTheme,
    required this.onThemeModeChanged,
    required this.onKeyboardThemeChanged,
  });

  final ThemeMode initialMode;
  final String initialKeyboardTheme;
  final ValueChanged<ThemeMode> onThemeModeChanged;
  final ValueChanged<String> onKeyboardThemeChanged;

  @override
  State<ThemeStudioScreen> createState() => _ThemeStudioScreenState();
}

class _ThemeStudioScreenState extends State<ThemeStudioScreen> {
  late ThemeMode _mode = widget.initialMode;
  late String _keyboardTheme = widget.initialKeyboardTheme;

  Future<void> _setMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(CurConvSettings.themeModeKey,
        mode == ThemeMode.dark ? 'dark' : 'light');
    if (!mounted) return;
    setState(() => _mode = mode);
    widget.onThemeModeChanged(mode);
  }

  Future<void> _chooseKeyboardTheme() async {
    final String? selected = await Navigator.of(context).push<String>(
      MaterialPageRoute<String>(
        builder: (_) => _KeyboardColorScreen(selected: _keyboardTheme),
      ),
    );
    if (selected == null || !mounted) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(CurConvSettings.keyboardThemeKey, selected);
    if (!mounted) return;
    setState(() => _keyboardTheme = selected);
    widget.onKeyboardThemeChanged(selected);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: curconvScaffoldColor(context),
      appBar: AppBar(
        title: const Text('Theme Studio'),
        centerTitle: true,
        backgroundColor: kCurconvTeal,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        decoration: curconvBackground(context),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(14, 18, 14, 22),
            children: <Widget>[
              Curconv3DCard(
                leading: curconvIconFrame(context: context, 
                  accent: const Color(0xFFECAA00),
                  tint: const Color(0xFFFFF4D7),
                  child: const Icon(Icons.wb_sunny_rounded,
                      color: Color(0xFFECAA00), size: 30),
                ),
                title: 'Light Mode',
                subtitle: 'Use a clean and bright theme',
                accent: const Color(0xFFECAA00),
                tint: const Color(0xFFFFF4D7),
                trailing: Curconv3DSwitch(
                  value: _mode == ThemeMode.light,
                  onChanged: (value) =>
                      _setMode(value ? ThemeMode.light : ThemeMode.dark),
                ),
              ),
              const SizedBox(height: 12),
              Curconv3DCard(
                leading: curconvIconFrame(context: context, 
                  accent: const Color(0xFF34279E),
                  tint: const Color(0xFFE8E5FF),
                  child: const Icon(Icons.nightlight_round,
                      color: Color(0xFF34279E), size: 30),
                ),
                title: 'Dark Mode',
                subtitle: 'Use a dark theme for less eye strain',
                accent: const Color(0xFF34279E),
                tint: const Color(0xFFE8E5FF),
                trailing: Curconv3DSwitch(
                  value: _mode == ThemeMode.dark,
                  onChanged: (value) =>
                      _setMode(value ? ThemeMode.dark : ThemeMode.light),
                ),
              ),
              const SizedBox(height: 12),
              Curconv3DCard(
                leading: curconvIconFrame(context: context, 
                  accent: const Color(0xFF008F7A),
                  tint: const Color(0xFFDDF7F2),
                  child: const Icon(Icons.keyboard,
                      color: Color(0xFF008F7A), size: 30),
                ),
                title: 'Keyboard Color',
                subtitle: 'Choose your preferred keyboard color',
                accent: const Color(0xFF008F7A),
                tint: const Color(0xFFDDF7F2),
                onTap: _chooseKeyboardTheme,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _KeyboardColorScreen extends StatelessWidget {
  const _KeyboardColorScreen({required this.selected});
  final String selected;

  static const Map<String, Color> _colors = <String, Color>{
    'classic': Color(0xFFEBAE70),
    'ocean': Color(0xFF4787D1),
    'teal': Color(0xFF26A690),
    'sunset': Color(0xFFFD9522),
    'skyPurple': Color(0xFF8956FC),
    'oxblood': Color(0xFF650500),
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: curconvScaffoldColor(context),
      appBar: AppBar(
        title: const Text('Keyboard Color'),
        centerTitle: true,
        backgroundColor: kCurconvTeal,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        decoration: curconvBackground(context),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(14, 18, 14, 22),
            children: CurConvSettings.keyboardThemeNames.entries.map((item) {
              final Color color = _colors[item.key] ?? Colors.teal;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Curconv3DCard(
                  leading: curconvIconFrame(context: context, 
                    accent: color,
                    tint: Colors.white,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  title: item.value,
                  accent: kCurconvTeal,
                  tint: const Color(0xFFDDF7F2),
                  trailing: selected == item.key
                      ? const Icon(Icons.check_circle, color: kCurconvTeal)
                      : null,
                  onTap: () => Navigator.of(context).pop(item.key),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
