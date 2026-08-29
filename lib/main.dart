import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/providers.dart';
import 'app/router.dart';
import 'app/theme.dart';
import 'data/db/database.dart';
import 'data/repo/photo_repo.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!isDesktop && !kIsWeb) await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  final db = AppDatabase();
  final repo = PhotoRepo(db);
  // Desktop convenience: PHOTORANK_FOLDER=/path skips onboarding on first run.
  final seedFolder = kIsWeb ? null : Platform.environment['PHOTORANK_FOLDER'];
  if (isDesktop && seedFolder != null && await repo.pref(prefOnboarded) != '1' && await Directory(seedFolder).exists()) {
    await repo.setPref('scan_scope', '{"months": null, "albums": null, "folders": ["$seedFolder"]}');
    await repo.setPref(prefOnboarded, '1');
  }
  final onboarded = await repo.pref(prefOnboarded) == '1';
  runApp(ProviderScope(
    overrides: [
      dbProvider.overrideWithValue(db),
      if (isDesktop) cacheDirProvider.overrideWithValue(await defaultCacheDir()),
    ],
    child: PhotoRankApp(initialLocation: onboarded ? '/play' : '/onboarding'),
  ));
}

class PhotoRankApp extends StatefulWidget {
  const PhotoRankApp({super.key, required this.initialLocation});

  final String initialLocation;

  @override
  State<PhotoRankApp> createState() => _PhotoRankAppState();
}

class _PhotoRankAppState extends State<PhotoRankApp> {
  late final _router = buildRouter(initialLocation: widget.initialLocation);

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'PhotoRank',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      themeMode: ThemeMode.dark,
      routerConfig: _router,
    );
  }
}
