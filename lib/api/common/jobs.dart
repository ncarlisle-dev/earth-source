enum JobStatus {
  starting,
  running,
  complete,
  failed,
}

abstract class Job {}

class TrainingJob extends Job {}

class PredictionJob extends Job {}