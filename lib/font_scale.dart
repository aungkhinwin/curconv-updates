import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String fontScaleKey = 'curconv_font_scale';
const double kDefaultFontScale = 1.0;

class FontScaleOption {
  const FontScaleOption(this.label, this.scale);
  final String label;
  final double scale;
}

const List<FontScaleOption> kFontScaleOptions = <FontScaleOption>[
  FontScaleOption('အလွန်သေး', 0.7),
  FontScaleOption('သေး', 0.8),
  FontScaleOption('နည်းနည်းသေး', 0.9),
  FontScaleOption('ပုံမှန်', 1.0),
  FontScaleOption('ကြီး', 1.1),
  FontScaleOption('အလွန်ကြီး', 1.2),
];

/// Current text scale for the whole app. MaterialApp listens to this.
final ValueNotifier<double> curconvFontScale =
    ValueNotifier<double>(kDefaultFontScale);

int _optionIndex(double scale) {
  final int i = kFontScaleOptions
      .indexWhere((FontScaleOption o) => (o.scale - scale).abs() < 0.001);
  return i < 0 ? 1 : i;
}

/// Loads the saved font scale (default 100%). Safe to call without awaiting.
Future<void> loadFontScale() async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  final double saved = prefs.getDouble(fontScaleKey) ?? kDefaultFontScale;
  curconvFontScale.value = kFontScaleOptions[_optionIndex(saved)].scale;
}

Future<void> saveFontScale(double scale) async {
  curconvFontScale.value = scale;
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.setDouble(fontScaleKey, scale);
}

class FontSizeScreen extends StatefulWidget {
  const FontSizeScreen({super.key});

  @override
  State<FontSizeScreen> createState() => _FontSizeScreenState();
}

class _FontSizeScreenState extends State<FontSizeScreen> {
  late double _index;

  @override
  void initState() {
    super.initState();
    _index = _optionIndex(curconvFontScale.value).toDouble();
  }

  double get _scale => kFontScaleOptions[_index.round()].scale;

  @override
  Widget build(BuildContext context) {
    final String pct = '${(_scale * 100).round()}%';
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Font Size'),
        backgroundColor: const Color(0xFF00796B),
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text(
                    'Font Size',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text('လက်ရှိ: ${kFontScaleOptions[_index.round()].label} ($pct)'),
                  Slider(
                    min: 0,
                    max: (kFontScaleOptions.length - 1).toDouble(),
                    divisions: kFontScaleOptions.length - 1,
                    value: _index,
                    activeColor: const Color(0xFF00796B),
                    onChanged: (double v) => setState(() => _index = v),
                    onChangeEnd: (double v) =>
                        saveFontScale(kFontScaleOptions[v.round()].scale),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      for (final FontScaleOption o in kFontScaleOptions)
                        Text(
                          '${(o.scale * 100).round()}%',
                          style: const TextStyle(fontSize: 11),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: TextScaler.linear(_scale),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const <Widget>[
                    Text('Preview', style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    Text('ဒီစာသားက ရွေးထားတဲ့ အရွယ်အစားနဲ့ ပြပါမယ်။'),
                    SizedBox(height: 4),
                    Text('¥ 5700 元 → 1,234,567 Ks'),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () {
              setState(() => _index = _optionIndex(kDefaultFontScale).toDouble());
              saveFontScale(kDefaultFontScale);
            },
            icon: const Icon(Icons.restart_alt_rounded),
            label: const Text('Reset to Default (100%)'),
          ),
        ],
      ),
    );
  }
}
