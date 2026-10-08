/// Muestras de lo que manda el API de F7 y F8 (`docs/servicios.md`,
/// `docs/finanzas.md`), para probar los repositorios con `FakeApi`.
library;

Map<String, dynamic> apiCity({String code = 'leon', String name = 'León'}) => {
  'id': 'city-$code',
  'code': code,
  'name': name,
};

Map<String, dynamic> apiGuideCard({
  String id = 'guide-1',
  String name = 'Pedro Ruiz',
  List<String> services = const ['guia'],
  Map<String, dynamic>? city,
  bool carriesTourists = false,
  double? rating = 4.8,
  int reviewsCount = 12,
}) => {
  'id': id,
  'user_id': 'user-$id',
  'name': name,
  'photo': {'key': 'photos/$id.jpg', 'url': 'https://s3.test/$id.jpg'},
  'presentation': 'Guía de León desde hace años.',
  'services': services,
  'languages': [
    {'code': 'es', 'name': 'Español', 'level': 'nativo'},
    {'code': 'en', 'name': 'Inglés', 'level': 'avanzado'},
  ],
  'city': city,
  'carries_tourists': carriesTourists,
  'rating': rating,
  'reviews_count': reviewsCount,
};

Map<String, dynamic> apiDeparture({
  String id = 'departure-1',
  String circuitId = 'circuit-1',
  String date = '2026-10-20',
  String startTime = '08:30',
  int capacity = 10,
  int booked = 3,
  bool exclusive = false,
  bool cancelled = false,
  int priceAdult = 200,
  int priceChild = 100,
}) => {
  'id': id,
  'circuit': {
    'id': circuitId,
    'title': 'León colonial',
    'kind': 'creativo',
    'city': apiCity(),
  },
  'guide': {'id': 'guide-1', 'name': 'Pedro Ruiz', 'photo': null},
  'date': date,
  'start_time': startTime,
  'capacity': capacity,
  'booked': booked,
  'remaining': capacity - booked,
  'exclusive': exclusive,
  'transport_included': true,
  'note': 'Nos vemos en el parque central.',
  'cancelled': cancelled,
  'price_adult': priceAdult,
  'price_child': priceChild,
};

Map<String, dynamic> apiGuideDetail({String id = 'guide-1'}) => {
  ...apiGuideCard(id: id, city: apiCity()),
  'reviews': [
    {
      'id': 'review-1',
      'rating': 5,
      'comment': 'Muy buen recorrido.',
      'author': 'Ana',
      'created_at': '2026-10-01T15:00:00Z',
    },
  ],
  'departures': [apiDeparture()],
};

Map<String, dynamic> apiBooking({
  String id = 'booking-1',
  String role = 'tourist',
  String status = 'confirmed',
  String date = '2026-10-20',
  String startTime = '08:30',
  int adults = 2,
  int children = 1,
  int amount = 500,
  String paymentStatus = 'pendiente',
  String paymentInstructions = 'Transfiere a la cuenta 123 de K\'Plan.',
  Map<String, dynamic>? circuit = const {
    'id': 'circuit-1',
    'title': 'León colonial',
  },
  Map<String, dynamic>? itinerary,
  String? departureId = 'departure-1',
  bool canCancel = true,
  int unread = 0,
  bool reviewed = false,
}) => {
  'id': id,
  'role': role,
  'status': status,
  'date': date,
  'start_time': startTime,
  'adults': adults,
  'children': children,
  'amount': amount,
  'payment_status': paymentStatus,
  'payment_instructions': paymentInstructions,
  'circuit': circuit,
  'itinerary': itinerary,
  'guide': {'id': 'guide-1', 'name': 'Pedro Ruiz', 'photo': null},
  'tourist': {'id': 'user-1', 'name': 'Ana Gómez'},
  'departure_id': departureId,
  'cancel_deadline': '2026-10-19T08:30:00Z',
  'can_cancel': canCancel,
  'cancelled_at': null,
  'cancel_reason': '',
  'created_at': '2026-10-08T15:00:00Z',
  'unread_messages': unread,
  'reviewed': reviewed,
};

Map<String, dynamic> apiApplication({
  String id = 'application-1',
  String requestId = 'request-1',
  int fee = 900,
  String status = 'sent',
}) => {
  'id': id,
  'request_id': requestId,
  'request': {
    'itinerary': {'id': 'itinerary-1', 'title': 'Mi día en León', 'stops': 3},
    'city': apiCity(),
    'date': '2026-10-25',
    'start_time': '09:00',
    'adults': 2,
    'children': 1,
  },
  'guide': apiGuideCard(carriesTourists: true),
  'fee': fee,
  'message': 'Conozco bien esa ruta.',
  'status': status,
  'created_at': '2026-10-08T16:00:00Z',
};

Map<String, dynamic> apiServiceRequest({
  String id = 'request-1',
  String itineraryId = 'itinerary-1',
  String status = 'open',
  List<Map<String, dynamic>> applications = const [],
  int? maxFee = 1000,
}) => {
  'id': id,
  'itinerary': {'id': itineraryId, 'title': 'Mi León', 'stops': 4},
  'city': apiCity(),
  'date': '2026-10-21',
  'start_time': '09:00',
  'adults': 2,
  'children': 0,
  'max_fee': maxFee,
  'note': 'Guía local',
  'status': status,
  'created_at': '2026-10-08T15:00:00Z',
  'applications': applications,
};

Map<String, dynamic> apiMessage({
  String id = 'message-1',
  bool mine = false,
  String body = 'Hola',
  String sentAt = '2026-10-08T16:00:00Z',
}) => {
  'id': id,
  'sender_id': mine ? 'user-1' : 'guide-1',
  'mine': mine,
  'body': body,
  'sent_at': sentAt,
};
