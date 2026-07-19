/// home_shell.dart
/// ---------------------------------------------------------------------------
/// The top-level home scaffold. Hosts the two main sections — the character
/// roster and the homebrew library — behind a Material 3 NavigationBar, so the
/// app opens on Characters and the player can switch to Homebrew with one tap.
///
/// Each section is a self-contained screen with its own AppBar and controls;
/// this shell only owns the section switch. An IndexedStack keeps both alive so
/// switching back doesn't reload or lose scroll position.
/// ---------------------------------------------------------------------------
library;

import 'package:flutter/material.dart';

import '../services/character_repository.dart';
import '../services/homebrew_repository.dart';
import 'character_list_screen.dart';
import 'homebrew_list_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({
    super.key,
    required this.characterRepository,
    required this.homebrewRepository,
  });

  final CharacterRepository characterRepository;
  final HomebrewRepository homebrewRepository;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          CharacterListScreen(
            repository: widget.characterRepository,
            homebrewRepository: widget.homebrewRepository,
          ),
          HomebrewListScreen(repository: widget.homebrewRepository),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.people_alt_outlined),
            selectedIcon: Icon(Icons.people_alt),
            label: 'Characters',
          ),
          NavigationDestination(
            icon: Icon(Icons.auto_fix_high_outlined),
            selectedIcon: Icon(Icons.auto_fix_high),
            label: 'Homebrew',
          ),
        ],
      ),
    );
  }
}
