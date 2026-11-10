import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'access_backend.dart';
import 'cloud_auth_panel.dart';
import 'cloud_auth_service.dart';
import 'customer_access.dart';
import 'customer_notice.dart';
import 'payment_screen.dart';

class CustomerAccessGate extends StatefulWidget {
  const CustomerAccessGate({
    super.key,
    required this.child,
    this.auth,
    required this.backend,
    this.showNotices = true,
  });
  final Widget child;
  final CloudAuthService? auth;
  final AccessBackend backend;
  final bool showNotices;
  @override
  State<CustomerAccessGate> createState() => CustomerAccessGateState();
}

class CustomerAccessGateState extends State<CustomerAccessGate>
    with WidgetsBindingObserver {
  late final CloudAuthService _auth;
  late final AccessBackend _backend;
  StreamSubscription<CloudAccount?>? _authSubscription;
  StreamSubscription<AccessEvent>? _accessSubscription;
  Timer? _leaseTimer;
  Timer? _onlineTimer;
  Timer? _deadlineTimer;
  CloudAccount? _account;
  OfflineLease? _lease;
  bool _allowed = false;
  bool _checking = false;
  // True until the first online check for a signed-in, verified account finishes.
  bool _booting = true;
  bool _busyAuth = false;
  bool _adminAuthorized = false;
  int _restoringGeneration = -1;
  int _generation = 0;
  String _message = 'Login ဝင်ပြီး ၇ ရက် အခမဲ့ စမ်းသုံးနိုင်ပါသည်။';

  @override
  void initState() {
    // Safety net: never leave the loading screen stuck. After 15 seconds the
    // login/payment panel (with its retry button) is shown instead.
    Future<void>.delayed(const Duration(seconds: 15), () {
      if (mounted && _booting) setState(() => _booting = false);
    });
    super.initState();
    _auth = widget.auth ?? FirebaseCloudAuth();
    _backend = widget.backend;
    WidgetsBinding.instance.addObserver(this);
    _acceptAccount(_auth.current);
    _authSubscription = _auth.changes.listen(
      _acceptAccount,
      onError: (Object error) => _deny('Login အခြေအနေ မစစ်နိုင်ပါ။'),
    );
    _leaseTimer = Timer.periodic(
      const Duration(seconds: 15),
      (_) => _checkLease(),
    );
    _onlineTimer = Timer.periodic(
      const Duration(minutes: 5),
      (_) => _checkOnline(),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _authSubscription?.cancel();
    _accessSubscription?.cancel();
    _leaseTimer?.cancel();
    _onlineTimer?.cancel();
    _deadlineTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final account = _account;
      if (account?.verified == true) {
        unawaited(_restoreOfflineThenCheck(account!.uid, _generation));
      } else if (_allowed) {
        unawaited(_checkLease());
      }
    }
  }

  void _closeOtherRoutes() {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_allowed) {
        Navigator.of(
          context,
          rootNavigator: true,
        ).popUntil((route) => route.isFirst);
      }
    });
  }

  void _deny(String message) {
    _deadlineTimer?.cancel();
    _adminAuthorized = false;
    if (!mounted) return;
    setState(() {
      _allowed = false;
      _lease = null;
      _message = message;
    });
    _closeOtherRoutes();
  }

  void _acceptAccount(CloudAccount? next) {
    if (_account?.uid == next?.uid &&
        _account?.verified == next?.verified &&
        _account?.email == next?.email) {
      return;
    }
    final String? previous = _account?.uid;
    _generation++;
    _accessSubscription?.cancel();
    _checking = false;
    _account = next;
    _deny(
      next == null
          ? 'Login ဝင်ပြီး ၇ ရက် အခမဲ့ စမ်းသုံးနိုင်ပါသည်။'
          : 'အသုံးပြုခွင့် စစ်ဆေးနေပါသည်။',
    );
    if (previous != null && previous != next?.uid) {
      unawaited(_backend.clearLocal());
    }
    if (next == null || !next.verified) return;
    unawaited(_activateAccount(next, _generation));
  }

  Future<void> _activateAccount(CloudAccount account, int generation) async {
    final String uid = account.uid;
    try {
      final DocumentSnapshot<Map<String, dynamic>> adminSnapshot =
          await FirebaseFirestore.instance
              .collection('admins')
              .doc(uid)
              .get(const GetOptions(source: Source.server));
      if (!mounted || generation != _generation || _account?.uid != uid) return;
      if (adminSnapshot.data()?['enabled'] == true) {
        _adminAuthorized = true;
        setState(() {
          _allowed = true;
          _lease = null;
          _message = 'Admin эрхээр нэвтэрсэн байна.';
        });
        return;
      }
    } catch (_) {
      // If the admin lookup is unavailable, continue through the normal
      // customer access checks instead of granting privileged access.
    }
    _accessSubscription = _backend
        .changes(uid)
        .listen(
          (event) {
            if (!mounted || _account?.uid != uid || event.fromCache) return;
            final access = event.access;
            if (access == null) {
              _deny('အသုံးပြုခွင့် မတွေ့ပါ။ ပြန်စစ်ပါ။');
            } else if (access.status == 'blocked') {
              _generation++;
              _checking = false;
              unawaited(_backend.clearLocal());
              _deny('Admin မှ အသုံးပြုခွင့် ယာယီပိတ်ထားပါသည်။');
            } else if (_lease != null &&
                access.expiresAt != _lease!.expiresAt) {
              // Any changed expiry must be server-verified again before continuing.
              _generation++;
              _checking = false;
              unawaited(
                _backend.clearLocal().then((_) {
                  if (mounted && _account?.uid == uid) return _checkOnline();
                }),
              );
              _deny('အသုံးပြုခွင့် ပြောင်းလဲထားပါသည်။ ပြန်စစ်နေပါသည်။');
            }
          },
          onError: (Object error) {
            if (_account?.uid != uid) return;
            if (error is FirebaseException &&
                error.code == 'permission-denied') {
              _generation++;
              _checking = false;
              unawaited(_backend.clearLocal());
              _deny('ဆာဗာမှ ခွင့်ပြုချက်မရပါ။ Login နဲ့ Rules ကို စစ်ပါ။');
            }
          },
        );
    unawaited(_restoreOfflineThenCheck(uid, generation));
  }

  Future<void> _restoreOfflineThenCheck(String uid, int generation) async {
    if (_restoringGeneration == generation) return;
    _restoringGeneration = generation;
    // True when a valid local lease (paid/trial, not yet expired) was restored.
    // Such accounts open straight away without a server check on every start;
    // the lease's own deadline timer forces a server check when it runs out.
    bool restoredLease = false;
    try {
      final lease = await _backend
          .checkOffline(uid)
          .timeout(const Duration(seconds: 4));
      if (!mounted || generation != _generation || _account?.uid != uid) {
        return;
      }
      if (lease != null) {
        restoredLease = true;
        _scheduleDeadline(lease);
        setState(() {
          _lease = lease;
          _allowed = true;
          _message = 'သက်တမ်းကုန်ရက်: ${formatAccessDate(lease.expiresAt)}';
        });
      }
    } on TimeoutException {
      // A slow local secure-storage read must not leave the app in a loading state.
    } catch (_) {
      // Continue with the normal online check when local access cannot be read.
    } finally {
      if (_restoringGeneration == generation) _restoringGeneration = -1;
      if (mounted &&
          generation == _generation &&
          _account?.uid == uid &&
          !restoredLease) {
        unawaited(_checkOnline());
      }
    }
  }

  void _scheduleDeadline(OfflineLease lease) {
    _deadlineTimer?.cancel();
    final offlineEnd = lease.serverAt.add(const Duration(hours: 24));
    final end =
        offlineEnd.isBefore(lease.expiresAt) ? offlineEnd : lease.expiresAt;
    final elapsed = DateTime.now().toUtc().difference(lease.wallAt);
    final remaining =
        end.difference(lease.serverAt).inMilliseconds - elapsed.inMilliseconds;
    _deadlineTimer = Timer(
      Duration(milliseconds: remaining < 0 ? 0 : remaining),
      () {
        _deny('Offline ခွင့် သို့မဟုတ် အသုံးပြုသက်တမ်းကုန်ပါပြီ။ ပြန်စစ်ပါ။');
        unawaited(_checkOnline());
      },
    );
  }

  Future<void> _checkLease() async {
    final account = _account;
    if (!_allowed || _adminAuthorized || account == null || _checking) return;
    final int generation = _generation;
    final lease = await _backend.checkOffline(account.uid);
    if (!mounted || generation != _generation || !_allowed) return;
    if (lease == null) {
      _deny(
        'Offline ခွင့် သို့မဟုတ် အသုံးပြုသက်တမ်းကုန်ပါပြီ။ အင်တာနက်ချိတ်ပြီး ပြန်စစ်ပါ။',
      );
      unawaited(_checkOnline());
    }
  }

  Future<void> _checkOnline() async {
    final account = _account;
    if (_adminAuthorized || _checking || account == null || !account.verified) return;
    final int generation = _generation;
    setState(() => _checking = true);
    try {
      final result = await _backend.checkOnline(account);
      if (!mounted || generation != _generation) return;
      _scheduleDeadline(result.lease);
      setState(() {
        _lease = result.lease;
        _allowed = true;
        _message =
            'သက်တမ်းကုန်ရက်: ${formatAccessDate(result.access.expiresAt)}';
      });
    } catch (error) {
      if (!mounted || generation != _generation) return;
      if (error is AccessDenied ||
          (error is FirebaseException && error.code == 'permission-denied')) {
        await _backend.clearLocal();
        if (mounted && generation == _generation) {
          _deny(
            error is AccessDenied
                ? error.message
                : 'ဆာဗာခွင့်ပြုချက်မရပါ။ Firebase Rules ကို စစ်ပါ။',
          );
        }
      } else if (error is FirebaseException &&
          <String>{
            'unavailable',
            'deadline-exceeded',
            'network-request-failed',
          }.contains(error.code)) {
        final lease = await _backend.checkOffline(account.uid);
        if (!mounted || generation != _generation) return;
        if (lease == null) {
          _deny('အင်တာနက်ချိတ်ပြီး အသုံးပြုခွင့် ပြန်စစ်ရန်လိုပါသည်။');
        } else {
          _scheduleDeadline(lease);
          setState(() {
            _lease = lease;
            _allowed = true;
          });
        }
      } else {
        _deny('အသုံးပြုခွင့် မစစ်နိုင်ပါ: $error');
      }
    } finally {
      if (mounted && generation == _generation) {
        setState(() {
          _checking = false;
          _booting = false;
        });
      }
    }
  }

  void showAccount() {
    showDialog<void>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('အကောင့်နှင့် အသုံးပြုခွင့်'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(_message),
                  if (widget.showNotices) const CustomerNotice(),
                  if (_lease != null)
                    Text(
                      'Offline ပြန်ချိတ်ရန်: ${formatAccessDate(_lease!.serverAt.add(const Duration(hours: 24)).isBefore(_lease!.expiresAt) ? _lease!.serverAt.add(const Duration(hours: 24)) : _lease!.expiresAt)}',
                    ),
                  CloudAuthPanel(
                    auth: _auth,
                    account: _account,
                    onBusy: (_) {},
                    onMessage: _notice,
                  ),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                onPressed: _checking ? null : _checkOnline,
                child: const Text('ပြန်စစ်'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('ပိတ်မည်'),
              ),
            ],
          ),
    );
  }

  void _notice(String message) {
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_allowed && _account != null) {
      return KeyedSubtree(
        key: ValueKey<String>(_account!.uid),
        child: widget.child,
      );
    }
    // Paid or trial users: show a short loading screen while the server check
    // runs, instead of flashing the login/payment panel on every start.
    if (_booting && _account != null && _account!.verified) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              CircularProgressIndicator(),
              SizedBox(height: 12),
              Text('အသုံးပြုခွင့် စစ်ဆေးနေပါသည်။'),
            ],
          ),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('CurConv အသုံးပြုခွင့်')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            const Text(
              'Email သို့မဟုတ် Google နဲ့ Login ဝင်ပါ။ အကောင့်အသစ်ကို ၇ ရက် အခမဲ့စမ်းသုံးခွင့်ပေးပါသည်။',
            ),
            const SizedBox(height: 8),
            CloudAuthPanel(
              auth: _auth,
              account: _account,
              disabled: _busyAuth,
              onBusy: (value) {
                if (mounted) setState(() => _busyAuth = value);
              },
              onMessage: _notice,
            ),
            if (_account != null && !_account!.verified)
              const Text('App စသုံးရန် Email ကို အတည်ပြုပါ။'),
            Text(_message, textAlign: TextAlign.center),
            if (_account?.verified == true)
              FilledButton.icon(
                onPressed: () async {
                  await Navigator.of(context).push<void>(
                    MaterialPageRoute<void>(
                      builder: (_) => const PaymentScreen(),
                    ),
                  );
                  if (mounted) unawaited(_checkOnline());
                },
                icon: const Icon(Icons.receipt_long_rounded),
                label: const Text('ငွေပေးချေပြီး သက်တမ်းတိုးရန်'),
              ),
            if (_account?.verified == true)
              FilledButton(
                onPressed: _checking ? null : _checkOnline,
                child: const Text('အင်တာနက်ချိတ်ပြီး ပြန်စစ်မည်'),
              ),
            const SizedBox(height: 8),
            const Text(
              'ပထမဆုံးအကြိမ် အင်တာနက်လိုပါသည်။ နောက်ဆုံးခွင့်ပြုချက်မှ ၂၄ နာရီအတွင်းသာ offline သုံးနိုင်သည်။ နာရီပြောင်းခြင်း/ဖုန်း restart ဖြစ်လျှင် ပြန်ချိတ်စစ်ရန် လိုနိုင်သည်။ စာရင်းဒေတာ မဖျက်ပါ။',
            ),
            if (widget.showNotices && _account?.verified == true)
              const CustomerNotice(),
          ],
        ),
      ),
    );
  }
}

String formatAccessDate(DateTime value) {
  final local = value.toLocal();
  return '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')} ${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
}
