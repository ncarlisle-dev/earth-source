import 'specs.dart' as specs;

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
  /// The id of the job.
  String name;
  String description;
  DateTime createdAt;
  JobStatus status;
  List<JobStatus> statusListeners = [];

  Job(this.id, this.name, this.description, this.createdAt, this.status);
}

/// An extension of the job class used specifically for model training.
class TrainingJob extends Job 
{
  TrainingJob(super.id, super.name, super.description, super.createdAt, super.status);
}

/// An extension of the job class used specifically for predictions, with a corresponding layer and model id if a new model is being used.
class PredictionJob extends Job 
{
  specs.LayerSpec layer;
  String? modelId;

  PredictionJob(super.id, super.name, super.description, super.createdAt, super.status, this.layer);
}