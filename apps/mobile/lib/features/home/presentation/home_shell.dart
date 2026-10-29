import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import 'activity_tab.dart';
import 'home_tab.dart';
import 'me_tab.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

enum _Tab { home, activity, me }

class _HomeShellState extends State<HomeShell> {
  _Tab _tab = _Tab.home;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: IndexedStack(
          index: _tab.index,
          children: const [HomeTab(), ActivityTab(), MeTab()],
        ),
      ),
      bottomNavigationBar: _NavBar(
        tab: _tab,
        onTab: (tab) => setState(() => _tab = tab),
      ),
    );
  }
}

class _NavBar extends StatelessWidget {
  const _NavBar({required this.tab, required this.onTab});

  final _Tab tab;
  final ValueChanged<_Tab> onTab;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: CasheColors.background,
        border: Border(top: BorderSide(color: CasheColors.divider)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              _NavItem(
                label: 'Home',
                active: tab == _Tab.home,
                onTap: () => onTab(_Tab.home),
              ),
              _NavItem(
                label: 'Activity',
                active: tab == _Tab.activity,
                onTap: () => onTab(_Tab.activity),
              ),
              _NavItem(
                label: 'Me',
                active: tab == _Tab.me,
                onTap: () => onTab(_Tab.me),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colour = active ? CasheColors.amber : CasheColors.muted;
    return Expanded(
      child: InkResponse(
        onTap: onTap,
        child: Semantics(
          selected: active,
          button: true,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: active ? CasheColors.amber : null,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: colour,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
