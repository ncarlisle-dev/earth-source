import 'package:flutter/material.dart';
import '../../api/api.dart' as api;

/// A stateful widget for viewing CSV data, which takes the current project and
/// a data spec object as required fields.
class DataView extends StatelessWidget {
  const DataView({
    required this.project,
    required this.dataSpec,
    super.key 
  });

  /// The current project corresponding to the data file.
  final api.Project project;
  /// The data spec currently being displayed.
  final api.DataSpec dataSpec;

  Future<(List<String>, List<String>)> getCSVData() async
  {
    List<String> headers = [];
    List<String> data = [];

    String? fileString = await project.getPxrfData(dataSpec.id!);

    if (fileString == null) return (headers, data);

    List<String> fileLines = fileString.split('\n');

    headers = fileLines[0].split(',');

    for (var i = 1; i < fileLines.length; i++) {
      List<String> fileLine = fileLines[i].split(',');
      for (var j = 0; j < fileLine.length; j++) {
        data.add(fileLine[j]);
      }
    }

    return (headers, data);
  }

  @override
  Widget build(BuildContext context)
  {
    return ListView(
      children: [
        Padding(
          padding: EdgeInsetsGeometry.symmetric(vertical: 16.0),
          child: Center(
            child: Text("pXRF Data",
              //dataSpec.fileName, 
              style: TextTheme.of(context).headlineLarge?.copyWith(
                fontWeight: FontWeight.bold, 
                color: Colors.indigo
              )
            )
          ), //Icon
        ),
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.90,
          child:
          FutureBuilder(
            future: getCSVData(),
            builder: (
              BuildContext ctx, 
              AsyncSnapshot<(List<String>, List<String>)> snapshot
            ) 
            => !(snapshot.hasData)
            ?
            Center(child:Text("No contents to view in this file!"))
            :
            ListView.builder(
              itemCount: snapshot.data!.$2.length, 
              itemBuilder: (BuildContext context, int index) {
                return Center(
                  child: Text(
                  "${snapshot.data!.$1[index % snapshot.data!.$1.length]}: "
                  "${snapshot.data!.$2[index]}"));
              }
            )
          ),
        ),
      ],
    );
  }
}