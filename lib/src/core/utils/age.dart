/// La edad mínima para crear una cuenta de K'Plan (el API también la exige).
const int adultAge = 18;

/// Si [birthDate] corresponde a una persona de al menos [adultAge] años en [now].
bool isAdult(DateTime birthDate, {DateTime? now}) {
  final today = now ?? DateTime.now();
  var age = today.year - birthDate.year;
  final hadBirthday =
      today.month > birthDate.month ||
      (today.month == birthDate.month && today.day >= birthDate.day);
  if (!hadBirthday) age--;
  return age >= adultAge;
}
