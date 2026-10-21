import 'package:app_links/app_links.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/claim_link.dart';

/// Claim tokens from links that open the app (`cashe://claim/<token>`), including
/// the link that launched it. Overridden with an empty stream in tests.
final claimTokensProvider = StreamProvider<String>((ref) {
  return AppLinks().uriLinkStream
      .map((uri) => ClaimLink.tokenFrom(uri.toString()))
      .where((token) => token != null)
      .cast<String>();
});
