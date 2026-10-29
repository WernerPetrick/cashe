import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/failure.dart';
import '../../../core/widgets/cashe_widgets.dart';
import 'auth_controller.dart';
import 'widgets/sign_in_steps.dart';

enum SignInStep { email, signIn, signUp }

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _name = TextEditingController();
  var _step = SignInStep.email;
  var _submitting = false;
  var _checking = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _name.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    if (_checking) return;
    if (!validEmail(_email.text)) {
      setState(() => _error = 'Enter a valid email address.');
      return;
    }
    setState(() => _checking = true);
    final exists = await ref
        .read(authControllerProvider.notifier)
        .accountExists(_email.text.trim());
    if (!mounted) return;
    _checking = false;
    _goTo(exists == false ? SignInStep.signUp : SignInStep.signIn);
  }

  void _goTo(SignInStep step, {String? error}) => setState(() {
    _step = step;
    _error = error;
    _password.clear();
  });

  Future<void> _submit() async {
    final problem = _step == SignInStep.signUp
        ? signUpProblem(_name.text, _password.text)
        : (_password.text.isEmpty ? 'Enter your password.' : null);
    setState(() => _error = problem);
    if (problem != null) return;

    setState(() => _submitting = true);
    final failure = await _attempt();
    if (!mounted) return;
    setState(() => _submitting = false);
    if (failure?.code == Failure.accountExists) {
      _goTo(SignInStep.signIn, error: 'You already have a wallet. Sign in.');
    } else {
      setState(() => _error = failure?.message);
    }
  }

  Future<Failure?> _attempt() {
    final auth = ref.read(authControllerProvider.notifier);
    final email = _email.text.trim();
    return _step == SignInStep.signUp
        ? auth.signUp(
            name: _name.text.trim(),
            email: email,
            password: _password.text,
          )
        : auth.signIn(email: email, password: _password.text);
  }

  @override
  Widget build(BuildContext context) {
    final atEmail = _step == SignInStep.email;
    return PopScope(
      canPop: atEmail,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _goTo(SignInStep.email);
      },
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Header(onBack: atEmail ? null : () => _goTo(SignInStep.email)),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 350),
                    child: atEmail ? _emailStep() : _passwordStep(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _emailStep() => EmailStep(
    key: const ValueKey(SignInStep.email),
    email: _email,
    error: _error,
    checking: _checking,
    onChanged: () => setState(() => _error = null),
    onContinue: _continue,
  );

  Widget _passwordStep() => PasswordStep(
    key: const ValueKey('password-step'),
    signingUp: _step == SignInStep.signUp,
    email: _email.text.trim(),
    password: _password,
    name: _name,
    error: _error,
    submitting: _submitting,
    onChanged: () => setState(() => _error = null),
    onSubmit: _submit,
    onChangeEmail: () => _goTo(SignInStep.email),
    onSwitchMode: () => _goTo(
      _step == SignInStep.signUp ? SignInStep.signIn : SignInStep.signUp,
    ),
  );
}

class _Header extends StatelessWidget {
  const _Header({required this.onBack});

  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 40,
    child: Row(
      children: [
        const SizedBox(width: 10),
        const Spacer(),
        if (onBack case final back?) PillButton(label: 'Back', onPressed: back),
      ],
    ),
  );
}

bool validEmail(String email) =>
    RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$').hasMatch(email.trim());

String? signUpProblem(String name, String password) {
  if (name.trim().isEmpty) return 'Enter your name.';
  if (!passwordLongEnough(password) || !passwordHasNumber(password)) {
    return 'Your password needs 8+ characters and a number.';
  }
  return null;
}

bool passwordLongEnough(String password) => password.length >= 8;

bool passwordHasNumber(String password) => RegExp(r'\d').hasMatch(password);
