import 'package:appwrite/appwrite.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/env.dart';
import 'jwt_source.dart';

final appwriteClientProvider = Provider<Client>((ref) {
  return Client()
      .setEndpoint(Env.appwriteEndpoint)
      .setProject(Env.appwriteProjectId);
});

final appwriteAccountProvider = Provider<Account>((ref) {
  return Account(ref.watch(appwriteClientProvider));
});

final jwtSourceProvider = Provider<JwtSource>((ref) {
  final account = ref.watch(appwriteAccountProvider);
  return JwtSource(mint: () async => (await account.createJWT()).jwt);
});
