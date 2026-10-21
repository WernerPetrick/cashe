import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/presentation/auth_controller.dart';
import '../features/auth/presentation/sign_in_screen.dart';
import '../features/auth/presentation/splash_screen.dart';
import '../features/claims/presentation/claim_screen.dart';
import '../features/home/presentation/home_shell.dart';
import '../features/claims/presentation/paste_claim_screen.dart';
import '../features/places/presentation/place_picker_screen.dart';
import '../features/unlock/presentation/unlock_screen.dart';
import '../features/wallets/domain/wallet.dart';
import '../features/wallets/presentation/add_money_screen.dart';
import '../features/wallets/presentation/create_wallet_screen.dart';
import '../features/wallets/presentation/gift_link_screen.dart';
import '../features/wallets/presentation/history_screen.dart';
import '../features/wallets/presentation/wallet_detail_screen.dart';

abstract final class Routes {
  static const splash = '/splash';
  static const signIn = '/sign-in';
  static const home = '/';
}

final routerProvider = Provider<GoRouter>((ref) {
  final authChanges = ValueNotifier(0);
  ref.listen(authControllerProvider, (_, _) => authChanges.value++);
  ref.onDispose(authChanges.dispose);

  return GoRouter(
    initialLocation: Routes.splash,
    refreshListenable: authChanges,
    redirect: (context, state) =>
        authRedirect(ref.read(authControllerProvider), state.uri),
    routes: [
      GoRoute(path: Routes.splash, builder: (_, _) => const SplashScreen()),
      GoRoute(path: Routes.signIn, builder: (_, _) => const SignInScreen()),
      // Everything else sits under home, so going straight to any screen (a claim
      // link, "Done" after sharing a gift) still leaves home underneath to go back to.
      GoRoute(
        path: Routes.home,
        builder: (_, _) => const HomeShell(),
        routes: [
          GoRoute(
            path: 'add',
            builder: (_, state) => AddMoneyScreen(
              walletId: int.tryParse(state.uri.queryParameters['wallet'] ?? ''),
            ),
          ),
          GoRoute(
            path: 'wallets/new/:kind',
            builder: (_, state) => CreateWalletScreen(
              kind: WalletKind.values.byName(state.pathParameters['kind']!),
            ),
          ),
          GoRoute(
            path: 'wallets/:id',
            builder: (_, state) => WalletDetailScreen(walletId: _id(state)),
            routes: [
              GoRoute(
                path: 'unlock',
                builder: (_, state) => UnlockScreen(walletId: _id(state)),
              ),
              GoRoute(
                path: 'history',
                builder: (_, state) => HistoryScreen(walletId: _id(state)),
              ),
              GoRoute(
                path: 'gift-link',
                builder: (_, state) => GiftLinkScreen(
                  walletId: _id(state),
                  claimUrl: state.extra as String?,
                ),
              ),
            ],
          ),
          GoRoute(
            path: 'places/pick',
            builder: (_, _) => const PlacePickerScreen(),
          ),
          GoRoute(path: 'claim', builder: (_, _) => const PasteClaimScreen()),
          GoRoute(
            path: 'claim/:token',
            builder: (_, state) =>
                ClaimScreen(token: state.pathParameters['token']!),
          ),
        ],
      ),
    ],
  );
});

int _id(GoRouterState state) => int.parse(state.pathParameters['id']!);

/// Splash while restoring, sign-in when signed out, otherwise where they were
/// going. A signed-out visit (e.g. a claim link) resumes after sign-in via `from`.
@visibleForTesting
String? authRedirect(AsyncValue<Object?> auth, Uri uri) {
  final atGate = uri.path == Routes.splash || uri.path == Routes.signIn;
  final destination = atGate
      ? _safe(uri.queryParameters['from'])
      : _destination(uri);

  if (auth.isLoading && !auth.hasValue) {
    return uri.path == Routes.splash ? null : _gate(Routes.splash, destination);
  }
  if (auth.value == null) {
    return uri.path == Routes.signIn ? null : _gate(Routes.signIn, destination);
  }
  return atGate ? destination ?? Routes.home : null;
}

String? _destination(Uri uri) =>
    uri.path == Routes.home ? null : uri.toString();

/// Only in-app paths, so `from` can't send someone off to another site.
String? _safe(String? from) =>
    from != null && from.startsWith('/') && !from.startsWith('//')
    ? from
    : null;

String _gate(String route, String? from) => from == null
    ? route
    : Uri(path: route, queryParameters: {'from': from}).toString();
