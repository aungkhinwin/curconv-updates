import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'backup_data.dart';
import 'cloud_auth_panel.dart';
import 'cloud_auth_service.dart';
import 'cloud_backup_repository.dart';

class BackupScreen extends StatefulWidget {
  const BackupScreen({super.key, this.auth, this.repository, this.autoAction});
  final CloudAuthService? auth;
  final CloudBackupRepository? repository;
  // 'backup' or 'restore': runs that action once the account is ready.
  final String? autoAction;
  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  late final CloudAuthService _auth;
  late final CloudBackupRepository _repository;
  StreamSubscription<CloudAccount?>? _subscription;
  CloudAccount? _account;
  bool _loadingAccount = true;
  bool _isLoading = false;
  bool _authBusy = false;
  bool _restored = false;
  bool _autoRan = false;
  String? _status;
  bool _error = false;
  static const Duration _networkTimeout = Duration(seconds: 30);
  bool get _busy => _isLoading || _authBusy;

  @override
  void initState() {
    super.initState();
    _auth = widget.auth ?? FirebaseCloudAuth();
    _repository = widget.repository ?? FirestoreCloudBackups();
    _account = _auth.current;
    _subscription = _auth.changes.listen((CloudAccount? account) {
      if (!mounted) return;
      setState(() {
        _account = account;
        _loadingAccount = false;
      });
      if (!_autoRan && widget.autoAction != null) {
        _autoRan = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          if (_account?.verified != true) {
            _message('Email အတည်ပြုပြီးမှ သုံးနိုင်ပါမည်။');
            return;
          }
          if (widget.autoAction == 'restore') {
            _restoreData();
          } else {
            _backupData();
          }
        });
      }
    }, onError: (Object error) {
      if (!mounted) return;
      setState(() {
        _loadingAccount = false;
        _status = cloudAuthError(error);
        _error = true;
      });
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  void _message(String message, {bool error = false}) {
    if (!mounted) return;
    setState(() {
      _status = message;
      _error = error;
    });
  }

  void _sameAccount(String uid) {
    final CloudAccount? account = _auth.current;
    if (account?.uid != uid || account?.verified != true) {
      throw StateError(
          'အကောင့် သို့မဟုတ် Email အတည်ပြုအခြေအနေ ပြောင်းသွားပါသည်။ Login ပြန်စစ်ပါ။');
    }
  }

  CloudAccount? _readyAccount() {
    final CloudAccount? account = _auth.current;
    if (account == null || !account.verified) {
      _message('Login ဝင်ပြီး Email ကို အတည်ပြုရန်လိုပါသည်။', error: true);
      return null;
    }
    return account;
  }

  Future<bool> _confirm(String title, String message, String action) async {
    if (!mounted) return false;
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext dialogContext) => AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: <Widget>[
              TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('မလုပ်တော့ပါ')),
              FilledButton(
                  onPressed: () => Navigator.pop(dialogContext, true),
                  child: Text(action)),
            ],
          ),
        ) ??
        false;
  }

  String _errorMessage(Object error, {bool writing = false}) {
    if (error is TimeoutException) {
      return writing
          ? 'Cloud အတည်ပြုချက်အတွက် အချိန်ကုန်သွားပါသည်။ Write ဆက်လုပ်နေနိုင်သဖြင့် ထပ်မသိမ်းခင် ချိတ်ဆက်မှု ပြန်စစ်ပါ။'
          : 'Cloud ဆာဗာချိတ်ဆက်မှု အချိန်ကုန်သွားပါသည်။ Network၊ Firestore database နဲ့ Android Internet permission ကို စစ်ပါ။';
    }
    if (error is FirebaseException) {
      switch (error.code) {
        case 'permission-denied':
          return 'Cloud ခွင့်ပြုချက် မရှိပါ (permission-denied)။ Email အတည်ပြုခြင်းနဲ့ UID-only Firestore Rules ကို စစ်ပါ။';
        case 'unauthenticated':
          return 'Login သက်တမ်းကုန်သွားနိုင်ပါသည်။ Login ပြန်ဝင်ပါ (unauthenticated)။';
        case 'unavailable':
          return 'Firestore ချိတ်ဆက်မရပါ (unavailable)။ Network/VPN၊ Android INTERNET permission၊ Firestore (default) database ဖွင့်ထားမှုကို စစ်ပါ။';
        default:
          return 'Firebase error (${error.code}): ${error.message ?? ''}';
      }
    }
    if (error is FormatException) return 'ဒေတာ မမှန်ပါ: ${error.message}';
    return error.toString();
  }

  Future<void> _backupData() async {
    if (_busy) return;
    final CloudAccount? account = _readyAccount();
    if (account == null) return;
    setState(() {
      _isLoading = true;
      _status = null;
    });
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final BackupData backup = BackupData.fromMap(<String, dynamic>{
        for (final String key in BackupData.keys)
          key: prefs.getStringList(key) ?? <String>[],
      });
      if (backup.estimatedBytes > 900 * 1024) {
        throw StateError(
            'Backup အရွယ်အစား ကြီးလွန်းပါသည်။ ခွဲသိမ်းစနစ် လိုပါသည်။');
      }
      _sameAccount(account.uid);
      final Map<String, dynamic>? existing =
          await _repository.read(account.uid).timeout(_networkTimeout);
      if (!mounted) return;
      _sameAccount(account.uid);
      final bool confirmed = await _confirm(
        'ဒီအကောင့်သို့ Backup သိမ်းရန်',
        '${account.email} ရဲ့ Cloud ပေါ်သို့ ဒီဖုန်းရှိ မှတ်တမ်း ${backup.recordCount} ခု သိမ်းပါမည်။ '
            '${existing == null ? 'ဒီအကောင့်အတွက် Backup အသစ်ဖြစ်ပါသည်။' : 'Cloud Backup အဟောင်းကို အစားထိုးပါမည်။'} '
            'Local စာရင်းတွေက Login အကောင့်ပြောင်းလည်း ဆက်ရှိနေသဖြင့် ဒီအကောင့်အတွက် မှန်ကန်သောစာရင်း ဟုတ်မဟုတ် အရင်စစ်ပါ။',
        'သိမ်းမည်',
      );
      if (!mounted || !confirmed) return;
      _sameAccount(account.uid);
      await _repository.save(account.uid, backup).timeout(_networkTimeout);
      if (!mounted) return;
      _sameAccount(account.uid);
      _message(
          'Cloud ပေါ်သို့ မှတ်တမ်း ${backup.recordCount} ခု သိမ်းဆည်းပြီးပါပြီ။');
    } catch (error) {
      _message(_errorMessage(error, writing: true), error: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _restoreData() async {
    if (_busy) return;
    final CloudAccount? account = _readyAccount();
    if (account == null) return;
    setState(() {
      _isLoading = true;
      _status = null;
    });
    try {
      final Map<String, dynamic>? data =
          await _repository.read(account.uid).timeout(_networkTimeout);
      if (!mounted) return;
      _sameAccount(account.uid);
      if (data == null) {
        _message('ဒီအကောင့်အတွက် Cloud Backup မရှိသေးပါ။');
        return;
      }
      final BackupData backup = validateAccountBackup(data, account.uid);
      final bool confirmed = await _confirm(
        'Cloud မှ ပြန်ယူရန်',
        '${account.email} ရဲ့ Cloud မှတ်တမ်း ${backup.recordCount} ခုနဲ့ ဒီဖုန်းရှိ History၊ ရက်ချုပ်နဲ့ Merchant စာရင်းတွေကို အစားထိုးပါမည်။ ပေါင်းမည်မဟုတ်ပါ။ ဆက်လုပ်မလား?',
        'အစားထိုးပြန်ယူမည်',
      );
      if (!mounted || !confirmed) return;
      _sameAccount(account.uid);
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      if (!mounted) return;
      _sameAccount(account.uid);
      await restoreLocalBackup(prefs, backup);
      if (!mounted) return;
      setState(() => _restored = true);
      _message(
          'မှတ်တမ်းများ ပြန်ယူပြီးပါပြီ။ Main screen ပြန်ရောက်လျှင် စုစုပေါင်းစာရင်း ပြန်ပြပါမည်။');
    } catch (error) {
      _message(_errorMessage(error), error: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _close() => Navigator.of(context).pop(_restored);

  @override
  Widget build(BuildContext context) {
    final bool allowed = _account?.verified == true;
    return PopScope<bool>(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, bool? result) {
        if (!didPop && !_busy) _close();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F7F8),
        appBar: AppBar(
          title: const Text(
            'Cloud Backup',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
          backgroundColor: const Color(0xFF008577),
          foregroundColor: Colors.white,
          elevation: 0,
          flexibleSpace: const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: <Color>[
                  Color(0xFF0E9C8C),
                  Color(0xFF008577),
                  Color(0xFF006D62),
                ],
              ),
            ),
          ),
          leading: IconButton(
            onPressed: _busy ? null : _close,
            icon: const Icon(Icons.arrow_back),
          ),
        ),
        body: _loadingAccount
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    const Text(
                      'Email သို့မဟုတ် Google account နဲ့ Login ဝင်ပြီး သင့်အကောင့်ရဲ့ Cloud Backup ကို သုံးနိုင်ပါသည်။',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF24415A),
                        fontSize: 15,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Account card: white rounded surface with a soft mint glow
                    Container(
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: <Color>[Color(0xFFFFFFFF), Color(0xFFF1FAF6)],
                        ),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          color: const Color(0xFFBFE8D5),
                          width: 1.2,
                        ),
                        boxShadow: const <BoxShadow>[
                          BoxShadow(
                            color: Color(0x2600B96B),
                            blurRadius: 24,
                            spreadRadius: 1,
                            offset: Offset(0, 8),
                          ),
                        ],
                      ),
                      child: CloudAuthPanel(
                          auth: _auth,
                          account: _account,
                          disabled: _isLoading,
                          onBusy: (bool busy) {
                            if (mounted) setState(() => _authBusy = busy);
                          },
                          onMessage: (String text) => _message(text)),
                    ),
                    if (allowed) ...<Widget>[
                      const SizedBox(height: 18),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Container(
                            width: 36,
                            height: 36,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: <Color>[
                                  Color(0xFF3CD68F),
                                  Color(0xFF00B96B),
                                ],
                              ),
                              boxShadow: <BoxShadow>[
                                BoxShadow(
                                  color: const Color(0x6600B96B),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(Icons.info_rounded,
                                color: Colors.white, size: 22),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'ဖုန်းထဲရှိ History၊ ရက်ချုပ်နဲ့ Merchant စာရင်း ၃ မျိုးကိုသာ သိမ်းပါမည်။ Login ဝင်ရုံနဲ့ အလိုအလျောက် Backup/Restore မလုပ်ပါ။',
                              style: TextStyle(
                                color: Color(0xFF24415A),
                                fontSize: 14,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: _BackupPillButton(
                              label: 'Backup လုပ်မည်',
                              icon: Icons.cloud_upload_rounded,
                              colors: const <Color>[
                                Color(0xFF3CD68F),
                                Color(0xFF00B96B),
                              ],
                              onTap: _busy ? null : _backupData,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _BackupPillButton(
                              label: 'ပြန်လည်ရယူမည်',
                              icon: Icons.cloud_download_rounded,
                              colors: const <Color>[
                                Color(0xFF5DB8FF),
                                Color(0xFF168FE5),
                              ],
                              onTap: _busy ? null : _restoreData,
                            ),
                          ),
                        ],
                      ),
                      if (_isLoading) ...<Widget>[
                        const SizedBox(height: 12),
                        const Center(child: CircularProgressIndicator())
                      ],
                    ],
                    if (_status != null) ...<Widget>[
                      const SizedBox(height: 16),
                      Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                              color: _error
                                  ? const Color(0xFFFFE8E5)
                                  : const Color(0xFFE0F2F1),
                              borderRadius: BorderRadius.circular(14)),
                          child: SelectableText(_status!,
                              style: TextStyle(
                                  color: _error
                                      ? const Color(0xFF8A2015)
                                      : const Color(0xFF005247)))),
                    ],
                  ],
                ),
              ),
      ),
    );
  }
}

/// Compact 3D action card (side by side) used for Back Up and Restore.
/// Raised look: tinted body, bright top rim, deep coloured shadow, glossy icon.
class _BackupActionCard extends StatelessWidget {
  const _BackupActionCard({
    required this.title,
    required this.subtitle,
    required this.caption,
    required this.icon,
    required this.accent,
    required this.surface,
    required this.titleColor,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final String caption;
  final IconData icon;
  final Color accent;
  final Color surface;
  final Color titleColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final bool enabled = onTap != null;
    final Color bright = Color.lerp(accent, Colors.white, 0.35)!;
    final Color deep = Color.lerp(accent, Colors.black, 0.12)!;
    return Opacity(
      opacity: enabled ? 1 : 0.6,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(26),
          onTap: onTap,
          child: Ink(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: <Color>[
                  Color.lerp(surface, Colors.white, 0.6)!,
                  surface,
                  Color.lerp(surface, accent, 0.22)!,
                ],
              ),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: accent.withValues(alpha: 0.38),
                  blurRadius: 22,
                  offset: const Offset(0, 12),
                ),
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.9),
                  blurRadius: 4,
                  offset: const Offset(-2, -2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    // Glossy 3D icon tile
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: <Color>[bright, accent, deep],
                        ),
                        boxShadow: <BoxShadow>[
                          BoxShadow(
                            color: accent.withValues(alpha: 0.55),
                            blurRadius: 14,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Stack(
                        children: <Widget>[
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(18),
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: <Color>[
                                    Colors.white.withValues(alpha: 0.5),
                                    Colors.white.withValues(alpha: 0.0),
                                  ],
                                  stops: const <double>[0, 0.55],
                                ),
                              ),
                            ),
                          ),
                          Center(
                            child: Icon(icon, color: Colors.white, size: 36),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    // Raised chevron button
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: <Color>[bright, accent],
                        ),
                        boxShadow: <BoxShadow>[
                          BoxShadow(
                            color: accent.withValues(alpha: 0.5),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.chevron_right_rounded,
                          color: Colors.white, size: 20),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: TextStyle(
                    color: titleColor,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: titleColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  caption,
                  style: const TextStyle(
                    color: Color(0xFF5F7A8A),
                    fontSize: 12,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Glossy 3D pill button (cloud icon, label, chevron) used for Backup and Restore.
class _BackupPillButton extends StatelessWidget {
  const _BackupPillButton({
    required this.label,
    required this.icon,
    required this.colors,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final List<Color> colors;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: onTap == null ? 0.6 : 1,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(30),
          onTap: onTap,
          child: Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: colors,
              ),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.7),
                width: 1.5,
              ),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: colors.last.withValues(alpha: 0.45),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: <Widget>[
                Icon(icon, color: Colors.white, size: 26),
                const SizedBox(width: 6),
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      label,
                      maxLines: 1,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                const Icon(Icons.chevron_right_rounded,
                    color: Colors.white, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

