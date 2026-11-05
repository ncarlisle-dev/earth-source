import 'package:flutter/material.dart';
import '../../api/api.dart' as api;
import 'prediction_generation.dart';
import 'prediction_view.dart';

const possibleJobStatuses = api.JobStatus.values;

/// A stateful widget for the project predictions page, which takes the id for 
/// the current project as a required field.
class PredictionsPage extends StatefulWidget 
{
  const PredictionsPage({super.key, required this.project});

  /// The current project being viewed.
  final api.Project project;

  @override
  State<PredictionsPage> createState() => _PredictionsPageState();
}

/// The mutable state of the project predictions page.
class _PredictionsPageState extends State<PredictionsPage> 
{
  @override
  Widget build(BuildContext context) 
  {
  
    return Material(child: ListView(
      children: [
        Padding(
          padding: EdgeInsetsGeometry.symmetric(vertical: 16.0),
          child: FloatingActionButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Icon(Icons.arrow_circle_left)
          )
        ),
        Padding(
          padding: EdgeInsetsGeometry.symmetric(vertical: 16.0),
          child: Center(
            child: Text(
              "Predictions", 
              style: TextTheme.of(context).headlineLarge?.copyWith(
                fontWeight: FontWeight.bold, 
                color: Colors.indigo
              )
            )
          ), //Icon
        ), 
        // Button for adding predictions which navigates to the prediction
        // generation page.
        Padding(
          padding: EdgeInsetsGeometry.symmetric(vertical: 16.0),
          child: FloatingActionButton(
            onPressed: () => Navigator.push(
              context, 
              MaterialPageRoute<void>(builder: 
                (context) => PredictionGeneration(project: widget.project)
              )
            ),
            child: const Icon(Icons.add)
          )
        ),
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.75,
          child: 
          (widget.project.predictions.isEmpty)
          ?
          Center(child:Text("No predictions at the moment!"))
          :
          ListView.builder(
            itemCount: widget.project.predictions.length, 
            itemBuilder: (BuildContext context, int index) {
              return Card(
                elevation: 50,
                shadowColor: Colors.black,
                child: SizedBox(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        Text(
                          widget.project.predictions[index].name,
                          style: TextStyle(
                            fontSize: 30,
                            color: Colors.indigo,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                        "Status: "
                        "${possibleJobStatuses[widget.project.predictions[index].status.index]}"
                        "\nDescription: ${widget.project.predictions[index].name}\n"
                        "Date Created: ${widget.project.predictions[index].createdAt}",
                          style: TextStyle(
                            fontSize: 15,
                          ),
                        ),
                        // Button which navigates to the prediction view
                        // page for the selected prediction.
                        SizedBox(
                          width: 100,
                          child: ElevatedButton(
                            onPressed: () => Navigator.push(
                                context, 
                                MaterialPageRoute<void>(builder: 
                                  (context) => PredictionView(
                                    project: widget.project, 
                                    predictionJob: 
                                      widget.project.predictions[index]
                                  )
                                )
                              ),
                            child: Text("View")
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              );
            }
          )
        ),
      ],
    ));
  }
}
