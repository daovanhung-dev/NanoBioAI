enum ScheduleCompletionErrorCode {
  notFound,
  waiting,
  locked,
  invalidScheduleTime,
  proofRequired,
  alreadyCompleted,
  notCompleted,
}

class ScheduleCompletionException implements Exception {
  final ScheduleCompletionErrorCode code;
  final String message;

  const ScheduleCompletionException(this.code, this.message);

  @override
  String toString() => message;
}
