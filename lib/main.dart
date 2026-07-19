/// main.dart
/// ---------------------------------------------------------------------------
/// Application entry point for the DBU Character Sheet.
///
/// Responsibilities:
///   • Ensure Flutter bindings are ready before touching plugins/storage.
///   • Create the (async) [CharacterRepository] once and inject it downstream.
///   • Configure a Material 3 theme with a Dragon Ball-flavoured colour scheme
///     (energetic orange seed) supporting light AND dark mode, so the app looks
///     right on Android, iOS, Windows, macOS and Web.
///   • Launch the character roster ([CharacterListScreen]) as the home screen.
/// ---------------------------------------------------------------------------
library;

import 'package:flutter/material.dart';

import 'data/homebrew_registry.dart';
import 'services/character_repository.dart';
import 'services/homebrew_repository.dart';
import 'ui/home_shell.dart';

Future<void> main() async {
  // Required before using any plugin (shared_preferences) prior to runApp.
  WidgetsFlutterBinding.ensureInitialized();

  // Initialise persistence up-front so the first frame already has storage.
  // Characters and homebrew live in separate stores (separate prefs keys).
  final repository = await CharacterRepository.create();
  final homebrewRepository = await HomebrewRepository.create();

  // Seed the runtime homebrew catalogue before the first frame, so characters
  // that use homebrew compute correctly on their very first build. The Homebrew
  // library screen keeps it in step after any save/delete.
  HomebrewRegistry.setAll(await homebrewRepository.loadAll());

  runApp(DbuApp(
    repository: repository,
    homebrewRepository: homebrewRepository,
  ));
}

class DbuApp extends StatelessWidget {
  const DbuApp({
    super.key,
    required this.repository,
    required this.homebrewRepository,
  });

  final CharacterRepository repository;
  final HomebrewRepository homebrewRepository;

  @override
  Widget build(BuildContext context) {
    const seed = Color(0xFFF25C05);

    ThemeData themed(Brightness brightness) => ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: seed,
            brightness: brightness,
          ),
          inputDecorationTheme: const InputDecorationTheme(
            border: OutlineInputBorder(),
            isDense: true,
          ),
        );

    return MaterialApp(
      title: 'DBU Character Sheet',
      debugShowCheckedModeBanner: false,
      theme: themed(Brightness.light),
      darkTheme: themed(Brightness.dark),
      // Follow the OS light/dark preference on every platform.
      themeMode: ThemeMode.system,
      home: HomeShell(
        characterRepository: repository,
        homebrewRepository: homebrewRepository,
      ),
    );
  }
}
