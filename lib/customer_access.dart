import 'package:cloud_firestore/cloud_firestore.dart';

class CustomerAccess {
  const CustomerAccess(
      {required this.uid,
      required this.email,
      required this.trialStartedAt,
      required this.expiresAt,
      required this.status,
      required this.lastSeenAt});
  final String uid;
  final String email;
  final DateTime trialStartedAt;
  final DateTime expiresAt;
  final String status;
  final DateTime lastSeenAt;

  factory CustomerAccess.fromMap(Map<String, dynamic> data) {
    DateTime date(String key) {
      final dynamic value = data[key];
      if (value is! Timestamp) {
        throw const FormatException('အသုံးပြုခွင့် ဒေတာမမှန်ပါ။');
      }
      return value.toDate().toUtc();
    }

    final DateTime trial = date('trial_started_at');
    return CustomerAccess(
        uid: data['uid'] as String,
        email: data['email'] as String,
        trialStartedAt: trial,
        expiresAt: data['expires_at'] == null
            ? trial.add(const Duration(days: 7))
            : date('expires_at'),
        status: data['status'] as String,
        lastSeenAt: date('last_seen_at'));
  }
  bool activeAt(DateTime serverTime) =>
      status == 'active' && serverTime.isBefore(expiresAt);
}

class OfflineLease {
  const OfflineLease(
      {required this.uid,
      required this.serverAt,
      required this.expiresAt,
      required this.wallAt,
      required this.uptimeAt,
      required this.highWaterWall,
      required this.bootId});
  final String uid;
  final String bootId;
  final DateTime serverAt;
  final DateTime expiresAt;
  final DateTime wallAt;
  final int uptimeAt;
  final DateTime highWaterWall;

  DateTime? estimatedServerNow(
      {required String currentUid,
      required DateTime wallNow,
      required int uptimeNow,
      required String bootNow}) {
    if (bootNow != bootId ||
        currentUid != uid ||
        uptimeNow < uptimeAt ||
        wallNow.isBefore(highWaterWall.subtract(const Duration(minutes: 2)))) {
      return null;
    }
    final Duration elapsed = Duration(milliseconds: uptimeNow - uptimeAt);
    // A reboot or incompatible wall/boot clock needs a new online check.
    final Duration wallElapsed = wallNow.difference(wallAt);
    if ((wallElapsed.inMilliseconds - elapsed.inMilliseconds).abs() >
        const Duration(minutes: 2).inMilliseconds) {
      return null;
    }
    return serverAt.add(elapsed);
  }

  bool permits(
      {required String currentUid,
      required DateTime wallNow,
      required int uptimeNow,
      required String bootNow}) {
    final DateTime? now = estimatedServerNow(
        currentUid: currentUid,
        wallNow: wallNow,
        uptimeNow: uptimeNow,
        bootNow: bootNow);
    return now != null &&
        now.isBefore(expiresAt) &&
        now.isBefore(serverAt.add(const Duration(hours: 24)));
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'uid': uid,
        'boot': bootId,
        'server': serverAt.millisecondsSinceEpoch,
        'expires': expiresAt.millisecondsSinceEpoch,
        'wall': wallAt.millisecondsSinceEpoch,
        'uptime': uptimeAt,
        'high': highWaterWall.millisecondsSinceEpoch
      };
  factory OfflineLease.fromJson(Map<String, dynamic> json) => OfflineLease(
      uid: json['uid'] as String,
      bootId: json['boot'] as String,
      serverAt: DateTime.fromMillisecondsSinceEpoch(json['server'] as int,
          isUtc: true),
      expiresAt: DateTime.fromMillisecondsSinceEpoch(json['expires'] as int,
          isUtc: true),
      wallAt:
          DateTime.fromMillisecondsSinceEpoch(json['wall'] as int, isUtc: true),
      uptimeAt: json['uptime'] as int,
      highWaterWall: DateTime.fromMillisecondsSinceEpoch(json['high'] as int,
          isUtc: true));
}
