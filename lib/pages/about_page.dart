import 'package:flutter/material.dart' as material;
import '../mapping/visualizer.dart' as visualizer;
import 'package:coordinate_converter/coordinate_converter.dart'
  as coord_converter;

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
    coord_converter.UTMCoordinates topLeft = 
    coord_converter.UTMCoordinates(x: 667083.5000, y: 9238889.5000, zoneNumber: 17, isSouthernHemisphere: true);
    coord_converter.UTMCoordinates bottomLeft = 
    coord_converter.UTMCoordinates(x: 667083.5000, y: 9238659.5000, zoneNumber: 17, isSouthernHemisphere: true);
    coord_converter.UTMCoordinates topRight = 
    coord_converter.UTMCoordinates(x: 667308.5000, y: 9238889.5000, zoneNumber: 17, isSouthernHemisphere: true);
    coord_converter.UTMCoordinates bottomRight = 
    coord_converter.UTMCoordinates(x: 667308.5000, y: 9238659.5000, zoneNumber: 17, isSouthernHemisphere: true);
    List<coord_converter.DDCoordinates> cornerCoordinates = [coord_converter.DDCoordinates.fromUTM(topLeft), coord_converter.DDCoordinates.fromUTM(bottomLeft), coord_converter.DDCoordinates.fromUTM(topRight), coord_converter.DDCoordinates.fromUTM(bottomRight)];


    return material.Scaffold(
      body:
        visualizer.Visualizer(cornerCoordinates: cornerCoordinates, dataFilePath: "assets/ebk_mean_prediction.csv", imageFilePath: "assets/2D_Site_Map_Test.png")
    );
    }
}