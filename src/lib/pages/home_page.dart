import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart' as cupertino;

import './about_page.dart';
import './help_page.dart';
import './languages_page.dart';
import './projects_page.dart';
import './settings_page.dart';

/// A page containing the navigation bar for the app from which all other pages
/// can be accessed.
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

/// The mutable state of the home page.
class _HomePageState extends State<HomePage> {
  final cupertino.CupertinoTabController controller = 
    cupertino.CupertinoTabController();

  @override
  Widget build(BuildContext context) {
    controller.index = 2;
    return cupertino.CupertinoTabScaffold(
      controller: controller,
      tabBar: cupertino.CupertinoTabBar(
        //backgroundColor: Color.fromARGB(255, 44, 57, 71),
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            label: "Settings",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.language_outlined),
            label: "Languages",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.help_outline),
            label: "Help",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.info_outline),
            label: "About",
          ),
        ],
        activeColor: Color.fromARGB(255, 84, 122, 149),
      ),
      tabBuilder: (context, index) {
        switch (index) {
          case 0:
            return cupertino.CupertinoTabView(builder: (context) {
              return cupertino.CupertinoPageScaffold(child: SettingsPage());
            });
          case 1:
            return cupertino.CupertinoTabView(builder: (context) {
              return cupertino.CupertinoPageScaffold(child: LanguagesPage());
            });
          case 2:
            return cupertino.CupertinoTabView(builder: (context) {
              return cupertino.CupertinoPageScaffold(child: UserProjectsPage());
            });
          case 3:
            return cupertino.CupertinoTabView(builder: (context) {
              return cupertino.CupertinoPageScaffold(child: HelpPage());
            });
          case 4:
            return cupertino.CupertinoTabView(builder: (context) {
              return cupertino.CupertinoPageScaffold(child: AboutPage());
            });
          default:
            return const cupertino.CupertinoTabView();
        }
      },
    );
  }
}
