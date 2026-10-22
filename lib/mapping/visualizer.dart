import 'dart:io' as io;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as map;
import 'package:latlong2/latlong.dart' as latlong;
import 'package:flutter_map_math/flutter_geo_math.dart' as flutter_geo_math;
import 'package:url_launcher/url_launcher.dart' as url_launcher;
import 'heat_palette.dart';
import 'package:coordinate_converter/coordinate_converter.dart' as 
  coord_converter;

/// A single data point with attached UTM coordinates.
class MappedPoint
{
  /// The predicted value at the current point.
  double predictionPoint;
  /// The UTM coordinates at which that point is located.
  coord_converter.UTMCoordinates coordinates;
  /// The color of the data point so that points exceeding the threshold are 
  /// more easily distinguishable.
  Color pointColor;

  MappedPoint(this.predictionPoint, this.coordinates, this.pointColor);
}

/// Utility function - validates the contents of a given 2D list of data and 
/// attaches coordinates to each data point.
/// 
/// Returns a list of type Polygon representing appropriately-colored polygons
/// to be drawn onto the map if the file contains valid content; an empty list 
/// if invalid or if no data file is provided.
Future<List<map.Polygon>> _validateData(
  Map<double, latlong.LatLng> locatedData,
  double threshold
) async
{
  /// List storing the polygons to be drawn onto the map.
  List<map.Polygon> polygons = [];
  /// Boolean to ensure polygons are only created if prediction data is within
  /// a valid range.
  bool isDataValid = true;

  if (predictionData != [])
  {
    for (var i = 0; i < predictionData.length; i++) {
      for (var j = 0; j < predictionData[i].length; j++) {
        if (predictionData[i][j] < 0 || predictionData[i][j] > 1) {
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

      heightInterval = heightInterval / predictionData.length;
      widthInterval = widthInterval / predictionData[0].length;

      for (var i = 0; i < predictionData.length; i++) {
        for (var j = 0; j < predictionData[0].length; j++) {
          double predictionPoint = predictionData[i][j];

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

/// Utility function - determines the UTM coordinates associated with each data
/// point (specifically, the coordinates of the center of each plotted 
/// rectangle) and returns a list of geolocated data points.
Future<List<MappedPoint>> _attachCoords(
  List<List<double>> predictionData, 
  List<latlong.LatLng> cornerCoordinates,
  double threshold
) async
{
  List<MappedPoint> mappedData = [];
  
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

  heightInterval = heightInterval / predictionData.length;
  widthInterval = widthInterval / predictionData[0].length;

  for (var i = 0; i < predictionData.length; i++) {
    for (var j = 0; j < predictionData[0].length; j++) {
      double predictionPoint = predictionData[i][j];

      // Calculate distance to the center of the polygon that would be drawn
      // for each point.
      double height = (i + 0.5) * heightInterval;
      double width = (j + 0.5) * widthInterval;
      // Use these distances to calculate latitude and longitude for each
      // of the four corner points of the polygon.
      double longitude = flutter_geo_math.FlutterMapMath.destinationPoint(
        cornerCoordinates[0].latitude, 
        cornerCoordinates[0].longitude, 
        width, 
        90
      ).longitude;
      double latitude = flutter_geo_math.FlutterMapMath.destinationPoint(
        cornerCoordinates[0].latitude, 
        cornerCoordinates[0].longitude, 
        height, 
        180
      ).latitude;
        
      // Convert latitude and longitude to UTM coordinates.
      coord_converter.DDCoordinates ddCoords = coord_converter.DDCoordinates(
        latitude: latitude, 
        longitude: longitude
      );
      coord_converter.UTMCoordinates utmCoords = 
        coord_converter.UTMCoordinates.fromDD(ddCoords);

      Color pointColor;

      // Set the color of the prediction point to red if it exceeds the given
      // threshold for easier visualization.
      if (predictionPoint >= threshold) {
        pointColor = Colors.red;
      }
      else {
        pointColor = Colors.green;
      }

      mappedData.add(MappedPoint(predictionPoint, utmCoords, pointColor));
    }
  } 
  return mappedData;
}

/// Utility function - converts a list of UTM coordinates to a list of 
/// latitudinal/longitudinal coordinates.
List<latlong.LatLng> convertCoordsUTM(
  List<coord_converter.UTMCoordinates> utmCoords
)
{
  List<latlong.LatLng> latLngCoords = [];
  for (var i = 0; i < utmCoords.length; i++) {
    coord_converter.DDCoordinates ddCoords = 
      coord_converter.DDCoordinates.fromUTM(utmCoords[i]);
    latLngCoords.add(latlong.LatLng(ddCoords.latitude, ddCoords.longitude));
  }
  return latLngCoords;
}

/// Utility function - converts a list of latitudinal/longitudal coordinates to 
/// a list of UTM coordinates.
List<coord_converter.UTMCoordinates> convertCoordsLatLng(
  List<latlong.LatLng> latLongCoords
)
{
  List<coord_converter.UTMCoordinates> utmCoords = [];
  for (var i = 0; i < utmCoords.length; i++) {
    coord_converter.DDCoordinates ddCoords = coord_converter.DDCoordinates(
      latitude: latLongCoords[i].latitude, 
      longitude: latLongCoords[i].longitude
    );
    utmCoords.add(coord_converter.UTMCoordinates.fromDD(ddCoords));
  }
  return utmCoords;
}

/// A visualizer widget that displays either an image with no modifications if
/// no data file is provided, or an image with a heatmap overlaid onto it.
class Visualizer extends StatelessWidget
{
  /// 2D list of data representing the prediction points to be displayed.
  final List<List<double>> predictionData;
  /// Filepath to the image to be displayed.
  final String imageFilePath;
  /// List of decimal coordinates for the four corners of the image.
  final List<latlong.LatLng> cornerCoordinates;
  /// Threshold for the minimum value at which prediction points are displayed
  /// on the map, set by the user in the prediction page UI.
  final double threshold;

  const Visualizer({
    super.key, 
    required this.imageFilePath, 
    required this.predictionData, 
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
                  predictionData, 
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
        ),
      ]
    );
  }  
}

/// A widget that displays text-formatted predictions as a scrollable list of
/// points with coordinates attached.
class TextDisplay extends StatelessWidget
{
  /// 2D list of data representing the prediction points to be displayed.
  final List<List<double>> predictionData;
  /// List of decimal coordinates for the four corners of the image.
  final List<latlong.LatLng> cornerCoordinates;
  /// Threshold for the minimum value at which prediction points are displayed
  /// on the map, set by the user in the prediction page UI.
  final double threshold;

  const TextDisplay({
    super.key,  
    required this.predictionData, 
    required this.cornerCoordinates,
    required this.threshold
  });

  @override
  Widget build(BuildContext context)
  {
    return FutureBuilder(
      future: _attachCoords(predictionData, cornerCoordinates, threshold), 
      builder: (BuildContext ctx, AsyncSnapshot<List> snapshot) 
        => snapshot.hasData
      ?
        ListView.builder(
            itemCount: snapshot.data!.length, 
            itemBuilder: (BuildContext context, int index) {
              return ListTile(
                leading: Text(
                  "X Coordinate: ${snapshot.data![index].coordinates.x}\t "
                  "Y Coordinate: ${snapshot.data![index].coordinates.y}"),
                trailing: Text(
                  "Prediction Value: ${snapshot.data![index].predictionPoint}",
                  style: TextStyle(
                    color: snapshot.data![index].pointColor, 
                    fontSize: 15
                  ), 
                ),
              );
            },
          )
      :
        Center(child: Text("Predicted data is currently unavailable.")));
  }
}