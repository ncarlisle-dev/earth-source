import 'specs.dart' as specs;

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
  String id;
  /// The name of the job.
  String name;
  /// The description of the job.
  String description;
  /// Time at which the job was created.
  DateTime createdAt;
  /// Current status of the job.
  JobStatus status;
  /// A collection of status listeners called when the job's status changes.
  final List<void Function(JobStatus)?> _statusListeners 
    = [];

  Job(this.id, this.name, this.description, this.createdAt, this.status);

  /// Sets a callback to be run every time the status of a given job changes
  Future<void> watchStatus(void Function(JobStatus status)? callback) async
  {
    _statusListeners.add(callback);
  }
}

/// An extension of the job class used specifically for model training.
class TrainingJob extends Job 
{
  TrainingJob(
    super.id, 
    super.name, 
    super.description, 
    super.createdAt, 
    super.status
  );
}

/// An extension of the job class used specifically for predictions, with a 
/// corresponding layer and model id if a new model is being used.
class PredictionJob extends Job 
{
  /// Layer over which the current predictions should run.
  specs.LayerSpec layer;
  /// Model id if a newly trained model is being used (defaults to base model
  /// if not.)
  String? modelId;

  PredictionJob(
    super.id, 
    super.name, 
    super.description, 
    super.createdAt, 
    super.status, 
    this.layer
  );

  Future<List<List<double>>>? getResults() async
  {
    return [];
  }
}