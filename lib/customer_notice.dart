import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CustomerNotice extends StatelessWidget {
  const CustomerNotice({super.key});
  @override
  Widget build(BuildContext context) =>
      StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('public_config')
            .doc('notice')
            .snapshots(),
        builder: (BuildContext context, snapshot) {
          final data = snapshot.data?.data();
          if (data == null || data['enabled'] != true) {
            return const SizedBox.shrink();
          }
          final String title = data['title'] as String? ?? '';
          final String body = data['body'] as String? ?? '';
          final String version = data['update_version'] as String? ?? '';
          final String url = data['update_url'] as String? ?? '';
          final Uri? uri = Uri.tryParse(url);
          return Card(
            color: Theme.of(context).colorScheme.secondaryContainer,
            child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    if (title.isNotEmpty)
                      Text(title,
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                    if (body.isNotEmpty) Text(body),
                    if (url.isNotEmpty &&
                        uri?.scheme == 'https' &&
                        (uri?.host.isNotEmpty ?? false))
                      OutlinedButton.icon(
                        onPressed: () async {
                          await Clipboard.setData(ClipboardData(text: url));
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                              content: Text(
                                  'Update link ကူးပြီးပါပြီ။ Browser မှာဖွင့်ပြီး Download လုပ်ပါ။')));
                        },
                        icon: const Icon(Icons.copy),
                        label: Text(
                            'Update ${version.isEmpty ? '' : '($version) '}link ကူးမည်'),
                      ),
                  ],
                )),
          );
        },
      );
}
