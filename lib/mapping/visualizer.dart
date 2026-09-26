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

Future<List<heatmap.WeightedLatLng>> _validateData(String dataFilePath, List<coord_converter.DDCoordinates> cornerCoordinates) async
  {
    List<heatmap.WeightedLatLng> heatMapData = [];
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
      
      for (var i = 0; i < rows.length; i++)
      {
        for (var j = 0; j < rows[i].length; j++)
        {
          if (double.parse(rows[i][j]) <= 0 || double.parse(rows[i][j]) >= 1)
          {
            isDataValid = false;
          }
        }
      }

      /// If data is valid, calculate appropriate intervals between data points 
      /// and attach coordinates to each prediction.
      if (isDataValid)
      {
        double latitudeInterval = (cornerCoordinates[1].latitude - 
          cornerCoordinates[0].latitude) / (rows.length - 1);
        double longitudeInterval = (cornerCoordinates[0].longitude - 
          cornerCoordinates[2].longitude) / (rows[0].length - 1);
        
        for (var i = 0; i < rows.length; i++)
        {
          for (var j = 0; j < rows[i].length; j++)
          {
            latlong.LatLng pointCoordinates = 
              latlong.LatLng(cornerCoordinates[0].latitude + j * 
              latitudeInterval, cornerCoordinates[0].longitude - i * 
              longitudeInterval);
            
            heatMapData.add(heatmap.WeightedLatLng(pointCoordinates, 
            double.parse(rows[i][j])));
          }
        }
      }
    } 
    return heatMapData;
  }

class Visualizer extends material.StatelessWidget
{
  final List<coord_converter.DDCoordinates> cornerCoordinates;
  final String dataFilePath;
  final String imageFilePath;

  const Visualizer({super.key, required this.cornerCoordinates, 
   required this.imageFilePath, required this.dataFilePath});

  @override
  material.Widget build(material.BuildContext context)
  {
    Map<double, material.MaterialColor> gradient = 
    {0.65: material.Colors.blue, 0.70: material.Colors.purple, 
    0.75: material.Colors.pink};

    final map.MapController mapController = map.MapController();

    return material.Column(
        children: [
          material.Expanded(
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
                        imageProvider: 
                        material.FileImage(io.File(imageFilePath)),
                      ),
                    ],
                  ),
                  material.FutureBuilder(
                    future: _validateData(dataFilePath, cornerCoordinates),
                    builder: (material.BuildContext ctx, material.AsyncSnapshot<List> snapshot) =>
                    snapshot.hasData
                    ? 
                    heatmap.HeatMapLayer(
                      heatMapDataSource: heatmap.InMemoryHeatMapDataSource(data:
                       snapshot.data! as List<heatmap.WeightedLatLng>),
                      heatMapOptions: heatmap.HeatMapOptions(
                          gradient: gradient, minOpacity: 0.1, radius: 1),
                      maxZoom: 30,
                    )
                    :
                    const material.Center()
                  )
                ],
              ),
            ),
          ]
    );
  }  
}