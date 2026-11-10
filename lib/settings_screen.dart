import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'font_scale.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'backup_screen.dart';
import 'customer_notice.dart';
import 'curconv_3d.dart';

class CurConvSettings {
  static const String currencyPairKey = 'curconv_currency_pair';
  static const String defaultCurrencyPair = 'cny_mmk';
  static const List<String> currencyPairIds = <String>[
    'cny_mmk',
    'myr_mmk',
    'thb_mmk',
  ];

  static String currencyName(String pair) => switch (pair) {
        'myr_mmk' => 'ရင်းဂစ်',
        'thb_mmk' => 'ဘတ်',
        _ => 'တရုတ်ယွမ်',
      };

  static String currencyShortName(String pair) => switch (pair) {
        'myr_mmk' => 'MYR',
        'thb_mmk' => 'THB',
        _ => 'CNY',
      };

  static String currencySymbol(String pair) => switch (pair) {
        'myr_mmk' => 'RM',
        'thb_mmk' => '฿',
        _ => '¥',
      };

  static String currencyUnit(String pair) => pair == 'cny_mmk' ? ' 元' : '';

  static String currencyFlag(String pair) => switch (pair) {
        'myr_mmk' => '🇲🇾',
        'thb_mmk' => '🇹🇭',
        _ => '🇨🇳',
      };

  static String currencyAmount(String amount, String pair) =>
      '${currencySymbol(pair)} $amount${currencyUnit(pair)}';

  static String customerRateKey(String pair) =>
      pair == 'cny_mmk' ? 'yuan_rate' : 'curconv_${pair}_customer_rate';
  static String reverseRateKey(String pair) => pair == 'cny_mmk'
      ? 'mmk_to_cny_yuan_rate'
      : 'curconv_${pair}_reverse_rate';
  static String traderRateKey(String pair) =>
      pair == 'cny_mmk' ? 'trader_rate' : 'curconv_${pair}_trader_rate';
  static String merchantRateKey(String pair) =>
      pair == 'cny_mmk' ? 'merchant_rate' : 'curconv_${pair}_merchant_rate';

  static const String letterKeyboardEnabledKey =
      'curconv_letter_keyboard_enabled';
  static const String keyboardThemeKey = 'curconv_keyboard_theme';
  static const String themeModeKey = 'curconv_theme_mode';
  static const String keySoundEnabledKey = 'curconv_key_sound_enabled';
  static const String hapticEnabledKey = 'curconv_haptic_enabled';
  static const String thousandSeparatorEnabledKey =
      'curconv_thousand_separator_enabled';
  static const String roundPrecisionEnabledKey =
      'curconv_round_precision_enabled';
  static const String roundPrecisionDigitsKey = 'curconv_round_precision_digits';
  static const String orangePanelsEnabledKey = 'curconv_orange_panels_enabled';
  static const String reductionAmountKey = 'curconv_reduction_amount';
  static const String yuanTotalLabelKey = 'merchant_yuan_total_label';
  static const String kyatTotalLabelKey = 'merchant_kyat_total_label';
  static const String receivedTotalLabelKey = 'merchant_received_total_label';
  static const String balanceTotalLabelKey = 'merchant_balance_total_label';
  static const String ledgerTitleKey = 'merchant_ledger_title';

  static const bool defaultLetterKeyboardEnabled = false;
  static const String defaultKeyboardTheme = 'classic';
  static const Map<String, String> keyboardThemeNames = <String, String>{
    'classic': 'မူလရွှေရောင်',
    'ocean': 'အပြာရောင်',
    'teal': 'စိမ်းပြာရောင်',
    'sunset': 'ရွှေဝါ လိမ္မော်',
    'skyPurple': 'အပြာ ခရမ်း',
    'oxblood': 'နီညို',
  };
  static const String defaultThemeMode = 'light';
  static const bool defaultKeySoundEnabled = false;
  static const bool defaultHapticEnabled = false;
  static const bool defaultThousandSeparatorEnabled = false;
  static const bool defaultRoundPrecisionEnabled = false;
  static const int defaultRoundPrecisionDigits = 2;
  static const bool defaultOrangePanelsEnabled = true;
  static const int defaultReductionAmount = 1;
  static const String defaultYuanTotalLabel = 'ယွမ် စုစုပေါင်း';
  static const String defaultKyatTotalLabel = 'ကျပ်ငွေ စုစုပေါင်း';
  static const String defaultReceivedTotalLabel = 'လက်ခံရရှိငွေ';
  static const String defaultBalanceTotalLabel = 'လက်ကျန်ငွေ';
  static const String defaultLedgerTitle = 'Merchant စာရင်း';

  static const Map<String, String> defaultLabels = <String, String>{
    yuanTotalLabelKey: defaultYuanTotalLabel,
    kyatTotalLabelKey: defaultKyatTotalLabel,
    receivedTotalLabelKey: defaultReceivedTotalLabel,
    balanceTotalLabelKey: defaultBalanceTotalLabel,
    ledgerTitleKey: defaultLedgerTitle,
  };

  static String formatDisplayNumber(
    num value, {
    required bool thousandSeparator,
    required int roundPrecision,
  }) {
    double amount = value.toDouble();
    if (!amount.isFinite) return '0';
    final int digits =
        roundPrecision < 0 ? 0 : (roundPrecision > 5 ? 5 : roundPrecision);
    final double trimmed = double.parse(amount.toStringAsFixed(digits));
    final bool whole = (trimmed - trimmed.roundToDouble()).abs() < 0.000001;
    final List<String> parts =
        (whole ? trimmed.toStringAsFixed(0) : trimmed.toStringAsFixed(digits))
            .split('.');
    if (thousandSeparator) {
      parts[0] = parts[0].replaceAllMapped(
        RegExp(r'\B(?=(\d{3})+(?!\d))'),
        (_) => ',',
      );
    }
    return parts.join('.');
  }

  static void playKeyFeedback({
    required bool soundEnabled,
    required bool hapticEnabled,
  }) {
    if (soundEnabled) unawaited(SystemSound.play(SystemSoundType.click));
    if (hapticEnabled) unawaited(HapticFeedback.selectionClick());
  }
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen(
      {super.key, this.onThemeModeChanged, this.showNotices = false});
  final ValueChanged<ThemeMode>? onThemeModeChanged;
  final bool showNotices;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _letterKeyboardEnabled = CurConvSettings.defaultLetterKeyboardEnabled;
  bool _keySoundEnabled = CurConvSettings.defaultKeySoundEnabled;
  bool _hapticEnabled = CurConvSettings.defaultHapticEnabled;
  bool _thousandSeparator = CurConvSettings.defaultThousandSeparatorEnabled;
  int _roundPrecision = CurConvSettings.defaultRoundPrecisionDigits;
  bool _loading = true;
  String? _errorMessage;
  String _autoBackupStatus = 'Cloud Backup အခြေအနေ မသိရသေးပါ';
  String _currencyPair = CurConvSettings.defaultCurrencyPair;
  Future<void> _saveQueue = Future<void>.value();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? backupStatus = prefs.getString('auto_backup_last_status');
    final String? backupAttempt = prefs.getString('auto_backup_last_attempt');
    final DateTime? backupTime = backupAttempt == null
        ? null
        : DateTime.tryParse(backupAttempt)?.toLocal();
    final String backupTimeText = backupTime == null
        ? ''
        : ' (${backupTime.year}/${backupTime.month.toString().padLeft(2, '0')}/${backupTime.day.toString().padLeft(2, '0')} '
            '${backupTime.hour.toString().padLeft(2, '0')}:${backupTime.minute.toString().padLeft(2, '0')})';
    if (!mounted) return;
    setState(() {
      _letterKeyboardEnabled =
          prefs.getBool(CurConvSettings.letterKeyboardEnabledKey) ??
              CurConvSettings.defaultLetterKeyboardEnabled;
      _keySoundEnabled = prefs.getBool(CurConvSettings.keySoundEnabledKey) ??
          CurConvSettings.defaultKeySoundEnabled;
      _hapticEnabled = prefs.getBool(CurConvSettings.hapticEnabledKey) ??
          CurConvSettings.defaultHapticEnabled;
      _thousandSeparator =
          prefs.getBool(CurConvSettings.thousandSeparatorEnabledKey) ??
              CurConvSettings.defaultThousandSeparatorEnabled;
      _roundPrecision =
          prefs.getInt(CurConvSettings.roundPrecisionDigitsKey) ?? CurConvSettings.defaultRoundPrecisionDigits;
      final String? savedPair =
          prefs.getString(CurConvSettings.currencyPairKey);
      _currencyPair = CurConvSettings.currencyPairIds.contains(savedPair)
          ? savedPair!
          : CurConvSettings.defaultCurrencyPair;
      _autoBackupStatus = switch (backupStatus) {
        'success' => 'နောက်ဆုံး Auto Backup အောင်မြင်ပါသည်$backupTimeText',
        'no_account' => 'အကောင့်မဝင်ထားသဖြင့် Auto Backup မလုပ်နိုင်ပါ$backupTimeText',
        'unverified' => 'Email အတည်မပြုရသေးသဖြင့် Auto Backup မလုပ်နိုင်ပါ$backupTimeText',
        'too_large' => 'ဒေတာ 900 KB ကျော်သဖြင့် Auto Backup မလုပ်နိုင်ပါ$backupTimeText',
        'unchanged' => 'ဒေတာအသစ်မရှိပါ။ Cloud Backup ကို ထပ်မတင်ပါ$backupTimeText',
        'empty' => 'သိမ်းရန် မှတ်တမ်းမရှိပါ$backupTimeText',
        String status when status.startsWith('schedule_failed') =>
          'နောက်ခံ Auto Backup စီစဉ်မှု မအောင်မြင်ပါ။ App ကို ပြန်ဖွင့်ပြီး စစ်ဆေးပါ',
        final String? status when status != null && status.startsWith('failed:') =>
          'Auto Backup မအောင်မြင်ပါ။ နောက်တစ်ကြိမ် ပြန်ကြိုးစားပါမည်$backupTimeText',
        _ => 'App ကို နောက်ခံတွင် မိနစ် 30 ထားပါက အင်တာနက်ရှိပြီး ဘက်ထရီနည်းမနေချိန်တွင် Auto Backup လုပ်ပါမည်',
      };
      _loading = false;
    });
  }

  void _queueSave() {
    _saveQueue = _saveQueue.then((_) => _persistSettings());
  }

  Future<void> _persistSettings() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool(
          CurConvSettings.letterKeyboardEnabledKey, _letterKeyboardEnabled);
      await prefs.setBool(CurConvSettings.keySoundEnabledKey, _keySoundEnabled);
      await prefs.setBool(CurConvSettings.hapticEnabledKey, _hapticEnabled);
      await prefs.setBool(
          CurConvSettings.thousandSeparatorEnabledKey, _thousandSeparator);
      await prefs.setInt(CurConvSettings.roundPrecisionDigitsKey, _roundPrecision);
      await prefs.setString(CurConvSettings.currencyPairKey, _currencyPair);
      if (!mounted) return;
      setState(() => _errorMessage = null);
    } catch (_) {
      if (!mounted) return;
      setState(
          () => _errorMessage = 'ဆက်တင်ကို သိမ်းဆည်း၍ မရပါ။ ထပ်မံကြိုးစားပါ။');
    }
  }

  void _selectCurrencyPair(String? value) {
    if (value == null || value == _currencyPair) return;
    setState(() => _currencyPair = value);
    _queueSave();
  }

  Widget _precisionRow() => Curconv3DTile(
        leading: const Icon(Icons.rounded_corner, color: kCurconvTeal, size: 28),
        title: const Text('Round up the precision',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
        subtitle: const Text('ဒဿမနေရာ ရွေးချယ်ရန်', style: TextStyle(fontSize: 16)),
        accent: kCurconvTeal,
        tint: const Color(0xFFDDF7F2),
        trailing: Text('$_roundPrecision',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        onTap: _showPrecisionDialog,
      );

  Future<void> _showPrecisionDialog() async {
    final int current = _roundPrecision;
    final int? picked = await showDialog<int>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('Number of decimal places'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            for (final int n in <int>[0, 1, 2, 3, 4, 5])
              ListTile(
                dense: true,
                leading: Radio<int>(
                  value: n,
                  groupValue: current,
                  activeColor: kCurconvTeal,
                  onChanged: (int? v) => Navigator.of(dialogContext).pop(v),
                ),
                title: Text(
                  '$n',
                  style: TextStyle(
                    color: current == n ? kCurconvTeal : null,
                    fontWeight: current == n ? FontWeight.bold : null,
                  ),
                ),
                onTap: () => Navigator.of(dialogContext).pop(n),
              ),
          ],
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('CANCEL'),
          ),
        ],
      ),
    );
    if (picked == null || !mounted) return;
    setState(() => _roundPrecision = picked);
    _queueSave();
  }

  Widget _currencyAdjustmentRow() => Curconv3DTile(
        leading: const Icon(Icons.tune_rounded, color: Color(0xFF008577), size: 28),
        title: const Text('Currency Adjustment',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
        subtitle: const Text('Orange Panels နှင့် Reduction Amount',
            style: TextStyle(fontSize: 16)),
        accent: const Color(0xFF008577),
        tint: const Color(0xFFE3FAF5),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (BuildContext _) => const CurrencyAdjustmentScreen(),
          ),
        ),
      );

  Widget _switchRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) =>
      Curconv3DTile(
        leading: Icon(icon, color: kCurconvTeal, size: 28),
        title: Text(title,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 16)),
        accent: kCurconvTeal,
        tint: const Color(0xFFDDF7F2),
        trailing: Curconv3DSwitch(value: value, onChanged: onChanged),
        onTap: () => onChanged(!value),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: const Color(0xFF00796B),
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: ListView(
                padding: EdgeInsets.all(
                  MediaQuery.sizeOf(context).width < 400 ? 12 : 16,
                ),
                children: [
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.text_fields_rounded,
                          color: Color(0xFF00796B), size: 30),
                      title: const Text('Font Size',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: ValueListenableBuilder<double>(
                        valueListenable: curconvFontScale,
                        builder: (BuildContext _, double scale, Widget? __) =>
                            Text(
                                '${(scale * 100).round()}%'),
                      ),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                            builder: (_) => const FontSizeScreen()),
                      ),
                    ),
                  ),
                  SizedBox(height: MediaQuery.sizeOf(context).width < 400 ? 8 : 12),
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.cloud_outlined,
                          color: Color(0xFF00796B), size: 32),
                      title: const Text('Cloud Backup',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(
                          'မှတ်တမ်းများကို Cloud သို့ သိမ်း/ပြန်ယူမည်\n$_autoBackupStatus'),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () async {
                        final bool? restored =
                            await Navigator.of(context).push<bool>(
                          MaterialPageRoute<bool>(
                              builder: (_) => const BackupScreen()),
                        );
                        if (!mounted || restored != true) return;
                        await _loadSettings();
                      },
                      ),
                  ),
                  SizedBox(height: MediaQuery.sizeOf(context).width < 400 ? 8 : 12),
                  Curconv3DTile(
                    accent: kCurconvTeal,
                    tint: const Color(0xFFDDF7F2),
                      leading: const Icon(Icons.language_rounded,
                          color: Color(0xFF00796B), size: 30),
                      title: const Text('Currency Pair',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(_currencyPairLabel(_currencyPair)),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () async {
                        final String? selected =
                            await Navigator.of(context).push<String>(
                          MaterialPageRoute<String>(
                            builder: (_) => CurrencyPairScreen(
                              selectedPair: _currencyPair,
                            ),
                          ),
                        );
                        if (mounted) _selectCurrencyPair(selected);
                      },
                    ),
                  if (widget.showNotices) ...[
                    SizedBox(height: MediaQuery.sizeOf(context).width < 400 ? 8 : 12),
                    const CustomerNotice(),
                  ],
                  SizedBox(height: MediaQuery.sizeOf(context).width < 400 ? 8 : 12),
                  Column(
                      children: [
                        _switchRow(
                          icon: Icons.keyboard_alt_outlined,
                          title: 'A-Z Keyboard',
                          subtitle:
                              'Send ကိုနှိပ်တဲ့အခါ စာလုံးကီးဘုတ်ကို ပြရန်',
                          value: _letterKeyboardEnabled,
                          onChanged: (value) {
                            setState(() => _letterKeyboardEnabled = value);
                            _queueSave();
                          },
                        ),
                        SizedBox(height: MediaQuery.sizeOf(context).width < 400 ? 8 : 12),
                        _switchRow(
                          icon: Icons.volume_up_outlined,
                          title: 'Sound',
                          subtitle: 'ဂဏန်းခလုတ်နှိပ်သည့်အခါ အသံဖွင့်ရန်',
                          value: _keySoundEnabled,
                          onChanged: (value) {
                            setState(() => _keySoundEnabled = value);
                            _queueSave();
                          },
                        ),
                        SizedBox(height: MediaQuery.sizeOf(context).width < 400 ? 8 : 12),
                        _switchRow(
                          icon: Icons.vibration,
                          title: 'Haptic Feedback',
                          subtitle: 'ဂဏန်းခလုတ်နှိပ်သည့်အခါ တုန်ခါရန်',
                          value: _hapticEnabled,
                          onChanged: (value) {
                            setState(() => _hapticEnabled = value);
                            _queueSave();
                          },
                        ),
                      ],
                    ),
                  SizedBox(height: MediaQuery.sizeOf(context).width < 400 ? 8 : 12),
                  Column(
                      children: [
                        _switchRow(
                          icon: Icons.numbers_rounded,
                          title: 'Thousand Separator',
                          subtitle: 'ဂဏန်းများတွင် ထောင်ဂဏန်း ကော်မာ (,) ပြရန်',
                          value: _thousandSeparator,
                          onChanged: (value) {
                            setState(() => _thousandSeparator = value);
                            _queueSave();
                          },
                        ),
                        SizedBox(height: MediaQuery.sizeOf(context).width < 400 ? 8 : 12),
                        _precisionRow(),
                        SizedBox(height: MediaQuery.sizeOf(context).width < 400 ? 8 : 12),
                        _currencyAdjustmentRow(),
                      ],
                    ),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 8),
                    Text(_errorMessage!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red)),
                  ],
                ],
              ),
            ),
    );
  }
}

String _currencyPairLabel(String pair) => switch (pair) {
      'myr_mmk' => 'မလေး ⇌ မြန်မာ (MYR/MMK)',
      'thb_mmk' => 'ထိုင်း ⇌ မြန်မာ (THB/MMK)',
      _ => 'တရုတ် ⇌ မြန်မာ (CNY/MMK)',
    };

class CurrencyPairScreen extends StatelessWidget {
  const CurrencyPairScreen({super.key, required this.selectedPair});

  final String selectedPair;

  static const List<String> _order = <String>['cny_mmk', 'myr_mmk', 'thb_mmk'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: curconvScaffoldColor(context),
      appBar: AppBar(
        title: const Text('Currency Pair'),
        backgroundColor: kCurconvTeal,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      body: Container(
        decoration: curconvBackground(context),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(14, 18, 14, 22),
            children: _order.map((pair) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Curconv3DCard(
                  leading: curconvIconFrame(context: context, 
                    accent: kCurconvTeal,
                    tint: const Color(0xFFDDF7F2),
                    child: Text(
                      CurConvSettings.currencyFlag(pair),
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                  title: _currencyPairLabel(pair),
                  accent: kCurconvTeal,
                  tint: const Color(0xFFDDF7F2),
                  trailing: Curconv3DSwitch(
                    value: selectedPair == pair,
                    onChanged: (value) {
                      if (value) Navigator.of(context).pop(pair);
                    },
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

/// Currency Adjustment page: Orange Panels switch and Reduction Amount.
class CurrencyAdjustmentScreen extends StatefulWidget {
  const CurrencyAdjustmentScreen({super.key});

  @override
  State<CurrencyAdjustmentScreen> createState() =>
      _CurrencyAdjustmentScreenState();
}

class _CurrencyAdjustmentScreenState extends State<CurrencyAdjustmentScreen> {
  bool _orangePanels = CurConvSettings.defaultOrangePanelsEnabled;
  int _reduction = CurConvSettings.defaultReductionAmount;
  final TextEditingController _reductionController = TextEditingController();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _reductionController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _orangePanels = prefs.getBool(CurConvSettings.orangePanelsEnabledKey) ??
          CurConvSettings.defaultOrangePanelsEnabled;
      _reduction = prefs.getInt(CurConvSettings.reductionAmountKey) ??
          CurConvSettings.defaultReductionAmount;
      _reductionController.text = '$_reduction';
      _loading = false;
    });
  }

  Future<void> _saveOrangePanels(bool value) async {
    setState(() => _orangePanels = value);
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(CurConvSettings.orangePanelsEnabledKey, value);
  }

  Future<void> _saveReduction(String text) async {
    final int? value = int.tryParse(text);
    if (value == null || value < 1) return;
    setState(() => _reduction = value);
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt(CurConvSettings.reductionAmountKey, value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Currency Adjustment'),
        centerTitle: true,
        backgroundColor: kCurconvTeal,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Container(
              decoration: curconvBackground(context),
              child: SafeArea(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(14, 18, 14, 22),
                  children: <Widget>[
                    Curconv3DTile(
                      leading: const Icon(Icons.grid_view_rounded,
                          color: Color(0xFF008577), size: 28),
                      title: const Text('Orange Panels',
                          style: TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 16)),
                      subtitle: const Text('လိမ္မော်ရောင် အကွက် ၂ ခု ပြရန်',
                          style: TextStyle(fontSize: 16)),
                      accent: const Color(0xFF008577),
                      tint: const Color(0xFFE3FAF5),
                      trailing: Curconv3DSwitch(
                        value: _orangePanels,
                        onChanged: _saveOrangePanels,
                      ),
                      onTap: () => _saveOrangePanels(!_orangePanels),
                    ),
                    const SizedBox(height: 12),
                    Curconv3DTile(
                      leading: const Icon(Icons.remove_circle_outline_rounded,
                          color: Color(0xFF008577), size: 28),
                      title: const Text('Reduction Amount',
                          style: TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 16)),
                      subtitle: const Text(
                          'အစိမ်းဈေးမှ လျှော့ချမည့် ပမာဏ',
                          style: TextStyle(fontSize: 16)),
                      accent: const Color(0xFF008577),
                      tint: const Color(0xFFE3FAF5),
                      trailing: SizedBox(
                        width: 72,
                        child: TextField(
                          controller: _reductionController,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          inputFormatters: <TextInputFormatter>[
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          decoration: const InputDecoration(
                            isDense: true,
                            border: OutlineInputBorder(),
                          ),
                          onChanged: _saveReduction,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
