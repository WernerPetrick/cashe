import 'package:flutter/material.dart';

import '../../../core/widgets/cashe_widgets.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CasheLogo(size: 88),
            SizedBox(height: 28),
            CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
