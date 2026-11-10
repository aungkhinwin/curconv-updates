import 'app_updater.dart';
import 'customer_access_gate.dart';
import 'font_scale.dart';
import 'customer_access_service.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' show DartPluginRegistrant;
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import 'merchant_screen.dart';
import 'settings_screen.dart';
import 'app_menu_screen.dart';
import 'payment_screen.dart';
import 'theme_studio_screen.dart';
import 'app_version.dart';
import 'backup_data.dart';
import 'cloud_backup_repository.dart';
import 'curconv_3d.dart';
import 'firebase_options.dart';

int _topNoticeSequence = 0;
OverlayEntry? _topNoticeEntry;

Widget _chinaFlagBadge({double width = 32}) {
  final double flagWidth = width - 4;
  final double flagHeight = flagWidth * 2 / 3;
  return Container(
    width: width,
    height: flagHeight + 4,
    padding: const EdgeInsets.all(2),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(5),
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(2),
      child: SizedBox(
        width: flagWidth,
        height: flagHeight,
        child: Stack(
          children: [
            const Positioned.fill(child: ColoredBox(color: Color(0xFFDE2910))),
            Positioned(
              left: width * 0.07,
              top: flagHeight * 0.04,
              child: Text(
                '★',
                style: TextStyle(
                  color: const Color(0xFFFFDE00),
                  fontSize: width * 0.31,
                  height: 1,
                ),
              ),
            ),
            ...[
              (flagWidth * 0.42, flagHeight * 0.10, -0.5),
              (flagWidth * 0.52, flagHeight * 0.27, 0.1),
              (flagWidth * 0.52, flagHeight * 0.49, 0.35),
              (flagWidth * 0.42, flagHeight * 0.66, 0.5),
            ].map(
              (star) => Positioned(
                left: star.$1,
                top: star.$2,
                child: Transform.rotate(
                  angle: star.$3,
                  child: Text(
                    '★',
                    style: TextStyle(
                      color: const Color(0xFFFFDE00),
                      fontSize: width * 0.13,
                      height: 1,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

String _signedAmount(String value, num amount) =>
    amount > 0 ? '+$value' : value;

Widget _currencyFlagBadge(String pair, {double width = 32}) {
  if (pair == 'cny_mmk') return _chinaFlagBadge(width: width);
  final double height = (width - 4) * 2 / 3;
  return Container(
    width: width,
    height: height + 4,
    padding: const EdgeInsets.all(2),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(5),
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(2),
      child: CustomPaint(
        size: Size(width - 4, height),
        painter: _CurrencyFlagPainter(pair),
      ),
    ),
  );
}

class _CurrencyFlagPainter extends CustomPainter {
  const _CurrencyFlagPainter(this.pair);

  final String pair;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()..style = PaintingStyle.fill;
    if (pair == 'thb_mmk') {
      const List<Color> stripes = <Color>[
        Color(0xFFA51931),
        Colors.white,
        Color(0xFF2D2A4A),
        Colors.white,
        Color(0xFFA51931),
      ];
      const List<double> weights = <double>[1, 1, 2, 1, 1];
      final double unit = size.height / 6;
      double top = 0;
      for (int i = 0; i < stripes.length; i++) {
        final double bandHeight = unit * weights[i];
        paint.color = stripes[i];
        canvas.drawRect(Rect.fromLTWH(0, top, size.width, bandHeight), paint);
        top += bandHeight;
      }
      return;
    }

    // Malaysia: fourteen alternating red/white stripes, blue canton,
    // crescent and fourteen-point star, all drawn without flag emoji.
    const int stripeCount = 14;
    final double stripeHeight = size.height / stripeCount;
    for (int i = 0; i < stripeCount; i++) {
      paint.color = i.isEven ? const Color(0xFFCC0001) : Colors.white;
      canvas.drawRect(
        Rect.fromLTWH(0, i * stripeHeight, size.width, stripeHeight + 0.2),
        paint,
      );
    }
    final double cantonWidth = size.width * 0.52;
    final double cantonHeight = stripeHeight * 8;
    paint.color = const Color(0xFF010066);
    canvas.drawRect(Rect.fromLTWH(0, 0, cantonWidth, cantonHeight), paint);

    final double crescentRadius = cantonHeight * 0.29;
    final Offset center = Offset(cantonWidth * 0.35, cantonHeight * 0.50);
    paint.color = const Color(0xFFFFCC00);
    canvas.drawCircle(center, crescentRadius, paint);
    paint.color = const Color(0xFF010066);
    canvas.drawCircle(
      Offset(
          center.dx + crescentRadius * 0.34, center.dy - crescentRadius * 0.10),
      crescentRadius * 0.80,
      paint,
    );

    final Offset starCenter = Offset(cantonWidth * 0.72, cantonHeight * 0.50);
    final double outer = cantonHeight * 0.31;
    final double inner = outer * 0.40;
    final Path star = Path();
    for (int i = 0; i < 28; i++) {
      final double radius = i.isEven ? outer : inner;
      final double angle = -math.pi / 2 + i * math.pi / 14;
      final Offset point = Offset(
        starCenter.dx + math.cos(angle) * radius,
        starCenter.dy + math.sin(angle) * radius,
      );
      if (i == 0) {
        star.moveTo(point.dx, point.dy);
      } else {
        star.lineTo(point.dx, point.dy);
      }
    }
    star.close();
    paint.color = const Color(0xFFFFCC00);
    canvas.drawPath(star, paint);
  }

  @override
  bool shouldRepaint(covariant _CurrencyFlagPainter oldDelegate) =>
      oldDelegate.pair != pair;
}

void _showTopNotice(
  BuildContext context,
  String message, {
  bool isWarning = false,
}) {
  final OverlayState overlay = Overlay.of(context, rootOverlay: true);
  final int noticeSequence = ++_topNoticeSequence;
  _topNoticeEntry?.remove();
  final double top = MediaQuery.of(context).padding.top + 8;
  final double maxWidth = MediaQuery.of(context).size.width - 32;

  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => Positioned(
      top: top,
      left: 0,
      right: 0,
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Material(
            color:
                isWarning ? const Color(0xFFFFF3CD) : const Color(0xFFFFD2ED),
            elevation: 6,
            shape: const StadiumBorder(),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 9,
              ),
              child: Text(
                message,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isWarning
                      ? const Color(0xFF684500)
                      : const Color(0xFF65002B),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  _topNoticeEntry = entry;
  overlay.insert(entry);

  Future.delayed(const Duration(seconds: 2), () {
    if (noticeSequence != _topNoticeSequence || !entry.mounted) return;
    entry.remove();
    if (identical(_topNoticeEntry, entry)) _topNoticeEntry = null;
  });
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  unawaited(loadFontScale());
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  if (Platform.isAndroid) {
    try {
      await Workmanager().initialize(autoBackupCallbackDispatcher);
    } catch (_) {
      await _saveAutoBackupStatus('schedule_failed');
    }
  }
  // Auto-archive today's daily summary to Saved Info once it is 23:30 or later.
  unawaited(autoArchiveTodayIfDue());
  // Keep checking while the app stays open (e.g. left running all afternoon).
  Timer.periodic(const Duration(minutes: 5), (_) {
    unawaited(autoArchiveTodayIfDue());
  });
  runApp(const CurrencyConverterApp());
}

const String _autoBackupTaskName = 'curconv_idle_cloud_backup';
const String _autoBackupWorkName = 'curconv-auto-backup-after-idle';
const String _autoBackupStatusKey = 'auto_backup_last_status';
const String _autoBackupAtKey = 'auto_backup_last_attempt';
const Duration _autoBackupIdleDelay = Duration(minutes: 30);

@pragma('vm:entry-point')
void autoBackupCallbackDispatcher() {
  Workmanager().executeTask((String taskName, Map<String, dynamic>? inputData) async {
    WidgetsFlutterBinding.ensureInitialized();
    DartPluginRegistrant.ensureInitialized();
    if (taskName != _autoBackupTaskName) return true;
    try {
      await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform);
      final bool completed = await _performAutoBackup();
      return completed;
    } catch (error) {
      await _saveAutoBackupStatus('failed: $error');
      return false;
    }
  });
}

Future<void> _scheduleAutoBackupAfterIdle() async {
  await Workmanager().registerOneOffTask(
    _autoBackupWorkName,
    _autoBackupTaskName,
    initialDelay: _autoBackupIdleDelay,
    constraints: Constraints(
      networkType: NetworkType.connected,
      requiresBatteryNotLow: true,
    ),
    existingWorkPolicy: ExistingWorkPolicy.replace,
    backoffPolicy: BackoffPolicy.exponential,
    backoffPolicyDelay: const Duration(minutes: 15),
  );
}

Future<void> _saveAutoBackupStatus(String status) async {
  try {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_autoBackupStatusKey, status);
    await prefs.setString(_autoBackupAtKey, DateTime.now().toIso8601String());
  } catch (_) {
    // A status-write failure must not prevent the backup worker from retrying.
  }
}

/// Runs in a WorkManager background isolate after the app has been idle.
Future<bool> _performAutoBackup() async {
  try {
    final DateTime now = DateTime.now();
    final String today = "${now.day.toString().padLeft(2, '0')}/"
        "${now.month.toString().padLeft(2, '0')}/${now.year}";
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    final User? user = await FirebaseAuth.instance.authStateChanges().first;
    if (user == null) {
      await _saveAutoBackupStatus('no_account');
      return true;
    }
    if (!user.emailVerified) {
      await _saveAutoBackupStatus('unverified');
      return true;
    }

    final BackupData backup = BackupData.fromMap(<String, dynamic>{
      for (final String key in BackupData.keys)
        key: prefs.getStringList(key) ?? <String>[],
    });
    if (backup.recordCount == 0) {
      await _saveAutoBackupStatus('empty');
      return true;
    }
    if (backup.estimatedBytes > 900 * 1024) {
      await _saveAutoBackupStatus('too_large');
      return true;
    }
    final String fingerprint =
        sha256.convert(utf8.encode(jsonEncode(<String, dynamic>{
      'uid': user.uid,
      'records': backup.toMap(),
    }))).toString();
    if (prefs.getString('auto_backup_fingerprint') == fingerprint) {
      await _saveAutoBackupStatus('unchanged');
      return true;
    }

    await FirestoreCloudBackups()
        .save(user.uid, backup)
        .timeout(const Duration(seconds: 60));
    await prefs.setString('auto_backup_date', today);
    await prefs.setString('auto_backup_fingerprint', fingerprint);
    await _saveAutoBackupStatus('success');
    return true;
  } catch (error) {
    await _saveAutoBackupStatus('failed: $error');
    return false;
  }
}

/// After 23:30, archive today's history into 'archived_summaries' (per pair).
/// Re-running on the same day replaces that day's entry, so no duplicates.
Future<void> autoArchiveTodayIfDue() async {
  try {
    final DateTime now = DateTime.now();
    if (now.hour * 60 + now.minute < 23 * 60 + 30) return;

    final String today = "${now.day.toString().padLeft(2, '0')}/"
        "${now.month.toString().padLeft(2, '0')}/${now.year}";

    final prefs = await SharedPreferences.getInstance();
    final List<String> historyList =
        prefs.getStringList('history_records') ?? <String>[];

    final Map<String, List<Map<String, dynamic>>> byPair = {};
    for (final raw in historyList) {
      final Map<String, dynamic> record =
          Map<String, dynamic>.from(jsonDecode(raw) as Map);
      if (record['date']?.toString() != today) continue;
      final String pair = record['currencyPair']?.toString() ??
          CurConvSettings.defaultCurrencyPair;
      byPair.putIfAbsent(pair, () => <Map<String, dynamic>>[]).add(record);
    }
    if (byPair.isEmpty) return;

    final List<String> archiveList =
        prefs.getStringList('archived_summaries') ?? <String>[];

    for (final entry in byPair.entries) {
      double totalYuan = 0;
      int totalCustomer = 0;
      int totalTrader = 0;
      int totalProfit = 0;
      for (final item in entry.value) {
        totalYuan += (item['yuan'] as num?)?.toDouble() ?? 0;
        totalCustomer += (item['customer'] as num?)?.toInt() ?? 0;
        totalTrader += (item['trader'] as num?)?.toInt() ?? 0;
        totalProfit += (item['profit'] as num?)?.toInt() ?? 0;
      }
      archiveList.removeWhere((String element) {
        try {
          final Map<String, dynamic> map = jsonDecode(element);
          return map['date'] == today &&
              (map['currencyPair']?.toString() ??
                      CurConvSettings.defaultCurrencyPair) ==
                  entry.key;
        } catch (_) {
          return false;
        }
      });
      archiveList.insert(
          0,
          jsonEncode({
            'date': today,
            'currencyPair': entry.key,
            'yuan': totalYuan,
            'customer': totalCustomer,
            'trader': totalTrader,
            'profit': totalProfit,
            'records': entry.value,
          }));
    }
    await prefs.setStringList('archived_summaries', archiveList);
  } catch (_) {
    // Never block app startup because of archiving.
  }
}

class CurrencyConverterApp extends StatefulWidget {
  const CurrencyConverterApp({super.key});

  @override
  State<CurrencyConverterApp> createState() => _CurrencyConverterAppState();
}

class _CurrencyConverterAppState extends State<CurrencyConverterApp>
    with WidgetsBindingObserver {
  ThemeMode _themeMode = ThemeMode.light;
  final GlobalKey<CustomerAccessGateState> _accessGateKey =
      GlobalKey<CustomerAccessGateState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadThemeMode();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!Platform.isAndroid) return;
    if (state == AppLifecycleState.resumed) {
      unawaited(_cancelAutoBackupAfterIdle());
    } else if (state == AppLifecycleState.paused) {
      unawaited(_scheduleAutoBackupAfterIdle().catchError((Object error) {
        return _saveAutoBackupStatus('schedule_failed: $error');
      }));
    }
  }

  Future<void> _cancelAutoBackupAfterIdle() async {
    try {
      await Workmanager().cancelByUniqueName(_autoBackupWorkName);
    } catch (_) {
      // Cancellation is best-effort; it must not affect normal app use.
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _loadThemeMode() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _themeMode = prefs.getString(CurConvSettings.themeModeKey) == 'dark'
          ? ThemeMode.dark
          : ThemeMode.light;
    });
  }

  void _setThemeMode(ThemeMode themeMode) {
    if (_themeMode == themeMode) return;
    setState(() => _themeMode = themeMode);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'CurConv',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF00796B),
        scaffoldBackgroundColor: const Color(0xFFF4F6F8),
        // မြန်မာစာအတွက် Pyidaungsu သုံးပြီး၊ မပါဝင်သည့် အင်္ဂလိပ်စာလုံးများကို
        // Android ၏ မူလ Roboto စာလုံးပုံစံဖြင့် ပြသပါမည်။
        fontFamily: 'Pyidaungsu',
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00796B),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF121A19),
        fontFamily: 'Pyidaungsu',
      ),
      themeMode: _themeMode,
      builder: (BuildContext context, Widget? child) =>
          ValueListenableBuilder<double>(
        valueListenable: curconvFontScale,
        builder: (BuildContext c, double scale, Widget? _) => MediaQuery(
          data: MediaQuery.of(c).copyWith(
            textScaler: TextScaler.linear(scale),
          ),
          child: child ?? const SizedBox.shrink(),
        ),
      ),
      home: CustomerAccessGate(
        key: _accessGateKey,
        backend: CustomerAccessService(),
        child: CurrencyConverterHomeScreen(
          onThemeModeChanged: _setThemeMode,
          onAccountTap: () => _accessGateKey.currentState?.showAccount(),
        ),
      ),
    );
  }
}

class _KeyboardPalette {
  const _KeyboardPalette({
    required this.panelColor,
    required this.letterKeyColor,
    required this.letterTextColor,
    required this.headingTextColor,
    required this.displayColor,
    required this.numberTextColor,
    required this.utilityTextColor,
    required this.shadowColor,
    required this.numberKeyColors,
    required this.numberPressedColors,
    required this.utilityKeyColors,
    required this.utilityPressedColors,
  });

  final Color panelColor;
  final Color letterKeyColor;
  final Color letterTextColor;
  final Color headingTextColor;
  final Color displayColor;
  final Color numberTextColor;
  final Color utilityTextColor;
  final Color shadowColor;
  final List<Color> numberKeyColors;
  final List<Color> numberPressedColors;
  final List<Color> utilityKeyColors;
  final List<Color> utilityPressedColors;
}

class CurrencyConverterHomeScreen extends StatefulWidget {
  const CurrencyConverterHomeScreen({
    super.key,
    required this.onThemeModeChanged,
    this.onAccountTap,
  });

  final ValueChanged<ThemeMode> onThemeModeChanged;
  final VoidCallback? onAccountTap;

  @override
  State<CurrencyConverterHomeScreen> createState() =>
      _CurrencyConverterHomeScreenState();
}

class _CurrencyConverterHomeScreenState
    extends State<CurrencyConverterHomeScreen> {
  final TextEditingController _yuanToKyatController = TextEditingController();
  final TextEditingController _kyatToYuanController = TextEditingController();
  final TextEditingController _yuanRateController = TextEditingController();
  // MMK to CNY screen has its own amount fields so it never mirrors the home screen.
  final TextEditingController _mmkYuanController = TextEditingController();
  final TextEditingController _mmkKyatController = TextEditingController();
  // false = Division (÷) mode (default), true = Multiplication (×) mode.
  bool _mmkMultiply = false;
  final TextEditingController _mmkToCnyRateController = TextEditingController();
  final TextEditingController _traderRateController = TextEditingController();

  TextEditingController? _activeController;
  String? _pressedKey;
  bool _showMmkToCnyScreen = false;
  int? _edgeSwipePointer;
  Offset? _edgeSwipeOrigin;
  bool _pendingIsA1 = true;
  String _selectedCode = '';
  bool _letterKeyboardEnabled = CurConvSettings.defaultLetterKeyboardEnabled;
  String _currencyPair = CurConvSettings.defaultCurrencyPair;
  String _keyboardTheme = CurConvSettings.defaultKeyboardTheme;
  bool _keySoundEnabled = CurConvSettings.defaultKeySoundEnabled;
  bool _hapticEnabled = CurConvSettings.defaultHapticEnabled;
  bool _thousandSeparator = CurConvSettings.defaultThousandSeparatorEnabled;
  int _roundPrecision = CurConvSettings.defaultRoundPrecisionDigits;
  bool _orangePanels = CurConvSettings.defaultOrangePanelsEnabled;
  int _reduction = CurConvSettings.defaultReductionAmount;
  final LayerLink _a1SendLayerLink = LayerLink();
  final LayerLink _a2SendLayerLink = LayerLink();
  final GlobalKey _a1SendTargetKey = GlobalKey();
  final GlobalKey _a2SendTargetKey = GlobalKey();
  OverlayEntry? _codeKeyboardOverlay;

  String _a1ResultText = '';
  String _a2ResultText = '';
  String _b1ResultText = '';
  String _b2ResultText = '';
  String _mmkYuanResultText = '';
  String _mmkKyatResultText = '';

  int _totalCustomerKyats = 0;
  int _totalProfit = 0;
  int _totalTraderKyats = 0;

  _KeyboardPalette get _keyboardPalette {
    switch (_keyboardTheme) {
      case 'ocean':
        return const _KeyboardPalette(
          panelColor: Color(0xFFE7F0FC),
          letterKeyColor: Color(0xFFF8FBFF),
          letterTextColor: Color(0xFF17395F),
          headingTextColor: Color(0xFF48627E),
          displayColor: Color(0xFFD4E5FA),
          numberTextColor: Color(0xFF17395F),
          utilityTextColor: Color(0xFF17395F),
          shadowColor: Color(0xFF466A91),
          numberKeyColors: <Color>[
            Color(0xFFEAF3FF),
            Color(0xFFB9D5FA),
            Color(0xFF82AEE7),
          ],
          numberPressedColors: <Color>[
            Color(0xFFD7E9FF),
            Color(0xFF9FC5F4),
            Color(0xFF6697DB),
          ],
          utilityKeyColors: <Color>[
            Color(0xFFDCE8F6),
            Color(0xFFB6CBE5),
            Color(0xFF8EAACD),
          ],
          utilityPressedColors: <Color>[
            Color(0xFFCDDEF2),
            Color(0xFFA3BDDF),
            Color(0xFF7899C3),
          ],
        );
      case 'teal':
        return const _KeyboardPalette(
          panelColor: Color(0xFFE4F3F0),
          letterKeyColor: Color(0xFFF7FCFB),
          letterTextColor: Color(0xFF174B43),
          headingTextColor: Color(0xFF47766E),
          displayColor: Color(0xFFD0E9E3),
          numberTextColor: Color(0xFF174B43),
          utilityTextColor: Color(0xFF174B43),
          shadowColor: Color(0xFF397A6E),
          numberKeyColors: <Color>[
            Color(0xFFE0F7F2),
            Color(0xFFA9DED3),
            Color(0xFF69BDAE),
          ],
          numberPressedColors: <Color>[
            Color(0xFFCFF0E9),
            Color(0xFF8CCFC1),
            Color(0xFF4BAA98),
          ],
          utilityKeyColors: <Color>[
            Color(0xFFD6ECE7),
            Color(0xFFA6CEC5),
            Color(0xFF75AFA4),
          ],
          utilityPressedColors: <Color>[
            Color(0xFFC5E4DE),
            Color(0xFF91C3B9),
            Color(0xFF5E9F93),
          ],
        );
      case 'sunset':
        return const _KeyboardPalette(
          panelColor: Color(0xFFE9EDF2),
          letterKeyColor: Colors.white,
          letterTextColor: Color(0xFF07142D),
          headingTextColor: Color(0xFF5F6368),
          displayColor: Color(0xFFF8F6F3),
          numberTextColor: Color(0xFF07142D),
          utilityTextColor: Color(0xFF07142D),
          shadowColor: Color(0xFFFD9522),
          numberKeyColors: <Color>[
            Color(0xFFF8F6F3),
            Color(0xFFFEE87B),
            Color(0xFFFDA755),
          ],
          numberPressedColors: <Color>[
            Color(0xFFF8F6F3),
            Color(0xFFFEE87B),
            Color(0xFFFDA755),
          ],
          utilityKeyColors: <Color>[
            Color(0xFFFD9522),
            Color(0xFFFD9522),
            Color(0xFFFD9522),
          ],
          utilityPressedColors: <Color>[
            Color(0xFFFD9522),
            Color(0xFFFD9522),
            Color(0xFFFD9522),
          ],
        );
      case 'skyPurple':
        return const _KeyboardPalette(
          panelColor: Color(0xFF33ABFD),
          letterKeyColor: Color(0xFFF4FAFE),
          letterTextColor: Color(0xFF00134E),
          headingTextColor: Color(0xFF00134E),
          displayColor: Color(0xFFF4FAFE),
          numberTextColor: Color(0xFF00134E),
          utilityTextColor: Color(0xFFFFFFFF),
          shadowColor: Color(0xFF315DA0),
          numberKeyColors: <Color>[
            Color(0xFFF4FAFE),
            Color(0xFFF4FAFE),
            Color(0xFFF4FAFE),
          ],
          numberPressedColors: <Color>[
            Color(0xFFF4FAFE),
            Color(0xFFF4FAFE),
            Color(0xFFF4FAFE),
          ],
          utilityKeyColors: <Color>[
            Color(0xFF8956FC),
            Color(0xFF8956FC),
            Color(0xFF8956FC),
          ],
          utilityPressedColors: <Color>[
            Color(0xFF8956FC),
            Color(0xFF8956FC),
            Color(0xFF8956FC),
          ],
        );
      case 'oxblood':
        return const _KeyboardPalette(
          panelColor: Color(0xFFFAF9F7),
          letterKeyColor: Colors.white,
          letterTextColor: Color(0xFF4A100B),
          headingTextColor: Color(0xFF4A100B),
          displayColor: Color(0xFFFAF9F7),
          numberTextColor: Colors.white,
          utilityTextColor: Color(0xFF4A100B),
          shadowColor: Color(0xFF650500),
          numberKeyColors: <Color>[
            Color(0xFF650500),
            Color(0xFF650500),
            Color(0xFF650500),
          ],
          numberPressedColors: <Color>[
            Color(0xFF650500),
            Color(0xFF650500),
            Color(0xFF650500),
          ],
          utilityKeyColors: <Color>[
            Color(0xFFE6B8B4),
            Color(0xFFE6B8B4),
            Color(0xFFE6B8B4),
          ],
          utilityPressedColors: <Color>[
            Color(0xFFE6B8B4),
            Color(0xFFE6B8B4),
            Color(0xFFE6B8B4),
          ],
        );
      default:
        return const _KeyboardPalette(
          panelColor: Color(0xFFE9EDF2),
          letterKeyColor: Colors.white,
          letterTextColor: Color(0xFF202124),
          headingTextColor: Color(0xFF5F6368),
          displayColor: Colors.white,
          numberTextColor: Color(0xFF4B1B0D),
          utilityTextColor: Color(0xFF4B1B0D),
          shadowColor: Color(0xFF8C573C),
          numberKeyColors: <Color>[
            Color(0xFFFFF0D8),
            Color(0xFFF9D09B),
            Color(0xFFEBAE70),
          ],
          numberPressedColors: <Color>[
            Color(0xFFFFE1B4),
            Color(0xFFF7C58F),
            Color(0xFFE8A96C),
          ],
          utilityKeyColors: <Color>[
            Color(0xFFF5DDD2),
            Color(0xFFDDB3A2),
            Color(0xFFC9917B),
          ],
          utilityPressedColors: <Color>[
            Color(0xFFE8C6B8),
            Color(0xFFD7A795),
            Color(0xFFC8917C),
          ],
        );
    }
  }

  @override
  void initState() {
    super.initState();
    _activeController = _yuanToKyatController;
    _loadSavedData();
  }

  @override
  void dispose() {
    _codeKeyboardOverlay?.remove();
    _codeKeyboardOverlay = null;
    _yuanToKyatController.dispose();
    _kyatToYuanController.dispose();
    _yuanRateController.dispose();
    _mmkYuanController.dispose();
    _mmkKyatController.dispose();
    _mmkToCnyRateController.dispose();
    _traderRateController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedData() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    final String? savedPair = prefs.getString(CurConvSettings.currencyPairKey);
    final String pair = CurConvSettings.currencyPairIds.contains(savedPair)
        ? savedPair!
        : CurConvSettings.defaultCurrencyPair;

    setState(() {
      _currencyPair = pair;
      _yuanRateController.text =
          prefs.getString(CurConvSettings.customerRateKey(pair)) ?? '';
      _mmkToCnyRateController.text =
          prefs.getString(CurConvSettings.reverseRateKey(pair)) ?? '';
      _traderRateController.text =
          prefs.getString(CurConvSettings.traderRateKey(pair)) ?? '';
      _letterKeyboardEnabled =
          prefs.getBool(CurConvSettings.letterKeyboardEnabledKey) ??
              CurConvSettings.defaultLetterKeyboardEnabled;
      final String? savedKeyboardTheme = prefs.getString(
        CurConvSettings.keyboardThemeKey,
      );
      _keyboardTheme =
          CurConvSettings.keyboardThemeNames.containsKey(savedKeyboardTheme)
              ? savedKeyboardTheme!
              : CurConvSettings.defaultKeyboardTheme;
      _keySoundEnabled = prefs.getBool(CurConvSettings.keySoundEnabledKey) ??
          CurConvSettings.defaultKeySoundEnabled;
      _hapticEnabled = prefs.getBool(CurConvSettings.hapticEnabledKey) ??
          CurConvSettings.defaultHapticEnabled;
      _thousandSeparator =
          prefs.getBool(CurConvSettings.thousandSeparatorEnabledKey) ??
              CurConvSettings.defaultThousandSeparatorEnabled;
      _roundPrecision =
          prefs.getInt(CurConvSettings.roundPrecisionDigitsKey) ?? CurConvSettings.defaultRoundPrecisionDigits;
      _orangePanels = prefs.getBool(CurConvSettings.orangePanelsEnabledKey) ??
          CurConvSettings.defaultOrangePanelsEnabled;
      _reduction = prefs.getInt(CurConvSettings.reductionAmountKey) ??
          CurConvSettings.defaultReductionAmount;
    });
    _recalculateTotalsFromHistory();
  }

  String _formatDisplayAmount(num value) => CurConvSettings.formatDisplayNumber(
        value,
        thousandSeparator: _thousandSeparator,
        roundPrecision: _roundPrecision,
      );

  Future<void> _recalculateTotalsFromHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> historyList =
        prefs.getStringList('history_records') ?? [];

    int customerSum = 0;
    int profitSum = 0;
    int traderSum = 0;

    for (final item in historyList) {
      final Map<String, dynamic> record = jsonDecode(item);
      customerSum += (record['customer'] as num).toInt();
      profitSum += (record['profit'] as num).toInt();
      traderSum += (record['trader'] as num).toInt();
    }

    if (!mounted) return;
    setState(() {
      _totalCustomerKyats = customerSum;
      _totalProfit = profitSum;
      _totalTraderKyats = traderSum;
    });
  }

  Future<void> _saveRates() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      CurConvSettings.customerRateKey(_currencyPair),
      _yuanRateController.text,
    );
    await prefs.setString(
      CurConvSettings.traderRateKey(_currencyPair),
      _traderRateController.text,
    );

    if (!mounted) return;
    _showTopNotice(context, 'ဈေးနှုန်းများ သိမ်းဆည်းပြီးပါပြီ!');
  }

  Future<void> _openSettings() async {
    await Navigator.of(context).push<bool>(
      PageRouteBuilder<bool>(
        opaque: true,
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
        pageBuilder: (context, animation, secondaryAnimation) => SettingsScreen(
          showNotices: true,
          onThemeModeChanged: widget.onThemeModeChanged,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            child,
      ),
    );
    if (!mounted) return;
    await _loadSavedData();
    if (!_letterKeyboardEnabled) _closeCodeKeyboard();
  }

  Future<void> _openThemes() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    final String? savedKeyboardTheme =
        prefs.getString(CurConvSettings.keyboardThemeKey);
    final String initialKeyboardTheme =
        CurConvSettings.keyboardThemeNames.containsKey(savedKeyboardTheme)
            ? savedKeyboardTheme!
            : CurConvSettings.defaultKeyboardTheme;
    await Navigator.of(context).push<void>(
      PageRouteBuilder<void>(
        opaque: true,
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
        pageBuilder: (_, animation, secondaryAnimation) => ThemeStudioScreen(
          initialMode: prefs.getString(CurConvSettings.themeModeKey) == 'dark'
              ? ThemeMode.dark
              : ThemeMode.light,
          initialKeyboardTheme: initialKeyboardTheme,
          onThemeModeChanged: widget.onThemeModeChanged,
          onKeyboardThemeChanged: (String theme) {
            if (mounted) setState(() => _keyboardTheme = theme);
          },
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            child,
      ),
    );
  }

  Future<void> _handleHomeMenu() async {
    await Navigator.of(context).push<void>(
      PageRouteBuilder<void>(
        opaque: true,
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
        pageBuilder: (_, animation, secondaryAnimation) =>
            AppMenuScreen(onAction: _handleMenuAction),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            child,
      ),
    );
  }

  void _handleMenuAction(AppMenuAction action) {
    switch (action) {
      case AppMenuAction.account:
        widget.onAccountTap?.call();
      case AppMenuAction.payment:
        Navigator.of(context).push<void>(
          MaterialPageRoute<void>(builder: (_) => const PaymentScreen()),
        );
      case AppMenuAction.themes:
        unawaited(_openThemes());
      case AppMenuAction.settings:
        unawaited(_openSettings());
      case AppMenuAction.about:
        _showAboutUpdateDialog();
    }
  }

  void _showAboutUpdateDialog() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => const _AboutUpdateDialog(),
    );
  }

  int _roundToNearestThousand(double value) {
    return ((value / 1000).round()) * 1000;
  }

  // MYR multiplies; CNY and THB keep the divide formula.
  double _toKyat(double amount, double rate) => _currencyPair == 'myr_mmk'
      ? amount * rate
      : (amount / rate) * 100000;

  double _toCurrency(double kyats, double rate) => _currencyPair == 'myr_mmk'
      ? kyats / rate
      : (kyats / 100000) * rate;

  void _calculate() {
    if (_showMmkToCnyScreen) {
      final String yuanResult = _swipeCopyText(yuanToKyat: true);
      final String kyatResult = _swipeCopyText(yuanToKyat: false);
      setState(() {
        _mmkYuanResultText = yuanResult;
        _mmkKyatResultText = kyatResult;
      });
      return;
    }

    final double yuan = double.tryParse(_yuanToKyatController.text) ?? 0;
    final double kyats = double.tryParse(_kyatToYuanController.text) ?? 0;
    final double yuanRate = double.tryParse(_yuanRateController.text) ?? 0;
    final double yuanRateMinus1 = yuanRate > 0 ? yuanRate - _reduction : 0;

    setState(() {
      if (yuan > 0 && yuanRate > 0) {
        final int calculatedKyats =
            _roundToNearestThousand(_toKyat(yuan, yuanRate));
        final String rateStr = _formatDisplayAmount(yuanRate);

        _a1ResultText =
            "${CurConvSettings.currencyAmount(_formatDisplayAmount(yuan), _currencyPair)} ($rateStr)\n"
            "KPay ➙ ${_formatDisplayAmount(calculatedKyats)} Ks";
      } else {
        _a1ResultText = '';
      }

      if (yuan > 0 && yuanRateMinus1 > 0) {
        final int calculatedKyats =
            _roundToNearestThousand(_toKyat(yuan, yuanRateMinus1));
        final String rateStr = _formatDisplayAmount(yuanRateMinus1);

        _a2ResultText =
            "${CurConvSettings.currencyAmount(_formatDisplayAmount(yuan), _currencyPair)} ($rateStr)\n"
            "KPay ➙ ${_formatDisplayAmount(calculatedKyats)} Ks";
      } else {
        _a2ResultText = '';
      }

      if (kyats > 0 && yuanRate > 0) {
        // ROUND(x, 0) for the yuan result on the home screen.
        final double calculatedYuan = _toCurrency(kyats, yuanRate).roundToDouble();
        final String rateStr = _formatDisplayAmount(yuanRate);

        _b1ResultText = "KPay ➙ ${_formatDisplayAmount(kyats)} Ks ($rateStr)\n"
            "${CurConvSettings.currencyAmount(_formatDisplayAmount(calculatedYuan), _currencyPair)}";
      } else {
        _b1ResultText = '';
      }

      if (kyats > 0 && yuanRateMinus1 > 0) {
        final double calculatedYuan =
            _toCurrency(kyats, yuanRateMinus1).roundToDouble();
        final String rateStr = _formatDisplayAmount(yuanRateMinus1);

        _b2ResultText = "KPay ➙ ${_formatDisplayAmount(kyats)} Ks ($rateStr)\n"
            "${CurConvSettings.currencyAmount(_formatDisplayAmount(calculatedYuan), _currencyPair)}";
      } else {
        _b2ResultText = '';
      }
    });
  }

  void _openCodeKeyboard(bool isA1) {
    final double yuan = double.tryParse(_yuanToKyatController.text) ?? 0;
    final double yuanRate = double.tryParse(_yuanRateController.text) ?? 0;
    final double effectiveRate = isA1 ? yuanRate : yuanRate - 1;

    if (yuan <= 0 || effectiveRate <= 0) {
      _showTopNotice(
        context,
        'ပမာဏနဲ့ ${CurConvSettings.currencyName(_currencyPair)} ဈေးကို အရင်ဖြည့်ပါ',
        isWarning: true,
      );
      return;
    }

    if (!_letterKeyboardEnabled) {
      _sendDirectToHistory(isA1, code: '');
      return;
    }

    _codeKeyboardOverlay?.remove();
    _codeKeyboardOverlay = null;
    setState(() {
      _pendingIsA1 = isA1;
      _selectedCode = '';
    });

    final LayerLink sendLink = isA1 ? _a1SendLayerLink : _a2SendLayerLink;
    final GlobalKey sendTargetKey = isA1 ? _a1SendTargetKey : _a2SendTargetKey;
    final RenderBox? sendTargetBox =
        sendTargetKey.currentContext?.findRenderObject() as RenderBox?;
    final double sendTargetLeft =
        sendTargetBox?.localToGlobal(Offset.zero).dx ?? 22;
    final double keyboardWidth = MediaQuery.of(context).size.width;

    _codeKeyboardOverlay = OverlayEntry(
      builder: (overlayContext) => Positioned.fill(
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: _closeCodeKeyboard,
                child: const SizedBox.expand(),
              ),
            ),
            CompositedTransformFollower(
              link: sendLink,
              showWhenUnlinked: false,
              targetAnchor: Alignment.bottomLeft,
              followerAnchor: Alignment.topLeft,
              offset: Offset(-sendTargetLeft, 8),
              child: Material(
                color: _keyboardPalette.panelColor,
                elevation: 12,
                borderRadius: BorderRadius.circular(14),
                clipBehavior: Clip.antiAlias,
                child: SizedBox(
                  width: keyboardWidth,
                  child: _buildAlphabetKeypad(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
    Overlay.of(context, rootOverlay: true).insert(_codeKeyboardOverlay!);
  }

  void _closeCodeKeyboard() {
    _codeKeyboardOverlay?.remove();
    _codeKeyboardOverlay = null;
    if (!mounted) return;
    setState(() {
      _selectedCode = '';
    });
  }

  void _removeLastCodeLetter() {
    if (_selectedCode.isEmpty) return;
    setState(() {
      _selectedCode = _selectedCode.substring(0, _selectedCode.length - 1);
    });
    _codeKeyboardOverlay?.markNeedsBuild();
  }

  Future<void> _selectCodeLetter(String letter) async {
    if (_selectedCode.length >= 2) return;
    final String nextCode = '$_selectedCode$letter';

    if (nextCode.length < 2) {
      setState(() => _selectedCode = nextCode);
      _codeKeyboardOverlay?.markNeedsBuild();
      return;
    }

    final bool isA1 = _pendingIsA1;
    _closeCodeKeyboard();
    await _sendDirectToHistory(isA1, code: nextCode);
  }

  Future<void> _sendDirectToHistory(bool isA1, {required String code}) async {
    final double yuan = double.tryParse(_yuanToKyatController.text) ?? 0;
    final double yuanRate = double.tryParse(_yuanRateController.text) ?? 0;
    final double traderRate = double.tryParse(_traderRateController.text) ?? 0;

    if (yuan <= 0 || yuanRate <= 0) return;

    final double currentRate = isA1 ? yuanRate : (yuanRate - _reduction);
    if (currentRate <= 0) return;

    final int customerKyats = _roundToNearestThousand(
      _toKyat(yuan, currentRate),
    );
    final int traderKyats = traderRate > 0
        ? _roundToNearestThousand(_toKyat(yuan, traderRate))
        : 0;
    final int profit = traderKyats - customerKyats;

    final prefs = await SharedPreferences.getInstance();
    final List<String> historyList =
        prefs.getStringList('history_records') ?? [];

    final DateTime now = DateTime.now();
    final String dateOnly = "${now.day.toString().padLeft(2, '0')}/"
        "${now.month.toString().padLeft(2, '0')}/${now.year}";
    final String timeOnly = "${now.hour.toString().padLeft(2, '0')}:"
        "${now.minute.toString().padLeft(2, '0')}:"
        "${now.second.toString().padLeft(2, '0')}";

    final Map<String, dynamic> record = {
      'date': dateOnly,
      'time': timeOnly,
      'customer': customerKyats,
      'profit': profit,
      'trader': traderKyats,
      'yuan': yuan,
      'rate': currentRate,
      'code': code,
      'currencyPair': _currencyPair,
    };

    historyList.insert(0, jsonEncode(record));
    await prefs.setStringList('history_records', historyList);
    await _recalculateTotalsFromHistory();

    if (!mounted) return;
    _showTopNotice(context, 'မှတ်တမ်းသို့ ပို့ပြီးပါပြီ');
  }

  Future<void> _copyToClipboard(
    String text,
    TextEditingController amountController,
  ) async {
    if (text.isEmpty) return;

    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;

    setState(() {
      amountController.clear();
      if (identical(amountController, _yuanToKyatController) ||
          identical(amountController, _mmkYuanController)) {
        if (identical(amountController, _mmkYuanController)) {
          _mmkYuanResultText = '';
        } else {
          _a1ResultText = '';
          _a2ResultText = '';
        }
      } else if (identical(amountController, _kyatToYuanController) ||
          identical(amountController, _mmkKyatController)) {
        if (identical(amountController, _mmkKyatController)) {
          _mmkKyatResultText = '';
        } else {
          _b1ResultText = '';
          _b2ResultText = '';
        }
      }
    });
    _showTopNotice(context, 'ကူးယူခဲ့သည်');
  }

  void _onKeypadTap(String value) {
    final TextEditingController? controller = _activeController;
    if (controller == null) return;

    final String oldText = controller.text;
    final TextSelection selection = controller.selection;
    final int start = selection.isValid
        ? selection.start.clamp(0, oldText.length).toInt()
        : oldText.length;
    final int end = selection.isValid
        ? selection.end.clamp(0, oldText.length).toInt()
        : oldText.length;

    if (value == 'BACKSPACE') {
      if (start == 0 && end == 0) return;
      final int deleteStart = start == end ? start - 1 : start;
      final String newText = oldText.replaceRange(deleteStart, end, '');
      controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: deleteStart),
      );
    } else {
      final String textBeforeInsertion = oldText.replaceRange(start, end, '');
      if (value == '.' && textBeforeInsertion.contains('.')) return;
      final String newText = oldText.replaceRange(start, end, value);
      controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: start + value.length),
      );
    }

    _calculate();
  }

  void _navigateToHistoryScreen() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const HistoryScreen()),
    );
    _recalculateTotalsFromHistory();
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    VoidCallback? onClear,
    Key? fieldKey,
    Key? clearKey,
    IconData clearIcon = Icons.cancel,
    Color clearIconColor = Colors.grey,
  }) {
    final bool isSelected = _activeController == controller;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isSelected
            ? (isDark ? const Color(0xFF18302D) : const Color(0xFFE8F5E9))
            : (isDark ? const Color(0xFF2B3332) : Colors.grey.shade100),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected
              ? const Color(0xFF00796B)
              : (isDark ? Colors.white38 : Colors.black38),
          width: isSelected ? 2 : 1,
        ),
      ),
      child: TextField(
        key: fieldKey,
        controller: controller,
        showCursor: true,
        keyboardType: TextInputType.none,
        onTap: () => setState(() => _activeController = controller),
        onChanged: (_) => _calculate(),
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        decoration: InputDecoration(
          labelText: labelText,
          floatingLabelBehavior: FloatingLabelBehavior.auto,
          labelStyle: TextStyle(
            color: isSelected
                ? const Color(0xFF00796B)
                : (isDark ? Colors.white70 : Colors.grey.shade700),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 8,
          ),
          suffixIcon: onClear != null && controller.text.isNotEmpty
              ? IconButton(
                  key: clearKey,
                  icon: Icon(
                    clearIcon,
                    size: 18,
                    color: clearIconColor,
                  ),
                  onPressed: onClear,
                )
              : null,
        ),
      ),
    );
  }

  void _resetEdgeSwipe() {
    _edgeSwipePointer = null;
    _edgeSwipeOrigin = null;
  }

  void _handleEdgePointerDown(PointerDownEvent event) {
    // Аль ч хэсгээс богино хэвтээ шудралтаар дэлгэц солих боломжтой.
    _edgeSwipePointer = event.pointer;
    _edgeSwipeOrigin = event.position;
  }

  void _handleEdgePointerMove(PointerMoveEvent event) {
    if (event.pointer != _edgeSwipePointer) return;
  }

  void _handleEdgePointerUp(PointerUpEvent event) {
    if (event.pointer != _edgeSwipePointer || _edgeSwipeOrigin == null) return;
    final Offset delta = event.position - _edgeSwipeOrigin!;
    _resetEdgeSwipe();
    if (delta.dx.abs() < 36 || delta.dx.abs() <= delta.dy.abs() * 1.2) return;

    if (!_showMmkToCnyScreen && delta.dx < 0) {
      _closeCodeKeyboard();
      setState(() {
        _showMmkToCnyScreen = true;
        _activeController = _mmkYuanController;
      });
      _calculate();
    } else if (_showMmkToCnyScreen && delta.dx > 0) {
      setState(() {
        _showMmkToCnyScreen = false;
        _activeController = _yuanToKyatController;
      });
      _calculate();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope<Object?>(
      canPop: !_showMmkToCnyScreen,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (!didPop && _showMmkToCnyScreen) {
          setState(() {
            _showMmkToCnyScreen = false;
            _activeController = _yuanToKyatController;
          });
          _calculate();
        }
      },
      child: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: _handleEdgePointerDown,
        onPointerMove: _handleEdgePointerMove,
        onPointerUp: _handleEdgePointerUp,
        onPointerCancel: (_) => _resetEdgeSwipe(),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 260),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (Widget child, Animation<double> animation) {
            final bool isReversePage = (child.key as ValueKey<bool>).value;
            final Offset begin =
                isReversePage ? const Offset(1, 0) : const Offset(-1, 0);
            return SlideTransition(
              position: Tween<Offset>(begin: begin, end: Offset.zero).animate(
                CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeInOutCubic,
                ),
              ),
              child: child,
            );
          },
          child: KeyedSubtree(
            key: ValueKey<bool>(_showMmkToCnyScreen),
            child: _showMmkToCnyScreen
                ? _buildMmkToCnyScreen()
                : _buildMainScreen(),
          ),
        ),
      ),
    );
  }

  Widget _buildMainScreen() {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        leadingWidth: MediaQuery.sizeOf(context).width < 400 ? 104 : 120,
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: 'မှတ်တမ်း',
              constraints: const BoxConstraints.tightFor(width: 48, height: 48),
              padding: EdgeInsets.zero,
              splashRadius: 24,
              onPressed: _navigateToHistoryScreen,
              icon: const CurconvHistoryIcon(size: 25),
            ),
            SizedBox(width: MediaQuery.sizeOf(context).width < 400 ? 8 : 16),
            IconButton(
              tooltip: 'Merchant',
              constraints: const BoxConstraints.tightFor(width: 48, height: 48),
              padding: EdgeInsets.zero,
              splashRadius: 24,
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (BuildContext context) => const MerchantScreen(),
                  ),
                );
              },
              icon: const Icon(
                Icons.storefront,
                color: Colors.white,
                size: 24,
              ),
            ),
          ],
        ),
        titleSpacing: 0,
        title: const Text(
          'CurConv',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 19,
          ),
        ),
        backgroundColor: const Color(0xFF00796B),
        actions: [
          IconButton(
            tooltip: 'Save',
            icon: const Icon(Icons.save_outlined, color: Colors.white),
            onPressed: _saveRates,
          ),
          const SizedBox(width: 16),
          IconButton(
            tooltip: 'Menu',
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: _handleHomeMenu,
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            color: Theme.of(context).colorScheme.surface,
            child: Row(
              children: [
                Expanded(
                  child: _buildTopDashboardCard(
                    iconAsset: 'assets/images/cash_transfer.webp',
                    text: '${_formatDisplayAmount(_totalCustomerKyats)} Ks',
                    bgColor:
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildTopDashboardCard(
                    iconAsset: 'assets/images/profit_graph.webp',
                    text: '${_signedAmount(_formatDisplayAmount(_totalProfit), _totalProfit)} Ks',
                    textColor: Colors.green.shade700,
                    bgColor:
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildTopDashboardCard(
                    iconAsset: 'assets/images/cash_withdrawal.webp',
                    text: '${_formatDisplayAmount(_totalTraderKyats)} Ks',
                    bgColor:
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          controller: _yuanToKyatController,
                          labelText:
                              CurConvSettings.currencyName(_currencyPair) ==
                                      'တရုတ်ယွမ်'
                                  ? 'ယွမ် မှ ကျပ်'
                                  : '${CurConvSettings.currencyName(_currencyPair)} မှ ကျပ်',
                          onClear: () {
                            _yuanToKyatController.clear();
                            _calculate();
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildTextField(
                          controller: _kyatToYuanController,
                          labelText:
                              CurConvSettings.currencyName(_currencyPair) ==
                                      'တရုတ်ယွမ်'
                                  ? 'ကျပ် မှ ယွမ်'
                                  : 'ကျပ် မှ ${CurConvSettings.currencyName(_currencyPair)}',
                          onClear: () {
                            _kyatToYuanController.clear();
                            _calculate();
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          controller: _yuanRateController,
                          labelText: 'ရောင်းဈေး',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildTextField(
                          controller: _traderRateController,
                          labelText: 'ကုန်သည်ဈေး',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildResultCard(
                          titleText: _a1ResultText.isEmpty
                              ? "${CurConvSettings.currencyAmount('0', _currencyPair)} (0)\nKPay ➙ 0 Ks"
                              : _a1ResultText,
                          bgColor: const Color(0xFF004D40),
                          isSendAvailable: true,
                          sendLayerLink: _a1SendLayerLink,
                          onSend: () => _openCodeKeyboard(true),
                          onCopy: () => _copyToClipboard(
                            _a1ResultText,
                            _yuanToKyatController,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildResultCard(
                          titleText: _b1ResultText.isEmpty
                              ? "KPay ➙ 0 Ks (0)\n${CurConvSettings.currencyAmount('0', _currencyPair)}"
                              : _b1ResultText,
                          bgColor: const Color(0xFF004D40),
                          isSendAvailable: false,
                          onCopy: () => _copyToClipboard(
                            _b1ResultText,
                            _kyatToYuanController,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_orangePanels) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _buildResultCard(
                          titleText: _a2ResultText.isEmpty
                              ? "${CurConvSettings.currencyAmount('0', _currencyPair)} (0)\nKPay ➙ 0 Ks"
                              : _a2ResultText,
                          bgColor: const Color(0xFFD97706),
                          isSendAvailable: true,
                          sendLayerLink: _a2SendLayerLink,
                          onSend: () => _openCodeKeyboard(false),
                          onCopy: () => _copyToClipboard(
                            _a2ResultText,
                            _yuanToKyatController,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildResultCard(
                          titleText: _b2ResultText.isEmpty
                              ? "KPay ➙ 0 Ks (0)\n${CurConvSettings.currencyAmount('0', _currencyPair)}"
                              : _b2ResultText,
                          bgColor: const Color(0xFFD97706),
                          isSendAvailable: false,
                          onCopy: () => _copyToClipboard(
                            _b2ResultText,
                            _kyatToYuanController,
                          ),
                        ),
                      ),
                    ],
                  ),
                  ],
                ],
              ),
            ),
          ),
          _buildCustomKeypad(),
        ],
      ),
    );
  }

  Future<void> _saveSwipeRate() async {
    final String text = _mmkToCnyRateController.text.trim();
    final double? rate = double.tryParse(text);
    if (rate == null || !rate.isFinite || rate <= 0) {
      _showTopNotice(
        context,
        '${CurConvSettings.currencyName(_currencyPair)} ရောင်းဈေးကို 0 ထက်ကြီးသော ကိန်းဂဏန်း ထည့်ပါ။',
        isWarning: true,
      );
      return;
    }
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      if (!await prefs.setString(
        CurConvSettings.reverseRateKey(_currencyPair),
        text,
      )) {
        throw StateError('ဈေးနှုန်း သိမ်း၍မရပါ။');
      }
      if (!mounted) return;
      _showTopNotice(
        context,
        '${CurConvSettings.currencyName(_currencyPair)} ရောင်းဈေး သိမ်းဆည်းပြီးပါပြီ။',
      );
    } catch (_) {
      if (mounted) {
        _showTopNotice(
          context,
          'ဈေးနှုန်း သိမ်း၍မရပါ။ ထပ်ကြိုးစားပါ။',
          isWarning: true,
        );
      }
    }
  }

  String _swipeDirectionLabel() => _currencyPair == 'cny_mmk'
      ? 'ကျပ်ပေး ယွမ်ယူ'
      : 'ကျပ်ပီး ${CurConvSettings.currencyName(_currencyPair)} ယူ';

  String _swipeCopyText({required bool yuanToKyat}) {
    final double rate = double.tryParse(_mmkToCnyRateController.text) ?? 0;
    final double amount = double.tryParse(
          yuanToKyat ? _mmkYuanController.text : _mmkKyatController.text,
        ) ??
        0;
    if (!rate.isFinite || rate <= 0 || !amount.isFinite || amount <= 0) {
      return '';
    }
    final String rateText = _formatDisplayAmount(rate);
    final String heading = '${_swipeDirectionLabel()} ($rateText)';
    if (yuanToKyat) {
      final double kyats = _mmkMultiply
          ? (amount * rate).roundToDouble()
          : _toKyat(amount, rate);
      if (!kyats.isFinite) return '';
      return '$heading\n'
          '${CurConvSettings.currencyAmount(_formatDisplayAmount(amount), _currencyPair)} ➙ ${_formatDisplayAmount(kyats.round())} Ks';
    }
    // Excel ROUND(x, 0) for the yuan result card.
    final double yuan = _mmkMultiply
        ? (amount / rate).roundToDouble()
        : _toCurrency(amount, rate);
    if (!yuan.isFinite) return '';
    return '$heading\n'
        'KPay ➙ ${_formatDisplayAmount(amount)} Ks\n'
        '${CurConvSettings.currencyAmount(_formatDisplayAmount(yuan), _currencyPair)}';
  }

  Widget _buildSwipeCopyCard({required bool yuanToKyat}) {
    final String result =
        yuanToKyat ? _mmkYuanResultText : _mmkKyatResultText;
    const Color orange = Color(0xFFE67E00);
    return Container(
      key: ValueKey<String>(yuanToKyat ? 'swipe-yuan-card' : 'swipe-kyat-card'),
      height: 120,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: orange,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Expanded(
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  result.isEmpty
                      ? (yuanToKyat
                      ? '${_swipeDirectionLabel()}\n${CurConvSettings.currencyAmount('0', _currencyPair)} ➙ 0 Ks'
                          : '${_swipeDirectionLabel()}\nKPay ➙ 0 Ks\n${CurConvSettings.currencyAmount('0', _currencyPair)}')
                      : result,
                  key: ValueKey<String>(
                    yuanToKyat ? 'swipe-yuan-result' : 'swipe-kyat-result',
                  ),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 36,
            child: ElevatedButton.icon(
              key: ValueKey<String>(
                yuanToKyat ? 'swipe-yuan-copy' : 'swipe-kyat-copy',
              ),
              onPressed: result.isEmpty
                  ? null
                  : () => _copyToClipboard(
                        result,
                        yuanToKyat
                            ? _mmkYuanController
                            : _mmkKyatController,
                      ),
              icon: const Icon(Icons.copy_rounded, size: 17),
              label: const Text(
                'Copy',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: orange,
                disabledBackgroundColor: Colors.white.withAlpha(210),
                disabledForegroundColor: orange.withAlpha(150),
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _setMmkMode(bool multiply) {
    if (_mmkMultiply == multiply) return;
    setState(() => _mmkMultiply = multiply);
    _calculate();
  }

  Widget _buildMmkModeButton({
    required String symbol,
    required bool active,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: active ? const Color(0xFF00897B) : const Color(0xFFF5F5F5),
          border: Border.all(
            color: active ? Colors.transparent : Colors.black,
            width: 1.5,
          ),
        ),
        child: Text(
          symbol,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: active ? Colors.white : const Color(0xFF808080),
          ),
        ),
      ),
    );
  }

  Widget _buildMmkToCnyScreen() {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        centerTitle: true,
        automaticallyImplyLeading: false,
        backgroundColor: const Color(0xFF00796B),
        foregroundColor: Colors.white,
        title: Text(
          'MMK to ${CurConvSettings.currencyShortName(_currencyPair)}',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              child: Column(
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: _buildTextField(
                          controller: _mmkYuanController,
                          labelText:
                              '${CurConvSettings.currencyName(_currencyPair).replaceAll('တရုတ်', '').trim()} မှ ကျပ်',
                          fieldKey: const ValueKey<String>('swipe-yuan-input'),
                          clearKey: const ValueKey<String>(
                            'swipe-yuan-input-clear',
                          ),
                          onClear: () {
                            _mmkYuanController.clear();
                            setState(
                              () => _activeController = _mmkYuanController,
                            );
                            _calculate();
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildTextField(
                          controller: _mmkKyatController,
                          labelText:
                              'ကျပ် မှ ${CurConvSettings.currencyName(_currencyPair).replaceAll('တရုတ်', '').trim()}',
                          fieldKey: const ValueKey<String>('swipe-kyat-input'),
                          clearKey: const ValueKey<String>(
                            'swipe-kyat-input-clear',
                          ),
                          onClear: () {
                            _mmkKyatController.clear();
                            setState(
                              () => _activeController = _mmkKyatController,
                            );
                            _calculate();
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: <Widget>[
                      Expanded(
                        flex: 1,
                        child: Align(
                          alignment: Alignment.center,
                          child: _buildMmkModeButton(
                            symbol: '÷',
                            active: !_mmkMultiply,
                            onTap: () => _setMmkMode(false),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: _buildTextField(
                          controller: _mmkToCnyRateController,
                          labelText:
                              '${CurConvSettings.currencyName(_currencyPair).replaceAll('တရုတ်', '').trim()} ရောင်းဈေး',
                          fieldKey: const ValueKey<String>('swipe-rate-input'),
                          clearKey: const ValueKey<String>(
                            'swipe-rate-input-clear',
                          ),
                          clearIcon: Icons.save_outlined,
                          clearIconColor: const Color(0xFF00796B),
                          onClear: () => _saveSwipeRate(),
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Align(
                          alignment: Alignment.center,
                          child: _buildMmkModeButton(
                            symbol: '×',
                            active: _mmkMultiply,
                            onTap: () => _setMmkMode(true),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: <Widget>[
                      Expanded(child: _buildSwipeCopyCard(yuanToKyat: true)),
                      const SizedBox(width: 8),
                      Expanded(child: _buildSwipeCopyCard(yuanToKyat: false)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          _buildCustomKeypad(),
        ],
      ),
    );
  }

  Widget _buildTopDashboardCard({
    required String iconAsset,
    required String text,
    Color? textColor,
    required Color bgColor,
  }) {
    return Container(
      height: 45,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        mainAxisSize: MainAxisSize.max,
        children: [
          Transform.translate(
            offset: const Offset(0, -4),
            child: SizedBox(
              height: 35,
              child: Center(
                child: SizedBox(
                  width: iconAsset.endsWith('cash_transfer.webp') ? 37 : 36,
                  height: iconAsset.endsWith('cash_transfer.webp') ? 19 : 18,
                  child: Image.asset(iconAsset, fit: BoxFit.contain),
                ),
              ),
            ),
          ),
          Transform.translate(
            offset: const Offset(0, -11),
            child: FittedBox(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: textColor ?? Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard({
    required String titleText,
    required Color bgColor,
    required bool isSendAvailable,
    LayerLink? sendLayerLink,
    VoidCallback? onSend,
    required VoidCallback onCopy,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            titleText,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 13,
              height: 1.3,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          if (isSendAvailable)
            Row(
              children: [
                CompositedTransformTarget(
                  key: sendLayerLink == _a1SendLayerLink
                      ? _a1SendTargetKey
                      : _a2SendTargetKey,
                  link: sendLayerLink ?? LayerLink(),
                  child: SizedBox(
                    width: 42,
                    child: ElevatedButton(
                      onPressed: onSend,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: bgColor,
                        elevation: 0,
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        '➤',
                        style: TextStyle(
                          color: bgColor,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onCopy,
                    icon: const Icon(Icons.copy_rounded, size: 13),
                    label: const Text(
                      'Copy',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: bgColor,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            )
          else
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onCopy,
                icon: const Icon(Icons.copy_rounded, size: 13),
                label: const Text(
                  'Copy',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: bgColor,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAlphabetKeypad() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final _KeyboardPalette palette = _keyboardPalette;
        final double keyWidth =
            ((constraints.maxWidth - 86) / 10).clamp(18.0, 34.0).toDouble();

        Widget letterRow(String letters, {double inset = 0}) {
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: inset),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: letters.split('').map((letter) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3.5),
                  child: SizedBox(
                    width: keyWidth,
                    height: 39,
                    child: Material(
                      color: palette.letterKeyColor,
                      elevation: 1.5,
                      shadowColor: palette.shadowColor.withAlpha(46),
                      borderRadius: BorderRadius.circular(6),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(6),
                        onTap: () => _selectCodeLetter(letter),
                        child: Center(
                          child: Text(
                            letter,
                            style: TextStyle(
                              color: palette.letterTextColor,
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          );
        }

        return Container(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
          decoration: BoxDecoration(
            color: palette.panelColor,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'အက္ခရာ ၂ လုံးရွေးပါ',
                      style: TextStyle(
                        color: palette.headingTextColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Container(
                    width: 44,
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    decoration: BoxDecoration(
                      color: palette.displayColor,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _selectedCode.padRight(2, '·'),
                      style: TextStyle(
                        color: palette.letterTextColor,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints.tightFor(
                      width: 32,
                      height: 30,
                    ),
                    onPressed:
                        _selectedCode.isEmpty ? null : _removeLastCodeLetter,
                    tooltip: 'နောက်ဆုံးစာလုံးဖျက်ရန်',
                    icon: const Icon(Icons.backspace_outlined, size: 17),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints.tightFor(
                      width: 32,
                      height: 30,
                    ),
                    onPressed: _closeCodeKeyboard,
                    tooltip: 'ပိတ်ရန်',
                    icon: const Icon(Icons.close_rounded, size: 18),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              letterRow('QWERTYUIOP'),
              const SizedBox(height: 9),
              letterRow('ASDFGHJKL', inset: keyWidth / 2),
              const SizedBox(height: 9),
              letterRow('ZXCVBNM', inset: keyWidth * 1.5),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCustomKeypad() {
    const List<List<String>> keys = [
      ['1', '2', '3', 'BACKSPACE'],
      ['4', '5', '6', '0000'],
      ['7', '8', '9', '00000'],
      ['0', '00', '.', '000000'],
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final _KeyboardPalette palette = _keyboardPalette;
        final double screenHeight = MediaQuery.of(context).size.height;
        final double maxKeySize = screenHeight < 820
            ? 52.0
            : screenHeight < 860
                ? 57.0
                : 62.0;
        final double keySize = ((constraints.maxWidth - 68) / 4.6)
            .clamp(42.0, maxKeySize)
            .toDouble();
        final double wideKeyWidth = keySize * 1.55;

        return Container(
          color: palette.panelColor,
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: keys.map((row) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: row.map((key) {
                    final bool isWideKey =
                        key == 'BACKSPACE' || key.startsWith('000');
                    final bool isPressed = _pressedKey == key;
                    final Widget buttonChild;

                    if (key == 'BACKSPACE') {
                      buttonChild = Icon(
                        Icons.backspace_outlined,
                        size: 25,
                        color: palette.utilityTextColor,
                      );
                    } else {
                      double fontSize = 28;
                      if (key == '0000') fontSize = 17;
                      if (key == '00000') fontSize = 15;
                      if (key == '000000') fontSize = 13;
                      if (key == '00') fontSize = 24;
                      if (key == '.') fontSize = 30;
                      buttonChild = Text(
                        key,
                        style: TextStyle(
                          fontFamily:
                              key.startsWith('000') ? 'Pyidaungsu' : 'Roboto',
                          fontSize: fontSize,
                          fontWeight: FontWeight.w900,
                          color: isWideKey
                              ? palette.utilityTextColor
                              : palette.numberTextColor,
                        ),
                      );
                    }

                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                      ),
                      child: Semantics(
                        button: true,
                        label: key == 'BACKSPACE' ? 'Backspace' : key,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTapDown: (_) => setState(() => _pressedKey = key),
                          onTapUp: (_) {
                            setState(() => _pressedKey = null);
                            if (key != 'BACKSPACE') {
                              CurConvSettings.playKeyFeedback(
                                soundEnabled: _keySoundEnabled,
                                hapticEnabled: _hapticEnabled,
                              );
                            }
                            _onKeypadTap(key);
                          },
                          onTapCancel: () => setState(() => _pressedKey = null),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 90),
                            curve: Curves.easeOut,
                            width: isWideKey ? wideKeyWidth : keySize,
                            height: keySize,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                stops: const [0.0, 0.48, 1.0],
                                colors: isWideKey
                                    ? (isPressed
                                        ? palette.utilityPressedColors
                                        : palette.utilityKeyColors)
                                    : (isPressed
                                        ? palette.numberPressedColors
                                        : palette.numberKeyColors),
                              ),
                              border: Border.all(
                                color: Colors.white.withAlpha(184),
                                width: 1.2,
                              ),
                              borderRadius: BorderRadius.circular(
                                isWideKey ? 999 : keySize / 2,
                              ),
                              boxShadow: isPressed
                                  ? [
                                      BoxShadow(
                                        color:
                                            palette.shadowColor.withAlpha(76),
                                        offset: const Offset(0, 3),
                                        blurRadius: 5,
                                      ),
                                    ]
                                  : [
                                      BoxShadow(
                                        color:
                                            palette.shadowColor.withAlpha(102),
                                        offset: const Offset(0, 7),
                                        blurRadius: 9,
                                        spreadRadius: 0.4,
                                      ),
                                      BoxShadow(
                                        color: Colors.white.withAlpha(
                                          250,
                                        ),
                                        offset: const Offset(-3, -3),
                                        blurRadius: 6,
                                      ),
                                    ],
                            ),
                            child: Center(child: buttonChild),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Map<String, dynamic>> _records = [];
  double _totalYuanSum = 0;
  String _currencyPair = CurConvSettings.defaultCurrencyPair;
  bool _thousandSeparator = CurConvSettings.defaultThousandSeparatorEnabled;
  int _roundPrecision = CurConvSettings.defaultRoundPrecisionDigits;

  @override
  void initState() {
    super.initState();
    _loadHistoryRecords();
  }

  Future<void> _loadHistoryRecords() async {
    final prefs = await SharedPreferences.getInstance();
    final String? savedPair = prefs.getString(CurConvSettings.currencyPairKey);
    final String selectedPair =
        CurConvSettings.currencyPairIds.contains(savedPair)
            ? savedPair!
            : CurConvSettings.defaultCurrencyPair;
    final List<String> historyList =
        prefs.getStringList('history_records') ?? [];

    double yuanSum = 0;
    final List<Map<String, dynamic>> loadedList = [];

    for (final item in historyList) {
      final Map<String, dynamic> record = jsonDecode(item);
      if ((record['currencyPair']?.toString() ??
              CurConvSettings.defaultCurrencyPair) ==
          selectedPair) {
        yuanSum += (record['yuan'] as num?)?.toDouble() ?? 0;
      }
      loadedList.add(record);
    }

    if (!mounted) return;
    setState(() {
      _records = loadedList;
      _totalYuanSum = yuanSum;
      _currencyPair = selectedPair;
      _thousandSeparator = prefs.getBool(
            CurConvSettings.thousandSeparatorEnabledKey,
          ) ??
          CurConvSettings.defaultThousandSeparatorEnabled;
      _roundPrecision = prefs.getInt(CurConvSettings.roundPrecisionDigitsKey) ?? CurConvSettings.defaultRoundPrecisionDigits;
    });
  }

  String _formatDisplayAmount(num value) => CurConvSettings.formatDisplayNumber(
        value,
        thousandSeparator: _thousandSeparator,
        roundPrecision: _roundPrecision,
      );

  Future<void> _deleteRecord(int index) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> historyList =
        prefs.getStringList('history_records') ?? [];

    historyList.removeAt(index);
    await prefs.setStringList('history_records', historyList);
    _loadHistoryRecords();
  }

  Future<void> _clearAllHistoryAndArchiveDailySummaries() async {
    final prefs = await SharedPreferences.getInstance();
    final Map<String, List<Map<String, dynamic>>> groupedRecords = {};

    for (final record in _records) {
      final String date = record['date']?.toString() ?? '01/10/2026';
      final String pair = record['currencyPair']?.toString() ??
          CurConvSettings.defaultCurrencyPair;
      groupedRecords.putIfAbsent('$date|$pair', () => []);
      groupedRecords['$date|$pair']!.add(record);
    }

    final List<String> archiveList =
        prefs.getStringList('archived_summaries') ?? [];
    for (final entry in groupedRecords.entries.toList().reversed) {
      final int separator = entry.key.lastIndexOf('|');
      final String date = entry.key.substring(0, separator);
      final String pair = entry.key.substring(separator + 1);
      double totalYuan = 0;
      int totalCustomer = 0;
      int totalTrader = 0;
      int totalProfit = 0;
      for (final item in entry.value) {
        totalYuan += (item['yuan'] as num?)?.toDouble() ?? 0;
        totalCustomer += (item['customer'] as num?)?.toInt() ?? 0;
        totalTrader += (item['trader'] as num?)?.toInt() ?? 0;
        totalProfit += (item['profit'] as num?)?.toInt() ?? 0;
      }
      archiveList.removeWhere((rawItem) {
        try {
          final Map<String, dynamic> savedSummary =
              jsonDecode(rawItem) as Map<String, dynamic>;
          return savedSummary['date'] == date &&
              (savedSummary['currencyPair']?.toString() ??
                      CurConvSettings.defaultCurrencyPair) ==
                  pair;
        } catch (_) {
          return false;
        }
      });
      archiveList.insert(
          0,
          jsonEncode({
            'date': date,
            'currencyPair': pair,
            'yuan': totalYuan,
            'customer': totalCustomer,
            'trader': totalTrader,
            'profit': totalProfit,
            'records': entry.value,
          }));
    }
    if (groupedRecords.isNotEmpty) {
      await prefs.setStringList('archived_summaries', archiveList);
    }
    await prefs.remove('history_records');
    if (!mounted) return;
    await _loadHistoryRecords();
    if (!mounted) return;
    _showTopNotice(context,
        'ဖျက်ပြီးပါပြီ');
  }

  Future<void> _confirmClearAllHistory() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'အသိပေးချက်',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: const Text(
            'မှတ်တမ်းတွေကို ဖျက်ပြီး တစ်ရက်စီရဲ့ ရက်ချုပ်စာရင်းတွေကို သိမ်းထားမလား?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'မဖျက်ဘူး',
                style: TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _clearAllHistoryAndArchiveDailySummaries();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'ဖျက်မည်',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _archiveDailySummary(
    String date,
    List<Map<String, dynamic>> items,
  ) async {
    final Map<String, List<Map<String, dynamic>>> byPair = {};
    for (final item in items) {
      final String pair = item['currencyPair']?.toString() ??
          CurConvSettings.defaultCurrencyPair;
      byPair.putIfAbsent(pair, () => <Map<String, dynamic>>[]).add(item);
    }
    final prefs = await SharedPreferences.getInstance();
    final List<String> archiveList =
        prefs.getStringList('archived_summaries') ?? [];
    for (final entry in byPair.entries) {
      double totalYuan = 0;
      int totalCustomer = 0;
      int totalTrader = 0;
      int totalProfit = 0;
      for (final item in entry.value) {
        totalYuan += (item['yuan'] as num?)?.toDouble() ?? 0;
        totalCustomer += (item['customer'] as num?)?.toInt() ?? 0;
        totalTrader += (item['trader'] as num?)?.toInt() ?? 0;
        totalProfit += (item['profit'] as num?)?.toInt() ?? 0;
      }
      archiveList.removeWhere((element) {
        try {
          final Map<String, dynamic> map = jsonDecode(element);
          return map['date'] == date &&
              (map['currencyPair']?.toString() ??
                      CurConvSettings.defaultCurrencyPair) ==
                  entry.key;
        } catch (_) {
          return false;
        }
      });
      archiveList.insert(
          0,
          jsonEncode({
            'date': date,
            'currencyPair': entry.key,
            'yuan': totalYuan,
            'customer': totalCustomer,
            'trader': totalTrader,
            'profit': totalProfit,
            'records': entry.value,
          }));
    }
    await prefs.setStringList('archived_summaries', archiveList);
    if (!mounted) return;
    _showTopNotice(context,
        'Saved Info သို့ ပို့ပြီးပါပြီ။');
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, List<Map<String, dynamic>>> groupedRecords = {};

    for (final record in _records) {
      final String date = record['date'] ?? '01/10/2026';
      groupedRecords.putIfAbsent(date, () => []);
      groupedRecords[date]!.add(record);
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'History',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        backgroundColor: const Color(0xFF00796B),
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const CurconvSaveInfoIcon(size: 24),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ArchiveScreen()),
              );
            },
            tooltip: 'Saved Info',
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('💴', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 4),
                Text(
                  CurConvSettings.currencyAmount(
                    _formatDisplayAmount(_totalYuanSum),
                    _currencyPair,
                  ),
                  style: const TextStyle(
                    color: Color(0xFFE53935),
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF004D40),
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              icon: const Icon(
                Icons.delete_forever_rounded,
                color: Colors.white,
                size: 22,
              ),
              onPressed: _records.isNotEmpty ? _confirmClearAllHistory : null,
              tooltip: 'Clear All History',
            ),
          ),
        ],
      ),
      body: _records.isEmpty
          ? const Center(
              child: Text(
                'သိမ်းဆည်းထားသော စာရင်းများ မရှိသေးပါ',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: groupedRecords.keys.length,
              itemBuilder: (context, dateIndex) {
                final String dateKey = groupedRecords.keys.elementAt(
                  dateIndex,
                );
                final List<Map<String, dynamic>> itemsForDate =
                    groupedRecords[dateKey]!;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 4,
                      ),
                      child: Row(
                        children: [
                          const Text('📅', style: TextStyle(fontSize: 18)),
                          const SizedBox(width: 6),
                          Text(
                            dateKey,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF00796B),
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Text(
                              '📌',
                              style: TextStyle(fontSize: 20),
                            ),
                            onPressed: () => _archiveDailySummary(
                              dateKey,
                              itemsForDate,
                            ),
                            tooltip: '🗃️ Saved info သို့ ပို့မည်',
                          ),
                        ],
                      ),
                    ),
                    ...itemsForDate.asMap().entries.map((entry) {
                      final item = entry.value;
                      final double yuanVal =
                          (item['yuan'] as num?)?.toDouble() ?? 0;
                      final double rateVal =
                          (item['rate'] as num?)?.toDouble() ?? 0;
                      final String rateText = _formatDisplayAmount(rateVal);
                      final int customerKs =
                          (item['customer'] as num?)?.toInt() ?? 0;
                      final int traderKs =
                          (item['trader'] as num?)?.toInt() ?? 0;
                      final int profitKs =
                          (item['profit'] as num?)?.toInt() ?? 0;
                      final String timeStr = item['time'] ?? '15:11:56';
                      final String recordPair =
                          item['currencyPair']?.toString() ??
                              CurConvSettings.defaultCurrencyPair;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Theme.of(context).brightness == Brightness.dark
                                ? const Color(0xFF64FFDA)
                                : const Color(0xFF00796B),
                            width: 1.8,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(10),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 4,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Text(
                                        '📤',
                                        style: TextStyle(fontSize: 14),
                                      ),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          '${_formatDisplayAmount(customerKs)} ks',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Text(
                                        '📥',
                                        style: TextStyle(fontSize: 14),
                                      ),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          '${_formatDisplayAmount(traderKs)} ks',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              flex: 4,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      _currencyFlagBadge(recordPair, width: 20),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          '${CurConvSettings.currencyAmount(_formatDisplayAmount(yuanVal), recordPair)} '
                                          '($rateText)',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Text(
                                        '⏰',
                                        style: TextStyle(fontSize: 14),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        timeStr,
                                        style: TextStyle(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSurface,
                                          fontWeight: FontWeight.w500,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              flex: 3,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      const Text(
                                        '🪙',
                                        style: TextStyle(fontSize: 13),
                                      ),
                                      const SizedBox(width: 2),
                                      Text(
                                        '${_signedAmount(_formatDisplayAmount(profitKs), profitKs)} Ks',
                                        style: TextStyle(
                                          color: Colors.green.shade700,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      if ((item['code']?.toString() ?? '')
                                          .isNotEmpty)
                                        Container(
                                          margin: const EdgeInsets.only(
                                            right: 4,
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFE8F5E9),
                                            borderRadius:
                                                BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            item['code'].toString(),
                                            style: const TextStyle(
                                              color: Color(0xFF00796B),
                                              fontSize: 12,
                                              fontWeight: FontWeight.w900,
                                              letterSpacing: 1,
                                            ),
                                          ),
                                        ),
                                      GestureDetector(
                                        onDoubleTap: () {
                                          final int realIndex =
                                              _records.indexOf(item);
                                          if (realIndex != -1) {
                                            _deleteRecord(realIndex);
                                          }
                                        },
                                        child: const Padding(
                                          padding: EdgeInsets.all(4.0),
                                          child: Icon(
                                            Icons.delete_outline_rounded,
                                            color: Colors.redAccent,
                                            size: 22,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                );
              },
            ),
    );
  }
}

class ArchiveScreen extends StatefulWidget {
  const ArchiveScreen({super.key});

  @override
  State<ArchiveScreen> createState() => _ArchiveScreenState();
}

class _ArchiveScreenState extends State<ArchiveScreen> {
  String _query = '';
  late final TextEditingController _searchController = TextEditingController();
  late final FocusNode _searchFocus = FocusNode();
  bool get _showDateFilters => _query.trim().isNotEmpty;
  bool _filterPanelOpen = false;
  bool get _showFilterControls => _showDateFilters || _filterPanelOpen;
  bool _monthlySortNewestFirst = true;
  late String _selectedYm = _currentYm();
  bool _showYearlySummary = false;
  int _selectedYear = DateTime.now().year;

  static String _currentYm() {
    final DateTime n = DateTime.now();
    return '${n.year}/${n.month.toString().padLeft(2, '0')}';
  }

  // Dropdown options: every month that has saved data, plus the current month.
  List<String> _monthOptions() {
    final Set<String> keys = <String>{_currentYm()};
    for (final Map<String, dynamic> item in _archivedSummaries) {
      final List<String> parts = (item['date']?.toString() ?? '').split('/');
      if (parts.length == 3) {
        keys.add('${parts[2]}/${parts[1].padLeft(2, '0')}');
      }
    }
    final List<String> list = keys.toList()..sort((String a, String b) => b.compareTo(a));
    return list;
  }
  List<int> _yearOptions() {
    final Set<int> years = <int>{DateTime.now().year};
    for (final Map<String, dynamic> item in _archivedSummaries) {
      final List<String> parts = (item['date']?.toString() ?? '').split('/');
      if (parts.length == 3) {
        final int? year = int.tryParse(parts[2]);
        if (year != null) years.add(year);
      }
    }
    return years.toList()..sort((int a, int b) => b.compareTo(a));
  }

  int? _filterYear;
  int? _filterMonth;

  static const List<String> _monthNames = <String>[
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  // Applies year, month and search filters to the saved daily summaries.
  List<Map<String, dynamic>> _filteredArchives({bool applySelectedMonth = true}) {
    final String q = _query.trim().toLowerCase();
    return _archivedSummaries.where((Map<String, dynamic> item) {
      final String dateStr = item['date']?.toString() ?? '';
      final List<String> parts = dateStr.split('/');
      if (parts.length != 3) return false;
      if (_showDateFilters || _filterYear != null || _filterMonth != null) {
        if (_filterYear != null && parts[2] != '$_filterYear') return false;
        if (_filterMonth != null &&
            int.tryParse(parts[1]) != _filterMonth) {
          return false;
        }
      } else if (applySelectedMonth) {
        final List<String> ym = _selectedYm.split('/');
        if (parts[2] != ym[0] || parts[1].padLeft(2, '0') != ym[1]) {
          return false;
        }
      }
      if (q.isEmpty) return true;
      final String haystack = <String>[
        dateStr,
        item['yuan']?.toString() ?? '',
        item['customer']?.toString() ?? '',
        item['trader']?.toString() ?? '',
        item['profit']?.toString() ?? '',
      ].join(' ').toLowerCase();
      return haystack.contains(q);
    }).toList();
  }

  Widget _buildArchiveControls() {
    const Color teal = Color(0xFF00695C);
    final int shownYear = _filterYear ?? DateTime.now().year;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      child: Column(
        children: <Widget>[
          SizedBox(
            height: 54,
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocus,
              onChanged: (String v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: 'လချုပ်၊ ရက်ချုပ် ရှာရန်...',
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: Colors.black54,
                  size: 24,
                ),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    if (_query.isNotEmpty)
                      IconButton(
                        tooltip: 'ရှာဖွေမှု ရှင်းရန်',
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _query = '';
                            _filterYear = null;
                            _filterMonth = null;
                          });
                        },
                      ),
                    IconButton(
                      tooltip: 'ရက်စွဲဖြင့် စစ်ထုတ်ရန်',
                      color: _filterPanelOpen
                          ? const Color(0xFF00796B)
                          : Colors.black54,
                      icon: const Icon(Icons.filter_list_rounded),
                      onPressed: () => setState(() {
                        _filterPanelOpen = !_filterPanelOpen;
                      }),
                    ),
                  ],
                ),
                isDense: true,
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFFB7DCD5), width: 1.2),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFF00796B), width: 1.6),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              SizedBox(
                width: MediaQuery.sizeOf(context).width < 380 ? 116 : 132,
                height: 46,
                child: PopupMenuButton<String>(
                  tooltip: 'လချုပ်အတွက် လ ရွေးရန်',
                  initialValue: _selectedYm,
                  color: Colors.white,
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  onSelected: (String month) => setState(() {
                    _selectedYm = month;
                    _showYearlySummary = false;
                  }),
                  itemBuilder: (BuildContext context) => _monthOptions()
                      .map((String month) => PopupMenuItem<String>(
                            value: month,
                            child: Container(
                              width: 112,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 7),
                              decoration: BoxDecoration(
                                color: month == _selectedYm && !_showYearlySummary
                                    ? const Color(0xFFE8F5E9)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(9),
                              ),
                              child: Text(
                                month,
                                style: const TextStyle(
                                  color: Color(0xFF00695C),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ))
                      .toList(),
                  child: Container(
                    decoration: BoxDecoration(
                      color: !_showYearlySummary
                          ? const Color(0xFFE8F5E9)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: teal, width: 1.7),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Flexible(
                          child: Text(
                            _selectedYm,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: teal,
                              fontWeight: FontWeight.w800,
                              fontSize: 17,
                            ),
                          ),
                        ),
                        const Icon(Icons.keyboard_arrow_down_rounded,
                            color: teal, size: 24),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: MediaQuery.sizeOf(context).width < 380 ? 116 : 132,
                height: 46,
                child: PopupMenuButton<int>(
                  tooltip: 'နှစ်ချုပ်အတွက် နှစ်ရွေးရန်',
                  initialValue: _selectedYear,
                  color: Colors.white,
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  onSelected: (int year) => setState(() {
                    _selectedYear = year;
                    _showYearlySummary = true;
                  }),
                  itemBuilder: (BuildContext context) => _yearOptions()
                      .map((int year) => PopupMenuItem<int>(
                            value: year,
                            child: Container(
                              width: 124,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 7),
                              decoration: BoxDecoration(
                                color: year == _selectedYear && _showYearlySummary
                                    ? const Color(0xFFE8F5E9)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(9),
                              ),
                              child: Text(
                                '$year နှစ်ချုပ်',
                                style: const TextStyle(
                                  color: Color(0xFF00695C),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ))
                      .toList(),
                  child: Container(
                    decoration: BoxDecoration(
                      color: _showYearlySummary
                          ? const Color(0xFFE8F5E9)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: teal, width: 1.7),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Flexible(
                          child: Text(
                            'နှစ်ချုပ်',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: teal,
                              fontWeight: FontWeight.w800,
                              fontSize: 17,
                            ),
                          ),
                        ),
                        Icon(Icons.keyboard_arrow_down_rounded,
                            color: teal, size: 24),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (_showFilterControls) ...<Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              IconButton(
                icon: const Icon(Icons.chevron_left_rounded),
                onPressed: () => setState(() {
                  _filterYear = shownYear - 1;
                }),
              ),
              GestureDetector(
                onTap: () => setState(() {
                  _filterYear = null;
                  _filterMonth = null;
                }),
                child: Text(
                  _filterYear == null ? 'အားလုံး' : '$shownYear',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right_rounded),
                onPressed: () => setState(() {
                  _filterYear = shownYear + 1;
                }),
              ),
            ],
          ),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 6,
            runSpacing: 6,
            children: <Widget>[
              for (int m = 1; m <= 12; m++)
                GestureDetector(
                  onTap: () => setState(() {
                    _filterMonth = _filterMonth == m ? null : m;
                  }),
                  child: Container(
                    width: 64,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: _filterMonth == m ? teal : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: teal, width: 1),
                    ),
                    child: Text(
                      _monthNames[m - 1],
                      style: TextStyle(
                        color: _filterMonth == m ? Colors.white : teal,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          ],
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _archivedSummaries = [];
  bool _thousandSeparator = CurConvSettings.defaultThousandSeparatorEnabled;
  int _roundPrecision = CurConvSettings.defaultRoundPrecisionDigits;

  @override
  void initState() {
    super.initState();
    _loadArchives();
  }

  Future<void> _loadArchives() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> rawList =
        prefs.getStringList('archived_summaries') ?? [];

    final List<Map<String, dynamic>> parsedList = [];
    for (final item in rawList) {
      parsedList.add(jsonDecode(item));
    }

    if (!mounted) return;
    setState(() {
      _archivedSummaries = parsedList;
      _thousandSeparator = prefs.getBool(
            CurConvSettings.thousandSeparatorEnabledKey,
          ) ??
          CurConvSettings.defaultThousandSeparatorEnabled;
      _roundPrecision = prefs.getInt(CurConvSettings.roundPrecisionDigitsKey) ?? CurConvSettings.defaultRoundPrecisionDigits;
    });
  }

  void _openDailySummary(Map<String, dynamic> summary) {
    final Object? rawRecords = summary['records'];
    final List<Map<String, dynamic>> records = rawRecords is List
        ? rawRecords
            .whereType<Map>()
            .map((record) => Map<String, dynamic>.from(record))
            .toList()
        : <Map<String, dynamic>>[];

    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (context) => ArchivedDayDetailsScreen(
          summary: summary,
          records: records,
          thousandSeparator: _thousandSeparator,
          roundPrecision: _roundPrecision,
        ),
      ),
    );
  }

  Future<void> _deleteArchive(int index) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> rawList =
        prefs.getStringList('archived_summaries') ?? [];

    rawList.removeAt(index);
    await prefs.setStringList('archived_summaries', rawList);
    _loadArchives();
  }

  String _formatSummaryNumber(num value) => CurConvSettings.formatDisplayNumber(
        value,
        thousandSeparator: _thousandSeparator,
        roundPrecision: _roundPrecision,
      );

  Widget _buildArchiveAmountTile({
    required Widget icon,
    required String label,
    required int amount,
    bool isProfit = false,
  }) {
    final Color highlight = isProfit ? const Color(0xFFFFE082) : Colors.white;
    return Container(
      constraints: const BoxConstraints(minHeight: 106),
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.tealAccent.withValues(alpha: 0.35)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 34,
            height: 34,
            child: FittedBox(fit: BoxFit.contain, child: icon),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isProfit ? const Color(0xFFFFE082) : Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: double.infinity,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                '${_formatSummaryNumber(amount)} Ks',
                maxLines: 1,
                softWrap: false,
                style: TextStyle(
                  color: highlight,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final Map<String, List<Map<String, dynamic>>> monthlyGroups = {};

    final List<Map<String, dynamic>> filteredItems = _filteredArchives(
      applySelectedMonth: !_showYearlySummary,
    );
    for (final item in filteredItems) {
      final String dateStr = item['date'] ?? '';
      final List<String> parts = dateStr.split('/');
      final String monthKey =
          parts.length == 3 ? "${parts[1]}/${parts[2]}" : "အခြား";
      final String pair = item['currencyPair']?.toString() ??
          CurConvSettings.defaultCurrencyPair;
      final String groupKey = '$monthKey|$pair';
      monthlyGroups.putIfAbsent(groupKey, () => []);
      monthlyGroups[groupKey]!.add(item);
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            CurconvSaveInfoIcon(size: 24),
            SizedBox(width: 8),
            Flexible(
              child: Text(
                'Saved Info',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF00796B),
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
      ),
      body: Column(
        children: <Widget>[
          _buildArchiveControls(),
          Expanded(
            child: _showYearlySummary
                ? YearlySummaryScreen(
                    year: _selectedYear,
                    summaries: filteredItems,
                    thousandSeparator: _thousandSeparator,
                    roundPrecision: _roundPrecision,
                    monthlySortNewestFirst: _monthlySortNewestFirst,
                    onMonthlySortChanged: (bool newestFirst) => setState(() {
                      _monthlySortNewestFirst = newestFirst;
                    }),
                  )
                : filteredItems.isEmpty
          ? const Center(
              child: Text(
                '🗃️ သိမ်းဆည်းထားသော ရက်ချုပ်စာရင်းများ မရှိသေးပါ',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: monthlyGroups.keys.length,
              itemBuilder: (context, mIndex) {
                final String groupKey = monthlyGroups.keys.elementAt(mIndex);
                final List<String> groupParts = groupKey.split('|');
                final String monthKey = groupParts.first;
                final String monthPair = groupParts.length > 1
                    ? groupParts.last
                    : CurConvSettings.defaultCurrencyPair;
                final List<Map<String, dynamic>> monthItems =
                    monthlyGroups[groupKey]!;

                double mYuan = 0;
                int mCustomer = 0;
                int mTrader = 0;
                int mProfit = 0;

                for (final item in monthItems) {
                  mYuan += (item['yuan'] as num?)?.toDouble() ?? 0;
                  mCustomer += (item['customer'] as num?)?.toInt() ?? 0;
                  mTrader += (item['trader'] as num?)?.toInt() ?? 0;
                  mProfit += (item['profit'] as num?)?.toInt() ?? 0;
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF004D40), Color(0xFF00695C)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: Colors.tealAccent.shade100),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x33004D40),
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              _currencyFlagBadge(monthPair, width: 40),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '$monthKey ${CurConvSettings.currencyName(monthPair)} လချုပ်စာရင်း',
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      CurConvSettings.currencyAmount(
                                        _formatSummaryNumber(mYuan),
                                        monthPair,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 30,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: _buildArchiveAmountTile(
                                  icon: RotatedBox(
                                    quarterTurns: 3,
                                    child: const Text(
                                      '➻',
                                      style: TextStyle(
                                        color: Color(0xFF69F0AE),
                                        fontSize: 44,
                                        height: 1,
                                      ),
                                    ),
                                  ),
                                  label: 'ထွက်ငွေ',
                                  amount: mCustomer,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _buildArchiveAmountTile(
                                  icon: RotatedBox(
                                    quarterTurns: 1,
                                    child: const Text(
                                      '➺',
                                      style: TextStyle(
                                        color: Color(0xFF69F0AE),
                                        fontSize: 44,
                                        height: 1,
                                      ),
                                    ),
                                  ),
                                  label: 'ဝင်ငွေ',
                                  amount: mTrader,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF00796B),
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                color: const Color(0xFFFFD54F),
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              children: [
                                Image.asset(
                                  'assets/images/profit_graph.webp',
                                  width: 38,
                                  height: 38,
                                  fit: BoxFit.contain,
                                ),
                                const SizedBox(width: 12),
                                Flexible(
                                  flex: 2,
                                  fit: FlexFit.loose,
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerLeft,
                                    child: const Text(
                                      'အမြတ်ငွေ',
                                      maxLines: 1,
                                      softWrap: false,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  flex: 3,
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerRight,
                                    child: Text(
                                      '${_signedAmount(_formatSummaryNumber(mProfit), mProfit)} Ks',
                                      maxLines: 1,
                                      textAlign: TextAlign.right,
                                      style: const TextStyle(
                                        color: Color(0xFFFFE082),
                                        fontSize: 23,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    ...monthItems.map((item) {
                      final double yuanVal =
                          (item['yuan'] as num?)?.toDouble() ?? 0;
                      final int customerKs =
                          (item['customer'] as num?)?.toInt() ?? 0;
                      final int traderKs =
                          (item['trader'] as num?)?.toInt() ?? 0;
                      final int profitKs =
                          (item['profit'] as num?)?.toInt() ?? 0;
                      final String dateStr = item['date'] ?? '';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.teal.shade100),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: () => _openDailySummary(item),
                                borderRadius: BorderRadius.circular(8),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 4,
                                    horizontal: 2,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '📅 $dateStr ရက်ချုပ်စာရင်း',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: Color(0xFF00796B),
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          _currencyFlagBadge(monthPair,
                                              width: 22),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${CurConvSettings.currencyName(monthPair)}: '
                                            '${CurConvSettings.currencyAmount(_formatSummaryNumber(yuanVal), monthPair)}',
                                            style: const TextStyle(
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Text(
                                        '📤 ထွက်ငွေ: ${_formatSummaryNumber(customerKs)} Ks | '
                                        '📥 ဝင်ငွေ: ${_formatSummaryNumber(traderKs)} Ks',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      const Text(
                                        'အသေးစိတ်ကြည့်ရန် နှိပ်ပါ',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Color(0xFF00796B),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '${_signedAmount(_formatSummaryNumber(profitKs), profitKs)} Ks',
                                  style: TextStyle(
                                    color: Colors.green.shade700,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                GestureDetector(
                                  onDoubleTap: () {
                                    final int realIdx =
                                        _archivedSummaries.indexOf(item);
                                    if (realIdx != -1) {
                                      _deleteArchive(realIdx);
                                    }
                                  },
                                  child: const Icon(
                                    Icons.delete_outline_rounded,
                                    color: Colors.redAccent,
                                    size: 20,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class YearlySummaryScreen extends StatelessWidget {
  const YearlySummaryScreen({
    super.key,
    required this.year,
    required this.summaries,
    required this.thousandSeparator,
    required this.roundPrecision,
    required this.monthlySortNewestFirst,
    required this.onMonthlySortChanged,
  });

  final int year;
  final List<Map<String, dynamic>> summaries;
  final bool thousandSeparator;
  final int roundPrecision;
  final bool monthlySortNewestFirst;
  final ValueChanged<bool> onMonthlySortChanged;

  String _format(num value) => CurConvSettings.formatDisplayNumber(
        value,
        thousandSeparator: thousandSeparator,
        roundPrecision: roundPrecision,
      );

  void _openDay(BuildContext context, Map<String, dynamic> summary) {
    final Object? rawRecords = summary['records'];
    final List<Map<String, dynamic>> records = rawRecords is List
        ? rawRecords
            .whereType<Map>()
            .map((Map record) => Map<String, dynamic>.from(record))
            .toList()
        : <Map<String, dynamic>>[];
    Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (BuildContext context) => ArchivedDayDetailsScreen(
          summary: summary,
          records: records,
          thousandSeparator: thousandSeparator,
          roundPrecision: roundPrecision,
        ),
      ),
    );
  }

  Widget _annualAmountTile({
    required Widget icon,
    required String label,
    required int amount,
    Color amountColor = Colors.white,
    Color labelColor = Colors.white70,
  }) {
    return Container(
      constraints: const BoxConstraints(minHeight: 112),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.tealAccent.withValues(alpha: 0.35)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          SizedBox(
            width: 40,
            height: 40,
            child: FittedBox(fit: BoxFit.contain, child: icon),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: labelColor,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 3),
          SizedBox(
            width: double.infinity,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                '${_format(amount)} Ks',
                maxLines: 1,
                softWrap: false,
                style: TextStyle(
                  color: amountColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> yearItems = summaries.where((item) {
      final List<String> parts = (item['date']?.toString() ?? '').split('/');
      return parts.length == 3 && parts[2] == '$year';
    }).toList()
      ..sort((Map<String, dynamic> a, Map<String, dynamic> b) =>
          (b['date']?.toString() ?? '').compareTo(a['date']?.toString() ?? ''));
    final Map<String, List<Map<String, dynamic>>> byPair =
        <String, List<Map<String, dynamic>>>{};
    for (final Map<String, dynamic> item in yearItems) {
      final String pair = item['currencyPair']?.toString() ??
          CurConvSettings.defaultCurrencyPair;
      byPair.putIfAbsent(pair, () => <Map<String, dynamic>>[]).add(item);
    }

    if (yearItems.isEmpty) {
      return Center(child: Text('$year ခုနှစ်အတွက် စာရင်းမရှိသေးပါ'));
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
      children: <Widget>[
        ...byPair.entries.map((entry) {
        double totalYuan = 0;
        int totalOut = 0;
        int totalIn = 0;
        int totalProfit = 0;
        final Map<String, List<Map<String, dynamic>>> byMonth =
            <String, List<Map<String, dynamic>>>{};
        for (final Map<String, dynamic> item in entry.value) {
          totalYuan += (item['yuan'] as num?)?.toDouble() ?? 0;
          totalOut += (item['customer'] as num?)?.toInt() ?? 0;
          totalIn += (item['trader'] as num?)?.toInt() ?? 0;
          totalProfit += (item['profit'] as num?)?.toInt() ?? 0;
          final List<String> dateParts =
              (item['date']?.toString() ?? '').split('/');
          final String monthKey = dateParts.length == 3
              ? '${dateParts[2]}/${dateParts[1].padLeft(2, '0')}'
              : 'အခြား';
          byMonth.putIfAbsent(monthKey, () => <Map<String, dynamic>>[]).add(item);
        }
        final List<String> monthKeys = byMonth.keys.toList()
          ..sort((String a, String b) => monthlySortNewestFirst
              ? b.compareTo(a)
              : a.compareTo(b));
        final String pairName = CurConvSettings.currencyName(entry.key);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF004D40), Color(0xFF00695C)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: Colors.tealAccent.shade100),
                boxShadow: const <BoxShadow>[
                  BoxShadow(
                    color: Color(0x33004D40),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      _currencyFlagBadge(entry.key, width: 36),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              '$year $pairName နှစ်ချုပ်စာရင်း',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              CurConvSettings.currencyAmount(_format(totalYuan), entry.key),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 30,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.trending_up_rounded,
                        color: Color(0xFF69F0AE),
                        size: 44,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: _annualAmountTile(
                          icon: RotatedBox(
                            quarterTurns: 3,
                            child: const Text(
                              '➻',
                              style: TextStyle(
                                color: Color(0xFF69F0AE),
                                fontSize: 47,
                                height: 1,
                              ),
                            ),
                          ),
                          label: 'ထွက်ငွေ',
                          amount: totalOut,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _annualAmountTile(
                          icon: RotatedBox(
                            quarterTurns: 1,
                            child: const Text(
                              '➺',
                              style: TextStyle(
                                color: Color(0xFF69F0AE),
                                fontSize: 47,
                                height: 1,
                              ),
                            ),
                          ),
                          label: 'ဝင်ငွေ',
                          amount: totalIn,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 13,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00796B),
                      borderRadius: BorderRadius.circular(36),
                      border: Border.all(
                        color: const Color(0xFFFFD54F),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: <Widget>[
                        Image.asset(
                          'assets/images/profit_graph.webp',
                          width: 42,
                          height: 42,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(width: 10),
                        const Flexible(
                          child: Text(
                            'အမြတ်ငွေ',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerRight,
                            child: Text(
                              '${_signedAmount(_format(totalProfit), totalProfit)} Ks',
                              maxLines: 1,
                              softWrap: false,
                              style: const TextStyle(
                                color: Color(0xFFFFE082),
                                fontSize: 23,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            ...monthKeys.map((String monthKey) {
              final List<Map<String, dynamic>> monthItems = byMonth[monthKey]!;
              double monthYuan = 0;
              int monthOut = 0;
              int monthIn = 0;
              int monthProfit = 0;
              for (final Map<String, dynamic> item in monthItems) {
                monthYuan += (item['yuan'] as num?)?.toDouble() ?? 0;
                monthOut += (item['customer'] as num?)?.toInt() ?? 0;
                monthIn += (item['trader'] as num?)?.toInt() ?? 0;
                monthProfit += (item['profit'] as num?)?.toInt() ?? 0;
              }
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(color: Colors.teal.shade100),
                ),
                child: ExpansionTile(
                  backgroundColor: const Color(0xFFEAF5F2),
                  collapsedBackgroundColor: Colors.transparent,
                  title: Row(
                    children: <Widget>[
                      Text(
                        monthKey,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF00695C),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          CurConvSettings.currencyAmount(
                            _format(monthYuan),
                            entry.key,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.left,
                          style: const TextStyle(
                            color: Color(0xFF263238),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${_signedAmount(_format(monthProfit), monthProfit)} Ks',
                        maxLines: 1,
                        softWrap: false,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          color: monthProfit >= 0
                              ? const Color(0xFF2E7D32)
                              : const Color(0xFFC62828),
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  subtitle: Row(
                    children: <Widget>[
                      const Icon(
                        Icons.calendar_month_rounded,
                        color: Color(0xFF00796B),
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'ဝင်ငွေ ${_format(monthIn)} Ks',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.left,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          'ထွက်ငွေ ${_format(monthOut)} Ks',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.right,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  children: <Widget>[
                    ...monthItems.map((Map<String, dynamic> item) {
                      final double dayYuan =
                          (item['yuan'] as num?)?.toDouble() ?? 0;
                      final int dayOut =
                          (item['customer'] as num?)?.toInt() ?? 0;
                      final int dayIn = (item['trader'] as num?)?.toInt() ?? 0;
                      final int dayProfit =
                          (item['profit'] as num?)?.toInt() ?? 0;
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () => _openDay(context, item),
                            child: Ink(
                              decoration: BoxDecoration(
                                color: const Color(0xFFF3F8F6),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFFB2DFDB),
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                child: Column(
                                  children: <Widget>[
                                    Row(
                                      children: <Widget>[
                                        Expanded(
                                          child: Row(
                                            children: <Widget>[
                                              Text(
                                                '${item['date'] ?? ''}',
                                                maxLines: 1,
                                                style: const TextStyle(
                                                  color: Color(0xFF263238),
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              const SizedBox(width: 7),
                                              Expanded(
                                                child: Text(
                                                  CurConvSettings.currencyAmount(
                                                    _format(dayYuan),
                                                    entry.key,
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                    color: Color(0xFF263238),
                                                    fontSize: 13,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          '${_signedAmount(_format(dayProfit), dayProfit)} Ks',
                                          maxLines: 1,
                                          style: const TextStyle(
                                            color: Color(0xFF00796B),
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: <Widget>[
                                        Expanded(
                                          child: Text(
                                            'ဝင်ငွေ ${_format(dayIn)} Ks',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              color: Color(0xFF546E7A),
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: Text(
                                            'ထွက်ငွေ ${_format(dayOut)} Ks',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            textAlign: TextAlign.right,
                                            style: const TextStyle(
                                              color: Color(0xFF546E7A),
                                              fontSize: 12,
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
                        ),
                      );
                    }),
                  ],
                ),
              );
            }),
          ],
        );
        }).toList(),
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 8, 4, 16),
          child: Align(
            alignment: Alignment.centerRight,
            child: PopupMenuButton<bool>(
              tooltip: 'လချုပ်စာရင်း စီရန်',
              initialValue: monthlySortNewestFirst,
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              onSelected: onMonthlySortChanged,
              itemBuilder: (BuildContext context) => <PopupMenuEntry<bool>>[
                const PopupMenuItem<bool>(
                  value: true,
                  child: Text('အသစ်ဆုံးကို အရင်ပြရန်'),
                ),
                const PopupMenuItem<bool>(
                  value: false,
                  child: Text('အဟောင်းဆုံးကို အရင်ပြရန်'),
                ),
              ],
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.teal.shade200),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const Icon(Icons.sort_rounded, color: Color(0xFF00695C)),
                    const SizedBox(width: 7),
                    Text(
                      monthlySortNewestFirst
                          ? 'စီရန်: အသစ်ဆုံး အရင်'
                          : 'စီရန်: အဟောင်းဆုံး အရင်',
                      style: const TextStyle(
                        color: Color(0xFF00695C),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: Color(0xFF00695C),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class ArchivedDayDetailsScreen extends StatelessWidget {
  const ArchivedDayDetailsScreen({
    super.key,
    required this.summary,
    required this.records,
    required this.thousandSeparator,
    required this.roundPrecision,
  });

  final Map<String, dynamic> summary;
  final List<Map<String, dynamic>> records;
  final bool thousandSeparator;
  final int roundPrecision;

  @override
  Widget build(BuildContext context) {
    final String date = summary['date']?.toString() ?? '';
    final String summaryPair = summary['currencyPair']?.toString() ??
        CurConvSettings.defaultCurrencyPair;
    final double yuan = (summary['yuan'] as num?)?.toDouble() ?? 0;
    final int customer = (summary['customer'] as num?)?.toInt() ?? 0;
    final int trader = (summary['trader'] as num?)?.toInt() ?? 0;
    final int profit = (summary['profit'] as num?)?.toInt() ?? 0;

    String formatSummaryNumber(num value) =>
        CurConvSettings.formatDisplayNumber(
          value,
          thousandSeparator: thousandSeparator,
          roundPrecision: roundPrecision,
        );

    Widget dailyAmountTile({
      required Widget icon,
      required String label,
      required int amount,
      bool isProfit = false,
    }) {
      final Color valueColor =
          isProfit ? const Color(0xFFFFE082) : Colors.white;
      final Color labelColor =
          isProfit ? const Color(0xFFFFE082) : Colors.white70;
      return Container(
        constraints: const BoxConstraints(minHeight: 106),
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.tealAccent.withValues(alpha: 0.35)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 34,
              height: 34,
              child: FittedBox(fit: BoxFit.contain, child: icon),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: labelColor,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            SizedBox(
              width: double.infinity,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  '${formatSummaryNumber(amount)} Ks',
                  maxLines: 1,
                  softWrap: false,
                  style: TextStyle(
                    color: valueColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    Widget infoCell(
      String icon,
      String value, {
      double fontSize = 14,
      double iconFontSize = 14,
      double letterSpacing = 0,
      Color? color,
      FontWeight fontWeight = FontWeight.normal,
      TextAlign textAlign = TextAlign.left,
    }) {
      return Row(
        children: [
          if (icon.isNotEmpty)
            CurConvSettings.currencyPairIds.contains(icon)
                ? _currencyFlagBadge(icon, width: iconFontSize * 1.5)
                : Text(icon, style: TextStyle(fontSize: iconFontSize)),
          if (icon.isNotEmpty) const SizedBox(width: 3),
          Expanded(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: textAlign,
              style: TextStyle(
                fontSize: fontSize,
                letterSpacing: letterSpacing,
                color: color ?? Theme.of(context).colorScheme.onSurface,
                fontWeight: fontWeight,
              ),
            ),
          ),
        ],
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          '$date ရက်ချုပ် စာရင်း',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF00796B),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: double.infinity),
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF004D40), Color(0xFF00695C)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: Colors.tealAccent.shade100),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x33004D40),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _currencyFlagBadge(summaryPair, width: 36),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$date ${CurConvSettings.currencyName(summaryPair)} ရက်ချုပ်စာရင်း',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                CurConvSettings.currencyAmount(
                                  formatSummaryNumber(yuan),
                                  summaryPair,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 30,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.trending_up_rounded,
                          color: Color(0xFF69F0AE),
                          size: 44,
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: dailyAmountTile(
                            icon: RotatedBox(
                              quarterTurns: 1,
                              child: const Text(
                                '➺',
                                style: TextStyle(
                                  color: Color(0xFF69F0AE),
                                  fontSize: 42,
                                  height: 1,
                                ),
                              ),
                            ),
                            label: 'ဝင်ငွေ',
                            amount: trader,
                          ),
                        ),
                        const SizedBox(width: 7),
                        Expanded(
                          child: dailyAmountTile(
                            icon: RotatedBox(
                              quarterTurns: 3,
                              child: const Text(
                                '➻',
                                style: TextStyle(
                                  color: Color(0xFF69F0AE),
                                  fontSize: 42,
                                  height: 1,
                                ),
                              ),
                            ),
                            label: 'ထွက်ငွေ',
                            amount: customer,
                          ),
                        ),
                        const SizedBox(width: 7),
                        Expanded(
                          child: dailyAmountTile(
                            icon: Image.asset(
                              'assets/images/profit_graph.webp',
                              fit: BoxFit.contain,
                            ),
                            label: 'အမြတ်ငွေ',
                            amount: profit,
                            isProfit: true,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: records.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'ဒီရက်ချုပ်စာရင်းကို သိမ်းတဲ့အချိန်မှာ တစ်ခုချင်းစီရဲ့ '
                        'အသေးစိတ်မှတ်တမ်းကို မသိမ်းထားခဲ့လို့ ပြန်ကြည့်လို့ မရပါ။\n\n'
                        'နောက်တစ်ခါ Clear All History မလုပ်ခင် သိမ်းထားတဲ့ '
                        'ရက်ချုပ်စာရင်းတွေမှာတော့ အသေးစိတ်ကို နှိပ်ပြီး ကြည့်နိုင်ပါမယ်။',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    itemCount: records.length,
                    itemBuilder: (context, index) {
                      final Map<String, dynamic> record = records[index];
                      final double recordYuan =
                          (record['yuan'] as num?)?.toDouble() ?? 0;
                      final double rate =
                          (record['rate'] as num?)?.toDouble() ?? 0;
                      final int recordCustomer =
                          (record['customer'] as num?)?.toInt() ?? 0;
                      final int recordTrader =
                          (record['trader'] as num?)?.toInt() ?? 0;
                      final int recordProfit =
                          (record['profit'] as num?)?.toInt() ?? 0;
                      final String time = record['time']?.toString() ?? '';
                      final String code = record['code']?.toString() ?? '';
                      final String recordPair =
                          record['currencyPair']?.toString() ??
                              CurConvSettings.defaultCurrencyPair;

                      return Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxWidth: double.infinity,
                          ),
                          child: Card(
                            color: Theme.of(context).colorScheme.surface,
                            margin: const EdgeInsets.only(bottom: 7),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: SizedBox(
                              height: 60,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 4,
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          infoCell(
                                            '📤',
                                            '${formatSummaryNumber(recordCustomer)} Ks',
                                            fontWeight: FontWeight.bold,
                                          ),
                                          const SizedBox(height: 4),
                                          infoCell(
                                            '📥',
                                            '${formatSummaryNumber(recordTrader)} Ks',
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      flex: 4,
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          infoCell(
                                            recordPair,
                                            '${CurConvSettings.currencyAmount(formatSummaryNumber(recordYuan), recordPair)} (${formatSummaryNumber(rate)})',
                                            fontWeight: FontWeight.bold,
                                          ),
                                          const SizedBox(height: 4),
                                          infoCell(
                                            '⏰',
                                            time.isEmpty ? '—' : time,
                                            fontSize: 14,
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.onSurface,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      flex: 3,
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            mainAxisAlignment:
                                                MainAxisAlignment.end,
                                            children: [
                                              const Text(
                                                '🪙',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                ),
                                              ),
                                              const SizedBox(width: 2),
                                              Flexible(
                                                child: Text(
                                                  '+$recordProfit',
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                    color:
                                                        Colors.green.shade700,
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          infoCell(
                                            '',
                                            code,
                                            fontSize: 14,
                                            letterSpacing: 1,
                                            color: const Color(0xFF00796B),
                                            fontWeight: FontWeight.w900,
                                            textAlign: TextAlign.right,
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
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}


class _AboutUpdateDialog extends StatefulWidget {
  const _AboutUpdateDialog();

  @override
  State<_AboutUpdateDialog> createState() => _AboutUpdateDialogState();
}

class _AboutUpdateDialogState extends State<_AboutUpdateDialog> {
  static const String _latestReleaseApi =
      'https://api.github.com/repos/aungkhinwin/curconv-updates/releases/latest';

  bool _checking = false;
  bool _checked = false;
  bool _downloading = false;
  double _downloadProgress = 0;
  String? _latestVersion;
  String? _apkUrl;
  String? _error;

  bool get _hasUpdate =>
      _latestVersion != null &&
      _compareVersions(_latestVersion!, curconvAppVersion) > 0;

  int _compareVersions(String a, String b) {
    List<int> parts(String value) => value
        .replaceFirst(RegExp(r'^[vV]'), '')
        .split('.')
        .map((part) => int.tryParse(part) ?? 0)
        .toList();
    final aa = parts(a);
    final bb = parts(b);
    for (var i = 0; i < (aa.length > bb.length ? aa.length : bb.length); i++) {
      final av = i < aa.length ? aa[i] : 0;
      final bv = i < bb.length ? bb[i] : 0;
      if (av != bv) return av.compareTo(bv);
    }
    return 0;
  }

  Future<void> _checkForUpdates() async {
    if (_checking) return;
    setState(() {
      _checking = true;
      _error = null;
    });
    HttpClient? client;
    try {
      client = HttpClient()..connectionTimeout = const Duration(seconds: 15);
      final request = await client.getUrl(Uri.parse(_latestReleaseApi));
      request.headers.set(HttpHeaders.userAgentHeader, 'CurConv-Android-App');
      request.headers.set(HttpHeaders.acceptHeader, 'application/vnd.github+json');
      final response = await request.close().timeout(const Duration(seconds: 20));
      if (response.statusCode != HttpStatus.ok) {
        throw HttpException('GitHub returned HTTP ${response.statusCode}');
      }
      final body = await response.transform(utf8.decoder).join();
      final data = jsonDecode(body) as Map<String, dynamic>;
      final tag = (data['tag_name'] ?? '').toString();
      final assets = (data['assets'] as List<dynamic>? ?? []);
      String? apk;
      for (final item in assets) {
        if (item is Map<String, dynamic>) {
          final name = (item['name'] ?? '').toString().toLowerCase();
          if (name.endsWith('.apk')) {
            apk = item['browser_download_url']?.toString();
            break;
          }
        }
      }
      if (tag.isEmpty) throw const FormatException('Release tag is missing');
      if (!mounted) return;
      setState(() {
        _latestVersion = tag.replaceFirst(RegExp(r'^[vV]'), '');
        _apkUrl = apk;
        _checked = true;
        if (_hasUpdate && (apk == null || apk.isEmpty)) {
          _error = 'A new version was found, but its APK file is missing.';
        }
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _checked = true;
          _error = 'Could not check for updates. Please check your internet connection and try again.';
        });
      }
    } finally {
      client?.close(force: true);
      if (mounted) setState(() => _checking = false);
    }
  }

  Future<void> _downloadUpdate() async {
    final url = _apkUrl;
    if (url == null || url.isEmpty || _downloading) return;
    setState(() {
      _downloading = true;
      _downloadProgress = 0;
      _error = null;
    });
    final String? error = await downloadAndInstallApk(
      url,
      onProgress: (receivedBytes, totalBytes) {
        if (!mounted) return;
        setState(() {
          _downloadProgress = totalBytes != null && totalBytes > 0
              ? (receivedBytes / totalBytes).clamp(0.0, 1.0).toDouble()
              : 0;
        });
      },
    );
    if (mounted) {
      setState(() {
        _downloading = false;
        if (error == null) _downloadProgress = 1;
      });
    }
    if (error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkForUpdates());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardColor = curconvCardColor(context);
    final green = const Color(0xFF008A5B);
    final latest = _latestVersion ?? (_checked ? '—' : 'Checking…');

    return Dialog(
      backgroundColor: cardColor,
      insetPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(26),
        side: BorderSide(color: green.withValues(alpha: 0.22)),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440, maxHeight: 650),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Text('About App',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      )),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 13, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD5F4E4),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text('CurConv',
                        style: TextStyle(
                            color: Color(0xFF087B50),
                            fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Container(
                width: 92,
                height: 92,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: green.withValues(alpha: 0.18)),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Image.asset('assets/icon/app_icon.png',
                      fit: BoxFit.cover),
                ),
              ),
              const SizedBox(height: 12),
              const Text('CurConv',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              Text('Version $curconvAppVersion',
                  style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 22),
              Divider(color: theme.dividerColor.withValues(alpha: 0.55)),
              const SizedBox(height: 12),
              _versionRow('Current Version', curconvAppVersion,
                  valueColor: theme.colorScheme.onSurface),
              const SizedBox(height: 18),
              _versionRow('Latest Version', latest,
                  valueColor: _hasUpdate ? green : const Color(0xFF087B50)),
              const SizedBox(height: 18),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.brightness == Brightness.dark
                      ? Colors.white.withValues(alpha: 0.06)
                      : const Color(0xFFF2F3F2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _hasUpdate
                              ? Icons.cloud_download_outlined
                              : Icons.verified_rounded,
                          color: green,
                          size: 25,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _checking
                                ? 'Checking for Updates'
                                : _hasUpdate
                                    ? 'New Update Available'
                                    : _checked && _error == null
                                        ? 'You’re using the latest version'
                                        : 'Check for Updates',
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w800),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _error ??
                          (_hasUpdate
                              ? 'A newer version is ready. Download the update to get the latest improvements.'
                              : _checked
                                  ? 'Your CurConv app is up to date.'
                                  : 'Connecting to GitHub to check the latest version…'),
                      style: TextStyle(
                          color: theme.textTheme.bodyMedium?.color
                              ?.withValues(alpha: 0.72)),
                    ),
                    if (_hasUpdate && _apkUrl != null) ...[
                      const SizedBox(height: 14),
                      if (_downloading) ...[
                        Row(
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: LinearProgressIndicator(
                                  value: _downloadProgress,
                                  minHeight: 9,
                                  backgroundColor: green.withValues(alpha: 0.16),
                                  valueColor:
                                      AlwaysStoppedAnimation<Color>(green),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              '${_downloadProgress <= 0 ? 0 : math.max(1, (_downloadProgress * 100).floor())}%',
                              style: TextStyle(
                                color: green,
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Downloading update…',
                          style: TextStyle(
                            color: theme.textTheme.bodyMedium?.color
                                ?.withValues(alpha: 0.72),
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: green,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                          ),
                          onPressed: _downloading ? null : _downloadUpdate,
                          icon: _downloading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : const Icon(Icons.download_rounded),
                          label: Text(
                              _downloading ? 'Downloading…' : 'Download Update',
                              style: TextStyle(
                                  fontSize: 17, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                    if (_error != null || !_hasUpdate) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _checking ? null : _checkForUpdates,
                          icon: _checking
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2))
                              : const Icon(Icons.refresh_rounded),
                          label: Text(_checking ? 'Checking…' : 'Check Again'),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 14),
              const Text('© CurConv',
                  style: TextStyle(color: Colors.grey, fontSize: 13)),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _versionRow(String label, String value, {required Color valueColor}) {
    return Row(
      children: [
        Expanded(
          child: Text(label,
              style: const TextStyle(color: Colors.grey, fontSize: 15)),
        ),
        Text(value,
            style: TextStyle(
                color: valueColor,
                fontSize: 17,
                fontWeight: FontWeight.w800)),
      ],
    );
  }
}
