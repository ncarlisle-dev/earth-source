import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as map;
import 'package:latlong2/latlong.dart' as latlong;
import 'package:flutter_map_math/flutter_geo_math.dart' as flutter_geo_math;
import 'package:url_launcher/url_launcher.dart' as url_launcher;
import 'heat_palette.dart';
import 'package:coordinate_converter/coordinate_converter.dart' as 
  coord_converter;
import 'dart:convert' as convert;

/// Utility function - validates the contents of a given 2D list of data and 
/// attaches coordinates to each data point.
/// 
/// Returns a list of type Polygon representing appropriately-colored polygons
/// to be drawn onto the map if the file contains valid content; an empty list 
/// if invalid or if no data file is provided.
Future<List<map.Polygon>> _validateData(
  List<coord_converter.UTMCoordinates> predictedPoints,
  List<double> predictedValues,
  double threshold
) async
{
  /// List storing the polygons to be drawn onto the map.
  List<map.Polygon> polygons = [];
  /// List in latitude/longitude of all the coordinates of the predictions.
  List<latlong.LatLng> coordinates = convertCoordsUTM(predictedPoints);

  double widthInterval = flutter_geo_math.FlutterMapMath.distanceBetween(
    coordinates[0].latitude, 
    coordinates[0].longitude, 
    coordinates[1].latitude, 
    coordinates[1].longitude,
    ""
  );

  int index = 0;
  while (predictedPoints[index].y == predictedPoints[index + 1].y)
  {
    index++;
  }
  index ++;

  double heightInterval = flutter_geo_math.FlutterMapMath.distanceBetween(
    coordinates[0].latitude, 
    coordinates[0].longitude, 
    coordinates[index].latitude, 
    coordinates[index].longitude,
    ""
  );

  for (var i = 0; i < predictedPoints.length; i++) {

    // Check that current prediction point is above the user-set threshold
    // - if not, to cut down on rendering costs, that point won't be
    // displayed.
    if (predictedValues[i] > threshold) {
      double right = flutter_geo_math.FlutterMapMath.destinationPoint(
        coordinates[i].latitude, 
        coordinates[i].longitude, 
        widthInterval, 
        90
      ).longitude;
      double bottom = flutter_geo_math.FlutterMapMath.destinationPoint(
        coordinates[i].latitude, 
        coordinates[i].longitude, 
        heightInterval, 
        180
      ).latitude;

      // Construct and color the polygon.
      map.Polygon polygon = map.Polygon(
        points: [
          latlong.LatLng(coordinates[i].latitude, coordinates[i].longitude), 
          latlong.LatLng(coordinates[i].latitude, right), 
          latlong.LatLng(bottom, right), 
          latlong.LatLng(bottom, coordinates[i].longitude)
        ], 
        color: HeatPalette.colorFor(predictedValues[i], threshold, "soil")
      );
      polygons.add(polygon);
    }
  }
  return polygons;
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
  for (var i = 0; i < latLongCoords.length; i++) {
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
  /// List of UTM coordinates for each prediction point.
  final List<coord_converter.UTMCoordinates> predictionCoords;
  /// List of calculated values corresponding to each prediction point.
  final List<double> predictionValues;
  /// Filepath to the image to be displayed.
  final String imageFile;
  /// List of decimal coordinates for the four corners of the image.
  final List<latlong.LatLng> corners;
  /// Threshold for the minimum value at which prediction points are displayed
  /// on the map, set by the user in the prediction page UI.
  final double threshold;

  const Visualizer({
    super.key, 
    required this.imageFile, 
    required this.predictionCoords, 
    required this.predictionValues,
    required this.cornerCoordinates,
    required this.threshold
  });

  @override
  Widget build(BuildContext context)
  {
    final map.MapController mapController = map.MapController();
    
    return Column(
      children: [  
        Expanded(
          child: map.FlutterMap(
            mapController: mapController,
            options: map.MapOptions(
              initialCenter: latlong.LatLng(
                (corners[0].latitude + 
                corners[1].latitude) / 2, 
                (corners[0].longitude + 
                corners[2].longitude) / 2
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
                      corners[0].latitude, 
                      corners[0].longitude
                    ),
                    bottomLeftCorner: latlong.LatLng(
                      corners[1].latitude, 
                      corners[1].longitude
                    ),
                    bottomRightCorner: latlong.LatLng(
                      corners[3].latitude, 
                      corners[3].longitude
                    ),
                    imageProvider: MemoryImage(convert.base64Decode(imageFile)),
                  )
                ]
              ),
              FutureBuilder(
                future: _validateData(
                  predictionCoords,
                  predictionValues,
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
                      corners[0].latitude, 
                      corners[0].longitude
                    ),
                    bottomLeftCorner: latlong.LatLng(
                      corners[1].latitude, 
                      corners[1].longitude
                    ),
                    bottomRightCorner: latlong.LatLng(
                      corners[3].latitude, 
                      corners[3].longitude
                    ),
                    imageProvider: MemoryImage(convert.base64Decode(imageFile)),
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
  /// List of the coordinates of the points to be displayed.
  final List<coord_converter.UTMCoordinates> predictionCoords;
  /// List of the values of each displayed point.
  final List<double> predictionValues;
  /// Threshold for the minimum value at which prediction points are displayed
  /// on the map, set by the user in the prediction page UI.
  final double threshold;

  const TextDisplay({
    super.key,  
    required this.predictionCoords, 
    required this.predictionValues,
    required this.threshold
  });

  @override
  Widget build(BuildContext context)
  {
    return ListView.builder(
      itemCount: predictionCoords.length, 
      itemBuilder: (BuildContext context, int index) {
        return ListTile(
          leading: Text(
            "X Coordinate: ${predictionCoords[index].x}\t "
            "Y Coordinate: ${predictionCoords[index].y}"),
          trailing: Text(
            "Prediction Value: ${predictionValues[index]}",
            style: TextStyle(
              color: predictionValues[index] > threshold ? Colors.red 
                : Colors.green, 
              fontSize: 15
            ), 
          ),
        );
      },
    );
  }
}