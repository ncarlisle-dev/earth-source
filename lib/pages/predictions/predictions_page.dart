import 'package:flutter/material.dart';
import '../../api/api.dart' as api;
import 'prediction_generation.dart';
import 'prediction_view.dart';

/// A stateful widget for the project predictions page, which takes the id for 
/// the current project as a required field.
class PredictionsPage extends StatefulWidget 
{
  const PredictionsPage({super.key, required this.projectId});

  /// The id of the current project.
  final String projectId;

  @override
  State<PredictionsPage> createState() => _PredictionsPageState();
}

/// The mutable state of the project predictions page.
class _PredictionsPageState extends State<PredictionsPage> 
{
  /// List of job status strings corresponding to the JobStatus enum.
  static const List<String> jobStatusList = [
    "Starting", 
    "Running", 
    "Complete", 
    "Failed"
  ];
  
  /// Fetches a list of all prediction jobs corresponding to the current 
  /// project.
  Future<List<api.PredictionJob>> fetchPredictions() async
  {
    api.ProjectController projectController = 
      await api.ProjectController.getInstance();
    int projectIndex = projectController.userProjects.indexWhere(
      (project) => project.id == widget.projectId);
    return projectController.userProjects[projectIndex].predictions;
  }

  @override
  Widget build(BuildContext context) {
  
    return ListView(
      children: [
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
                (context) => PredictionGeneration(projectId: widget.projectId)
              )
            ),
            child: const Icon(Icons.add)
          )
        ),
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.75,
          child: FutureBuilder(
            future: fetchPredictions(),
            builder: (
              BuildContext ctx, 
              AsyncSnapshot<List<api.PredictionJob>> snapshot
            ) 
            => snapshot.hasData
            ?
            ListView.builder(
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
                          Text(
                            snapshot.data![index].name!,
                            style: TextStyle(
                              fontSize: 30,
                              color: Colors.indigo,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                          "Status: "
                          "${jobStatusList[snapshot.data![index].status.index]}"
                          "\nDescription: ${snapshot.data![index].name!}\n"
                          "Date Created: ${snapshot.data![index].createdAt}",
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
                                      projectId: widget.projectId, 
                                      predictionJob: snapshot.data![index]
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
            :
            Center(child:Text("Predictions could not be loaded."))
          ),
        ),
      ],
    );
  }
}