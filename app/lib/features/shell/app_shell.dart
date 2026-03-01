import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/repositories/bible_repository.dart';
import '../../theme/app_theme.dart';
import '../books/books_screen.dart';
import '../home/home_screen.dart';
import '../legal/legal_screen.dart';
import '../library/library_screen.dart';
import '../reader/desktop_reader_shell.dart';
import '../reader/reader_selection_controller.dart';
import '../search/search_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  static const double _mobileBreakpoint = 600;
  static const double _desktopBreakpoint = 1024;

  late int _selectedIndex;
  final ReaderSelectionController _readerSelectionController =
      ReaderSelectionController();

  final List<_AppShellDestination> _destinations =
      const <_AppShellDestination>[
        _AppShellDestination(
          icon: Icons.home_outlined,
          selectedIcon: Icons.home,
          label: 'Accueil',
        ),
        _AppShellDestination(
          icon: Icons.menu_book_outlined,
          selectedIcon: Icons.menu_book,
          label: 'Livres',
        ),
        _AppShellDestination(
          icon: Icons.search_outlined,
          selectedIcon: Icons.search,
          label: 'Recherche',
        ),
        _AppShellDestination(
          icon: Icons.bookmark_outline,
          selectedIcon: Icons.bookmark,
          label: 'Bibliothèque',
        ),
        _AppShellDestination(
          icon: Icons.settings_outlined,
          selectedIcon: Icons.settings,
          label: 'Paramètres',
        ),
      ];

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

  @override
  void dispose() {
    _readerSelectionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final isMobile = width < _mobileBreakpoint;
        final isDesktop = width >= _desktopBreakpoint;

        if (isMobile) {
          return Scaffold(
            body: _buildBody(isDesktop: false),
            bottomNavigationBar: BottomNavigationBar(
              type: BottomNavigationBarType.fixed,
              currentIndex: _selectedIndex,
              onTap: _onDestinationSelected,
              items: _destinations
                  .map(
                    (destination) => BottomNavigationBarItem(
                      icon: Icon(destination.icon),
                      activeIcon: Icon(destination.selectedIcon),
                      label: destination.label,
                    ),
                  )
                  .toList(growable: false),
            ),
          );
        }

        return Scaffold(
          body: Row(
            children: [
              NavigationRail(
                selectedIndex: _selectedIndex,
                onDestinationSelected: _onDestinationSelected,
                extended: isDesktop,
                labelType:
                    isDesktop ? NavigationRailLabelType.none : NavigationRailLabelType.all,
                destinations: _destinations
                    .map(
                      (destination) => NavigationRailDestination(
                        icon: Icon(destination.icon),
                        selectedIcon: Icon(destination.selectedIcon),
                        label: Text(destination.label),
                      ),
                    )
                    .toList(growable: false),
              ),
              const VerticalDivider(width: 1),
              Expanded(
                child: _constrainDesktopBody(
                  child: _buildBody(isDesktop: isDesktop),
                  isDesktop: isDesktop,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _constrainDesktopBody({
    required Widget child,
    required bool isDesktop,
  }) {
    if (!isDesktop || _selectedIndex == 1) {
      return child;
    }
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppTheme.maxContentWidth),
        child: child,
      ),
    );
  }

  Widget _buildBody({required bool isDesktop}) {
    final bibleRepository = context.read<BibleRepository>();

    switch (_selectedIndex) {
      case 0:
        return HomeScreen(bibleRepository: bibleRepository);
      case 1:
        if (isDesktop) {
          return ChangeNotifierProvider<ReaderSelectionController>.value(
            value: _readerSelectionController,
            child: const DesktopReaderShell(),
          );
        }
        return const BooksScreen();
      case 2:
        return const SearchScreen();
      case 3:
        return const LibraryScreen();
      case 4:
      default:
        return const LegalScreen();
    }
  }

  void _onDestinationSelected(int index) {
    if (index == _selectedIndex) {
      return;
    }
    setState(() {
      _selectedIndex = index;
    });
  }
}

class _AppShellDestination {
  const _AppShellDestination({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
}
