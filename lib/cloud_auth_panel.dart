import 'package:flutter/material.dart';

import 'curconv_3d.dart';

import 'cloud_auth_service.dart';

class CloudAuthPanel extends StatefulWidget {
  const CloudAuthPanel(
      {super.key,
      required this.auth,
      required this.account,
      required this.onBusy,
      required this.onMessage,
      this.disabled = false});
  final CloudAuthService auth;
  final CloudAccount? account;
  final ValueChanged<bool> onBusy;
  final ValueChanged<String> onMessage;
  final bool disabled;

  @override
  State<CloudAuthPanel> createState() => _CloudAuthPanelState();
}

class _CloudAuthPanelState extends State<CloudAuthPanel> {
  final GlobalKey<FormState> _form = GlobalKey<FormState>();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _confirmPassword = TextEditingController();
  bool _register = false;
  bool _busy = false;
  bool _hidePassword = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant CloudAuthPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.account?.uid != widget.account?.uid) {
      _password.clear();
      _confirmPassword.clear();
    }
  }

  bool get _locked => _busy || widget.disabled;

  Future<void> _run(Future<void> Function() action, {String? success}) async {
    if (_locked) return;
    FocusScope.of(context).unfocus();
    setState(() => _busy = true);
    widget.onBusy(true);
    try {
      await action();
      if (mounted && success != null) widget.onMessage(success);
    } catch (error) {
      if (mounted) widget.onMessage(cloudAuthError(error));
    } finally {
      if (mounted) {
        setState(() => _busy = false);
        widget.onBusy(false);
      }
    }
  }

  Future<void> _emailLogin() async {
    if (_form.currentState?.validate() != true) return;
    final String email = _email.text.trim();
    final String password = _password.text;
    final bool registering = _register;
    await _run(() => registering
        ? widget.auth.register(email, password)
        : widget.auth.signInEmail(email, password));
  }

  Future<void> _reset() async {
    final String email = _email.text.trim();
    if (!email.contains('@') || email.endsWith('@')) {
      widget.onMessage('Password reset အတွက် Email ကို အရင်ထည့်ပါ။');
      return;
    }
    await _run(() => widget.auth.sendReset(email),
        success:
            'ဒီ Email အတွက် reset လုပ်နိုင်ပါက Password reset စာ ပို့ပါမည်။ Inbox နဲ့ Spam ကို စစ်ပါ။');
  }

  Future<void> _addPassword() async {
    final ({String password, String confirmation})? result =
        await showDialog<({String password, String confirmation})>(
      context: context,
      builder: (_) => _PasswordDialog(email: widget.account?.email ?? ''),
    );
    if (!mounted || result == null) return;
    await _run(() => widget.auth.addPassword(result.password),
        success: 'ဒီအကောင့်ကို Email/Password နဲ့လည်း ဝင်နိုင်ပါပြီ။');
  }

  Future<void> _logout() async {
    final bool confirmed = await showDialog<bool>(
          context: context,
          builder: (BuildContext ctx) => AlertDialog(
            title: const Text('Logout လုပ်ရန်'),
            content: const Text(
                'Cloud အကောင့်မှ ထွက်ပါမည်။ ဖုန်းထဲရှိ စာရင်းတွေ မဖျက်ပါ။ ဒီဖုန်းပေါ်တွင် အခြားအကောင့်ဝင်လျှင်လည်း local စာရင်းတွေ ဆက်ရှိနေမည်။'),
            actions: <Widget>[
              TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('မထွက်တော့ပါ')),
              FilledButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Logout')),
            ],
          ),
        ) ??
        false;
    if (!mounted || !confirmed) return;
    await _run(widget.auth.signOut);
  }

  @override
  Widget build(BuildContext context) {
    final CloudAccount? account = widget.account;
    if (account == null) return _loginForm();
    return Curconv3DPanel(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const Icon(Icons.account_circle_outlined,
                size: 42, color: Color(0xFF00796B)),
            const SizedBox(height: 8),
            Text(account.email,
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
            const SizedBox(height: 6),
            Text(
                account.verified
                    ? 'Email အတည်ပြုပြီးပါပြီ'
                    : 'Cloud Backup သုံးရန် Email ကို အတည်ပြုပါ။ Inbox/Spam ထဲက link ကို နှိပ်ပြီး ပြန်စစ်ပါ။',
                textAlign: TextAlign.center),
            if (!account.verified) ...<Widget>[
              const SizedBox(height: 10),
              OutlinedButton(
                  onPressed: _locked
                      ? null
                      : () => _run(widget.auth.sendVerification,
                          success: 'Email အတည်ပြုစာ ပို့ပြီးပါပြီ။'),
                  child: const Text('အတည်ပြု Email ပြန်ပို့မည်')),
              FilledButton(
                  onPressed: _locked
                      ? null
                      : () => _run(widget.auth.refresh,
                          success: widget.account?.verified == true
                              ? 'Email အတည်ပြုပြီးပါပြီ။'
                              : 'အတည်ပြုအခြေအနေ ပြန်စစ်ပြီးပါပြီ။'),
                  child: const Text('အတည်ပြုပြီး / ပြန်စစ်မည်')),
            ],
            if (account.verified && !account.providers.contains('google.com'))
              OutlinedButton.icon(
                onPressed: _locked ? null : () => _run(widget.auth.linkGoogle),
                icon: const Icon(Icons.link),
                label: const Text('Google Login ကို ဒီအကောင့်နဲ့ ချိတ်မည်'),
              ),
            if (account.verified && !account.providers.contains('password'))
              OutlinedButton.icon(
                onPressed: _locked ? null : _addPassword,
                icon: const Icon(Icons.password),
                label: const Text('Email Login အတွက် Password ထည့်မည်'),
              ),
            TextButton(
                onPressed: _locked ? null : _logout,
                child: const Text('Logout')),
          ],
        ),
      ),
    );
  }

  Widget _loginForm() {
    return Curconv3DPanel(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                  _register
                      ? 'အကောင့်အသစ်ဖွင့်မည်'
                      : 'Cloud အကောင့်သို့ Login ဝင်မည်',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextFormField(
                key: const ValueKey<String>('cloud-email'),
                controller: _email,
                enabled: !_locked,
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                textCapitalization: TextCapitalization.none,
                autofillHints: const <String>[AutofillHints.email],
                decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email_outlined),
                    border: OutlineInputBorder()),
                validator: (String? v) => v == null ||
                        !v.trim().contains('@') ||
                        v.trim().endsWith('@')
                    ? 'Email ကို မှန်ကန်စွာ ထည့်ပါ။'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const ValueKey<String>('cloud-password'),
                controller: _password,
                enabled: !_locked,
                obscureText: _hidePassword,
                autocorrect: false,
                enableSuggestions: false,
                autofillHints: const <String>[AutofillHints.password],
                decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      onPressed: _locked
                          ? null
                          : () =>
                              setState(() => _hidePassword = !_hidePassword),
                      icon: Icon(_hidePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined),
                    )),
                validator: (String? v) => v == null || v.isEmpty
                    ? 'Password ထည့်ပါ။'
                    : _register && v.length < 6
                        ? 'အနည်းဆုံး ၆ လုံး ထည့်ပါ။'
                        : null,
              ),
              if (_register) ...<Widget>[
                const SizedBox(height: 12),
                TextFormField(
                  key: const ValueKey<String>('cloud-confirm-password'),
                  controller: _confirmPassword,
                  enabled: !_locked,
                  obscureText: true,
                  autocorrect: false,
                  enableSuggestions: false,
                  decoration: const InputDecoration(
                      labelText: 'Password ထပ်ထည့်ပါ',
                      border: OutlineInputBorder()),
                  validator: (String? v) =>
                      v != _password.text ? 'Password နှစ်ခု မတူပါ။' : null,
                ),
              ],
              const SizedBox(height: 16),
              FilledButton(
                  onPressed: _locked ? null : _emailLogin,
                  child: Text(_register ? 'အကောင့်ဖွင့်မည်' : 'Login')),
              if (!_register)
                TextButton(
                    onPressed: _locked ? null : _reset,
                    child: const Text('Password မေ့နေပါသလား?')),
              TextButton(
                  onPressed: _locked
                      ? null
                      : () => setState(() {
                            _register = !_register;
                            _password.clear();
                            _confirmPassword.clear();
                          }),
                  child: Text(_register
                      ? 'အကောင့်ရှိပြီးသား / Login'
                      : 'အကောင့်အသစ်ဖွင့်ရန်')),
              const Divider(),
              OutlinedButton.icon(
                  onPressed:
                      _locked ? null : () => _run(widget.auth.signInGoogle),
                  icon: const Icon(Icons.account_circle_outlined),
                  label: const Text('Google နဲ့ ဝင်မည်')),
            ],
          ),
        ),
      ),
    );
  }
}

class _PasswordDialog extends StatefulWidget {
  const _PasswordDialog({required this.email});
  final String email;
  @override
  State<_PasswordDialog> createState() => _PasswordDialogState();
}

class _PasswordDialogState extends State<_PasswordDialog> {
  final GlobalKey<FormState> _form = GlobalKey<FormState>();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _confirm = TextEditingController();
  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Email Login ချိတ်ရန်'),
        content: Form(
            key: _form,
            child: SingleChildScrollView(
                child:
                    Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
              Text(widget.email),
              const SizedBox(height: 12),
              TextFormField(
                  controller: _password,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Password အသစ်'),
                  validator: (String? v) => v == null || v.length < 6
                      ? 'အနည်းဆုံး ၆ လုံး ထည့်ပါ။'
                      : null),
              TextFormField(
                  controller: _confirm,
                  obscureText: true,
                  decoration:
                      const InputDecoration(labelText: 'Password ထပ်ထည့်ပါ'),
                  validator: (String? v) =>
                      v != _password.text ? 'Password နှစ်ခု မတူပါ။' : null),
            ]))),
        actions: <Widget>[
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('မလုပ်တော့ပါ')),
          FilledButton(
              onPressed: () {
                if (_form.currentState?.validate() == true) {
                  Navigator.pop(context,
                      (password: _password.text, confirmation: _confirm.text));
                }
              },
              child: const Text('ချိတ်မည်')),
        ],
      );
}
