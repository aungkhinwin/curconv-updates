import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'backup_data.dart';

abstract class CloudBackupRepository {
  Future<Map<String, dynamic>?> read(String uid);
  Future<void> save(String uid, BackupData backup);
}

class FirestoreCloudBackups implements CloudBackupRepository {
  FirestoreCloudBackups({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;
  final FirebaseFirestore _db;

  DocumentReference<Map<String, dynamic>> _document(String uid) =>
      _db.collection('users').doc(uid).collection('backups').doc('latest');

  @override
  Future<Map<String, dynamic>?> read(String uid) async {
    final DocumentSnapshot<Map<String, dynamic>> doc =
        await _document(uid).get(const GetOptions(source: Source.server));
    return doc.exists ? doc.data() : null;
  }

  @override
  Future<void> save(String uid, BackupData backup) =>
      _document(uid).set(<String, dynamic>{
        ...backup.toMap(),
        'owner_uid': uid,
        'schema_version': 2,
        'last_backup': DateTime.now().toUtc().toIso8601String(),
        'server_backup_time': FieldValue.serverTimestamp(),
      });
}

/// Checks identity before local writes. Legacy name-based backups are not trusted.
BackupData validateAccountBackup(Map<String, dynamic> data, String uid) {
  if (data['owner_uid'] != uid || data['schema_version'] != 2) {
    throw const FormatException(
        'အကောင့် သို့မဟုတ် Backup version မကိုက်ပါ။ Local data မပြောင်းထားပါ။');
  }
  return BackupData.fromMap(data);
}

Future<void> restoreLocalBackup(
    SharedPreferences prefs, BackupData backup) async {
  final Map<String, List<String>?> previous = <String, List<String>?>{
    for (final String key in BackupData.keys)
      key: prefs.getStringList(key) ?? <String>[],
  };
  try {
    for (final String key in BackupData.keys) {
      if (!await prefs.setStringList(key, backup.records[key]!)) {
        throw StateError('ဖုန်းထဲသို့ $key သိမ်းမရပါ။');
      }
    }
  } catch (_) {
    bool rollbackOk = true;
    for (final String key in BackupData.keys) {
      try {
        final List<String>? old = previous[key];
        final bool ok = old == null
            ? await prefs.remove(key)
            : await prefs.setStringList(key, old);
        if (!ok) rollbackOk = false;
      } catch (_) {
        rollbackOk = false;
      }
    }
    if (!rollbackOk) {
      throw StateError(
          'Restore မအောင်မြင်ဘဲ ဒေတာအဟောင်းအားလုံး ပြန်ထားမရပါ။ Cloud Backup ကို မအစားထိုးပါနှင့်။');
    }
    rethrow;
  }
}
