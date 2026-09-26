import 'package:flutter/foundation.dart';

/// Avisos que el turista puede encender o apagar.
enum NotificationTopic {
  tripReminders('Recordatorios de viajes'),
  bookingChanges('Cambios en mis reservas'),
  savedEvents('Eventos guardados'),
  newsAndBenefits('Beneficios y novedades');

  const NotificationTopic(this.label);
  final String label;
}

/// Preferencias de Configuraciones.
///
/// Vive en memoria mientras no exista backend; la UI ya escucha este
/// [ChangeNotifier]. La ubicación no está aquí: la maneja
/// `LocationRepository`, que es quien enciende el GPS.
class SettingsRepository extends ChangeNotifier {
  final Map<NotificationTopic, bool> _notifications = {
    NotificationTopic.tripReminders: true,
    NotificationTopic.bookingChanges: true,
    NotificationTopic.savedEvents: true,
    NotificationTopic.newsAndBenefits: false,
  };
  bool _personalizedRecommendations = true;
  bool _showBadgesOnProfile = false;

  bool isNotificationOn(NotificationTopic topic) =>
      _notifications[topic] ?? false;

  void setNotification(NotificationTopic topic, bool value) {
    if (_notifications[topic] == value) return;
    _notifications[topic] = value;
    notifyListeners();
  }

  bool get personalizedRecommendations => _personalizedRecommendations;

  set personalizedRecommendations(bool value) {
    if (_personalizedRecommendations == value) return;
    _personalizedRecommendations = value;
    notifyListeners();
  }

  bool get showBadgesOnProfile => _showBadgesOnProfile;

  set showBadgesOnProfile(bool value) {
    if (_showBadgesOnProfile == value) return;
    _showBadgesOnProfile = value;
    notifyListeners();
  }
}
