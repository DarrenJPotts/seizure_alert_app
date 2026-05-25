class ResultDto<T> {
  final T? data;
  final String? error;
  final bool isSuccess;

  ResultDto.success(this.data)
      : error = null,
        isSuccess = true;

  ResultDto.failure(this.error)
      : data = null,
        isSuccess = false;
}