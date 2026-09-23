import 'package:flutter/material.dart' as material;
import 'package:coordinate_converter/coordinate_converter.dart'
  as coord_converter;
import 'dart:io' as io;
import 'package:flutter_map/flutter_map.dart' as map;
import 'package:flutter_map_heatmap/flutter_map_heatmap.dart' as heatmap;
import 'package:latlong2/latlong.dart' as latlong;

class _Visualizer extends material.StatelessWidget
{
  final List<coord_converter.DDCoordinates> cornerCoordinates;
  final io.File dataFile;
  final io.File imageFile;

  const _Visualizer({super.key, required this.cornerCoordinates, required this.dataFile, required this.imageFile});

  @override
  material.Widget build(material.BuildContext context)
  {
    
  }
}