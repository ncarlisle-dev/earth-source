import 'package:flutter/material.dart';
import './about_page.dart' as about_page;
import './help_page.dart' as help_page;
import './languages_page.dart' as languages_page;
import './projects_page.dart' as projects_page;
import './settings_page.dart' as settings_page;

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int currentPageIndex = 2;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Scaffold(
      bottomNavigationBar: NavigationBar(
        onDestinationSelected: (int index) {
          setState(() {
            currentPageIndex = index;
          });
        },
        indicatorColor: Colors.amber,
        selectedIndex: currentPageIndex,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
        destinations: const <Widget>[
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            label: 'Settings',
          ),
          NavigationDestination(
            icon: Icon(Icons.language_outlined),
            label: 'Languages',
          ),
          NavigationDestination(
            selectedIcon: Icon(Icons.home),
            icon: Icon(Icons.home_outlined),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.help_outline),
            label: 'Help',
          ),
          NavigationDestination(
            icon: Icon(Icons.info_outline),
            label: 'About',
          ),
          
        ],
      ),
      body: <Widget>[
        settings_page.SettingsPage(),
        languages_page.LanguagesPage(),
        projects_page.ProjectsPage(),
        help_page.HelpPage(),
        about_page.AboutPage(),
      ][currentPageIndex],
    );
  }
}