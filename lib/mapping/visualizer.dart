import 'package:flutter/material.dart' as material;
import 'package:coordinate_converter/coordinate_converter.dart'
  as coord_converter;
import 'dart:io' as io;
import 'package:flutter_map/flutter_map.dart' as map;
import 'package:flutter_map_heatmap/flutter_map_heatmap.dart' as heatmap;
import 'package:latlong2/latlong.dart' as latlong;
import 'package:url_launcher/url_launcher.dart' as url_launcher;
import 'package:csv/csv.dart' as csv_dart;
import 'dart:convert' as convert;

/// Opens the .CSV data file, checks if data is in the proper format, and 
/// converts it to a format that can be used to make a heat map.
/// 
/// Parameters: path to the data file, list of decimal coordinates representing
/// the four corners of the image file
/// 
/// Returns: A list of type WeightedLatLng, representing each prediction value
/// attached to a set of coordinates.
Future<List<heatmap.WeightedLatLng>> _validateData(String dataFilePath, 
List<coord_converter.DDCoordinates> cornerCoordinates) async
{
  List<heatmap.WeightedLatLng> heatmapData = [];
  bool isDataValid = true;

  // Check if a data file has been provided - if not, the following code is 
  // irrelevant
  if (dataFilePath != "")
  {
    io.File dataFile = io.File(dataFilePath);
    List<List<dynamic>> rows = await dataFile
      .openRead()
      .transform(convert.utf8.decoder)
      .transform(csv_dart.csv.decoder)
      .toList();
    
    /// Check if any data values fall outside the appropriate range (0 - 1)
    for (var i = 0; i < rows.length; i++)
    {
      for (var j = 0; j < rows[i].length; j++)
      {
        if (rows[i][j] <= 0 || rows[i][j] >= 1)
        {
          isDataValid = false;
        }
      }
    }

    /// If data is valid, calculate appropriate intervals between data points 
    /// and attach coordinates to each prediction.
    /// Note: I am assuming that eventually the CSV data outputted for 
    /// predictions will also contain locational data so that the information 
    /// plotted is accurate; hence why I am not calculating distances between 
    /// coordinates in the proper (and heavily mathematical) way at the moment.
    /// If need be, though, I will change this.
    if (isDataValid)
    {
      double horizontalInterval = (cornerCoordinates[2].longitude - 
        cornerCoordinates[0].longitude) / (rows[0].length - 1);
      double verticalInterval = (cornerCoordinates[0].latitude - 
        cornerCoordinates[1].latitude) / (rows.length - 1);
      
      for (var i = 0; i < rows.length; i++)
      {
        for (var j = 0; j < rows[i].length; j++)
        {
          latlong.LatLng pointCoordinates = 
            latlong.LatLng(cornerCoordinates[0].latitude + i * 
            horizontalInterval, cornerCoordinates[0].longitude + j * 
            verticalInterval);
          
          heatmapData.add(heatmap.WeightedLatLng(pointCoordinates, rows[i][j]));
        }
      }
    }
  }
  return heatmapData;
}

class _Visualizer extends material.StatelessWidget
{
  final List<coord_converter.DDCoordinates> cornerCoordinates;
  final String dataFilePath;
  final String imageFilePath;

  const _Visualizer({super.key, required this.cornerCoordinates, 
  required this.dataFilePath, required this.imageFilePath});

  @override
  material.Widget build(material.BuildContext context)
  {
    
    final map.MapController mapController = map.MapController();
    Map<double, material.MaterialColor> gradient = 
    {0.65: material.Colors.amber, 0.70: material.Colors.orange, 
    0.75: material.Colors.pink};

    List<heatmap.WeightedLatLng> heatmapData = [];

    Future<List<heatmap.WeightedLatLng>> futureHeatmapData = 
    _validateData(dataFilePath, cornerCoordinates);

    futureHeatmapData.then((value) {
      heatmapData = value;
    },);

    return material.Column(
        children: [
          material.Expanded(
            child: map.FlutterMap(
                mapController: mapController,
                options: map.MapOptions(
                  initialCenter: latlong.LatLng((cornerCoordinates[0].latitude + 
                  cornerCoordinates[2].latitude) / 2, 
                  (cornerCoordinates[0].longitude + 
                  cornerCoordinates[1].longitude) / 2),
                  initialZoom: 22.0,
                ),
                children: [
                  map.TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
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
                          cornerCoordinates[0].longitude),
                        bottomLeftCorner: latlong.LatLng(
                          cornerCoordinates[1].latitude, 
                          cornerCoordinates[1].longitude),
                        bottomRightCorner: latlong.LatLng(
                          cornerCoordinates[3].latitude, 
                          cornerCoordinates[3].longitude),
                        imageProvider: 
                        material.FileImage(io.File(imageFilePath)),
                      ),
                    ],
                  ),
                  if (heatmapData.isNotEmpty)
                    heatmap.HeatMapLayer(
                      heatMapDataSource: heatmap.InMemoryHeatMapDataSource(data:
                       heatmapData),
                      heatMapOptions: heatmap.HeatMapOptions(
                          gradient: gradient, minOpacity: 0.1),
                    ),
                ],
              ),
            ),
          ]
    );
  }
}