import 'dart:io' as io;
import 'dart:convert' as convert;
import 'package:flutter/material.dart';
import 'package:csv/csv.dart' as csv_dart;
import 'package:flutter_map/flutter_map.dart' as map;
import 'package:latlong2/latlong.dart' as latlong;
import 'package:flutter_map_math/flutter_geo_math.dart' as flutter_geo_math;

/// Utility function - opens the given data file and reads and validates its 
/// contents.
/// 
/// Returns a 2D list of parsed CSV data if the file contains valid content; an
/// empty list if invalid or if no data file is provided.
Future<List<map.Polygon>> _validateData(String dataFilePath, List<latlong.LatLng> cornerCoordinates) async
{
  List<map.Polygon> polygons = [];
  /// Boolean to ensure data is only returned if it's within a valid range.
  bool isDataValid = true;

  if (dataFilePath != "")
  {
    io.File dataFile = io.File(dataFilePath);
    List<List<dynamic>> rows = await dataFile
      .openRead()
      .transform(convert.utf8.decoder)
      .transform(csv_dart.csv.decoder)
      .toList();
    
    for (var i = 0; i < rows.length; i++) {
      for (var j = 0; j < rows[i].length; j++) {
        if (double.parse(rows[i][j]) <= 0 || double.parse(rows[i][j]) >= 1) {
          isDataValid = false;
        }
      }
    }

    if (isDataValid) {
      double heightInterval = flutter_geo_math.FlutterMapMath.distanceBetween(cornerCoordinates[0].latitude, cornerCoordinates[0].longitude, cornerCoordinates[1].latitude, cornerCoordinates[1].longitude, "");
      double widthInterval = flutter_geo_math.FlutterMapMath.distanceBetween(cornerCoordinates[0].latitude, cornerCoordinates[0].longitude, cornerCoordinates[2].latitude, cornerCoordinates[2].longitude, "");

      heightInterval = heightInterval / rows.length;
      widthInterval = widthInterval / rows[0].length;

      for (var i = 0; i < rows.length; i++) {
        for (var j = 0; j < rows[0].length; j++) {
          double height1 = i * heightInterval;
          double height2 = (i + 1) * heightInterval;
          double width1 = j * widthInterval;
          double width2 = (j + 1) * widthInterval;
          double left = flutter_geo_math.FlutterMapMath.destinationPoint(cornerCoordinates[0].latitude, cornerCoordinates[0].longitude, width1, 90).longitude;
          double right = flutter_geo_math.FlutterMapMath.destinationPoint(cornerCoordinates[0].latitude, cornerCoordinates[0].longitude, width2, 90).longitude;
          double top = flutter_geo_math.FlutterMapMath.destinationPoint(cornerCoordinates[0].latitude, cornerCoordinates[0].longitude, height1, 180).latitude;
          double bottom = flutter_geo_math.FlutterMapMath.destinationPoint(cornerCoordinates[0].latitude, cornerCoordinates[0].longitude, height2, 180).latitude;
          Color color;
          switch (double.parse(rows[i][j]))
          {
            case > 0.9:
              color = Color.fromARGB(255, 8, 61, 1);
              break;
            case > 0.8:
              color = Color.fromARGB(255, 69, 153, 32);
              break;
            case > 0.75:
              color = Color.fromARGB(255, 117, 200, 54);
              break;
            case > 0.6:
              color = Color.fromARGB(255, 185, 247, 114);
              break;
            case > 0.5:
              color = Color.fromARGB(255, 206, 253, 200);
              break;
            default:
              color = Colors.transparent;
              break;
          }
          map.Polygon polygon = map.Polygon(points: [latlong.LatLng(top, left), latlong.LatLng(top, right), latlong.LatLng(bottom, right), latlong.LatLng(bottom, left)], color: color);
          polygons.add(polygon);
        }
      } 
    }
  }
  return polygons;
}

/// A visualizer widget that displays either an image with no modifications if
/// no data file is provided, or an image with a heatmap overlaid onto it.
class Visualizer extends StatelessWidget
{
  /// Filepath to a CSV file storing prediction results (given an empty string
  /// if non-applicable);
  final String dataFilePath;
  /// Filepath to the image to be displayed.
  final String imageFilePath;
  /// List of decimal coordinates for the four corners of the image - currently
  /// not in use.
  final List<latlong.LatLng> cornerCoordinates;

  const Visualizer({
    super.key, 
    required this.imageFilePath, 
    required this.dataFilePath, 
    required this.cornerCoordinates
  });

  @override
  Widget build(BuildContext context)
  {
    final map.MapController mapController = map.MapController();
    io.File image = io.File(imageFilePath);
    
    return Column(
      children: [  
        Expanded(
            child: map.FlutterMap(
                mapController: mapController,
                options: map.MapOptions(
                  initialCenter: latlong.LatLng((cornerCoordinates[0].latitude + 
                  cornerCoordinates[1].latitude) / 2, 
                  (cornerCoordinates[0].longitude + 
                  cornerCoordinates[2].longitude) / 2),
                  initialZoom: 22.0,
                ),
                children: [
                  map.OverlayImageLayer(
                    overlayImages: [
                      map.RotatedOverlayImage(
                        topLeftCorner: latlong.LatLng(
                          cornerCoordinates[0].latitude, 
                          cornerCoordinates[0].longitude),
                        bottomLeftCorner: latlong.LatLng(
                          cornerCoordinates[1].latitude, 
                          cornerCoordinates[1].longitude),
                        bottomRightCorner: latlong.LatLng(
                          cornerCoordinates[3].latitude, 
                          cornerCoordinates[3].longitude),
                        imageProvider: FileImage(image),
                      )
                    ]
                  ),
                  FutureBuilder(
                    future: _validateData(dataFilePath, cornerCoordinates),
                    builder: (BuildContext ctx, 
                    AsyncSnapshot<List> snapshot) 
                    => snapshot.hasData
                  ?
                    map.PolygonLayer(polygons: snapshot.data! as List<map.Polygon>)
                  :
                    Center(),
                  ),
                  map.OverlayImageLayer(
                    overlayImages: [
                      map.RotatedOverlayImage(
                        topLeftCorner: latlong.LatLng(
                          cornerCoordinates[0].latitude, 
                          cornerCoordinates[0].longitude),
                        bottomLeftCorner: latlong.LatLng(
                          cornerCoordinates[1].latitude, 
                          cornerCoordinates[1].longitude),
                        bottomRightCorner: latlong.LatLng(
                          cornerCoordinates[3].latitude, 
                          cornerCoordinates[3].longitude),
                        imageProvider: FileImage(image),
                        opacity: 0.2,
                      )
                    ]
                  ),
                  map.OverlayImageLayer(
                    overlayImages: [
                      map.RotatedOverlayImage(
                        topLeftCorner: latlong.LatLng(
                          cornerCoordinates[0].latitude, 
                          cornerCoordinates[0].longitude),
                        bottomLeftCorner: latlong.LatLng(
                          cornerCoordinates[1].latitude, 
                          cornerCoordinates[1].longitude),
                        bottomRightCorner: latlong.LatLng(
                          cornerCoordinates[3].latitude, 
                          cornerCoordinates[3].longitude),
                        imageProvider: FileImage(image),
                        opacity: 0.5,
                      )
                    ]
                  ),
                  const map.Scalebar(
                    textStyle: TextStyle(color: Colors.black, fontSize: 14),
                    padding: EdgeInsets.only(right: 10, left: 10, bottom: 40),
                    alignment: Alignment.bottomCenter,
                    length: map.ScalebarLength.xxl,
                  ),
                ]
              )
            )
      ]
    );
  }  
}