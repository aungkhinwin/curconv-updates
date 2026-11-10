import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'curconv_3d.dart';
import 'backup_screen.dart';
import 'settings_screen.dart';
import 'merchant_label_dialog.dart';

const Color _merchantTeal = Color(0xFF00796B);

Widget _merchantFlagBadge(String flag, {double width = 32}) {
  final double flagWidth = width - 4;
  final double flagHeight = flagWidth * 2 / 3;
  final bool china = flag == '🇨🇳' || flag == 'cny_mmk';
  final bool malaysia = flag == '🇲🇾' || flag == 'myr_mmk';
  final bool thailand = flag == '🇹🇭' || flag == 'thb_mmk';
  final Color yellow = const Color(0xFFFFDE00);
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
            if (china)
              const Positioned.fill(child: ColoredBox(color: Color(0xFFDE2910)))
            else if (!malaysia && !thailand)
              Positioned.fill(
                child: CustomPaint(painter: _MyanmarFlagStripePainter()),
              )
            else
              Positioned.fill(
                child: CustomPaint(
                  painter: malaysia
                      ? const _MerchantMalaysiaFlagPainter()
                      : const _MerchantThailandFlagPainter(),
                ),
              ),
            if (china) ...[
              Positioned(
                left: flagWidth * 0.06,
                top: flagHeight * 0.02,
                child: Text(
                  '★',
                  style: TextStyle(
                      color: yellow, fontSize: width * 0.30, height: 1),
                ),
              ),
              ...[
                (flagWidth * 0.42, flagHeight * 0.08, -0.5),
                (flagWidth * 0.53, flagHeight * 0.25, 0.1),
                (flagWidth * 0.53, flagHeight * 0.47, 0.35),
                (flagWidth * 0.42, flagHeight * 0.64, 0.5),
              ].map(
                (star) => Positioned(
                  left: star.$1,
                  top: star.$2,
                  child: Transform.rotate(
                    angle: star.$3,
                    child: Text(
                      '★',
                      style: TextStyle(
                        color: yellow,
                        fontSize: width * 0.12,
                        height: 1,
                      ),
                    ),
                  ),
                ),
              ),
            ] else if (!malaysia && !thailand)
              Center(
                child: Text(
                  '★',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: flagHeight * 0.82 + 1,
                    height: 1,
                  ),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

class _MyanmarFlagStripePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double stripeHeight = size.height / 3;
    final Paint paint = Paint()..style = PaintingStyle.fill;
    paint.color = const Color(0xFFFECB00);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, stripeHeight), paint);
    paint.color = const Color(0xFF34B233);
    canvas.drawRect(
      Rect.fromLTWH(0, stripeHeight, size.width, stripeHeight),
      paint,
    );
    paint.color = const Color(0xFFEA2839);
    canvas.drawRect(
      Rect.fromLTWH(
          0, stripeHeight * 2, size.width, size.height - stripeHeight * 2),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _MyanmarFlagStripePainter oldDelegate) => false;
}

class _MerchantThailandFlagPainter extends CustomPainter {
  const _MerchantThailandFlagPainter();

  @override
  void paint(Canvas canvas, Size size) {
    const List<Color> colors = <Color>[
      Color(0xFFA51931),
      Colors.white,
      Color(0xFF2D2A4A),
      Colors.white,
      Color(0xFFA51931),
    ];
    const List<double> weights = <double>[1, 1, 2, 1, 1];
    final double unit = size.height / 6;
    double top = 0;
    final Paint paint = Paint();
    for (int i = 0; i < colors.length; i++) {
      final double height = unit * weights[i];
      paint.color = colors[i];
      canvas.drawRect(Rect.fromLTWH(0, top, size.width, height + 0.2), paint);
      top += height;
    }
  }

  @override
  bool shouldRepaint(covariant _MerchantThailandFlagPainter oldDelegate) =>
      false;
}

class _MerchantMalaysiaFlagPainter extends CustomPainter {
  const _MerchantMalaysiaFlagPainter();

  @override
  void paint(Canvas canvas, Size size) {
    const int stripeCount = 14;
    final double stripeHeight = size.height / stripeCount;
    final Paint paint = Paint();
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

    final double radius = cantonHeight * 0.29;
    final Offset center = Offset(cantonWidth * 0.35, cantonHeight * 0.50);
    paint.color = const Color(0xFFFFCC00);
    canvas.drawCircle(center, radius, paint);
    paint.color = const Color(0xFF010066);
    canvas.drawCircle(
      Offset(center.dx + radius * 0.34, center.dy - radius * 0.10),
      radius * 0.80,
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
  bool shouldRepaint(covariant _MerchantMalaysiaFlagPainter oldDelegate) =>
      false;
}

Widget _merchantReceivedIcon({double size = 28}) => SizedBox.square(
    dimension: size, child: CustomPaint(painter: _ReceivedMoneyPainter()));

class _ReceivedMoneyPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 40, size.height / 40);

    final Paint green = Paint()..color = const Color(0xFF14B978);
    final Paint greenDark = Paint()..color = const Color(0xFF078F5A);
    final Paint skin = Paint()..color = const Color(0xFFFFB38A);
    final Paint skinShade = Paint()..color = const Color(0xFFF28A63);

    final Path curvedArrow = Path()
      ..moveTo(4, 13)
      ..cubicTo(8, 4, 20, 1, 29, 6)
      ..lineTo(27, 2)
      ..lineTo(38, 8)
      ..lineTo(27, 13)
      ..lineTo(27, 9)
      ..cubicTo(20, 5, 11, 8, 8, 15)
      ..close();
    canvas.drawPath(curvedArrow, green);

    canvas.drawCircle(const Offset(20, 23), 12, greenDark);
    canvas.drawCircle(
        const Offset(20, 22), 10.5, Paint()..color = const Color(0xFFFFC928));
    canvas.drawCircle(
        const Offset(20, 22), 8.4, Paint()..color = const Color(0xFFFFD84D));

    final TextPainter amount = TextPainter(
      text: const TextSpan(
        text: 'Ks',
        style: TextStyle(
          color: Color(0xFF9A5B00),
          fontSize: 8,
          fontWeight: FontWeight.w900,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    amount.paint(canvas, Offset(20 - amount.width / 2, 22 - amount.height / 2));

    final Path palm = Path()
      ..moveTo(4, 31)
      ..cubicTo(7, 27, 11, 26, 15, 27)
      ..lineTo(20, 29)
      ..lineTo(28, 29)
      ..cubicTo(32, 29, 34, 31, 32, 34)
      ..lineTo(21, 37)
      ..cubicTo(16, 39, 10, 38, 6, 35)
      ..close();
    canvas.drawPath(palm, skin);
    canvas.drawLine(
      const Offset(13, 32),
      const Offset(27, 32),
      Paint()
        ..color = const Color(0xFFE98762)
        ..strokeWidth = 1.4
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawPath(
      Path()
        ..moveTo(7, 35)
        ..cubicTo(12, 38, 18, 38, 22, 36),
      skinShade
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..strokeCap = StrokeCap.round,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _ReceivedMoneyPainter oldDelegate) => false;
}

Color _merchantPageBackground(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF121A19)
        : const Color(0xFFF4F6F8);

int _merchantNoticeSequence = 0;
OverlayEntry? _merchantNoticeEntry;

void _showMerchantNotice(
  BuildContext context,
  String message, {
  bool warning = false,
}) {
  final OverlayState overlay = Overlay.of(context, rootOverlay: true);
  final int sequence = ++_merchantNoticeSequence;
  _merchantNoticeEntry?.remove();
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
            color: warning ? const Color(0xFFFFF3CD) : const Color(0xFFFFD2ED),
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
                  color: warning
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
  _merchantNoticeEntry = entry;
  overlay.insert(entry);

  Future<void>.delayed(const Duration(seconds: 2), () {
    if (sequence == _merchantNoticeSequence && entry.mounted) {
      entry.remove();
      if (identical(_merchantNoticeEntry, entry)) {
        _merchantNoticeEntry = null;
      }
    }
  });
}

enum _MerchantField { yuan, rate, remittance, received }

enum _MerchantMethod { divide, multiply }

class MerchantScreen extends StatefulWidget {
  const MerchantScreen({super.key});

  @override
  State<MerchantScreen> createState() => _MerchantScreenState();
}

class _MerchantScreenState extends State<MerchantScreen> {
  static const String _recordsKey = 'merchant_transactions';
  static const String _snapshotsKey = 'merchant_history_snapshots';

  final TextEditingController _yuanController = TextEditingController();
  final TextEditingController _rateController = TextEditingController();
  final TextEditingController _remittanceController = TextEditingController();
  final TextEditingController _receivedController = TextEditingController();

  _MerchantField _activeField = _MerchantField.yuan;
  String? _pressedKey;
  bool _isSaving = false;
  bool _editingLabel = false;
  bool _keySoundEnabled = CurConvSettings.defaultKeySoundEnabled;
  bool _hapticEnabled = CurConvSettings.defaultHapticEnabled;
  bool _thousandSeparator = CurConvSettings.defaultThousandSeparatorEnabled;
  int _roundPrecision = CurConvSettings.defaultRoundPrecisionDigits;
  String _currencyPair = CurConvSettings.defaultCurrencyPair;
  List<Map<String, dynamic>> _records = [];

  double _totalYuan = 0;
  double _totalKyat = 0;
  double _totalRemittance = 0;
  double _totalReceived = 0;
  String _yuanTotalLabel = CurConvSettings.defaultYuanTotalLabel;
  String _kyatTotalLabel = CurConvSettings.defaultKyatTotalLabel;
  String _receivedTotalLabel = CurConvSettings.defaultReceivedTotalLabel;
  String _balanceTotalLabel = CurConvSettings.defaultBalanceTotalLabel;

  @override
  void initState() {
    super.initState();
    _loadMerchantData();
  }

  @override
  void dispose() {
    _yuanController.dispose();
    _rateController.dispose();
    _remittanceController.dispose();
    _receivedController.dispose();
    super.dispose();
  }

  static double _numberFrom(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  String _formatAmount(num value) => CurConvSettings.formatDisplayNumber(
        value,
        thousandSeparator: _thousandSeparator,
        roundPrecision: _roundPrecision,
      );

  static _MerchantMethod? _methodForRate(double rate,
      [String pair = 'cny_mmk']) {
    // MYR: always multiply, no range check
    if (pair == 'myr_mmk') {
      return rate > 0 ? _MerchantMethod.multiply : null;
    }
    if (rate >= 100 && rate <= 200) return _MerchantMethod.divide;
    if (rate >= 400 && rate <= 1000) return _MerchantMethod.multiply;
    return null;
  }

  void _recalculateTotals() {
    double yuan = 0;
    double kyat = 0;
    double remittance = 0;
    double received = 0;

    for (final Map<String, dynamic> record in _records) {
      switch (record['type']?.toString()) {
        case 'conversion':
          if ((record['currencyPair']?.toString() ??
                      CurConvSettings.defaultCurrencyPair) ==
                  _currencyPair &&
              record['deletedYuan'] != true) {
            yuan += _numberFrom(record['yuan']);
          }
          if (record['deletedKyat'] != true) {
            kyat += _numberFrom(record['kyat']);
          }
          break;
        case 'remittance':
          remittance += _numberFrom(record['amount']);
          break;
        case 'received':
          received += _numberFrom(record['amount']);
          break;
      }
    }

    _totalYuan = yuan;
    _totalKyat = kyat;
    _totalRemittance = remittance;
    _totalReceived = received;
  }

  Future<void> _loadMerchantData() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? savedPair = prefs.getString(CurConvSettings.currencyPairKey);
    final String pair = CurConvSettings.currencyPairIds.contains(savedPair)
        ? savedPair!
        : CurConvSettings.defaultCurrencyPair;
    final List<Map<String, dynamic>> loadedRecords = [];
    for (final String raw in prefs.getStringList(_recordsKey) ?? <String>[]) {
      try {
        final dynamic decoded = jsonDecode(raw);
        if (decoded is Map) {
          loadedRecords.add(Map<String, dynamic>.from(decoded));
        }
      } catch (_) {
        // Ignore a malformed Merchant row without disturbing other app data.
      }
    }

    if (!mounted) return;
    setState(() {
      _keySoundEnabled = prefs.getBool(CurConvSettings.keySoundEnabledKey) ??
          CurConvSettings.defaultKeySoundEnabled;
      _hapticEnabled = prefs.getBool(CurConvSettings.hapticEnabledKey) ??
          CurConvSettings.defaultHapticEnabled;
      _thousandSeparator = prefs.getBool(
            CurConvSettings.thousandSeparatorEnabledKey,
          ) ??
          CurConvSettings.defaultThousandSeparatorEnabled;
      _roundPrecision = prefs.getInt(CurConvSettings.roundPrecisionDigitsKey) ?? CurConvSettings.defaultRoundPrecisionDigits;
      _currencyPair = pair;
      _rateController.text = prefs.getString(
            CurConvSettings.merchantRateKey(pair),
          ) ??
          '';
      final String? savedYuanLabel =
          prefs.getString(CurConvSettings.yuanTotalLabelKey);
      _yuanTotalLabel = savedYuanLabel == null ||
              savedYuanLabel == CurConvSettings.defaultYuanTotalLabel
          ? '${CurConvSettings.currencyName(pair)} စုစုပေါင်း'
          : savedYuanLabel;
      _kyatTotalLabel = prefs.getString(CurConvSettings.kyatTotalLabelKey) ??
          CurConvSettings.defaultKyatTotalLabel;
      _receivedTotalLabel =
          prefs.getString(CurConvSettings.receivedTotalLabelKey) ??
              CurConvSettings.defaultReceivedTotalLabel;
      _balanceTotalLabel =
          prefs.getString(CurConvSettings.balanceTotalLabelKey) ??
              CurConvSettings.defaultBalanceTotalLabel;
      _records = loadedRecords.reversed.toList();
      _recalculateTotals();
    });
  }

  Future<void> _saveRate() async {
    final double rate = double.tryParse(_rateController.text) ?? 0;
    if (_methodForRate(rate, _currencyPair) == null) {
      _showMerchantNotice(
        context,
        '${CurConvSettings.currencyName(_currencyPair)} ရောင်းဈေးကို 100 မှ 200 သို့မဟုတ် 400 မှ 1000 အတွင်း ထည့်ပါ',
        warning: true,
      );
      return;
    }
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      CurConvSettings.merchantRateKey(_currencyPair),
      _rateController.text,
    );
    if (!mounted) return;
    _showMerchantNotice(
      context,
      'Merchant ${CurConvSettings.currencyName(_currencyPair)} ရောင်းဈေး သိမ်းပြီးပါပြီ',
    );
  }

  Future<void> _clearInputs() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('မှတ်တမ်းနှင့် စုစုပေါင်း ရှင်းရန်'),
        content: const Text(
          'ယွမ်၊ ကျပ်၊ လက်ခံရရှိငွေနှင့် လက်ကျန်ငွေတို့၏ စုစုပေါင်းကို 0 လုပ်ရန် '
          'Txn Hist ထဲရှိ လက်ရှိမှတ်တမ်းအားလုံးကို ဖျက်ပါမည်။ '
          'အမည်ပေး၍ သိမ်းထားသော Snapshot ဖိုင်များကို မဖျက်ပါ။ ဆက်လုပ်မလား?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('မလုပ်တော့ပါ'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('မှတ်တမ်းအားလုံး ဖျက်မည်'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove(_recordsKey);
      if (!mounted) return;
      setState(() {
        _records = <Map<String, dynamic>>[];
        _totalYuan = 0;
        _totalKyat = 0;
        _totalReceived = 0;
        _totalRemittance = 0;
        _yuanController.clear();
        _remittanceController.clear();
        _receivedController.clear();
        _activeField = _MerchantField.yuan;
      });
      _showMerchantNotice(
        context,
        'မှတ်တမ်းများ ဖျက်ပြီး စုစုပေါင်းကို 0 လုပ်ပြီးပါပြီ',
      );
    } catch (error) {
      if (mounted) {
        _showMerchantNotice(context, 'မှတ်တမ်းရှင်းမရပါ: $error',
            warning: true);
      }
    }
  }

  String? _activeSnapshotId; // Add/Edit နဲ့ ပြန်ဖွင့်ထားတဲ့ snapshot id

  Map<String, dynamic>? _rawSnapshotMap(String raw) {
    try {
      final Object? decoded = jsonDecode(raw);
      return decoded is Map ? Map<String, dynamic>.from(decoded) : null;
    } catch (_) {
      return null;
    }
  }

  bool _isSnapshotNameTaken(String name, List<String> saved) {
    final String key = name.trim().toLowerCase();
    return saved.any((String raw) {
      final String existing =
          _rawSnapshotMap(raw)?['name']?.toString().trim().toLowerCase() ?? '';
      return existing == key;
    });
  }

  Future<String?> _askSnapshotName(List<String> saved) async {
    final TextEditingController nameController = TextEditingController();
    String? errorText; // dialog rebuild တိုင်း မပျောက်အောင် ပြင်ပမှာ ထားသည်
    final String? name = await showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setDialogState) {
          void submit() {
            final String value = nameController.text.trim();
            if (value.isEmpty) return;
            if (_isSnapshotNameTaken(value, saved)) {
              setDialogState(() => errorText = 'ဒီနာမည်နဲ့ ဖိုင်ရှိပြီးသားပါ');
              return;
            }
            Navigator.of(dialogContext).pop(value);
          }

          return AlertDialog(
            title: const Text('TxnHist Save'),
            content: TextField(
              controller: nameController,
              autofocus: true,
              maxLength: 60,
              decoration: InputDecoration(
                labelText: 'File Name',
                hintText: 'ဖိုင်အမည်ရေးပါ',
                errorText: errorText,
              ),
              onSubmitted: (_) => submit(),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('CANCEL'),
              ),
              FilledButton(onPressed: submit, child: const Text('SAVE')),
            ],
          );
        },
      ),
    );
    nameController.dispose();
    return name;
  }

  Future<void> _saveLedgerSnapshot() async {
    if (_isSaving) return;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<String> saved =
        prefs.getStringList(_snapshotsKey) ?? <String>[];

    // Add/Edit နဲ့ ပြန်ဖွင့်ထားတဲ့ ဖိုင်ဖြစ်ရင် နာမည်မမေးဘဲ အဲဒီဖိုင်ကိုပဲ အစားထိုးမယ်
    int existingIndex = -1;
    String? fileName;
    if (_activeSnapshotId != null) {
      existingIndex = saved.indexWhere((String raw) =>
          _rawSnapshotMap(raw)?['id']?.toString() == _activeSnapshotId);
      if (existingIndex >= 0) {
        fileName = _rawSnapshotMap(saved[existingIndex])?['name']?.toString();
      }
    }
    if (existingIndex < 0) {
      _activeSnapshotId = null;
      fileName = await _askSnapshotName(saved);
      if (!mounted) return;
    }
    final String name = fileName?.trim() ?? '';
    if (name.isEmpty) return;

    try {
      final DateTime now = DateTime.now();
      final bool overwrite = existingIndex >= 0;
      final String snapshotId = overwrite
          ? _activeSnapshotId!
          : '${now.millisecondsSinceEpoch}-${saved.length}';
      final Map<String, dynamic> snapshot = <String, dynamic>{
        'id': snapshotId,
        'name': name,
        'createdAt': now.toIso8601String(),
        'date': '${now.day.toString().padLeft(2, '0')}/'
            '${now.month.toString().padLeft(2, '0')}/${now.year}',
        'time': '${now.hour.toString().padLeft(2, '0')}:'
            '${now.minute.toString().padLeft(2, '0')}',
        'records': _records
            .map((Map<String, dynamic> record) =>
                Map<String, dynamic>.from(record))
            .toList(),
        'totalYuan': _totalYuan,
        'totalKyat': _totalKyat,
        'totalReceived': _totalReceived,
        'totalRemittance': _totalRemittance,
        'currencyPair': _currencyPair,
      };
      if (overwrite) {
        saved[existingIndex] = jsonEncode(snapshot);
      } else {
        saved.insert(0, jsonEncode(snapshot));
      }
      if (!await prefs.setStringList(_snapshotsKey, saved)) {
        throw StateError('Snapshot ကို သိမ်း၍မရပါ');
      }
      if (mounted) {
        final Map<String, dynamic>? restoredSnapshot =
            await Navigator.of(context).push<Map<String, dynamic>>(
          MaterialPageRoute<Map<String, dynamic>>(
            builder: (BuildContext context) =>
                MerchantLedgerScreen(captureSnapshotId: snapshotId),
          ),
        );
        if (!mounted) return;
        if (restoredSnapshot == null) {
          await _loadMerchantData();
        } else {
          await _restoreSnapshotToMerchant(restoredSnapshot);
        }
      }
    } catch (error) {
      if (mounted) {
        _showMerchantNotice(context, 'Snapshot သိမ်းမရပါ: $error',
            warning: true);
      }
    }
  }

  TextEditingController get _activeController {
    switch (_activeField) {
      case _MerchantField.yuan:
        return _yuanController;
      case _MerchantField.rate:
        return _rateController;
      case _MerchantField.remittance:
        return _remittanceController;
      case _MerchantField.received:
        return _receivedController;
    }
  }

  void _editWithKey(String key) {
    final TextEditingController controller = _activeController;
    final String oldText = controller.text;
    final TextSelection selection = controller.selection;
    final int start = selection.isValid
        ? selection.start.clamp(0, oldText.length).toInt()
        : oldText.length;
    final int end = selection.isValid
        ? selection.end.clamp(0, oldText.length).toInt()
        : oldText.length;

    if (key == 'BACKSPACE') {
      if (start == 0 && end == 0) return;
      final int deleteStart = start == end ? start - 1 : start;
      final String updated = oldText.replaceRange(deleteStart, end, '');
      setState(() {
        controller.value = TextEditingValue(
          text: updated,
          selection: TextSelection.collapsed(offset: deleteStart),
        );
      });
      return;
    }

    final String before = oldText.replaceRange(start, end, '');
    if (key == '.' && before.contains('.')) return;
    final String updated = oldText.replaceRange(start, end, key);
    setState(() {
      controller.value = TextEditingValue(
        text: updated,
        selection: TextSelection.collapsed(offset: start + key.length),
      );
    });
  }

  Future<void> _submitActiveField() async {
    if (_isSaving) return;
    if (_activeField == _MerchantField.rate) {
      await _saveRate();
      return;
    }

    final TextEditingController controller = _activeController;
    final double amount = double.tryParse(controller.text) ?? 0;
    if (amount <= 0) {
      _showMerchantNotice(context, 'ပမာဏကို အရင်ဖြည့်ပါ', warning: true);
      return;
    }

    final DateTime now = DateTime.now();
    final String date = '${now.day.toString().padLeft(2, '0')}/'
        '${now.month.toString().padLeft(2, '0')}/${now.year}';
    final String time = '${now.hour.toString().padLeft(2, '0')}:'
        '${now.minute.toString().padLeft(2, '0')}:'
        '${now.second.toString().padLeft(2, '0')}';

    final Map<String, dynamic> record;
    if (_activeField == _MerchantField.yuan) {
      final double rate = double.tryParse(_rateController.text) ?? 0;
      final _MerchantMethod? method = _methodForRate(rate, _currencyPair);
      if (method == null) {
        _showMerchantNotice(
          context,
          'ယွမ်ရောင်းဈေးကို 100 မှ 200 သို့မဟုတ် 400 မှ 1000 အတွင်း ထည့်ပါ',
          warning: true,
        );
        return;
      }
      final double kyat = method == _MerchantMethod.divide
          ? (amount / rate) * 100000
          : amount * rate;
      record = <String, dynamic>{
        'type': 'conversion',
        'currencyPair': _currencyPair,
        'yuan': amount,
        'kyat': kyat,
        'rate': rate,
        'method': method == _MerchantMethod.divide ? '÷' : '×',
        'date': date,
        'time': time,
      };
    } else if (_activeField == _MerchantField.remittance) {
      record = <String, dynamic>{
        'type': 'remittance',
        'amount': amount,
        'date': date,
        'time': time,
      };
    } else {
      record = <String, dynamic>{
        'type': 'received',
        'amount': amount,
        'date': date,
        'time': time,
      };
    }

    setState(() => _isSaving = true);
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final List<String> saved = prefs.getStringList(_recordsKey) ?? <String>[];
      saved.insert(0, jsonEncode(record));
      await prefs.setStringList(_recordsKey, saved);

      if (!mounted) return;
      final List<Map<String, dynamic>> loaded = saved
          .map(
            (String raw) => Map<String, dynamic>.from(jsonDecode(raw) as Map),
          )
          .toList();
      setState(() {
        _records = loaded.reversed.toList();
        _recalculateTotals();
        controller.clear();
        _isSaving = false;
      });
      _showMerchantNotice(context, '📜 Txn Hist သို့ သိမ်းပြီးပါပြီ');
    } catch (error) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      _showMerchantNotice(context, 'စာရင်းသိမ်းမရပါ: $error', warning: true);
    }
  }

  Future<void> _restoreSnapshotToMerchant(
    Map<String, dynamic> restoredSnapshot,
  ) async {
    final Object? rawRecords = restoredSnapshot['records'];
    final List<Map<String, dynamic>> restoredRecords = rawRecords is List
        ? rawRecords
            .whereType<Map>()
            .map((Map record) => Map<String, dynamic>.from(record))
            .toList()
        : <Map<String, dynamic>>[];
    final String requestedPair = restoredSnapshot['currencyPair']?.toString() ??
        CurConvSettings.defaultCurrencyPair;
    final String pair = CurConvSettings.currencyPairIds.contains(requestedPair)
        ? requestedPair
        : CurConvSettings.defaultCurrencyPair;

    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(
        _recordsKey,
        restoredRecords.reversed
            .map((Map<String, dynamic> item) => jsonEncode(item))
            .toList(),
      );
      await prefs.setString(CurConvSettings.currencyPairKey, pair);
      if (!mounted) return;
      setState(() {
        _activeSnapshotId = restoredSnapshot['id']?.toString();
        _currencyPair = pair;
        _records = restoredRecords;
        _recalculateTotals();
        _yuanController.clear();
        _remittanceController.clear();
        _receivedController.clear();
        _activeField = _MerchantField.yuan;
      });
      _showMerchantNotice(context,
          'Snapshot စာရင်းနှင့် ပမာဏများကို Merchant သို့ ပြန်ထည့်ပြီးပါပြီ');
    } catch (error) {
      if (mounted) {
        _showMerchantNotice(context, 'Snapshot ပြန်ထည့်မရပါ: $error',
            warning: true);
      }
    }
  }

  Future<void> _openLedger() async {
    final Map<String, dynamic>? restoredSnapshot =
        await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute<Map<String, dynamic>>(
        builder: (BuildContext context) => const MerchantLedgerScreen(),
      ),
    );
    if (!mounted) return;
    if (restoredSnapshot == null) {
      await _loadMerchantData();
    } else {
      await _restoreSnapshotToMerchant(restoredSnapshot);
    }
  }

  Future<void> _editSummaryLabel(String key, String currentLabel) async {
    if (_editingLabel || _isSaving) return;
    setState(() => _editingLabel = true);
    try {
      final String? value = await showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (_) => MerchantLabelDialog(
          currentLabel: currentLabel,
          defaultLabel: CurConvSettings.defaultLabels[key]!,
        ),
      );
      if (!mounted || value == null || value == currentLabel) return;
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      if (!mounted) return;
      if (!await prefs.setString(key, value)) {
        throw StateError('စာတန်းကို သိမ်း၍မရပါ။');
      }
      if (!mounted) return;
      setState(() {
        switch (key) {
          case CurConvSettings.yuanTotalLabelKey:
            _yuanTotalLabel = value;
            break;
          case CurConvSettings.kyatTotalLabelKey:
            _kyatTotalLabel = value;
            break;
          case CurConvSettings.receivedTotalLabelKey:
            _receivedTotalLabel = value;
            break;
          case CurConvSettings.balanceTotalLabelKey:
            _balanceTotalLabel = value;
            break;
        }
      });
    } catch (error) {
      if (mounted) {
        _showMerchantNotice(context, 'စာတန်းသိမ်းမရပါ: $error', warning: true);
      }
    } finally {
      if (mounted) setState(() => _editingLabel = false);
    }
  }

  Widget _buildSummaryTile({
    required String icon,
    required String label,
    required String labelKey,
    required String value,
    required Color background,
    required Color foreground,
    VoidCallback? onLongPressValue,
    double labelFontSize = 18,
    double valueFontSize = 14,
  }) {
    Timer? valueHoldTimer;
    return Expanded(
      child: Container(
        height: 82,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              key: ValueKey<String>('merchant-label-$labelKey'),
              behavior: HitTestBehavior.opaque,
              onDoubleTap: () => _editSummaryLabel(labelKey, label),
              child: Tooltip(
                message: 'စာတန်းပြင်ရန် နှစ်ချက်နှိပ်ပါ',
                child: SizedBox(
                  width: double.infinity,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (CurConvSettings.currencyPairIds.contains(icon) ||
                            icon == '🇲🇲')
                          _merchantFlagBadge(
                            icon,
                            width: icon == '🇲🇲' ? 31 : 32,
                          )
                        else if (icon == '📥')
                          _merchantReceivedIcon(size: 30)
                        else
                          Text(
                            icon,
                            style: TextStyle(
                              color: foreground,
                              fontWeight: FontWeight.bold,
                              fontSize: labelFontSize,
                            ),
                          ),
                        const SizedBox(width: 5),
                        Text(
                          label,
                          style: TextStyle(
                            color: foreground,
                            fontWeight: FontWeight.bold,
                            fontSize: labelFontSize,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 5),
            SizedBox(
              width: double.infinity,
              child: Listener(
                behavior: HitTestBehavior.translucent,
                onPointerDown: onLongPressValue == null
                    ? null
                    : (_) {
                        valueHoldTimer?.cancel();
                        valueHoldTimer = Timer(
                          const Duration(milliseconds: 350),
                          onLongPressValue!,
                        );
                      },
                onPointerUp: onLongPressValue == null
                    ? null
                    : (_) => valueHoldTimer?.cancel(),
                onPointerCancel: onLongPressValue == null
                    ? null
                    : (_) => valueHoldTimer?.cancel(),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    value,
                    maxLines: 1,
                    softWrap: false,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: foreground,
                      fontWeight: FontWeight.w900,
                      fontSize: valueFontSize,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalsPanel() {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 10, 12, 4),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFFE5E9EC),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _buildSummaryTile(
                icon: _currencyPair,
                label: _yuanTotalLabel,
                labelKey: CurConvSettings.yuanTotalLabelKey,
                value: CurConvSettings.currencyAmount(
                    _formatAmount(_totalYuan), _currencyPair),
                valueFontSize: 20,
                background: const Color(0xFFD32F2F),
                foreground: Colors.white,
              ),
              const SizedBox(width: 6),
              _buildSummaryTile(
                icon: '🇲🇲',
                label: _kyatTotalLabel,
                labelKey: CurConvSettings.kyatTotalLabelKey,
                labelFontSize: 20,
                valueFontSize: 20,
                value:
                    '${_formatAmount(_totalKyat - _totalReceived + _totalRemittance)} Ks',
                onLongPressValue: () {
                  final String amount = _formatAmount(
                    _totalKyat - _totalReceived + _totalRemittance,
                  );
                  unawaited(Clipboard.setData(ClipboardData(text: amount)));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('ကျပ်ငွေပမာဏကို ကူးယူပြီးပါပြီ'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
                background: const Color(0xFF2E7D32),
                foreground: Colors.white,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildSummaryTile(
                icon: '📥',
                label: _receivedTotalLabel,
                labelKey: CurConvSettings.receivedTotalLabelKey,
                value: '${_formatAmount(_totalReceived)} Ks',
                background: const Color(0xFFFFC107),
                foreground: const Color(0xFF4E342E),
              ),
              const SizedBox(width: 6),
              _buildSummaryTile(
                icon: '💸',
                label: _balanceTotalLabel,
                labelKey: CurConvSettings.balanceTotalLabelKey,
                value: '${_formatAmount(_totalRemittance)} Ks',
                background: const Color(0xFFFFCDD2),
                foreground: const Color(0xFF8E2424),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required _MerchantField field,
    required TextEditingController controller,
    required String label,
    Color? backgroundColor,
    Color? foregroundColor,
  }) {
    final bool selected = _activeField == field;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor ??
            (selected
                ? (isDark ? const Color(0xFF18302D) : const Color(0xFFE8F5E9))
                : (isDark ? const Color(0xFF2B3332) : Colors.grey.shade100)),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: selected
              ? _merchantTeal
              : (isDark ? Colors.white38 : Colors.black38),
          width: selected ? 2 : 1,
        ),
      ),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.none,
        showCursor: true,
        onTap: () => setState(() => _activeField = field),
        style: TextStyle(
          fontFamily: 'Roboto',
          fontWeight: FontWeight.bold,
          fontSize: 18,
          color: foregroundColor,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            fontFamily: 'Pyidaungsu',
            color: foregroundColor ??
                (selected
                    ? _merchantTeal
                    : (isDark ? Colors.white70 : Colors.grey.shade700)),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 8,
          ),
          suffixIcon: field == _MerchantField.rate
              ? IconButton(
                  tooltip:
                      '${CurConvSettings.currencyName(_currencyPair)} ရောင်းဈေး သိမ်းရန်',
                  icon: const Icon(Icons.save_rounded, color: _merchantTeal),
                  onPressed: _saveRate,
                )
              : controller.text.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(
                        Icons.cancel,
                        size: 18,
                        color: Colors.grey,
                      ),
                      onPressed: () {
                        setState(controller.clear);
                      },
                    ),
        ),
      ),
    );
  }

  Widget _buildAutoMethodHint() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 3, 12, 5),
      child: SizedBox(
        height: 40,
        child: Center(
          child: Text(
            '100–200: ÷    |    400–1000: ×',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildKeypad() {
    const List<List<String>> keys = <List<String>>[
      <String>['1', '2', '3', 'BACKSPACE'],
      <String>['4', '5', '6', '0000'],
      <String>['7', '8', '9', '00000'],
      <String>['0', '00', '.', 'SEND'],
    ];

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double screenHeight = MediaQuery.of(context).size.height;
        final double maxKeySize = screenHeight < 820
            ? 52
            : screenHeight < 860
                ? 57
                : 62;
        final double keySize = ((constraints.maxWidth - 68) / 4.6)
            .clamp(42.0, maxKeySize)
            .toDouble();
        final double wideKeyWidth = keySize * 1.55;

        return Container(
          color: _merchantPageBackground(context),
          padding: const EdgeInsets.fromLTRB(10, 3, 10, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: keys.map((List<String> row) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: row.map((String key) {
                    final bool wide = key == 'BACKSPACE' ||
                        key.startsWith('000') ||
                        key == 'SEND';
                    final bool pressed = _pressedKey == key;
                    final Widget child;
                    if (key == 'BACKSPACE') {
                      child = const Icon(
                        Icons.backspace_rounded,
                        size: 26,
                        color: Color(0xFF4B1B0D),
                      );
                    } else if (key == 'SEND') {
                      child = const Icon(
                        Icons.send_rounded,
                        size: 27,
                        color: Color(0xFF4B1B0D),
                      );
                    } else {
                      double size = 28;
                      if (key == '0000') size = 17;
                      if (key == '00000') size = 15;
                      if (key == '00') size = 24;
                      if (key == '.') size = 30;
                      child = Text(
                        key,
                        style: TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: size,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF4B1B0D),
                        ),
                      );
                    }

                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                      ),
                      child: Semantics(
                        button: true,
                        label: key == 'SEND'
                            ? 'ပို့ရန်'
                            : key == 'BACKSPACE'
                                ? 'စာလုံးဖျက်ရန်'
                                : key,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTapDown: (_) => setState(() => _pressedKey = key),
                          onTapUp: (_) {
                            setState(() => _pressedKey = null);
                            if (key != 'SEND') {
                              CurConvSettings.playKeyFeedback(
                                soundEnabled: _keySoundEnabled,
                                hapticEnabled: _hapticEnabled,
                              );
                            }
                            if (key == 'BACKSPACE') {
                              _editWithKey('BACKSPACE');
                            } else if (key == 'SEND') {
                              _submitActiveField();
                            } else {
                              _editWithKey(key);
                            }
                          },
                          onTapCancel: () => setState(() => _pressedKey = null),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 90),
                            curve: Curves.easeOut,
                            width: wide ? wideKeyWidth : keySize,
                            height: keySize,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: wide
                                    ? (pressed
                                        ? const <Color>[
                                            Color(0xFFE8C6B8),
                                            Color(0xFFD7A795),
                                            Color(0xFFC8917C),
                                          ]
                                        : const <Color>[
                                            Color(0xFFF5DDD2),
                                            Color(0xFFDDB3A2),
                                            Color(0xFFC9917B),
                                          ])
                                    : (pressed
                                        ? const <Color>[
                                            Color(0xFFFFE1B4),
                                            Color(0xFFF7C58F),
                                            Color(0xFFE8A96C),
                                          ]
                                        : const <Color>[
                                            Color(0xFFFFF0D8),
                                            Color(0xFFF9D09B),
                                            Color(0xFFEBAE70),
                                          ]),
                              ),
                              border: Border.all(
                                color: Colors.white.withAlpha(184),
                                width: 1.2,
                              ),
                              borderRadius: BorderRadius.circular(
                                wide ? 999 : keySize / 2,
                              ),
                              boxShadow: <BoxShadow>[
                                BoxShadow(
                                  color: const Color(
                                    0xFF8C573C,
                                  ).withAlpha(pressed ? 61 : 102),
                                  offset: Offset(0, pressed ? 3 : 7),
                                  blurRadius: pressed ? 5 : 9,
                                ),
                              ],
                            ),
                            child: Center(child: child),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Custom keypad stays in place; the label dialog handles keyboard insets.
      resizeToAvoidBottomInset: false,
      backgroundColor: _merchantPageBackground(context),
      appBar: AppBar(
        backgroundColor: _merchantTeal,
        foregroundColor: Colors.white,
        centerTitle: true,
        leadingWidth: 120,
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: 'Back',
              constraints: const BoxConstraints.tightFor(width: 48, height: 48),
              padding: EdgeInsets.zero,
              splashRadius: 24,
              icon: const Icon(Icons.arrow_back_rounded, size: 28),
              onPressed: () => Navigator.of(context).pop(),
            ),
            const SizedBox(width: 16),
            IconButton(
              tooltip: 'Txn Hist',
              constraints: const BoxConstraints.tightFor(width: 48, height: 48),
              padding: EdgeInsets.zero,
              splashRadius: 24,
              onPressed: _openLedger,
              icon: const Text('📜', style: TextStyle(fontSize: 24)),
            ),
          ],
        ),
        titleSpacing: 0,
        title: const Text(
          'Merchant',
          style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: 'Clear Inputs',
            onPressed: _clearInputs,
            icon: const Icon(Icons.cleaning_services_rounded),
          ),
          const SizedBox(width: 16),
          IconButton(
            tooltip: 'TxnHist Save',
            onPressed: _saveLedgerSnapshot,
            icon: const Icon(Icons.save_outlined),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildTotalsPanel(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 5),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildInputField(
                          field: _MerchantField.yuan,
                          controller: _yuanController,
                          label:
                              '${CurConvSettings.currencyName(_currencyPair)} မှ ကျပ်',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildInputField(
                          field: _MerchantField.rate,
                          controller: _rateController,
                          label:
                              '${CurConvSettings.currencyName(_currencyPair)} ရောင်းဈေး',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _buildInputField(
                          field: _MerchantField.received,
                          controller: _receivedController,
                          label: 'လက်ခံရရှိ',
                          backgroundColor: const Color(0xFFFFC107),
                          foregroundColor: const Color(0xFF4E342E),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildInputField(
                          field: _MerchantField.remittance,
                          controller: _remittanceController,
                          label: '💸 လက်ကျန် & ပြန်လွှဲ',
                          backgroundColor: const Color(0xFFFFCDD2),
                          foregroundColor: const Color(0xFF8E2424),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          _buildAutoMethodHint(),
          _buildKeypad(),
        ],
      ),
    );
  }
}

class MerchantLedgerScreen extends StatefulWidget {
  const MerchantLedgerScreen({super.key, this.captureSnapshotId});

  final String? captureSnapshotId;

  @override
  State<MerchantLedgerScreen> createState() => _MerchantLedgerScreenState();
}

class _MerchantLedgerScreenState extends State<MerchantLedgerScreen> {
  static const String _recordsKey = 'merchant_transactions';
  static const String _snapshotsKey = 'merchant_history_snapshots';
  final GlobalKey _exportBoundaryKey = GlobalKey();
  List<Map<String, dynamic>> _records = [];
  List<Map<String, dynamic>> _snapshots = [];
  double _totalYuan = 0;
  double _totalKyat = 0;
  double _totalRemittance = 0;
  double _totalReceived = 0;
  bool _sharing = false;
  bool _deleteMode = false;
  bool _isCapturingSnapshot = false;
  bool _thousandSeparator = CurConvSettings.defaultThousandSeparatorEnabled;
  int _roundPrecision = CurConvSettings.defaultRoundPrecisionDigits;
  String _yuanTotalLabel = CurConvSettings.defaultYuanTotalLabel;
  String _kyatTotalLabel = CurConvSettings.defaultKyatTotalLabel;
  String _receivedTotalLabel = CurConvSettings.defaultReceivedTotalLabel;
  String _balanceTotalLabel = CurConvSettings.defaultBalanceTotalLabel;
  String _ledgerTitle = CurConvSettings.defaultLedgerTitle;
  String _currencyPair = CurConvSettings.defaultCurrencyPair;
  String? _captureReportTitle;

  static double _numberFrom(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  String _formatAmount(num value) => CurConvSettings.formatDisplayNumber(
        value,
        thousandSeparator: _thousandSeparator,
        roundPrecision: _roundPrecision,
      );

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  Future<void> _loadRecords() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<Map<String, dynamic>> loaded = [];
    for (final String raw in prefs.getStringList(_recordsKey) ?? <String>[]) {
      try {
        final dynamic decoded = jsonDecode(raw);
        if (decoded is Map) loaded.add(Map<String, dynamic>.from(decoded));
      } catch (_) {
        // Skip a malformed row but keep the rest of the ledger.
      }
    }

    final List<Map<String, dynamic>> loadedSnapshots = [];
    for (final String raw in prefs.getStringList(_snapshotsKey) ?? <String>[]) {
      try {
        final dynamic decoded = jsonDecode(raw);
        if (decoded is Map) {
          loadedSnapshots.add(Map<String, dynamic>.from(decoded));
        }
      } catch (_) {
        // Skip a malformed snapshot without hiding the remaining saved files.
      }
    }

    final Map<String, dynamic>? snapshotToCapture =
        widget.captureSnapshotId == null
            ? null
            : loadedSnapshots.cast<Map<String, dynamic>?>().firstWhere(
                  (Map<String, dynamic>? item) =>
                      item?['id']?.toString() == widget.captureSnapshotId,
                  orElse: () => null,
                );
    List<Map<String, dynamic>> recordsToShow = loaded.reversed.toList();
    final String? prefsPair = prefs.getString(CurConvSettings.currencyPairKey);
    final String savedPair = snapshotToCapture?['currencyPair']?.toString() ??
        (CurConvSettings.currencyPairIds.contains(prefsPair)
            ? prefsPair!
            : CurConvSettings.defaultCurrencyPair);
    final String reportPair =
        CurConvSettings.currencyPairIds.contains(savedPair)
            ? savedPair
            : CurConvSettings.defaultCurrencyPair;
    if (snapshotToCapture != null) {
      final Object? rawSnapshotRecords = snapshotToCapture['records'];
      if (rawSnapshotRecords is List) {
        // Snapshots are stored in entry order (first entry on top).
        recordsToShow = rawSnapshotRecords
            .whereType<Map>()
            .map((Map item) => Map<String, dynamic>.from(item))
            .toList();
      }
    }

    double yuan = 0;
    double kyat = 0;
    double remittance = 0;
    double received = 0;
    for (final Map<String, dynamic> record in recordsToShow) {
      switch (record['type']?.toString()) {
        case 'conversion':
          if ((record['currencyPair']?.toString() ??
                      CurConvSettings.defaultCurrencyPair) ==
                  reportPair &&
              record['deletedYuan'] != true) {
            yuan += _numberFrom(record['yuan']);
          }
          if (record['deletedKyat'] != true) {
            kyat += _numberFrom(record['kyat']);
          }
          break;
        case 'remittance':
          remittance += _numberFrom(record['amount']);
          break;
        case 'received':
          received += _numberFrom(record['amount']);
          break;
      }
    }

    if (!mounted) return;
    setState(() {
      // Transactions are persisted newest-first; show them in send order.
      _records = recordsToShow;
      _snapshots = loadedSnapshots;
      _currencyPair = reportPair;
      _totalYuan = snapshotToCapture == null
          ? yuan
          : _numberFrom(snapshotToCapture['totalYuan']);
      _totalKyat = snapshotToCapture == null
          ? kyat
          : _numberFrom(snapshotToCapture['totalKyat']);
      _totalRemittance = snapshotToCapture == null
          ? remittance
          : _numberFrom(snapshotToCapture['totalRemittance']);
      _totalReceived = snapshotToCapture == null
          ? received
          : _numberFrom(snapshotToCapture['totalReceived']);
      _thousandSeparator = prefs.getBool(
            CurConvSettings.thousandSeparatorEnabledKey,
          ) ??
          CurConvSettings.defaultThousandSeparatorEnabled;
      _roundPrecision = prefs.getInt(CurConvSettings.roundPrecisionDigitsKey) ?? CurConvSettings.defaultRoundPrecisionDigits;
      _isCapturingSnapshot = snapshotToCapture != null &&
          (snapshotToCapture['imageData']?.toString().isNotEmpty != true);
      final String? savedYuanLabel =
          prefs.getString(CurConvSettings.yuanTotalLabelKey);
      _yuanTotalLabel = savedYuanLabel == null ||
              savedYuanLabel == CurConvSettings.defaultYuanTotalLabel ||
              savedYuanLabel == 'မလေးရှား ရင်းဂစ် စုစုပေါင်း' ||
              savedYuanLabel == 'ထိုင်းဘတ် စုစုပေါင်း'
          ? '${CurConvSettings.currencyName(reportPair)} စုစုပေါင်း'
          : savedYuanLabel;
      _kyatTotalLabel = prefs.getString(CurConvSettings.kyatTotalLabelKey) ??
          CurConvSettings.defaultKyatTotalLabel;
      _receivedTotalLabel =
          prefs.getString(CurConvSettings.receivedTotalLabelKey) ??
              CurConvSettings.defaultReceivedTotalLabel;
      _balanceTotalLabel =
          prefs.getString(CurConvSettings.balanceTotalLabelKey) ??
              CurConvSettings.defaultBalanceTotalLabel;
      _ledgerTitle = prefs.getString(CurConvSettings.ledgerTitleKey) ??
          CurConvSettings.defaultLedgerTitle;
      _captureReportTitle = snapshotToCapture?['name']?.toString();
    });
    if (_isCapturingSnapshot && widget.captureSnapshotId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _captureSnapshotImage(widget.captureSnapshotId!);
      });
    }
  }

  Future<void> _captureSnapshotImage(String snapshotId) async {
    try {
      await WidgetsBinding.instance.endOfFrame;
      final RenderObject? object =
          _exportBoundaryKey.currentContext?.findRenderObject();
      if (object is! RenderRepaintBoundary || object.size.isEmpty) {
        throw StateError('Snapshot ပုံကို ပြင်ဆင်၍ မရပါ');
      }
      final ui.Image image = await object.toImage(pixelRatio: 3.0);
      final ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      if (byteData == null) throw StateError('PNG ပုံဖန်တီး၍ မရပါ');
      final String imageData = base64Encode(byteData.buffer.asUint8List());

      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final List<String> saved =
          prefs.getStringList(_snapshotsKey) ?? <String>[];
      final List<String> updated = <String>[];
      for (final String raw in saved) {
        try {
          final dynamic decoded = jsonDecode(raw);
          if (decoded is Map && decoded['id']?.toString() == snapshotId) {
            final Map<String, dynamic> snapshot =
                Map<String, dynamic>.from(decoded);
            snapshot['imageData'] = imageData;
            updated.add(jsonEncode(snapshot));
          } else {
            updated.add(raw);
          }
        } catch (_) {
          updated.add(raw);
        }
      }
      if (!await prefs.setStringList(_snapshotsKey, updated)) {
        throw StateError('Snapshot ပုံကို သိမ်း၍မရပါ');
      }
      if (!mounted) return;
      setState(() {
        _snapshots = updated
            .map((String raw) =>
                Map<String, dynamic>.from(jsonDecode(raw) as Map))
            .toList();
        _isCapturingSnapshot = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _isCapturingSnapshot = false);
      _showMerchantNotice(context, 'Snapshot ပုံသိမ်းမရပါ: $error',
          warning: true);
    }
  }

  Future<void> _editLedgerTitle() async {
    final String current = _ledgerTitle;
    final String? value = await showDialog<String>(
      context: context,
      builder: (_) => MerchantLabelDialog(
        currentLabel: current,
        defaultLabel: CurConvSettings.defaultLedgerTitle,
      ),
    );
    if (!mounted || value == null || value.trim().isEmpty || value == current) {
      return;
    }
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(CurConvSettings.ledgerTitleKey, value.trim());
    if (!mounted) return;
    setState(() => _ledgerTitle = value.trim());
    _showMerchantNotice(context, 'ခေါင်းစဉ်ကို သိမ်းပြီးပါပြီ');
  }

  Future<void> _confirmDeleteCell(
    Map<String, dynamic> record,
    String columnIcon,
  ) async {
    if (!_deleteMode) return;
    final bool isConversion = record['type']?.toString() == 'conversion';
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: Text('$columnIcon ကော်လံက တန်ဖိုးကို ဖျက်မလား?'),
        content: Text(
          isConversion
              ? 'ဒီအတန်းရဲ့ ဘယ်ဘက် ယွမ်၊ ရောင်းဈေး၊ ကျပ်ငွေ ကော်လံသုံးခုကို '
                  'အတူဖျက်ပါမယ်။ ညာဘက် လက်ခံရရှိငွေကော်လံကို မထိပါဘူး။ ပြန်ယူ၍မရပါ။'
              : 'ဒီညာဘက် လက်ခံရရှိငွေကော်လံက ဒီအတန်းရဲ့ တန်ဖိုးတစ်ခုတည်းကို '
                  'ဖျက်ပါမယ်။ ပြန်ယူ၍မရပါ။',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('မဖျက်တော့ပါ'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('ဖျက်မည်'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final int recordIndex = _records.indexOf(record);
    if (recordIndex < 0) return;
    final List<Map<String, dynamic>> updatedRecords =
        List<Map<String, dynamic>>.of(_records);
    // Deleted rows are removed from the list, so the rows below move up
    // and no empty space is left behind.
    updatedRecords.removeAt(recordIndex);

    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final List<String> encodedRecords = updatedRecords.reversed
          .map((Map<String, dynamic> item) => jsonEncode(item))
          .toList();
      final bool saved = await prefs.setStringList(_recordsKey, encodedRecords);
      if (!saved) throw StateError('မှတ်တမ်းကို သိမ်းမရပါ');

      double yuan = 0;
      double kyat = 0;
      double remittance = 0;
      double received = 0;
      for (final Map<String, dynamic> item in updatedRecords) {
        switch (item['type']?.toString()) {
          case 'conversion':
            if (item['deletedYuan'] != true) {
              yuan += _numberFrom(item['yuan']);
            }
            if (item['deletedKyat'] != true) {
              kyat += _numberFrom(item['kyat']);
            }
            break;
          case 'remittance':
            remittance += _numberFrom(item['amount']);
            break;
          case 'received':
            received += _numberFrom(item['amount']);
            break;
        }
      }

      if (!mounted) return;
      setState(() {
        _records = updatedRecords;
        _totalYuan = yuan;
        _totalKyat = kyat;
        _totalRemittance = remittance;
        _totalReceived = received;
        if (_records.isEmpty) _deleteMode = false;
      });
      _showMerchantNotice(
        context,
        isConversion
            ? 'ဘယ်ဘက် ယွမ်၊ ရောင်းဈေး၊ ကျပ်ငွေ ကော်လံသုံးခုကို ဖျက်ပြီးပါပြီ'
            : 'ညာဘက် လက်ခံရရှိငွေကော်လံကို ဖျက်ပြီးပါပြီ',
      );
    } catch (error) {
      if (mounted) {
        _showMerchantNotice(context, 'မှတ်တမ်းဖျက်မရပါ: $error', warning: true);
      }
    }
  }

  Widget _exportSummaryTile({
    required String icon,
    required String label,
    required String value,
    required Color color,
    required Color textColor,
    double labelFontSize = 18,
    double valueFontSize = 16,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: double.infinity,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (CurConvSettings.currencyPairIds.contains(icon) ||
                        icon == '🇲🇲')
                      _merchantFlagBadge(
                        icon,
                        width: icon == '🇲🇲' ? 23 : 24,
                      )
                    else if (icon == '📥')
                      _merchantReceivedIcon(size: 24)
                    else
                      Text(
                        icon,
                        style: TextStyle(
                          color: textColor,
                          fontSize: labelFontSize,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    const SizedBox(width: 5),
                    Text(
                      label,
                      style: TextStyle(
                        color: textColor,
                        fontSize: labelFontSize,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 4),
            SizedBox(
              width: double.infinity,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  maxLines: 1,
                  softWrap: false,
                  style: TextStyle(
                    color: textColor,
                    fontSize: valueFontSize,
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

  /// A row is removed once its conversion cells are all deleted and it has no cash entry.
  bool _isRemovedLedgerRow({
    Map<String, dynamic>? conversion,
    Map<String, dynamic>? cashRecord,
  }) {
    if (conversion == null || cashRecord != null) return false;
    return conversion['deletedYuan'] == true &&
        conversion['deletedRate'] == true &&
        conversion['deletedKyat'] == true;
  }

  Widget _buildExportContent({
    List<Map<String, dynamic>>? recordsOverride,
    String? reportTitleOverride,
    String? reportDateOverride,
    String? currencyPairOverride,
    double? totalYuanOverride,
    double? totalKyatOverride,
    double? totalReceivedOverride,
    double? totalRemittanceOverride,
    bool? deleteModeOverride,
    void Function(Map<String, dynamic>, String)? onDeleteCell,
  }) {
    final List<Map<String, dynamic>> reportRecords = recordsOverride ?? _records;
    final String reportPair = currencyPairOverride ?? _currencyPair;
    final double reportYuan = totalYuanOverride ?? _totalYuan;
    final double reportKyat = totalKyatOverride ?? _totalKyat;
    final double reportReceived = totalReceivedOverride ?? _totalReceived;
    final double reportRemittance =
        totalRemittanceOverride ?? _totalRemittance;
    final bool reportDeleteMode = deleteModeOverride ?? _deleteMode;
    final String reportDate = reportDateOverride ??
        'ထုတ်ယူသည့်နေ့: ${DateTime.now().day.toString().padLeft(2, '0')}/'
            '${DateTime.now().month.toString().padLeft(2, '0')}/${DateTime.now().year}';
    final List<Map<String, dynamic>> conversionRecords = reportRecords
        .where(
          (Map<String, dynamic> record) =>
              record['type']?.toString() == 'conversion' &&
              !(record['deletedYuan'] == true &&
                  record['deletedRate'] == true &&
                  record['deletedKyat'] == true),
        )
        .toList();
    final List<Map<String, dynamic>> cashRecords =
        reportRecords.where((Map<String, dynamic> record) {
      final String type = record['type']?.toString() ?? '';
      return type == 'received' || type == 'remittance';
    }).toList();
    final int ledgerRowCount = conversionRecords.length > cashRecords.length
        ? conversionRecords.length
        : cashRecords.length;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black, width: 4),
        borderRadius: BorderRadius.circular(20),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Container(
            width: double.infinity,
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                  child: Column(
                    children: [
                      GestureDetector(
                        key: const ValueKey<String>('money-txn-report-title'),
                        behavior: HitTestBehavior.opaque,
                        onDoubleTap: reportTitleOverride == null
                            ? _editLedgerTitle
                            : null,
                        child: Tooltip(
                          message: 'အစီရင်ခံစာခေါင်းစဉ်ပြင်ရန် နှစ်ချက်နှိပ်ပါ',
                          child: Text(
                            '📜 ${reportTitleOverride ?? _captureReportTitle ?? _ledgerTitle}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: _merchantTeal,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 1.5,
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        color: Colors.black,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        reportDate,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _exportSummaryTile(
                            icon: reportPair,
                            label: _yuanTotalLabel,
                            value: CurConvSettings.currencyAmount(
                                _formatAmount(reportYuan), reportPair),
                            valueFontSize: 20,
                            color: const Color(0xFFD32F2F),
                            textColor: Colors.white,
                          ),
                          const SizedBox(width: 8),
                          _exportSummaryTile(
                            icon: '🇲🇲',
                            label: _kyatTotalLabel,
                            labelFontSize: 20,
                            valueFontSize: 20,
                            value:
                                '${_formatAmount(reportKyat - reportReceived + reportRemittance)} Ks',
                            color: const Color(0xFF2E7D32),
                            textColor: Colors.white,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _exportSummaryTile(
                            icon: '📥',
                            label: _receivedTotalLabel,
                            value: '${_formatAmount(reportReceived)} Ks',
                            color: const Color(0xFFFFC107),
                            textColor: const Color(0xFF4E342E),
                          ),
                          const SizedBox(width: 8),
                          _exportSummaryTile(
                            icon: '💸',
                            label: _balanceTotalLabel,
                            value: '${_formatAmount(reportRemittance)} Ks',
                            color: const Color(0xFFFFCDD2),
                            textColor: const Color(0xFF8E2424),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  width: double.infinity,
                  color: Theme.of(context).colorScheme.surface,
                  padding: const EdgeInsets.fromLTRB(8, 10, 8, 12),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          _buildLedgerHeaderCell(reportPair, flex: 10),
                          _buildLedgerHeaderCell('🏷️', flex: 8),
                          _buildLedgerHeaderCell('🇲🇲', flex: 11),
                          _buildLedgerHeaderCell('📥', flex: 11),
                        ],
                      ),
                      const SizedBox(height: 10),
                      for (int index = 0; index < ledgerRowCount; index++)
                        if (!_isRemovedLedgerRow(
                          conversion: index < conversionRecords.length
                              ? conversionRecords[index]
                              : null,
                          cashRecord: index < cashRecords.length
                              ? cashRecords[index]
                              : null,
                        ))
                          _buildLedgerRecordRow(
                            conversion: index < conversionRecords.length
                                ? conversionRecords[index]
                                : null,
                            cashRecord: index < cashRecords.length
                                ? cashRecords[index]
                                : null,
                            deleteModeOverride: reportDeleteMode,
                            onDeleteCell: onDeleteCell,
                          ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
    );
  }

  Widget _buildLedgerHeaderCell(String icon, {required int flex}) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3),
        child: Container(
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFF00BFA5),
            borderRadius: BorderRadius.circular(9),
          ),
          child:
              CurConvSettings.currencyPairIds.contains(icon) || icon == '🇲🇲'
                  ? _merchantFlagBadge(icon, width: icon == '🇲🇲' ? 26 : 27)
                  : icon == '📥'
                      ? _moneyTransferIcon(size: 26)
                      : icon.startsWith('🏷')
                          ? _tagIcon(size: 23)
                          : Text(icon, style: const TextStyle(fontSize: 21)),
        ),
      ),
    );
  }

  Widget _buildLedgerValueCell(
    String value, {
    required Color color,
    required Color textColor,
    required int flex,
    bool empty = false,
    bool deleteMode = false,
    VoidCallback? onDelete,
  }) {
    final bool canDelete = deleteMode && onDelete != null;
    final BorderRadius borderRadius = BorderRadius.circular(5);
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Material(
              color: empty ? Colors.transparent : color,
              borderRadius: borderRadius,
              child: InkWell(
                borderRadius: borderRadius,
                onTap: canDelete ? onDelete : null,
                child: Container(
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 3,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: borderRadius,
                    border: canDelete
                        ? Border.all(
                            color: const Color(0xFFD32F2F),
                            width: 1.5,
                          )
                        : null,
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      value,
                      maxLines: 1,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: empty ? Colors.black38 : textColor,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (canDelete)
              Positioned(
                top: 1,
                right: 1,
                child: IgnorePointer(
                  child: Container(
                    width: 15,
                    height: 15,
                    decoration: const BoxDecoration(
                      color: Color(0xFFD32F2F),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      size: 10,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLedgerRecordRow({
    required Map<String, dynamic>? conversion,
    required Map<String, dynamic>? cashRecord,
    bool? deleteModeOverride,
    void Function(Map<String, dynamic>, String)? onDeleteCell,
  }) {
    final bool activeDeleteMode = deleteModeOverride ?? _deleteMode;
    VoidCallback? deleteAction(Map<String, dynamic>? record, String label) {
      if (record == null) return null;
      return () {
        if (onDeleteCell != null) {
          onDeleteCell(record, label);
        } else {
          unawaited(_confirmDeleteCell(record, label));
        }
      };
    }

    final bool isConversion = conversion != null;
    final String cashType = cashRecord?['type']?.toString() ?? '';
    final bool isReceived = cashType == 'received';
    final bool isRemittance = cashType == 'remittance';
    final bool yuanDeleted = conversion?['deletedYuan'] == true;
    final String recordPair = conversion?['currencyPair']?.toString() ??
        CurConvSettings.defaultCurrencyPair;
    final bool rateDeleted = conversion?['deletedRate'] == true;
    final bool kyatDeleted = conversion?['deletedKyat'] == true;
    final String yuan = conversion != null && !yuanDeleted
        ? CurConvSettings.currencyAmount(
            _formatAmount(_numberFrom(conversion['yuan'])),
            recordPair,
          )
        : '';
    final String rate = conversion != null && !rateDeleted
        ? _formatAmount(_numberFrom(conversion['rate']))
        : '';
    final String kyat = conversion != null && !kyatDeleted
        ? _formatAmount(_numberFrom(conversion['kyat']))
        : '';
    final String cash = cashRecord != null
        ? _formatAmount(_numberFrom(cashRecord['amount']))
        : '';

    final Widget yuanCell = _buildLedgerValueCell(
      yuan,
      color: const Color(0xFFD32F2F),
      textColor: Colors.white,
      flex: 10,
      empty: !isConversion || yuanDeleted,
      deleteMode: activeDeleteMode,
      onDelete: yuanDeleted
          ? null
          : deleteAction(conversion, 'ယွမ်၊ ရောင်းဈေး၊ ကျပ်ငွေ'),
    );
    final Widget rateCell = _buildLedgerValueCell(
      rate,
      color: const Color(0xFFFFD1E8),
      textColor: const Color(0xFF7A1C46),
      flex: 8,
      empty: !isConversion || rateDeleted,
      deleteMode: activeDeleteMode,
      onDelete: rateDeleted
          ? null
          : deleteAction(conversion, 'ယွမ်၊ ရောင်းဈေး၊ ကျပ်ငွေ'),
    );
    final Widget kyatCell = _buildLedgerValueCell(
      kyat,
      color: const Color(0xFF007F5F),
      textColor: Colors.white,
      flex: 11,
      empty: !isConversion || kyatDeleted,
      deleteMode: activeDeleteMode,
      onDelete: kyatDeleted
          ? null
          : deleteAction(conversion, 'ယွမ်၊ ရောင်းဈေး၊ ကျပ်ငွေ'),
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      child: Row(
        children: [
          if (activeDeleteMode &&
              conversion != null &&
              !(yuanDeleted && rateDeleted && kyatDeleted))
            Expanded(
              flex: 29,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(7),
                    onTap: deleteAction(
                      conversion,
                      'ယွမ်၊ ရောင်းဈေး၊ ကျပ်ငွေ',
                    ),
                    child: Stack(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: const Color(0xFFD32F2F),
                              width: 1.5,
                            ),
                            borderRadius: BorderRadius.circular(7),
                          ),
                          child: Row(
                            children: [
                              _buildLedgerValueCell(
                                yuan,
                                color: const Color(0xFFD32F2F),
                                textColor: Colors.white,
                                flex: 10,
                                empty: yuanDeleted,
                              ),
                              _buildLedgerValueCell(
                                rate,
                                color: const Color(0xFFFFD1E8),
                                textColor: const Color(0xFF7A1C46),
                                flex: 8,
                                empty: rateDeleted,
                              ),
                              _buildLedgerValueCell(
                                kyat,
                                color: const Color(0xFF007F5F),
                                textColor: Colors.white,
                                flex: 11,
                                empty: kyatDeleted,
                              ),
                            ],
                          ),
                        ),
                        Positioned(
                          top: 1,
                          right: 1,
                          child: IgnorePointer(
                            child: Container(
                              width: 16,
                              height: 16,
                              decoration: const BoxDecoration(
                                color: Color(0xFFD32F2F),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close_rounded,
                                size: 11,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            )
          else ...[
            yuanCell,
            rateCell,
            kyatCell,
          ],
          _buildLedgerValueCell(
            cash,
            color: isRemittance
                ? const Color(0xFFFFCDD2)
                : const Color(0xFFFFC107),
            textColor: isRemittance
                ? const Color(0xFF8E2424)
                : const Color(0xFF3E3420),
            flex: 11,
            empty: !isReceived && !isRemittance,
            deleteMode: activeDeleteMode && (isReceived || isRemittance),
            onDelete: deleteAction(cashRecord, '📥'),
          ),
        ],
      ),
    );
  }

  Future<void> _openSavedSnapshot(Map<String, dynamic> source) async {
    final Map<String, dynamic> snapshot = Map<String, dynamic>.from(source);
    final String id = snapshot['id']?.toString() ??
        'legacy-${snapshot['createdAt'] ?? ''}-${snapshot['name'] ?? ''}';
    snapshot['id'] = id;
    final int snapshotIndex = _snapshots.indexWhere(
      (Map<String, dynamic> item) =>
          item['createdAt']?.toString() == source['createdAt']?.toString() &&
          item['name']?.toString() == source['name']?.toString(),
    );
    if (snapshotIndex >= 0) {
      final List<Map<String, dynamic>> updated =
          List<Map<String, dynamic>>.from(_snapshots);
      updated[snapshotIndex] = snapshot;
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(
        _snapshotsKey,
        updated.map((Map<String, dynamic> item) => jsonEncode(item)).toList(),
      );
      if (mounted) setState(() => _snapshots = updated);
    }

    final String? imageData = snapshot['imageData']?.toString();
    if (imageData != null && imageData.isNotEmpty) {
      await _showSavedSnapshot(snapshot);
      return;
    }

    final Object? rawRecords = snapshot['records'];
    final List<Map<String, dynamic>> snapshotRecords = rawRecords is List
        ? rawRecords
            .whereType<Map>()
            .map((Map record) => Map<String, dynamic>.from(record))
            .toList()
        : <Map<String, dynamic>>[];
    if (!mounted) return;
    setState(() {
      _records = snapshotRecords;
      _totalYuan = _numberFrom(snapshot['totalYuan']);
      _totalKyat = _numberFrom(snapshot['totalKyat']);
      _totalReceived = _numberFrom(snapshot['totalReceived']);
      _totalRemittance = _numberFrom(snapshot['totalRemittance']);
      _captureReportTitle = snapshot['name']?.toString();
      _isCapturingSnapshot = true;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _captureSnapshotImage(id);
      if (!mounted) return;
      Map<String, dynamic>? savedSnapshot;
      for (final Map<String, dynamic> item in _snapshots) {
        if (item['id']?.toString() == id) {
          savedSnapshot = item;
          break;
        }
      }
      if (savedSnapshot != null) await _showSavedSnapshot(savedSnapshot);
    });
  }

  Future<void> _showSavedSnapshot(Map<String, dynamic> sourceSnapshot) async {
    Map<String, dynamic> snapshot = Map<String, dynamic>.from(sourceSnapshot);
    List<Map<String, dynamic>> readRecords() {
      final Object? raw = snapshot['records'];
      return raw is List
          ? raw
              .whereType<Map>()
              .map((Map record) => Map<String, dynamic>.from(record))
              .toList()
          : <Map<String, dynamic>>[];
    }

    void recalculateSnapshotTotals(List<Map<String, dynamic>> records) {
      double yuan = 0;
      double kyat = 0;
      double received = 0;
      double remittance = 0;
      for (final Map<String, dynamic> record in records) {
        switch (record['type']?.toString()) {
          case 'conversion':
            if (record['deletedYuan'] != true) {
              yuan += _numberFrom(record['yuan']);
            }
            if (record['deletedKyat'] != true) {
              kyat += _numberFrom(record['kyat']);
            }
            break;
          case 'received':
            received += _numberFrom(record['amount']);
            break;
          case 'remittance':
            remittance += _numberFrom(record['amount']);
            break;
        }
      }
      snapshot['totalYuan'] = yuan;
      snapshot['totalKyat'] = kyat;
      snapshot['totalReceived'] = received;
      snapshot['totalRemittance'] = remittance;
    }

    Future<void> persistSnapshot() async {
      final String createdAt = sourceSnapshot['createdAt']?.toString() ?? '';
      final int index = _snapshots.indexWhere((Map<String, dynamic> item) =>
          item['createdAt']?.toString() == createdAt &&
          item['name']?.toString() == sourceSnapshot['name']?.toString());
      if (index < 0) return;
      final List<Map<String, dynamic>> updated =
          List<Map<String, dynamic>>.from(_snapshots);
      updated[index] = Map<String, dynamic>.from(snapshot);
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final bool saved = await prefs.setStringList(
        _snapshotsKey,
        updated.map((Map<String, dynamic> item) => jsonEncode(item)).toList(),
      );
      if (!saved) throw StateError('Snapshot ကို သိမ်းမရပါ');
      if (mounted) setState(() => _snapshots = updated);
    }

    bool deleteMode = false;
    bool busy = false;
    await showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) => StatefulBuilder(
        builder: (BuildContext context, StateSetter updateDialog) {
          final List<Map<String, dynamic>> records = readRecords();
          final String name = snapshot['name']?.toString() ?? 'Snapshot';

          Future<void> deleteRecord(int index) async {
            final List<Map<String, dynamic>> beforeConfirm = readRecords();
            if (index < 0 || index >= beforeConfirm.length) return;
            final bool isConversion =
                beforeConfirm[index]['type']?.toString() == 'conversion';
            final bool? confirm = await showDialog<bool>(
              context: dialogContext,
              builder: (BuildContext confirmContext) => AlertDialog(
                title: const Text('မှတ်တမ်းဖျက်ရန်'),
                content: Text(
                  isConversion
                      ? 'ဘယ်ဘက် ယွမ်၊ ရောင်းဈေး၊ ကျပ်ငွေ သုံးကွက်ကို အတူဖျက်မလား?'
                      : 'ညာဘက်ကွက်တစ်ခုတည်းကို ဖျက်မလား?',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(confirmContext, false),
                    child: const Text('မဖျက်တော့ပါ'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(confirmContext, true),
                    child: const Text('ဖျက်မည်'),
                  ),
                ],
              ),
            );
            if (confirm != true) return;
            updateDialog(() {
              final List<Map<String, dynamic>> current = readRecords();
              if (index >= 0 && index < current.length) {
                current.removeAt(index);
              }
              snapshot['records'] = current;
              snapshot['imageData'] = '';
              recalculateSnapshotTotals(current);
              busy = true;
            });
            try {
              await persistSnapshot();
            } catch (error) {
              _showMerchantNotice(context, 'မှတ်တမ်းဖျက်မရပါ: $error',
                  warning: true);
            } finally {
              updateDialog(() => busy = false);
            }
          }

          Widget buildDeleteModeTable() {
            final String snapshotPair =
                snapshot['currencyPair']?.toString() ?? _currencyPair;
            return Container(
              color: const Color(0xFFE8F5E9),
              child: SingleChildScrollView(
              child: _buildExportContent(
                // Stored newest-first; show oldest at top, latest at bottom.
                recordsOverride: records,
                reportTitleOverride: name,
                reportDateOverride: 'ထုတ်ယူသည့်နေ့: ${snapshot['date'] ?? ''}',
                currencyPairOverride: snapshotPair,
                totalYuanOverride: _numberFrom(snapshot['totalYuan']),
                totalKyatOverride: _numberFrom(snapshot['totalKyat']),
                totalReceivedOverride: _numberFrom(snapshot['totalReceived']),
                totalRemittanceOverride:
                    _numberFrom(snapshot['totalRemittance']),
                deleteModeOverride: deleteMode,
                onDeleteCell: (Map<String, dynamic> record, String _) {
                  final int index = records.indexOf(record);
                  if (index >= 0) unawaited(deleteRecord(index));
                },
              ),
              ),
            );
          }

          Future<void> shareSnapshot() async {
            final String snapshotPair = snapshot['currencyPair']?.toString() ??
                CurConvSettings.defaultCurrencyPair;
            final List<String> lines = <String>[
              name,
              '${snapshot['date'] ?? ''} ${snapshot['time'] ?? ''}',
              '${CurConvSettings.currencyName(snapshotPair)} စုစုပေါင်း: ${CurConvSettings.currencyAmount(_formatAmount(_numberFrom(snapshot['totalYuan'])), snapshotPair)}',
              'ကျပ်စုစုပေါင်း: ${_formatAmount(_numberFrom(snapshot['totalKyat']))} Ks',
              'လက်ခံရရှိငွေ: ${_formatAmount(_numberFrom(snapshot['totalReceived']))} Ks',
              'လက်ကျန်/ပြန်လွှဲ: ${_formatAmount(_numberFrom(snapshot['totalRemittance']))} Ks',
              ...readRecords().map((Map<String, dynamic> record) {
                final String type = record['type']?.toString() ?? '';
                if (type == 'conversion') {
                  final String recordPair =
                      record['currencyPair']?.toString() ?? snapshotPair;
                  return '${CurConvSettings.currencyAmount(_formatAmount(_numberFrom(record['yuan'])), recordPair)} → '
                      '${_formatAmount(_numberFrom(record['kyat']))} Ks';
                }
                return '${type == 'received' ? 'လက်ခံရရှိငွေ' : 'လက်ကျန်/ပြန်လွှဲ'}: '
                    '${_formatAmount(_numberFrom(record['amount']))} Ks';
              }),
            ];
            try {
              final String? imageData = snapshot['imageData']?.toString();
              if (imageData != null && imageData.isNotEmpty) {
                final Uint8List bytes = base64Decode(imageData);
                final File imageFile = File(
                  '${Directory.systemTemp.path}/snapshot_${DateTime.now().microsecondsSinceEpoch}.png',
                );
                await imageFile.writeAsBytes(bytes, flush: true);
                await Share.shareXFiles(
                  <XFile>[
                    XFile(imageFile.path,
                        mimeType: 'image/png', name: '$name.png'),
                  ],
                  text: name,
                  subject: name,
                );
              } else {
                await Share.share(lines.join('\n'), subject: name);
              }
            } catch (error) {
              _showMerchantNotice(context, 'Snapshot မျှဝေမရပါ: $error',
                  warning: true);
            }
          }

          Widget raisedActionButton({
            required String label,
            IconData? icon,
            Widget? iconWidget,
            required Color topColor,
            required Color bottomColor,
            required VoidCallback? onTap,
          }) {
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Center(
                  child: _ActionIconButton(
                    icon: icon,
                    iconWidget: iconWidget,
                    onTap: onTap,
                  ),
                ),
              ),
            );
          }

          return AlertDialog(
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 2,
              vertical: 12,
            ),
            contentPadding: const EdgeInsets.fromLTRB(0, 4, 0, 2),
            actionsPadding: EdgeInsets.zero,
            content: SizedBox(
              width: double.maxFinite,
              height: MediaQuery.of(context).size.height * 0.78,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: <Widget>[
                      raisedActionButton(
                        label: 'ဖျက်မုဒ်',
                        iconWidget: CurconvTrashIcon(
                          size: 22,
                          color: deleteMode
                              ? const Color(0xFFEF5350)
                              : const Color(0xFF004D40),
                        ),
                        topColor: deleteMode
                            ? const Color(0xFFEF5350)
                            : const Color(0xFF26A69A),
                        bottomColor: deleteMode
                            ? const Color(0xFFB71C1C)
                            : const Color(0xFF00695C),
                        onTap: busy
                            ? null
                            : () => updateDialog(
                                  () => deleteMode = !deleteMode,
                                ),
                      ),
                      raisedActionButton(
                        label: 'Add / Edit',
                        iconWidget: const CurconvEditIcon(size: 22, color: Color(0xFF004D40)),
                        topColor: const Color(0xFF42A5F5),
                        bottomColor: const Color(0xFF1565C0),
                        onTap: () {
                          Navigator.of(dialogContext).pop();
                          Navigator.of(this.context).pop<Map<String, dynamic>>(
                            Map<String, dynamic>.from(snapshot),
                          );
                        },
                      ),
                      raisedActionButton(
                        label: 'Share',
                        iconWidget: const CurconvShareIcon(size: 22, color: Color(0xFF004D40)),
                        topColor: const Color(0xFFFFC107),
                        bottomColor: const Color(0xFFEF6C00),
                        onTap: busy ? null : shareSnapshot,
                      ),
                    ],
                  ),
                  const Divider(
                    height: 8,
                    thickness: 1,
                    indent: 2,
                    endIndent: 2,
                  ),
                  Expanded(
                    child: busy
                        ? const Center(child: CircularProgressIndicator())
                        : buildDeleteModeTable(),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _persistSnapshotList() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final bool saved = await prefs.setStringList(
      _snapshotsKey,
      _snapshots.map((Map<String, dynamic> item) => jsonEncode(item)).toList(),
    );
    if (!saved) throw StateError('Snapshot ဖိုင်စာရင်း သိမ်းမရပါ');
  }

  Future<void> _renameSnapshot(int index) async {
    if (index < 0 || index >= _snapshots.length) return;
    final TextEditingController controller = TextEditingController(
      text: _snapshots[index]['name']?.toString() ?? '',
    );
    final String? newName = await showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('Snapshot အမည်ပြောင်းရန်'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 60,
          decoration: const InputDecoration(labelText: 'File Name'),
          onSubmitted: (String value) {
            if (value.trim().isNotEmpty) {
              Navigator.of(dialogContext).pop(value.trim());
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('CANCEL'),
          ),
          FilledButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                Navigator.of(dialogContext).pop(controller.text.trim());
              }
            },
            child: const Text('SAVE'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (newName == null || newName.trim().isEmpty || !mounted) return;
    final String trimmedName = newName.trim();
    final bool nameTaken = _snapshots.asMap().entries.any(
          (MapEntry<int, Map<String, dynamic>> e) =>
              e.key != index &&
              (e.value['name']?.toString().trim().toLowerCase() ?? '') ==
                  trimmedName.toLowerCase(),
        );
    if (nameTaken) {
      _showMerchantNotice(context, 'ဒီနာမည်နဲ့ ဖိုင်ရှိပြီးသားပါ',
          warning: true);
      return;
    }
    final List<Map<String, dynamic>> updated = _snapshots
        .map((Map<String, dynamic> item) => Map<String, dynamic>.from(item))
        .toList();
    updated[index]['name'] = newName.trim();
    setState(() => _snapshots = updated);
    try {
      await _persistSnapshotList();
    } catch (error) {
      if (mounted) {
        _showMerchantNotice(context, 'အမည်ပြောင်းမရပါ: $error', warning: true);
      }
    }
  }

  Future<void> _deleteSnapshot(int index) async {
    if (index < 0 || index >= _snapshots.length) return;
    final Map<String, dynamic> selected = _snapshots[index];
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('Snapshot ဖျက်ရန်'),
        content: Text('“${selected['name'] ?? 'Snapshot'}” ဖိုင်ကို ဖျက်မလား?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('CANCEL'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final List<Map<String, dynamic>> updated = List<Map<String, dynamic>>.from(
      _snapshots,
    )..removeAt(index);
    setState(() => _snapshots = updated);
    try {
      await _persistSnapshotList();
    } catch (error) {
      if (mounted) {
        _showMerchantNotice(context, 'Snapshot ဖျက်မရပါ: $error',
            warning: true);
      }
    }
  }

  Future<void> _duplicateSnapshot(int index) async {
    if (index < 0 || index >= _snapshots.length) return;
    final Map<String, dynamic> duplicate = Map<String, dynamic>.from(
      jsonDecode(jsonEncode(_snapshots[index])) as Map,
    );
    final DateTime now = DateTime.now();
    duplicate['id'] = '${now.microsecondsSinceEpoch}-copy';
    duplicate['name'] = '${duplicate['name'] ?? 'Snapshot'} (မိတ္တူ)';
    duplicate['createdAt'] = now.toIso8601String();
    duplicate['date'] = '${now.day.toString().padLeft(2, '0')}/'
        '${now.month.toString().padLeft(2, '0')}/${now.year}';
    duplicate['time'] = '${now.hour.toString().padLeft(2, '0')}:'
        '${now.minute.toString().padLeft(2, '0')}';
    final List<Map<String, dynamic>> updated = <Map<String, dynamic>>[
      duplicate,
      ..._snapshots,
    ];
    setState(() => _snapshots = updated);
    try {
      await _persistSnapshotList();
      if (mounted)
        _showMerchantNotice(context, 'Snapshot မိတ္တူ ဖန်တီးပြီးပါပြီ');
    } catch (error) {
      if (mounted) {
        _showMerchantNotice(context, 'Snapshot မိတ္တူ မသိမ်းနိုင်ပါ: $error',
            warning: true);
      }
    }
  }

  Widget _buildSavedSnapshotsSection() {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'သိမ်းထားသော Snapshot ဖိုင်များ',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            ..._snapshots.asMap().entries.map((
              MapEntry<int, Map<String, dynamic>> entry,
            ) {
              final int index = entry.key;
              final Map<String, dynamic> snapshot = entry.value;
              final Object? rawRecords = snapshot['records'];
              final int count = rawRecords is List ? rawRecords.length : 0;
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.receipt_long_rounded,
                    color: _merchantTeal, size: 28),
                title: Text('📜 ${snapshot['name']?.toString() ?? 'Snapshot'}'),
                subtitle: Text(
                  '${snapshot['date'] ?? ''}  ${snapshot['time'] ?? ''} · $count စာရင်း',
                ),
                trailing: PopupMenuButton<String>(
                  tooltip: 'Snapshot လုပ်ဆောင်ချက်များ',
                  icon: const Icon(Icons.more_vert_rounded),
                  onSelected: (String action) {
                    switch (action) {
                      case 'rename':
                        unawaited(_renameSnapshot(index));
                        break;
                      case 'delete':
                        unawaited(_deleteSnapshot(index));
                        break;
                      case 'duplicate':
                        unawaited(_duplicateSnapshot(index));
                        break;
                    }
                  },
                  itemBuilder: (BuildContext context) => const [
                    PopupMenuItem<String>(
                      value: 'rename',
                      child: ListTile(
                        leading: Icon(Icons.drive_file_rename_outline_rounded),
                        title: Text('Rename'),
                        dense: true,
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: 'delete',
                      child: ListTile(
                        leading: Icon(Icons.delete_outline_rounded),
                        title: Text('Delete'),
                        dense: true,
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: 'duplicate',
                      child: ListTile(
                        leading: Icon(Icons.copy_rounded),
                        title: Text('Duplicate'),
                        dense: true,
                      ),
                    ),
                  ],
                ),
                onTap: () => _openSavedSnapshot(snapshot),
              );
            }),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _merchantPageBackground(context),
      appBar: AppBar(
        backgroundColor: _merchantTeal,
        foregroundColor: Colors.white,
        centerTitle: true,
        // Back Up and Restore sit either side of the title with equal gaps.
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            IconButton(
              tooltip: 'Back Up',
              constraints: const BoxConstraints.tightFor(width: 48, height: 48),
              padding: EdgeInsets.zero,
              splashRadius: 24,
              icon: _cloudArrowGlyph(
                cloud: const Color(0xFF00B96B),
                arrow: Icons.arrow_upward_rounded,
              ),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const BackupScreen(autoAction: 'backup'),
                ),
              ),
            ),
            const SizedBox(width: 40),
            const Text(
              'Money Txn',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            const SizedBox(width: 40),
            IconButton(
              tooltip: 'Restore',
              constraints: const BoxConstraints.tightFor(width: 48, height: 48),
              padding: EdgeInsets.zero,
              splashRadius: 24,
              icon: _cloudArrowGlyph(
                cloud: const Color(0xFF168FE5),
                arrow: Icons.arrow_downward_rounded,
              ),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const BackupScreen(autoAction: 'restore'),
                ),
              ),
            ),
          ],
        ),
      ),
      body: _isCapturingSnapshot
          ? Stack(
              fit: StackFit.expand,
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.all(12),
                  child: RepaintBoundary(
                    key: _exportBoundaryKey,
                    child: _buildExportContent(),
                  ),
                ),
                Positioned.fill(
                  child: ColoredBox(
                    color: _merchantPageBackground(context),
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                ),
              ],
            )
          : _snapshots.isEmpty
              ? const Center(
                  child: Text('သိမ်းထားသော Snapshot ဖိုင် မရှိသေးပါ'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(12),
                  child: _buildSavedSnapshotsSection(),
                ),
    );
  }
}

/// Circular icon button with a pressed background and ripple effect.
class _ActionIconButton extends StatefulWidget {
  const _ActionIconButton({
    required this.onTap,
    this.icon,
    this.iconWidget,
  });

  final IconData? icon;
  final Widget? iconWidget;
  final VoidCallback? onTap;

  @override
  State<_ActionIconButton> createState() => _ActionIconButtonState();
}

class _ActionIconButtonState extends State<_ActionIconButton> {
  bool _pressed = false;

  static const Color _normalBackground = Color(0xFFC8F0E2);
  static const Color _pressedBackground = Color(0xFFA5DCCB);
  static const Color _iconColor = Color(0xFF004D40);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        splashColor: const Color(0x40004D40),
        highlightColor: const Color(0x20004D40),
        onHighlightChanged: (bool value) {
          if (mounted) setState(() => _pressed = value);
        },
        onTap: widget.onTap,
        child: Container(
          width: 48,
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: _pressed ? _pressedBackground : _normalBackground,
            shape: BoxShape.circle,
          ),
          child: widget.iconWidget ??
              Icon(widget.icon, color: _iconColor, size: 22),
        ),
      ),
    );
  }
}

/// Money-transfer icon drawn to match the reference artwork.
/// Top half yellow #FFC107, bottom half pink #FFCDD2, with navy inner details.
Widget _moneyTransferIcon({double size = 24}) => SizedBox(
      width: size,
      height: size * 1760 / 2048,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          CustomPaint(painter: _MoneyTransferOutlinePainter()),
          ShaderMask(
            blendMode: BlendMode.srcIn,
            shaderCallback: (Rect rect) => const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: <Color>[
                Color(0xFFFFC107),
                Color(0xFFFFC107),
                Color(0xFFFFCDD2),
                Color(0xFFFFCDD2),
              ],
              stops: <double>[0, 0.489, 0.489, 1],
            ).createShader(rect),
            child: CustomPaint(painter: _MoneyTransferPainter()),
          ),
          CustomPaint(painter: _MoneyTransferNavyPainter()),
          Align(
            alignment: const Alignment(0.14, 0.01),
            child: Text(
              'Ks',
              style: TextStyle(
                color: const Color(0xFFFFC107),
                fontWeight: FontWeight.w900,
                fontSize: size * 0.3,
                height: 1,
              ),
            ),
          ),
        ],
      ),
    );

class _MoneyTransferPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double s = size.width / 2048;
    canvas.save();
    canvas.scale(s);

    // Bill body with two white cut-outs where the arrows bend in
    final Path bill = Path()
      ..addRRect(RRect.fromRectAndRadius(
        const Rect.fromLTRB(238, 285, 1862, 1497),
        const Radius.circular(190),
      ));
    final Path topCut = Path()
      ..addOval(Rect.fromCircle(center: const Offset(415, 590), radius: 225));
    final Path bottomCut = Path()
      ..addOval(Rect.fromCircle(center: const Offset(1690, 1230), radius: 230));
    final Path body = Path.combine(
      PathOperation.difference,
      Path.combine(PathOperation.difference, bill, topCut),
      bottomCut,
    );
    canvas.drawPath(body, Paint()..color = Colors.white);

    final Paint arrow = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 150
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Left arrow (top half)
    canvas.drawPath(
      Path()
        ..moveTo(430, 130)
        ..lineTo(185, 360)
        ..lineTo(430, 600)
        ..moveTo(185, 360)
        ..lineTo(900, 360),
      arrow,
    );
    // Right arrow (bottom half)
    canvas.drawPath(
      Path()
        ..moveTo(1690, 1190)
        ..lineTo(1935, 1430)
        ..lineTo(1690, 1670)
        ..moveTo(1935, 1430)
        ..lineTo(1150, 1430),
      arrow,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// White outer border that surrounds the bill and both arrows.
class _MoneyTransferOutlinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const double ring = 158; // 2 px white border at 26 px icon size
    final double s = size.width / 2048;
    canvas.save();
    canvas.scale(s);
    final Paint white = Paint()..color = Colors.white;
    final Paint whiteStroke = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = ring * 2
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;

    final RRect rr = RRect.fromRectAndRadius(
      const Rect.fromLTRB(238, 285, 1862, 1497),
      const Radius.circular(190),
    );
    canvas.drawRRect(rr, white);
    canvas.drawRRect(rr, whiteStroke);

    final Path arrows = Path()
      ..moveTo(430, 130)
      ..lineTo(185, 360)
      ..lineTo(430, 600)
      ..moveTo(185, 360)
      ..lineTo(900, 360)
      ..moveTo(1690, 1190)
      ..lineTo(1935, 1430)
      ..lineTo(1690, 1670)
      ..moveTo(1935, 1430)
      ..lineTo(1150, 1430);
    canvas.drawPath(
      arrows,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 150 + ring * 2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _MoneyTransferNavyPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double s = size.width / 2048;
    canvas.save();
    canvas.scale(s);
    final Paint navy = Paint()..color = const Color(0xFF10305A);

    // Centre disc
    canvas.drawCircle(const Offset(1050, 890), 305, navy);

    // Top-right corner detail
    canvas.drawPath(
      Path()
        ..moveTo(1462, 500)
        ..quadraticBezierTo(1500, 650, 1630, 688)
        ..quadraticBezierTo(1660, 692, 1660, 662)
        ..lineTo(1660, 512)
        ..quadraticBezierTo(1660, 486, 1634, 486)
        ..lineTo(1490, 486)
        ..quadraticBezierTo(1462, 486, 1462, 500)
        ..close(),
      navy,
    );

    // Bottom-left corner detail
    canvas.drawPath(
      Path()
        ..moveTo(443, 1270)
        ..quadraticBezierTo(443, 1295, 470, 1295)
        ..lineTo(615, 1295)
        ..quadraticBezierTo(645, 1295, 640, 1260)
        ..quadraticBezierTo(620, 1120, 490, 1100)
        ..quadraticBezierTo(443, 1098, 443, 1140)
        ..close(),
      navy,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Price tag icon (navy) with a grey metal keyring in the hole.
Widget _tagIcon({double size = 24}) => SizedBox.square(
      dimension: size,
      child: CustomPaint(painter: _TagPainter()),
    );

class _TagPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Drawn on a 340-unit grid, centred on the tag's bounding box.
    final double s = size.width / 340;
    canvas.save();
    canvas.translate(size.width / 2 - 335 * s, size.height / 2 - 288 * s);
    canvas.scale(s);

    final Path tag = Path()
      ..moveTo(208, 140)
      ..lineTo(334, 140)
      ..quadraticBezierTo(340, 140, 346, 146)
      ..lineTo(479, 279)
      ..quadraticBezierTo(490, 290, 479, 301)
      ..lineTo(351, 429)
      ..quadraticBezierTo(340, 440, 329, 429)
      ..lineTo(186, 286)
      ..lineTo(186, 162)
      ..quadraticBezierTo(186, 140, 208, 140)
      ..close();

    final Offset hole = const Offset(257, 212);
    final Path holeOuter = Path()
      ..addOval(Rect.fromCircle(center: hole, radius: 44));
    final Path holeInner = Path()
      ..addOval(Rect.fromCircle(center: hole, radius: 22));

    // White outer border around the whole tag
    canvas.drawPath(tag, Paint()..color = Colors.white);
    canvas.drawPath(
      tag,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 58 // 2 px white border at 23 px icon size
        ..strokeJoin = StrokeJoin.round,
    );

    // Yellow body with the hole cut out
    canvas.drawPath(
      Path.combine(PathOperation.difference, tag, holeInner),
      Paint()..color = const Color(0xFFFFC107),
    );
    // White ring around the hole
    canvas.drawPath(
      Path.combine(PathOperation.difference, holeOuter, holeInner),
      Paint()..color = Colors.white,
    );

    // Silver keyring passing through the hole
    canvas.drawCircle(
      const Offset(228, 170),
      46,
      Paint()
        ..color = const Color(0xFFB0BEC5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 14,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Icon-only cloud button for the Money Txn AppBar: coloured cloud with a
/// white, slightly larger arrow inside.
class _CloudIconButton extends StatelessWidget {
  const _CloudIconButton({
    required this.cloudColor,
    required this.arrowIcon,
    required this.onTap,
  });

  final Color cloudColor;
  final IconData arrowIcon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 24,
          height: 24,
          child: Stack(
            alignment: Alignment.center,
            children: <Widget>[
              Icon(Icons.cloud_rounded, color: cloudColor, size: 24),
              Padding(
                padding: const EdgeInsets.only(top: 3),
                child: Icon(arrowIcon, color: Colors.white, size: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Coloured cloud with a white arrow inside (Back Up = green up, Restore = blue down).
Widget _cloudArrowGlyph({required Color cloud, required IconData arrow}) =>
    SizedBox(
      width: 24,
      height: 24,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          Icon(Icons.cloud_rounded, color: cloud, size: 24),
          Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Icon(arrow, color: Colors.white, size: 13),
          ),
        ],
      ),
    );

