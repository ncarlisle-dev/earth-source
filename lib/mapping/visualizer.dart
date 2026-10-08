import 'dart:io' as io;
import 'dart:convert' as convert;
import 'package:flutter/material.dart';
import 'package:csv/csv.dart' as csv_dart;
import 'package:flutter_map/flutter_map.dart' as map;
import 'package:latlong2/latlong.dart' as latlong;
import 'package:flutter_map_math/flutter_geo_math.dart' as flutter_geo_math;
import 'package:url_launcher/url_launcher.dart' as url_launcher;
import 'heat_palette.dart';

/// Utility function - opens the given data file and reads and validates its 
/// contents.
/// 
/// Returns a list of type Polygon representing appropriately-colored polygons
/// to be drawn onto the map if the file contains valid content; an empty list 
/// if invalid or if no data file is provided.
Future<List<map.Polygon>> _validateData(
  String dataFilePath, 
  List<latlong.LatLng> cornerCoordinates,
  double threshold
) async
{
  /// List storing the polygons to be drawn onto the map.
  List<map.Polygon> polygons = [];
  /// Boolean to ensure polygons are only created if prediction data is within
  /// a valid range.
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
      // Calculate the intervals in height (i.e. latitude) and width 
      // (i.e. longitude) between points in the grid by evenly spacing them over
      // the distance between corner coordinates.
      double heightInterval = flutter_geo_math.FlutterMapMath.distanceBetween(
        cornerCoordinates[0].latitude, 
        cornerCoordinates[0].longitude, 
        cornerCoordinates[1].latitude, 
        cornerCoordinates[1].longitude, 
        ""
      );
      double widthInterval = flutter_geo_math.FlutterMapMath.distanceBetween(
        cornerCoordinates[0].latitude, 
        cornerCoordinates[0].longitude, 
        cornerCoordinates[2].latitude, 
        cornerCoordinates[2].longitude, 
        ""
      );

      heightInterval = heightInterval / rows.length;
      widthInterval = widthInterval / rows[0].length;

      for (var i = 0; i < rows.length; i++) {
        for (var j = 0; j < rows[0].length; j++) {
          double predictionPoint = double.parse(rows[i][j]);

          // Check that current prediction point is above the user-set threshold
          // - if not, to cut down on rendering costs, that point won't be
          // displayed.
          if (predictionPoint > threshold) {
            // Calculate distance from the left side of the map image to the
            // left and right sides of the current point's polygon, as well as
            // distance from the top side of the map image to the top and 
            // bottom sides of the polygon.
            double height1 = i * heightInterval;
            double height2 = (i + 1) * heightInterval;
            double width1 = j * widthInterval;
            double width2 = (j + 1) * widthInterval;
            // Use these distances to calculate latitude and longitude for each
            // of the four corner points of the polygon.
            double left = flutter_geo_math.FlutterMapMath.destinationPoint(
              cornerCoordinates[0].latitude, 
              cornerCoordinates[0].longitude, 
              width1, 
              90
            ).longitude;
            double right = flutter_geo_math.FlutterMapMath.destinationPoint(
              cornerCoordinates[0].latitude, 
              cornerCoordinates[0].longitude, 
              width2, 
              90
            ).longitude;
            double top = flutter_geo_math.FlutterMapMath.destinationPoint(
              cornerCoordinates[0].latitude, 
              cornerCoordinates[0].longitude, 
              height1, 
              180
            ).latitude;
            double bottom = flutter_geo_math.FlutterMapMath.destinationPoint(
              cornerCoordinates[0].latitude, 
              cornerCoordinates[0].longitude, 
              height2, 
              180
            ).latitude;

            // Construct and color the polygon.
            map.Polygon polygon = map.Polygon(
              points: [
                latlong.LatLng(top, left), 
                latlong.LatLng(top, right), 
                latlong.LatLng(bottom, right), 
                latlong.LatLng(bottom, left)
              ], 
              color: HeatPalette.colorFor(predictionPoint, threshold, "soil")
            );
            polygons.add(polygon);
          }
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
  /// Threshold for the minimum value at which prediction points are displayed
  /// on the map, set by the user in the prediction page UI.
  final double threshold;

  const Visualizer({
    super.key, 
    required this.imageFilePath, 
    required this.dataFilePath, 
    required this.cornerCoordinates,
    required this.threshold
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
              initialCenter: latlong.LatLng(
                (cornerCoordinates[0].latitude + 
                cornerCoordinates[1].latitude) / 2, 
                (cornerCoordinates[0].longitude + 
                cornerCoordinates[2].longitude) / 2
              ),
              initialZoom: 22.0,
            ),
            children: [
              map.TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.archaeosight_two'
              ),
              map.RichAttributionWidget(
                popupInitialDisplayDuration: const Duration(seconds: 5),
                animationConfig: const map.ScaleRAWA(),
                showFlutterMapAttribution: false,
                attributions: [
                  map.TextSourceAttribution(
                    'OpenStreetMap contributors',
                    onTap: () async => url_launcher.launchUrl(
                      Uri.parse('https://openstreetmap.org/copyright'),
                    ),
                  ),
                ],
              ),
              map.OverlayImageLayer(
                overlayImages: [
                  map.RotatedOverlayImage(
                    topLeftCorner: latlong.LatLng(
                      cornerCoordinates[0].latitude, 
                      cornerCoordinates[0].longitude
                    ),
                    bottomLeftCorner: latlong.LatLng(
                      cornerCoordinates[1].latitude, 
                      cornerCoordinates[1].longitude
                    ),
                    bottomRightCorner: latlong.LatLng(
                      cornerCoordinates[3].latitude, 
                      cornerCoordinates[3].longitude
                    ),
                    imageProvider: FileImage(image),
                  )
                ]
              ),
              FutureBuilder(
                future: _validateData(
                  dataFilePath, 
                  cornerCoordinates, 
                  threshold
                ),
                builder: (
                  BuildContext ctx, 
                  AsyncSnapshot<List> snapshot
                ) 
                => snapshot.hasData
              ?
                map.PolygonLayer(
                  polygons: snapshot.data! as List<map.Polygon>
                )
              :
                Center(),
              ),
              map.OverlayImageLayer(
                overlayImages: [
                  map.RotatedOverlayImage(
                    topLeftCorner: latlong.LatLng(
                      cornerCoordinates[0].latitude, 
                      cornerCoordinates[0].longitude
                    ),
                    bottomLeftCorner: latlong.LatLng(
                      cornerCoordinates[1].latitude, 
                      cornerCoordinates[1].longitude
                    ),
                    bottomRightCorner: latlong.LatLng(
                      cornerCoordinates[3].latitude, 
                      cornerCoordinates[3].longitude
                    ),
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