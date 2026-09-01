/// Formato del código QR físico de cada parada: `kplan:stop:<id>`.
///
/// Único lugar que arma y valida ese texto, para que el generador (demo) y
/// el escáner nunca se desincronicen.
abstract final class StopQrCode {
  static String payloadFor(String stopId) => 'kplan:stop:$stopId';

  static bool matches(String payload, String stopId) =>
      payload.trim() == payloadFor(stopId);
}
