import 'package:flutter/material.dart' as material;

import './about_page.dart' as about_page;
import './help_page.dart' as help_page;
import './languages_page.dart' as languages_page;
import './projects_page.dart' as projects_page;
import './settings_page.dart' as settings_page;
import './connections_page.dart' as connections_page;
import './predictions/prediction_view.dart';
import '../api/api.dart' as api;

/// A page containing the navigation bar for the app from which all other pages
/// can be accessed.
class HomePage extends material.StatefulWidget {
  const HomePage({super.key});

  @override
  material.State<HomePage> createState() => _HomePageState();
}

/// The mutable state of the home page.
class _HomePageState extends material.State<HomePage> {
  // index of the current page being displayed from the nav bar
  int currentPageIndex = 2;

  @override
  material.Widget build(material.BuildContext context) {
    api.LayerSpec layer = api.LayerSpec("Layer 1", "An archaeological stratum", DateTime.now(), DateTime.now());
    api.PredictionJob job = api.PredictionJob(layer);
    job.name = "Prediction 1";
    job.description = "This is a prediction!";
    job.createdAt = DateTime.now();
    job.status = api.JobStatus.complete;
    Map<String, String> layerAssignments = {"Unit 1": "pXRF_1.csv", "Unit 2": "pXRF_2.csv", "Unit 3": "pXRF_1.csv"};
    return material.Scaffold(
      bottomNavigationBar: material.NavigationBar(
        onDestinationSelected: (int index) {
          setState(() {
            currentPageIndex = index;
          });
        },
        indicatorColor: material.Colors.amber,
        selectedIndex: currentPageIndex,
        labelBehavior: material.NavigationDestinationLabelBehavior.alwaysHide,
        destinations: const <material.Widget>[
          material.NavigationDestination(
            icon: material.Icon(material.Icons.settings_outlined),
            label: 'Settings',
          ),
          material.NavigationDestination(
            icon: material.Icon(material.Icons.language_outlined),
            label: 'Languages',
          ),
          material.NavigationDestination(
            selectedIcon: material.Icon(material.Icons.home),
            icon: material.Icon(material.Icons.home_outlined),
            label: 'Home',
          ),
          material.NavigationDestination(
            icon: material.Icon(material.Icons.help_outline),
            label: 'Help',
          ),
          material.NavigationDestination(
            icon: material.Icon(material.Icons.info_outline),
            label: 'About',
          ),
          material.NavigationDestination(
            icon: material.Icon(material.Icons.warning),
            label: 'WIP'
          ),
        ],
      ),
      
      // page destinations of each item in the nav bar
      body: <material.Widget>[
        settings_page.SettingsPage(),
        languages_page.LanguagesPage(),
        projects_page.ProjectsPage(),
        help_page.HelpPage(),
        about_page.AboutPage(),
        PredictionView(predictionJob: job, layerAssignments: layerAssignments),
        ///connections_page.ConnectionsPage(),
      ][currentPageIndex],
    );
  }
}