import 'package:flutter/material.dart' as material;
import '../mapping/visualizer.dart' as visualizer;
import 'package:latlong2/latlong.dart' as latlong;

/// A page for describing the project, with links to the repository and website.
class AboutPage extends material.StatefulWidget {
  const AboutPage({super.key});

  @override
  material.State<AboutPage> createState() => _AboutPageState();
}

/// The mutable state of the about page.
class _AboutPageState extends material.State<AboutPage> {

  @override
  material.Widget build(material.BuildContext context) {
    
    return material.Scaffold(
      body:
        visualizer.Visualizer(
          dataFilePath: "assets/ebk_mean_prediction.csv", 
          imageFilePath: "assets/2D_Site_Map_Test.png",
          // The following coordinates represent the four corners of a site map
          // photo - the first is the top left corner, second is bottom left,
          // third is top right, and fourth is bottom right. The coordinates
          // used here for testing are taken mostly from Dr. Sharp's 
          // excavation area photo and correspond roughly to UTM coordinates of 
          // (631404.5, 9285285), (631404.5, 9285271), (631413.5, 9285285), and
          // (631413.5, 9285271) in Zone 17, Southern Hemisphere.
          cornerCoordinates: [
            latlong.LatLng(-6.464587823350703, -79.81167832340672), 
            latlong.LatLng(-6.464714347149058, -79.81167832340672), 
            latlong.LatLng(-6.464587823350703, -79.8115973391495), 
            latlong.LatLng(-6.464714347149058, -79.8115973391495)
          ],
          threshold: 0.6
        )
    );
    }
}