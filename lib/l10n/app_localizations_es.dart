// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get assistantAiTag => 'IA';

  @override
  String get assistantAllGood => 'Así queda bien. ¿Lo guardamos?';

  @override
  String assistantAppliedAdd(String stop) {
    return 'Agregaste $stop';
  }

  @override
  String assistantAppliedLunch(String stop) {
    return 'Almuerzas en $stop';
  }

  @override
  String assistantAppliedRemove(String stop) {
    return 'Quitaste $stop';
  }

  @override
  String assistantAppliedReorder(String saved) {
    return 'Cambiaste el orden: ahorras $saved';
  }

  @override
  String assistantAppliedStartLater(String time) {
    return 'Sales a las $time';
  }

  @override
  String get assistantAppliedVehicle => 'Te mueves en vehículo';

  @override
  String get assistantApply => 'Aplicar';

  @override
  String get assistantAskCity => '¿A qué ciudad vas?';

  @override
  String get assistantAskInterests =>
      '¿Qué te interesa más? Puedes elegir varias cosas.';

  @override
  String get assistantAskPace => '¿Cómo quieres tu día?';

  @override
  String get assistantAskStartTime => '¿A qué hora quieres empezar?';

  @override
  String assistantDefaultTitle(String city) {
    return 'Mi día en $city';
  }

  @override
  String get assistantDismiss => 'No, gracias';

  @override
  String assistantIntroCircuit(String title, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count paradas',
      one: '1 parada',
    );
    return '¡Hola! Soy el asistente de K\'Plan. Voy a organizar \"$title\" ($_temp0) contando los traslados y los horarios de cada lugar.';
  }

  @override
  String get assistantIntroScratch =>
      '¡Hola! Soy el asistente de K\'Plan. Te armo un día con horarios reales, contando los traslados entre cada lugar.';

  @override
  String get assistantNoPreference => 'Me da igual';

  @override
  String assistantProposalCircuit(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count paradas',
      one: '1 parada',
    );
    return 'Listo. Calculé cada traslado y la hora a la que llegas a tus $_temp0.';
  }

  @override
  String assistantProposalEmpty(String city) {
    return 'No encontré paradas en $city que quepan en tu día. Prueba con otro ritmo o una hora más temprano.';
  }

  @override
  String assistantProposalScratch(String city, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count paradas',
      one: '1 parada',
    );
    return 'Listo. Te armé un día en $city con $_temp0, en el orden que menos traslado pide.';
  }

  @override
  String assistantProposalTitle(String mode, String pace) {
    return 'Tu día · $mode · ritmo $pace';
  }

  @override
  String get assistantSave => 'Guardar itinerario';

  @override
  String get assistantSaved => '¡Listo! Guardamos tu itinerario';

  @override
  String assistantSuggestionsIntro(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Tengo $count sugerencias para mejorarlo:',
      one: 'Tengo 1 sugerencia para mejorarlo:',
    );
    return '$_temp0';
  }

  @override
  String get assistantThinking => 'Calculando traslados y horarios…';

  @override
  String get assistantTitle => 'Asistente K\'Plan';

  @override
  String get bookingAdults => 'Adultos';

  @override
  String get bookingBadges => 'Insignias';

  @override
  String get bookingBadgesSoon => 'Insignias: próximamente';

  @override
  String bookingBudgetLine(String summary) {
    return 'Presupuesto: $summary';
  }

  @override
  String get bookingChatEmpty =>
      'Todavía no hay mensajes. Escribe para coordinar el punto de encuentro.';

  @override
  String get bookingChatHint => 'Escribe un mensaje';

  @override
  String get bookingChatReadOnly =>
      'La reserva se canceló: el chat quedó de solo lectura.';

  @override
  String get bookingChatSend => 'Enviar';

  @override
  String get bookingChatTitle => 'Chat';

  @override
  String get bookingChildren => 'Niños';

  @override
  String bookingChildrenCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count niños',
      one: '1 niño',
    );
    return '$_temp0';
  }

  @override
  String get bookingCircuitNotFound => 'No encontramos este circuito';

  @override
  String get bookingConfirmed => '¡Listo! Tu circuito quedó agendado';

  @override
  String get bookingConfirmedWithProposal =>
      '¡Listo! Tu circuito quedó agendado y tu propuesta ya está publicada para los guías';

  @override
  String get bookingDaySchedule => 'Horario del día';

  @override
  String get bookingDetailCancel => 'Cancelar reserva';

  @override
  String bookingDetailCancelClosed(String day, String time) {
    return 'El plazo para cancelar venció el $day a las $time.';
  }

  @override
  String get bookingDetailCancelled => 'Reserva cancelada';

  @override
  String get bookingDetailCancelMessage =>
      'Si ya pagaste, el equipo de K\'Plan te devolverá el dinero.';

  @override
  String get bookingDetailCancelReasonHint => 'Cuéntale al turista por qué';

  @override
  String get bookingDetailCancelReasonRequired => 'Escribe el motivo';

  @override
  String get bookingDetailCancelTitle => '¿Cancelar la reserva?';

  @override
  String bookingDetailCancelUntil(String day, String time) {
    return 'Puedes cancelar gratis hasta el $day a las $time.';
  }

  @override
  String get bookingDetailChatWithGuide => 'Escribirle al guía';

  @override
  String get bookingDetailChatWithTourist => 'Escribirle al turista';

  @override
  String get bookingDetailConfirmedTitle => '¡Reserva confirmada!';

  @override
  String get bookingDetailHowToPay => 'Cómo pagar';

  @override
  String get bookingDetailKeep => 'Mantenerla';

  @override
  String get bookingDetailOpen => 'Ver mi reserva';

  @override
  String get bookingDetailPaymentManual =>
      'El equipo de K\'Plan confirma tu pago a mano y te avisa cuando quede listo.';

  @override
  String get bookingDetailPaymentTitle => 'Pago';

  @override
  String bookingDetailStatus(String status) {
    return 'Estado: $status';
  }

  @override
  String get bookingDetailsTitle => 'Detalles de la reserva';

  @override
  String get bookingDetailTitle => 'Tu reserva';

  @override
  String get bookingDetailWasCancelled => 'Esta reserva se canceló.';

  @override
  String bookingDetailWasCancelledBecause(String reason) {
    return 'Esta reserva se canceló: $reason';
  }

  @override
  String bookingDurationEnds(String duration, String time) {
    return '$duration · termina aprox. a las $time';
  }

  @override
  String get bookingEstimatedDuration => 'Duración estimada';

  @override
  String get bookingGoBack => 'Volver';

  @override
  String get bookingGroup => 'Grupo';

  @override
  String get bookingGuideOrTranslator => 'Guía o traductor';

  @override
  String get bookingGuideRowAdd => 'Agregar';

  @override
  String bookingGuideSummary(String need, int hours) {
    return '$need · ${hours}h';
  }

  @override
  String get bookingIncludes => 'Incluye';

  @override
  String get bookingItineraryNotSaved =>
      'Tu circuito todavía no se guardó en tu cuenta. Revisa tu conexión e intenta de nuevo.';

  @override
  String get bookingMeetingPoint => 'Punto de encuentro';

  @override
  String get bookingNeedBilingualSubtitle =>
      'Te explica todo el recorrido en tu idioma.';

  @override
  String get bookingNeedBilingualTitle => 'Guía que habla tu idioma';

  @override
  String get bookingNeedGuideTranslatorSubtitle =>
      'Un guía local y alguien que te traduce en el momento.';

  @override
  String get bookingNeedGuideTranslatorTitle => 'Guía local + traductor';

  @override
  String get bookingNeedLocalGuideSubtitle => 'Te da el recorrido en español.';

  @override
  String get bookingNeedTranslatorOnlySubtitle =>
      'Recorres por tu cuenta con alguien que te traduce.';

  @override
  String get bookingNeedTranslatorOnlyTitle => 'Solo traductor';

  @override
  String get bookingNoGuideOrTranslator => 'Sin guía ni traductor';

  @override
  String get bookingOwnCircuitNote =>
      'Lo armaste tú, así que no tiene precio por persona: sólo pagas el guía o traductor que contrates.';

  @override
  String get bookingProposalBudget => 'Presupuesto que ofreces';

  @override
  String get bookingProposalBudgetHint =>
      'Cada guía lo acepta o propone su precio al postularse.';

  @override
  String get bookingProposalDuration => 'Duración del servicio';

  @override
  String get bookingProposalFewerHours => 'Menos horas';

  @override
  String get bookingProposalIntro =>
      'Los guías verán tu propuesta y se postularán. Tú revisas sus perfiles y eliges a quién contratar.';

  @override
  String bookingProposalItineraryLasts(String duration) {
    return 'Tu itinerario dura $duration.';
  }

  @override
  String get bookingProposalLodgingHint =>
      'Más de un día de recorrido: si le das alojamiento, el precio baja.';

  @override
  String get bookingProposalLodgingTitle => '¿Le darás alojamiento al guía?';

  @override
  String bookingProposalMinHoursGuide(int hours) {
    return 'Mínimo $hours horas con guía.';
  }

  @override
  String bookingProposalMinHoursTranslator(int hours) {
    return 'Mínimo $hours horas sólo con traductor.';
  }

  @override
  String get bookingProposalMoreHours => 'Más horas';

  @override
  String get bookingProposalNote =>
      'Al agendar publicamos tu propuesta: los guías se postulan y tú eliges a quién contratar.';

  @override
  String get bookingProposalTitle => 'Propuesta para guía o traductor';

  @override
  String get bookingProposalTransport => 'Transporte';

  @override
  String get bookingProposalVehicleWarning =>
      'Este recorrido se hace en vehículo: a pie hay tramos muy largos y el día no alcanza.';

  @override
  String get bookingProposalWhatYouNeed => '¿Qué necesitas?';

  @override
  String get bookingProposalYourLanguage => 'Tu idioma';

  @override
  String get bookingRecommendations => 'Recomendaciones';

  @override
  String get bookingRemove => 'Quitar';

  @override
  String get bookingRequestPublished =>
      'Publicamos tu convocatoria: los guías se postularán con su precio y tú eliges.';

  @override
  String get bookingReviewCommentHint =>
      'Cuenta cómo fue el recorrido: puntualidad, trato, lo que aprendiste';

  @override
  String get bookingReviewDone => 'Ya dejaste tu reseña. ¡Gracias!';

  @override
  String bookingReviewQuestion(String name) {
    return '¿Cómo te fue con $name?';
  }

  @override
  String get bookingReviewSent => 'Reseña publicada. ¡Gracias!';

  @override
  String get bookingReviewVisibility =>
      'Tu reseña se publica al instante en el perfil del guía.';

  @override
  String bookingScheduleSummary(String start, String mode, String end) {
    return 'Saliendo a las $start · $mode · termina aprox. a las $end';
  }

  @override
  String get bookingServiceFee => 'Servicio (20%)';

  @override
  String get bookingStartTime => 'Hora inicial';

  @override
  String get bookingSubtotal => 'Subtotal';

  @override
  String get bookingTitle => 'Agendar';

  @override
  String get bookingTourInfoTitle => 'Información del recorrido';

  @override
  String get bookingTourNotes => 'Notas del recorrido';

  @override
  String get bookingTransportGuide => 'Que lo ponga el guía';

  @override
  String get bookingTransportOnFoot => 'A pie';

  @override
  String get bookingTransportTourist => 'Yo pongo el transporte';

  @override
  String get categoryAdventure => 'Aventura';

  @override
  String get categoryCity => 'Ciudad';

  @override
  String get categoryCulture => 'Cultura';

  @override
  String get categoryFair => 'Feria';

  @override
  String get categoryFood => 'Gastronomía';

  @override
  String get categoryHistory => 'Historia';

  @override
  String get categoryNature => 'Naturaleza';

  @override
  String get categoryTradition => 'Tradición';

  @override
  String get circuitDetailAllReviewsSoon => 'Todas las reseñas: próximamente';

  @override
  String circuitDetailBadgesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count insignias',
      one: '1 insignia',
    );
    return '$_temp0';
  }

  @override
  String get circuitDetailBook => 'Agendar circuito';

  @override
  String circuitDetailCommentsTitle(int count) {
    return 'Comentarios ($count)';
  }

  @override
  String get circuitDetailDownloadSoon =>
      'Descargar sin conexión: próximamente';

  @override
  String get circuitDetailDownloadTooltip => 'Descargar sin conexión';

  @override
  String get circuitDetailLeavingAt => 'Si sales a las…';

  @override
  String get circuitDetailOrderSaved =>
      'Orden guardado: el itinerario se recalculó';

  @override
  String circuitDetailPricePerAdult(String price) {
    return '$price p. adulta';
  }

  @override
  String get circuitDetailReorder => 'Ordenar';

  @override
  String get circuitDetailSeeAll => 'Ver todos';

  @override
  String get circuitDetailSeeTimes => 'Ver horarios disponibles';

  @override
  String circuitDetailSkipWhy(String stop) {
    return '¿Por qué saltas $stop?';
  }

  @override
  String get circuitDetailStartTrip => 'Comenzar viaje';

  @override
  String circuitDetailStopsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count paradas',
      one: '1 parada',
    );
    return '$_temp0';
  }

  @override
  String circuitDetailStopsTitle(int count) {
    return 'Paradas del recorrido ($count)';
  }

  @override
  String get circuitDetailTodayRoute => 'Tu recorrido de hoy';

  @override
  String get circuitDetailTripEnded => 'Viaje finalizado';

  @override
  String circuitDetailTripStarted(String stop) {
    return '¡Viaje iniciado! Dirígete a $stop';
  }

  @override
  String get commonAccept => 'Aceptar';

  @override
  String get commonBack => 'Regresar';

  @override
  String get commonBackToHome => 'Volver al inicio';

  @override
  String get commonBirthDate => 'Fecha de nacimiento';

  @override
  String get commonCancel => 'Cancelar';

  @override
  String get commonChangePassword => 'Cambiar contraseña';

  @override
  String get commonChooseCountry => 'Elige tu país';

  @override
  String get commonClose => 'Cerrar';

  @override
  String get commonContinue => 'Continuar';

  @override
  String get commonCoupons => 'Cupones';

  @override
  String get commonCreateAccount => 'Crear cuenta';

  @override
  String get commonCreativeCircuits => 'Circuitos creativos';

  @override
  String get commonDate => 'Fecha';

  @override
  String get commonDone => 'Listo';

  @override
  String get commonEmail => 'Correo electrónico';

  @override
  String get commonFullName => 'Nombre completo';

  @override
  String get commonGuide => 'Guía';

  @override
  String get commonHome => 'Inicio';

  @override
  String get commonLocalGuide => 'Guía local';

  @override
  String get commonLogout => 'Cerrar sesión';

  @override
  String get commonMyCircuits => 'Mis circuitos';

  @override
  String get commonMyMedals => 'Mis medallas';

  @override
  String get commonMyTrips => 'Mis viajes';

  @override
  String get commonNationality => 'Nacionalidad';

  @override
  String get commonNewPassword => 'Contraseña nueva';

  @override
  String get commonNewPasswordHelper =>
      'Usa al menos 8 caracteres, una mayúscula y un número.';

  @override
  String get commonNext => 'Siguiente';

  @override
  String get commonNotifications => 'Notificaciones';

  @override
  String get commonPassword => 'Contraseña';

  @override
  String get commonPasswordsDontMatch => 'Las contraseñas no coinciden';

  @override
  String get commonRepeatPassword => 'Repite la contraseña';

  @override
  String get commonResendCode => 'Reenviar código';

  @override
  String get commonRetry => 'Reintentar';

  @override
  String get commonSave => 'Guardar';

  @override
  String get commonSaved => 'Guardados';

  @override
  String get commonSeeOnMap => 'Ver en el mapa';

  @override
  String get commonSettings => 'Configuraciones';

  @override
  String get commonSomethingWentWrong => 'Algo salió mal, intenta de nuevo';

  @override
  String get commonTotal => 'Total';

  @override
  String get commonTourist => 'Turista';

  @override
  String get commonTranslator => 'Traductor';

  @override
  String get commonViewProfile => 'Ver perfil';

  @override
  String couponsBalanceLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'insignias disponibles para canjear',
    );
    return '$_temp0';
  }

  @override
  String get couponsRedeemButton => 'CANJEAR';

  @override
  String get couponsRedeemConfirm => 'Canjear';

  @override
  String get couponsRedeemed => '¡Cupón canjeado! Muéstralo al reservar.';

  @override
  String get couponsRedeemedLabel => 'Canjeado';

  @override
  String get couponsRedeemFailed => 'No se pudo canjear el cupón';

  @override
  String couponsRedeemMessage(int cost) {
    String _temp0 = intl.Intl.pluralLogic(
      cost,
      locale: localeName,
      other: 'Se descontarán $cost insignias de tu saldo.',
      one: 'Se descontará 1 insignia de tu saldo.',
    );
    return '$_temp0';
  }

  @override
  String couponsRedeemTitle(String title) {
    return '¿Canjear \"$title\"?';
  }

  @override
  String get eventDetailFreeEntry => 'Entrada libre';

  @override
  String get forgotPasswordCodeMissing =>
      'Escribe el código de 6 dígitos que te llegó al correo.';

  @override
  String get forgotPasswordCodeResent =>
      'Si pasó un minuto desde el último, te enviamos otro código.';

  @override
  String forgotPasswordCodeSentTo(String email) {
    return 'Si $email tiene una cuenta, le enviamos un código de 6 dígitos. Vence en 15 minutos.';
  }

  @override
  String get forgotPasswordCodeSubtitle =>
      'Ingresa tu correo y te enviaremos un código de 6 dígitos.';

  @override
  String get forgotPasswordCodeTitle => 'Escribe el código';

  @override
  String get forgotPasswordDemoNote =>
      'Demostración: todavía no se envían correos; sirve cualquier código de 6 dígitos.';

  @override
  String get forgotPasswordSendCode => 'Enviar código';

  @override
  String get forgotPasswordTitle => '¿Olvidaste tu contraseña?';

  @override
  String get forgotPasswordUpdated =>
      'Contraseña actualizada. Entra con la nueva.';

  @override
  String get forgotPasswordUseAnotherEmail => 'Usar otro correo';

  @override
  String formatAdults(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'adultos x $count',
      one: 'adulto x $count',
    );
    return '$_temp0';
  }

  @override
  String get formatAm => 'a.m.';

  @override
  String formatChildren(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'niños x $count',
      one: 'niño x $count',
    );
    return '$_temp0';
  }

  @override
  String formatCompactDate(String weekday, String dayAndMonth) {
    return '$weekday $dayAndMonth';
  }

  @override
  String formatDayAndMonth(int day, String month) {
    return '$day $month';
  }

  @override
  String formatDaysAgo(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'hace $days días',
      one: 'hace 1 día',
    );
    return '$_temp0';
  }

  @override
  String formatHoursAgo(int hours) {
    return 'hace $hours h';
  }

  @override
  String get formatLessThanOneMinute => 'menos de 1 min';

  @override
  String formatMinutesAgo(int minutes) {
    return 'hace $minutes min';
  }

  @override
  String get formatNoPeople => 'Sin personas';

  @override
  String get formatNow => 'ahora';

  @override
  String formatPeople(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count personas',
      one: '$count persona',
    );
    return '$_temp0';
  }

  @override
  String get formatPm => 'p.m.';

  @override
  String formatShortDate(int day, String month, int year) {
    return '$day $month $year';
  }

  @override
  String get formatToday => 'Hoy';

  @override
  String get formatTomorrow => 'Mañana';

  @override
  String formatWeekdayDate(String weekday, String dayAndMonth) {
    return '$weekday $dayAndMonth';
  }

  @override
  String get formatYesterday => 'Ayer';

  @override
  String groupSlotsAdultsLine(int count, String price) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count adultos',
      one: '1 adulto',
    );
    return '$_temp0 × $price';
  }

  @override
  String get groupSlotsCertifiedGuide => 'Guía certificado';

  @override
  String groupSlotsChildrenLine(int count, String price) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count niños',
      one: '1 niño',
    );
    return '$_temp0 × $price';
  }

  @override
  String get groupSlotsConfirm => 'Confirmar';

  @override
  String groupSlotsDuration(String duration) {
    return 'Duración: $duration';
  }

  @override
  String get groupSlotsEmpty =>
      'Todavía no hay horarios publicados para este circuito. Vuelve a revisar pronto.';

  @override
  String groupSlotsEndsAround(String time) {
    return 'Termina aprox. $time';
  }

  @override
  String groupSlotsEnrolled(String date, String time) {
    return '¡Listo! Tu grupo quedó inscrito el $date, $time';
  }

  @override
  String groupSlotsEnrolledWithGroup(String people) {
    return 'Inscrito con tu grupo · $people';
  }

  @override
  String groupSlotsEnrollMe(String people) {
    return 'Inscribirme · $people';
  }

  @override
  String get groupSlotsEnrollTitle => 'Inscribirte en este horario';

  @override
  String get groupSlotsFull => 'Lleno';

  @override
  String groupSlotsGroupDoesNotFit(String people) {
    return 'Tu grupo no cabe ($people)';
  }

  @override
  String groupSlotsGroupNote(int capacity) {
    return 'Es un grupo de hasta $capacity personas: compartirás el recorrido con gente que no conoces.';
  }

  @override
  String groupSlotsJoined(int joined, int capacity) {
    return '$joined de $capacity personas inscritas';
  }

  @override
  String groupSlotsMeetingPoint(String place) {
    return 'Punto de encuentro: $place';
  }

  @override
  String get groupSlotsNoSpots => 'Sin cupos';

  @override
  String get groupSlotsNoSpotsLeft =>
      'Ya no quedan cupos suficientes en ese horario';

  @override
  String get groupSlotsNoTransport => 'Sin transporte';

  @override
  String get groupSlotsPeople => 'Personas';

  @override
  String groupSlotsPrices(String adult, String child) {
    return '$adult por adulto · $child por niño';
  }

  @override
  String get groupSlotsPublishedHint =>
      'Cada guía fija la hora, el cupo y si pone transporte.';

  @override
  String get groupSlotsPublishedTitle => 'Horarios publicados por guías';

  @override
  String groupSlotsSessionWhen(String date, String time) {
    return '$date · $time';
  }

  @override
  String groupSlotsSessionWhenWithGuide(
    String date,
    String time,
    String guide,
  ) {
    return '$date · $time · con $guide';
  }

  @override
  String groupSlotsSpotsLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Quedan $count cupos',
      one: 'Quedan 1 cupo',
    );
    return '$_temp0';
  }

  @override
  String get groupSlotsTitle => 'Horarios disponibles';

  @override
  String get groupSlotsTransportIncluded => 'Incluye transporte';

  @override
  String get groupSlotsYourGroup => 'Tu grupo';

  @override
  String get guideAccessAppBarSemantics => 'K’Plan, guías';

  @override
  String get guideAccessAppBarTitle => 'K’Plan  /  Guías';

  @override
  String get guideAccessAttachFile => 'Adjuntar archivo';

  @override
  String get guideAccessBackToDocuments => 'Volver y revisar documentos';

  @override
  String get guideAccessCityError => 'Elige la ciudad donde trabajas';

  @override
  String get guideAccessCityHint => 'Elige una ciudad';

  @override
  String get guideAccessCityLabel => 'Ciudad';

  @override
  String get guideAccessCodeRejected =>
      'El código no es válido o venció. Revísalo o pide uno nuevo.';

  @override
  String guideAccessCodeResent(String email) {
    return 'Enviamos un nuevo código a $email. Usa el más reciente.';
  }

  @override
  String guideAccessCodeSent(String email) {
    return 'Enviamos un código de 6 dígitos a $email.';
  }

  @override
  String get guideAccessCodeTitle => 'Ingresa el código de verificación';

  @override
  String get guideAccessConfirmPasswordHint => 'Repite tu contraseña';

  @override
  String get guideAccessConfirmPasswordLabel => 'Confirma tu contraseña';

  @override
  String get guideAccessConsentError =>
      'Autoriza la revisión de tus documentos para enviar la solicitud.';

  @override
  String get guideAccessConsentLabel =>
      'Autorizo al equipo de K’Plan a revisar mi información y documentación para evaluar esta solicitud.';

  @override
  String get guideAccessCountryCodeTooltip => 'Código de país';

  @override
  String get guideAccessCountryCostaRica => 'Costa Rica';

  @override
  String get guideAccessCountryElSalvador => 'El Salvador';

  @override
  String get guideAccessCountryGuatemala => 'Guatemala';

  @override
  String get guideAccessCountryHonduras => 'Honduras';

  @override
  String get guideAccessCountryMexico => 'México';

  @override
  String get guideAccessCountryNicaragua => 'Nicaragua';

  @override
  String get guideAccessCountryPanama => 'Panamá';

  @override
  String get guideAccessCountrySpain => 'España';

  @override
  String get guideAccessCountryUnitedStatesOrCanada =>
      'Estados Unidos o Canadá';

  @override
  String get guideAccessCoverageError => 'Elige dónde trabajas';

  @override
  String get guideAccessCoverageLabel => 'Dónde trabajas';

  @override
  String get guideAccessCoverageLocalSubtitle =>
      'Por ejemplo, un guía local certificado en ella.';

  @override
  String get guideAccessCoverageLocalTitle => 'En una ciudad';

  @override
  String get guideAccessCoverageNationalSubtitle =>
      'Por ejemplo, un guía nacional del INTUR.';

  @override
  String get guideAccessCoverageNationalTitle => 'En todo el país';

  @override
  String guideAccessCoverageSummaryLocal(String city) {
    return 'Solo en $city';
  }

  @override
  String get guideAccessCoverageSummaryNational =>
      'Todo el territorio nicaragüense';

  @override
  String get guideAccessCreateAccountAndSend => 'Crear cuenta y enviar';

  @override
  String get guideAccessDocumentAccepted => 'Aceptado';

  @override
  String get guideAccessDocumentAlreadyExpired =>
      'El documento ya venció: sube uno vigente';

  @override
  String get guideAccessDocumentAttached => 'Adjunto · Pendiente de revisión';

  @override
  String get guideAccessDocumentAttachFile => 'Adjunta el archivo';

  @override
  String get guideAccessDocumentCouldNotAccept => 'no pudimos aceptarlo';

  @override
  String get guideAccessDocumentExpiresBeforeIssued =>
      'El vencimiento tiene que ser posterior a la emisión';

  @override
  String get guideAccessDocumentExpiresOn => 'Vence el';

  @override
  String get guideAccessDocumentExpiresOnOptional => 'Vence el · Opcional';

  @override
  String get guideAccessDocumentExpiresRequired =>
      'Elige la fecha de vencimiento';

  @override
  String get guideAccessDocumentIssuedFuture =>
      'La fecha de emisión no puede ser futura';

  @override
  String get guideAccessDocumentIssuedOn => 'Emitido el';

  @override
  String get guideAccessDocumentIssuedRequired => 'Elige la fecha de emisión';

  @override
  String get guideAccessDocumentKept => 'Pasa tal cual a la solicitud nueva';

  @override
  String get guideAccessDocumentKeptAccepted =>
      'Aceptado: pasa tal cual a la solicitud nueva';

  @override
  String get guideAccessDocumentNoExpiry => 'No vence';

  @override
  String get guideAccessDocumentNumber => 'Número del documento';

  @override
  String get guideAccessDocumentNumberHint => 'Como aparece en el documento';

  @override
  String get guideAccessDocumentNumberRequired =>
      'Escribe el número del documento';

  @override
  String get guideAccessDocumentPending => 'Por revisar';

  @override
  String guideAccessDocumentRejected(String reason) {
    return 'Rechazado: $reason';
  }

  @override
  String guideAccessDocumentRejectedByUs(String reason) {
    return 'Lo rechazamos: $reason';
  }

  @override
  String get guideAccessDocumentsCorrectSubtitle =>
      'Sube otra vez lo que rechazamos. Lo que aceptamos pasa tal cual.';

  @override
  String get guideAccessDocumentsCorrectTitle => 'Corrige tus documentos';

  @override
  String get guideAccessDocumentsSubtitle =>
      'Adjunta una foto legible o un PDF de cada uno, con sus fechas. Solo el equipo de revisión los verá.';

  @override
  String get guideAccessDocumentsTitle => 'Tus documentos';

  @override
  String get guideAccessDocumentUploadAgain => 'súbelo de nuevo';

  @override
  String get guideAccessDocumentValid => 'En vigor';

  @override
  String get guideAccessEmailHelper =>
      'Usa uno que no tenga ya una cuenta de K’Plan.';

  @override
  String get guideAccessEmailHint => 'tu@correo.com';

  @override
  String get guideAccessEmailLabel => 'Correo';

  @override
  String get guideAccessExperienceHint =>
      'Ej.: 3 años en recorridos de historia colonial';

  @override
  String get guideAccessExperienceLabel => 'Preséntate a los turistas';

  @override
  String get guideAccessExperienceRequired => 'Cuéntanos tu experiencia';

  @override
  String get guideAccessExperienceSubtitle =>
      'Tu certificación define hasta dónde puedes acompañar a los viajeros.';

  @override
  String get guideAccessFileFormats => 'PDF, JPG o PNG';

  @override
  String get guideAccessFilePickerFailed =>
      'No pudimos abrir tus archivos. Intenta de nuevo.';

  @override
  String get guideAccessFileSizeProblem =>
      'El archivo pesa más de 10 MB. Elige uno más liviano.';

  @override
  String get guideAccessFileTypeProblem => 'Adjunta un archivo PDF, JPG o PNG.';

  @override
  String get guideAccessIdentitySubtitle =>
      'Usa tus datos tal como aparecen en tu cédula. Con este correo se crea tu cuenta de guía o traductor.';

  @override
  String get guideAccessIdentityTitle => 'Cuéntanos quién eres';

  @override
  String get guideAccessLanguagesError => 'Elige al menos un idioma';

  @override
  String get guideAccessLanguagesLabel => 'Idiomas';

  @override
  String get guideAccessNameHint => 'Nombre y apellidos';

  @override
  String get guideAccessNameRequired => 'Ingresa tu nombre completo';

  @override
  String get guideAccessPasswordHint => 'Ingresa tu contraseña';

  @override
  String get guideAccessPasswordSubtitle =>
      'Tu correo está verificado. Crea una contraseña: al enviar, subimos tus documentos y tu solicitud queda en revisión.';

  @override
  String get guideAccessPasswordTitle => 'Protege tu cuenta';

  @override
  String get guideAccessPhoneLabel => 'Teléfono de contacto';

  @override
  String get guideAccessProfileMissing =>
      'Elige tu fecha de nacimiento y tu nacionalidad.';

  @override
  String guideAccessProgressLabel(int step, int total) {
    return 'POSTULACIÓN  ·  PASO $step DE $total';
  }

  @override
  String guideAccessProgressSemantics(int step, int total) {
    return 'Postulación, paso $step de $total';
  }

  @override
  String guideAccessRemoveFile(String name) {
    return 'Quitar $name';
  }

  @override
  String get guideAccessReviewAccount => 'Tu cuenta';

  @override
  String get guideAccessReviewCorrectionTitle => 'Revisa tu corrección';

  @override
  String get guideAccessReviewDocuments =>
      'Documentos que envías · Por verificar';

  @override
  String get guideAccessReviewServices => 'Lo que ofreces';

  @override
  String get guideAccessReviewSubtitle =>
      'Confirma tu información antes de enviarla.';

  @override
  String get guideAccessReviewTitle => 'Revisa tu postulación';

  @override
  String get guideAccessReviewVehicle => 'Lleva turistas en su vehículo';

  @override
  String get guideAccessSendCorrection => 'Enviar corrección';

  @override
  String get guideAccessSendRequest => 'Enviar solicitud';

  @override
  String get guideAccessServiceGuide => 'Guía de turismo';

  @override
  String get guideAccessServicesCorrectingSubtitle =>
      'Revisa tus datos: puedes cambiarlos antes de volver a enviar.';

  @override
  String get guideAccessServicesError => 'Elige al menos uno';

  @override
  String get guideAccessServicesLabel => 'Ofreces';

  @override
  String get guideAccessServicesTitle => 'Qué ofreces y dónde';

  @override
  String get guideAccessStartApply => 'Postularme';

  @override
  String get guideAccessStartChecklistCredential =>
      'Tu licencia del INTUR si eres guía, o tu certificado de idiomas si eres traductor';

  @override
  String get guideAccessStartChecklistEmail =>
      'Un correo que no tenga ya una cuenta de K’Plan';

  @override
  String get guideAccessStartChecklistId => 'Tu cédula y tu récord de policía';

  @override
  String get guideAccessStartChecklistLabel => 'Ten a mano';

  @override
  String get guideAccessStartChecklistVehicle =>
      'Tu licencia de conducir y el seguro si llevas turistas en tu vehículo';

  @override
  String get guideAccessStartContinueAsTourist => 'Continuar como turista';

  @override
  String get guideAccessStartNotice =>
      'El equipo de K’Plan revisará tu información antes de habilitar tu acceso.';

  @override
  String get guideAccessStartSignOutToApply => 'Salir para postularme';

  @override
  String get guideAccessStartSubtitle =>
      'Postúlate para ofrecer tus servicios como guía de turismo o como traductor.';

  @override
  String get guideAccessStartTitle => 'Comparte tu territorio';

  @override
  String get guideAccessStartTouristNotice =>
      'Tu cuenta de K’Plan es de turista. Para ofrecer tus servicios necesitas una cuenta aparte, con otro correo: sal de esta y postúlate.';

  @override
  String get guideAccessStatusApprovedSubtitle =>
      'Tu solicitud fue aprobada: los turistas ya te encuentran en K’Plan.';

  @override
  String get guideAccessStatusApprovedTitle => 'Acceso de guía habilitado';

  @override
  String get guideAccessStatusEnterAsGuide => 'Entrar como guía';

  @override
  String guideAccessStatusMissing(String items) {
    return 'Falta: $items.';
  }

  @override
  String get guideAccessStatusPendingNotice =>
      'El acceso de guía estará disponible únicamente si tu solicitud es aprobada. Te avisamos por correo.';

  @override
  String get guideAccessStatusPendingSubtitle =>
      'El equipo de K’Plan está revisando tus documentos.';

  @override
  String get guideAccessStatusPendingTitle => 'Solicitud en revisión';

  @override
  String get guideAccessStatusReceivedSubtitle =>
      'Tu solicitud llegó. El equipo la revisa por orden de llegada.';

  @override
  String get guideAccessStatusRejectedSubtitle =>
      'Revisa lo que hay que corregir.';

  @override
  String get guideAccessStatusRejectedTitle =>
      'No pudimos aprobar tu solicitud';

  @override
  String get guideAccessStatusRenewalApprovedSubtitle =>
      'Tus documentos nuevos están en vigor.';

  @override
  String get guideAccessStatusRenewalApprovedTitle => 'Renovación aprobada';

  @override
  String get guideAccessStatusRenewalPendingTitle => 'Renovación en revisión';

  @override
  String get guideAccessStatusResubmit => 'Corregir y volver a enviar';

  @override
  String guideAccessStatusTeamNote(String note) {
    return 'Nota del equipo: $note';
  }

  @override
  String get guideAccessVehicleSubtitle =>
      'Te pediremos tu licencia de conducir y el seguro del vehículo.';

  @override
  String get guideAccessVehicleTitle => 'Llevo turistas en mi vehículo';

  @override
  String get guideAccessVerify => 'Verificar';

  @override
  String get guideAppBalanceAvailable => 'Disponible para retirar';

  @override
  String guideAppBalanceCommissionNote(int percent) {
    return 'K’Plan descuenta el $percent% de cada viaje. Lo demás es tuyo.';
  }

  @override
  String get guideAppBalanceEmptyHint =>
      'Cuando termines un viaje, lo que recibes aparece aquí para retirarlo.';

  @override
  String get guideAppBalanceEmptyMessage =>
      'Aquí verás lo que recibes por cada viaje y tus retiros.';

  @override
  String get guideAppBalanceEmptyTitle => 'Todavía no hay movimientos';

  @override
  String get guideAppBalanceMovements => 'Movimientos';

  @override
  String get guideAppBalanceNothingPending => 'Nada por cobrar por ahora';

  @override
  String guideAppBalancePayoutBreakdown(String price, String commission) {
    return 'Precio $price · comisión $commission';
  }

  @override
  String guideAppBalancePending(String amount, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count viajes próximos',
      one: '1 viaje próximo',
    );
    return 'Por cobrar $amount de $_temp0';
  }

  @override
  String get guideAppBalanceTitle => 'Balance';

  @override
  String guideAppBalanceToAccount(String account) {
    return 'A $account';
  }

  @override
  String guideAppBalanceWithdrawalDeposited(String date) {
    return '$date · Depositado';
  }

  @override
  String guideAppBalanceWithdrawalProcessing(String date) {
    return '$date · En proceso';
  }

  @override
  String guideAppBalanceWithdrawalSent(String amount) {
    return 'Retiro de $amount en camino';
  }

  @override
  String guideAppBalanceWithdrawalTo(String account) {
    return 'Retiro a $account';
  }

  @override
  String get guideAppBarModeTag => 'Guías';

  @override
  String get guideAppChatsEmptyMessage =>
      'Cuando un turista te contrate, aquí coordinan el punto de encuentro.';

  @override
  String get guideAppChatsEmptyTitle => 'Todavía no tienes conversaciones';

  @override
  String get guideAppChatsNoMessages => 'Sin mensajes';

  @override
  String guideAppChatsUnread(int count) {
    return '$count sin leer';
  }

  @override
  String guideAppChatsYou(String text) {
    return 'Tú: $text';
  }

  @override
  String get guideAppDocumentExpired => 'Vencido';

  @override
  String get guideAppDocumentInReview => 'En revisión';

  @override
  String get guideAppDocumentRejected => 'Rechazado';

  @override
  String get guideAppDocumentValidNoExpiry => 'En vigor · no vence';

  @override
  String guideAppDocumentValidUntil(String date) {
    return 'En vigor · vence el $date';
  }

  @override
  String get guideAppEarningsLabelDone => 'Recibiste';

  @override
  String get guideAppEarningsLabelUpcoming => 'Recibes';

  @override
  String get guideAppHomeATourist => 'Un turista';

  @override
  String get guideAppHomeAvailable => 'Disponible';

  @override
  String get guideAppHomeDefaultName => 'guía';

  @override
  String guideAppHomeEmptyLocal(String city) {
    return 'No hay propuestas nuevas en $city';
  }

  @override
  String get guideAppHomeEmptyMessage =>
      'Cuando un turista publique una, aparecerá aquí.';

  @override
  String get guideAppHomeEmptyNational => 'No hay propuestas nuevas por ahora';

  @override
  String guideAppHomeGreeting(String name) {
    return 'Hola, $name';
  }

  @override
  String guideAppHomeHiredNotice(
    String who,
    String circuit,
    String day,
    String time,
  ) {
    return '¡$who te contrató para $circuit! $day · $time';
  }

  @override
  String get guideAppHomeLoadingProposals => 'Cargando propuestas';

  @override
  String get guideAppHomeNextTrip => 'Próximo viaje';

  @override
  String get guideAppHomePending => 'Por cobrar';

  @override
  String get guideAppHomeProposals => 'Propuestas para ti';

  @override
  String guideAppHomeProposalsLocal(String city) {
    return 'Solo ves propuestas de $city, donde tienes tu certificación.';
  }

  @override
  String get guideAppHomeProposalsNational =>
      'De todo el país, en los idiomas que hablas.';

  @override
  String guideAppHoursShort(int hours) {
    return '$hours h';
  }

  @override
  String get guideAppJobApplicationSent => 'Postulación enviada';

  @override
  String get guideAppJobApplicationTitle => 'Tu postulación';

  @override
  String get guideAppJobApplied => 'Postulado';

  @override
  String guideAppJobAppliedNotice(String price, String name) {
    return 'Te postulaste por $price. $name está decidiendo; te avisaremos en Inicio.';
  }

  @override
  String get guideAppJobApply => 'Postularme';

  @override
  String guideAppJobHiredNotice(String name) {
    return '¡$name te contrató! Ya es uno de tus viajes.';
  }

  @override
  String get guideAppJobLodging => 'El turista te da alojamiento';

  @override
  String get guideAppJobMessageHint =>
      'Cuéntale por qué eres buena opción para este recorrido';

  @override
  String guideAppJobMessageLabel(String name) {
    return 'Mensaje para $name';
  }

  @override
  String get guideAppJobNotFoundMessage =>
      'Puede que el turista la haya retirado.';

  @override
  String get guideAppJobNotFoundTitle => 'No encontramos esta propuesta';

  @override
  String get guideAppJobPostedBy => 'Quién la publicó';

  @override
  String guideAppJobPriceHelper(String amount) {
    return 'El turista ofrece $amount. Puedes proponer otro precio.';
  }

  @override
  String get guideAppJobPriceLabel => 'Tu precio (C\$)';

  @override
  String get guideAppJobPriceRequired => 'Escribe tu precio en córdobas';

  @override
  String guideAppJobPublished(String timeAgo) {
    return 'Publicada $timeAgo';
  }

  @override
  String get guideAppJobRowBudget => 'presupuesto';

  @override
  String get guideAppJobRowYourPrice => 'tu precio';

  @override
  String guideAppJobTakenNotice(String name) {
    return '$name contrató a otro guía. Hay más propuestas en Inicio.';
  }

  @override
  String get guideAppJobTitle => 'Propuesta';

  @override
  String get guideAppJobTouristBudget => 'presupuesto del turista';

  @override
  String guideAppJobWouldReceive(String amount) {
    return 'Recibirías $amount después del 20%.';
  }

  @override
  String guideAppJobYouReceiveAfterFee(String amount) {
    return 'Recibes $amount después del 20% de K’Plan';
  }

  @override
  String get guideAppMoneyAgreedPrice => 'Precio acordado';

  @override
  String guideAppMoneyCommission(int percent) {
    return 'Comisión K’Plan ($percent%)';
  }

  @override
  String get guideAppNavChats => 'Chats';

  @override
  String guideAppNavChatsUnread(int count) {
    return 'Chats, $count sin leer';
  }

  @override
  String get guideAppNavProfile => 'Perfil';

  @override
  String get guideAppNavTrips => 'Viajes';

  @override
  String guideAppProfileAvailable(String amount) {
    return 'Disponible $amount';
  }

  @override
  String get guideAppProfileBalanceHint => 'Lo que recibes por tus viajes';

  @override
  String get guideAppProfileDocuments => 'Mis documentos';

  @override
  String get guideAppProfileEdit => 'Editar mi perfil';

  @override
  String get guideAppProfileEditHint =>
      'Foto, presentación, teléfono e idiomas';

  @override
  String get guideAppProfileNoReviews => 'Todavía sin reseñas de turistas';

  @override
  String get guideAppProfileRenewalInReview =>
      'Tienes una renovación en revisión.';

  @override
  String guideAppProfileSpeaks(String languages) {
    return 'Habla $languages';
  }

  @override
  String guideAppProfileSuspended(String documents) {
    return 'Tu perfil está suspendido: se venció $documents. Renuévalo para volver a aparecer para los turistas.';
  }

  @override
  String get guideAppProfileSuspendedADocument => 'un documento';

  @override
  String get guideAppRateCommentHint =>
      'Cuenta cómo fue: puntualidad, trato, si siguió las indicaciones…';

  @override
  String get guideAppRateMissingStars => 'Elige cuántas estrellas le das';

  @override
  String guideAppRateQuestion(String name) {
    return '¿Cómo fue trabajar con $name?';
  }

  @override
  String get guideAppRateSent =>
      'Calificación enviada. Gracias por ayudar a otros guías.';

  @override
  String guideAppRateStars(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count estrellas',
      one: '1 estrella',
    );
    return '$_temp0';
  }

  @override
  String get guideAppRateSubmit => 'Enviar calificación';

  @override
  String guideAppRateTourist(String name) {
    return 'Calificar a $name';
  }

  @override
  String get guideAppRateVisibility =>
      'Solo otros guías verán tu calificación.';

  @override
  String guideAppRatingAverage(String average) {
    return '$average de guías';
  }

  @override
  String guideAppRatingAverageNamed(String average, String name) {
    return '$average de guías · $name';
  }

  @override
  String get guideAppRatingNone => 'Sin calificaciones de guías';

  @override
  String guideAppRatingNoneNamed(String name) {
    return 'Sin calificaciones de guías · $name';
  }

  @override
  String get guideAppSeeProposals => 'Ver propuestas';

  @override
  String guideAppServiceHours(int hours) {
    return '$hours h de servicio';
  }

  @override
  String get guideAppTheTourist => 'el turista';

  @override
  String get guideAppTheTouristCapital => 'El turista';

  @override
  String get guideAppThreadEmpty =>
      'Escribe para acordar el punto de encuentro.';

  @override
  String get guideAppThreadHint => 'Escribe un mensaje…';

  @override
  String get guideAppThreadSend => 'Enviar';

  @override
  String get guideAppThreadTitle => 'Conversación';

  @override
  String guideAppTouristNoRatingsMessage(String name) {
    return 'Cuando un guía termine un viaje con $name, su opinión aparecerá aquí.';
  }

  @override
  String get guideAppTouristNoRatingsTitle => 'Todavía sin calificaciones';

  @override
  String get guideAppTouristNotFoundMessage =>
      'Puede que haya cerrado su cuenta.';

  @override
  String get guideAppTouristNotFoundTitle => 'No encontramos a este turista';

  @override
  String guideAppTouristRatedAlready(String name) {
    return 'Ya calificaste a $name. Si vuelven a viajar juntos, podrás calificarlo otra vez.';
  }

  @override
  String guideAppTouristRatedFor(String circuit, String date) {
    return 'Por $circuit del $date.';
  }

  @override
  String guideAppTouristRateLater(String name) {
    return 'Podrás calificar a $name cuando terminen un viaje juntos.';
  }

  @override
  String guideAppTouristRatingCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count guías',
      one: '1 guía',
    );
    return 'de $_temp0';
  }

  @override
  String guideAppTouristRatingsNotice(String name) {
    return 'Solo los guías de K’Plan ven estas calificaciones. $name no las ve.';
  }

  @override
  String get guideAppTouristRatingsTitle => 'Calificaciones de guías';

  @override
  String guideAppTouristSince(String country, int year) {
    return '$country · En K’Plan desde $year';
  }

  @override
  String guideAppTouristTileDetails(String country, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count viajes',
      one: '1 viaje',
    );
    return '$country · $_temp0 con K’Plan';
  }

  @override
  String guideAppTouristTrips(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count viajes con K’Plan',
      one: '1 viaje con K’Plan',
    );
    return '$_temp0';
  }

  @override
  String get guideAppTransportGuide => 'Tú pones el transporte';

  @override
  String get guideAppTransportOnFoot => 'Recorrido a pie';

  @override
  String get guideAppTransportTourist => 'El turista pone el transporte';

  @override
  String guideAppTripMeetingPending(String city) {
    return '$city · Punto de encuentro por acordar en el chat';
  }

  @override
  String guideAppTripMessageTourist(String name) {
    return 'Escribir a $name';
  }

  @override
  String get guideAppTripNotFoundMessage =>
      'Revisa tus viajes desde la pestaña Viajes.';

  @override
  String get guideAppTripNotFoundTitle => 'No encontramos este viaje';

  @override
  String get guideAppTripPayment => 'Pago';

  @override
  String get guideAppTripPaymentNote =>
      'Pasa a tu balance cuando termine el viaje.';

  @override
  String get guideAppTripRate => 'Calificar';

  @override
  String guideAppTripRated(String name) {
    return 'Ya calificaste a $name por este viaje.';
  }

  @override
  String get guideAppTripsEmptyDoneMessage =>
      'Después de cada viaje podrás calificar al turista para ayudar a otros guías.';

  @override
  String get guideAppTripsEmptyDoneTitle =>
      'Aquí verás los viajes que termines';

  @override
  String get guideAppTripsEmptyUpcomingMessage =>
      'Postúlate a una propuesta desde Inicio; cuando un turista te contrate, el viaje aparece aquí.';

  @override
  String get guideAppTripsEmptyUpcomingTitle =>
      'Todavía no tienes viajes próximos';

  @override
  String get guideAppTripsTabDone => 'Realizados';

  @override
  String guideAppTripsTabDoneToRate(int count) {
    return 'Realizados · $count por calificar';
  }

  @override
  String get guideAppTripsTabUpcoming => 'Próximos';

  @override
  String get guideAppTripStatusDone => 'Terminado';

  @override
  String get guideAppTripStatusUpcoming => 'Próximo';

  @override
  String get guideAppTripTitle => 'Viaje';

  @override
  String get guideAppTripViewChat => 'Ver la conversación';

  @override
  String get guideAppViewTrip => 'Ver viaje';

  @override
  String get guideAppWithdraw => 'Retirar';

  @override
  String get guideAppWithdrawAmountLabel => 'Monto (C\$)';

  @override
  String get guideAppWithdrawAmountRequired => 'Escribe cuánto quieres retirar';

  @override
  String guideAppWithdrawAvailable(String amount) {
    return 'Disponible: $amount';
  }

  @override
  String get guideAppWithdrawNotice =>
      'Te avisaremos aquí cuando llegue a tu cuenta.';

  @override
  String guideAppWithdrawOverBalance(String amount) {
    return 'Solo tienes $amount disponibles';
  }

  @override
  String get guideAppWithdrawToAccount => 'A tu cuenta';

  @override
  String guideAppYouReceive(String amount) {
    return 'Recibes $amount';
  }

  @override
  String guideAppYouReceived(String amount) {
    return 'Recibiste $amount';
  }

  @override
  String guideChatAgreedPrice(String price) {
    return 'Precio acordado: $price · Pago y reserva: a definir';
  }

  @override
  String get guideChatEmpty => 'Escribe para coordinar el punto de encuentro.';

  @override
  String get guideChatMessageHint => 'Escribe un mensaje…';

  @override
  String guideChatNamePair(String first, String second) {
    return '$first y $second';
  }

  @override
  String get guideProfileAcceptsBudget => 'Acepta tu presupuesto';

  @override
  String get guideProfileAppliedAsGuide =>
      'Se postuló como guía a tu propuesta';

  @override
  String get guideProfileAppliedAsTranslator =>
      'Se postuló como traductor a tu propuesta';

  @override
  String get guideProfileChat => 'Chatear';

  @override
  String get guideProfileDeparturesTitle => 'Próximas salidas';

  @override
  String get guideProfileHasVehicle => 'Tiene vehículo propio';

  @override
  String get guideProfileHiredAsGuide => 'Contratado como guía';

  @override
  String get guideProfileHiredAsTranslator => 'Contratado como traductor';

  @override
  String guideProfileHireFor(String price) {
    return 'Contratar por $price';
  }

  @override
  String guideProfileLessThanBudget(String amount) {
    return '$amount menos que tu presupuesto';
  }

  @override
  String guideProfileMoreThanBudget(String amount) {
    return '$amount más que tu presupuesto';
  }

  @override
  String get guideProfileNoTransport => 'No pone transporte';

  @override
  String get guideProfileNoVehicle => 'Sin vehículo propio';

  @override
  String get guideProfileOffersTransport => 'Pone transporte para tu grupo';

  @override
  String get guideProfilePaymentPending => 'Pago y reserva: a definir';

  @override
  String guideProfileReviewsCount(int count) {
    return 'Reseñas ($count)';
  }

  @override
  String get guideProfileTitle => 'Perfil del guía';

  @override
  String get guideRequestApplicationsTitle => 'Postulaciones';

  @override
  String guideRequestApplicationsTitleCount(int count) {
    return 'Postulaciones ($count)';
  }

  @override
  String get guideRequestApplicationUnavailable =>
      'Esta postulación ya no está disponible';

  @override
  String guideRequestBudget(String total) {
    return 'Presupuesto: $total';
  }

  @override
  String guideRequestBudgetBoth(String total, String guide, String translator) {
    return 'Presupuesto: $total (guía $guide + traductor $translator)';
  }

  @override
  String get guideRequestCancelAction => 'Retirar propuesta';

  @override
  String get guideRequestCancelConfirm => 'Retirar';

  @override
  String get guideRequestCancelMessage =>
      'Los guías ya no podrán postularse. Tu reserva del circuito sigue agendada.';

  @override
  String get guideRequestCancelTitle => '¿Retirar tu propuesta?';

  @override
  String get guideRequestGoToChat => 'Ir al chat';

  @override
  String get guideRequestGuidesTitle => 'Guías';

  @override
  String guideRequestGuidesTitleCount(int count) {
    return 'Guías ($count)';
  }

  @override
  String get guideRequestHire => 'Contratar';

  @override
  String get guideRequestHired => 'Contratado';

  @override
  String guideRequestHireMessageGuide(String price) {
    return 'Será tu guía por $price. Las demás postulaciones para este puesto quedan descartadas.';
  }

  @override
  String guideRequestHireMessageTranslator(String price) {
    return 'Será tu traductor por $price. Las demás postulaciones para este puesto quedan descartadas.';
  }

  @override
  String get guideRequestHireNextGuide => '¡Listo! Ahora elige a tu guía.';

  @override
  String get guideRequestHireNextTranslator =>
      '¡Listo! Ahora elige a tu traductor.';

  @override
  String guideRequestHireTitle(String name) {
    return '¿Contratar a $name?';
  }

  @override
  String get guideRequestLodgingProvided => 'Le das alojamiento al guía';

  @override
  String get guideRequestNoMaxFee =>
      'Sin tope de precio: cada guía propone el suyo';

  @override
  String get guideRequestNoneSubtitle =>
      'Publica una al agendar un circuito, desde \"Guía o traductor\".';

  @override
  String get guideRequestNoneTitle => 'No tienes una propuesta activa';

  @override
  String get guideRequestNoTransport => 'Sin transporte';

  @override
  String get guideRequestOffersTransport => 'Pone transporte';

  @override
  String guideRequestPriceLess(String amount) {
    return '$amount menos';
  }

  @override
  String guideRequestPriceMore(String amount) {
    return '$amount más';
  }

  @override
  String get guideRequestPriceYourBudget => 'Tu presupuesto';

  @override
  String get guideRequestRoleBoth => 'Guía y traductor';

  @override
  String get guideRequestStatusCancelledSubtitle =>
      'Los guías ya no pueden postularse.';

  @override
  String get guideRequestStatusCancelledTitle => 'Retiraste esta propuesta';

  @override
  String get guideRequestStatusExpiredSubtitle =>
      'No contrataste a nadie a tiempo. Puedes publicar otra desde Agendar.';

  @override
  String get guideRequestStatusExpiredTitle => 'Tu propuesta venció';

  @override
  String guideRequestStatusHiredSubtitle(String price) {
    return 'Acordaste $price por el servicio.';
  }

  @override
  String get guideRequestStatusHiredTitle =>
      '¡Listo! Ya tienes quién te acompañe';

  @override
  String guideRequestStatusOpenSubtitle(String remaining) {
    return 'Los guías ya pueden verla. Vence en $remaining.';
  }

  @override
  String get guideRequestStatusOpenTitle =>
      'Publicada · recibiendo postulaciones';

  @override
  String get guideRequestTeamTitle => 'Tu equipo';

  @override
  String get guideRequestTitle => 'Tu propuesta';

  @override
  String get guideRequestTranslatorsTitle => 'Traductores';

  @override
  String guideRequestTranslatorsTitleCount(int count) {
    return 'Traductores ($count)';
  }

  @override
  String get guideRequestTransportGuide => 'El guía pone el transporte';

  @override
  String get guideRequestTransportOnFoot => 'Recorrido a pie';

  @override
  String get guideRequestTransportTourist => 'Tú pones el transporte';

  @override
  String get guideRequestWaitingGuides =>
      'Esperando postulaciones de guías. Te avisamos aquí apenas alguien se postule.';

  @override
  String get guideRequestWaitingTranslators =>
      'Esperando postulaciones de traductores. Te avisamos aquí apenas alguien se postule.';

  @override
  String guideRequestWaitingTranslatorsLanguage(String language) {
    return 'Esperando postulaciones de traductores de $language. Te avisamos aquí apenas alguien se postule.';
  }

  @override
  String guideRequestYearsExperience(int years) {
    String _temp0 = intl.Intl.pluralLogic(
      years,
      locale: localeName,
      other: '$years años de experiencia',
      one: '1 año de experiencia',
    );
    return '$_temp0';
  }

  @override
  String get guidesEmptyMessage =>
      'Cuando el equipo apruebe a más guías y traductores, aparecerán aquí.';

  @override
  String get guidesEmptyTitle => 'Todavía no hay guías disponibles';

  @override
  String get guidesFilterAll => 'Todos';

  @override
  String get guidesFilterGuides => 'Guías';

  @override
  String get guidesFilterTranslators => 'Traductores';

  @override
  String get guidesNoReviews => 'Sin reseñas todavía';

  @override
  String get guidesTitle => 'Guías y traductores';

  @override
  String get homeActiveTripAllVisited =>
      'Ya pasaste por todas las paradas · toca para finalizar';

  @override
  String homeActiveTripNext(String stop, String time, String delay) {
    return 'Siguiente: $stop · $time · $delay';
  }

  @override
  String homeActiveTripTitle(String title) {
    return 'Viaje en curso: $title';
  }

  @override
  String get homeActiveTripViewMap => 'Ver mapa';

  @override
  String homeCircuitBonus(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '+$count insignias extra y medalla',
      one: '+1 insignia extra y medalla',
    );
    return '$_temp0';
  }

  @override
  String homeCircuitStops(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count paradas',
      one: '1 parada',
    );
    return '$_temp0';
  }

  @override
  String get homeDrawerBecomeGuide => 'Ser guía en K’Plan';

  @override
  String homeDrawerComingSoon(String label) {
    return '$label: próximamente';
  }

  @override
  String get homeDrawerGuideMode => 'Modo guía';

  @override
  String get homeDrawerTranslatorMode => 'Modo traductor';

  @override
  String get homeEmptySearchMessage =>
      'Prueba con otra palabra o revisa cómo está escrita.';

  @override
  String get homeEmptySearchTitle => 'No encontramos nada con esa búsqueda';

  @override
  String get homeEmptyStopsMessage =>
      'Prueba con otra categoría o con otra búsqueda.';

  @override
  String get homeEmptyStopsTitle => 'No hay paradas que coincidan';

  @override
  String get homeGuideRequestApplicationsHint =>
      'Toca para revisarlas y elegir';

  @override
  String homeGuideRequestApplicationsTitle(int count, String circuit) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count postulaciones para $circuit',
      one: '1 postulación para $circuit',
    );
    return '$_temp0';
  }

  @override
  String get homeGuideRequestHiredHint => 'Toca para chatear';

  @override
  String homeGuideRequestHiredTitle(String names, String circuit) {
    return 'Contrataste a $names para $circuit';
  }

  @override
  String homeGuideRequestNamesJoin(String first, String second) {
    return '$first y $second';
  }

  @override
  String get homeGuideRequestPublishedHint =>
      'Esperando que los guías se postulen';

  @override
  String homeGuideRequestPublishedTitle(String circuit) {
    return 'Tu propuesta para $circuit está publicada';
  }

  @override
  String homeRewardsAvailable(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Tienes $count insignias para canjear',
      one: 'Tienes 1 insignia para canjear',
    );
    return '$_temp0';
  }

  @override
  String get homeRewardsEarn => 'Gana insignias visitando paradas';

  @override
  String get homeRewardsHint => 'Cámbialas por cupones y descuentos';

  @override
  String get homeSearchHint => '¿Qué quieres descubrir?';

  @override
  String get homeSectionCircuits => 'Circuitos completos';

  @override
  String get homeSectionEvents => 'Eventos Próximos';

  @override
  String get homeSectionStops => 'Paradas destacadas';

  @override
  String homeStopCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count paradas',
      one: '1 parada',
    );
    return '$_temp0';
  }

  @override
  String get homeTabCircuits => 'Circuitos';

  @override
  String get homeTabEvents => 'Eventos';

  @override
  String get homeTabForYou => 'Para ti';

  @override
  String get homeTabStops => 'Paradas';

  @override
  String get homeTitle => 'Descubre tu próximo plan';

  @override
  String get homeTopBarMenu => 'Menú';

  @override
  String get homeUpcomingTripHint => 'Toca para ver los detalles del circuito';

  @override
  String homeUpcomingTripTitle(String circuit, String date) {
    return 'Tu viaje a $circuit es el $date';
  }

  @override
  String get languageChoiceNote =>
      'Podrás cambiarlo después en Configuraciones.';

  @override
  String get languageChoiceTitle => 'Elige tu idioma';

  @override
  String get languageNameEnglish => 'Inglés';

  @override
  String get languageNameFrench => 'Francés';

  @override
  String get languageNameGerman => 'Alemán';

  @override
  String get languageNameItalian => 'Italiano';

  @override
  String get languageNamePortuguese => 'Portugués';

  @override
  String get languageNameSpanish => 'Español';

  @override
  String get languagePlaceNamesNote =>
      'Los nombres de lugares conservan su idioma original.';

  @override
  String get languageSettingsHeading => 'Idioma de la aplicación';

  @override
  String get languageSettingsTitle => 'Idioma';

  @override
  String get loginApplyAsGuide => 'Postularme';

  @override
  String get loginApplyAsGuideButton => 'Postularme como guía';

  @override
  String get loginContinueWithGoogle => 'Continuar con Google';

  @override
  String get loginForgotPassword => '¿Olvidaste tu contraseña?';

  @override
  String get loginGoogleProfileFailed =>
      'No pudimos completar tu perfil, intenta de nuevo';

  @override
  String get loginGoogleProfileSubtitle =>
      'Google no nos da estos datos y los necesitamos para crear tu cuenta. Debes ser mayor de 18 años.';

  @override
  String get loginGoogleProfileTitle => 'Completa tu perfil';

  @override
  String get loginGuideAccountHint =>
      'Entra con la cuenta con la que te postulaste como guía o traductor.';

  @override
  String get loginGuideNotYet => '¿Todavía no eres guía en K’Plan?';

  @override
  String get loginMissingAccountGuide => '¿Quieres registrarte como guía?';

  @override
  String get loginMissingAccountTitle => 'No hemos encontrado esta cuenta';

  @override
  String get loginMissingAccountTourist => '¿Quieres registrarte como turista?';

  @override
  String get loginNoAccount => '¿No tienes cuenta?';

  @override
  String get loginSubmit => 'Iniciar sesión';

  @override
  String get loginTwoFactorCodeHint => 'Código';

  @override
  String get loginTwoFactorCodeRequired =>
      'Escribe el código de 6 dígitos o uno de recuperación';

  @override
  String get loginTwoFactorSubtitle =>
      'Escribe el código de 6 dígitos de tu app de autenticación. Si perdiste el celular, usa uno de tus códigos de recuperación.';

  @override
  String get loginTwoFactorTitle => 'Verifica que eres tú';

  @override
  String get loginTwoFactorVerify => 'Verificar';

  @override
  String medalsBalanceAvailable(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count disponibles',
      one: '1 disponible',
    );
    return '$_temp0';
  }

  @override
  String medalsBalanceEarned(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count insignias',
      one: '1 insignia',
    );
    return '$_temp0';
  }

  @override
  String medalsBalanceNote(String earned, String available) {
    return 'Ganaste $earned en total: eso es lo que cuenta para tus medallas, y no baja aunque gastes insignias. Tienes $available para canjear en Cupones.';
  }

  @override
  String medalsBalanceNoteSpent(String earned, String available, int spent) {
    String _temp0 = intl.Intl.pluralLogic(
      spent,
      locale: localeName,
      other: '$spent ya gastadas',
      one: '1 ya gastada',
    );
    return 'Ganaste $earned en total: eso es lo que cuenta para tus medallas, y no baja aunque gastes insignias. Tienes $available para canjear en Cupones ($_temp0).';
  }

  @override
  String get medalsByCategory => 'Medallas por categoría';

  @override
  String get medalsByCategoryNote =>
      'Se ganan insignias visitando paradas que las otorgan.';

  @override
  String get medalsCityEarned => 'Medalla ganada';

  @override
  String medalsCityLocked(String city) {
    return 'Completa un circuito creativo de $city';
  }

  @override
  String get medalsCreativeCities => 'Medallas de ciudades creativas';

  @override
  String get medalsCreativeCitiesNote =>
      'Se ganan al completar un circuito creativo de esa ciudad.';

  @override
  String get medalsMaxLevel => '¡Nivel máximo alcanzado!';

  @override
  String medalsOverall(String tier) {
    return 'Medalla general: $tier';
  }

  @override
  String medalsTierMax(String tier) {
    return '$tier · nivel máximo';
  }

  @override
  String medalsTierToNext(String tier, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'faltan $count para subir',
      one: 'falta 1 para subir',
    );
    return '$tier · $_temp0';
  }

  @override
  String medalsToNextOverall(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Te faltan $count insignias para la siguiente medalla',
      one: 'Te falta 1 insignia para la siguiente medalla',
    );
    return '$_temp0';
  }

  @override
  String get modelBookingStatusCancelled => 'Cancelada';

  @override
  String get modelBookingStatusClosed => 'Cerrada';

  @override
  String get modelBookingStatusConfirmed => 'Confirmada';

  @override
  String get modelBookingStatusDelivered => 'Terminada';

  @override
  String get modelBookingStatusInProgress => 'En curso';

  @override
  String get modelDropReasonClosed => 'Estaba cerrado';

  @override
  String get modelDropReasonNoTime => 'Falta de tiempo';

  @override
  String get modelDropReasonNotInterested => 'No me interesó';

  @override
  String get modelDropReasonOther => 'Otro motivo';

  @override
  String get modelDropReasonTooExpensive => 'Muy caro';

  @override
  String get modelDropReasonTooFar => 'Muy lejos o sin transporte';

  @override
  String get modelDropReasonWeather => 'Por el clima';

  @override
  String modelGuideCoverageLocalCity(String city) {
    return 'Guía local · $city';
  }

  @override
  String get modelGuideCoverageNational => 'Guía nacional';

  @override
  String modelLegFixed(String duration) {
    return '$duration de traslado';
  }

  @override
  String get modelLegNoTransfer => 'Sin traslado';

  @override
  String get modelLegSamePlace => 'A pasos';

  @override
  String modelLegVehicle(String duration) {
    return '$duration en vehículo';
  }

  @override
  String modelLegWalking(String duration) {
    return '$duration a pie';
  }

  @override
  String modelNeedBilingualGuide(String language) {
    return 'Guía que habla $language';
  }

  @override
  String get modelNeedBilingualGuideShort => 'Guía bilingüe';

  @override
  String get modelNeedGuideAndTranslatorShort => 'Guía + traductor';

  @override
  String modelNeedLocalGuideAndTranslator(String language) {
    return 'Guía local + traductor de $language';
  }

  @override
  String modelNeedTranslatorOnly(String language) {
    return 'Traductor de $language';
  }

  @override
  String get modelNeedTranslatorOnlyShort => 'Solo traductor';

  @override
  String get modelNeedYourLanguage => 'tu idioma';

  @override
  String get modelPaceBalanced => 'Equilibrado';

  @override
  String get modelPaceIntense => 'Intenso';

  @override
  String get modelPaceRelaxed => 'Relajado';

  @override
  String get modelPaymentFree => 'Sin cobro';

  @override
  String get modelPaymentPaid => 'Pagado';

  @override
  String get modelPaymentPending => 'Pago pendiente';

  @override
  String get modelPaymentRefundDue => 'Por reembolsar';

  @override
  String get modelPaymentRefunded => 'Reembolsado';

  @override
  String get modelPaymentVoided => 'Pago anulado';

  @override
  String get modelTravelModeVehicle => 'En vehículo';

  @override
  String get modelTravelModeWalking => 'A pie';

  @override
  String get myCircuitAiMessage =>
      'Te pregunta cómo quieres tu día, calcula los traslados y te sugiere qué quitar o agregar.';

  @override
  String get myCircuitAiTitle => 'Organizar con IA';

  @override
  String myCircuitArrivalAt(String stop) {
    return 'Hora de llegada a $stop';
  }

  @override
  String get myCircuitDepartureTime => 'Hora de salida';

  @override
  String get myCircuitEmpty => 'Este circuito todavía no tiene paradas';

  @override
  String get myCircuitEmptyMessage =>
      'En cualquier parada, toca \"Añadir a un circuito\" y elige este.';

  @override
  String get myCircuitExploreStops => 'Explorar paradas';

  @override
  String get myCircuitFixedTime => 'Hora fija';

  @override
  String get myCircuitFixedTimeRemove => 'Quitar';

  @override
  String myCircuitMissedFixedTime(String time) {
    return 'Querías llegar a las $time';
  }

  @override
  String get myCircuitProposalNote =>
      'Como lo armaste tú, puedes publicar una propuesta para que guías o traductores se postulen.';

  @override
  String myCircuitRemoved(String stop) {
    return '$stop se quitó del circuito';
  }

  @override
  String get myCircuitRemoveTooltip => 'Quitar del circuito';

  @override
  String myCircuitRemoveWhy(String stop) {
    return '¿Por qué quitas $stop?';
  }

  @override
  String get myCircuitReorderHint =>
      'Toca la hora de una parada para cambiarla y arrástrala para cambiar el orden.';

  @override
  String get myCircuitSchedule => 'Agendar circuito';

  @override
  String myCircuitSkipWhy(String stop) {
    return '¿Por qué saltas $stop?';
  }

  @override
  String get myCircuitStartTrip => 'Comenzar viaje';

  @override
  String get myCircuitStopsHeader => 'Paradas del recorrido';

  @override
  String get myCircuitTimeHint => 'Toca la hora de una parada para cambiarla.';

  @override
  String get myCircuitTodayRoute => 'Tu recorrido de hoy';

  @override
  String get myCircuitTransport => 'Transporte';

  @override
  String get myCircuitTravelQuestion => '¿Cómo te vas a mover?';

  @override
  String get myCircuitTripEnded => 'Viaje finalizado';

  @override
  String myCircuitTripStarted(String stop) {
    return '¡Viaje iniciado! Dirígete a $stop';
  }

  @override
  String get myCircuitUndo => 'Deshacer';

  @override
  String get myCircuitYourDay => 'Tu día';

  @override
  String get myTripsAiSubtitle => 'Te organiza el día con horarios y traslados';

  @override
  String get myTripsAiTitle => 'Arma tu viaje con IA';

  @override
  String get myTripsAllVisited => 'Ya pasaste por todas las paradas';

  @override
  String get myTripsAllVisitedHint =>
      'Entra al detalle para finalizar el recorrido';

  @override
  String myTripsArrival(String time, String delay) {
    return 'Llegada $time · $delay';
  }

  @override
  String myTripsBookingConfirmed(String people) {
    return 'Reserva confirmada · $people';
  }

  @override
  String myTripsBookingDeparture(String time) {
    return 'Salida $time';
  }

  @override
  String get myTripsCircuitsEmpty =>
      'Todavía no armaste ninguno. Los que crees aparecen aquí para editarlos, reservarlos o salir a recorrerlos.';

  @override
  String get myTripsContactGuide => 'Contactar a mi guía';

  @override
  String get myTripsContactTranslator => 'Contactar a mi traductora';

  @override
  String get myTripsCreateSubtitle => 'Elige tú las paradas y el orden';

  @override
  String get myTripsCreateTitle => 'Crear un circuito desde cero';

  @override
  String get myTripsDeleteConfirm => 'Eliminar';

  @override
  String get myTripsDeleteMessage =>
      'Se borrarán sus paradas guardadas. No se puede deshacer.';

  @override
  String myTripsDeleteTitle(String title) {
    return '¿Eliminar \"$title\"?';
  }

  @override
  String myTripsDeleteTooltip(String title) {
    return 'Eliminar $title';
  }

  @override
  String get myTripsExploreCircuits => 'Explorar circuitos';

  @override
  String myTripsGuideRoleLanguages(String role, String languages) {
    return '$role · $languages';
  }

  @override
  String get myTripsHeadline => 'El próximo destino te espera';

  @override
  String myTripsNextStop(String stop) {
    return 'Siguiente: $stop';
  }

  @override
  String get myTripsOngoingEmptyMessage =>
      'Cuando empieces un circuito, aquí verás tu próxima parada, la hora de llegada y el mapa.';

  @override
  String get myTripsOngoingEmptyTitle => 'Ningún recorrido en curso';

  @override
  String get myTripsOpenMap => 'Abrir el mapa';

  @override
  String get myTripsPlanAnother => 'Planificar otro viaje';

  @override
  String myTripsProgress(int visited, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '$visited de $total paradas',
      one: '$visited de 1 parada',
    );
    return '$_temp0';
  }

  @override
  String myTripsProgressSemantics(int visited, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: 'Llevas $visited de $total paradas',
      one: 'Llevas $visited de 1 parada',
    );
    return '$_temp0';
  }

  @override
  String get myTripsSeeDetails => 'Ver detalle del recorrido';

  @override
  String get myTripsSeeUpcoming => 'Ver mis próximos viajes';

  @override
  String get myTripsTabOngoing => 'En curso';

  @override
  String get myTripsTabUpcoming => 'Próximos';

  @override
  String get myTripsUpcomingEmptyMessage =>
      'Elige un circuito y organiza tu primera salida. Aquí encontrarás los detalles de cada viaje.';

  @override
  String get myTripsUpcomingEmptyOrAi => 'O arma tu viaje con IA';

  @override
  String get myTripsUpcomingEmptyTitle => 'Tu historia está por empezar';

  @override
  String get myTripsYourCircuits => 'Tus circuitos';

  @override
  String myTripsYourCircuitsCount(int count) {
    return 'Tus circuitos · $count';
  }

  @override
  String get myTripsYourGuide => 'Tu guía';

  @override
  String get myTripsYourTranslator => 'Tu traductora';

  @override
  String get profileCouponsSubtitle => 'Beneficios de negocios locales';

  @override
  String get profileGuestName => 'Invitado';

  @override
  String get profileMedalsSubtitle => 'Recuerdos de tus recorridos';

  @override
  String get profileMyCoupons => 'Mis cupones';

  @override
  String get profileNotificationsSubtitle => 'Avisos de tus viajes y reservas';

  @override
  String get profilePersonalData => 'Datos personales';

  @override
  String get profilePersonalDataSubtitle => 'Nombre y datos de contacto';

  @override
  String get profileSavedSubtitle =>
      'Circuitos, lugares y eventos que marcaste';

  @override
  String get profileSettingsSubtitle => 'Cuenta, idioma y privacidad';

  @override
  String get profileStatBadges => 'Insignias';

  @override
  String get profileTitle => 'Mi perfil';

  @override
  String registerAdultOnly(int age) {
    return 'Debes ser mayor de $age años para crear una cuenta';
  }

  @override
  String get registerBirthDatePartDay => 'Día';

  @override
  String get registerBirthDatePartMonth => 'Mes';

  @override
  String get registerBirthDatePartYear => 'Año';

  @override
  String get registerBirthDateSubtitle =>
      'Tu fecha de nacimiento será privada, y nos ayudará a ofrecerte una mejor experiencia';

  @override
  String get registerBirthDateTitle => '¿Cuándo naciste?';

  @override
  String registerCodeSent(String email) {
    return 'Enviamos un código de 6 dígitos al correo $email';
  }

  @override
  String get registerCodeTitle => 'Ingrese el código de verificación';

  @override
  String get registerEmailSubtitle =>
      'Lo usaremos para verificar tu cuenta. Tu información se mantendrá privada.';

  @override
  String get registerEmailTitle => 'Ingrese su correo electrónico';

  @override
  String get registerLoginAction => 'Inicia sesión';

  @override
  String registerLoginLink(String action) {
    return '¿Ya tienes cuenta? $action';
  }

  @override
  String get registerNameLabel => 'Nombre';

  @override
  String get registerNameRequired => 'Ingresa tu nombre';

  @override
  String get registerNameTitle => '¿Cómo te llamas?';

  @override
  String get registerNationalityLabel => 'País';

  @override
  String get registerNationalitySubtitle =>
      'Tu nacionalidad es privada: nos ayuda a recomendarte mejor y a cumplir con la ley.';

  @override
  String get registerNationalityTitle => '¿De dónde eres?';

  @override
  String get registerPasswordRuleLength => '8 caracteres';

  @override
  String registerPasswordRuleMet(String rule) {
    return '$rule: cumplido';
  }

  @override
  String get registerPasswordRuleNumber => 'Un número';

  @override
  String registerPasswordRulePending(String rule) {
    return '$rule: pendiente';
  }

  @override
  String get registerPasswordRuleUpper => 'Una mayúscula';

  @override
  String get registerPasswordSubtitle =>
      'Usa al menos 8 caracteres, una mayúscula y un número.';

  @override
  String get registerPasswordTitle => 'Cree una contraseña';

  @override
  String get registerUsernameLabel => 'Nombre de usuario';

  @override
  String get registerUsernameSubtitle =>
      'Este nombre será visible dentro de K’Plan';

  @override
  String get registerUsernameTitle => 'Cree un nombre de usuario';

  @override
  String get repoAccessDemoExperienceLocal =>
      '6 años en Granada: historia colonial y gastronomía.';

  @override
  String get repoAccessDemoExperienceNational =>
      '9 años con recorridos de arquitectura colonial y leyendas.';

  @override
  String get repoAccessSignInFirst => 'Inicia sesión primero';

  @override
  String get repoApplicantDefaultMessage =>
      '¡Me encantaría acompañarte en este recorrido!';

  @override
  String get repoApplicantHasVehicle => 'Tengo vehículo propio para tu grupo.';

  @override
  String repoApplicantStrengths(String specialties) {
    return 'Mi fuerte: $specialties.';
  }

  @override
  String repoApplicantTourInLanguage(String language) {
    return 'Puedo dar todo el recorrido en $language.';
  }

  @override
  String get repoApplicantTranslatorMessage =>
      'Traduzco en tiempo real durante todo el recorrido.';

  @override
  String repoApplicantTranslatorMessageToLanguage(String language) {
    return 'Traduzco en tiempo real del español al $language durante todo el recorrido.';
  }

  @override
  String get repoAuthAccountCreated =>
      'Tu cuenta quedó creada. Inicia sesión para entrar.';

  @override
  String get repoAuthAccountNotFound => 'No hemos encontrado esta cuenta';

  @override
  String get repoAuthGoogleFailed =>
      'No pudimos entrar con Google, intenta de nuevo';

  @override
  String get repoAuthInvalidCode => 'El código no es válido';

  @override
  String get repoAuthMissingData => 'Faltan datos para crear la cuenta';

  @override
  String get repoAuthWrongCredentials => 'Correo o contraseña incorrectos';

  @override
  String get repoChatReplyMeetingPoint =>
      'Perfecto, nos vemos en el punto de encuentro. ¡Puntual!';

  @override
  String get repoChatReplyQuestions =>
      'Cualquier duda antes del recorrido, escríbeme por aquí.';

  @override
  String get repoChatReplyWelcome =>
      '¡Hola! Con gusto te acompaño en el recorrido.';

  @override
  String repoCollectionsDeleteFailed(String message) {
    return 'No pudimos borrar el circuito de tu cuenta. $message';
  }

  @override
  String repoCollectionsLoadFailed(String message) {
    return 'No pudimos traer los circuitos guardados en tu cuenta. $message';
  }

  @override
  String repoCollectionsSaveFailed(String message) {
    return 'No pudimos guardar el circuito en tu cuenta; tus cambios siguen en este teléfono. $message';
  }

  @override
  String get repoInboxReplyEarlier => '¿Podemos empezar 15 minutos antes?';

  @override
  String get repoInboxReplyNoted => 'Genial, gracias por avisar.';

  @override
  String get repoInboxReplySeeYou => 'Ahí estaremos. ¡Nos vemos!';

  @override
  String get repoInboxReplyThanks => '¡Perfecto, gracias!';

  @override
  String get repoInlineLanguageEnglish => 'inglés';

  @override
  String get repoInlineLanguageFrench => 'francés';

  @override
  String get repoInlineLanguageGerman => 'alemán';

  @override
  String get repoInlineLanguageItalian => 'italiano';

  @override
  String get repoInlineLanguagePortuguese => 'portugués';

  @override
  String get repoInlineLanguageSpanish => 'español';

  @override
  String get repoNetworkCommunicationError =>
      'Ocurrió un error de comunicación con el servidor';

  @override
  String get repoNetworkConnectionTimeout => 'Tiempo de conexión agotado';

  @override
  String get repoNetworkNoConnection => 'No hay conexión a internet';

  @override
  String repoNetworkRetryIn(String message, String wait) {
    return '$message Puedes reintentar en $wait.';
  }

  @override
  String get repoNetworkServerTimeout =>
      'El servidor tardó demasiado en responder';

  @override
  String get repoNetworkSessionExpired =>
      'Sesión expirada, vuelve a iniciar sesión';

  @override
  String get repoNetworkTooManyAttempts =>
      'Demasiados intentos, espera un momento e intenta de nuevo';

  @override
  String repoNetworkWaitMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count minutos',
      one: '1 minuto',
    );
    return '$_temp0';
  }

  @override
  String repoNetworkWaitSeconds(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count segundos',
      one: '1 segundo',
    );
    return '$_temp0';
  }

  @override
  String get repoNotificationBookingChanges => 'Cambios en mis reservas';

  @override
  String get repoNotificationNewsAndBenefits => 'Beneficios y novedades';

  @override
  String get repoNotificationSavedEvents => 'Eventos guardados';

  @override
  String get repoNotificationTripReminders => 'Recordatorios de viajes';

  @override
  String repoSpecialtiesPair(String first, String second) {
    return '$first y $second';
  }

  @override
  String repoTourBadgesNote(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Este recorrido contiene un total de $count insignias coleccionables',
      one: 'Este recorrido contiene 1 insignia coleccionable',
      zero: 'Este recorrido no tiene insignias coleccionables',
    );
    return '$_temp0';
  }

  @override
  String repoTourBadgesNoteBonus(int count, int extra) {
    return 'Este recorrido contiene un total de $count insignias coleccionables, más $extra insignias extra al completarlo';
  }

  @override
  String repoTourBadgesNoteCreative(int count, int extra, String city) {
    return 'Este recorrido contiene un total de $count insignias coleccionables, más $extra insignias extra de \"Circuitos creativos\" y una medalla de $city al completarlo';
  }

  @override
  String get repoTourDifficultyEasy => 'Fácil';

  @override
  String get repoTourDifficultyModerate => 'Moderado';

  @override
  String repoTourDurationAbout(int hours) {
    return '$hours h aprox.';
  }

  @override
  String get repoTourDurationDay => '1 día';

  @override
  String get repoTouristNotFound => 'No encontramos a este turista';

  @override
  String get repoTouristRateOnce =>
      'Solo puedes calificar una vez, después de terminar el viaje';

  @override
  String get repoTouristRateStars => 'Elige de 1 a 5 estrellas';

  @override
  String get repoTouristRatingToday => 'hoy';

  @override
  String repoWorkAmountExceedsAvailable(String amount) {
    return 'Solo tienes $amount disponibles';
  }

  @override
  String get repoWorkAmountInvalid => 'Escribe un monto mayor a cero';

  @override
  String get repoWorkGuideFallbackName => 'Guía de K’Plan';

  @override
  String repoWorkHireGreeting(String circuitTitle) {
    return '¡Hola! Te contraté para $circuitTitle. ¿Dónde nos vemos?';
  }

  @override
  String get repoWorkJobNotFound => 'No encontramos esta propuesta';

  @override
  String get repoWorkJobNotOpen => 'Ya no puedes postularte a esta propuesta';

  @override
  String get repoWorkPriceInvalid => 'Escribe un precio mayor a cero';

  @override
  String get repoWorkSampleBankAccount => 'Cuenta de ejemplo •••• 0000';

  @override
  String get repoWorkWithdrawLoginRequired =>
      'Inicia sesión como guía para retirar';

  @override
  String get reviewDisputeHint => 'Explica por qué el equipo debería revisarla';

  @override
  String get reviewDisputeSend => 'Pedir revisión';

  @override
  String get reviewDisputeSent => 'Le pedimos al equipo que revise la reseña.';

  @override
  String get reviewDisputeTitle => 'Impugnar la reseña';

  @override
  String get reviewDisputeTooShort => 'Escribe al menos 10 caracteres';

  @override
  String get routeMapAllowLocationInSettings =>
      'Permite la ubicación en los ajustes para verte en el mapa';

  @override
  String get routeMapAlreadyHere => 'Ya estás aquí';

  @override
  String routeMapArrival(String time) {
    return 'Llegada $time';
  }

  @override
  String routeMapArrivalDelay(String time, String delay) {
    return 'Llegada $time · $delay';
  }

  @override
  String routeMapBadgeEarned(String category) {
    return 'Insignia de $category obtenida';
  }

  @override
  String routeMapBadgeToEarn(String category) {
    return 'Escanea su código QR para ganar la insignia de $category';
  }

  @override
  String get routeMapCenterPlace => 'Centrar el lugar';

  @override
  String get routeMapDemoQrTooltip => 'Ver código de prueba';

  @override
  String get routeMapDirections => 'Cómo llegar';

  @override
  String routeMapDistanceFromYou(String distance, String label) {
    return 'A $distance de ti · $label';
  }

  @override
  String get routeMapEndTrip => 'Finalizar viaje';

  @override
  String get routeMapFreeEntry => 'Entrada libre';

  @override
  String routeMapGoToNext(String name) {
    return 'Ir a la siguiente: $name';
  }

  @override
  String get routeMapLocationHint =>
      'Activa tu ubicación para verte en el mapa';

  @override
  String get routeMapLocationOffInSettings =>
      'Apagaste la ubicación en Configuraciones';

  @override
  String get routeMapMyCircuit => 'Mi circuito';

  @override
  String get routeMapMyLocation => 'Mi ubicación';

  @override
  String routeMapNextStop(String name) {
    return 'Siguiente: $name';
  }

  @override
  String get routeMapNextStopOverline => 'Siguiente parada';

  @override
  String get routeMapNoLocation =>
      'Sin tu ubicación, el mapa no puede mostrarte';

  @override
  String get routeMapNoStops => 'Este circuito todavía no tiene paradas';

  @override
  String routeMapOpenHours(String hours) {
    return 'Abierto de $hours';
  }

  @override
  String get routeMapOverlineEvent => 'Evento';

  @override
  String get routeMapOverlineStop => 'Parada';

  @override
  String get routeMapScanQr => 'Escanear código QR';

  @override
  String get routeMapSearchingLocation => 'Buscando tu ubicación…';

  @override
  String get routeMapSettingsAction => 'Ajustes';

  @override
  String get routeMapShowWholeRoute => 'Ver todo el recorrido';

  @override
  String routeMapStopCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count paradas',
      one: '1 parada',
    );
    return '$_temp0';
  }

  @override
  String routeMapStopOfTotal(int number, int total) {
    return 'Parada $number de $total';
  }

  @override
  String routeMapStopSkipped(int number) {
    return 'Parada $number · Saltada';
  }

  @override
  String routeMapStopVisited(int number) {
    return 'Parada $number · Visitada';
  }

  @override
  String routeMapSuggestedVisit(String duration) {
    return 'Visita sugerida: $duration';
  }

  @override
  String get routeMapTapStopHint => 'Toca una parada para ver su información';

  @override
  String get routeMapTips => 'Recomendaciones';

  @override
  String get routeMapTripComplete => '¡Recorrido completo!';

  @override
  String get routeMapTripEnded => 'Viaje finalizado';

  @override
  String get routeMapTurnOn => 'Activar';

  @override
  String get routeMapTurnOnPhoneLocation =>
      'Enciende la ubicación del teléfono para verte en el mapa';

  @override
  String routeMapVisitConfirmed(String name) {
    return '¡Visita a $name confirmada!';
  }

  @override
  String routeMapWhySkip(String name) {
    return '¿Por qué saltas $name?';
  }

  @override
  String get routeMapYouSkipped => 'La saltaste';

  @override
  String routeMapYouSkippedReason(String reason) {
    return 'La saltaste · $reason';
  }

  @override
  String get savedEmpty => 'Todavía no guardaste nada';

  @override
  String get savedEmptyMessage =>
      'Toca el marcador de un circuito, una parada o un evento y lo encontrarás aquí.';

  @override
  String get savedHeadline => 'Tus próximos descubrimientos';

  @override
  String get savedSectionPlaces => 'Lugares';

  @override
  String get settingsAccountAddName => 'Agrega tu nombre';

  @override
  String get settingsAccountChangePasswordSubtitle =>
      'Con tu contraseña actual';

  @override
  String get settingsAccountLoginEmail => 'Correo de acceso';

  @override
  String get settingsAccountNameRequired => 'Escribe tu nombre';

  @override
  String get settingsAccountNameTitle => 'Tu nombre';

  @override
  String get settingsAccountPersonalData => 'Datos personales';

  @override
  String get settingsAccountTitle => 'Cuenta';

  @override
  String get settingsAccountTwoFactorOff => 'Pide un código extra al entrar';

  @override
  String get settingsAccountTwoFactorOn => 'Activa';

  @override
  String get settingsAccountTwoFactorTitle => 'Verificación en dos pasos';

  @override
  String get settingsBookingHelpBody =>
      'En Mis viajes ves la fecha, la hora de salida, las personas y, si lo contrataste, tu guía. Antes de cancelar, revisa las condiciones del servicio en el detalle del circuito.';

  @override
  String get settingsBookingHelpHeading => 'Encuentra los detalles de tu viaje';

  @override
  String get settingsBookingHelpTitle => 'Ayuda con mi reserva';

  @override
  String get settingsBookingHelpViewTrips => 'Ver mis viajes';

  @override
  String get settingsChangePassword => 'Cambiar contraseña';

  @override
  String get settingsContactSupport => 'Contactar soporte';

  @override
  String get settingsDataUsageBody =>
      'La ubicación sirve para mostrarte en el mapa durante un recorrido; puedes apagarla en Privacidad. Tu correo y tu nombre se usan para gestionar tu cuenta y tus reservas.';

  @override
  String get settingsDataUsageHeading => 'Tú decides qué compartir';

  @override
  String get settingsDataUsageRightsBody =>
      'Puedes pedir una copia de tus datos o que los borremos escribiéndole al equipo de soporte.';

  @override
  String get settingsDataUsageRightsTitle => 'Tus derechos';

  @override
  String get settingsDataUsageTitle => 'Uso de tus datos';

  @override
  String get settingsDataUsageWriteSupport => 'Escribir a soporte';

  @override
  String get settingsHelpBookingSubtitle => 'Confirmaciones y cancelaciones';

  @override
  String get settingsHelpBookingTitle => 'Mi reserva';

  @override
  String get settingsHelpContactSubtitle => 'Cuéntanos qué ocurrió';

  @override
  String get settingsHelpHeading => '¿En qué podemos ayudarte?';

  @override
  String get settingsHelpPrivacySubtitle => 'Controles de tus datos';

  @override
  String get settingsHelpPrivacyTitle => 'Privacidad';

  @override
  String get settingsHelpTitle => 'Ayuda y soporte';

  @override
  String get settingsHomeAccount => 'Cuenta';

  @override
  String get settingsHomeAccountSubtitle => 'Datos y acceso';

  @override
  String get settingsHomeHelp => 'Ayuda y soporte';

  @override
  String get settingsHomeHelpSubtitle => 'Preguntas y contacto';

  @override
  String get settingsHomeNotificationsOff => 'Todos los avisos apagados';

  @override
  String get settingsHomeNotificationsOn => 'Viajes, reservas y eventos';

  @override
  String get settingsHomePrivacy => 'Privacidad y seguridad';

  @override
  String get settingsHomePrivacySubtitle => 'Ubicación y datos personales';

  @override
  String get settingsLogoutNote =>
      'Tus guardados y viajes siguen asociados a tu cuenta.';

  @override
  String get settingsLogoutTitle => '¿Cerrar tu sesión?';

  @override
  String get settingsNotificationsHeading => 'Mantente al tanto';

  @override
  String get settingsNotificationsPermissionNote =>
      'El permiso para mostrar notificaciones se cambia desde la configuración del teléfono.';

  @override
  String get settingsPasswordChangeCurrent => 'Contraseña actual';

  @override
  String get settingsPasswordChangeCurrentRequired =>
      'Escribe tu contraseña actual';

  @override
  String get settingsPasswordChangedDemoNote =>
      'Demostración: no hay un servidor que la guarde.';

  @override
  String get settingsPasswordChangedLogInAgain =>
      'Contraseña actualizada. Vuelve a entrar.';

  @override
  String get settingsPasswordChangedMessage => 'Tu contraseña nueva ya sirve.';

  @override
  String get settingsPasswordChangedTitle => 'Contraseña actualizada';

  @override
  String get settingsPasswordChangeIntro =>
      'Por seguridad, al cambiarla cerraremos tu sesión en todos tus dispositivos y tendrás que volver a entrar.';

  @override
  String get settingsPasswordChangeRepeat => 'Repite la contraseña nueva';

  @override
  String get settingsPasswordResetBackToAccount => 'Volver a Cuenta';

  @override
  String get settingsPrivacyAccountSecurity => 'Seguridad de la cuenta';

  @override
  String get settingsPrivacyDataUsageSubtitle => 'Información y controles';

  @override
  String get settingsPrivacyPersonalize => 'Personalizar recomendaciones';

  @override
  String get settingsPrivacyPersonalizeDescription =>
      'Según los circuitos que guardas y recorres';

  @override
  String get settingsPrivacyShowBadges => 'Mostrar insignias en mi perfil';

  @override
  String get settingsPrivacyTitle => 'Privacidad y seguridad';

  @override
  String get settingsPrivacyUseLocation => 'Usar ubicación al explorar';

  @override
  String get settingsPrivacyUseLocationDescription =>
      'Para verte en el mapa durante un recorrido';

  @override
  String get settingsSupportBackToHelp => 'Volver a Ayuda';

  @override
  String get settingsSupportDemoNote =>
      'Demostración: por ahora el mensaje no sale de tu teléfono.';

  @override
  String get settingsSupportMessage => 'Mensaje';

  @override
  String get settingsSupportMessageHint => 'Qué pasó, en qué circuito y cuándo';

  @override
  String get settingsSupportMessageRequired => 'Escribe tu mensaje';

  @override
  String settingsSupportReplyTo(String email) {
    return 'Te responderemos a $email.';
  }

  @override
  String get settingsSupportSend => 'Enviar consulta';

  @override
  String settingsSupportSentMessage(String email) {
    return 'El equipo de soporte te responderá a $email.';
  }

  @override
  String get settingsSupportSentPanelTitle => 'Tu consulta está lista';

  @override
  String get settingsSupportSentTitle => 'Consulta enviada';

  @override
  String get settingsSupportSubject => 'Asunto';

  @override
  String get settingsSupportSubjectHint => 'Ej. Consulta sobre mi reserva';

  @override
  String get settingsSupportSubjectRequired => 'Cuéntanos de qué se trata';

  @override
  String get sharedAddToCircuit => 'Añadir a un circuito';

  @override
  String get sharedAlwaysUseOption => 'Usar siempre esta opción';

  @override
  String sharedBadgeEarnedSubtitle(String category) {
    return '$category · ¡Sigue así!';
  }

  @override
  String get sharedBadgeEarnedTitle => '+1 insignia';

  @override
  String sharedChangeArrivalTime(String time) {
    return 'Cambiar hora de llegada, $time';
  }

  @override
  String get sharedCloseHint => 'cerrar';

  @override
  String get sharedContinueTrip => 'Seguir el viaje';

  @override
  String sharedCreativeBannerBody(String organizer) {
    return 'Lo creó la $organizer. Se hace en grupo: te inscribes en un horario publicado por un guía certificado.';
  }

  @override
  String get sharedCreativeBannerBodyNoOrganizer =>
      'Lo creó una alcaldía. Se hace en grupo: te inscribes en un horario publicado por un guía certificado.';

  @override
  String get sharedCreativeBannerTitle => 'Circuito creativo oficial';

  @override
  String get sharedCreativeCircuitBadge => 'Circuito creativo';

  @override
  String sharedCreativeCityMedal(String city) {
    return 'Medalla de $city';
  }

  @override
  String sharedCreativeExtraBadges(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '+$count insignias extra',
      one: '+1 insignia extra',
    );
    return '$_temp0';
  }

  @override
  String get sharedDirectionsWithTitle => 'Cómo llegar con...';

  @override
  String get sharedDragToReorder => 'Arrastrar para cambiar el orden';

  @override
  String get sharedDropWhyWeAsk =>
      'Nos ayuda a mejorar los circuitos y a que cada lugar sepa qué pasó.';

  @override
  String get sharedEndTrip => 'Finalizar';

  @override
  String get sharedFilterAll => 'Todas';

  @override
  String get sharedHidePassword => 'Ocultar contraseña';

  @override
  String get sharedHiredCoordinate =>
      'Coordina el punto de encuentro por el chat.';

  @override
  String get sharedHiredGoToChat => 'Ir al chat';

  @override
  String sharedHiredName(String name) {
    return '¡Contrataste a $name!';
  }

  @override
  String get sharedHiredTeamReady => '¡Tu equipo está listo!';

  @override
  String sharedItineraryEnds(String time) {
    return 'Termina aprox. $time';
  }

  @override
  String sharedItineraryFreeTime(String travel, String duration) {
    return '$travel · $duration libres';
  }

  @override
  String sharedItineraryTravelTime(String duration) {
    return '$duration de traslados';
  }

  @override
  String get sharedItineraryWarningsTitle => 'Para tener en cuenta';

  @override
  String get sharedMapStart => 'Inicio';

  @override
  String get sharedNationalityNoResults => 'No encontramos ese país';

  @override
  String get sharedNationalitySearchHint => 'Busca tu país';

  @override
  String get sharedNationalityTitle => 'Tu nacionalidad';

  @override
  String get sharedNavProfile => 'Perfil';

  @override
  String get sharedNewCircuitCreate => 'Crear';

  @override
  String get sharedNewCircuitEmpty => 'Ponle un nombre a tu circuito';

  @override
  String get sharedNewCircuitHint => 'Ej. Fin de semana en el sur';

  @override
  String get sharedNewCircuitTitle => 'Nuevo circuito';

  @override
  String get sharedNewCircuitTooShort => 'Usa al menos 3 caracteres';

  @override
  String sharedOpenAppFailed(String app) {
    return 'No se pudo abrir $app';
  }

  @override
  String get sharedOpenWithTitle => 'Abrir circuito con...';

  @override
  String get sharedRemoveFromSaved => 'Quitar de guardados';

  @override
  String get sharedReorderHint =>
      'Arrastra cada parada a su lugar. Los horarios del itinerario se recalculan solos.';

  @override
  String get sharedReorderSave => 'Guardar orden';

  @override
  String get sharedReorderTitle => 'Ordenar paradas';

  @override
  String sharedReviewsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '($count reseñas)',
      one: '(1 reseña)',
    );
    return '$_temp0';
  }

  @override
  String get sharedSearchByVoice => 'Buscar por voz';

  @override
  String get sharedShowPassword => 'Mostrar contraseña';

  @override
  String get sharedSkip => 'Saltar';

  @override
  String get sharedStopBadge => 'Insignia';

  @override
  String get sharedTimePickerHour => 'Hora';

  @override
  String get sharedTimePickerMinutes => 'Minutos';

  @override
  String get sharedTripAllStopsDone =>
      'Ya pasaste por todas las paradas. Toca Finalizar para cerrar el viaje.';

  @override
  String sharedTripArrivedAt(String time) {
    return 'Llegaste a las $time';
  }

  @override
  String sharedTripConflictBody(String title) {
    return 'Estás recorriendo $title. Sólo se puede seguir un circuito a la vez: finalízalo para comenzar este.';
  }

  @override
  String get sharedTripConflictEndAndStart => 'Finalizar ese y comenzar este';

  @override
  String get sharedTripConflictGoToActive => 'Ir al viaje en curso';

  @override
  String get sharedTripConflictTitle => 'Ya tienes un viaje en curso';

  @override
  String sharedTripDelayed(String duration) {
    return 'Vas $duration atrasado';
  }

  @override
  String get sharedTripEndSubtitle =>
      '¿Por qué no fuiste? Es opcional. Nos ayuda a mejorar los circuitos y a que cada lugar sepa qué pasó.';

  @override
  String sharedTripEndTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Te quedaron $count paradas sin visitar',
      one: 'Te quedó 1 parada sin visitar',
    );
    return '$_temp0';
  }

  @override
  String sharedTripInProgress(int checked, int total) {
    return 'Viaje en curso · $checked/$total paradas confirmadas';
  }

  @override
  String sharedTripNextDelay(String delay) {
    return 'Siguiente · $delay';
  }

  @override
  String sharedTripNextStop(String name, String time) {
    return 'Siguiente: $name · $time';
  }

  @override
  String get sharedTripOnTime => 'Vas a tiempo';

  @override
  String sharedTripSkippedReason(String reason) {
    return 'Saltada · $reason';
  }

  @override
  String get sharedVerificationCode => 'Código de verificación';

  @override
  String get stopDetailAddedToCircuit => 'Añadida a este circuito';

  @override
  String get stopDetailAddToCircuit => 'Añadir a un circuito';

  @override
  String stopDetailBadgeAwarded(String category) {
    return 'Esta parada otorga una insignia de $category';
  }

  @override
  String stopDetailBadgeEarned(String category) {
    return 'Insignia de $category obtenida';
  }

  @override
  String stopDetailCircuitCreated(String title) {
    return 'Circuito \"$title\" creado';
  }

  @override
  String get stopDetailConfirmed => '¡Parada confirmada!';

  @override
  String get stopDetailMoreOptions => 'Más opciones';

  @override
  String get stopDetailNewCircuit => 'Crear circuito nuevo';

  @override
  String get stopDetailNewCircuitHint => 'Y añadir esta parada ahí';

  @override
  String get stopDetailNoCircuits => 'Todavía no tienes circuitos';

  @override
  String stopDetailOpenHours(String hours) {
    return 'Abierto de $hours';
  }

  @override
  String get stopDetailQrAim => 'Apunta la cámara al código QR de la parada';

  @override
  String get stopDetailQrDemoHint =>
      'Escanéalo desde el detalle de esta parada para reclamar su insignia.';

  @override
  String get stopDetailQrDemoTitle => 'Código QR (demo)';

  @override
  String get stopDetailQrWrongStop => 'Ese código no es de esta parada';

  @override
  String get stopDetailSavedIn => 'Guardado en';

  @override
  String get stopDetailScanQr => 'Escanear código QR';

  @override
  String get stopDetailShowDemoQr => 'Ver código de prueba';

  @override
  String utilAdvisorAddTitle(String stop) {
    return 'Agregar $stop';
  }

  @override
  String utilAdvisorExtraInterestMessage(
    String slack,
    String category,
    String stop,
    String duration,
    String leg,
  ) {
    return 'Te sobra $slack en el día. Como te interesa $category, agrega $stop: $duration de visita, $leg.';
  }

  @override
  String utilAdvisorExtraMessage(
    String slack,
    String stop,
    String duration,
    String leg,
  ) {
    return 'Te sobra $slack en el día. Agrega $stop: $duration de visita, $leg.';
  }

  @override
  String get utilAdvisorFirstStopNote => 'es la primera parada';

  @override
  String utilAdvisorLunchMessage(String stop, String arrival, String leg) {
    return 'Tu día pasa por el mediodía y no tiene parada para comer. En $stop llegarías a las $arrival ($leg).';
  }

  @override
  String utilAdvisorLunchTitle(String stop) {
    return 'Almorzar en $stop';
  }

  @override
  String utilAdvisorRemoveClosedMessage(
    String stop,
    String closes,
    String departure,
  ) {
    return '$stop cierra a las $closes y no alcanzarías a visitarla: saldrías a las $departure';
  }

  @override
  String utilAdvisorRemoveEndsLateMessage(
    String lateEnd,
    String stop,
    String end,
  ) {
    return 'Terminarías a las $lateEnd, ya de noche. Si quitas $stop, terminas a las $end';
  }

  @override
  String utilAdvisorRemoveTitle(String stop) {
    return 'Quitar $stop';
  }

  @override
  String utilAdvisorRemoveTooLongMessage(
    String duration,
    String pace,
    String maxDuration,
    String stop,
    String end,
  ) {
    return 'Tu día duraría $duration y con ritmo $pace conviene no pasar de $maxDuration. Si quitas $stop, terminas a las $end';
  }

  @override
  String utilAdvisorReorderMessage(String saved) {
    return 'Si cambias el orden de las paradas ahorras $saved de traslado.';
  }

  @override
  String get utilAdvisorReorderTitle => 'Cambiar el orden';

  @override
  String utilAdvisorStartLaterMessage(
    String stop,
    String arrival,
    String opens,
    String startTime,
  ) {
    return 'Llegarías a $stop a las $arrival y abre a las $opens Si sales a las $startTime, llegas con todo abierto.';
  }

  @override
  String utilAdvisorStartLaterTitle(String startTime) {
    return 'Salir a las $startTime';
  }

  @override
  String get utilAdvisorToStartNote => 'para empezar';

  @override
  String utilAdvisorVehicleMessage(int count, String km, String saved) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Hay $count tramos',
      one: 'Hay un tramo',
    );
    return '$_temp0 de más de $km km a pie. En vehículo ahorras $saved y los cortos los sigues caminando.';
  }

  @override
  String get utilAdvisorVehicleTitle => 'Moverte en vehículo';

  @override
  String get utilMedalBronze => 'Bronce';

  @override
  String get utilMedalGold => 'Oro';

  @override
  String get utilMedalNone => 'Sin medalla';

  @override
  String get utilMedalSilver => 'Plata';

  @override
  String utilPlannerArrivesAfterClosing(
    String stop,
    String arrival,
    String closes,
  ) {
    return 'Llegarías a $stop a las $arrival, cuando ya cerró (cierra a las $closes).';
  }

  @override
  String utilPlannerArrivesBeforeOpening(
    String stop,
    String arrival,
    String opens,
  ) {
    return 'Llegarías a $stop a las $arrival y abre a las $opens';
  }

  @override
  String utilPlannerEndsLate(String end) {
    return 'Terminarías a las $end, ya de noche.';
  }

  @override
  String utilPlannerLeavesAfterClosing(
    String stop,
    String closes,
    String departure,
  ) {
    return '$stop cierra a las $closes y saldrías a las $departure';
  }

  @override
  String utilPlannerLongWalk(
    String origin,
    String destination,
    String distance,
    String duration,
  ) {
    return 'De $origin a $destination son $distance a pie ($duration). Si prefieres, haz ese tramo en taxi o en vehículo.';
  }

  @override
  String utilPlannerMissedTime(String stop, String fixed, String arrival) {
    return 'No alcanzas a llegar a $stop a las $fixed: llegarías a las $arrival.';
  }

  @override
  String get validatorEmailInvalid => 'El correo no es válido';

  @override
  String get validatorEmailRequired => 'Ingresa tu correo electrónico';

  @override
  String get validatorNewPasswordRules =>
      'Usa al menos 8 caracteres, una mayúscula y un número';

  @override
  String validatorPasswordMinLength(int count) {
    return 'Mínimo $count caracteres';
  }

  @override
  String get validatorPasswordRequired => 'Ingresa tu contraseña';

  @override
  String get validatorPhoneInvalid => 'El teléfono no es válido';

  @override
  String get validatorPhoneRequired => 'Ingresa un teléfono de contacto';

  @override
  String get validatorUsernameInvalid =>
      'De 3 a 20 letras, números, puntos o guiones bajos';

  @override
  String get validatorUsernameRequired => 'Ingresa un nombre de usuario';

  @override
  String get welcomeGuideSubtitle => 'Accede o postula tus servicios';

  @override
  String get welcomeSubtitle => 'Elige cómo quieres continuar.';

  @override
  String get welcomeTitle => 'Bienvenido';

  @override
  String get welcomeTouristSubtitle => 'Explora y organiza tus viajes';
}
