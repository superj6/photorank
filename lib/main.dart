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
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  final db = AppDatabase();
  final onboarded = await PhotoRepo(db).pref(prefOnboarded) == '1';
  runApp(ProviderScope(
    overrides: [dbProvider.overrideWithValue(db)],
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
