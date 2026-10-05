import "package:flutter/material.dart";

import "home_screen.dart";
import "library_screen.dart";
import "profile_screen.dart";
import "search_screen.dart";

/// Estrutura principal do app logado: 4 abas com barra de navegação
/// inferior. Cada aba mantém o próprio estado (scroll, filtros) graças ao
/// [IndexedStack].
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  static const int homeTab = 0;
  static const int searchTab = 1;
  static const int libraryTab = 2;
  static const int profileTab = 3;

  /// Troca de aba a partir de qualquer tela dentro do shell (ex.: o card
  /// "Importe sua biblioteca Steam" da Home leva para a aba Biblioteca).
  static void goToTab(BuildContext context, int index) {
    context.findAncestorStateOfType<_MainShellState>()?._select(index);
  }

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = MainShell.homeTab;

  void _select(int index) => setState(() => _index = index);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: const [
          HomeScreen(),
          SearchScreen(),
          LibraryScreen(),
          ProfileScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: _select,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: "Início",
          ),
          NavigationDestination(
            icon: Icon(Icons.search_rounded),
            label: "Buscar",
          ),
          NavigationDestination(
            icon: Icon(Icons.sports_esports_outlined),
            selectedIcon: Icon(Icons.sports_esports_rounded),
            label: "Biblioteca",
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: "Perfil",
          ),
        ],
      ),
    );
  }
}

/// Limita a largura do conteúdo em telas grandes (web/desktop), mantendo o
/// layout pensado para celular legível no navegador.
class ContentWidth extends StatelessWidget {
  const ContentWidth({super.key, required this.child, this.maxWidth = 760});

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
