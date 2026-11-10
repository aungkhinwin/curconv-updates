import 'dart:convert';

/// Keeps the original three Firestore fields, so existing backups still work.
class BackupData {
  BackupData._(this.records);

  static const List<String> keys = <String>[
    'history_records',
    'archived_summaries',
    'merchant_transactions',
    'merchant_history_snapshots',
  ];

  final Map<String, List<String>> records;

  static String _stripImageData(String row) {
    try {
      final dynamic decoded = jsonDecode(row);
      if (decoded is Map<String, dynamic> && decoded.containsKey('imageData')) {
        decoded.remove('imageData');
        return jsonEncode(decoded);
      }
    } catch (_) {
      // Keep the original row if it cannot be decoded; validation reports it.
    }
    return row;
  }

  factory BackupData.fromMap(Map<String, dynamic> data) {
    final Map<String, List<String>> records = <String, List<String>>{};
    for (final String key in keys) {
      final dynamic value = data[key] ?? <String>[];
      if (value is! List || value.any((dynamic item) => item is! String)) {
        throw FormatException('$key: မှတ်တမ်းပုံစံ မမှန်ပါ။');
      }
      // Snapshot preview images (base64 PNG) are large and can be rebuilt,
      // so they are left out of the cloud backup to keep it under the size limit.
      final List<String> rows = key == 'merchant_history_snapshots'
          ? List<String>.from(value).map(_stripImageData).toList()
          : List<String>.from(value);
      for (final String row in rows) {
        final dynamic decoded = jsonDecode(row);
        if (decoded is! Map<String, dynamic>) {
          throw FormatException('$key: JSON မှတ်တမ်းပုံစံ မမှန်ပါ။');
        }
        _validateRecord(key, decoded);
      }
      records[key] = rows;
    }
    return BackupData._(records);
  }

  static void _validateRecord(String key, Map<String, dynamic> row) {
    if (key == 'merchant_transactions') {
      final dynamic type = row['type'];
      if (type == 'conversion') {
        _validateNumbers(row, <String>['yuan', 'kyat', 'rate']);
      } else if (type == 'remittance' || type == 'received') {
        _validateNumbers(row, <String>['amount']);
      } else {
        throw const FormatException('Merchant မှတ်တမ်းအမျိုးအစား မမှန်ပါ။');
      }
    } else if (key == 'merchant_history_snapshots') {
      final dynamic nested = row['records'];
      if (nested is! List) {
        throw const FormatException('Snapshot records ပုံစံ မမှန်ပါ။');
      }
      for (final dynamic item in nested) {
        if (item is! Map<String, dynamic>) {
          throw const FormatException('Snapshot အတွင်း JSON မှတ်တမ်း မမှန်ပါ။');
        }
        _validateRecord('merchant_transactions', item);
      }
      _validateNumbers(row,
          <String>['totalYuan', 'totalKyat', 'totalReceived', 'totalRemittance']);
    } else {
      _validateNumbers(
          row, <String>['yuan', 'customer', 'trader', 'profit', 'rate']);
      for (final String field in <String>['date', 'time', 'code']) {
        if (row[field] != null && row[field] is! String) {
          throw FormatException('$field: စာသားဖြစ်ရပါမည်။');
        }
      }
      if (key == 'archived_summaries' && row['records'] != null) {
        final dynamic nested = row['records'];
        if (nested is! List) {
          throw const FormatException('ရက်ချုပ် records ပုံစံ မမှန်ပါ။');
        }
        for (final dynamic item in nested) {
          if (item is! Map<String, dynamic>) {
            throw const FormatException(
                'ရက်ချုပ်အတွင်း JSON မှတ်တမ်း မမှန်ပါ။');
          }
          _validateRecord('history_records', item);
        }
      }
    }
  }

  static void _validateNumbers(Map<String, dynamic> row, List<String> fields) {
    for (final String field in fields) {
      final dynamic value = row[field];
      if (value != null && (value is! num || !value.isFinite)) {
        throw FormatException('$field: ကိန်းဂဏန်းဖြစ်ရပါမည်။');
      }
    }
  }

  /// Conservative guard below Firestore's 1 MiB document limit.
  /// Actual size is still enforced by Firestore, not this estimate.
  int get estimatedBytes => utf8.encode(jsonEncode(records)).length;

  int get recordCount => records.values
      .fold(0, (int count, List<String> rows) => count + rows.length);

  Map<String, dynamic> toMap() => <String, dynamic>{...records};
}
