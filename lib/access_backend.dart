import 'cloud_auth_service.dart';
import 'customer_access.dart';

class AccessResult {
  const AccessResult({required this.access, required this.lease});
  final CustomerAccess access;
  final OfflineLease lease;
}

class AccessEvent {
  const AccessEvent({required this.access, required this.fromCache});
  final CustomerAccess? access;
  final bool fromCache;
}

class AccessDenied implements Exception {
  const AccessDenied(this.message);
  final String message;
  @override
  String toString() => message;
}

abstract class AccessBackend {
  Future<AccessResult> checkOnline(CloudAccount account);
  Future<OfflineLease?> checkOffline(String uid);
  Stream<AccessEvent> changes(String uid);
  Future<void> clearLocal();
}
