import 'dart:io';

import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

const MethodChannel _updateInstallChannel = MethodChannel('curconv/update');

typedef ApkDownloadProgress = void Function(int receivedBytes, int? totalBytes);

/// Downloads the APK inside the app, reports progress, then opens the installer.
/// Returns null on success, or a message describing the error.
Future<String?> downloadAndInstallApk(
  String apkUrl, {
  ApkDownloadProgress? onProgress,
}) async {
  final http.Client client = http.Client();
  try {
    final http.StreamedResponse response =
        await client.send(http.Request('GET', Uri.parse(apkUrl)));
    if (response.statusCode != 200) {
      return 'APK ဒေါင်းလို့မရပါ (status ${response.statusCode})';
    }

    final int? totalBytes = response.contentLength;
    final Directory dir = await getTemporaryDirectory();
    final File file = File('${dir.path}/curconv_update.apk');
    if (await file.exists()) await file.delete();

    final IOSink sink = file.openWrite();
    int receivedBytes = 0;
    try {
      await for (final List<int> chunk in response.stream) {
        sink.add(chunk);
        receivedBytes += chunk.length;
        onProgress?.call(receivedBytes, totalBytes);
      }
      await sink.flush();
    } finally {
      await sink.close();
    }

    if (totalBytes != null && receivedBytes != totalBytes) {
      return 'APK ဒေါင်းလုဒ် မပြည့်စုံပါ။ ထပ်မံကြိုးစားပါ။';
    }
    onProgress?.call(receivedBytes, totalBytes ?? receivedBytes);

    await _updateInstallChannel.invokeMethod<void>(
      'installApk',
      <String, dynamic>{'path': file.path},
    );
    return null;
  } catch (e) {
    return 'Update ဒေါင်းရာတွင် အမှား: $e';
  } finally {
    client.close();
  }
}
