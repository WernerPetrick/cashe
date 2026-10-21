import 'package:flutter/material.dart';

import '../../../../app/theme.dart';
import '../../../../core/widgets/cashe_widgets.dart';
import '../sign_in_screen.dart';

const _headline = TextStyle(
  fontSize: 30,
  height: 1.12,
  fontWeight: FontWeight.w800,
  letterSpacing: -0.9,
  color: CasheColors.text,
);

const _footnote = TextStyle(
  fontSize: 12.5,
  height: 1.5,
  color: CasheColors.faint,
);

/// Step one: the concept art, the pitch and the email field.
class EmailStep extends StatelessWidget {
  const EmailStep({
    super.key,
    required this.email,
    required this.error,
    required this.onChanged,
    required this.onContinue,
  });

  final TextEditingController email;
  final String? error;
  final VoidCallback onChanged;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) => FillOrScroll(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 34, bottom: 8),
          child: PlaceConcept(),
        ),
        const Spacer(),
        const Text('Money that waits for the right place.', style: _headline),
        const SizedBox(height: 10),
        Text(
          'Cashe holds your funds until you arrive where you chose to spend them.',
          style: Theme.of(context).textTheme.bodyLarge
              ?.copyWith(height: 1.5, color: CasheColors.textBody),
        ),
        const SizedBox(height: 28),
        LabelledField(
          label: 'Email',
          error: error,
          field: TextField(
            key: const Key('email'),
            controller: email,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(hintText: 'you@example.com'),
            onChanged: (_) => onChanged(),
            onSubmitted: (_) => onContinue(),
          ),
        ),
        const SizedBox(height: 16),
        FilledButton(onPressed: onContinue, child: const Text('Continue')),
        const SizedBox(height: 14),
        const Text(
          'Next you’ll sign in, or set up a new wallet if you’re new.',
          textAlign: TextAlign.center,
          style: _footnote,
        ),
      ],
    ),
  );
}

/// A place ring three-quarters full with a pulsing pin: "unlocks when you arrive".
class PlaceConcept extends StatelessWidget {
  const PlaceConcept({super.key});

  @override
  Widget build(BuildContext context) => Column(
    children: [
      RingDial(
        size: 196,
        progress: 0.75,
        thickness: 14,
        dotted: true,
        child: PulseRings(
          size: 58,
          child: Container(
            width: 58,
            height: 58,
            alignment: const Alignment(-0.35, -0.38),
            decoration: const BoxDecoration(
              color: CasheColors.amber,
              shape: BoxShape.circle,
            ),
            child: const CircleAvatar(
              radius: 7.5,
              backgroundColor: Color(0xFFF9D894),
            ),
          ),
        ),
      ),
      const SizedBox(height: 18),
      const _PlaceChip('Unlocks at · Riverside Market'),
    ],
  );
}

class _PlaceChip extends StatelessWidget {
  const _PlaceChip(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(10, 7, 12, 7),
    decoration: BoxDecoration(
      color: CasheColors.surface,
      border: Border.all(color: CasheColors.border),
      borderRadius: BorderRadius.circular(999),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const CircleAvatar(radius: 3.5, backgroundColor: CasheColors.amber),
        const SizedBox(width: 8),
        Flexible(child: MonoLabel(text, color: CasheColors.textSoft)),
      ],
    ),
  );
}

/// Step two: sign in, or create an account, for the email from step one.
class PasswordStep extends StatelessWidget {
  const PasswordStep({
    super.key,
    required this.signingUp,
    required this.email,
    required this.password,
    required this.name,
    required this.error,
    required this.submitting,
    required this.onChanged,
    required this.onSubmit,
    required this.onChangeEmail,
    required this.onSwitchMode,
  });

  final bool signingUp;
  final String email;
  final TextEditingController password;
  final TextEditingController name;
  final String? error;
  final bool submitting;
  final VoidCallback onChanged;
  final VoidCallback onSubmit;
  final VoidCallback onChangeEmail;
  final VoidCallback onSwitchMode;

  @override
  Widget build(BuildContext context) => FillOrScroll(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 40),
        MonoLabel(
          signingUp ? 'New to Cashe' : 'Welcome back',
          color: CasheColors.amber,
        ),
        const SizedBox(height: 10),
        Text(
          signingUp ? 'Create your wallet' : 'Enter your password',
          style: _headline,
        ),
        const SizedBox(height: 18),
        EmailCard(email: email, onChange: onChangeEmail),
        if (signingUp) ...[const SizedBox(height: 24), _nameField()],
        const SizedBox(height: 24),
        _passwordField(),
        if (signingUp) ...[
          const SizedBox(height: 14),
          PasswordRules(password: password.text),
        ],
        const Spacer(),
        const SizedBox(height: 24),
        _SubmitButton(label: _cta, submitting: submitting, onPressed: onSubmit),
        const SizedBox(height: 6),
        TextButton(
          onPressed: submitting ? null : onSwitchMode,
          child: Text(
            signingUp
                ? 'Already have a wallet? Sign in'
                : 'New to Cashe? Create your wallet',
          ),
        ),
      ],
    ),
  );

  String get _cta => switch ((signingUp, submitting)) {
    (true, true) => 'Creating account…',
    (true, false) => 'Create account',
    (false, true) => 'Signing in…',
    (false, false) => 'Sign in',
  };

  Widget _nameField() => LabelledField(
    label: 'Your name',
    field: TextField(
      key: const Key('name'),
      controller: name,
      textCapitalization: TextCapitalization.words,
      autofillHints: const [AutofillHints.name],
      textInputAction: TextInputAction.next,
      decoration: const InputDecoration(
        hintText: 'Shown to people who send you gifts',
      ),
      onChanged: (_) => onChanged(),
    ),
  );

  Widget _passwordField() => LabelledField(
    label: signingUp ? 'Create a password' : 'Password',
    error: error,
    field: PasswordField(
      controller: password,
      newPassword: signingUp,
      onChanged: onChanged,
      onSubmitted: onSubmit,
    ),
  );
}

/// The email being used, with a way back to change it.
class EmailCard extends StatelessWidget {
  const EmailCard({super.key, required this.email, required this.onChange});

  final String email;
  final VoidCallback onChange;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(14, 6, 4, 6),
    decoration: BoxDecoration(
      color: CasheColors.surface,
      border: Border.all(color: CasheColors.border),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(
      children: [
        CircleAvatar(
          radius: 15,
          backgroundColor: CasheColors.track,
          child: Text(
            email.isEmpty ? '?' : email[0].toUpperCase(),
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: CasheColors.amber,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            email,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600),
          ),
        ),
        TextButton(
          onPressed: onChange,
          style: TextButton.styleFrom(foregroundColor: CasheColors.amber),
          child: const Text('Change'),
        ),
      ],
    ),
  );
}

/// A password input with a Show/Hide toggle.
class PasswordField extends StatefulWidget {
  const PasswordField({
    super.key,
    required this.controller,
    required this.newPassword,
    required this.onChanged,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final bool newPassword;
  final VoidCallback onChanged;
  final VoidCallback onSubmitted;

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  var _hidden = true;

  @override
  Widget build(BuildContext context) => TextField(
    key: const Key('password'),
    controller: widget.controller,
    obscureText: _hidden,
    autofillHints: [
      widget.newPassword ? AutofillHints.newPassword : AutofillHints.password,
    ],
    textInputAction: TextInputAction.done,
    decoration: InputDecoration(
      hintText: widget.newPassword ? 'At least 8 characters' : 'Your password',
      suffixIcon: Padding(
        padding: const EdgeInsets.only(right: 6),
        child: TextButton(
          onPressed: () => setState(() => _hidden = !_hidden),
          child: Text(_hidden ? 'Show' : 'Hide'),
        ),
      ),
    ),
    onChanged: (_) => widget.onChanged(),
    onSubmitted: (_) => widget.onSubmitted(),
  );
}

/// The new-password rules, each turning amber once met.
class PasswordRules extends StatelessWidget {
  const PasswordRules({super.key, required this.password});

  final String password;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _Rule('At least 8 characters', met: passwordLongEnough(password)),
      const SizedBox(height: 8),
      _Rule('Includes a number', met: passwordHasNumber(password)),
    ],
  );
}

class _Rule extends StatelessWidget {
  const _Rule(this.label, {required this.met});

  final String label;
  final bool met;

  @override
  Widget build(BuildContext context) {
    final colour = met ? CasheColors.amber : CasheColors.muted;
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: met ? colour : Colors.transparent,
            border: Border.all(color: colour, width: 1.5),
          ),
        ),
        const SizedBox(width: 10),
        Text(label, style: TextStyle(fontSize: 13.5, color: colour)),
      ],
    );
  }
}

/// A field with the design's small label above it and an error line below.
class LabelledField extends StatelessWidget {
  const LabelledField({
    super.key,
    required this.label,
    required this.field,
    this.error,
  });

  final String label;
  final Widget field;
  final String? error;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: CasheColors.textSoft,
        ),
      ),
      const SizedBox(height: 8),
      field,
      if (error case final message?) ...[
        const SizedBox(height: 8),
        Text(
          message,
          style: const TextStyle(fontSize: 13, color: CasheColors.warning),
        ),
      ],
    ],
  );
}

class _SubmitButton extends StatelessWidget {
  const _SubmitButton({
    required this.label,
    required this.submitting,
    required this.onPressed,
  });

  final String label;
  final bool submitting;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => FilledButton(
    onPressed: submitting ? null : onPressed,
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (submitting) ...[
          const SizedBox.square(
            dimension: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: CasheColors.background,
            ),
          ),
          const SizedBox(width: 10),
        ],
        Text(label),
      ],
    ),
  );
}
