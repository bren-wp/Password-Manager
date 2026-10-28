import 'dart:io';

import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import 'core/vault_store.dart';
import 'ui/auth_screen.dart';
import 'ui/brand.dart';
import 'ui/vault_shell.dart';
import 'ui/welcome_screen.dart';
import 'ui/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isWindows) {
    await windowManager.ensureInitialized();
    const options = WindowOptions(
      size: Size(1200, 800),
      minimumSize: Size(820, 560),
      center: true,
      title: 'Veldigo',
      backgroundColor: VColors.background,
    );
    await windowManager.waitUntilReadyToShow(options, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }
  runApp(const VeldigoApp());
}

class VeldigoApp extends StatefulWidget {
  const VeldigoApp({super.key});
  @override
  State<VeldigoApp> createState() => _VeldigoAppState();
}

class _VeldigoAppState extends State<VeldigoApp> with WidgetsBindingObserver {
  final VaultStore store = VaultStore();
  bool loading = true;
  bool welcomeCompleted = false;
  String? error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _init();
  }

  Future<void> _init() async {
    try {
      await store.initialize();
    } catch (_) {
      error = 'Trezor se ne može otvoriti. Provjerite prostor i dopuštenja.';
    }
    if (mounted) { setState(() => loading = false); }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Prevent cached credentials from remaining available after switching
    // applications, minimizing the time secrets live in Dart-managed memory.
    // Windows can remain inactive with another application foregrounded:
    // treat focus loss as a lock, except during an explicitly authorized,
    // time-limited native encrypted-backup file picker.
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached ||
        (Platform.isWindows && state == AppLifecycleState.inactive)) {
      if (store.isUnlocked && !store.externalPickerGraceActive) {
        store.lock();
      }
    } else if (state == AppLifecycleState.resumed &&
        store.externalPickerExpired && store.isUnlocked) {
      // Timers may be suspended while Android's file picker is in front.
      store.lock();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    store.lock();
    store.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Veldigo',
    debugShowCheckedModeBanner: false,
    theme: veldigoTheme(),
    home: AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        if (loading) { return const SplashScreen(); }
        if (error != null) { return Scaffold(
          body: Center(child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(error!, textAlign: TextAlign.center)))); }
        if (!store.hasVault && !welcomeCompleted) {
          return WelcomeScreen(onStart: () => setState(() {
            welcomeCompleted = true;
          }));
        }
        if (!store.hasVault) { return AuthScreen(
          key: const ValueKey('create'), store: store, create: true); }
        if (!store.isUnlocked) { return AuthScreen(
          key: const ValueKey('unlock'), store: store, create: false); }
        return VaultShell(store: store);
      },
    ),
  );
}
