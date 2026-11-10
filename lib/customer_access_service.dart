import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';

import 'cloud_auth_service.dart';
import 'access_backend.dart';
import 'customer_access.dart';

abstract class AccessDevice {
  Future<int> uptime();
  Future<String> bootId();
  Future<String?> readLease();
  Future<void> writeLease(String value);
  Future<void> clearLease();
}

abstract class DeviceMetadataProvider {
  Future<Map<String, String>> deviceInfo();
}

class AndroidAccessDevice implements AccessDevice, DeviceMetadataProvider {
  static const MethodChannel _channel = MethodChannel('curconv/access_clock');
  @override
  Future<int> uptime() async => (await _channel.invokeMethod<int>('uptime'))!;
  @override
  Future<String> bootId() async =>
      (await _channel.invokeMethod<String>('bootIdentity'))!;
  @override
  Future<String?> readLease() => _channel.invokeMethod<String>('readLease');
  @override
  Future<void> writeLease(String value) => _channel
      .invokeMethod<void>('writeLease', <String, String>{'lease': value});
  @override
  Future<void> clearLease() => _channel.invokeMethod<void>('clearLease');

  @override
  Future<Map<String, String>> deviceInfo() async {
    final result = await _channel.invokeMapMethod<String, String>('deviceInfo');
    if (result == null) throw StateError('စက်အချက်အလက် မရရှိပါ။');
    return result;
  }
}

class CustomerAccessService implements AccessBackend {
  CustomerAccessService({FirebaseFirestore? firestore, AccessDevice? device})
      : db = firestore ?? FirebaseFirestore.instance,
        device = device ?? AndroidAccessDevice();
  final FirebaseFirestore db;
  final AccessDevice device;
  int _localRevision = 0;
  DocumentReference<Map<String, dynamic>> ref(String uid) =>
      db.collection('customer_access').doc(uid);

  @override
  Future<AccessResult> checkOnline(CloudAccount account) {
    final revision = _localRevision;
    return _performOnline(account, revision)
        .timeout(const Duration(seconds: 20), onTimeout: () {
      if (_localRevision == revision) _localRevision++;
      throw FirebaseException(
          plugin: 'cloud_firestore',
          code: 'deadline-exceeded',
          message: 'အသုံးပြုခွင့် စစ်ဆေးချိန်ကြာနေပါသည်။');
    });
  }

  Future<AccessResult> _performOnline(
      CloudAccount account, int revision) async {
    final startWall = DateTime.now().toUtc();
    final startUptime = await device.uptime();
    final boot = await device.bootId();
    final reference = ref(account.uid);
    // Transaction is online-only. Rules bind start time to request.time and
    // disallow client changes to it forever; reopening cannot reset this UID's trial.
    await db.runTransaction((Transaction tx) async {
      final snapshot = await tx.get(reference);
      if (!snapshot.exists) {
        tx.set(reference, <String, dynamic>{
          'uid': account.uid,
          'email': account.email,
          'trial_started_at': FieldValue.serverTimestamp(),
          'expires_at': null,
          'status': 'active',
          'last_seen_at': FieldValue.serverTimestamp(),
          'updated_at': FieldValue.serverTimestamp(),
        });
      } else {
        tx.update(reference, <String, dynamic>{
          'email': account.email,
          'last_seen_at': FieldValue.serverTimestamp()
        });
      }
    });
    final snapshot =
        await reference.get(const GetOptions(source: Source.server));
    if (!snapshot.exists) throw const AccessDenied('အသုံးပြုခွင့် မတွေ့ပါ။');
    final access = CustomerAccess.fromMap(snapshot.data()!);
    final checkin = db.collection('customer_checkins').doc(account.uid);
    if (!access.activeAt(access.lastSeenAt)) {
      await device.clearLease();
      throw AccessDenied(access.status == 'blocked'
          ? 'Admin မှ အသုံးပြုခွင့် ယာယီပိတ်ထားပါသည်။'
          : 'အသုံးပြုခွင့် သက်တမ်းကုန်ပါပြီ။ Admin ကို ဆက်သွယ်ပါ။');
    }
    // Rules check the current access document again at commit time, including
    // an admin revocation racing with the previous read.
    await checkin.set(<String, dynamic>{
      'uid': account.uid,
      'verified_at': FieldValue.serverTimestamp()
    });
    final stamp = await checkin.get(const GetOptions(source: Source.server));
    final verifiedAt =
        (stamp.data()!['verified_at'] as Timestamp).toDate().toUtc();
    final latest = await reference.get(const GetOptions(source: Source.server));
    final latestAccess = CustomerAccess.fromMap(latest.data()!);
    if (!latestAccess.activeAt(verifiedAt)) {
      await device.clearLease();
      throw const AccessDenied('အသုံးပြုခွင့် ပြောင်းသွားပါသည်။ ပြန်စစ်ပါ။');
    }
    await _recordDevice(account);
    final wall = startWall;
    final lease = OfflineLease(
        uid: account.uid,
        serverAt: verifiedAt,
        expiresAt: latestAccess.expiresAt,
        wallAt: wall,
        uptimeAt: startUptime,
        bootId: boot,
        highWaterWall: wall);
    if (!lease.permits(
        currentUid: account.uid,
        wallNow: DateTime.now().toUtc(),
        uptimeNow: await device.uptime(),
        bootNow: await device.bootId())) {
      throw const AccessDenied('အသုံးပြုခွင့် သက်တမ်းကုန်ပါပြီ။ ပြန်စစ်ပါ။');
    }
    if (revision != _localRevision) {
      throw const AccessDenied('အသုံးပြုခွင့် ပြောင်းသွားပါသည်။');
    }
    await device.writeLease(jsonEncode(lease.toJson()));
    if (revision != _localRevision) {
      await device.clearLease();
      throw const AccessDenied('အသုံးပြုခွင့် ပြောင်းသွားပါသည်။');
    }
    return AccessResult(access: latestAccess, lease: lease);
  }

  Future<void> _recordDevice(CloudAccount account) async {
    final AccessDevice currentDevice = device;
    if (currentDevice is! DeviceMetadataProvider) return;
    try {
      final info = await (currentDevice as DeviceMetadataProvider).deviceInfo();
      final deviceId = info['device_id'];
      if (deviceId == null ||
          !RegExp(r'^[a-fA-F0-9-]{16,64}$').hasMatch(deviceId)) {
        return;
      }
      final doc = db
          .collection('customer_devices')
          .doc(account.uid)
          .collection('devices')
          .doc(deviceId);
      await db.runTransaction((Transaction tx) async {
        final existing = await tx.get(doc);
        final metadata = <String, dynamic>{
          'device_id': deviceId,
          'brand': (info['brand'] ?? '').trim(),
          'model': (info['model'] ?? '').trim(),
          'android_version': (info['android_version'] ?? '').trim(),
          'app_version': (info['app_version'] ?? '').trim(),
          'email': account.email,
          'last_seen_at': FieldValue.serverTimestamp(),
        };
        if (existing.exists) {
          tx.update(doc, metadata);
        } else {
          tx.set(doc, <String, dynamic>{
            ...metadata,
            'first_seen_at': FieldValue.serverTimestamp(),
          });
        }
      });
    } on FirebaseException {
      // Device reporting is informational and must not prevent authorized use.
    } on PlatformException {
      // A missing device-info implementation must not lock out the customer.
    } catch (_) {
      // Ignore metadata/storage failures; access remains governed by the licence.
    }
  }

  @override
  Future<OfflineLease?> checkOffline(String uid) async {
    final revision = _localRevision;
    try {
      final raw = await device.readLease();
      if (raw == null) return null;
      final lease = OfflineLease.fromJson(
          Map<String, dynamic>.from(jsonDecode(raw) as Map));
      final wall = DateTime.now().toUtc();
      if (!lease.permits(
          currentUid: uid,
          wallNow: wall,
          uptimeNow: await device.uptime(),
          bootNow: await device.bootId())) {
        return null;
      }
      final highWater =
          wall.isAfter(lease.highWaterWall) ? wall : lease.highWaterWall;
      final updated = OfflineLease(
          uid: lease.uid,
          serverAt: lease.serverAt,
          expiresAt: lease.expiresAt,
          wallAt: lease.wallAt,
          uptimeAt: lease.uptimeAt,
          highWaterWall: highWater,
          bootId: lease.bootId);
      if (revision != _localRevision) return null;
      await device.writeLease(jsonEncode(updated.toJson()));
      if (revision != _localRevision) {
        await device.clearLease();
        return null;
      }
      return updated;
    } catch (_) {
      return null;
    }
  }

  @override
  Stream<AccessEvent> changes(String uid) => ref(uid)
      .snapshots(includeMetadataChanges: true)
      .map((snapshot) => AccessEvent(
          access:
              snapshot.exists ? CustomerAccess.fromMap(snapshot.data()!) : null,
          fromCache: snapshot.metadata.isFromCache));

  @override
  Future<void> clearLocal() async {
    _localRevision++;
    await device.clearLease();
  }
}
