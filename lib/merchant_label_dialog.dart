import 'package:flutter/material.dart';

/// Edits a display label only. Does not change transactions or amounts.
class MerchantLabelDialog extends StatefulWidget {
  const MerchantLabelDialog({
    super.key,
    required this.currentLabel,
    required this.defaultLabel,
  });

  final String currentLabel;
  final String defaultLabel;

  @override
  State<MerchantLabelDialog> createState() => _MerchantLabelDialogState();
}

class _MerchantLabelDialogState extends State<MerchantLabelDialog> {
  final GlobalKey<FormState> _form = GlobalKey<FormState>();
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.currentLabel);
    _controller.selection = TextSelection(
      baseOffset: 0,
      extentOffset: _controller.text.length,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    if (_form.currentState?.validate() != true) return;
    Navigator.of(context).pop(_controller.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Merchant စာတန်းပြင်ရန်'),
      content: SingleChildScrollView(
        child: Form(
          key: _form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const Text(
                  'စာတန်းအမည်ကိုသာ ပြင်ပါမည်။ ငွေပမာဏနှင့် မှတ်တမ်းများ မပြောင်းပါ။'),
              const SizedBox(height: 12),
              TextFormField(
                key: const ValueKey<String>('merchant-label-input'),
                controller: _controller,
                autofocus: true,
                maxLength: 60,
                maxLines: 1,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _save(),
                decoration: const InputDecoration(
                  labelText: 'စာတန်းအမည်',
                  border: OutlineInputBorder(),
                ),
                validator: (String? value) =>
                    value == null || value.trim().isEmpty
                        ? 'စာတန်းအမည် ထည့်ပါ။'
                        : null,
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  key: const ValueKey<String>('merchant-label-default'),
                  onPressed: () {
                    _controller.text = widget.defaultLabel;
                    _controller.selection = TextSelection.collapsed(
                      offset: _controller.text.length,
                    );
                  },
                  child: const Text('မူလအမည် ပြန်ထားမည်'),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          key: const ValueKey<String>('merchant-label-cancel'),
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('မပြင်တော့ပါ'),
        ),
        FilledButton(
          key: const ValueKey<String>('merchant-label-save'),
          onPressed: _save,
          child: const Text('သိမ်းမည်'),
        ),
      ],
    );
  }
}
