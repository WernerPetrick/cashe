import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/cashe_widgets.dart';
import 'auth_controller.dart';

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    final failure = await ref
        .read(authControllerProvider.notifier)
        .signIn(email: _email.text.trim(), password: _password.text);
    if (!mounted) return;
    setState(() {
      _submitting = false;
      _error = failure?.message;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: _SignInFields(
                email: _email,
                password: _password,
                submitting: _submitting,
                error: _error,
                onSubmit: _submit,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SignInFields extends StatelessWidget {
  const _SignInFields({
    required this.email,
    required this.password,
    required this.submitting,
    required this.error,
    required this.onSubmit,
  });

  final TextEditingController email;
  final TextEditingController password;
  final bool submitting;
  final String? error;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Align(
          alignment: Alignment.centerLeft,
          child: CasheLogo(size: 56),
        ),
        const SizedBox(height: 20),
        Text('Cashe', style: theme.textTheme.displaySmall),
        const SizedBox(height: 32),
        TextFormField(
          controller: email,
          decoration: const InputDecoration(labelText: 'Email'),
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.email],
          validator: (v) => (v ?? '').contains('@') ? null : 'Enter your email',
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: password,
          decoration: const InputDecoration(labelText: 'Password'),
          obscureText: true,
          autofillHints: const [AutofillHints.password],
          validator: (v) => (v ?? '').isEmpty ? 'Enter your password' : null,
          onFieldSubmitted: (_) => onSubmit(),
        ),
        if (error != null) ...[
          const SizedBox(height: 16),
          Text(error!, style: TextStyle(color: theme.colorScheme.error)),
        ],
        const SizedBox(height: 24),
        FilledButton(
          onPressed: submitting ? null : onSubmit,
          child: Text(submitting ? 'Signing in…' : 'Sign in'),
        ),
      ],
    );
  }
}
