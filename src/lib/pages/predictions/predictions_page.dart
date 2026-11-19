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
    return Material(child: Column(
      children: [
        Padding(
          padding: EdgeInsetsGeometry.symmetric(vertical: 16.0),
          child: Center(
            child: Text(
              "Predictions", 
              style: TextTheme.of(context).headlineLarge?.copyWith(
                fontWeight: FontWeight.bold
              )
            )
          ), //Icon
        ), 
        Padding(
          padding: EdgeInsetsGeometry.all(16.0),
          child: FloatingActionButton(
            onPressed: () {
              Navigator.push(context, MaterialPageRoute<void>(builder: (context) 
                => PredictionGeneration(project: widget.project)
              ));
            },
            child: const Icon(Icons.add)
          )
        ),
        Center(
          child: Container(
            width: MediaQuery.of(context).size.width, // match the window width
            height: MediaQuery.of(context).size.height - 200,
            margin: const EdgeInsets.symmetric(horizontal: 15.0),
            child:
            widget.project.predictions.isEmpty
            ?
              Center(child: Text("No predictions running yet!"))
            :
        ListView.builder(
          shrinkWrap: true,
          physics: ClampingScrollPhysics(),
          itemCount: widget.project.predictions.length, 
          itemBuilder: (BuildContext context, int index) {
            return GestureDetector(
              onTap: () {
                
                Navigator.push(context, MaterialPageRoute<void>(
                  builder: (context) => PredictionView(
                    project: widget.project, 
                    predictionJob: widget.project.predictions[index],)
                ));
              },
              child: Card(
                    margin: EdgeInsetsGeometry.only(
                      top: 20.0, 
                      left: 20.0, 
                      right: 20.0
                    ),
                    color: Color.fromARGB(255, 232, 237, 242),
                    surfaceTintColor: Color.fromARGB(255, 84, 122, 149),
                    child: Padding(
                      padding: const .all(10.0),
                      child: SizedBox(
                        height: 140, 
                        child: JobFields(
                  name: widget.project.predictions[index].name,
                  description: widget.project.predictions[index].description,
                  timeCreated: 
                    widget.project.predictions[index].createdAt.toString(),
                  timeUpdated: 
                    widget.project.predictions[index].lastUpdated.toString(),
                  status: widget.project.predictions[index].status,
                  layerName: widget.project.layers.firstWhere((layer)
                   => layer.id == widget.project.predictions[index].layerId).name
                  ),
                )
            )));
          }
        ),))
      ],
    ));
  }
}


/// Widget containing the text-based fields for a job.
class JobFields extends StatelessWidget {
  const JobFields({
    super.key,
    required this.name,
    required this.description,
    required this.status,
    required this.timeCreated,
    required this.timeUpdated,
    required this.layerName,
  });

  /// Name of the job.
  final String name;
  /// Description of the job.
  final String description;
  /// Status of the job.
  final api.JobStatus status;
  /// Time at which the job was created.
  final String timeCreated;
  /// Time at which the job was last updated.
  final String timeUpdated;
  /// Layer over which the job is run.
  final String layerName;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: .start,
      children: <Widget>[
        Text(
          name,
          maxLines: 1,
          overflow: .ellipsis,
          style: const TextStyle(fontWeight: .bold, fontSize: 22.0),
        ),
        const Padding(padding: .only(bottom: 2.0)),
        Expanded(
          child: Text(
            description,
            maxLines: 1,
            overflow: .ellipsis,
            style: const TextStyle(
              fontSize: 15.0, 
              color: Color.fromARGB(255, 84, 122, 149)
            ),
          ),
        ),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: "Status: ",
                style: TextStyle(fontSize: 15.0, color: Color.fromARGB(255, 44, 57, 71))
              ),
              WidgetSpan(
                child: Icon(
                  Icons.circle, 
                  size: 16, 
                  color: api.statusColors[status.index]
                ),
              ),
            ],
          ),
        ),
        Text(
          "Created At: $timeCreated",
          maxLines: 1,
          overflow: .ellipsis,
          style: const TextStyle(fontSize: 15.0),
        ),
        Text(
          "Last Updated: $timeUpdated",
          maxLines: 1,
          overflow: .ellipsis,
          style: const TextStyle(fontSize: 15.0),
        ),
        Text(
          "Layer: $layerName",
          maxLines: 1,
          overflow: .ellipsis,
          style: const TextStyle(fontSize: 15.0),
        ),
      ],
    );
  }
}