import 'package:flutter/material.dart';
import '../../api/api.dart' as api;
import 'prediction_generation.dart';

/// A stateful widget for the prediction view page, which takes the id for the
/// current project and a prediction job object as required fields.
class PredictionsPage extends StatefulWidget 
{
  const PredictionsPage({super.key, required this.projectId});

  /// The id of the current project.
  final String projectId;

  @override
  State<PredictionsPage> createState() => _PredictionsPageState();
}

/// The mutable state of the prediction view page.
class _PredictionsPageState extends State<PredictionsPage> 
{
  static const List<String> titles = ["Prediction 1", "Prediction 2", "Yet Another Prediction", "Prediction 1000"];
  static const List<String> descriptions = ["Status: Complete\nDate Created: 10/17", "Status: Running\nDate Created: 10/17", "Status: Complete\nDate Created: 10/10", "Status: Complete\nDate Created: 9/03"];
  @override
  Widget build(BuildContext context) {
  
    return ListView(
      children: [
        Padding(
          padding: EdgeInsetsGeometry.symmetric(vertical: 16.0),
          child: Center(child: Text("Predictions", style: TextTheme.of(context).headlineLarge?.copyWith(fontWeight: FontWeight.bold, 
                  color: Colors.indigo))), //Icon
        ), 
        Padding(
          padding: EdgeInsetsGeometry.symmetric(vertical: 16.0),
          child: FloatingActionButton(
            onPressed: () => Navigator.push(
              context, 
              MaterialPageRoute<void>(builder: 
                (context) => PredictionGeneration(projectId: widget.projectId)
              )
            ),
            child: const Icon(Icons.add)
          )
        ),
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.75,
        child:ListView.builder(
            itemCount: 4, 
            itemBuilder: (BuildContext context, int index) {
              return Card(
              elevation: 50,
              shadowColor: Colors.black,
              child: SizedBox(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                  children: [
                    const SizedBox(
                      height: 10,
                    ), //SizedBox
                    Text(
                      titles[index],
                      style: TextStyle(
                        fontSize: 30,
                        color: Colors.indigo,
                        fontWeight: FontWeight.w500,
                      ), //Textstyle
                    ), //Text
                    SizedBox(
                      height: 10,
                    ), //SizedBox
                    Text(
                      descriptions[index],
                      style: TextStyle(
                        fontSize: 15,
                      ), //Textstyle
                    ), //Text
                    SizedBox(
                      height: 10,
                    ), //SizedBox
                    SizedBox(
                      width: 100,

                      child: ElevatedButton(
                        onPressed: () => Navigator.push(context, MaterialPageRoute<void>(builder: 
                (context) => PredictionGeneration(projectId: "$index")
              ),),
                        child: Text("View")
                    ),
                  ) //SizedBox
                ],
              ), //Column
            ), //Padding
          ), //SizedBox
        );}),),
      ],
    );
  }
}