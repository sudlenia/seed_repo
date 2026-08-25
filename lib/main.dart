import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import 'package:wallet_test/core/di/get_it_injector.dart';
import 'package:wallet_test/features/auth/auth_repository.dart';
import 'package:wallet_test/features/router/app_router.dart';
import 'package:wallet_test/features/router/auth_change_notifier.dart';

void main() {
  registerAppDependencies();
  runApp(const WalletApp());
}

class WalletApp extends StatefulWidget {
  const WalletApp({super.key});

  @override
  State<WalletApp> createState() => _WalletAppState();
}

class _WalletAppState extends State<WalletApp> {
  late final AppRouter _appRouter;
  late final AuthChangeNotifier _authNotifier;

  @override
  void initState() {
    super.initState();
    _appRouter = GetIt.instance<AppRouter>();
    _authNotifier = AuthChangeNotifier(
      auth: GetIt.instance<IAuthRepository>(),
      router: _appRouter.router,
    );
  }

  @override
  void dispose() {
    _authNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: _appRouter.router,
      debugShowCheckedModeBanner: false,
    );
  }
}