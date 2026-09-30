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

Future<List<List<double>>> _validateData(String dataFilePath, List<coord_converter.DDCoordinates> cornerCoordinates) async
  {
    List<List<double>> heatMapData = [];
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

  @override
  material.Widget build(material.BuildContext context)
  {
    ///Map<double, material.MaterialColor> gradient = 
    ///{0.65: material.Colors.blue, 0.70: material.Colors.purple, 
    ///0.75: material.Colors.pink};

    ///final map.MapController mapController = map.MapController();
    ///
    io.File image = io.File(imageFilePath);
    final jpgResult = image_size_getter.ImageSizeGetter.getSizeResult(file_input.FileInput(image));

    ui.Size imageSize = ui.Size(jpgResult.size.width.toDouble(), jpgResult.size.height.toDouble());
    
    return material.ListView(
        children: [   
                  material.FutureBuilder(
                    future: _validateData(dataFilePath, cornerCoordinates),
                    builder: (material.BuildContext ctx, material.AsyncSnapshot<List> snapshot) =>
                    snapshot.hasData
                    ? 
                    material.Center(
                      child: material.SizedBox(
                        width: material.MediaQuery.of(context).size.width < imageSize.width ? material.MediaQuery.of(context).size.width : imageSize.width,
                        height: material.MediaQuery.of(context).size.height < imageSize.height ? material.MediaQuery.of(context).size.height : imageSize.height,
                        child: material.Stack(
                          fit: material.StackFit.loose,
                          children: [
                            material.Image.file(io.File(imageFilePath), width: imageSize.width, height: imageSize.height,
                            fit: material.BoxFit.scaleDown),
                            material.IgnorePointer(child: material.CustomPaint(
                                painter: heatmap_painter.HeatmapPainter(
                                heat: snapshot.data! as List<List<double>>,
                                maxVal: 1,
                                debugGridLines: false,
                                ),
                              //size: imageSize,
                              ),)
                          ],
                        )
                      )
                    )
                    :
                    const material.Center(child: material.Text('Data failed to load'))
                  )
                ],
              );
  }  
}