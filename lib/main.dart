import 'dart:io';

import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import 'core/vault_store.dart';
import 'ui/auth_screen.dart';
import 'ui/brand.dart';
import 'ui/vault_shell.dart';

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
  String? error;
  DateTime? backgroundedAt;

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
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      backgroundedAt ??= DateTime.now();
    } else if (state == AppLifecycleState.resumed) {
      final previous = backgroundedAt;
      backgroundedAt = null;
      if (previous != null &&
          DateTime.now().difference(previous) >= const Duration(minutes: 2)) {
        store.lock();
      }
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
        if (loading) { return const Scaffold(
          body: Center(child: CircularProgressIndicator(color: VColors.accent))); }
        if (error != null) { return Scaffold(
          body: Center(child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(error!, textAlign: TextAlign.center)))); }
        if (!store.hasVault) { return AuthScreen(
          key: const ValueKey('create'), store: store, create: true); }
        if (!store.isUnlocked) { return AuthScreen(
          key: const ValueKey('unlock'), store: store, create: false); }
        return VaultShell(store: store);
      },
    ),
  );
}
