import 'dart:io' as io;
import 'dart:ui' as ui;
import 'dart:convert' as convert;
import 'package:flutter/material.dart';
import 'package:csv/csv.dart' as csv_dart;
import 'package:image_size_getter/image_size_getter.dart' as image_size_getter;
import 'package:image_size_getter/file_input.dart' as file_input;
import 'heatmap.dart';

/// Utility function - opens the given data file and reads and validates its 
/// contents.
/// 
/// Returns a 2D list of parsed CSV data if the file contains valid content; an
/// empty list if invalid or if no data file is provided.
Future<List<List<double>>> _validateData(String dataFilePath) async
{
  /// 2D list of data values.
  List<List<double>> heatMapData = [];
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
      for (var i = 0; i < rows.length; i++) {
        List<double> rowList = [];
        for (var j = 0; j < rows[i].length; j++) {
          rowList.add(double.parse(rows[i][j]));
          heatMapData.add(rowList);
        }
      } 
    }
  }
  return heatMapData;
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
  final List<List<double>> cornerCoordinates;

  const Visualizer({
    super.key, 
    required this.imageFilePath, 
    required this.dataFilePath, 
    required this.cornerCoordinates
  });

  /// Calculates the appropriately-scaled dimensions of the image and heatmap as
  /// they should be displayed on the screen.
  List<double> _calculateDimensions(
    double screenWidth, 
    double screenHeight, 
    double imageWidth, 
    double imageHeight
  )
  {
    double containerWidth;
    double containerHeight;

    /// If current screen width and height are greater than or equal to image
    /// dimensions, the image can be displayed with no modifications.
    if (screenWidth >= imageWidth && screenHeight >= imageHeight) {
      containerWidth = imageWidth;
      containerHeight = imageHeight;
    }
    /// Otherwise, scale down the image depending on whether screen height or 
    /// width is the more limiting factor.
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
  Widget build(BuildContext context)
  {
    io.File image = io.File(imageFilePath);
    final jpgResult = 
      image_size_getter.ImageSizeGetter.getSizeResult
      (file_input.FileInput(image));
    ui.Size imageSize = ui.Size(
      jpgResult.size.width.toDouble(), 
      jpgResult.size.height.toDouble()
    );
    
    return ListView(
      children: [
        InteractiveViewer(
        child:   
          FutureBuilder(
            future: _validateData(dataFilePath),
            builder: (
              BuildContext ctx, 
              AsyncSnapshot<List> snapshot
            ) 
            => snapshot.hasData
            ? 
            Center(
              child: SizedBox(
                width: _calculateDimensions(
                  MediaQuery.of(context).size.width, 
                  MediaQuery.of(context).size.height, 
                  imageSize.width, 
                  imageSize.height
                )[0],
                height: _calculateDimensions(
                  MediaQuery.of(context).size.width, 
                  MediaQuery.of(context).size.height, 
                  imageSize.width, 
                  imageSize.height
                )[1],
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.file(
                      io.File(imageFilePath), 
                      width: imageSize.width, 
                      height: imageSize.height,
                      fit: BoxFit.fill
                    ),
                    IgnorePointer(
                      child: CustomPaint(
                        painter: HeatmapPainter(
                          heat: snapshot.data! as List<List<double>>,
                          debugGridLines: false,
                        ),
                      ),
                    ),
                  ],
                )
              )
            )
            :
            Image.file(
              io.File(imageFilePath), 
              width: imageSize.width, 
              height: imageSize.height, 
              fit: BoxFit.scaleDown
            ),
          ),
        ),
      ],
    );
  }  
}
