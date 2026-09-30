import 'package:flutter/material.dart' as material;
import 'package:coordinate_converter/coordinate_converter.dart'
  as coord_converter;
import 'dart:io' as io;
import 'package:csv/csv.dart' as csv_dart;
import 'dart:convert' as convert;
import 'package:image_size_getter/image_size_getter.dart' as image_size_getter;
import 'package:image_size_getter/file_input.dart' as file_input;
import 'heatmap_painter.dart' as heatmap_painter;
import 'dart:ui' as ui;

/// Opens the given data file and reads and validates its contents.
/// 
/// Returns a 2D list of parsed CSV data if the file contains valid content; an
/// empty list if invalid or if no data file is provided.
Future<List<List<double>>> _validateData(String dataFilePath) async
{
  /// 2D list of data values.
  List<List<double>> heatMapData = [];
  /// Boolean to ensure data is only returned if it's within a valid range.
  bool isDataValid = true;

  // Check if a data file has been provided and open it if so.
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

    if (isDataValid)
    {
      for (var i = 0; i < rows.length; i++)
      {
        List<double> rowList = [];
        for (var j = 0; j < rows[i].length; j++)
        {
          rowList.add(double.parse(rows[i][j]));
          heatMapData.add(rowList);
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

  List<double> _calculateDimensions(double screenWidth, double screenHeight, double imageWidth, double imageHeight)
  {
    double containerWidth;
    double containerHeight;

    if (screenWidth >= imageWidth && screenHeight >= imageHeight) {
      containerWidth = imageWidth;
      containerHeight = imageHeight;
    }
    else if (screenWidth >= imageWidth && screenHeight < imageHeight) {
      containerWidth = (screenHeight / imageHeight) * imageWidth;
      containerHeight = screenHeight;
    }
    else if (screenWidth < imageWidth && screenHeight >= imageHeight) {
      containerWidth = screenWidth;
      containerHeight = (screenWidth / imageWidth) * imageHeight;
    }
    else {
      if (screenWidth / imageWidth < screenHeight / imageHeight) {
        containerWidth = screenWidth;
        containerHeight = (screenWidth / imageWidth) * imageHeight;
      }
      else {
        containerWidth = (screenHeight / imageHeight) * imageWidth;
        containerHeight = screenHeight;
      }
    }
    return [containerWidth, containerHeight];
  }

  @override
  material.Widget build(material.BuildContext context)
  {
    io.File image = io.File(imageFilePath);
    final jpgResult = image_size_getter.ImageSizeGetter.getSizeResult(file_input.FileInput(image));

    ui.Size imageSize = ui.Size(jpgResult.size.width.toDouble(), jpgResult.size.height.toDouble());
    
    return material.ListView(
        children: [   
                  material.FutureBuilder(
                    future: _validateData(dataFilePath),
                    builder: (material.BuildContext ctx, material.AsyncSnapshot<List> snapshot) =>
                    snapshot.hasData
                    ? 
                    material.Center(
                      child: material.SizedBox(
                        width: _calculateDimensions(material.MediaQuery.of(context).size.width, material.MediaQuery.of(context).size.height, imageSize.width, imageSize.height)[0],
                        height: _calculateDimensions(material.MediaQuery.of(context).size.width, material.MediaQuery.of(context).size.height, imageSize.width, imageSize.height)[1],
                        child: material.Stack(
                          fit: material.StackFit.expand,
                          children: [
                            material.Image.file(io.File(imageFilePath), width: imageSize.width, height: imageSize.height,
                            fit: material.BoxFit.fill),
                              material.IgnorePointer(child: material.CustomPaint(
                                  painter: heatmap_painter.HeatmapPainter(
                                  heat: snapshot.data! as List<List<double>>,
                                  maxVal: 1,
                                  debugGridLines: false,
                                  ),
                                //size: imageSize,
                                ),
                            ),
                          ],
                        )
                      )
                    )
                    :
                    material.Image.file(io.File(imageFilePath), width: imageSize.width, height: imageSize.height, fit: material.BoxFit.scaleDown),
                  )
                ],
              );
  }  
}