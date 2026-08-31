/// Resultado de una operación de datos.
///
/// Evita lanzar excepciones hacia la capa de UI: el repositorio siempre
/// devuelve `Ok` o `Failure` y el ViewModel decide con pattern matching.
///
/// ```dart
/// switch (await repo.login(...)) {
///   case Ok(:final value):   // éxito
///   case Failure(:final message): // error controlado
/// }
/// ```
sealed class Result<T> {
  const Result();

  const factory Result.ok(T value) = Ok<T>;
  const factory Result.failure(String message, [Object? error]) = Failure<T>;

  bool get isOk => this is Ok<T>;
}

final class Ok<T> extends Result<T> {
  const Ok(this.value);
  final T value;
}

final class Failure<T> extends Result<T> {
  const Failure(this.message, [this.error]);
  final String message;
  final Object? error;
}
