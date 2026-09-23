import 'package:flutter/material.dart' as material;
import 'package:coordinate_converter/coordinate_converter.dart'
  as coord_converter;
import 'dart:io' as io;

class LayerMap
{
  /// Coordinates for the corner points are stored in UTM and DD (since the 
  /// latter is needed to plot latitude and longitude)
  List<coord_converter.DDCoordinates> _cornerCoordinatesDD = [];
  
  io.File? imageFile;
  io.File? dataFile;

  LayerMap(this.dataFile, this.imageFile, this._cornerCoordinatesDD);
}

class Visualizer extends material.StatefulWidget {
  const Visualizer({super.key});

  @override
  material.State<Visualizer> createState() => VisualizerState();
}


class VisualizerState extends material.State<Visualizer>
{

  List<coord_converter.DDCoordinates> _cornerCoordinatesDD = [];
  
  io.File? imageFile;
  io.File? dataFile;

  @override
  material.Widget build(material.BuildContext context) {
    return material.MaterialApp(
        
      // Disable debug banner
      debugShowCheckedModeBanner: false, 
      home: material.Scaffold(
        appBar: material.AppBar(
          leading: const material.Icon(
            material.Icons.menu,
            
            // Icon color
            color: material.Colors.white, 
          ), 
          
          // Menu icon on the left
          
          // Green background color for AppBar
          backgroundColor: Colors.green, 
          title: const Text(
            
            // Title text
            "GeeksforGeeks", 
            
            // Text style
            style: TextStyle(color: Colors.white), 
          ),
        ), // AppBar
        body: const Center(
          child: Text(
              
            // Center text
            "Stateless Widget",
            
            // Text style
            style: TextStyle(color: Colors.black, fontSize: 30), 
          ),
        ), // Center
      ), // Scaffold
    ); // MaterialApp
  }
}