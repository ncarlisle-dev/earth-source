import 'specs.dart' as specs;
import '../services/network_service.dart';
import 'network.dart' as network;

/// Possible job statuses.
enum JobStatus {
  starting,
  running,
  complete,
  failed,
}

/// A batch job that serves to either run or train a model.
abstract class Job 
{
  /// The id of the job.
  final String id;
  /// The name of the job.
  String name;
  /// The description of the job.
  String description;
  /// Current status of the job.
  JobStatus status;
  /// Time at which the job was created.
  final DateTime createdAt;
  /// Time at which the job was last updated.
  DateTime lastUpdated;

  /// A collection of status listeners called when the job's status changes.
  final List<void Function(JobStatus)> _statusListeners = [];

  Job({
    required this.id,
    required this.createdAt,
    required this.lastUpdated,
    required this.name,
    required this.description,
    required this.status,
  });

  /// Sets a callback to be run every time the status of a given job changes
  Future<void> watchStatus(void Function(JobStatus status) callback) async
  {
    _statusListeners.add(callback);
  }
}

/// An extension of the job class used specifically for model training.
class TrainingJob extends Job 
{
  final String trainingDataSpecId;

  TrainingJob({
    required super.id,
    required super.name,
    required super.description,
    required super.createdAt,
    required super.lastUpdated,
    required super.status,
    required this.trainingDataSpecId,
  });
}

/// An extension of the job class used specifically for predictions, with a 
/// corresponding layer and model id if a new model is being used.
class PredictionJob extends Job 
{
  /// Layer over which the current predictions should run.
  final String layerId;
  /// Model id if a newly trained model is being used (defaults to base model if 
  /// empty).
  final String? modelId;
  final Map<String, String> dataAssignments;

  PredictionJob({
    required super.id,
    required super.name,
    required super.description,
    required super.createdAt,
    required super.lastUpdated,
    required this.layerId,
    required this.modelId,
    this.dataAssignments = const {},
    super.status = .starting,
  });

  /// Obtains the results of generating a prediction and returns them formatted
  /// as a 2D list of doubles. If results are not yet available, returns an 
  /// empty list.
  /// 
  /// Throws a [network.ApiNetworkException] if results file cannot be fetched.
  Future<List<List<double>>>? getResults() async
  {
    final List<List<double>> results = [];
    NetworkService networkService = await NetworkService.getInstance();
    assert(status == JobStatus.complete, "Job isn't complete.");

    final String fileContents;

    try {
      fileContents = await networkService.fetchPredictionJobResults(
        projectId,
        id,
      );
    }
    on network.ApiNetworkException catch (error) {
      throw network.ApiNetworkException(
        "Prediction file could not be fetched due to the following error:"
        " $error",
        error.statusCode
      );
    }

    // Parse file contents into a 2D list of strings, then convert strings to 
    // doubles.
    if (fileContents == "") return [];

    List<List<String>> resultsAsString = [];
    List<String> fileLines = fileContents.split('\n');
    for (var i = 0; i < fileLines.length; i++) {
      resultsAsString.add(fileLines[i].split(','));
    }
    for (var i = 0; i < fileLines.length; i++) {
      List<double> parsedList = [];
      for (var j = 0; j < fileLines[0].length; j++) {
        parsedList.add(double.parse(resultsAsString[i][j]));
      }
      results.add(parsedList);
    }
    
    return results;
  }
}