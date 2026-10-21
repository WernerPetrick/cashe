import '../errors/failure.dart';

/// Typed outcome of an API call.
sealed class ApiResult<T> {
  const ApiResult();
}

final class ApiSuccess<T> extends ApiResult<T> {
  const ApiSuccess(this.value);

  final T value;
}

final class ApiFailure<T> extends ApiResult<T> {
  const ApiFailure(this.failure);

  final Failure failure;
}

extension ApiResultUnwrap<T> on ApiResult<T> {
  /// The value, or throws the [Failure] for repositories that surface errors as exceptions.
  T unwrap() => switch (this) {
    ApiSuccess(:final value) => value,
    ApiFailure(:final failure) => throw failure,
  };
}
