import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

const String _paymentReceipts = 'paymentReceipts';
const int _monthlyFee = 15000;
const String _walletNumber = '09755411121';
const String _walletName = 'MG NYI NYI HTUN LWIN';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  late final Future<bool> _adminFuture;

  @override
  void initState() {
    super.initState();
    _adminFuture = _checkAdmin();
  }

  Future<bool> _checkAdmin() async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null || !user.emailVerified) return false;
    final DocumentSnapshot<Map<String, dynamic>> snapshot =
        await FirebaseFirestore.instance.collection('admins').doc(user.uid).get();
    return snapshot.data()?['enabled'] == true;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _adminFuture,
      builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final bool isAdmin = snapshot.data == true;
        if (!isAdmin) return const _CustomerPaymentPage();
        return DefaultTabController(
          length: 2,
          child: Scaffold(
            appBar: AppBar(
              title: const Text('ငွေပေးချေမှု'),
              bottom: const TabBar(
                tabs: <Widget>[
                  Tab(text: 'ငွေလွှဲရန်', icon: Icon(Icons.payment_rounded)),
                  Tab(text: 'Admin စာရင်း', icon: Icon(Icons.fact_check_rounded)),
                ],
              ),
            ),
            body: const TabBarView(
              children: <Widget>[
                _CustomerPaymentPage(showAppBar: false),
                _AdminPaymentInbox(),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CustomerPaymentPage extends StatefulWidget {
  const _CustomerPaymentPage({this.showAppBar = true});

  final bool showAppBar;

  @override
  State<_CustomerPaymentPage> createState() => _CustomerPaymentPageState();
}

class _CustomerPaymentPageState extends State<_CustomerPaymentPage> {
  final ImagePicker _picker = ImagePicker();
  XFile? _receipt;
  String? _activeRequestId;
  bool _sending = false;

  String? _contentType(String path) {
    final String lower = path.toLowerCase();
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    return null;
  }

  Future<void> _pickReceipt() async {
    try {
      final XFile? file = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1800,
      );
      if (file == null || !mounted) return;
      if (_contentType(file.path) == null) {
        _notice('JPG, PNG သို့မဟုတ် WebP ဓာတ်ပုံကို ရွေးချယ်ပါ။');
        return;
      }
      final int bytes = await file.length();
      if (bytes > 5 * 1024 * 1024) {
        _notice('ပြေစာပုံအရွယ်အစား 5 MB ထက် မကျော်ရပါ။');
        return;
      }
      setState(() => _receipt = file);
    } catch (error) {
      _notice('ပြေစာပုံ ဖွင့်မရပါ: $error');
    }
  }

  Future<void> _submit() async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null || !user.emailVerified) {
      _notice('အတည်ပြုပြီးသော အကောင့်ဖြင့် Login ဝင်ပါ။');
      return;
    }
    final XFile? receipt = _receipt;
    if (receipt == null) {
      _notice('ငွေလွှဲပြေစာပုံကို ရွေးပါ။');
      return;
    }
    final String? type = _contentType(receipt.path);
    if (type == null) {
      _notice('JPG, PNG သို့မဟုတ် WebP ပုံကို ရွေးပါ။');
      return;
    }
    setState(() => _sending = true);
    try {
      final FirebaseFirestore db = FirebaseFirestore.instance;
      final CollectionReference<Map<String, dynamic>> requests =
          db.collection('paymentRequests');
      String requestId = _activeRequestId ?? requests.doc().id;
      _activeRequestId = requestId;
      final String path = '$_paymentReceipts/${user.uid}/$requestId/receipt';
      final DocumentReference<Map<String, dynamic>> requestRef =
          requests.doc(requestId);
      final DocumentSnapshot<Map<String, dynamic>> existing =
          await requestRef.get();
      if (!existing.exists) {
        await requestRef.set(<String, dynamic>{
          'uid': user.uid,
          'email': user.email ?? '',
          'amount': _monthlyFee,
          'receiptPath': path,
          'status': 'pending',
          'createdAt': FieldValue.serverTimestamp(),
        });
      } else if (existing.data()?['uid'] != user.uid ||
          existing.data()?['status'] != 'pending') {
        throw StateError('ဤတောင်းဆိုမှုကို ပြန်လည်အသုံးပြု၍ မရပါ။');
      }
      await FirebaseStorage.instance.ref(path).putFile(
            File(receipt.path),
            SettableMetadata(contentType: type),
          );
      if (!mounted) return;
      setState(() {
        _sending = false;
        _receipt = null;
        _activeRequestId = null;
      });
      _notice('တောင်းဆိုမှုနှင့် ပြေစာကို Admin ထံ ပေးပို့ပြီးပါပြီ။ စစ်ဆေးမှုကို စောင့်ပါ။');
    } catch (error) {
      if (!mounted) return;
      setState(() => _sending = false);
      _notice('ပေးပို့မရပါ။ အင်တာနက်ကို စစ်ဆေးပြီး ပြန်ကြိုးစားပါ။ $error');
    }
  }

  void _notice(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('အရင်ဆုံး Login ဝင်ပါ။')));
    }
    return Scaffold(
      appBar: widget.showAppBar
          ? AppBar(title: const Text('ငွေပေးချေ / သက်တမ်းတိုး'))
          : null,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text('တစ်လစာ အခွင့်အရေး', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text('15,000 ကျပ် / 1 လ', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Color(0xFF00796B))),
                  const SizedBox(height: 16),
                  const Divider(),
                  const Text('ငွေလက်ခံအကောင့်', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text('KBZPay'),
                  Text(_walletName, style: const TextStyle(fontWeight: FontWeight.w600)),
                  Row(
                    children: <Widget>[
                      Expanded(child: SelectableText(_walletNumber, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                      IconButton(
                        tooltip: 'နံပါတ်ကူးရန်',
                        onPressed: () async {
                          await Clipboard.setData(const ClipboardData(text: _walletNumber));
                          _notice('KBZPay နံပါတ်ကို ကူးယူပြီးပါပြီ။');
                        },
                        icon: const Icon(Icons.copy_rounded),
                      ),
                    ],
                  ),
                  const Text('အထက်ပါအကောင့်သို့ ငွေလွှဲပြီး ပြေစာပုံကို ပေးပို့ပါ။'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: _sending ? null : _pickReceipt,
            icon: const Icon(Icons.image_outlined),
            label: Text(_receipt == null ? 'ငွေလွှဲပြေစာ ရွေးရန်' : 'ပြေစာပုံ ရွေးပြီးပါပြီ — ပြောင်းရန်နှိပ်ပါ'),
          ),
          if (_receipt != null) ...<Widget>[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(File(_receipt!.path), height: 210, fit: BoxFit.contain),
            ),
          ],
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _sending ? null : _submit,
            icon: _sending
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.send_rounded),
            label: Text(_sending ? 'ပေးပို့နေသည်…' : 'ပြေစာပေးပို့ပြီး တောင်းဆိုရန်'),
          ),
          const SizedBox(height: 10),
          const Text('Admin က ငွေလက်ခံရရှိကြောင်း စစ်ဆေးအတည်ပြုပြီးမှ ၁ လ သက်တမ်း ဖွင့်ပေးပါမည်။ ပြေစာသည် ဤ Firebase အကောင့်နှင့် ချိတ်ဆက်ထားပါသည်။'),
          const SizedBox(height: 18),
          const Text('ကျွန်ုပ်၏ ငွေပေးချေမှု တောင်းဆိုချက်များ', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('paymentRequests')
                .where('uid', isEqualTo: user.uid)
                .orderBy('createdAt', descending: true)
                .limit(10)
                .snapshots(),
            builder: (BuildContext context, AsyncSnapshot<QuerySnapshot<Map<String, dynamic>>> snapshot) {
              if (snapshot.hasError) return Text('တောင်းဆိုမှုအခြေအနေကို ဖတ်မရပါ: ${snapshot.error}');
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              if (snapshot.data!.docs.isEmpty) return const Text('လက်ရှိ တောင်းဆိုချက် မရှိပါ။');
              return Column(
                children: snapshot.data!.docs.map((QueryDocumentSnapshot<Map<String, dynamic>> doc) {
                  final Map<String, dynamic> data = doc.data();
                  final String status = data['status']?.toString() ?? 'unknown';
                  final String label = switch (status) {
                    'pending' => 'Admin စစ်ဆေးနေသည်',
                    'approved' => 'ငွေပေးချေမှု အတည်ပြုပြီးပါပြီ',
                    'rejected' => 'တောင်းဆိုမှုကို ပယ်ချထားသည်',
                    _ => status,
                  };
                  return Card(
                    child: ListTile(
                      leading: Icon(status == 'approved' ? Icons.check_circle : status == 'rejected' ? Icons.cancel : Icons.hourglass_top, color: status == 'approved' ? Colors.green : status == 'rejected' ? Colors.red : Colors.orange),
                      title: Text(label),
                      subtitle: Text('15,000 ကျပ် · ${doc.id}'),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _AdminPaymentInbox extends StatelessWidget {
  const _AdminPaymentInbox();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('paymentRequests')
          .where('status', isEqualTo: 'pending')
          .orderBy('createdAt', descending: true)
          .limit(50)
          .snapshots(),
      builder: (BuildContext context, AsyncSnapshot<QuerySnapshot<Map<String, dynamic>>> snapshot) {
        if (snapshot.hasError) {
          return Center(child: Padding(padding: const EdgeInsets.all(20), child: Text('တောင်းဆိုချက်ကို ဖတ်မရပါ။ Admin အခွင့်အရေးနှင့် Firebase Rules ကို စစ်ဆေးပါ။ ${snapshot.error}')));
        }
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        if (snapshot.data!.docs.isEmpty) return const Center(child: Text('ငွေပေးချေမှု တောင်းဆိုချက်အသစ် မရှိပါ။'));
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (BuildContext context, int index) =>
              _AdminPaymentCard(request: snapshot.data!.docs[index]),
        );
      },
    );
  }
}

class _AdminPaymentCard extends StatelessWidget {
  const _AdminPaymentCard({required this.request});
  final QueryDocumentSnapshot<Map<String, dynamic>> request;

  Future<void> _review(BuildContext context, bool approve) async {
    final User? adminUser = FirebaseAuth.instance.currentUser;
    if (adminUser == null) return;
    try {
      if (approve) {
        final String receiptPath = request.data()['receiptPath'] as String;
        final Uint8List? receiptBytes = await FirebaseStorage.instance
            .ref(receiptPath)
            .getData(5 * 1024 * 1024);
        if (receiptBytes == null || receiptBytes.isEmpty) {
          throw StateError('သိမ်းဆည်းထားသော ပြေစာပုံ မတွေ့ပါ။');
        }
      }
      final FirebaseFirestore db = FirebaseFirestore.instance;
      final DocumentReference<Map<String, dynamic>> requestRef = request.reference;
      final DocumentReference<Map<String, dynamic>> accessRef =
          db.collection('customer_access').doc(request.data()['uid'] as String);
      await db.runTransaction((Transaction transaction) async {
        final DocumentSnapshot<Map<String, dynamic>> requestSnap =
            await transaction.get(requestRef);
        if (!requestSnap.exists || requestSnap.data()?['status'] != 'pending') {
          throw StateError('ဤတောင်းဆိုချက်ကို စစ်ဆေးပြီးဖြစ်သည်။');
        }
        if (approve) {
          final DocumentSnapshot<Map<String, dynamic>> accessSnap =
              await transaction.get(accessRef);
          final Map<String, dynamic>? access = accessSnap.data();
          if (access == null) throw StateError('အသုံးပြုသူ၏ သက်တမ်းမှတ်တမ်း မတွေ့ပါ။');
          final DateTime now = DateTime.now();
          final Timestamp? currentExpiry = access['expires_at'] as Timestamp?;
          final Timestamp? trialStarted =
              access['trial_started_at'] as Timestamp?;
          final DateTime existingExpiry = currentExpiry?.toDate() ??
              trialStarted?.toDate().add(const Duration(days: 7)) ??
              now;
          final DateTime start = existingExpiry.isAfter(now) ? existingExpiry : now;
          transaction.update(accessRef, <String, dynamic>{
            'status': 'active',
            'expires_at': Timestamp.fromDate(start.add(const Duration(days: 30))),
            'updated_at': FieldValue.serverTimestamp(),
          });
        }
        transaction.update(requestRef, <String, dynamic>{
          'status': approve ? 'approved' : 'rejected',
          'reviewedBy': adminUser.uid,
          'reviewedAt': FieldValue.serverTimestamp(),
        });
      });
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(approve ? 'ငွေပေးချေမှုကို အတည်ပြုပြီး ၁ လ သက်တမ်း ဖွင့်ပေးလိုက်ပါပြီ။' : 'တောင်းဆိုမှုကို ပယ်ချလိုက်ပါပြီ။')));
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('လုပ်ဆောင်မှု မအောင်မြင်ပါ: $error')));
      }
    }
  }

  Future<void> _showReceipt(BuildContext context) async {
    try {
      final Uint8List? bytes = await FirebaseStorage.instance
          .ref(request.data()['receiptPath'] as String)
          .getData(5 * 1024 * 1024);
      if (!context.mounted) return;
      if (bytes == null) throw StateError('ပုံ မတွေ့ပါ။');
      await showDialog<void>(
        context: context,
        builder: (BuildContext dialogContext) => AlertDialog(
          title: const Text('ငွေလွှဲပြေစာ'),
          content: SingleChildScrollView(child: Image.memory(bytes, fit: BoxFit.contain)),
          actions: <Widget>[TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('ပိတ်မည်'))],
        ),
      );
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('ပြေစာကို ဖွင့်မရပါ: $error')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> data = request.data();
    final Timestamp? createdAt = data['createdAt'] as Timestamp?;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(data['email']?.toString() ?? 'အီးမေးလ် မရှိပါ', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('UID: ${data['uid']}'),
            Text('တောင်းဆိုထားသော ငွေပမာဏ: ${data['amount']} ကျပ် · ၁ လစာ'),
            Text('တောင်းဆိုချိန်: ${createdAt?.toDate().toLocal() ?? 'အချိန်မသိပါ'}'),
            const SizedBox(height: 8),
            OutlinedButton.icon(onPressed: () => _showReceipt(context), icon: const Icon(Icons.receipt_long), label: const Text('ပြေစာကြည့်ရန်')),
            Row(
              children: <Widget>[
                Expanded(child: OutlinedButton(onPressed: () => _review(context, false), child: const Text('ပယ်ချမည်'))),
                const SizedBox(width: 10),
                Expanded(child: FilledButton(onPressed: () => _review(context, true), child: const Text('ငွေလက်ခံရရှိမှု စစ်ဆေးပြီး အတည်ပြုမည်'))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
