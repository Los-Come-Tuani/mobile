import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
  ];

  /// No description provided for @assistantAiTag.
  ///
  /// In es, this message translates to:
  /// **'IA'**
  String get assistantAiTag;

  /// No description provided for @assistantAllGood.
  ///
  /// In es, this message translates to:
  /// **'Así queda bien. ¿Lo guardamos?'**
  String get assistantAllGood;

  /// No description provided for @assistantAppliedAdd.
  ///
  /// In es, this message translates to:
  /// **'Agregaste {stop}'**
  String assistantAppliedAdd(String stop);

  /// No description provided for @assistantAppliedLunch.
  ///
  /// In es, this message translates to:
  /// **'Almuerzas en {stop}'**
  String assistantAppliedLunch(String stop);

  /// No description provided for @assistantAppliedRemove.
  ///
  /// In es, this message translates to:
  /// **'Quitaste {stop}'**
  String assistantAppliedRemove(String stop);

  /// No description provided for @assistantAppliedReorder.
  ///
  /// In es, this message translates to:
  /// **'Cambiaste el orden: ahorras {saved}'**
  String assistantAppliedReorder(String saved);

  /// No description provided for @assistantAppliedStartLater.
  ///
  /// In es, this message translates to:
  /// **'Sales a las {time}'**
  String assistantAppliedStartLater(String time);

  /// No description provided for @assistantAppliedVehicle.
  ///
  /// In es, this message translates to:
  /// **'Te mueves en vehículo'**
  String get assistantAppliedVehicle;

  /// No description provided for @assistantApply.
  ///
  /// In es, this message translates to:
  /// **'Aplicar'**
  String get assistantApply;

  /// No description provided for @assistantAskCity.
  ///
  /// In es, this message translates to:
  /// **'¿A qué ciudad vas?'**
  String get assistantAskCity;

  /// No description provided for @assistantAskInterests.
  ///
  /// In es, this message translates to:
  /// **'¿Qué te interesa más? Puedes elegir varias cosas.'**
  String get assistantAskInterests;

  /// No description provided for @assistantAskPace.
  ///
  /// In es, this message translates to:
  /// **'¿Cómo quieres tu día?'**
  String get assistantAskPace;

  /// No description provided for @assistantAskStartTime.
  ///
  /// In es, this message translates to:
  /// **'¿A qué hora quieres empezar?'**
  String get assistantAskStartTime;

  /// No description provided for @assistantDefaultTitle.
  ///
  /// In es, this message translates to:
  /// **'Mi día en {city}'**
  String assistantDefaultTitle(String city);

  /// No description provided for @assistantDismiss.
  ///
  /// In es, this message translates to:
  /// **'No, gracias'**
  String get assistantDismiss;

  /// No description provided for @assistantIntroCircuit.
  ///
  /// In es, this message translates to:
  /// **'¡Hola! Soy el asistente de K\'Plan. Voy a organizar \"{title}\" ({count, plural, =1{1 parada} other{{count} paradas}}) contando los traslados y los horarios de cada lugar.'**
  String assistantIntroCircuit(String title, int count);

  /// No description provided for @assistantIntroScratch.
  ///
  /// In es, this message translates to:
  /// **'¡Hola! Soy el asistente de K\'Plan. Te armo un día con horarios reales, contando los traslados entre cada lugar.'**
  String get assistantIntroScratch;

  /// No description provided for @assistantNoPreference.
  ///
  /// In es, this message translates to:
  /// **'Me da igual'**
  String get assistantNoPreference;

  /// No description provided for @assistantProposalCircuit.
  ///
  /// In es, this message translates to:
  /// **'Listo. Calculé cada traslado y la hora a la que llegas a tus {count, plural, =1{1 parada} other{{count} paradas}}.'**
  String assistantProposalCircuit(int count);

  /// No description provided for @assistantProposalEmpty.
  ///
  /// In es, this message translates to:
  /// **'No encontré paradas en {city} que quepan en tu día. Prueba con otro ritmo o una hora más temprano.'**
  String assistantProposalEmpty(String city);

  /// No description provided for @assistantProposalScratch.
  ///
  /// In es, this message translates to:
  /// **'Listo. Te armé un día en {city} con {count, plural, =1{1 parada} other{{count} paradas}}, en el orden que menos traslado pide.'**
  String assistantProposalScratch(String city, int count);

  /// No description provided for @assistantProposalTitle.
  ///
  /// In es, this message translates to:
  /// **'Tu día · {mode} · ritmo {pace}'**
  String assistantProposalTitle(String mode, String pace);

  /// No description provided for @assistantSave.
  ///
  /// In es, this message translates to:
  /// **'Guardar itinerario'**
  String get assistantSave;

  /// No description provided for @assistantSaved.
  ///
  /// In es, this message translates to:
  /// **'¡Listo! Guardamos tu itinerario'**
  String get assistantSaved;

  /// No description provided for @assistantSuggestionsIntro.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{Tengo 1 sugerencia para mejorarlo:} other{Tengo {count} sugerencias para mejorarlo:}}'**
  String assistantSuggestionsIntro(int count);

  /// No description provided for @assistantThinking.
  ///
  /// In es, this message translates to:
  /// **'Calculando traslados y horarios…'**
  String get assistantThinking;

  /// No description provided for @assistantTitle.
  ///
  /// In es, this message translates to:
  /// **'Asistente K\'Plan'**
  String get assistantTitle;

  /// No description provided for @bookingAdults.
  ///
  /// In es, this message translates to:
  /// **'Adultos'**
  String get bookingAdults;

  /// No description provided for @bookingBadges.
  ///
  /// In es, this message translates to:
  /// **'Insignias'**
  String get bookingBadges;

  /// No description provided for @bookingBadgesSoon.
  ///
  /// In es, this message translates to:
  /// **'Insignias: próximamente'**
  String get bookingBadgesSoon;

  /// No description provided for @bookingBudgetLine.
  ///
  /// In es, this message translates to:
  /// **'Presupuesto: {summary}'**
  String bookingBudgetLine(String summary);

  /// No description provided for @bookingChatEmpty.
  ///
  /// In es, this message translates to:
  /// **'Todavía no hay mensajes. Escribe para coordinar el punto de encuentro.'**
  String get bookingChatEmpty;

  /// No description provided for @bookingChatHint.
  ///
  /// In es, this message translates to:
  /// **'Escribe un mensaje'**
  String get bookingChatHint;

  /// No description provided for @bookingChatReadOnly.
  ///
  /// In es, this message translates to:
  /// **'La reserva se canceló: el chat quedó de solo lectura.'**
  String get bookingChatReadOnly;

  /// No description provided for @bookingChatSend.
  ///
  /// In es, this message translates to:
  /// **'Enviar'**
  String get bookingChatSend;

  /// No description provided for @bookingChatTitle.
  ///
  /// In es, this message translates to:
  /// **'Chat'**
  String get bookingChatTitle;

  /// No description provided for @bookingChildren.
  ///
  /// In es, this message translates to:
  /// **'Niños'**
  String get bookingChildren;

  /// No description provided for @bookingChildrenCount.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 niño} other{{count} niños}}'**
  String bookingChildrenCount(int count);

  /// No description provided for @bookingCircuitNotFound.
  ///
  /// In es, this message translates to:
  /// **'No encontramos este circuito'**
  String get bookingCircuitNotFound;

  /// No description provided for @bookingConfirmed.
  ///
  /// In es, this message translates to:
  /// **'¡Listo! Tu circuito quedó agendado'**
  String get bookingConfirmed;

  /// No description provided for @bookingConfirmedWithProposal.
  ///
  /// In es, this message translates to:
  /// **'¡Listo! Tu circuito quedó agendado y tu propuesta ya está publicada para los guías'**
  String get bookingConfirmedWithProposal;

  /// No description provided for @bookingDaySchedule.
  ///
  /// In es, this message translates to:
  /// **'Horario del día'**
  String get bookingDaySchedule;

  /// No description provided for @bookingDetailCancel.
  ///
  /// In es, this message translates to:
  /// **'Cancelar reserva'**
  String get bookingDetailCancel;

  /// No description provided for @bookingDetailCancelClosed.
  ///
  /// In es, this message translates to:
  /// **'El plazo para cancelar venció el {day} a las {time}.'**
  String bookingDetailCancelClosed(String day, String time);

  /// No description provided for @bookingDetailCancelled.
  ///
  /// In es, this message translates to:
  /// **'Reserva cancelada'**
  String get bookingDetailCancelled;

  /// No description provided for @bookingDetailCancelMessage.
  ///
  /// In es, this message translates to:
  /// **'Si ya pagaste, el equipo de K\'Plan te devolverá el dinero.'**
  String get bookingDetailCancelMessage;

  /// No description provided for @bookingDetailCancelReasonHint.
  ///
  /// In es, this message translates to:
  /// **'Cuéntale al turista por qué'**
  String get bookingDetailCancelReasonHint;

  /// No description provided for @bookingDetailCancelReasonRequired.
  ///
  /// In es, this message translates to:
  /// **'Escribe el motivo'**
  String get bookingDetailCancelReasonRequired;

  /// No description provided for @bookingDetailCancelTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Cancelar la reserva?'**
  String get bookingDetailCancelTitle;

  /// No description provided for @bookingDetailCancelUntil.
  ///
  /// In es, this message translates to:
  /// **'Puedes cancelar gratis hasta el {day} a las {time}.'**
  String bookingDetailCancelUntil(String day, String time);

  /// No description provided for @bookingDetailChatWithGuide.
  ///
  /// In es, this message translates to:
  /// **'Escribirle al guía'**
  String get bookingDetailChatWithGuide;

  /// No description provided for @bookingDetailChatWithTourist.
  ///
  /// In es, this message translates to:
  /// **'Escribirle al turista'**
  String get bookingDetailChatWithTourist;

  /// No description provided for @bookingDetailConfirmedTitle.
  ///
  /// In es, this message translates to:
  /// **'¡Reserva confirmada!'**
  String get bookingDetailConfirmedTitle;

  /// No description provided for @bookingDetailFinish.
  ///
  /// In es, this message translates to:
  /// **'Terminar el recorrido'**
  String get bookingDetailFinish;

  /// No description provided for @bookingDetailFinished.
  ///
  /// In es, this message translates to:
  /// **'Recorrido terminado. Cuando el pago esté confirmado, entra a tu saldo.'**
  String get bookingDetailFinished;

  /// No description provided for @bookingDetailHowToPay.
  ///
  /// In es, this message translates to:
  /// **'Cómo pagar'**
  String get bookingDetailHowToPay;

  /// No description provided for @bookingDetailKeep.
  ///
  /// In es, this message translates to:
  /// **'Mantenerla'**
  String get bookingDetailKeep;

  /// No description provided for @bookingDetailOpen.
  ///
  /// In es, this message translates to:
  /// **'Ver mi reserva'**
  String get bookingDetailOpen;

  /// No description provided for @bookingDetailPaymentManual.
  ///
  /// In es, this message translates to:
  /// **'El equipo de K\'Plan confirma tu pago a mano y te avisa cuando quede listo.'**
  String get bookingDetailPaymentManual;

  /// No description provided for @bookingDetailPaymentTitle.
  ///
  /// In es, this message translates to:
  /// **'Pago'**
  String get bookingDetailPaymentTitle;

  /// No description provided for @bookingDetailStart.
  ///
  /// In es, this message translates to:
  /// **'Iniciar el recorrido'**
  String get bookingDetailStart;

  /// No description provided for @bookingDetailStarted.
  ///
  /// In es, this message translates to:
  /// **'Recorrido en curso'**
  String get bookingDetailStarted;

  /// No description provided for @bookingDetailStatus.
  ///
  /// In es, this message translates to:
  /// **'Estado: {status}'**
  String bookingDetailStatus(String status);

  /// No description provided for @bookingDetailsTitle.
  ///
  /// In es, this message translates to:
  /// **'Detalles de la reserva'**
  String get bookingDetailsTitle;

  /// No description provided for @bookingDetailTitle.
  ///
  /// In es, this message translates to:
  /// **'Tu reserva'**
  String get bookingDetailTitle;

  /// No description provided for @bookingDetailWasCancelled.
  ///
  /// In es, this message translates to:
  /// **'Esta reserva se canceló.'**
  String get bookingDetailWasCancelled;

  /// No description provided for @bookingDetailWasCancelledBecause.
  ///
  /// In es, this message translates to:
  /// **'Esta reserva se canceló: {reason}'**
  String bookingDetailWasCancelledBecause(String reason);

  /// No description provided for @bookingDurationEnds.
  ///
  /// In es, this message translates to:
  /// **'{duration} · termina aprox. a las {time}'**
  String bookingDurationEnds(String duration, String time);

  /// No description provided for @bookingEstimatedDuration.
  ///
  /// In es, this message translates to:
  /// **'Duración estimada'**
  String get bookingEstimatedDuration;

  /// No description provided for @bookingGoBack.
  ///
  /// In es, this message translates to:
  /// **'Volver'**
  String get bookingGoBack;

  /// No description provided for @bookingGroup.
  ///
  /// In es, this message translates to:
  /// **'Grupo'**
  String get bookingGroup;

  /// No description provided for @bookingGuideOrTranslator.
  ///
  /// In es, this message translates to:
  /// **'Guía o traductor'**
  String get bookingGuideOrTranslator;

  /// No description provided for @bookingGuideRowAdd.
  ///
  /// In es, this message translates to:
  /// **'Agregar'**
  String get bookingGuideRowAdd;

  /// No description provided for @bookingGuideSummary.
  ///
  /// In es, this message translates to:
  /// **'{need} · {hours}h'**
  String bookingGuideSummary(String need, int hours);

  /// No description provided for @bookingIncludes.
  ///
  /// In es, this message translates to:
  /// **'Incluye'**
  String get bookingIncludes;

  /// No description provided for @bookingItineraryNotSaved.
  ///
  /// In es, this message translates to:
  /// **'Tu circuito todavía no se guardó en tu cuenta. Revisa tu conexión e intenta de nuevo.'**
  String get bookingItineraryNotSaved;

  /// No description provided for @bookingMeetingPoint.
  ///
  /// In es, this message translates to:
  /// **'Punto de encuentro'**
  String get bookingMeetingPoint;

  /// No description provided for @bookingNeedBilingualSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Te explica todo el recorrido en tu idioma.'**
  String get bookingNeedBilingualSubtitle;

  /// No description provided for @bookingNeedBilingualTitle.
  ///
  /// In es, this message translates to:
  /// **'Guía que habla tu idioma'**
  String get bookingNeedBilingualTitle;

  /// No description provided for @bookingNeedGuideTranslatorSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Un guía local y alguien que te traduce en el momento.'**
  String get bookingNeedGuideTranslatorSubtitle;

  /// No description provided for @bookingNeedGuideTranslatorTitle.
  ///
  /// In es, this message translates to:
  /// **'Guía local + traductor'**
  String get bookingNeedGuideTranslatorTitle;

  /// No description provided for @bookingNeedLocalGuideSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Te da el recorrido en español.'**
  String get bookingNeedLocalGuideSubtitle;

  /// No description provided for @bookingNeedTranslatorOnlySubtitle.
  ///
  /// In es, this message translates to:
  /// **'Recorres por tu cuenta con alguien que te traduce.'**
  String get bookingNeedTranslatorOnlySubtitle;

  /// No description provided for @bookingNeedTranslatorOnlyTitle.
  ///
  /// In es, this message translates to:
  /// **'Solo traductor'**
  String get bookingNeedTranslatorOnlyTitle;

  /// No description provided for @bookingNoGuideOrTranslator.
  ///
  /// In es, this message translates to:
  /// **'Sin guía ni traductor'**
  String get bookingNoGuideOrTranslator;

  /// No description provided for @bookingOwnCircuitNote.
  ///
  /// In es, this message translates to:
  /// **'Lo armaste tú, así que no tiene precio por persona: sólo pagas el guía o traductor que contrates.'**
  String get bookingOwnCircuitNote;

  /// No description provided for @bookingProposalBudget.
  ///
  /// In es, this message translates to:
  /// **'Presupuesto que ofreces'**
  String get bookingProposalBudget;

  /// No description provided for @bookingProposalBudgetHint.
  ///
  /// In es, this message translates to:
  /// **'Cada guía lo acepta o propone su precio al postularse.'**
  String get bookingProposalBudgetHint;

  /// No description provided for @bookingProposalDuration.
  ///
  /// In es, this message translates to:
  /// **'Duración del servicio'**
  String get bookingProposalDuration;

  /// No description provided for @bookingProposalFewerHours.
  ///
  /// In es, this message translates to:
  /// **'Menos horas'**
  String get bookingProposalFewerHours;

  /// No description provided for @bookingProposalIntro.
  ///
  /// In es, this message translates to:
  /// **'Los guías verán tu propuesta y se postularán. Tú revisas sus perfiles y eliges a quién contratar.'**
  String get bookingProposalIntro;

  /// No description provided for @bookingProposalItineraryLasts.
  ///
  /// In es, this message translates to:
  /// **'Tu itinerario dura {duration}.'**
  String bookingProposalItineraryLasts(String duration);

  /// No description provided for @bookingProposalLodgingHint.
  ///
  /// In es, this message translates to:
  /// **'Más de un día de recorrido: si le das alojamiento, el precio baja.'**
  String get bookingProposalLodgingHint;

  /// No description provided for @bookingProposalLodgingTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Le darás alojamiento al guía?'**
  String get bookingProposalLodgingTitle;

  /// No description provided for @bookingProposalMinHoursGuide.
  ///
  /// In es, this message translates to:
  /// **'Mínimo {hours} horas con guía.'**
  String bookingProposalMinHoursGuide(int hours);

  /// No description provided for @bookingProposalMinHoursTranslator.
  ///
  /// In es, this message translates to:
  /// **'Mínimo {hours} horas sólo con traductor.'**
  String bookingProposalMinHoursTranslator(int hours);

  /// No description provided for @bookingProposalMoreHours.
  ///
  /// In es, this message translates to:
  /// **'Más horas'**
  String get bookingProposalMoreHours;

  /// No description provided for @bookingProposalNote.
  ///
  /// In es, this message translates to:
  /// **'Al agendar publicamos tu propuesta: los guías se postulan y tú eliges a quién contratar.'**
  String get bookingProposalNote;

  /// No description provided for @bookingProposalTitle.
  ///
  /// In es, this message translates to:
  /// **'Propuesta para guía o traductor'**
  String get bookingProposalTitle;

  /// No description provided for @bookingProposalTransport.
  ///
  /// In es, this message translates to:
  /// **'Transporte'**
  String get bookingProposalTransport;

  /// No description provided for @bookingProposalVehicleWarning.
  ///
  /// In es, this message translates to:
  /// **'Este recorrido se hace en vehículo: a pie hay tramos muy largos y el día no alcanza.'**
  String get bookingProposalVehicleWarning;

  /// No description provided for @bookingProposalWhatYouNeed.
  ///
  /// In es, this message translates to:
  /// **'¿Qué necesitas?'**
  String get bookingProposalWhatYouNeed;

  /// No description provided for @bookingProposalYourLanguage.
  ///
  /// In es, this message translates to:
  /// **'Tu idioma'**
  String get bookingProposalYourLanguage;

  /// No description provided for @bookingRecommendations.
  ///
  /// In es, this message translates to:
  /// **'Recomendaciones'**
  String get bookingRecommendations;

  /// No description provided for @bookingRemove.
  ///
  /// In es, this message translates to:
  /// **'Quitar'**
  String get bookingRemove;

  /// No description provided for @bookingRequestPublished.
  ///
  /// In es, this message translates to:
  /// **'Publicamos tu convocatoria: los guías se postularán con su precio y tú eliges.'**
  String get bookingRequestPublished;

  /// No description provided for @bookingReviewCommentHint.
  ///
  /// In es, this message translates to:
  /// **'Cuenta cómo fue el recorrido: puntualidad, trato, lo que aprendiste'**
  String get bookingReviewCommentHint;

  /// No description provided for @bookingReviewDone.
  ///
  /// In es, this message translates to:
  /// **'Ya dejaste tu reseña. ¡Gracias!'**
  String get bookingReviewDone;

  /// No description provided for @bookingReviewQuestion.
  ///
  /// In es, this message translates to:
  /// **'¿Cómo te fue con {name}?'**
  String bookingReviewQuestion(String name);

  /// No description provided for @bookingReviewSent.
  ///
  /// In es, this message translates to:
  /// **'Reseña publicada. ¡Gracias!'**
  String get bookingReviewSent;

  /// No description provided for @bookingReviewVisibility.
  ///
  /// In es, this message translates to:
  /// **'Tu reseña se publica al instante en el perfil del guía.'**
  String get bookingReviewVisibility;

  /// No description provided for @bookingScheduleSummary.
  ///
  /// In es, this message translates to:
  /// **'Saliendo a las {start} · {mode} · termina aprox. a las {end}'**
  String bookingScheduleSummary(String start, String mode, String end);

  /// No description provided for @bookingServiceFee.
  ///
  /// In es, this message translates to:
  /// **'Servicio (20%)'**
  String get bookingServiceFee;

  /// No description provided for @bookingStartTime.
  ///
  /// In es, this message translates to:
  /// **'Hora inicial'**
  String get bookingStartTime;

  /// No description provided for @bookingSubtotal.
  ///
  /// In es, this message translates to:
  /// **'Subtotal'**
  String get bookingSubtotal;

  /// No description provided for @bookingTitle.
  ///
  /// In es, this message translates to:
  /// **'Agendar'**
  String get bookingTitle;

  /// No description provided for @bookingTourInfoTitle.
  ///
  /// In es, this message translates to:
  /// **'Información del recorrido'**
  String get bookingTourInfoTitle;

  /// No description provided for @bookingTourNotes.
  ///
  /// In es, this message translates to:
  /// **'Notas del recorrido'**
  String get bookingTourNotes;

  /// No description provided for @bookingTransportGuide.
  ///
  /// In es, this message translates to:
  /// **'Que lo ponga el guía'**
  String get bookingTransportGuide;

  /// No description provided for @bookingTransportOnFoot.
  ///
  /// In es, this message translates to:
  /// **'A pie'**
  String get bookingTransportOnFoot;

  /// No description provided for @bookingTransportTourist.
  ///
  /// In es, this message translates to:
  /// **'Yo pongo el transporte'**
  String get bookingTransportTourist;

  /// No description provided for @categoryAdventure.
  ///
  /// In es, this message translates to:
  /// **'Aventura'**
  String get categoryAdventure;

  /// No description provided for @categoryCity.
  ///
  /// In es, this message translates to:
  /// **'Ciudad'**
  String get categoryCity;

  /// No description provided for @categoryCulture.
  ///
  /// In es, this message translates to:
  /// **'Cultura'**
  String get categoryCulture;

  /// No description provided for @categoryFair.
  ///
  /// In es, this message translates to:
  /// **'Feria'**
  String get categoryFair;

  /// No description provided for @categoryFood.
  ///
  /// In es, this message translates to:
  /// **'Gastronomía'**
  String get categoryFood;

  /// No description provided for @categoryHistory.
  ///
  /// In es, this message translates to:
  /// **'Historia'**
  String get categoryHistory;

  /// No description provided for @categoryNature.
  ///
  /// In es, this message translates to:
  /// **'Naturaleza'**
  String get categoryNature;

  /// No description provided for @categoryTradition.
  ///
  /// In es, this message translates to:
  /// **'Tradición'**
  String get categoryTradition;

  /// No description provided for @circuitDetailAllReviewsSoon.
  ///
  /// In es, this message translates to:
  /// **'Todas las reseñas: próximamente'**
  String get circuitDetailAllReviewsSoon;

  /// No description provided for @circuitDetailBadgesCount.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 insignia} other{{count} insignias}}'**
  String circuitDetailBadgesCount(int count);

  /// No description provided for @circuitDetailBook.
  ///
  /// In es, this message translates to:
  /// **'Agendar circuito'**
  String get circuitDetailBook;

  /// No description provided for @circuitDetailCommentsTitle.
  ///
  /// In es, this message translates to:
  /// **'Comentarios ({count})'**
  String circuitDetailCommentsTitle(int count);

  /// No description provided for @circuitDetailDownloadSoon.
  ///
  /// In es, this message translates to:
  /// **'Descargar sin conexión: próximamente'**
  String get circuitDetailDownloadSoon;

  /// No description provided for @circuitDetailDownloadTooltip.
  ///
  /// In es, this message translates to:
  /// **'Descargar sin conexión'**
  String get circuitDetailDownloadTooltip;

  /// No description provided for @circuitDetailLeavingAt.
  ///
  /// In es, this message translates to:
  /// **'Si sales a las…'**
  String get circuitDetailLeavingAt;

  /// No description provided for @circuitDetailOrderSaved.
  ///
  /// In es, this message translates to:
  /// **'Orden guardado: el itinerario se recalculó'**
  String get circuitDetailOrderSaved;

  /// No description provided for @circuitDetailPricePerAdult.
  ///
  /// In es, this message translates to:
  /// **'{price} p. adulta'**
  String circuitDetailPricePerAdult(String price);

  /// No description provided for @circuitDetailReorder.
  ///
  /// In es, this message translates to:
  /// **'Ordenar'**
  String get circuitDetailReorder;

  /// No description provided for @circuitDetailSeeAll.
  ///
  /// In es, this message translates to:
  /// **'Ver todos'**
  String get circuitDetailSeeAll;

  /// No description provided for @circuitDetailSeeTimes.
  ///
  /// In es, this message translates to:
  /// **'Ver horarios disponibles'**
  String get circuitDetailSeeTimes;

  /// No description provided for @circuitDetailSkipWhy.
  ///
  /// In es, this message translates to:
  /// **'¿Por qué saltas {stop}?'**
  String circuitDetailSkipWhy(String stop);

  /// No description provided for @circuitDetailStartTrip.
  ///
  /// In es, this message translates to:
  /// **'Comenzar viaje'**
  String get circuitDetailStartTrip;

  /// No description provided for @circuitDetailStopsCount.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 parada} other{{count} paradas}}'**
  String circuitDetailStopsCount(int count);

  /// No description provided for @circuitDetailStopsTitle.
  ///
  /// In es, this message translates to:
  /// **'Paradas del recorrido ({count})'**
  String circuitDetailStopsTitle(int count);

  /// No description provided for @circuitDetailTodayRoute.
  ///
  /// In es, this message translates to:
  /// **'Tu recorrido de hoy'**
  String get circuitDetailTodayRoute;

  /// No description provided for @circuitDetailTripEnded.
  ///
  /// In es, this message translates to:
  /// **'Viaje finalizado'**
  String get circuitDetailTripEnded;

  /// No description provided for @circuitDetailTripStarted.
  ///
  /// In es, this message translates to:
  /// **'¡Viaje iniciado! Dirígete a {stop}'**
  String circuitDetailTripStarted(String stop);

  /// No description provided for @commonAccept.
  ///
  /// In es, this message translates to:
  /// **'Aceptar'**
  String get commonAccept;

  /// No description provided for @commonBack.
  ///
  /// In es, this message translates to:
  /// **'Regresar'**
  String get commonBack;

  /// No description provided for @commonBackToHome.
  ///
  /// In es, this message translates to:
  /// **'Volver al inicio'**
  String get commonBackToHome;

  /// No description provided for @commonBirthDate.
  ///
  /// In es, this message translates to:
  /// **'Fecha de nacimiento'**
  String get commonBirthDate;

  /// No description provided for @commonCancel.
  ///
  /// In es, this message translates to:
  /// **'Cancelar'**
  String get commonCancel;

  /// No description provided for @commonChangePassword.
  ///
  /// In es, this message translates to:
  /// **'Cambiar contraseña'**
  String get commonChangePassword;

  /// No description provided for @commonChooseCountry.
  ///
  /// In es, this message translates to:
  /// **'Elige tu país'**
  String get commonChooseCountry;

  /// No description provided for @commonClose.
  ///
  /// In es, this message translates to:
  /// **'Cerrar'**
  String get commonClose;

  /// No description provided for @commonContinue.
  ///
  /// In es, this message translates to:
  /// **'Continuar'**
  String get commonContinue;

  /// No description provided for @commonCoupons.
  ///
  /// In es, this message translates to:
  /// **'Cupones'**
  String get commonCoupons;

  /// No description provided for @commonCreateAccount.
  ///
  /// In es, this message translates to:
  /// **'Crear cuenta'**
  String get commonCreateAccount;

  /// No description provided for @commonCreativeCircuits.
  ///
  /// In es, this message translates to:
  /// **'Circuitos creativos'**
  String get commonCreativeCircuits;

  /// No description provided for @commonDate.
  ///
  /// In es, this message translates to:
  /// **'Fecha'**
  String get commonDate;

  /// No description provided for @commonDone.
  ///
  /// In es, this message translates to:
  /// **'Listo'**
  String get commonDone;

  /// No description provided for @commonEmail.
  ///
  /// In es, this message translates to:
  /// **'Correo electrónico'**
  String get commonEmail;

  /// No description provided for @commonFullName.
  ///
  /// In es, this message translates to:
  /// **'Nombre completo'**
  String get commonFullName;

  /// No description provided for @commonGuide.
  ///
  /// In es, this message translates to:
  /// **'Guía'**
  String get commonGuide;

  /// No description provided for @commonHome.
  ///
  /// In es, this message translates to:
  /// **'Inicio'**
  String get commonHome;

  /// No description provided for @commonLocalGuide.
  ///
  /// In es, this message translates to:
  /// **'Guía local'**
  String get commonLocalGuide;

  /// No description provided for @commonLogout.
  ///
  /// In es, this message translates to:
  /// **'Cerrar sesión'**
  String get commonLogout;

  /// No description provided for @commonMyCircuits.
  ///
  /// In es, this message translates to:
  /// **'Mis circuitos'**
  String get commonMyCircuits;

  /// No description provided for @commonMyMedals.
  ///
  /// In es, this message translates to:
  /// **'Mis medallas'**
  String get commonMyMedals;

  /// No description provided for @commonMyTrips.
  ///
  /// In es, this message translates to:
  /// **'Mis viajes'**
  String get commonMyTrips;

  /// No description provided for @commonNationality.
  ///
  /// In es, this message translates to:
  /// **'Nacionalidad'**
  String get commonNationality;

  /// No description provided for @commonNewPassword.
  ///
  /// In es, this message translates to:
  /// **'Contraseña nueva'**
  String get commonNewPassword;

  /// No description provided for @commonNewPasswordHelper.
  ///
  /// In es, this message translates to:
  /// **'Usa al menos 8 caracteres, una mayúscula y un número.'**
  String get commonNewPasswordHelper;

  /// No description provided for @commonNext.
  ///
  /// In es, this message translates to:
  /// **'Siguiente'**
  String get commonNext;

  /// No description provided for @commonNotifications.
  ///
  /// In es, this message translates to:
  /// **'Notificaciones'**
  String get commonNotifications;

  /// No description provided for @commonPassword.
  ///
  /// In es, this message translates to:
  /// **'Contraseña'**
  String get commonPassword;

  /// No description provided for @commonPasswordsDontMatch.
  ///
  /// In es, this message translates to:
  /// **'Las contraseñas no coinciden'**
  String get commonPasswordsDontMatch;

  /// No description provided for @commonRepeatPassword.
  ///
  /// In es, this message translates to:
  /// **'Repite la contraseña'**
  String get commonRepeatPassword;

  /// No description provided for @commonResendCode.
  ///
  /// In es, this message translates to:
  /// **'Reenviar código'**
  String get commonResendCode;

  /// No description provided for @commonRetry.
  ///
  /// In es, this message translates to:
  /// **'Reintentar'**
  String get commonRetry;

  /// No description provided for @commonSave.
  ///
  /// In es, this message translates to:
  /// **'Guardar'**
  String get commonSave;

  /// No description provided for @commonSaved.
  ///
  /// In es, this message translates to:
  /// **'Guardados'**
  String get commonSaved;

  /// No description provided for @commonSeeOnMap.
  ///
  /// In es, this message translates to:
  /// **'Ver en el mapa'**
  String get commonSeeOnMap;

  /// No description provided for @commonSettings.
  ///
  /// In es, this message translates to:
  /// **'Configuraciones'**
  String get commonSettings;

  /// No description provided for @commonSomethingWentWrong.
  ///
  /// In es, this message translates to:
  /// **'Algo salió mal, intenta de nuevo'**
  String get commonSomethingWentWrong;

  /// No description provided for @commonTotal.
  ///
  /// In es, this message translates to:
  /// **'Total'**
  String get commonTotal;

  /// No description provided for @commonTourist.
  ///
  /// In es, this message translates to:
  /// **'Turista'**
  String get commonTourist;

  /// No description provided for @commonTranslator.
  ///
  /// In es, this message translates to:
  /// **'Traductor'**
  String get commonTranslator;

  /// No description provided for @commonViewProfile.
  ///
  /// In es, this message translates to:
  /// **'Ver perfil'**
  String get commonViewProfile;

  /// No description provided for @couponsBalanceLabel.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, other{insignias disponibles para canjear}}'**
  String couponsBalanceLabel(int count);

  /// No description provided for @couponsRedeemButton.
  ///
  /// In es, this message translates to:
  /// **'CANJEAR'**
  String get couponsRedeemButton;

  /// No description provided for @couponsRedeemConfirm.
  ///
  /// In es, this message translates to:
  /// **'Canjear'**
  String get couponsRedeemConfirm;

  /// No description provided for @couponsRedeemed.
  ///
  /// In es, this message translates to:
  /// **'¡Cupón canjeado! Muéstralo al reservar.'**
  String get couponsRedeemed;

  /// No description provided for @couponsRedeemedLabel.
  ///
  /// In es, this message translates to:
  /// **'Canjeado'**
  String get couponsRedeemedLabel;

  /// No description provided for @couponsRedeemFailed.
  ///
  /// In es, this message translates to:
  /// **'No se pudo canjear el cupón'**
  String get couponsRedeemFailed;

  /// No description provided for @couponsRedeemMessage.
  ///
  /// In es, this message translates to:
  /// **'{cost, plural, =1{Se descontará 1 insignia de tu saldo.} other{Se descontarán {cost} insignias de tu saldo.}}'**
  String couponsRedeemMessage(int cost);

  /// No description provided for @couponsRedeemTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Canjear \"{title}\"?'**
  String couponsRedeemTitle(String title);

  /// No description provided for @eventDetailFreeEntry.
  ///
  /// In es, this message translates to:
  /// **'Entrada libre'**
  String get eventDetailFreeEntry;

  /// No description provided for @forgotPasswordCodeMissing.
  ///
  /// In es, this message translates to:
  /// **'Escribe el código de 6 dígitos que te llegó al correo.'**
  String get forgotPasswordCodeMissing;

  /// No description provided for @forgotPasswordCodeResent.
  ///
  /// In es, this message translates to:
  /// **'Si pasó un minuto desde el último, te enviamos otro código.'**
  String get forgotPasswordCodeResent;

  /// No description provided for @forgotPasswordCodeSentTo.
  ///
  /// In es, this message translates to:
  /// **'Si {email} tiene una cuenta, le enviamos un código de 6 dígitos. Vence en 15 minutos.'**
  String forgotPasswordCodeSentTo(String email);

  /// No description provided for @forgotPasswordCodeSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Ingresa tu correo y te enviaremos un código de 6 dígitos.'**
  String get forgotPasswordCodeSubtitle;

  /// No description provided for @forgotPasswordCodeTitle.
  ///
  /// In es, this message translates to:
  /// **'Escribe el código'**
  String get forgotPasswordCodeTitle;

  /// No description provided for @forgotPasswordDemoNote.
  ///
  /// In es, this message translates to:
  /// **'Demostración: todavía no se envían correos; sirve cualquier código de 6 dígitos.'**
  String get forgotPasswordDemoNote;

  /// No description provided for @forgotPasswordSendCode.
  ///
  /// In es, this message translates to:
  /// **'Enviar código'**
  String get forgotPasswordSendCode;

  /// No description provided for @forgotPasswordTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Olvidaste tu contraseña?'**
  String get forgotPasswordTitle;

  /// No description provided for @forgotPasswordUpdated.
  ///
  /// In es, this message translates to:
  /// **'Contraseña actualizada. Entra con la nueva.'**
  String get forgotPasswordUpdated;

  /// No description provided for @forgotPasswordUseAnotherEmail.
  ///
  /// In es, this message translates to:
  /// **'Usar otro correo'**
  String get forgotPasswordUseAnotherEmail;

  /// No description provided for @formatAdults.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{adulto x {count}} other{adultos x {count}}}'**
  String formatAdults(int count);

  /// No description provided for @formatAm.
  ///
  /// In es, this message translates to:
  /// **'a.m.'**
  String get formatAm;

  /// No description provided for @formatChildren.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{niño x {count}} other{niños x {count}}}'**
  String formatChildren(int count);

  /// No description provided for @formatCompactDate.
  ///
  /// In es, this message translates to:
  /// **'{weekday} {dayAndMonth}'**
  String formatCompactDate(String weekday, String dayAndMonth);

  /// No description provided for @formatDayAndMonth.
  ///
  /// In es, this message translates to:
  /// **'{day} {month}'**
  String formatDayAndMonth(int day, String month);

  /// No description provided for @formatDaysAgo.
  ///
  /// In es, this message translates to:
  /// **'{days, plural, =1{hace 1 día} other{hace {days} días}}'**
  String formatDaysAgo(int days);

  /// No description provided for @formatHoursAgo.
  ///
  /// In es, this message translates to:
  /// **'hace {hours} h'**
  String formatHoursAgo(int hours);

  /// No description provided for @formatLessThanOneMinute.
  ///
  /// In es, this message translates to:
  /// **'menos de 1 min'**
  String get formatLessThanOneMinute;

  /// No description provided for @formatMinutesAgo.
  ///
  /// In es, this message translates to:
  /// **'hace {minutes} min'**
  String formatMinutesAgo(int minutes);

  /// No description provided for @formatNoPeople.
  ///
  /// In es, this message translates to:
  /// **'Sin personas'**
  String get formatNoPeople;

  /// No description provided for @formatNow.
  ///
  /// In es, this message translates to:
  /// **'ahora'**
  String get formatNow;

  /// No description provided for @formatPeople.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{{count} persona} other{{count} personas}}'**
  String formatPeople(int count);

  /// No description provided for @formatPm.
  ///
  /// In es, this message translates to:
  /// **'p.m.'**
  String get formatPm;

  /// No description provided for @formatShortDate.
  ///
  /// In es, this message translates to:
  /// **'{day} {month} {year}'**
  String formatShortDate(int day, String month, int year);

  /// No description provided for @formatToday.
  ///
  /// In es, this message translates to:
  /// **'Hoy'**
  String get formatToday;

  /// No description provided for @formatTomorrow.
  ///
  /// In es, this message translates to:
  /// **'Mañana'**
  String get formatTomorrow;

  /// No description provided for @formatWeekdayDate.
  ///
  /// In es, this message translates to:
  /// **'{weekday} {dayAndMonth}'**
  String formatWeekdayDate(String weekday, String dayAndMonth);

  /// No description provided for @formatYesterday.
  ///
  /// In es, this message translates to:
  /// **'Ayer'**
  String get formatYesterday;

  /// No description provided for @groupSlotsAdultsLine.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 adulto} other{{count} adultos}} × {price}'**
  String groupSlotsAdultsLine(int count, String price);

  /// No description provided for @groupSlotsCertifiedGuide.
  ///
  /// In es, this message translates to:
  /// **'Guía certificado'**
  String get groupSlotsCertifiedGuide;

  /// No description provided for @groupSlotsChildrenLine.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 niño} other{{count} niños}} × {price}'**
  String groupSlotsChildrenLine(int count, String price);

  /// No description provided for @groupSlotsConfirm.
  ///
  /// In es, this message translates to:
  /// **'Confirmar'**
  String get groupSlotsConfirm;

  /// No description provided for @groupSlotsDuration.
  ///
  /// In es, this message translates to:
  /// **'Duración: {duration}'**
  String groupSlotsDuration(String duration);

  /// No description provided for @groupSlotsEmpty.
  ///
  /// In es, this message translates to:
  /// **'Todavía no hay horarios publicados para este circuito. Vuelve a revisar pronto.'**
  String get groupSlotsEmpty;

  /// No description provided for @groupSlotsEndsAround.
  ///
  /// In es, this message translates to:
  /// **'Termina aprox. {time}'**
  String groupSlotsEndsAround(String time);

  /// No description provided for @groupSlotsEnrolled.
  ///
  /// In es, this message translates to:
  /// **'¡Listo! Tu grupo quedó inscrito el {date}, {time}'**
  String groupSlotsEnrolled(String date, String time);

  /// No description provided for @groupSlotsEnrolledWithGroup.
  ///
  /// In es, this message translates to:
  /// **'Inscrito con tu grupo · {people}'**
  String groupSlotsEnrolledWithGroup(String people);

  /// No description provided for @groupSlotsEnrollMe.
  ///
  /// In es, this message translates to:
  /// **'Inscribirme · {people}'**
  String groupSlotsEnrollMe(String people);

  /// No description provided for @groupSlotsEnrollTitle.
  ///
  /// In es, this message translates to:
  /// **'Inscribirte en este horario'**
  String get groupSlotsEnrollTitle;

  /// No description provided for @groupSlotsFull.
  ///
  /// In es, this message translates to:
  /// **'Lleno'**
  String get groupSlotsFull;

  /// No description provided for @groupSlotsGroupDoesNotFit.
  ///
  /// In es, this message translates to:
  /// **'Tu grupo no cabe ({people})'**
  String groupSlotsGroupDoesNotFit(String people);

  /// No description provided for @groupSlotsGroupNote.
  ///
  /// In es, this message translates to:
  /// **'Es un grupo de hasta {capacity} personas: compartirás el recorrido con gente que no conoces.'**
  String groupSlotsGroupNote(int capacity);

  /// No description provided for @groupSlotsJoined.
  ///
  /// In es, this message translates to:
  /// **'{joined} de {capacity} personas inscritas'**
  String groupSlotsJoined(int joined, int capacity);

  /// No description provided for @groupSlotsMeetingPoint.
  ///
  /// In es, this message translates to:
  /// **'Punto de encuentro: {place}'**
  String groupSlotsMeetingPoint(String place);

  /// No description provided for @groupSlotsNoSpots.
  ///
  /// In es, this message translates to:
  /// **'Sin cupos'**
  String get groupSlotsNoSpots;

  /// No description provided for @groupSlotsNoSpotsLeft.
  ///
  /// In es, this message translates to:
  /// **'Ya no quedan cupos suficientes en ese horario'**
  String get groupSlotsNoSpotsLeft;

  /// No description provided for @groupSlotsNoTransport.
  ///
  /// In es, this message translates to:
  /// **'Sin transporte'**
  String get groupSlotsNoTransport;

  /// No description provided for @groupSlotsPeople.
  ///
  /// In es, this message translates to:
  /// **'Personas'**
  String get groupSlotsPeople;

  /// No description provided for @groupSlotsPrices.
  ///
  /// In es, this message translates to:
  /// **'{adult} por adulto · {child} por niño'**
  String groupSlotsPrices(String adult, String child);

  /// No description provided for @groupSlotsPublishedHint.
  ///
  /// In es, this message translates to:
  /// **'Cada guía fija la hora, el cupo y si pone transporte.'**
  String get groupSlotsPublishedHint;

  /// No description provided for @groupSlotsPublishedTitle.
  ///
  /// In es, this message translates to:
  /// **'Horarios publicados por guías'**
  String get groupSlotsPublishedTitle;

  /// No description provided for @groupSlotsSessionWhen.
  ///
  /// In es, this message translates to:
  /// **'{date} · {time}'**
  String groupSlotsSessionWhen(String date, String time);

  /// No description provided for @groupSlotsSessionWhenWithGuide.
  ///
  /// In es, this message translates to:
  /// **'{date} · {time} · con {guide}'**
  String groupSlotsSessionWhenWithGuide(String date, String time, String guide);

  /// No description provided for @groupSlotsSpotsLeft.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{Quedan 1 cupo} other{Quedan {count} cupos}}'**
  String groupSlotsSpotsLeft(int count);

  /// No description provided for @groupSlotsTitle.
  ///
  /// In es, this message translates to:
  /// **'Horarios disponibles'**
  String get groupSlotsTitle;

  /// No description provided for @groupSlotsTransportIncluded.
  ///
  /// In es, this message translates to:
  /// **'Incluye transporte'**
  String get groupSlotsTransportIncluded;

  /// No description provided for @groupSlotsYourGroup.
  ///
  /// In es, this message translates to:
  /// **'Tu grupo'**
  String get groupSlotsYourGroup;

  /// No description provided for @guideAccessAppBarSemantics.
  ///
  /// In es, this message translates to:
  /// **'K’Plan, guías'**
  String get guideAccessAppBarSemantics;

  /// No description provided for @guideAccessAppBarTitle.
  ///
  /// In es, this message translates to:
  /// **'K’Plan  /  Guías'**
  String get guideAccessAppBarTitle;

  /// No description provided for @guideAccessAttachFile.
  ///
  /// In es, this message translates to:
  /// **'Adjuntar archivo'**
  String get guideAccessAttachFile;

  /// No description provided for @guideAccessBackToDocuments.
  ///
  /// In es, this message translates to:
  /// **'Volver y revisar documentos'**
  String get guideAccessBackToDocuments;

  /// No description provided for @guideAccessCityError.
  ///
  /// In es, this message translates to:
  /// **'Elige la ciudad donde trabajas'**
  String get guideAccessCityError;

  /// No description provided for @guideAccessCityHint.
  ///
  /// In es, this message translates to:
  /// **'Elige una ciudad'**
  String get guideAccessCityHint;

  /// No description provided for @guideAccessCityLabel.
  ///
  /// In es, this message translates to:
  /// **'Ciudad'**
  String get guideAccessCityLabel;

  /// No description provided for @guideAccessCodeRejected.
  ///
  /// In es, this message translates to:
  /// **'El código no es válido o venció. Revísalo o pide uno nuevo.'**
  String get guideAccessCodeRejected;

  /// No description provided for @guideAccessCodeResent.
  ///
  /// In es, this message translates to:
  /// **'Enviamos un nuevo código a {email}. Usa el más reciente.'**
  String guideAccessCodeResent(String email);

  /// No description provided for @guideAccessCodeSent.
  ///
  /// In es, this message translates to:
  /// **'Enviamos un código de 6 dígitos a {email}.'**
  String guideAccessCodeSent(String email);

  /// No description provided for @guideAccessCodeTitle.
  ///
  /// In es, this message translates to:
  /// **'Ingresa el código de verificación'**
  String get guideAccessCodeTitle;

  /// No description provided for @guideAccessConfirmPasswordHint.
  ///
  /// In es, this message translates to:
  /// **'Repite tu contraseña'**
  String get guideAccessConfirmPasswordHint;

  /// No description provided for @guideAccessConfirmPasswordLabel.
  ///
  /// In es, this message translates to:
  /// **'Confirma tu contraseña'**
  String get guideAccessConfirmPasswordLabel;

  /// No description provided for @guideAccessConsentError.
  ///
  /// In es, this message translates to:
  /// **'Autoriza la revisión de tus documentos para enviar la solicitud.'**
  String get guideAccessConsentError;

  /// No description provided for @guideAccessConsentLabel.
  ///
  /// In es, this message translates to:
  /// **'Autorizo al equipo de K’Plan a revisar mi información y documentación para evaluar esta solicitud.'**
  String get guideAccessConsentLabel;

  /// No description provided for @guideAccessCountryCodeTooltip.
  ///
  /// In es, this message translates to:
  /// **'Código de país'**
  String get guideAccessCountryCodeTooltip;

  /// No description provided for @guideAccessCountryCostaRica.
  ///
  /// In es, this message translates to:
  /// **'Costa Rica'**
  String get guideAccessCountryCostaRica;

  /// No description provided for @guideAccessCountryElSalvador.
  ///
  /// In es, this message translates to:
  /// **'El Salvador'**
  String get guideAccessCountryElSalvador;

  /// No description provided for @guideAccessCountryGuatemala.
  ///
  /// In es, this message translates to:
  /// **'Guatemala'**
  String get guideAccessCountryGuatemala;

  /// No description provided for @guideAccessCountryHonduras.
  ///
  /// In es, this message translates to:
  /// **'Honduras'**
  String get guideAccessCountryHonduras;

  /// No description provided for @guideAccessCountryMexico.
  ///
  /// In es, this message translates to:
  /// **'México'**
  String get guideAccessCountryMexico;

  /// No description provided for @guideAccessCountryNicaragua.
  ///
  /// In es, this message translates to:
  /// **'Nicaragua'**
  String get guideAccessCountryNicaragua;

  /// No description provided for @guideAccessCountryPanama.
  ///
  /// In es, this message translates to:
  /// **'Panamá'**
  String get guideAccessCountryPanama;

  /// No description provided for @guideAccessCountrySpain.
  ///
  /// In es, this message translates to:
  /// **'España'**
  String get guideAccessCountrySpain;

  /// No description provided for @guideAccessCountryUnitedStatesOrCanada.
  ///
  /// In es, this message translates to:
  /// **'Estados Unidos o Canadá'**
  String get guideAccessCountryUnitedStatesOrCanada;

  /// No description provided for @guideAccessCoverageError.
  ///
  /// In es, this message translates to:
  /// **'Elige dónde trabajas'**
  String get guideAccessCoverageError;

  /// No description provided for @guideAccessCoverageLabel.
  ///
  /// In es, this message translates to:
  /// **'Dónde trabajas'**
  String get guideAccessCoverageLabel;

  /// No description provided for @guideAccessCoverageLocalSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Por ejemplo, un guía local certificado en ella.'**
  String get guideAccessCoverageLocalSubtitle;

  /// No description provided for @guideAccessCoverageLocalTitle.
  ///
  /// In es, this message translates to:
  /// **'En una ciudad'**
  String get guideAccessCoverageLocalTitle;

  /// No description provided for @guideAccessCoverageNationalSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Por ejemplo, un guía nacional del INTUR.'**
  String get guideAccessCoverageNationalSubtitle;

  /// No description provided for @guideAccessCoverageNationalTitle.
  ///
  /// In es, this message translates to:
  /// **'En todo el país'**
  String get guideAccessCoverageNationalTitle;

  /// No description provided for @guideAccessCoverageSummaryLocal.
  ///
  /// In es, this message translates to:
  /// **'Solo en {city}'**
  String guideAccessCoverageSummaryLocal(String city);

  /// No description provided for @guideAccessCoverageSummaryNational.
  ///
  /// In es, this message translates to:
  /// **'Todo el territorio nicaragüense'**
  String get guideAccessCoverageSummaryNational;

  /// No description provided for @guideAccessCreateAccountAndSend.
  ///
  /// In es, this message translates to:
  /// **'Crear cuenta y enviar'**
  String get guideAccessCreateAccountAndSend;

  /// No description provided for @guideAccessDocumentAccepted.
  ///
  /// In es, this message translates to:
  /// **'Aceptado'**
  String get guideAccessDocumentAccepted;

  /// No description provided for @guideAccessDocumentAlreadyExpired.
  ///
  /// In es, this message translates to:
  /// **'El documento ya venció: sube uno vigente'**
  String get guideAccessDocumentAlreadyExpired;

  /// No description provided for @guideAccessDocumentAttached.
  ///
  /// In es, this message translates to:
  /// **'Adjunto · Pendiente de revisión'**
  String get guideAccessDocumentAttached;

  /// No description provided for @guideAccessDocumentAttachFile.
  ///
  /// In es, this message translates to:
  /// **'Adjunta el archivo'**
  String get guideAccessDocumentAttachFile;

  /// No description provided for @guideAccessDocumentCouldNotAccept.
  ///
  /// In es, this message translates to:
  /// **'no pudimos aceptarlo'**
  String get guideAccessDocumentCouldNotAccept;

  /// No description provided for @guideAccessDocumentExpiresBeforeIssued.
  ///
  /// In es, this message translates to:
  /// **'El vencimiento tiene que ser posterior a la emisión'**
  String get guideAccessDocumentExpiresBeforeIssued;

  /// No description provided for @guideAccessDocumentExpiresOn.
  ///
  /// In es, this message translates to:
  /// **'Vence el'**
  String get guideAccessDocumentExpiresOn;

  /// No description provided for @guideAccessDocumentExpiresOnOptional.
  ///
  /// In es, this message translates to:
  /// **'Vence el · Opcional'**
  String get guideAccessDocumentExpiresOnOptional;

  /// No description provided for @guideAccessDocumentExpiresRequired.
  ///
  /// In es, this message translates to:
  /// **'Elige la fecha de vencimiento'**
  String get guideAccessDocumentExpiresRequired;

  /// No description provided for @guideAccessDocumentIssuedFuture.
  ///
  /// In es, this message translates to:
  /// **'La fecha de emisión no puede ser futura'**
  String get guideAccessDocumentIssuedFuture;

  /// No description provided for @guideAccessDocumentIssuedOn.
  ///
  /// In es, this message translates to:
  /// **'Emitido el'**
  String get guideAccessDocumentIssuedOn;

  /// No description provided for @guideAccessDocumentIssuedRequired.
  ///
  /// In es, this message translates to:
  /// **'Elige la fecha de emisión'**
  String get guideAccessDocumentIssuedRequired;

  /// No description provided for @guideAccessDocumentKept.
  ///
  /// In es, this message translates to:
  /// **'Pasa tal cual a la solicitud nueva'**
  String get guideAccessDocumentKept;

  /// No description provided for @guideAccessDocumentKeptAccepted.
  ///
  /// In es, this message translates to:
  /// **'Aceptado: pasa tal cual a la solicitud nueva'**
  String get guideAccessDocumentKeptAccepted;

  /// No description provided for @guideAccessDocumentNoExpiry.
  ///
  /// In es, this message translates to:
  /// **'No vence'**
  String get guideAccessDocumentNoExpiry;

  /// No description provided for @guideAccessDocumentNumber.
  ///
  /// In es, this message translates to:
  /// **'Número del documento'**
  String get guideAccessDocumentNumber;

  /// No description provided for @guideAccessDocumentNumberHint.
  ///
  /// In es, this message translates to:
  /// **'Como aparece en el documento'**
  String get guideAccessDocumentNumberHint;

  /// No description provided for @guideAccessDocumentNumberRequired.
  ///
  /// In es, this message translates to:
  /// **'Escribe el número del documento'**
  String get guideAccessDocumentNumberRequired;

  /// No description provided for @guideAccessDocumentPending.
  ///
  /// In es, this message translates to:
  /// **'Por revisar'**
  String get guideAccessDocumentPending;

  /// No description provided for @guideAccessDocumentRejected.
  ///
  /// In es, this message translates to:
  /// **'Rechazado: {reason}'**
  String guideAccessDocumentRejected(String reason);

  /// No description provided for @guideAccessDocumentRejectedByUs.
  ///
  /// In es, this message translates to:
  /// **'Lo rechazamos: {reason}'**
  String guideAccessDocumentRejectedByUs(String reason);

  /// No description provided for @guideAccessDocumentsCorrectSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Sube otra vez lo que rechazamos. Lo que aceptamos pasa tal cual.'**
  String get guideAccessDocumentsCorrectSubtitle;

  /// No description provided for @guideAccessDocumentsCorrectTitle.
  ///
  /// In es, this message translates to:
  /// **'Corrige tus documentos'**
  String get guideAccessDocumentsCorrectTitle;

  /// No description provided for @guideAccessDocumentsSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Adjunta una foto legible o un PDF de cada uno, con sus fechas. Solo el equipo de revisión los verá.'**
  String get guideAccessDocumentsSubtitle;

  /// No description provided for @guideAccessDocumentsTitle.
  ///
  /// In es, this message translates to:
  /// **'Tus documentos'**
  String get guideAccessDocumentsTitle;

  /// No description provided for @guideAccessDocumentUploadAgain.
  ///
  /// In es, this message translates to:
  /// **'súbelo de nuevo'**
  String get guideAccessDocumentUploadAgain;

  /// No description provided for @guideAccessDocumentValid.
  ///
  /// In es, this message translates to:
  /// **'En vigor'**
  String get guideAccessDocumentValid;

  /// No description provided for @guideAccessEmailHelper.
  ///
  /// In es, this message translates to:
  /// **'Usa uno que no tenga ya una cuenta de K’Plan.'**
  String get guideAccessEmailHelper;

  /// No description provided for @guideAccessEmailHint.
  ///
  /// In es, this message translates to:
  /// **'tu@correo.com'**
  String get guideAccessEmailHint;

  /// No description provided for @guideAccessEmailLabel.
  ///
  /// In es, this message translates to:
  /// **'Correo'**
  String get guideAccessEmailLabel;

  /// No description provided for @guideAccessExperienceHint.
  ///
  /// In es, this message translates to:
  /// **'Ej.: 3 años en recorridos de historia colonial'**
  String get guideAccessExperienceHint;

  /// No description provided for @guideAccessExperienceLabel.
  ///
  /// In es, this message translates to:
  /// **'Preséntate a los turistas'**
  String get guideAccessExperienceLabel;

  /// No description provided for @guideAccessExperienceRequired.
  ///
  /// In es, this message translates to:
  /// **'Cuéntanos tu experiencia'**
  String get guideAccessExperienceRequired;

  /// No description provided for @guideAccessExperienceSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Tu certificación define hasta dónde puedes acompañar a los viajeros.'**
  String get guideAccessExperienceSubtitle;

  /// No description provided for @guideAccessFileFormats.
  ///
  /// In es, this message translates to:
  /// **'PDF, JPG o PNG'**
  String get guideAccessFileFormats;

  /// No description provided for @guideAccessFilePickerFailed.
  ///
  /// In es, this message translates to:
  /// **'No pudimos abrir tus archivos. Intenta de nuevo.'**
  String get guideAccessFilePickerFailed;

  /// No description provided for @guideAccessFileSizeProblem.
  ///
  /// In es, this message translates to:
  /// **'El archivo pesa más de 10 MB. Elige uno más liviano.'**
  String get guideAccessFileSizeProblem;

  /// No description provided for @guideAccessFileTypeProblem.
  ///
  /// In es, this message translates to:
  /// **'Adjunta un archivo PDF, JPG o PNG.'**
  String get guideAccessFileTypeProblem;

  /// No description provided for @guideAccessIdentitySubtitle.
  ///
  /// In es, this message translates to:
  /// **'Usa tus datos tal como aparecen en tu cédula. Con este correo se crea tu cuenta de guía o traductor.'**
  String get guideAccessIdentitySubtitle;

  /// No description provided for @guideAccessIdentityTitle.
  ///
  /// In es, this message translates to:
  /// **'Cuéntanos quién eres'**
  String get guideAccessIdentityTitle;

  /// No description provided for @guideAccessLanguagesError.
  ///
  /// In es, this message translates to:
  /// **'Elige al menos un idioma'**
  String get guideAccessLanguagesError;

  /// No description provided for @guideAccessLanguagesLabel.
  ///
  /// In es, this message translates to:
  /// **'Idiomas'**
  String get guideAccessLanguagesLabel;

  /// No description provided for @guideAccessNameHint.
  ///
  /// In es, this message translates to:
  /// **'Nombre y apellidos'**
  String get guideAccessNameHint;

  /// No description provided for @guideAccessNameRequired.
  ///
  /// In es, this message translates to:
  /// **'Ingresa tu nombre completo'**
  String get guideAccessNameRequired;

  /// No description provided for @guideAccessPasswordHint.
  ///
  /// In es, this message translates to:
  /// **'Ingresa tu contraseña'**
  String get guideAccessPasswordHint;

  /// No description provided for @guideAccessPasswordSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Tu correo está verificado. Crea una contraseña: al enviar, subimos tus documentos y tu solicitud queda en revisión.'**
  String get guideAccessPasswordSubtitle;

  /// No description provided for @guideAccessPasswordTitle.
  ///
  /// In es, this message translates to:
  /// **'Protege tu cuenta'**
  String get guideAccessPasswordTitle;

  /// No description provided for @guideAccessPhoneLabel.
  ///
  /// In es, this message translates to:
  /// **'Teléfono de contacto'**
  String get guideAccessPhoneLabel;

  /// No description provided for @guideAccessProfileMissing.
  ///
  /// In es, this message translates to:
  /// **'Elige tu fecha de nacimiento y tu nacionalidad.'**
  String get guideAccessProfileMissing;

  /// No description provided for @guideAccessProgressLabel.
  ///
  /// In es, this message translates to:
  /// **'POSTULACIÓN  ·  PASO {step} DE {total}'**
  String guideAccessProgressLabel(int step, int total);

  /// No description provided for @guideAccessProgressSemantics.
  ///
  /// In es, this message translates to:
  /// **'Postulación, paso {step} de {total}'**
  String guideAccessProgressSemantics(int step, int total);

  /// No description provided for @guideAccessRemoveFile.
  ///
  /// In es, this message translates to:
  /// **'Quitar {name}'**
  String guideAccessRemoveFile(String name);

  /// No description provided for @guideAccessReviewAccount.
  ///
  /// In es, this message translates to:
  /// **'Tu cuenta'**
  String get guideAccessReviewAccount;

  /// No description provided for @guideAccessReviewCorrectionTitle.
  ///
  /// In es, this message translates to:
  /// **'Revisa tu corrección'**
  String get guideAccessReviewCorrectionTitle;

  /// No description provided for @guideAccessReviewDocuments.
  ///
  /// In es, this message translates to:
  /// **'Documentos que envías · Por verificar'**
  String get guideAccessReviewDocuments;

  /// No description provided for @guideAccessReviewServices.
  ///
  /// In es, this message translates to:
  /// **'Lo que ofreces'**
  String get guideAccessReviewServices;

  /// No description provided for @guideAccessReviewSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Confirma tu información antes de enviarla.'**
  String get guideAccessReviewSubtitle;

  /// No description provided for @guideAccessReviewTitle.
  ///
  /// In es, this message translates to:
  /// **'Revisa tu postulación'**
  String get guideAccessReviewTitle;

  /// No description provided for @guideAccessReviewVehicle.
  ///
  /// In es, this message translates to:
  /// **'Lleva turistas en su vehículo'**
  String get guideAccessReviewVehicle;

  /// No description provided for @guideAccessSendCorrection.
  ///
  /// In es, this message translates to:
  /// **'Enviar corrección'**
  String get guideAccessSendCorrection;

  /// No description provided for @guideAccessSendRequest.
  ///
  /// In es, this message translates to:
  /// **'Enviar solicitud'**
  String get guideAccessSendRequest;

  /// No description provided for @guideAccessServiceGuide.
  ///
  /// In es, this message translates to:
  /// **'Guía de turismo'**
  String get guideAccessServiceGuide;

  /// No description provided for @guideAccessServicesCorrectingSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Revisa tus datos: puedes cambiarlos antes de volver a enviar.'**
  String get guideAccessServicesCorrectingSubtitle;

  /// No description provided for @guideAccessServicesError.
  ///
  /// In es, this message translates to:
  /// **'Elige al menos uno'**
  String get guideAccessServicesError;

  /// No description provided for @guideAccessServicesLabel.
  ///
  /// In es, this message translates to:
  /// **'Ofreces'**
  String get guideAccessServicesLabel;

  /// No description provided for @guideAccessServicesTitle.
  ///
  /// In es, this message translates to:
  /// **'Qué ofreces y dónde'**
  String get guideAccessServicesTitle;

  /// No description provided for @guideAccessStartApply.
  ///
  /// In es, this message translates to:
  /// **'Postularme'**
  String get guideAccessStartApply;

  /// No description provided for @guideAccessStartChecklistCredential.
  ///
  /// In es, this message translates to:
  /// **'Tu licencia del INTUR si eres guía, o tu certificado de idiomas si eres traductor'**
  String get guideAccessStartChecklistCredential;

  /// No description provided for @guideAccessStartChecklistEmail.
  ///
  /// In es, this message translates to:
  /// **'Un correo que no tenga ya una cuenta de K’Plan'**
  String get guideAccessStartChecklistEmail;

  /// No description provided for @guideAccessStartChecklistId.
  ///
  /// In es, this message translates to:
  /// **'Tu cédula y tu récord de policía'**
  String get guideAccessStartChecklistId;

  /// No description provided for @guideAccessStartChecklistLabel.
  ///
  /// In es, this message translates to:
  /// **'Ten a mano'**
  String get guideAccessStartChecklistLabel;

  /// No description provided for @guideAccessStartChecklistVehicle.
  ///
  /// In es, this message translates to:
  /// **'Tu licencia de conducir y el seguro si llevas turistas en tu vehículo'**
  String get guideAccessStartChecklistVehicle;

  /// No description provided for @guideAccessStartContinueAsTourist.
  ///
  /// In es, this message translates to:
  /// **'Continuar como turista'**
  String get guideAccessStartContinueAsTourist;

  /// No description provided for @guideAccessStartNotice.
  ///
  /// In es, this message translates to:
  /// **'El equipo de K’Plan revisará tu información antes de habilitar tu acceso.'**
  String get guideAccessStartNotice;

  /// No description provided for @guideAccessStartSignOutToApply.
  ///
  /// In es, this message translates to:
  /// **'Salir para postularme'**
  String get guideAccessStartSignOutToApply;

  /// No description provided for @guideAccessStartSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Postúlate para ofrecer tus servicios como guía de turismo o como traductor.'**
  String get guideAccessStartSubtitle;

  /// No description provided for @guideAccessStartTitle.
  ///
  /// In es, this message translates to:
  /// **'Comparte tu territorio'**
  String get guideAccessStartTitle;

  /// No description provided for @guideAccessStartTouristNotice.
  ///
  /// In es, this message translates to:
  /// **'Tu cuenta de K’Plan es de turista. Para ofrecer tus servicios necesitas una cuenta aparte, con otro correo: sal de esta y postúlate.'**
  String get guideAccessStartTouristNotice;

  /// No description provided for @guideAccessStatusApprovedSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Tu solicitud fue aprobada: los turistas ya te encuentran en K’Plan.'**
  String get guideAccessStatusApprovedSubtitle;

  /// No description provided for @guideAccessStatusApprovedTitle.
  ///
  /// In es, this message translates to:
  /// **'Acceso de guía habilitado'**
  String get guideAccessStatusApprovedTitle;

  /// No description provided for @guideAccessStatusEnterAsGuide.
  ///
  /// In es, this message translates to:
  /// **'Entrar como guía'**
  String get guideAccessStatusEnterAsGuide;

  /// No description provided for @guideAccessStatusMissing.
  ///
  /// In es, this message translates to:
  /// **'Falta: {items}.'**
  String guideAccessStatusMissing(String items);

  /// No description provided for @guideAccessStatusPendingNotice.
  ///
  /// In es, this message translates to:
  /// **'El acceso de guía estará disponible únicamente si tu solicitud es aprobada. Te avisamos por correo.'**
  String get guideAccessStatusPendingNotice;

  /// No description provided for @guideAccessStatusPendingSubtitle.
  ///
  /// In es, this message translates to:
  /// **'El equipo de K’Plan está revisando tus documentos.'**
  String get guideAccessStatusPendingSubtitle;

  /// No description provided for @guideAccessStatusPendingTitle.
  ///
  /// In es, this message translates to:
  /// **'Solicitud en revisión'**
  String get guideAccessStatusPendingTitle;

  /// No description provided for @guideAccessStatusReceivedSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Tu solicitud llegó. El equipo la revisa por orden de llegada.'**
  String get guideAccessStatusReceivedSubtitle;

  /// No description provided for @guideAccessStatusRejectedSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Revisa lo que hay que corregir.'**
  String get guideAccessStatusRejectedSubtitle;

  /// No description provided for @guideAccessStatusRejectedTitle.
  ///
  /// In es, this message translates to:
  /// **'No pudimos aprobar tu solicitud'**
  String get guideAccessStatusRejectedTitle;

  /// No description provided for @guideAccessStatusRenewalApprovedSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Tus documentos nuevos están en vigor.'**
  String get guideAccessStatusRenewalApprovedSubtitle;

  /// No description provided for @guideAccessStatusRenewalApprovedTitle.
  ///
  /// In es, this message translates to:
  /// **'Renovación aprobada'**
  String get guideAccessStatusRenewalApprovedTitle;

  /// No description provided for @guideAccessStatusRenewalPendingTitle.
  ///
  /// In es, this message translates to:
  /// **'Renovación en revisión'**
  String get guideAccessStatusRenewalPendingTitle;

  /// No description provided for @guideAccessStatusResubmit.
  ///
  /// In es, this message translates to:
  /// **'Corregir y volver a enviar'**
  String get guideAccessStatusResubmit;

  /// No description provided for @guideAccessStatusTeamNote.
  ///
  /// In es, this message translates to:
  /// **'Nota del equipo: {note}'**
  String guideAccessStatusTeamNote(String note);

  /// No description provided for @guideAccessVehicleSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Te pediremos tu licencia de conducir y el seguro del vehículo.'**
  String get guideAccessVehicleSubtitle;

  /// No description provided for @guideAccessVehicleTitle.
  ///
  /// In es, this message translates to:
  /// **'Llevo turistas en mi vehículo'**
  String get guideAccessVehicleTitle;

  /// No description provided for @guideAccessVerify.
  ///
  /// In es, this message translates to:
  /// **'Verificar'**
  String get guideAccessVerify;

  /// No description provided for @guideAppBalanceAvailable.
  ///
  /// In es, this message translates to:
  /// **'Disponible para retirar'**
  String get guideAppBalanceAvailable;

  /// No description provided for @guideAppBalanceCommissionNote.
  ///
  /// In es, this message translates to:
  /// **'K’Plan descuenta el {percent}% de cada viaje. Lo demás es tuyo.'**
  String guideAppBalanceCommissionNote(int percent);

  /// No description provided for @guideAppBalanceEmptyHint.
  ///
  /// In es, this message translates to:
  /// **'Cuando termines un viaje, lo que recibes aparece aquí para retirarlo.'**
  String get guideAppBalanceEmptyHint;

  /// No description provided for @guideAppBalanceEmptyMessage.
  ///
  /// In es, this message translates to:
  /// **'Aquí verás lo que recibes por cada viaje y tus retiros.'**
  String get guideAppBalanceEmptyMessage;

  /// No description provided for @guideAppBalanceEmptyTitle.
  ///
  /// In es, this message translates to:
  /// **'Todavía no hay movimientos'**
  String get guideAppBalanceEmptyTitle;

  /// No description provided for @guideAppBalanceMovements.
  ///
  /// In es, this message translates to:
  /// **'Movimientos'**
  String get guideAppBalanceMovements;

  /// No description provided for @guideAppBalanceNothingPending.
  ///
  /// In es, this message translates to:
  /// **'Nada por cobrar por ahora'**
  String get guideAppBalanceNothingPending;

  /// No description provided for @guideAppBalancePayoutBreakdown.
  ///
  /// In es, this message translates to:
  /// **'Precio {price} · comisión {commission}'**
  String guideAppBalancePayoutBreakdown(String price, String commission);

  /// No description provided for @guideAppBalancePending.
  ///
  /// In es, this message translates to:
  /// **'Por cobrar {amount} de {count, plural, =1{1 viaje próximo} other{{count} viajes próximos}}'**
  String guideAppBalancePending(String amount, int count);

  /// No description provided for @guideAppBalanceTitle.
  ///
  /// In es, this message translates to:
  /// **'Balance'**
  String get guideAppBalanceTitle;

  /// No description provided for @guideAppBalanceToAccount.
  ///
  /// In es, this message translates to:
  /// **'A {account}'**
  String guideAppBalanceToAccount(String account);

  /// No description provided for @guideAppBalanceWithdrawalDeposited.
  ///
  /// In es, this message translates to:
  /// **'{date} · Depositado'**
  String guideAppBalanceWithdrawalDeposited(String date);

  /// No description provided for @guideAppBalanceWithdrawalProcessing.
  ///
  /// In es, this message translates to:
  /// **'{date} · En proceso'**
  String guideAppBalanceWithdrawalProcessing(String date);

  /// No description provided for @guideAppBalanceWithdrawalSent.
  ///
  /// In es, this message translates to:
  /// **'Retiro de {amount} en camino'**
  String guideAppBalanceWithdrawalSent(String amount);

  /// No description provided for @guideAppBalanceWithdrawalTo.
  ///
  /// In es, this message translates to:
  /// **'Retiro a {account}'**
  String guideAppBalanceWithdrawalTo(String account);

  /// No description provided for @guideAppBarModeTag.
  ///
  /// In es, this message translates to:
  /// **'Guías'**
  String get guideAppBarModeTag;

  /// No description provided for @guideAppChatsEmptyMessage.
  ///
  /// In es, this message translates to:
  /// **'Cuando un turista te contrate, aquí coordinan el punto de encuentro.'**
  String get guideAppChatsEmptyMessage;

  /// No description provided for @guideAppChatsEmptyTitle.
  ///
  /// In es, this message translates to:
  /// **'Todavía no tienes conversaciones'**
  String get guideAppChatsEmptyTitle;

  /// No description provided for @guideAppChatsNoMessages.
  ///
  /// In es, this message translates to:
  /// **'Sin mensajes'**
  String get guideAppChatsNoMessages;

  /// No description provided for @guideAppChatsUnread.
  ///
  /// In es, this message translates to:
  /// **'{count} sin leer'**
  String guideAppChatsUnread(int count);

  /// No description provided for @guideAppChatsYou.
  ///
  /// In es, this message translates to:
  /// **'Tú: {text}'**
  String guideAppChatsYou(String text);

  /// No description provided for @guideAppDocumentExpired.
  ///
  /// In es, this message translates to:
  /// **'Vencido'**
  String get guideAppDocumentExpired;

  /// No description provided for @guideAppDocumentInReview.
  ///
  /// In es, this message translates to:
  /// **'En revisión'**
  String get guideAppDocumentInReview;

  /// No description provided for @guideAppDocumentRejected.
  ///
  /// In es, this message translates to:
  /// **'Rechazado'**
  String get guideAppDocumentRejected;

  /// No description provided for @guideAppDocumentValidNoExpiry.
  ///
  /// In es, this message translates to:
  /// **'En vigor · no vence'**
  String get guideAppDocumentValidNoExpiry;

  /// No description provided for @guideAppDocumentValidUntil.
  ///
  /// In es, this message translates to:
  /// **'En vigor · vence el {date}'**
  String guideAppDocumentValidUntil(String date);

  /// No description provided for @guideAppEarningsLabelDone.
  ///
  /// In es, this message translates to:
  /// **'Recibiste'**
  String get guideAppEarningsLabelDone;

  /// No description provided for @guideAppEarningsLabelUpcoming.
  ///
  /// In es, this message translates to:
  /// **'Recibes'**
  String get guideAppEarningsLabelUpcoming;

  /// No description provided for @guideAppHomeATourist.
  ///
  /// In es, this message translates to:
  /// **'Un turista'**
  String get guideAppHomeATourist;

  /// No description provided for @guideAppHomeAvailable.
  ///
  /// In es, this message translates to:
  /// **'Disponible'**
  String get guideAppHomeAvailable;

  /// No description provided for @guideAppHomeDefaultName.
  ///
  /// In es, this message translates to:
  /// **'guía'**
  String get guideAppHomeDefaultName;

  /// No description provided for @guideAppHomeEmptyLocal.
  ///
  /// In es, this message translates to:
  /// **'No hay propuestas nuevas en {city}'**
  String guideAppHomeEmptyLocal(String city);

  /// No description provided for @guideAppHomeEmptyMessage.
  ///
  /// In es, this message translates to:
  /// **'Cuando un turista publique una, aparecerá aquí.'**
  String get guideAppHomeEmptyMessage;

  /// No description provided for @guideAppHomeEmptyNational.
  ///
  /// In es, this message translates to:
  /// **'No hay propuestas nuevas por ahora'**
  String get guideAppHomeEmptyNational;

  /// No description provided for @guideAppHomeGreeting.
  ///
  /// In es, this message translates to:
  /// **'Hola, {name}'**
  String guideAppHomeGreeting(String name);

  /// No description provided for @guideAppHomeHiredNotice.
  ///
  /// In es, this message translates to:
  /// **'¡{who} te contrató para {circuit}! {day} · {time}'**
  String guideAppHomeHiredNotice(
    String who,
    String circuit,
    String day,
    String time,
  );

  /// No description provided for @guideAppHomeLoadingProposals.
  ///
  /// In es, this message translates to:
  /// **'Cargando propuestas'**
  String get guideAppHomeLoadingProposals;

  /// No description provided for @guideAppHomeNextTrip.
  ///
  /// In es, this message translates to:
  /// **'Próximo viaje'**
  String get guideAppHomeNextTrip;

  /// No description provided for @guideAppHomePending.
  ///
  /// In es, this message translates to:
  /// **'Por cobrar'**
  String get guideAppHomePending;

  /// No description provided for @guideAppHomeProposals.
  ///
  /// In es, this message translates to:
  /// **'Propuestas para ti'**
  String get guideAppHomeProposals;

  /// No description provided for @guideAppHomeProposalsLocal.
  ///
  /// In es, this message translates to:
  /// **'Solo ves propuestas de {city}, donde tienes tu certificación.'**
  String guideAppHomeProposalsLocal(String city);

  /// No description provided for @guideAppHomeProposalsNational.
  ///
  /// In es, this message translates to:
  /// **'De todo el país, en los idiomas que hablas.'**
  String get guideAppHomeProposalsNational;

  /// No description provided for @guideAppHoursShort.
  ///
  /// In es, this message translates to:
  /// **'{hours} h'**
  String guideAppHoursShort(int hours);

  /// No description provided for @guideAppJobApplicationSent.
  ///
  /// In es, this message translates to:
  /// **'Postulación enviada'**
  String get guideAppJobApplicationSent;

  /// No description provided for @guideAppJobApplicationTitle.
  ///
  /// In es, this message translates to:
  /// **'Tu postulación'**
  String get guideAppJobApplicationTitle;

  /// No description provided for @guideAppJobApplied.
  ///
  /// In es, this message translates to:
  /// **'Postulado'**
  String get guideAppJobApplied;

  /// No description provided for @guideAppJobAppliedNotice.
  ///
  /// In es, this message translates to:
  /// **'Te postulaste por {price}. {name} está decidiendo; te avisaremos en Inicio.'**
  String guideAppJobAppliedNotice(String price, String name);

  /// No description provided for @guideAppJobApply.
  ///
  /// In es, this message translates to:
  /// **'Postularme'**
  String get guideAppJobApply;

  /// No description provided for @guideAppJobHiredNotice.
  ///
  /// In es, this message translates to:
  /// **'¡{name} te contrató! Ya es uno de tus viajes.'**
  String guideAppJobHiredNotice(String name);

  /// No description provided for @guideAppJobLodging.
  ///
  /// In es, this message translates to:
  /// **'El turista te da alojamiento'**
  String get guideAppJobLodging;

  /// No description provided for @guideAppJobMessageHint.
  ///
  /// In es, this message translates to:
  /// **'Cuéntale por qué eres buena opción para este recorrido'**
  String get guideAppJobMessageHint;

  /// No description provided for @guideAppJobMessageLabel.
  ///
  /// In es, this message translates to:
  /// **'Mensaje para {name}'**
  String guideAppJobMessageLabel(String name);

  /// No description provided for @guideAppJobNotFoundMessage.
  ///
  /// In es, this message translates to:
  /// **'Puede que el turista la haya retirado.'**
  String get guideAppJobNotFoundMessage;

  /// No description provided for @guideAppJobNotFoundTitle.
  ///
  /// In es, this message translates to:
  /// **'No encontramos esta propuesta'**
  String get guideAppJobNotFoundTitle;

  /// No description provided for @guideAppJobPostedBy.
  ///
  /// In es, this message translates to:
  /// **'Quién la publicó'**
  String get guideAppJobPostedBy;

  /// No description provided for @guideAppJobPriceHelper.
  ///
  /// In es, this message translates to:
  /// **'El turista ofrece {amount}. Puedes proponer otro precio.'**
  String guideAppJobPriceHelper(String amount);

  /// No description provided for @guideAppJobPriceLabel.
  ///
  /// In es, this message translates to:
  /// **'Tu precio (C\$)'**
  String get guideAppJobPriceLabel;

  /// No description provided for @guideAppJobPriceRequired.
  ///
  /// In es, this message translates to:
  /// **'Escribe tu precio en córdobas'**
  String get guideAppJobPriceRequired;

  /// No description provided for @guideAppJobPublished.
  ///
  /// In es, this message translates to:
  /// **'Publicada {timeAgo}'**
  String guideAppJobPublished(String timeAgo);

  /// No description provided for @guideAppJobRowBudget.
  ///
  /// In es, this message translates to:
  /// **'presupuesto'**
  String get guideAppJobRowBudget;

  /// No description provided for @guideAppJobRowYourPrice.
  ///
  /// In es, this message translates to:
  /// **'tu precio'**
  String get guideAppJobRowYourPrice;

  /// No description provided for @guideAppJobTakenNotice.
  ///
  /// In es, this message translates to:
  /// **'{name} contrató a otro guía. Hay más propuestas en Inicio.'**
  String guideAppJobTakenNotice(String name);

  /// No description provided for @guideAppJobTitle.
  ///
  /// In es, this message translates to:
  /// **'Propuesta'**
  String get guideAppJobTitle;

  /// No description provided for @guideAppJobTouristBudget.
  ///
  /// In es, this message translates to:
  /// **'presupuesto del turista'**
  String get guideAppJobTouristBudget;

  /// No description provided for @guideAppJobWouldReceive.
  ///
  /// In es, this message translates to:
  /// **'Recibirías {amount} después del 20%.'**
  String guideAppJobWouldReceive(String amount);

  /// No description provided for @guideAppJobYouReceiveAfterFee.
  ///
  /// In es, this message translates to:
  /// **'Recibes {amount} después del 20% de K’Plan'**
  String guideAppJobYouReceiveAfterFee(String amount);

  /// No description provided for @guideAppMoneyAgreedPrice.
  ///
  /// In es, this message translates to:
  /// **'Precio acordado'**
  String get guideAppMoneyAgreedPrice;

  /// No description provided for @guideAppMoneyCommission.
  ///
  /// In es, this message translates to:
  /// **'Comisión K’Plan ({percent}%)'**
  String guideAppMoneyCommission(int percent);

  /// No description provided for @guideAppNavChats.
  ///
  /// In es, this message translates to:
  /// **'Chats'**
  String get guideAppNavChats;

  /// No description provided for @guideAppNavChatsUnread.
  ///
  /// In es, this message translates to:
  /// **'Chats, {count} sin leer'**
  String guideAppNavChatsUnread(int count);

  /// No description provided for @guideAppNavProfile.
  ///
  /// In es, this message translates to:
  /// **'Perfil'**
  String get guideAppNavProfile;

  /// No description provided for @guideAppNavTrips.
  ///
  /// In es, this message translates to:
  /// **'Viajes'**
  String get guideAppNavTrips;

  /// No description provided for @guideAppProfileAvailable.
  ///
  /// In es, this message translates to:
  /// **'Disponible {amount}'**
  String guideAppProfileAvailable(String amount);

  /// No description provided for @guideAppProfileBalanceHint.
  ///
  /// In es, this message translates to:
  /// **'Lo que recibes por tus viajes'**
  String get guideAppProfileBalanceHint;

  /// No description provided for @guideAppProfileDocuments.
  ///
  /// In es, this message translates to:
  /// **'Mis documentos'**
  String get guideAppProfileDocuments;

  /// No description provided for @guideAppProfileEdit.
  ///
  /// In es, this message translates to:
  /// **'Editar mi perfil'**
  String get guideAppProfileEdit;

  /// No description provided for @guideAppProfileEditHint.
  ///
  /// In es, this message translates to:
  /// **'Foto, presentación, teléfono e idiomas'**
  String get guideAppProfileEditHint;

  /// No description provided for @guideAppProfileNoReviews.
  ///
  /// In es, this message translates to:
  /// **'Todavía sin reseñas de turistas'**
  String get guideAppProfileNoReviews;

  /// No description provided for @guideAppProfileRenewalInReview.
  ///
  /// In es, this message translates to:
  /// **'Tienes una renovación en revisión.'**
  String get guideAppProfileRenewalInReview;

  /// No description provided for @guideAppProfileSpeaks.
  ///
  /// In es, this message translates to:
  /// **'Habla {languages}'**
  String guideAppProfileSpeaks(String languages);

  /// No description provided for @guideAppProfileSuspended.
  ///
  /// In es, this message translates to:
  /// **'Tu perfil está suspendido: se venció {documents}. Renuévalo para volver a aparecer para los turistas.'**
  String guideAppProfileSuspended(String documents);

  /// No description provided for @guideAppProfileSuspendedADocument.
  ///
  /// In es, this message translates to:
  /// **'un documento'**
  String get guideAppProfileSuspendedADocument;

  /// No description provided for @guideAppRateCommentHint.
  ///
  /// In es, this message translates to:
  /// **'Cuenta cómo fue: puntualidad, trato, si siguió las indicaciones…'**
  String get guideAppRateCommentHint;

  /// No description provided for @guideAppRateMissingStars.
  ///
  /// In es, this message translates to:
  /// **'Elige cuántas estrellas le das'**
  String get guideAppRateMissingStars;

  /// No description provided for @guideAppRateQuestion.
  ///
  /// In es, this message translates to:
  /// **'¿Cómo fue trabajar con {name}?'**
  String guideAppRateQuestion(String name);

  /// No description provided for @guideAppRateSent.
  ///
  /// In es, this message translates to:
  /// **'Calificación enviada. Gracias por ayudar a otros guías.'**
  String get guideAppRateSent;

  /// No description provided for @guideAppRateStars.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 estrella} other{{count} estrellas}}'**
  String guideAppRateStars(int count);

  /// No description provided for @guideAppRateSubmit.
  ///
  /// In es, this message translates to:
  /// **'Enviar calificación'**
  String get guideAppRateSubmit;

  /// No description provided for @guideAppRateTourist.
  ///
  /// In es, this message translates to:
  /// **'Calificar a {name}'**
  String guideAppRateTourist(String name);

  /// No description provided for @guideAppRateVisibility.
  ///
  /// In es, this message translates to:
  /// **'Solo otros guías verán tu calificación.'**
  String get guideAppRateVisibility;

  /// No description provided for @guideAppRatingAverage.
  ///
  /// In es, this message translates to:
  /// **'{average} de guías'**
  String guideAppRatingAverage(String average);

  /// No description provided for @guideAppRatingAverageNamed.
  ///
  /// In es, this message translates to:
  /// **'{average} de guías · {name}'**
  String guideAppRatingAverageNamed(String average, String name);

  /// No description provided for @guideAppRatingNone.
  ///
  /// In es, this message translates to:
  /// **'Sin calificaciones de guías'**
  String get guideAppRatingNone;

  /// No description provided for @guideAppRatingNoneNamed.
  ///
  /// In es, this message translates to:
  /// **'Sin calificaciones de guías · {name}'**
  String guideAppRatingNoneNamed(String name);

  /// No description provided for @guideAppSeeProposals.
  ///
  /// In es, this message translates to:
  /// **'Ver propuestas'**
  String get guideAppSeeProposals;

  /// No description provided for @guideAppServiceHours.
  ///
  /// In es, this message translates to:
  /// **'{hours} h de servicio'**
  String guideAppServiceHours(int hours);

  /// No description provided for @guideAppTheTourist.
  ///
  /// In es, this message translates to:
  /// **'el turista'**
  String get guideAppTheTourist;

  /// No description provided for @guideAppTheTouristCapital.
  ///
  /// In es, this message translates to:
  /// **'El turista'**
  String get guideAppTheTouristCapital;

  /// No description provided for @guideAppThreadEmpty.
  ///
  /// In es, this message translates to:
  /// **'Escribe para acordar el punto de encuentro.'**
  String get guideAppThreadEmpty;

  /// No description provided for @guideAppThreadHint.
  ///
  /// In es, this message translates to:
  /// **'Escribe un mensaje…'**
  String get guideAppThreadHint;

  /// No description provided for @guideAppThreadSend.
  ///
  /// In es, this message translates to:
  /// **'Enviar'**
  String get guideAppThreadSend;

  /// No description provided for @guideAppThreadTitle.
  ///
  /// In es, this message translates to:
  /// **'Conversación'**
  String get guideAppThreadTitle;

  /// No description provided for @guideAppTouristNoRatingsMessage.
  ///
  /// In es, this message translates to:
  /// **'Cuando un guía termine un viaje con {name}, su opinión aparecerá aquí.'**
  String guideAppTouristNoRatingsMessage(String name);

  /// No description provided for @guideAppTouristNoRatingsTitle.
  ///
  /// In es, this message translates to:
  /// **'Todavía sin calificaciones'**
  String get guideAppTouristNoRatingsTitle;

  /// No description provided for @guideAppTouristNotFoundMessage.
  ///
  /// In es, this message translates to:
  /// **'Puede que haya cerrado su cuenta.'**
  String get guideAppTouristNotFoundMessage;

  /// No description provided for @guideAppTouristNotFoundTitle.
  ///
  /// In es, this message translates to:
  /// **'No encontramos a este turista'**
  String get guideAppTouristNotFoundTitle;

  /// No description provided for @guideAppTouristRatedAlready.
  ///
  /// In es, this message translates to:
  /// **'Ya calificaste a {name}. Si vuelven a viajar juntos, podrás calificarlo otra vez.'**
  String guideAppTouristRatedAlready(String name);

  /// No description provided for @guideAppTouristRatedFor.
  ///
  /// In es, this message translates to:
  /// **'Por {circuit} del {date}.'**
  String guideAppTouristRatedFor(String circuit, String date);

  /// No description provided for @guideAppTouristRateLater.
  ///
  /// In es, this message translates to:
  /// **'Podrás calificar a {name} cuando terminen un viaje juntos.'**
  String guideAppTouristRateLater(String name);

  /// No description provided for @guideAppTouristRatingCount.
  ///
  /// In es, this message translates to:
  /// **'de {count, plural, =1{1 guía} other{{count} guías}}'**
  String guideAppTouristRatingCount(int count);

  /// No description provided for @guideAppTouristRatingsNotice.
  ///
  /// In es, this message translates to:
  /// **'Solo los guías de K’Plan ven estas calificaciones. {name} no las ve.'**
  String guideAppTouristRatingsNotice(String name);

  /// No description provided for @guideAppTouristRatingsTitle.
  ///
  /// In es, this message translates to:
  /// **'Calificaciones de guías'**
  String get guideAppTouristRatingsTitle;

  /// No description provided for @guideAppTouristSince.
  ///
  /// In es, this message translates to:
  /// **'{country} · En K’Plan desde {year}'**
  String guideAppTouristSince(String country, int year);

  /// No description provided for @guideAppTouristTileDetails.
  ///
  /// In es, this message translates to:
  /// **'{country} · {count, plural, =1{1 viaje} other{{count} viajes}} con K’Plan'**
  String guideAppTouristTileDetails(String country, int count);

  /// No description provided for @guideAppTouristTrips.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 viaje con K’Plan} other{{count} viajes con K’Plan}}'**
  String guideAppTouristTrips(int count);

  /// No description provided for @guideAppTransportGuide.
  ///
  /// In es, this message translates to:
  /// **'Tú pones el transporte'**
  String get guideAppTransportGuide;

  /// No description provided for @guideAppTransportOnFoot.
  ///
  /// In es, this message translates to:
  /// **'Recorrido a pie'**
  String get guideAppTransportOnFoot;

  /// No description provided for @guideAppTransportTourist.
  ///
  /// In es, this message translates to:
  /// **'El turista pone el transporte'**
  String get guideAppTransportTourist;

  /// No description provided for @guideAppTripMeetingPending.
  ///
  /// In es, this message translates to:
  /// **'{city} · Punto de encuentro por acordar en el chat'**
  String guideAppTripMeetingPending(String city);

  /// No description provided for @guideAppTripMessageTourist.
  ///
  /// In es, this message translates to:
  /// **'Escribir a {name}'**
  String guideAppTripMessageTourist(String name);

  /// No description provided for @guideAppTripNotFoundMessage.
  ///
  /// In es, this message translates to:
  /// **'Revisa tus viajes desde la pestaña Viajes.'**
  String get guideAppTripNotFoundMessage;

  /// No description provided for @guideAppTripNotFoundTitle.
  ///
  /// In es, this message translates to:
  /// **'No encontramos este viaje'**
  String get guideAppTripNotFoundTitle;

  /// No description provided for @guideAppTripPayment.
  ///
  /// In es, this message translates to:
  /// **'Pago'**
  String get guideAppTripPayment;

  /// No description provided for @guideAppTripPaymentNote.
  ///
  /// In es, this message translates to:
  /// **'Pasa a tu balance cuando termine el viaje.'**
  String get guideAppTripPaymentNote;

  /// No description provided for @guideAppTripRate.
  ///
  /// In es, this message translates to:
  /// **'Calificar'**
  String get guideAppTripRate;

  /// No description provided for @guideAppTripRated.
  ///
  /// In es, this message translates to:
  /// **'Ya calificaste a {name} por este viaje.'**
  String guideAppTripRated(String name);

  /// No description provided for @guideAppTripsEmptyDoneMessage.
  ///
  /// In es, this message translates to:
  /// **'Después de cada viaje podrás calificar al turista para ayudar a otros guías.'**
  String get guideAppTripsEmptyDoneMessage;

  /// No description provided for @guideAppTripsEmptyDoneTitle.
  ///
  /// In es, this message translates to:
  /// **'Aquí verás los viajes que termines'**
  String get guideAppTripsEmptyDoneTitle;

  /// No description provided for @guideAppTripsEmptyUpcomingMessage.
  ///
  /// In es, this message translates to:
  /// **'Postúlate a una propuesta desde Inicio; cuando un turista te contrate, el viaje aparece aquí.'**
  String get guideAppTripsEmptyUpcomingMessage;

  /// No description provided for @guideAppTripsEmptyUpcomingTitle.
  ///
  /// In es, this message translates to:
  /// **'Todavía no tienes viajes próximos'**
  String get guideAppTripsEmptyUpcomingTitle;

  /// No description provided for @guideAppTripsTabDone.
  ///
  /// In es, this message translates to:
  /// **'Realizados'**
  String get guideAppTripsTabDone;

  /// No description provided for @guideAppTripsTabDoneToRate.
  ///
  /// In es, this message translates to:
  /// **'Realizados · {count} por calificar'**
  String guideAppTripsTabDoneToRate(int count);

  /// No description provided for @guideAppTripsTabUpcoming.
  ///
  /// In es, this message translates to:
  /// **'Próximos'**
  String get guideAppTripsTabUpcoming;

  /// No description provided for @guideAppTripStatusDone.
  ///
  /// In es, this message translates to:
  /// **'Terminado'**
  String get guideAppTripStatusDone;

  /// No description provided for @guideAppTripStatusUpcoming.
  ///
  /// In es, this message translates to:
  /// **'Próximo'**
  String get guideAppTripStatusUpcoming;

  /// No description provided for @guideAppTripTitle.
  ///
  /// In es, this message translates to:
  /// **'Viaje'**
  String get guideAppTripTitle;

  /// No description provided for @guideAppTripViewChat.
  ///
  /// In es, this message translates to:
  /// **'Ver la conversación'**
  String get guideAppTripViewChat;

  /// No description provided for @guideAppViewTrip.
  ///
  /// In es, this message translates to:
  /// **'Ver viaje'**
  String get guideAppViewTrip;

  /// No description provided for @guideAppWithdraw.
  ///
  /// In es, this message translates to:
  /// **'Retirar'**
  String get guideAppWithdraw;

  /// No description provided for @guideAppWithdrawAmountLabel.
  ///
  /// In es, this message translates to:
  /// **'Monto (C\$)'**
  String get guideAppWithdrawAmountLabel;

  /// No description provided for @guideAppWithdrawAmountRequired.
  ///
  /// In es, this message translates to:
  /// **'Escribe cuánto quieres retirar'**
  String get guideAppWithdrawAmountRequired;

  /// No description provided for @guideAppWithdrawAvailable.
  ///
  /// In es, this message translates to:
  /// **'Disponible: {amount}'**
  String guideAppWithdrawAvailable(String amount);

  /// No description provided for @guideAppWithdrawNotice.
  ///
  /// In es, this message translates to:
  /// **'Te avisaremos aquí cuando llegue a tu cuenta.'**
  String get guideAppWithdrawNotice;

  /// No description provided for @guideAppWithdrawOverBalance.
  ///
  /// In es, this message translates to:
  /// **'Solo tienes {amount} disponibles'**
  String guideAppWithdrawOverBalance(String amount);

  /// No description provided for @guideAppWithdrawToAccount.
  ///
  /// In es, this message translates to:
  /// **'A tu cuenta'**
  String get guideAppWithdrawToAccount;

  /// No description provided for @guideAppYouReceive.
  ///
  /// In es, this message translates to:
  /// **'Recibes {amount}'**
  String guideAppYouReceive(String amount);

  /// No description provided for @guideAppYouReceived.
  ///
  /// In es, this message translates to:
  /// **'Recibiste {amount}'**
  String guideAppYouReceived(String amount);

  /// No description provided for @guideChatAgreedPrice.
  ///
  /// In es, this message translates to:
  /// **'Precio acordado: {price} · Pago y reserva: a definir'**
  String guideChatAgreedPrice(String price);

  /// No description provided for @guideChatEmpty.
  ///
  /// In es, this message translates to:
  /// **'Escribe para coordinar el punto de encuentro.'**
  String get guideChatEmpty;

  /// No description provided for @guideChatMessageHint.
  ///
  /// In es, this message translates to:
  /// **'Escribe un mensaje…'**
  String get guideChatMessageHint;

  /// No description provided for @guideChatNamePair.
  ///
  /// In es, this message translates to:
  /// **'{first} y {second}'**
  String guideChatNamePair(String first, String second);

  /// No description provided for @guideDeskAlreadyApplied.
  ///
  /// In es, this message translates to:
  /// **'Ya te postulaste'**
  String get guideDeskAlreadyApplied;

  /// No description provided for @guideDeskApplied.
  ///
  /// In es, this message translates to:
  /// **'Te postulaste: el turista verá tu precio y tu mensaje.'**
  String get guideDeskApplied;

  /// No description provided for @guideDeskApply.
  ///
  /// In es, this message translates to:
  /// **'Postularme'**
  String get guideDeskApply;

  /// No description provided for @guideDeskApplyFee.
  ///
  /// In es, this message translates to:
  /// **'Tu precio (C\$)'**
  String get guideDeskApplyFee;

  /// No description provided for @guideDeskApplyFeeMissing.
  ///
  /// In es, this message translates to:
  /// **'Escribe tu precio'**
  String get guideDeskApplyFeeMissing;

  /// No description provided for @guideDeskApplyMaxFee.
  ///
  /// In es, this message translates to:
  /// **'Hasta {amount}'**
  String guideDeskApplyMaxFee(String amount);

  /// No description provided for @guideDeskApplyMessage.
  ///
  /// In es, this message translates to:
  /// **'Un mensaje para el turista (opcional)'**
  String get guideDeskApplyMessage;

  /// No description provided for @guideDeskApplyTitle.
  ///
  /// In es, this message translates to:
  /// **'Postularte a la convocatoria'**
  String get guideDeskApplyTitle;

  /// No description provided for @guideDeskBidAccepted.
  ///
  /// In es, this message translates to:
  /// **'Te eligieron'**
  String get guideDeskBidAccepted;

  /// No description provided for @guideDeskBidRejected.
  ///
  /// In es, this message translates to:
  /// **'Eligieron a otra persona'**
  String get guideDeskBidRejected;

  /// No description provided for @guideDeskBidsEmpty.
  ///
  /// In es, this message translates to:
  /// **'Todavía no te postulas a ninguna convocatoria.'**
  String get guideDeskBidsEmpty;

  /// No description provided for @guideDeskBidSent.
  ///
  /// In es, this message translates to:
  /// **'Enviada'**
  String get guideDeskBidSent;

  /// No description provided for @guideDeskBidsTitle.
  ///
  /// In es, this message translates to:
  /// **'Mis postulaciones'**
  String get guideDeskBidsTitle;

  /// No description provided for @guideDeskBidTitle.
  ///
  /// In es, this message translates to:
  /// **'Convocatoria'**
  String get guideDeskBidTitle;

  /// No description provided for @guideDeskBidWithdrawn.
  ///
  /// In es, this message translates to:
  /// **'Retirada'**
  String get guideDeskBidWithdrawn;

  /// No description provided for @guideDeskBookingsEmpty.
  ///
  /// In es, this message translates to:
  /// **'Cuando un turista reserve contigo, su reserva aparecerá aquí.'**
  String get guideDeskBookingsEmpty;

  /// No description provided for @guideDeskBookingsTitle.
  ///
  /// In es, this message translates to:
  /// **'Mis reservas'**
  String get guideDeskBookingsTitle;

  /// No description provided for @guideDeskChatsEmpty.
  ///
  /// In es, this message translates to:
  /// **'Cada reserva tiene su chat con el turista. Todavía no tienes reservas.'**
  String get guideDeskChatsEmpty;

  /// No description provided for @guideDeskDepartureCancel.
  ///
  /// In es, this message translates to:
  /// **'Cancelar salida'**
  String get guideDeskDepartureCancel;

  /// No description provided for @guideDeskDepartureCancelled.
  ///
  /// In es, this message translates to:
  /// **'Salida cancelada. Avisamos a quienes habían reservado.'**
  String get guideDeskDepartureCancelled;

  /// No description provided for @guideDeskDepartureCancelTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Cancelar la salida? Sus reservas también se cancelan.'**
  String get guideDeskDepartureCancelTitle;

  /// No description provided for @guideDeskDepartureCapacity.
  ///
  /// In es, this message translates to:
  /// **'Cupo'**
  String get guideDeskDepartureCapacity;

  /// No description provided for @guideDeskDepartureCircuit.
  ///
  /// In es, this message translates to:
  /// **'Circuito'**
  String get guideDeskDepartureCircuit;

  /// No description provided for @guideDeskDepartureCircuitMissing.
  ///
  /// In es, this message translates to:
  /// **'Elige un circuito'**
  String get guideDeskDepartureCircuitMissing;

  /// No description provided for @guideDeskDepartureEdit.
  ///
  /// In es, this message translates to:
  /// **'Editar'**
  String get guideDeskDepartureEdit;

  /// No description provided for @guideDeskDepartureEditTitle.
  ///
  /// In es, this message translates to:
  /// **'Editar la salida'**
  String get guideDeskDepartureEditTitle;

  /// No description provided for @guideDeskDepartureExclusive.
  ///
  /// In es, this message translates to:
  /// **'Privada'**
  String get guideDeskDepartureExclusive;

  /// No description provided for @guideDeskDepartureNote.
  ///
  /// In es, this message translates to:
  /// **'Nota para los turistas (opcional)'**
  String get guideDeskDepartureNote;

  /// No description provided for @guideDeskDeparturePublish.
  ///
  /// In es, this message translates to:
  /// **'Publicar salida'**
  String get guideDeskDeparturePublish;

  /// No description provided for @guideDeskDeparturePublished.
  ///
  /// In es, this message translates to:
  /// **'Salida publicada: ya la ven los turistas.'**
  String get guideDeskDeparturePublished;

  /// No description provided for @guideDeskDeparturePublishTitle.
  ///
  /// In es, this message translates to:
  /// **'Publicar una salida'**
  String get guideDeskDeparturePublishTitle;

  /// No description provided for @guideDeskDepartureSaved.
  ///
  /// In es, this message translates to:
  /// **'Salida actualizada'**
  String get guideDeskDepartureSaved;

  /// No description provided for @guideDeskDeparturesEmpty.
  ///
  /// In es, this message translates to:
  /// **'Publica una salida en un circuito oficial de tu ciudad para que los turistas la reserven.'**
  String get guideDeskDeparturesEmpty;

  /// No description provided for @guideDeskDeparturesTitle.
  ///
  /// In es, this message translates to:
  /// **'Mis salidas'**
  String get guideDeskDeparturesTitle;

  /// No description provided for @guideDeskDepartureTime.
  ///
  /// In es, this message translates to:
  /// **'Hora de salida'**
  String get guideDeskDepartureTime;

  /// No description provided for @guideDeskDepartureTransport.
  ///
  /// In es, this message translates to:
  /// **'Incluyo el transporte'**
  String get guideDeskDepartureTransport;

  /// No description provided for @guideDeskLess.
  ///
  /// In es, this message translates to:
  /// **'Menos'**
  String get guideDeskLess;

  /// No description provided for @guideDeskMore.
  ///
  /// In es, this message translates to:
  /// **'Más'**
  String get guideDeskMore;

  /// No description provided for @guideDeskOpenRequestsEmpty.
  ///
  /// In es, this message translates to:
  /// **'No hay convocatorias abiertas en tu ciudad por ahora.'**
  String get guideDeskOpenRequestsEmpty;

  /// No description provided for @guideDeskOpenRequestsTitle.
  ///
  /// In es, this message translates to:
  /// **'Convocatorias abiertas'**
  String get guideDeskOpenRequestsTitle;

  /// No description provided for @guideDeskStops.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 parada} other{{count} paradas}}'**
  String guideDeskStops(int count);

  /// No description provided for @guideDeskWithdraw.
  ///
  /// In es, this message translates to:
  /// **'Retirar postulación'**
  String get guideDeskWithdraw;

  /// No description provided for @guideDeskWithdrawn.
  ///
  /// In es, this message translates to:
  /// **'Postulación retirada'**
  String get guideDeskWithdrawn;

  /// No description provided for @guideDeskWithdrawTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Retirar tu postulación?'**
  String get guideDeskWithdrawTitle;

  /// No description provided for @guideFinanceAccountActive.
  ///
  /// In es, this message translates to:
  /// **'Recibe tus retiros'**
  String get guideFinanceAccountActive;

  /// No description provided for @guideFinanceAccountAdd.
  ///
  /// In es, this message translates to:
  /// **'Agregar'**
  String get guideFinanceAccountAdd;

  /// No description provided for @guideFinanceAccountBank.
  ///
  /// In es, this message translates to:
  /// **'Banco'**
  String get guideFinanceAccountBank;

  /// No description provided for @guideFinanceAccountBankMissing.
  ///
  /// In es, this message translates to:
  /// **'Escribe el banco'**
  String get guideFinanceAccountBankMissing;

  /// No description provided for @guideFinanceAccountChange.
  ///
  /// In es, this message translates to:
  /// **'Cambiar'**
  String get guideFinanceAccountChange;

  /// No description provided for @guideFinanceAccountChecking.
  ///
  /// In es, this message translates to:
  /// **'Corriente'**
  String get guideFinanceAccountChecking;

  /// No description provided for @guideFinanceAccountHolder.
  ///
  /// In es, this message translates to:
  /// **'Titular de la cuenta'**
  String get guideFinanceAccountHolder;

  /// No description provided for @guideFinanceAccountHolderMissing.
  ///
  /// In es, this message translates to:
  /// **'Escribe el nombre del titular'**
  String get guideFinanceAccountHolderMissing;

  /// No description provided for @guideFinanceAccountNone.
  ///
  /// In es, this message translates to:
  /// **'Todavía no tienes una cuenta para recibir tus retiros.'**
  String get guideFinanceAccountNone;

  /// No description provided for @guideFinanceAccountNumber.
  ///
  /// In es, this message translates to:
  /// **'Número de cuenta'**
  String get guideFinanceAccountNumber;

  /// No description provided for @guideFinanceAccountNumberInvalid.
  ///
  /// In es, this message translates to:
  /// **'Escribe el número completo (solo números, espacios o guiones)'**
  String get guideFinanceAccountNumberInvalid;

  /// No description provided for @guideFinanceAccountPendingFrom.
  ///
  /// In es, this message translates to:
  /// **'El cambio vale desde el {day} a las {time}'**
  String guideFinanceAccountPendingFrom(String day, String time);

  /// No description provided for @guideFinanceAccountSaved.
  ///
  /// In es, this message translates to:
  /// **'Cuenta guardada'**
  String get guideFinanceAccountSaved;

  /// No description provided for @guideFinanceAccountSavings.
  ///
  /// In es, this message translates to:
  /// **'Ahorro'**
  String get guideFinanceAccountSavings;

  /// No description provided for @guideFinanceAccountTitle.
  ///
  /// In es, this message translates to:
  /// **'Cuenta bancaria'**
  String get guideFinanceAccountTitle;

  /// No description provided for @guideFinanceAccountWait.
  ///
  /// In es, this message translates to:
  /// **'La primera cuenta vale de una vez; un cambio espera 24 horas por seguridad.'**
  String get guideFinanceAccountWait;

  /// No description provided for @guideFinanceAvailable.
  ///
  /// In es, this message translates to:
  /// **'Puedes retirar hasta {amount}'**
  String guideFinanceAvailable(String amount);

  /// No description provided for @guideFinanceBalance.
  ///
  /// In es, this message translates to:
  /// **'Saldo disponible'**
  String get guideFinanceBalance;

  /// No description provided for @guideFinanceMovementReturned.
  ///
  /// In es, this message translates to:
  /// **'Retiro devuelto'**
  String get guideFinanceMovementReturned;

  /// No description provided for @guideFinanceMovementsEmpty.
  ///
  /// In es, this message translates to:
  /// **'Todavía no hay movimientos.'**
  String get guideFinanceMovementsEmpty;

  /// No description provided for @guideFinanceMovementService.
  ///
  /// In es, this message translates to:
  /// **'Recorrido'**
  String get guideFinanceMovementService;

  /// No description provided for @guideFinanceMovementsTitle.
  ///
  /// In es, this message translates to:
  /// **'Movimientos'**
  String get guideFinanceMovementsTitle;

  /// No description provided for @guideFinanceMovementWithdrawal.
  ///
  /// In es, this message translates to:
  /// **'Retiro'**
  String get guideFinanceMovementWithdrawal;

  /// No description provided for @guideFinanceNeedsAccount.
  ///
  /// In es, this message translates to:
  /// **'Agrega una cuenta bancaria para pedir retiros.'**
  String get guideFinanceNeedsAccount;

  /// No description provided for @guideFinancePayoutAmount.
  ///
  /// In es, this message translates to:
  /// **'Monto (C\$)'**
  String get guideFinancePayoutAmount;

  /// No description provided for @guideFinancePayoutAmountMissing.
  ///
  /// In es, this message translates to:
  /// **'Escribe el monto'**
  String get guideFinancePayoutAmountMissing;

  /// No description provided for @guideFinancePayoutPaid.
  ///
  /// In es, this message translates to:
  /// **'Depositado'**
  String get guideFinancePayoutPaid;

  /// No description provided for @guideFinancePayoutPending.
  ///
  /// In es, this message translates to:
  /// **'En proceso'**
  String get guideFinancePayoutPending;

  /// No description provided for @guideFinancePayoutRejected.
  ///
  /// In es, this message translates to:
  /// **'Rechazado'**
  String get guideFinancePayoutRejected;

  /// No description provided for @guideFinancePayoutRequest.
  ///
  /// In es, this message translates to:
  /// **'Pedir un retiro'**
  String get guideFinancePayoutRequest;

  /// No description provided for @guideFinancePayoutRequested.
  ///
  /// In es, this message translates to:
  /// **'Pediste el retiro: el equipo lo depositará en tu cuenta.'**
  String get guideFinancePayoutRequested;

  /// No description provided for @guideFinancePayoutsEmpty.
  ///
  /// In es, this message translates to:
  /// **'Todavía no has pedido retiros.'**
  String get guideFinancePayoutsEmpty;

  /// No description provided for @guideFinancePayoutsTitle.
  ///
  /// In es, this message translates to:
  /// **'Mis retiros'**
  String get guideFinancePayoutsTitle;

  /// No description provided for @guideFinancePayoutTitle.
  ///
  /// In es, this message translates to:
  /// **'Pedir un retiro'**
  String get guideFinancePayoutTitle;

  /// No description provided for @guideFinancePendingPayouts.
  ///
  /// In es, this message translates to:
  /// **'{amount} en retiros por depositar'**
  String guideFinancePendingPayouts(String amount);

  /// No description provided for @guideFinanceTitle.
  ///
  /// In es, this message translates to:
  /// **'Mi dinero'**
  String get guideFinanceTitle;

  /// No description provided for @guideProfileAcceptsBudget.
  ///
  /// In es, this message translates to:
  /// **'Acepta tu presupuesto'**
  String get guideProfileAcceptsBudget;

  /// No description provided for @guideProfileAppliedAsGuide.
  ///
  /// In es, this message translates to:
  /// **'Se postuló como guía a tu propuesta'**
  String get guideProfileAppliedAsGuide;

  /// No description provided for @guideProfileAppliedAsTranslator.
  ///
  /// In es, this message translates to:
  /// **'Se postuló como traductor a tu propuesta'**
  String get guideProfileAppliedAsTranslator;

  /// No description provided for @guideProfileChat.
  ///
  /// In es, this message translates to:
  /// **'Chatear'**
  String get guideProfileChat;

  /// No description provided for @guideProfileDeparturesTitle.
  ///
  /// In es, this message translates to:
  /// **'Próximas salidas'**
  String get guideProfileDeparturesTitle;

  /// No description provided for @guideProfileHasVehicle.
  ///
  /// In es, this message translates to:
  /// **'Tiene vehículo propio'**
  String get guideProfileHasVehicle;

  /// No description provided for @guideProfileHiredAsGuide.
  ///
  /// In es, this message translates to:
  /// **'Contratado como guía'**
  String get guideProfileHiredAsGuide;

  /// No description provided for @guideProfileHiredAsTranslator.
  ///
  /// In es, this message translates to:
  /// **'Contratado como traductor'**
  String get guideProfileHiredAsTranslator;

  /// No description provided for @guideProfileHireFor.
  ///
  /// In es, this message translates to:
  /// **'Contratar por {price}'**
  String guideProfileHireFor(String price);

  /// No description provided for @guideProfileLessThanBudget.
  ///
  /// In es, this message translates to:
  /// **'{amount} menos que tu presupuesto'**
  String guideProfileLessThanBudget(String amount);

  /// No description provided for @guideProfileMoreThanBudget.
  ///
  /// In es, this message translates to:
  /// **'{amount} más que tu presupuesto'**
  String guideProfileMoreThanBudget(String amount);

  /// No description provided for @guideProfileNoTransport.
  ///
  /// In es, this message translates to:
  /// **'No pone transporte'**
  String get guideProfileNoTransport;

  /// No description provided for @guideProfileNoVehicle.
  ///
  /// In es, this message translates to:
  /// **'Sin vehículo propio'**
  String get guideProfileNoVehicle;

  /// No description provided for @guideProfileOffersTransport.
  ///
  /// In es, this message translates to:
  /// **'Pone transporte para tu grupo'**
  String get guideProfileOffersTransport;

  /// No description provided for @guideProfilePaymentPending.
  ///
  /// In es, this message translates to:
  /// **'Pago y reserva: a definir'**
  String get guideProfilePaymentPending;

  /// No description provided for @guideProfileReviewsCount.
  ///
  /// In es, this message translates to:
  /// **'Reseñas ({count})'**
  String guideProfileReviewsCount(int count);

  /// No description provided for @guideProfileTitle.
  ///
  /// In es, this message translates to:
  /// **'Perfil del guía'**
  String get guideProfileTitle;

  /// No description provided for @guideRequestApplicationsTitle.
  ///
  /// In es, this message translates to:
  /// **'Postulaciones'**
  String get guideRequestApplicationsTitle;

  /// No description provided for @guideRequestApplicationsTitleCount.
  ///
  /// In es, this message translates to:
  /// **'Postulaciones ({count})'**
  String guideRequestApplicationsTitleCount(int count);

  /// No description provided for @guideRequestApplicationUnavailable.
  ///
  /// In es, this message translates to:
  /// **'Esta postulación ya no está disponible'**
  String get guideRequestApplicationUnavailable;

  /// No description provided for @guideRequestBudget.
  ///
  /// In es, this message translates to:
  /// **'Presupuesto: {total}'**
  String guideRequestBudget(String total);

  /// No description provided for @guideRequestBudgetBoth.
  ///
  /// In es, this message translates to:
  /// **'Presupuesto: {total} (guía {guide} + traductor {translator})'**
  String guideRequestBudgetBoth(String total, String guide, String translator);

  /// No description provided for @guideRequestCancelAction.
  ///
  /// In es, this message translates to:
  /// **'Retirar propuesta'**
  String get guideRequestCancelAction;

  /// No description provided for @guideRequestCancelConfirm.
  ///
  /// In es, this message translates to:
  /// **'Retirar'**
  String get guideRequestCancelConfirm;

  /// No description provided for @guideRequestCancelMessage.
  ///
  /// In es, this message translates to:
  /// **'Los guías ya no podrán postularse. Tu reserva del circuito sigue agendada.'**
  String get guideRequestCancelMessage;

  /// No description provided for @guideRequestCancelTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Retirar tu propuesta?'**
  String get guideRequestCancelTitle;

  /// No description provided for @guideRequestGoToChat.
  ///
  /// In es, this message translates to:
  /// **'Ir al chat'**
  String get guideRequestGoToChat;

  /// No description provided for @guideRequestGuidesTitle.
  ///
  /// In es, this message translates to:
  /// **'Guías'**
  String get guideRequestGuidesTitle;

  /// No description provided for @guideRequestGuidesTitleCount.
  ///
  /// In es, this message translates to:
  /// **'Guías ({count})'**
  String guideRequestGuidesTitleCount(int count);

  /// No description provided for @guideRequestHire.
  ///
  /// In es, this message translates to:
  /// **'Contratar'**
  String get guideRequestHire;

  /// No description provided for @guideRequestHired.
  ///
  /// In es, this message translates to:
  /// **'Contratado'**
  String get guideRequestHired;

  /// No description provided for @guideRequestHireMessageGuide.
  ///
  /// In es, this message translates to:
  /// **'Será tu guía por {price}. Las demás postulaciones para este puesto quedan descartadas.'**
  String guideRequestHireMessageGuide(String price);

  /// No description provided for @guideRequestHireMessageTranslator.
  ///
  /// In es, this message translates to:
  /// **'Será tu traductor por {price}. Las demás postulaciones para este puesto quedan descartadas.'**
  String guideRequestHireMessageTranslator(String price);

  /// No description provided for @guideRequestHireNextGuide.
  ///
  /// In es, this message translates to:
  /// **'¡Listo! Ahora elige a tu guía.'**
  String get guideRequestHireNextGuide;

  /// No description provided for @guideRequestHireNextTranslator.
  ///
  /// In es, this message translates to:
  /// **'¡Listo! Ahora elige a tu traductor.'**
  String get guideRequestHireNextTranslator;

  /// No description provided for @guideRequestHireTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Contratar a {name}?'**
  String guideRequestHireTitle(String name);

  /// No description provided for @guideRequestLodgingProvided.
  ///
  /// In es, this message translates to:
  /// **'Le das alojamiento al guía'**
  String get guideRequestLodgingProvided;

  /// No description provided for @guideRequestNoMaxFee.
  ///
  /// In es, this message translates to:
  /// **'Sin tope de precio: cada guía propone el suyo'**
  String get guideRequestNoMaxFee;

  /// No description provided for @guideRequestNoneSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Publica una al agendar un circuito, desde \"Guía o traductor\".'**
  String get guideRequestNoneSubtitle;

  /// No description provided for @guideRequestNoneTitle.
  ///
  /// In es, this message translates to:
  /// **'No tienes una propuesta activa'**
  String get guideRequestNoneTitle;

  /// No description provided for @guideRequestNoTransport.
  ///
  /// In es, this message translates to:
  /// **'Sin transporte'**
  String get guideRequestNoTransport;

  /// No description provided for @guideRequestOffersTransport.
  ///
  /// In es, this message translates to:
  /// **'Pone transporte'**
  String get guideRequestOffersTransport;

  /// No description provided for @guideRequestPriceLess.
  ///
  /// In es, this message translates to:
  /// **'{amount} menos'**
  String guideRequestPriceLess(String amount);

  /// No description provided for @guideRequestPriceMore.
  ///
  /// In es, this message translates to:
  /// **'{amount} más'**
  String guideRequestPriceMore(String amount);

  /// No description provided for @guideRequestPriceYourBudget.
  ///
  /// In es, this message translates to:
  /// **'Tu presupuesto'**
  String get guideRequestPriceYourBudget;

  /// No description provided for @guideRequestRoleBoth.
  ///
  /// In es, this message translates to:
  /// **'Guía y traductor'**
  String get guideRequestRoleBoth;

  /// No description provided for @guideRequestStatusCancelledSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Los guías ya no pueden postularse.'**
  String get guideRequestStatusCancelledSubtitle;

  /// No description provided for @guideRequestStatusCancelledTitle.
  ///
  /// In es, this message translates to:
  /// **'Retiraste esta propuesta'**
  String get guideRequestStatusCancelledTitle;

  /// No description provided for @guideRequestStatusExpiredSubtitle.
  ///
  /// In es, this message translates to:
  /// **'No contrataste a nadie a tiempo. Puedes publicar otra desde Agendar.'**
  String get guideRequestStatusExpiredSubtitle;

  /// No description provided for @guideRequestStatusExpiredTitle.
  ///
  /// In es, this message translates to:
  /// **'Tu propuesta venció'**
  String get guideRequestStatusExpiredTitle;

  /// No description provided for @guideRequestStatusHiredSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Acordaste {price} por el servicio.'**
  String guideRequestStatusHiredSubtitle(String price);

  /// No description provided for @guideRequestStatusHiredTitle.
  ///
  /// In es, this message translates to:
  /// **'¡Listo! Ya tienes quién te acompañe'**
  String get guideRequestStatusHiredTitle;

  /// No description provided for @guideRequestStatusOpenSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Los guías ya pueden verla. Vence en {remaining}.'**
  String guideRequestStatusOpenSubtitle(String remaining);

  /// No description provided for @guideRequestStatusOpenTitle.
  ///
  /// In es, this message translates to:
  /// **'Publicada · recibiendo postulaciones'**
  String get guideRequestStatusOpenTitle;

  /// No description provided for @guideRequestTeamTitle.
  ///
  /// In es, this message translates to:
  /// **'Tu equipo'**
  String get guideRequestTeamTitle;

  /// No description provided for @guideRequestTitle.
  ///
  /// In es, this message translates to:
  /// **'Tu propuesta'**
  String get guideRequestTitle;

  /// No description provided for @guideRequestTranslatorsTitle.
  ///
  /// In es, this message translates to:
  /// **'Traductores'**
  String get guideRequestTranslatorsTitle;

  /// No description provided for @guideRequestTranslatorsTitleCount.
  ///
  /// In es, this message translates to:
  /// **'Traductores ({count})'**
  String guideRequestTranslatorsTitleCount(int count);

  /// No description provided for @guideRequestTransportGuide.
  ///
  /// In es, this message translates to:
  /// **'El guía pone el transporte'**
  String get guideRequestTransportGuide;

  /// No description provided for @guideRequestTransportOnFoot.
  ///
  /// In es, this message translates to:
  /// **'Recorrido a pie'**
  String get guideRequestTransportOnFoot;

  /// No description provided for @guideRequestTransportTourist.
  ///
  /// In es, this message translates to:
  /// **'Tú pones el transporte'**
  String get guideRequestTransportTourist;

  /// No description provided for @guideRequestWaitingGuides.
  ///
  /// In es, this message translates to:
  /// **'Esperando postulaciones de guías. Te avisamos aquí apenas alguien se postule.'**
  String get guideRequestWaitingGuides;

  /// No description provided for @guideRequestWaitingTranslators.
  ///
  /// In es, this message translates to:
  /// **'Esperando postulaciones de traductores. Te avisamos aquí apenas alguien se postule.'**
  String get guideRequestWaitingTranslators;

  /// No description provided for @guideRequestWaitingTranslatorsLanguage.
  ///
  /// In es, this message translates to:
  /// **'Esperando postulaciones de traductores de {language}. Te avisamos aquí apenas alguien se postule.'**
  String guideRequestWaitingTranslatorsLanguage(String language);

  /// No description provided for @guideRequestYearsExperience.
  ///
  /// In es, this message translates to:
  /// **'{years, plural, =1{1 año de experiencia} other{{years} años de experiencia}}'**
  String guideRequestYearsExperience(int years);

  /// No description provided for @guidesEmptyMessage.
  ///
  /// In es, this message translates to:
  /// **'Cuando el equipo apruebe a más guías y traductores, aparecerán aquí.'**
  String get guidesEmptyMessage;

  /// No description provided for @guidesEmptyTitle.
  ///
  /// In es, this message translates to:
  /// **'Todavía no hay guías disponibles'**
  String get guidesEmptyTitle;

  /// No description provided for @guidesFilterAll.
  ///
  /// In es, this message translates to:
  /// **'Todos'**
  String get guidesFilterAll;

  /// No description provided for @guidesFilterGuides.
  ///
  /// In es, this message translates to:
  /// **'Guías'**
  String get guidesFilterGuides;

  /// No description provided for @guidesFilterTranslators.
  ///
  /// In es, this message translates to:
  /// **'Traductores'**
  String get guidesFilterTranslators;

  /// No description provided for @guidesNoReviews.
  ///
  /// In es, this message translates to:
  /// **'Sin reseñas todavía'**
  String get guidesNoReviews;

  /// No description provided for @guidesTitle.
  ///
  /// In es, this message translates to:
  /// **'Guías y traductores'**
  String get guidesTitle;

  /// No description provided for @homeActiveTripAllVisited.
  ///
  /// In es, this message translates to:
  /// **'Ya pasaste por todas las paradas · toca para finalizar'**
  String get homeActiveTripAllVisited;

  /// No description provided for @homeActiveTripNext.
  ///
  /// In es, this message translates to:
  /// **'Siguiente: {stop} · {time} · {delay}'**
  String homeActiveTripNext(String stop, String time, String delay);

  /// No description provided for @homeActiveTripTitle.
  ///
  /// In es, this message translates to:
  /// **'Viaje en curso: {title}'**
  String homeActiveTripTitle(String title);

  /// No description provided for @homeActiveTripViewMap.
  ///
  /// In es, this message translates to:
  /// **'Ver mapa'**
  String get homeActiveTripViewMap;

  /// No description provided for @homeCircuitBonus.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{+1 insignia extra y medalla} other{+{count} insignias extra y medalla}}'**
  String homeCircuitBonus(int count);

  /// No description provided for @homeCircuitStops.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 parada} other{{count} paradas}}'**
  String homeCircuitStops(int count);

  /// No description provided for @homeDrawerBecomeGuide.
  ///
  /// In es, this message translates to:
  /// **'Ser guía en K’Plan'**
  String get homeDrawerBecomeGuide;

  /// No description provided for @homeDrawerComingSoon.
  ///
  /// In es, this message translates to:
  /// **'{label}: próximamente'**
  String homeDrawerComingSoon(String label);

  /// No description provided for @homeDrawerGuideMode.
  ///
  /// In es, this message translates to:
  /// **'Modo guía'**
  String get homeDrawerGuideMode;

  /// No description provided for @homeDrawerTranslatorMode.
  ///
  /// In es, this message translates to:
  /// **'Modo traductor'**
  String get homeDrawerTranslatorMode;

  /// No description provided for @homeEmptySearchMessage.
  ///
  /// In es, this message translates to:
  /// **'Prueba con otra palabra o revisa cómo está escrita.'**
  String get homeEmptySearchMessage;

  /// No description provided for @homeEmptySearchTitle.
  ///
  /// In es, this message translates to:
  /// **'No encontramos nada con esa búsqueda'**
  String get homeEmptySearchTitle;

  /// No description provided for @homeEmptyStopsMessage.
  ///
  /// In es, this message translates to:
  /// **'Prueba con otra categoría o con otra búsqueda.'**
  String get homeEmptyStopsMessage;

  /// No description provided for @homeEmptyStopsTitle.
  ///
  /// In es, this message translates to:
  /// **'No hay paradas que coincidan'**
  String get homeEmptyStopsTitle;

  /// No description provided for @homeGuideRequestApplicationsHint.
  ///
  /// In es, this message translates to:
  /// **'Toca para revisarlas y elegir'**
  String get homeGuideRequestApplicationsHint;

  /// No description provided for @homeGuideRequestApplicationsTitle.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 postulación para {circuit}} other{{count} postulaciones para {circuit}}}'**
  String homeGuideRequestApplicationsTitle(int count, String circuit);

  /// No description provided for @homeGuideRequestHiredHint.
  ///
  /// In es, this message translates to:
  /// **'Toca para chatear'**
  String get homeGuideRequestHiredHint;

  /// No description provided for @homeGuideRequestHiredTitle.
  ///
  /// In es, this message translates to:
  /// **'Contrataste a {names} para {circuit}'**
  String homeGuideRequestHiredTitle(String names, String circuit);

  /// No description provided for @homeGuideRequestNamesJoin.
  ///
  /// In es, this message translates to:
  /// **'{first} y {second}'**
  String homeGuideRequestNamesJoin(String first, String second);

  /// No description provided for @homeGuideRequestPublishedHint.
  ///
  /// In es, this message translates to:
  /// **'Esperando que los guías se postulen'**
  String get homeGuideRequestPublishedHint;

  /// No description provided for @homeGuideRequestPublishedTitle.
  ///
  /// In es, this message translates to:
  /// **'Tu propuesta para {circuit} está publicada'**
  String homeGuideRequestPublishedTitle(String circuit);

  /// No description provided for @homeRewardsAvailable.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{Tienes 1 insignia para canjear} other{Tienes {count} insignias para canjear}}'**
  String homeRewardsAvailable(int count);

  /// No description provided for @homeRewardsEarn.
  ///
  /// In es, this message translates to:
  /// **'Gana insignias visitando paradas'**
  String get homeRewardsEarn;

  /// No description provided for @homeRewardsHint.
  ///
  /// In es, this message translates to:
  /// **'Cámbialas por cupones y descuentos'**
  String get homeRewardsHint;

  /// No description provided for @homeSearchHint.
  ///
  /// In es, this message translates to:
  /// **'¿Qué quieres descubrir?'**
  String get homeSearchHint;

  /// No description provided for @homeSectionCircuits.
  ///
  /// In es, this message translates to:
  /// **'Circuitos completos'**
  String get homeSectionCircuits;

  /// No description provided for @homeSectionEvents.
  ///
  /// In es, this message translates to:
  /// **'Eventos Próximos'**
  String get homeSectionEvents;

  /// No description provided for @homeSectionStops.
  ///
  /// In es, this message translates to:
  /// **'Paradas destacadas'**
  String get homeSectionStops;

  /// No description provided for @homeStopCount.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 parada} other{{count} paradas}}'**
  String homeStopCount(int count);

  /// No description provided for @homeTabCircuits.
  ///
  /// In es, this message translates to:
  /// **'Circuitos'**
  String get homeTabCircuits;

  /// No description provided for @homeTabEvents.
  ///
  /// In es, this message translates to:
  /// **'Eventos'**
  String get homeTabEvents;

  /// No description provided for @homeTabForYou.
  ///
  /// In es, this message translates to:
  /// **'Para ti'**
  String get homeTabForYou;

  /// No description provided for @homeTabStops.
  ///
  /// In es, this message translates to:
  /// **'Paradas'**
  String get homeTabStops;

  /// No description provided for @homeTitle.
  ///
  /// In es, this message translates to:
  /// **'Descubre tu próximo plan'**
  String get homeTitle;

  /// No description provided for @homeTopBarMenu.
  ///
  /// In es, this message translates to:
  /// **'Menú'**
  String get homeTopBarMenu;

  /// No description provided for @homeUpcomingTripHint.
  ///
  /// In es, this message translates to:
  /// **'Toca para ver los detalles del circuito'**
  String get homeUpcomingTripHint;

  /// No description provided for @homeUpcomingTripTitle.
  ///
  /// In es, this message translates to:
  /// **'Tu viaje a {circuit} es el {date}'**
  String homeUpcomingTripTitle(String circuit, String date);

  /// No description provided for @languageChoiceNote.
  ///
  /// In es, this message translates to:
  /// **'Podrás cambiarlo después en Configuraciones.'**
  String get languageChoiceNote;

  /// No description provided for @languageChoiceTitle.
  ///
  /// In es, this message translates to:
  /// **'Elige tu idioma'**
  String get languageChoiceTitle;

  /// No description provided for @languageNameEnglish.
  ///
  /// In es, this message translates to:
  /// **'Inglés'**
  String get languageNameEnglish;

  /// No description provided for @languageNameFrench.
  ///
  /// In es, this message translates to:
  /// **'Francés'**
  String get languageNameFrench;

  /// No description provided for @languageNameGerman.
  ///
  /// In es, this message translates to:
  /// **'Alemán'**
  String get languageNameGerman;

  /// No description provided for @languageNameItalian.
  ///
  /// In es, this message translates to:
  /// **'Italiano'**
  String get languageNameItalian;

  /// No description provided for @languageNamePortuguese.
  ///
  /// In es, this message translates to:
  /// **'Portugués'**
  String get languageNamePortuguese;

  /// No description provided for @languageNameSpanish.
  ///
  /// In es, this message translates to:
  /// **'Español'**
  String get languageNameSpanish;

  /// No description provided for @languagePlaceNamesNote.
  ///
  /// In es, this message translates to:
  /// **'Los nombres de lugares conservan su idioma original.'**
  String get languagePlaceNamesNote;

  /// No description provided for @languageSettingsHeading.
  ///
  /// In es, this message translates to:
  /// **'Idioma de la aplicación'**
  String get languageSettingsHeading;

  /// No description provided for @languageSettingsTitle.
  ///
  /// In es, this message translates to:
  /// **'Idioma'**
  String get languageSettingsTitle;

  /// No description provided for @loginApplyAsGuide.
  ///
  /// In es, this message translates to:
  /// **'Postularme'**
  String get loginApplyAsGuide;

  /// No description provided for @loginApplyAsGuideButton.
  ///
  /// In es, this message translates to:
  /// **'Postularme como guía'**
  String get loginApplyAsGuideButton;

  /// No description provided for @loginContinueWithGoogle.
  ///
  /// In es, this message translates to:
  /// **'Continuar con Google'**
  String get loginContinueWithGoogle;

  /// No description provided for @loginForgotPassword.
  ///
  /// In es, this message translates to:
  /// **'¿Olvidaste tu contraseña?'**
  String get loginForgotPassword;

  /// No description provided for @loginGoogleProfileFailed.
  ///
  /// In es, this message translates to:
  /// **'No pudimos completar tu perfil, intenta de nuevo'**
  String get loginGoogleProfileFailed;

  /// No description provided for @loginGoogleProfileSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Google no nos da estos datos y los necesitamos para crear tu cuenta. Debes ser mayor de 18 años.'**
  String get loginGoogleProfileSubtitle;

  /// No description provided for @loginGoogleProfileTitle.
  ///
  /// In es, this message translates to:
  /// **'Completa tu perfil'**
  String get loginGoogleProfileTitle;

  /// No description provided for @loginGuideAccountHint.
  ///
  /// In es, this message translates to:
  /// **'Entra con la cuenta con la que te postulaste como guía o traductor.'**
  String get loginGuideAccountHint;

  /// No description provided for @loginGuideNotYet.
  ///
  /// In es, this message translates to:
  /// **'¿Todavía no eres guía en K’Plan?'**
  String get loginGuideNotYet;

  /// No description provided for @loginMissingAccountGuide.
  ///
  /// In es, this message translates to:
  /// **'¿Quieres registrarte como guía?'**
  String get loginMissingAccountGuide;

  /// No description provided for @loginMissingAccountTitle.
  ///
  /// In es, this message translates to:
  /// **'No hemos encontrado esta cuenta'**
  String get loginMissingAccountTitle;

  /// No description provided for @loginMissingAccountTourist.
  ///
  /// In es, this message translates to:
  /// **'¿Quieres registrarte como turista?'**
  String get loginMissingAccountTourist;

  /// No description provided for @loginNoAccount.
  ///
  /// In es, this message translates to:
  /// **'¿No tienes cuenta?'**
  String get loginNoAccount;

  /// No description provided for @loginSubmit.
  ///
  /// In es, this message translates to:
  /// **'Iniciar sesión'**
  String get loginSubmit;

  /// No description provided for @loginTwoFactorCodeHint.
  ///
  /// In es, this message translates to:
  /// **'Código'**
  String get loginTwoFactorCodeHint;

  /// No description provided for @loginTwoFactorCodeRequired.
  ///
  /// In es, this message translates to:
  /// **'Escribe el código de 6 dígitos o uno de recuperación'**
  String get loginTwoFactorCodeRequired;

  /// No description provided for @loginTwoFactorSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Escribe el código de 6 dígitos de tu app de autenticación. Si perdiste el celular, usa uno de tus códigos de recuperación.'**
  String get loginTwoFactorSubtitle;

  /// No description provided for @loginTwoFactorTitle.
  ///
  /// In es, this message translates to:
  /// **'Verifica que eres tú'**
  String get loginTwoFactorTitle;

  /// No description provided for @loginTwoFactorVerify.
  ///
  /// In es, this message translates to:
  /// **'Verificar'**
  String get loginTwoFactorVerify;

  /// No description provided for @medalsBalanceAvailable.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 disponible} other{{count} disponibles}}'**
  String medalsBalanceAvailable(int count);

  /// No description provided for @medalsBalanceEarned.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 insignia} other{{count} insignias}}'**
  String medalsBalanceEarned(int count);

  /// No description provided for @medalsBalanceNote.
  ///
  /// In es, this message translates to:
  /// **'Ganaste {earned} en total: eso es lo que cuenta para tus medallas, y no baja aunque gastes insignias. Tienes {available} para canjear en Cupones.'**
  String medalsBalanceNote(String earned, String available);

  /// No description provided for @medalsBalanceNoteSpent.
  ///
  /// In es, this message translates to:
  /// **'Ganaste {earned} en total: eso es lo que cuenta para tus medallas, y no baja aunque gastes insignias. Tienes {available} para canjear en Cupones ({spent, plural, =1{1 ya gastada} other{{spent} ya gastadas}}).'**
  String medalsBalanceNoteSpent(String earned, String available, int spent);

  /// No description provided for @medalsByCategory.
  ///
  /// In es, this message translates to:
  /// **'Medallas por categoría'**
  String get medalsByCategory;

  /// No description provided for @medalsByCategoryNote.
  ///
  /// In es, this message translates to:
  /// **'Se ganan insignias visitando paradas que las otorgan.'**
  String get medalsByCategoryNote;

  /// No description provided for @medalsCityEarned.
  ///
  /// In es, this message translates to:
  /// **'Medalla ganada'**
  String get medalsCityEarned;

  /// No description provided for @medalsCityLocked.
  ///
  /// In es, this message translates to:
  /// **'Completa un circuito creativo de {city}'**
  String medalsCityLocked(String city);

  /// No description provided for @medalsCreativeCities.
  ///
  /// In es, this message translates to:
  /// **'Medallas de ciudades creativas'**
  String get medalsCreativeCities;

  /// No description provided for @medalsCreativeCitiesNote.
  ///
  /// In es, this message translates to:
  /// **'Se ganan al completar un circuito creativo de esa ciudad.'**
  String get medalsCreativeCitiesNote;

  /// No description provided for @medalsMaxLevel.
  ///
  /// In es, this message translates to:
  /// **'¡Nivel máximo alcanzado!'**
  String get medalsMaxLevel;

  /// No description provided for @medalsOverall.
  ///
  /// In es, this message translates to:
  /// **'Medalla general: {tier}'**
  String medalsOverall(String tier);

  /// No description provided for @medalsTierMax.
  ///
  /// In es, this message translates to:
  /// **'{tier} · nivel máximo'**
  String medalsTierMax(String tier);

  /// No description provided for @medalsTierToNext.
  ///
  /// In es, this message translates to:
  /// **'{tier} · {count, plural, =1{falta 1 para subir} other{faltan {count} para subir}}'**
  String medalsTierToNext(String tier, int count);

  /// No description provided for @medalsToNextOverall.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{Te falta 1 insignia para la siguiente medalla} other{Te faltan {count} insignias para la siguiente medalla}}'**
  String medalsToNextOverall(int count);

  /// No description provided for @modelBookingStatusCancelled.
  ///
  /// In es, this message translates to:
  /// **'Cancelada'**
  String get modelBookingStatusCancelled;

  /// No description provided for @modelBookingStatusClosed.
  ///
  /// In es, this message translates to:
  /// **'Cerrada'**
  String get modelBookingStatusClosed;

  /// No description provided for @modelBookingStatusConfirmed.
  ///
  /// In es, this message translates to:
  /// **'Confirmada'**
  String get modelBookingStatusConfirmed;

  /// No description provided for @modelBookingStatusDelivered.
  ///
  /// In es, this message translates to:
  /// **'Terminada'**
  String get modelBookingStatusDelivered;

  /// No description provided for @modelBookingStatusInProgress.
  ///
  /// In es, this message translates to:
  /// **'En curso'**
  String get modelBookingStatusInProgress;

  /// No description provided for @modelDropReasonClosed.
  ///
  /// In es, this message translates to:
  /// **'Estaba cerrado'**
  String get modelDropReasonClosed;

  /// No description provided for @modelDropReasonNoTime.
  ///
  /// In es, this message translates to:
  /// **'Falta de tiempo'**
  String get modelDropReasonNoTime;

  /// No description provided for @modelDropReasonNotInterested.
  ///
  /// In es, this message translates to:
  /// **'No me interesó'**
  String get modelDropReasonNotInterested;

  /// No description provided for @modelDropReasonOther.
  ///
  /// In es, this message translates to:
  /// **'Otro motivo'**
  String get modelDropReasonOther;

  /// No description provided for @modelDropReasonTooExpensive.
  ///
  /// In es, this message translates to:
  /// **'Muy caro'**
  String get modelDropReasonTooExpensive;

  /// No description provided for @modelDropReasonTooFar.
  ///
  /// In es, this message translates to:
  /// **'Muy lejos o sin transporte'**
  String get modelDropReasonTooFar;

  /// No description provided for @modelDropReasonWeather.
  ///
  /// In es, this message translates to:
  /// **'Por el clima'**
  String get modelDropReasonWeather;

  /// No description provided for @modelGuideCoverageLocalCity.
  ///
  /// In es, this message translates to:
  /// **'Guía local · {city}'**
  String modelGuideCoverageLocalCity(String city);

  /// No description provided for @modelGuideCoverageNational.
  ///
  /// In es, this message translates to:
  /// **'Guía nacional'**
  String get modelGuideCoverageNational;

  /// No description provided for @modelLegFixed.
  ///
  /// In es, this message translates to:
  /// **'{duration} de traslado'**
  String modelLegFixed(String duration);

  /// No description provided for @modelLegNoTransfer.
  ///
  /// In es, this message translates to:
  /// **'Sin traslado'**
  String get modelLegNoTransfer;

  /// No description provided for @modelLegSamePlace.
  ///
  /// In es, this message translates to:
  /// **'A pasos'**
  String get modelLegSamePlace;

  /// No description provided for @modelLegVehicle.
  ///
  /// In es, this message translates to:
  /// **'{duration} en vehículo'**
  String modelLegVehicle(String duration);

  /// No description provided for @modelLegWalking.
  ///
  /// In es, this message translates to:
  /// **'{duration} a pie'**
  String modelLegWalking(String duration);

  /// No description provided for @modelNeedBilingualGuide.
  ///
  /// In es, this message translates to:
  /// **'Guía que habla {language}'**
  String modelNeedBilingualGuide(String language);

  /// No description provided for @modelNeedBilingualGuideShort.
  ///
  /// In es, this message translates to:
  /// **'Guía bilingüe'**
  String get modelNeedBilingualGuideShort;

  /// No description provided for @modelNeedGuideAndTranslatorShort.
  ///
  /// In es, this message translates to:
  /// **'Guía + traductor'**
  String get modelNeedGuideAndTranslatorShort;

  /// No description provided for @modelNeedLocalGuideAndTranslator.
  ///
  /// In es, this message translates to:
  /// **'Guía local + traductor de {language}'**
  String modelNeedLocalGuideAndTranslator(String language);

  /// No description provided for @modelNeedTranslatorOnly.
  ///
  /// In es, this message translates to:
  /// **'Traductor de {language}'**
  String modelNeedTranslatorOnly(String language);

  /// No description provided for @modelNeedTranslatorOnlyShort.
  ///
  /// In es, this message translates to:
  /// **'Solo traductor'**
  String get modelNeedTranslatorOnlyShort;

  /// No description provided for @modelNeedYourLanguage.
  ///
  /// In es, this message translates to:
  /// **'tu idioma'**
  String get modelNeedYourLanguage;

  /// No description provided for @modelPaceBalanced.
  ///
  /// In es, this message translates to:
  /// **'Equilibrado'**
  String get modelPaceBalanced;

  /// No description provided for @modelPaceIntense.
  ///
  /// In es, this message translates to:
  /// **'Intenso'**
  String get modelPaceIntense;

  /// No description provided for @modelPaceRelaxed.
  ///
  /// In es, this message translates to:
  /// **'Relajado'**
  String get modelPaceRelaxed;

  /// No description provided for @modelPaymentFree.
  ///
  /// In es, this message translates to:
  /// **'Sin cobro'**
  String get modelPaymentFree;

  /// No description provided for @modelPaymentPaid.
  ///
  /// In es, this message translates to:
  /// **'Pagado'**
  String get modelPaymentPaid;

  /// No description provided for @modelPaymentPending.
  ///
  /// In es, this message translates to:
  /// **'Pago pendiente'**
  String get modelPaymentPending;

  /// No description provided for @modelPaymentRefundDue.
  ///
  /// In es, this message translates to:
  /// **'Por reembolsar'**
  String get modelPaymentRefundDue;

  /// No description provided for @modelPaymentRefunded.
  ///
  /// In es, this message translates to:
  /// **'Reembolsado'**
  String get modelPaymentRefunded;

  /// No description provided for @modelPaymentVoided.
  ///
  /// In es, this message translates to:
  /// **'Pago anulado'**
  String get modelPaymentVoided;

  /// No description provided for @modelTravelModeVehicle.
  ///
  /// In es, this message translates to:
  /// **'En vehículo'**
  String get modelTravelModeVehicle;

  /// No description provided for @modelTravelModeWalking.
  ///
  /// In es, this message translates to:
  /// **'A pie'**
  String get modelTravelModeWalking;

  /// No description provided for @myCircuitAiMessage.
  ///
  /// In es, this message translates to:
  /// **'Te pregunta cómo quieres tu día, calcula los traslados y te sugiere qué quitar o agregar.'**
  String get myCircuitAiMessage;

  /// No description provided for @myCircuitAiTitle.
  ///
  /// In es, this message translates to:
  /// **'Organizar con IA'**
  String get myCircuitAiTitle;

  /// No description provided for @myCircuitArrivalAt.
  ///
  /// In es, this message translates to:
  /// **'Hora de llegada a {stop}'**
  String myCircuitArrivalAt(String stop);

  /// No description provided for @myCircuitDepartureTime.
  ///
  /// In es, this message translates to:
  /// **'Hora de salida'**
  String get myCircuitDepartureTime;

  /// No description provided for @myCircuitEmpty.
  ///
  /// In es, this message translates to:
  /// **'Este circuito todavía no tiene paradas'**
  String get myCircuitEmpty;

  /// No description provided for @myCircuitEmptyMessage.
  ///
  /// In es, this message translates to:
  /// **'En cualquier parada, toca \"Añadir a un circuito\" y elige este.'**
  String get myCircuitEmptyMessage;

  /// No description provided for @myCircuitExploreStops.
  ///
  /// In es, this message translates to:
  /// **'Explorar paradas'**
  String get myCircuitExploreStops;

  /// No description provided for @myCircuitFixedTime.
  ///
  /// In es, this message translates to:
  /// **'Hora fija'**
  String get myCircuitFixedTime;

  /// No description provided for @myCircuitFixedTimeRemove.
  ///
  /// In es, this message translates to:
  /// **'Quitar'**
  String get myCircuitFixedTimeRemove;

  /// No description provided for @myCircuitMissedFixedTime.
  ///
  /// In es, this message translates to:
  /// **'Querías llegar a las {time}'**
  String myCircuitMissedFixedTime(String time);

  /// No description provided for @myCircuitProposalNote.
  ///
  /// In es, this message translates to:
  /// **'Como lo armaste tú, puedes publicar una propuesta para que guías o traductores se postulen.'**
  String get myCircuitProposalNote;

  /// No description provided for @myCircuitRemoved.
  ///
  /// In es, this message translates to:
  /// **'{stop} se quitó del circuito'**
  String myCircuitRemoved(String stop);

  /// No description provided for @myCircuitRemoveTooltip.
  ///
  /// In es, this message translates to:
  /// **'Quitar del circuito'**
  String get myCircuitRemoveTooltip;

  /// No description provided for @myCircuitRemoveWhy.
  ///
  /// In es, this message translates to:
  /// **'¿Por qué quitas {stop}?'**
  String myCircuitRemoveWhy(String stop);

  /// No description provided for @myCircuitReorderHint.
  ///
  /// In es, this message translates to:
  /// **'Toca la hora de una parada para cambiarla y arrástrala para cambiar el orden.'**
  String get myCircuitReorderHint;

  /// No description provided for @myCircuitSchedule.
  ///
  /// In es, this message translates to:
  /// **'Agendar circuito'**
  String get myCircuitSchedule;

  /// No description provided for @myCircuitSkipWhy.
  ///
  /// In es, this message translates to:
  /// **'¿Por qué saltas {stop}?'**
  String myCircuitSkipWhy(String stop);

  /// No description provided for @myCircuitStartTrip.
  ///
  /// In es, this message translates to:
  /// **'Comenzar viaje'**
  String get myCircuitStartTrip;

  /// No description provided for @myCircuitStopsHeader.
  ///
  /// In es, this message translates to:
  /// **'Paradas del recorrido'**
  String get myCircuitStopsHeader;

  /// No description provided for @myCircuitTimeHint.
  ///
  /// In es, this message translates to:
  /// **'Toca la hora de una parada para cambiarla.'**
  String get myCircuitTimeHint;

  /// No description provided for @myCircuitTodayRoute.
  ///
  /// In es, this message translates to:
  /// **'Tu recorrido de hoy'**
  String get myCircuitTodayRoute;

  /// No description provided for @myCircuitTransport.
  ///
  /// In es, this message translates to:
  /// **'Transporte'**
  String get myCircuitTransport;

  /// No description provided for @myCircuitTravelQuestion.
  ///
  /// In es, this message translates to:
  /// **'¿Cómo te vas a mover?'**
  String get myCircuitTravelQuestion;

  /// No description provided for @myCircuitTripEnded.
  ///
  /// In es, this message translates to:
  /// **'Viaje finalizado'**
  String get myCircuitTripEnded;

  /// No description provided for @myCircuitTripStarted.
  ///
  /// In es, this message translates to:
  /// **'¡Viaje iniciado! Dirígete a {stop}'**
  String myCircuitTripStarted(String stop);

  /// No description provided for @myCircuitUndo.
  ///
  /// In es, this message translates to:
  /// **'Deshacer'**
  String get myCircuitUndo;

  /// No description provided for @myCircuitYourDay.
  ///
  /// In es, this message translates to:
  /// **'Tu día'**
  String get myCircuitYourDay;

  /// No description provided for @myTripsAiSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Te organiza el día con horarios y traslados'**
  String get myTripsAiSubtitle;

  /// No description provided for @myTripsAiTitle.
  ///
  /// In es, this message translates to:
  /// **'Arma tu viaje con IA'**
  String get myTripsAiTitle;

  /// No description provided for @myTripsAllVisited.
  ///
  /// In es, this message translates to:
  /// **'Ya pasaste por todas las paradas'**
  String get myTripsAllVisited;

  /// No description provided for @myTripsAllVisitedHint.
  ///
  /// In es, this message translates to:
  /// **'Entra al detalle para finalizar el recorrido'**
  String get myTripsAllVisitedHint;

  /// No description provided for @myTripsArrival.
  ///
  /// In es, this message translates to:
  /// **'Llegada {time} · {delay}'**
  String myTripsArrival(String time, String delay);

  /// No description provided for @myTripsBookingConfirmed.
  ///
  /// In es, this message translates to:
  /// **'Reserva confirmada · {people}'**
  String myTripsBookingConfirmed(String people);

  /// No description provided for @myTripsBookingDeparture.
  ///
  /// In es, this message translates to:
  /// **'Salida {time}'**
  String myTripsBookingDeparture(String time);

  /// No description provided for @myTripsCircuitsEmpty.
  ///
  /// In es, this message translates to:
  /// **'Todavía no armaste ninguno. Los que crees aparecen aquí para editarlos, reservarlos o salir a recorrerlos.'**
  String get myTripsCircuitsEmpty;

  /// No description provided for @myTripsContactGuide.
  ///
  /// In es, this message translates to:
  /// **'Contactar a mi guía'**
  String get myTripsContactGuide;

  /// No description provided for @myTripsContactTranslator.
  ///
  /// In es, this message translates to:
  /// **'Contactar a mi traductora'**
  String get myTripsContactTranslator;

  /// No description provided for @myTripsCreateSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Elige tú las paradas y el orden'**
  String get myTripsCreateSubtitle;

  /// No description provided for @myTripsCreateTitle.
  ///
  /// In es, this message translates to:
  /// **'Crear un circuito desde cero'**
  String get myTripsCreateTitle;

  /// No description provided for @myTripsDeleteConfirm.
  ///
  /// In es, this message translates to:
  /// **'Eliminar'**
  String get myTripsDeleteConfirm;

  /// No description provided for @myTripsDeleteMessage.
  ///
  /// In es, this message translates to:
  /// **'Se borrarán sus paradas guardadas. No se puede deshacer.'**
  String get myTripsDeleteMessage;

  /// No description provided for @myTripsDeleteTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Eliminar \"{title}\"?'**
  String myTripsDeleteTitle(String title);

  /// No description provided for @myTripsDeleteTooltip.
  ///
  /// In es, this message translates to:
  /// **'Eliminar {title}'**
  String myTripsDeleteTooltip(String title);

  /// No description provided for @myTripsExploreCircuits.
  ///
  /// In es, this message translates to:
  /// **'Explorar circuitos'**
  String get myTripsExploreCircuits;

  /// No description provided for @myTripsGuideRoleLanguages.
  ///
  /// In es, this message translates to:
  /// **'{role} · {languages}'**
  String myTripsGuideRoleLanguages(String role, String languages);

  /// No description provided for @myTripsHeadline.
  ///
  /// In es, this message translates to:
  /// **'El próximo destino te espera'**
  String get myTripsHeadline;

  /// No description provided for @myTripsNextStop.
  ///
  /// In es, this message translates to:
  /// **'Siguiente: {stop}'**
  String myTripsNextStop(String stop);

  /// No description provided for @myTripsOngoingEmptyMessage.
  ///
  /// In es, this message translates to:
  /// **'Cuando empieces un circuito, aquí verás tu próxima parada, la hora de llegada y el mapa.'**
  String get myTripsOngoingEmptyMessage;

  /// No description provided for @myTripsOngoingEmptyTitle.
  ///
  /// In es, this message translates to:
  /// **'Ningún recorrido en curso'**
  String get myTripsOngoingEmptyTitle;

  /// No description provided for @myTripsOpenMap.
  ///
  /// In es, this message translates to:
  /// **'Abrir el mapa'**
  String get myTripsOpenMap;

  /// No description provided for @myTripsPlanAnother.
  ///
  /// In es, this message translates to:
  /// **'Planificar otro viaje'**
  String get myTripsPlanAnother;

  /// No description provided for @myTripsProgress.
  ///
  /// In es, this message translates to:
  /// **'{total, plural, =1{{visited} de 1 parada} other{{visited} de {total} paradas}}'**
  String myTripsProgress(int visited, int total);

  /// No description provided for @myTripsProgressSemantics.
  ///
  /// In es, this message translates to:
  /// **'{total, plural, =1{Llevas {visited} de 1 parada} other{Llevas {visited} de {total} paradas}}'**
  String myTripsProgressSemantics(int visited, int total);

  /// No description provided for @myTripsSeeDetails.
  ///
  /// In es, this message translates to:
  /// **'Ver detalle del recorrido'**
  String get myTripsSeeDetails;

  /// No description provided for @myTripsSeeUpcoming.
  ///
  /// In es, this message translates to:
  /// **'Ver mis próximos viajes'**
  String get myTripsSeeUpcoming;

  /// No description provided for @myTripsTabOngoing.
  ///
  /// In es, this message translates to:
  /// **'En curso'**
  String get myTripsTabOngoing;

  /// No description provided for @myTripsTabUpcoming.
  ///
  /// In es, this message translates to:
  /// **'Próximos'**
  String get myTripsTabUpcoming;

  /// No description provided for @myTripsUpcomingEmptyMessage.
  ///
  /// In es, this message translates to:
  /// **'Elige un circuito y organiza tu primera salida. Aquí encontrarás los detalles de cada viaje.'**
  String get myTripsUpcomingEmptyMessage;

  /// No description provided for @myTripsUpcomingEmptyOrAi.
  ///
  /// In es, this message translates to:
  /// **'O arma tu viaje con IA'**
  String get myTripsUpcomingEmptyOrAi;

  /// No description provided for @myTripsUpcomingEmptyTitle.
  ///
  /// In es, this message translates to:
  /// **'Tu historia está por empezar'**
  String get myTripsUpcomingEmptyTitle;

  /// No description provided for @myTripsYourCircuits.
  ///
  /// In es, this message translates to:
  /// **'Tus circuitos'**
  String get myTripsYourCircuits;

  /// No description provided for @myTripsYourCircuitsCount.
  ///
  /// In es, this message translates to:
  /// **'Tus circuitos · {count}'**
  String myTripsYourCircuitsCount(int count);

  /// No description provided for @myTripsYourGuide.
  ///
  /// In es, this message translates to:
  /// **'Tu guía'**
  String get myTripsYourGuide;

  /// No description provided for @myTripsYourTranslator.
  ///
  /// In es, this message translates to:
  /// **'Tu traductora'**
  String get myTripsYourTranslator;

  /// No description provided for @notificationsEmptyMessage.
  ///
  /// In es, this message translates to:
  /// **'Aquí te avisamos de tus reservas, mensajes, postulaciones y pagos.'**
  String get notificationsEmptyMessage;

  /// No description provided for @notificationsEmptyTitle.
  ///
  /// In es, this message translates to:
  /// **'No tienes avisos'**
  String get notificationsEmptyTitle;

  /// No description provided for @notificationsMore.
  ///
  /// In es, this message translates to:
  /// **'Ver más'**
  String get notificationsMore;

  /// No description provided for @notificationsReadAll.
  ///
  /// In es, this message translates to:
  /// **'Marcar todo como leído'**
  String get notificationsReadAll;

  /// No description provided for @profileCouponsSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Beneficios de negocios locales'**
  String get profileCouponsSubtitle;

  /// No description provided for @profileGuestName.
  ///
  /// In es, this message translates to:
  /// **'Invitado'**
  String get profileGuestName;

  /// No description provided for @profileMedalsSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Recuerdos de tus recorridos'**
  String get profileMedalsSubtitle;

  /// No description provided for @profileMyCoupons.
  ///
  /// In es, this message translates to:
  /// **'Mis cupones'**
  String get profileMyCoupons;

  /// No description provided for @profileNotificationsSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Avisos de tus viajes y reservas'**
  String get profileNotificationsSubtitle;

  /// No description provided for @profilePersonalData.
  ///
  /// In es, this message translates to:
  /// **'Datos personales'**
  String get profilePersonalData;

  /// No description provided for @profilePersonalDataSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Nombre y datos de contacto'**
  String get profilePersonalDataSubtitle;

  /// No description provided for @profileSavedSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Circuitos, lugares y eventos que marcaste'**
  String get profileSavedSubtitle;

  /// No description provided for @profileSettingsSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Cuenta, idioma y privacidad'**
  String get profileSettingsSubtitle;

  /// No description provided for @profileStatBadges.
  ///
  /// In es, this message translates to:
  /// **'Insignias'**
  String get profileStatBadges;

  /// No description provided for @profileTitle.
  ///
  /// In es, this message translates to:
  /// **'Mi perfil'**
  String get profileTitle;

  /// No description provided for @registerAdultOnly.
  ///
  /// In es, this message translates to:
  /// **'Debes ser mayor de {age} años para crear una cuenta'**
  String registerAdultOnly(int age);

  /// No description provided for @registerBirthDatePartDay.
  ///
  /// In es, this message translates to:
  /// **'Día'**
  String get registerBirthDatePartDay;

  /// No description provided for @registerBirthDatePartMonth.
  ///
  /// In es, this message translates to:
  /// **'Mes'**
  String get registerBirthDatePartMonth;

  /// No description provided for @registerBirthDatePartYear.
  ///
  /// In es, this message translates to:
  /// **'Año'**
  String get registerBirthDatePartYear;

  /// No description provided for @registerBirthDateSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Tu fecha de nacimiento será privada, y nos ayudará a ofrecerte una mejor experiencia'**
  String get registerBirthDateSubtitle;

  /// No description provided for @registerBirthDateTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Cuándo naciste?'**
  String get registerBirthDateTitle;

  /// No description provided for @registerCodeSent.
  ///
  /// In es, this message translates to:
  /// **'Enviamos un código de 6 dígitos al correo {email}'**
  String registerCodeSent(String email);

  /// No description provided for @registerCodeTitle.
  ///
  /// In es, this message translates to:
  /// **'Ingrese el código de verificación'**
  String get registerCodeTitle;

  /// No description provided for @registerEmailSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Lo usaremos para verificar tu cuenta. Tu información se mantendrá privada.'**
  String get registerEmailSubtitle;

  /// No description provided for @registerEmailTitle.
  ///
  /// In es, this message translates to:
  /// **'Ingrese su correo electrónico'**
  String get registerEmailTitle;

  /// No description provided for @registerLoginAction.
  ///
  /// In es, this message translates to:
  /// **'Inicia sesión'**
  String get registerLoginAction;

  /// No description provided for @registerLoginLink.
  ///
  /// In es, this message translates to:
  /// **'¿Ya tienes cuenta? {action}'**
  String registerLoginLink(String action);

  /// No description provided for @registerNameLabel.
  ///
  /// In es, this message translates to:
  /// **'Nombre'**
  String get registerNameLabel;

  /// No description provided for @registerNameRequired.
  ///
  /// In es, this message translates to:
  /// **'Ingresa tu nombre'**
  String get registerNameRequired;

  /// No description provided for @registerNameTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Cómo te llamas?'**
  String get registerNameTitle;

  /// No description provided for @registerNationalityLabel.
  ///
  /// In es, this message translates to:
  /// **'País'**
  String get registerNationalityLabel;

  /// No description provided for @registerNationalitySubtitle.
  ///
  /// In es, this message translates to:
  /// **'Tu nacionalidad es privada: nos ayuda a recomendarte mejor y a cumplir con la ley.'**
  String get registerNationalitySubtitle;

  /// No description provided for @registerNationalityTitle.
  ///
  /// In es, this message translates to:
  /// **'¿De dónde eres?'**
  String get registerNationalityTitle;

  /// No description provided for @registerPasswordRuleLength.
  ///
  /// In es, this message translates to:
  /// **'8 caracteres'**
  String get registerPasswordRuleLength;

  /// No description provided for @registerPasswordRuleMet.
  ///
  /// In es, this message translates to:
  /// **'{rule}: cumplido'**
  String registerPasswordRuleMet(String rule);

  /// No description provided for @registerPasswordRuleNumber.
  ///
  /// In es, this message translates to:
  /// **'Un número'**
  String get registerPasswordRuleNumber;

  /// No description provided for @registerPasswordRulePending.
  ///
  /// In es, this message translates to:
  /// **'{rule}: pendiente'**
  String registerPasswordRulePending(String rule);

  /// No description provided for @registerPasswordRuleUpper.
  ///
  /// In es, this message translates to:
  /// **'Una mayúscula'**
  String get registerPasswordRuleUpper;

  /// No description provided for @registerPasswordSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Usa al menos 8 caracteres, una mayúscula y un número.'**
  String get registerPasswordSubtitle;

  /// No description provided for @registerPasswordTitle.
  ///
  /// In es, this message translates to:
  /// **'Cree una contraseña'**
  String get registerPasswordTitle;

  /// No description provided for @registerUsernameLabel.
  ///
  /// In es, this message translates to:
  /// **'Nombre de usuario'**
  String get registerUsernameLabel;

  /// No description provided for @registerUsernameSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Este nombre será visible dentro de K’Plan'**
  String get registerUsernameSubtitle;

  /// No description provided for @registerUsernameTitle.
  ///
  /// In es, this message translates to:
  /// **'Cree un nombre de usuario'**
  String get registerUsernameTitle;

  /// No description provided for @repoAccessDemoExperienceLocal.
  ///
  /// In es, this message translates to:
  /// **'6 años en Granada: historia colonial y gastronomía.'**
  String get repoAccessDemoExperienceLocal;

  /// No description provided for @repoAccessDemoExperienceNational.
  ///
  /// In es, this message translates to:
  /// **'9 años con recorridos de arquitectura colonial y leyendas.'**
  String get repoAccessDemoExperienceNational;

  /// No description provided for @repoAccessSignInFirst.
  ///
  /// In es, this message translates to:
  /// **'Inicia sesión primero'**
  String get repoAccessSignInFirst;

  /// No description provided for @repoApplicantDefaultMessage.
  ///
  /// In es, this message translates to:
  /// **'¡Me encantaría acompañarte en este recorrido!'**
  String get repoApplicantDefaultMessage;

  /// No description provided for @repoApplicantHasVehicle.
  ///
  /// In es, this message translates to:
  /// **'Tengo vehículo propio para tu grupo.'**
  String get repoApplicantHasVehicle;

  /// No description provided for @repoApplicantStrengths.
  ///
  /// In es, this message translates to:
  /// **'Mi fuerte: {specialties}.'**
  String repoApplicantStrengths(String specialties);

  /// No description provided for @repoApplicantTourInLanguage.
  ///
  /// In es, this message translates to:
  /// **'Puedo dar todo el recorrido en {language}.'**
  String repoApplicantTourInLanguage(String language);

  /// No description provided for @repoApplicantTranslatorMessage.
  ///
  /// In es, this message translates to:
  /// **'Traduzco en tiempo real durante todo el recorrido.'**
  String get repoApplicantTranslatorMessage;

  /// No description provided for @repoApplicantTranslatorMessageToLanguage.
  ///
  /// In es, this message translates to:
  /// **'Traduzco en tiempo real del español al {language} durante todo el recorrido.'**
  String repoApplicantTranslatorMessageToLanguage(String language);

  /// No description provided for @repoAuthAccountCreated.
  ///
  /// In es, this message translates to:
  /// **'Tu cuenta quedó creada. Inicia sesión para entrar.'**
  String get repoAuthAccountCreated;

  /// No description provided for @repoAuthAccountNotFound.
  ///
  /// In es, this message translates to:
  /// **'No hemos encontrado esta cuenta'**
  String get repoAuthAccountNotFound;

  /// No description provided for @repoAuthGoogleFailed.
  ///
  /// In es, this message translates to:
  /// **'No pudimos entrar con Google, intenta de nuevo'**
  String get repoAuthGoogleFailed;

  /// No description provided for @repoAuthInvalidCode.
  ///
  /// In es, this message translates to:
  /// **'El código no es válido'**
  String get repoAuthInvalidCode;

  /// No description provided for @repoAuthMissingData.
  ///
  /// In es, this message translates to:
  /// **'Faltan datos para crear la cuenta'**
  String get repoAuthMissingData;

  /// No description provided for @repoAuthWrongCredentials.
  ///
  /// In es, this message translates to:
  /// **'Correo o contraseña incorrectos'**
  String get repoAuthWrongCredentials;

  /// No description provided for @repoChatReplyMeetingPoint.
  ///
  /// In es, this message translates to:
  /// **'Perfecto, nos vemos en el punto de encuentro. ¡Puntual!'**
  String get repoChatReplyMeetingPoint;

  /// No description provided for @repoChatReplyQuestions.
  ///
  /// In es, this message translates to:
  /// **'Cualquier duda antes del recorrido, escríbeme por aquí.'**
  String get repoChatReplyQuestions;

  /// No description provided for @repoChatReplyWelcome.
  ///
  /// In es, this message translates to:
  /// **'¡Hola! Con gusto te acompaño en el recorrido.'**
  String get repoChatReplyWelcome;

  /// No description provided for @repoCollectionsDeleteFailed.
  ///
  /// In es, this message translates to:
  /// **'No pudimos borrar el circuito de tu cuenta. {message}'**
  String repoCollectionsDeleteFailed(String message);

  /// No description provided for @repoCollectionsLoadFailed.
  ///
  /// In es, this message translates to:
  /// **'No pudimos traer los circuitos guardados en tu cuenta. {message}'**
  String repoCollectionsLoadFailed(String message);

  /// No description provided for @repoCollectionsSaveFailed.
  ///
  /// In es, this message translates to:
  /// **'No pudimos guardar el circuito en tu cuenta; tus cambios siguen en este teléfono. {message}'**
  String repoCollectionsSaveFailed(String message);

  /// No description provided for @repoInboxReplyEarlier.
  ///
  /// In es, this message translates to:
  /// **'¿Podemos empezar 15 minutos antes?'**
  String get repoInboxReplyEarlier;

  /// No description provided for @repoInboxReplyNoted.
  ///
  /// In es, this message translates to:
  /// **'Genial, gracias por avisar.'**
  String get repoInboxReplyNoted;

  /// No description provided for @repoInboxReplySeeYou.
  ///
  /// In es, this message translates to:
  /// **'Ahí estaremos. ¡Nos vemos!'**
  String get repoInboxReplySeeYou;

  /// No description provided for @repoInboxReplyThanks.
  ///
  /// In es, this message translates to:
  /// **'¡Perfecto, gracias!'**
  String get repoInboxReplyThanks;

  /// No description provided for @repoInlineLanguageEnglish.
  ///
  /// In es, this message translates to:
  /// **'inglés'**
  String get repoInlineLanguageEnglish;

  /// No description provided for @repoInlineLanguageFrench.
  ///
  /// In es, this message translates to:
  /// **'francés'**
  String get repoInlineLanguageFrench;

  /// No description provided for @repoInlineLanguageGerman.
  ///
  /// In es, this message translates to:
  /// **'alemán'**
  String get repoInlineLanguageGerman;

  /// No description provided for @repoInlineLanguageItalian.
  ///
  /// In es, this message translates to:
  /// **'italiano'**
  String get repoInlineLanguageItalian;

  /// No description provided for @repoInlineLanguagePortuguese.
  ///
  /// In es, this message translates to:
  /// **'portugués'**
  String get repoInlineLanguagePortuguese;

  /// No description provided for @repoInlineLanguageSpanish.
  ///
  /// In es, this message translates to:
  /// **'español'**
  String get repoInlineLanguageSpanish;

  /// No description provided for @repoNetworkCommunicationError.
  ///
  /// In es, this message translates to:
  /// **'Ocurrió un error de comunicación con el servidor'**
  String get repoNetworkCommunicationError;

  /// No description provided for @repoNetworkConnectionTimeout.
  ///
  /// In es, this message translates to:
  /// **'Tiempo de conexión agotado'**
  String get repoNetworkConnectionTimeout;

  /// No description provided for @repoNetworkNoConnection.
  ///
  /// In es, this message translates to:
  /// **'No hay conexión a internet'**
  String get repoNetworkNoConnection;

  /// No description provided for @repoNetworkRetryIn.
  ///
  /// In es, this message translates to:
  /// **'{message} Puedes reintentar en {wait}.'**
  String repoNetworkRetryIn(String message, String wait);

  /// No description provided for @repoNetworkServerTimeout.
  ///
  /// In es, this message translates to:
  /// **'El servidor tardó demasiado en responder'**
  String get repoNetworkServerTimeout;

  /// No description provided for @repoNetworkSessionExpired.
  ///
  /// In es, this message translates to:
  /// **'Sesión expirada, vuelve a iniciar sesión'**
  String get repoNetworkSessionExpired;

  /// No description provided for @repoNetworkTooManyAttempts.
  ///
  /// In es, this message translates to:
  /// **'Demasiados intentos, espera un momento e intenta de nuevo'**
  String get repoNetworkTooManyAttempts;

  /// No description provided for @repoNetworkWaitMinutes.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 minuto} other{{count} minutos}}'**
  String repoNetworkWaitMinutes(int count);

  /// No description provided for @repoNetworkWaitSeconds.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 segundo} other{{count} segundos}}'**
  String repoNetworkWaitSeconds(int count);

  /// No description provided for @repoNotificationBookingChanges.
  ///
  /// In es, this message translates to:
  /// **'Cambios en mis reservas'**
  String get repoNotificationBookingChanges;

  /// No description provided for @repoNotificationNewsAndBenefits.
  ///
  /// In es, this message translates to:
  /// **'Beneficios y novedades'**
  String get repoNotificationNewsAndBenefits;

  /// No description provided for @repoNotificationSavedEvents.
  ///
  /// In es, this message translates to:
  /// **'Eventos guardados'**
  String get repoNotificationSavedEvents;

  /// No description provided for @repoNotificationTripReminders.
  ///
  /// In es, this message translates to:
  /// **'Recordatorios de viajes'**
  String get repoNotificationTripReminders;

  /// No description provided for @repoSpecialtiesPair.
  ///
  /// In es, this message translates to:
  /// **'{first} y {second}'**
  String repoSpecialtiesPair(String first, String second);

  /// No description provided for @repoTourBadgesNote.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =0{Este recorrido no tiene insignias coleccionables} =1{Este recorrido contiene 1 insignia coleccionable} other{Este recorrido contiene un total de {count} insignias coleccionables}}'**
  String repoTourBadgesNote(int count);

  /// No description provided for @repoTourBadgesNoteBonus.
  ///
  /// In es, this message translates to:
  /// **'Este recorrido contiene un total de {count} insignias coleccionables, más {extra} insignias extra al completarlo'**
  String repoTourBadgesNoteBonus(int count, int extra);

  /// No description provided for @repoTourBadgesNoteCreative.
  ///
  /// In es, this message translates to:
  /// **'Este recorrido contiene un total de {count} insignias coleccionables, más {extra} insignias extra de \"Circuitos creativos\" y una medalla de {city} al completarlo'**
  String repoTourBadgesNoteCreative(int count, int extra, String city);

  /// No description provided for @repoTourDifficultyEasy.
  ///
  /// In es, this message translates to:
  /// **'Fácil'**
  String get repoTourDifficultyEasy;

  /// No description provided for @repoTourDifficultyModerate.
  ///
  /// In es, this message translates to:
  /// **'Moderado'**
  String get repoTourDifficultyModerate;

  /// No description provided for @repoTourDurationAbout.
  ///
  /// In es, this message translates to:
  /// **'{hours} h aprox.'**
  String repoTourDurationAbout(int hours);

  /// No description provided for @repoTourDurationDay.
  ///
  /// In es, this message translates to:
  /// **'1 día'**
  String get repoTourDurationDay;

  /// No description provided for @repoTouristNotFound.
  ///
  /// In es, this message translates to:
  /// **'No encontramos a este turista'**
  String get repoTouristNotFound;

  /// No description provided for @repoTouristRateOnce.
  ///
  /// In es, this message translates to:
  /// **'Solo puedes calificar una vez, después de terminar el viaje'**
  String get repoTouristRateOnce;

  /// No description provided for @repoTouristRateStars.
  ///
  /// In es, this message translates to:
  /// **'Elige de 1 a 5 estrellas'**
  String get repoTouristRateStars;

  /// No description provided for @repoTouristRatingToday.
  ///
  /// In es, this message translates to:
  /// **'hoy'**
  String get repoTouristRatingToday;

  /// No description provided for @repoWorkAmountExceedsAvailable.
  ///
  /// In es, this message translates to:
  /// **'Solo tienes {amount} disponibles'**
  String repoWorkAmountExceedsAvailable(String amount);

  /// No description provided for @repoWorkAmountInvalid.
  ///
  /// In es, this message translates to:
  /// **'Escribe un monto mayor a cero'**
  String get repoWorkAmountInvalid;

  /// No description provided for @repoWorkGuideFallbackName.
  ///
  /// In es, this message translates to:
  /// **'Guía de K’Plan'**
  String get repoWorkGuideFallbackName;

  /// No description provided for @repoWorkHireGreeting.
  ///
  /// In es, this message translates to:
  /// **'¡Hola! Te contraté para {circuitTitle}. ¿Dónde nos vemos?'**
  String repoWorkHireGreeting(String circuitTitle);

  /// No description provided for @repoWorkJobNotFound.
  ///
  /// In es, this message translates to:
  /// **'No encontramos esta propuesta'**
  String get repoWorkJobNotFound;

  /// No description provided for @repoWorkJobNotOpen.
  ///
  /// In es, this message translates to:
  /// **'Ya no puedes postularte a esta propuesta'**
  String get repoWorkJobNotOpen;

  /// No description provided for @repoWorkPriceInvalid.
  ///
  /// In es, this message translates to:
  /// **'Escribe un precio mayor a cero'**
  String get repoWorkPriceInvalid;

  /// No description provided for @repoWorkSampleBankAccount.
  ///
  /// In es, this message translates to:
  /// **'Cuenta de ejemplo •••• 0000'**
  String get repoWorkSampleBankAccount;

  /// No description provided for @repoWorkWithdrawLoginRequired.
  ///
  /// In es, this message translates to:
  /// **'Inicia sesión como guía para retirar'**
  String get repoWorkWithdrawLoginRequired;

  /// No description provided for @reviewDisputeHint.
  ///
  /// In es, this message translates to:
  /// **'Explica por qué el equipo debería revisarla'**
  String get reviewDisputeHint;

  /// No description provided for @reviewDisputeSend.
  ///
  /// In es, this message translates to:
  /// **'Pedir revisión'**
  String get reviewDisputeSend;

  /// No description provided for @reviewDisputeSent.
  ///
  /// In es, this message translates to:
  /// **'Le pedimos al equipo que revise la reseña.'**
  String get reviewDisputeSent;

  /// No description provided for @reviewDisputeTitle.
  ///
  /// In es, this message translates to:
  /// **'Impugnar la reseña'**
  String get reviewDisputeTitle;

  /// No description provided for @reviewDisputeTooShort.
  ///
  /// In es, this message translates to:
  /// **'Escribe al menos 10 caracteres'**
  String get reviewDisputeTooShort;

  /// No description provided for @routeMapAllowLocationInSettings.
  ///
  /// In es, this message translates to:
  /// **'Permite la ubicación en los ajustes para verte en el mapa'**
  String get routeMapAllowLocationInSettings;

  /// No description provided for @routeMapAlreadyHere.
  ///
  /// In es, this message translates to:
  /// **'Ya estás aquí'**
  String get routeMapAlreadyHere;

  /// No description provided for @routeMapArrival.
  ///
  /// In es, this message translates to:
  /// **'Llegada {time}'**
  String routeMapArrival(String time);

  /// No description provided for @routeMapArrivalDelay.
  ///
  /// In es, this message translates to:
  /// **'Llegada {time} · {delay}'**
  String routeMapArrivalDelay(String time, String delay);

  /// No description provided for @routeMapBadgeEarned.
  ///
  /// In es, this message translates to:
  /// **'Insignia de {category} obtenida'**
  String routeMapBadgeEarned(String category);

  /// No description provided for @routeMapBadgeToEarn.
  ///
  /// In es, this message translates to:
  /// **'Escanea su código QR para ganar la insignia de {category}'**
  String routeMapBadgeToEarn(String category);

  /// No description provided for @routeMapCenterPlace.
  ///
  /// In es, this message translates to:
  /// **'Centrar el lugar'**
  String get routeMapCenterPlace;

  /// No description provided for @routeMapDemoQrTooltip.
  ///
  /// In es, this message translates to:
  /// **'Ver código de prueba'**
  String get routeMapDemoQrTooltip;

  /// No description provided for @routeMapDirections.
  ///
  /// In es, this message translates to:
  /// **'Cómo llegar'**
  String get routeMapDirections;

  /// No description provided for @routeMapDistanceFromYou.
  ///
  /// In es, this message translates to:
  /// **'A {distance} de ti · {label}'**
  String routeMapDistanceFromYou(String distance, String label);

  /// No description provided for @routeMapEndTrip.
  ///
  /// In es, this message translates to:
  /// **'Finalizar viaje'**
  String get routeMapEndTrip;

  /// No description provided for @routeMapFreeEntry.
  ///
  /// In es, this message translates to:
  /// **'Entrada libre'**
  String get routeMapFreeEntry;

  /// No description provided for @routeMapGoToNext.
  ///
  /// In es, this message translates to:
  /// **'Ir a la siguiente: {name}'**
  String routeMapGoToNext(String name);

  /// No description provided for @routeMapLocationHint.
  ///
  /// In es, this message translates to:
  /// **'Activa tu ubicación para verte en el mapa'**
  String get routeMapLocationHint;

  /// No description provided for @routeMapLocationOffInSettings.
  ///
  /// In es, this message translates to:
  /// **'Apagaste la ubicación en Configuraciones'**
  String get routeMapLocationOffInSettings;

  /// No description provided for @routeMapMyCircuit.
  ///
  /// In es, this message translates to:
  /// **'Mi circuito'**
  String get routeMapMyCircuit;

  /// No description provided for @routeMapMyLocation.
  ///
  /// In es, this message translates to:
  /// **'Mi ubicación'**
  String get routeMapMyLocation;

  /// No description provided for @routeMapNextStop.
  ///
  /// In es, this message translates to:
  /// **'Siguiente: {name}'**
  String routeMapNextStop(String name);

  /// No description provided for @routeMapNextStopOverline.
  ///
  /// In es, this message translates to:
  /// **'Siguiente parada'**
  String get routeMapNextStopOverline;

  /// No description provided for @routeMapNoLocation.
  ///
  /// In es, this message translates to:
  /// **'Sin tu ubicación, el mapa no puede mostrarte'**
  String get routeMapNoLocation;

  /// No description provided for @routeMapNoStops.
  ///
  /// In es, this message translates to:
  /// **'Este circuito todavía no tiene paradas'**
  String get routeMapNoStops;

  /// No description provided for @routeMapOpenHours.
  ///
  /// In es, this message translates to:
  /// **'Abierto de {hours}'**
  String routeMapOpenHours(String hours);

  /// No description provided for @routeMapOverlineEvent.
  ///
  /// In es, this message translates to:
  /// **'Evento'**
  String get routeMapOverlineEvent;

  /// No description provided for @routeMapOverlineStop.
  ///
  /// In es, this message translates to:
  /// **'Parada'**
  String get routeMapOverlineStop;

  /// No description provided for @routeMapScanQr.
  ///
  /// In es, this message translates to:
  /// **'Escanear código QR'**
  String get routeMapScanQr;

  /// No description provided for @routeMapSearchingLocation.
  ///
  /// In es, this message translates to:
  /// **'Buscando tu ubicación…'**
  String get routeMapSearchingLocation;

  /// No description provided for @routeMapSettingsAction.
  ///
  /// In es, this message translates to:
  /// **'Ajustes'**
  String get routeMapSettingsAction;

  /// No description provided for @routeMapShowWholeRoute.
  ///
  /// In es, this message translates to:
  /// **'Ver todo el recorrido'**
  String get routeMapShowWholeRoute;

  /// No description provided for @routeMapStopCount.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 parada} other{{count} paradas}}'**
  String routeMapStopCount(int count);

  /// No description provided for @routeMapStopOfTotal.
  ///
  /// In es, this message translates to:
  /// **'Parada {number} de {total}'**
  String routeMapStopOfTotal(int number, int total);

  /// No description provided for @routeMapStopSkipped.
  ///
  /// In es, this message translates to:
  /// **'Parada {number} · Saltada'**
  String routeMapStopSkipped(int number);

  /// No description provided for @routeMapStopVisited.
  ///
  /// In es, this message translates to:
  /// **'Parada {number} · Visitada'**
  String routeMapStopVisited(int number);

  /// No description provided for @routeMapSuggestedVisit.
  ///
  /// In es, this message translates to:
  /// **'Visita sugerida: {duration}'**
  String routeMapSuggestedVisit(String duration);

  /// No description provided for @routeMapTapStopHint.
  ///
  /// In es, this message translates to:
  /// **'Toca una parada para ver su información'**
  String get routeMapTapStopHint;

  /// No description provided for @routeMapTips.
  ///
  /// In es, this message translates to:
  /// **'Recomendaciones'**
  String get routeMapTips;

  /// No description provided for @routeMapTripComplete.
  ///
  /// In es, this message translates to:
  /// **'¡Recorrido completo!'**
  String get routeMapTripComplete;

  /// No description provided for @routeMapTripEnded.
  ///
  /// In es, this message translates to:
  /// **'Viaje finalizado'**
  String get routeMapTripEnded;

  /// No description provided for @routeMapTurnOn.
  ///
  /// In es, this message translates to:
  /// **'Activar'**
  String get routeMapTurnOn;

  /// No description provided for @routeMapTurnOnPhoneLocation.
  ///
  /// In es, this message translates to:
  /// **'Enciende la ubicación del teléfono para verte en el mapa'**
  String get routeMapTurnOnPhoneLocation;

  /// No description provided for @routeMapVisitConfirmed.
  ///
  /// In es, this message translates to:
  /// **'¡Visita a {name} confirmada!'**
  String routeMapVisitConfirmed(String name);

  /// No description provided for @routeMapWhySkip.
  ///
  /// In es, this message translates to:
  /// **'¿Por qué saltas {name}?'**
  String routeMapWhySkip(String name);

  /// No description provided for @routeMapYouSkipped.
  ///
  /// In es, this message translates to:
  /// **'La saltaste'**
  String get routeMapYouSkipped;

  /// No description provided for @routeMapYouSkippedReason.
  ///
  /// In es, this message translates to:
  /// **'La saltaste · {reason}'**
  String routeMapYouSkippedReason(String reason);

  /// No description provided for @savedEmpty.
  ///
  /// In es, this message translates to:
  /// **'Todavía no guardaste nada'**
  String get savedEmpty;

  /// No description provided for @savedEmptyMessage.
  ///
  /// In es, this message translates to:
  /// **'Toca el marcador de un circuito, una parada o un evento y lo encontrarás aquí.'**
  String get savedEmptyMessage;

  /// No description provided for @savedHeadline.
  ///
  /// In es, this message translates to:
  /// **'Tus próximos descubrimientos'**
  String get savedHeadline;

  /// No description provided for @savedSectionPlaces.
  ///
  /// In es, this message translates to:
  /// **'Lugares'**
  String get savedSectionPlaces;

  /// No description provided for @settingsAccountAddName.
  ///
  /// In es, this message translates to:
  /// **'Agrega tu nombre'**
  String get settingsAccountAddName;

  /// No description provided for @settingsAccountChangePasswordSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Con tu contraseña actual'**
  String get settingsAccountChangePasswordSubtitle;

  /// No description provided for @settingsAccountLoginEmail.
  ///
  /// In es, this message translates to:
  /// **'Correo de acceso'**
  String get settingsAccountLoginEmail;

  /// No description provided for @settingsAccountNameRequired.
  ///
  /// In es, this message translates to:
  /// **'Escribe tu nombre'**
  String get settingsAccountNameRequired;

  /// No description provided for @settingsAccountNameTitle.
  ///
  /// In es, this message translates to:
  /// **'Tu nombre'**
  String get settingsAccountNameTitle;

  /// No description provided for @settingsAccountPersonalData.
  ///
  /// In es, this message translates to:
  /// **'Datos personales'**
  String get settingsAccountPersonalData;

  /// No description provided for @settingsAccountTitle.
  ///
  /// In es, this message translates to:
  /// **'Cuenta'**
  String get settingsAccountTitle;

  /// No description provided for @settingsAccountTwoFactorOff.
  ///
  /// In es, this message translates to:
  /// **'Pide un código extra al entrar'**
  String get settingsAccountTwoFactorOff;

  /// No description provided for @settingsAccountTwoFactorOn.
  ///
  /// In es, this message translates to:
  /// **'Activa'**
  String get settingsAccountTwoFactorOn;

  /// No description provided for @settingsAccountTwoFactorTitle.
  ///
  /// In es, this message translates to:
  /// **'Verificación en dos pasos'**
  String get settingsAccountTwoFactorTitle;

  /// No description provided for @settingsBookingHelpBody.
  ///
  /// In es, this message translates to:
  /// **'En Mis viajes ves la fecha, la hora de salida, las personas y, si lo contrataste, tu guía. Antes de cancelar, revisa las condiciones del servicio en el detalle del circuito.'**
  String get settingsBookingHelpBody;

  /// No description provided for @settingsBookingHelpHeading.
  ///
  /// In es, this message translates to:
  /// **'Encuentra los detalles de tu viaje'**
  String get settingsBookingHelpHeading;

  /// No description provided for @settingsBookingHelpTitle.
  ///
  /// In es, this message translates to:
  /// **'Ayuda con mi reserva'**
  String get settingsBookingHelpTitle;

  /// No description provided for @settingsBookingHelpViewTrips.
  ///
  /// In es, this message translates to:
  /// **'Ver mis viajes'**
  String get settingsBookingHelpViewTrips;

  /// No description provided for @settingsChangePassword.
  ///
  /// In es, this message translates to:
  /// **'Cambiar contraseña'**
  String get settingsChangePassword;

  /// No description provided for @settingsContactSupport.
  ///
  /// In es, this message translates to:
  /// **'Contactar soporte'**
  String get settingsContactSupport;

  /// No description provided for @settingsDataUsageBody.
  ///
  /// In es, this message translates to:
  /// **'La ubicación sirve para mostrarte en el mapa durante un recorrido; puedes apagarla en Privacidad. Tu correo y tu nombre se usan para gestionar tu cuenta y tus reservas.'**
  String get settingsDataUsageBody;

  /// No description provided for @settingsDataUsageHeading.
  ///
  /// In es, this message translates to:
  /// **'Tú decides qué compartir'**
  String get settingsDataUsageHeading;

  /// No description provided for @settingsDataUsageRightsBody.
  ///
  /// In es, this message translates to:
  /// **'Puedes pedir una copia de tus datos o que los borremos escribiéndole al equipo de soporte.'**
  String get settingsDataUsageRightsBody;

  /// No description provided for @settingsDataUsageRightsTitle.
  ///
  /// In es, this message translates to:
  /// **'Tus derechos'**
  String get settingsDataUsageRightsTitle;

  /// No description provided for @settingsDataUsageTitle.
  ///
  /// In es, this message translates to:
  /// **'Uso de tus datos'**
  String get settingsDataUsageTitle;

  /// No description provided for @settingsDataUsageWriteSupport.
  ///
  /// In es, this message translates to:
  /// **'Escribir a soporte'**
  String get settingsDataUsageWriteSupport;

  /// No description provided for @settingsHelpBookingSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Confirmaciones y cancelaciones'**
  String get settingsHelpBookingSubtitle;

  /// No description provided for @settingsHelpBookingTitle.
  ///
  /// In es, this message translates to:
  /// **'Mi reserva'**
  String get settingsHelpBookingTitle;

  /// No description provided for @settingsHelpContactSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Cuéntanos qué ocurrió'**
  String get settingsHelpContactSubtitle;

  /// No description provided for @settingsHelpHeading.
  ///
  /// In es, this message translates to:
  /// **'¿En qué podemos ayudarte?'**
  String get settingsHelpHeading;

  /// No description provided for @settingsHelpPrivacySubtitle.
  ///
  /// In es, this message translates to:
  /// **'Controles de tus datos'**
  String get settingsHelpPrivacySubtitle;

  /// No description provided for @settingsHelpPrivacyTitle.
  ///
  /// In es, this message translates to:
  /// **'Privacidad'**
  String get settingsHelpPrivacyTitle;

  /// No description provided for @settingsHelpTitle.
  ///
  /// In es, this message translates to:
  /// **'Ayuda y soporte'**
  String get settingsHelpTitle;

  /// No description provided for @settingsHomeAccount.
  ///
  /// In es, this message translates to:
  /// **'Cuenta'**
  String get settingsHomeAccount;

  /// No description provided for @settingsHomeAccountSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Datos y acceso'**
  String get settingsHomeAccountSubtitle;

  /// No description provided for @settingsHomeHelp.
  ///
  /// In es, this message translates to:
  /// **'Ayuda y soporte'**
  String get settingsHomeHelp;

  /// No description provided for @settingsHomeHelpSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Preguntas y contacto'**
  String get settingsHomeHelpSubtitle;

  /// No description provided for @settingsHomeNotificationsOff.
  ///
  /// In es, this message translates to:
  /// **'Todos los avisos apagados'**
  String get settingsHomeNotificationsOff;

  /// No description provided for @settingsHomeNotificationsOn.
  ///
  /// In es, this message translates to:
  /// **'Viajes, reservas y eventos'**
  String get settingsHomeNotificationsOn;

  /// No description provided for @settingsHomePrivacy.
  ///
  /// In es, this message translates to:
  /// **'Privacidad y seguridad'**
  String get settingsHomePrivacy;

  /// No description provided for @settingsHomePrivacySubtitle.
  ///
  /// In es, this message translates to:
  /// **'Ubicación y datos personales'**
  String get settingsHomePrivacySubtitle;

  /// No description provided for @settingsLogoutNote.
  ///
  /// In es, this message translates to:
  /// **'Tus guardados y viajes siguen asociados a tu cuenta.'**
  String get settingsLogoutNote;

  /// No description provided for @settingsLogoutTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Cerrar tu sesión?'**
  String get settingsLogoutTitle;

  /// No description provided for @settingsNotificationsHeading.
  ///
  /// In es, this message translates to:
  /// **'Mantente al tanto'**
  String get settingsNotificationsHeading;

  /// No description provided for @settingsNotificationsInboxNote.
  ///
  /// In es, this message translates to:
  /// **'Apagar un aviso solo deja de mandarlo al teléfono: siempre llega a tu bandeja de avisos.'**
  String get settingsNotificationsInboxNote;

  /// No description provided for @settingsNotificationsPermissionNote.
  ///
  /// In es, this message translates to:
  /// **'El permiso para mostrar notificaciones se cambia desde la configuración del teléfono.'**
  String get settingsNotificationsPermissionNote;

  /// No description provided for @settingsPasswordChangeCurrent.
  ///
  /// In es, this message translates to:
  /// **'Contraseña actual'**
  String get settingsPasswordChangeCurrent;

  /// No description provided for @settingsPasswordChangeCurrentRequired.
  ///
  /// In es, this message translates to:
  /// **'Escribe tu contraseña actual'**
  String get settingsPasswordChangeCurrentRequired;

  /// No description provided for @settingsPasswordChangedDemoNote.
  ///
  /// In es, this message translates to:
  /// **'Demostración: no hay un servidor que la guarde.'**
  String get settingsPasswordChangedDemoNote;

  /// No description provided for @settingsPasswordChangedLogInAgain.
  ///
  /// In es, this message translates to:
  /// **'Contraseña actualizada. Vuelve a entrar.'**
  String get settingsPasswordChangedLogInAgain;

  /// No description provided for @settingsPasswordChangedMessage.
  ///
  /// In es, this message translates to:
  /// **'Tu contraseña nueva ya sirve.'**
  String get settingsPasswordChangedMessage;

  /// No description provided for @settingsPasswordChangedTitle.
  ///
  /// In es, this message translates to:
  /// **'Contraseña actualizada'**
  String get settingsPasswordChangedTitle;

  /// No description provided for @settingsPasswordChangeIntro.
  ///
  /// In es, this message translates to:
  /// **'Por seguridad, al cambiarla cerraremos tu sesión en todos tus dispositivos y tendrás que volver a entrar.'**
  String get settingsPasswordChangeIntro;

  /// No description provided for @settingsPasswordChangeRepeat.
  ///
  /// In es, this message translates to:
  /// **'Repite la contraseña nueva'**
  String get settingsPasswordChangeRepeat;

  /// No description provided for @settingsPasswordResetBackToAccount.
  ///
  /// In es, this message translates to:
  /// **'Volver a Cuenta'**
  String get settingsPasswordResetBackToAccount;

  /// No description provided for @settingsPrivacyAccountSecurity.
  ///
  /// In es, this message translates to:
  /// **'Seguridad de la cuenta'**
  String get settingsPrivacyAccountSecurity;

  /// No description provided for @settingsPrivacyDataUsageSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Información y controles'**
  String get settingsPrivacyDataUsageSubtitle;

  /// No description provided for @settingsPrivacyPersonalize.
  ///
  /// In es, this message translates to:
  /// **'Personalizar recomendaciones'**
  String get settingsPrivacyPersonalize;

  /// No description provided for @settingsPrivacyPersonalizeDescription.
  ///
  /// In es, this message translates to:
  /// **'Según los circuitos que guardas y recorres'**
  String get settingsPrivacyPersonalizeDescription;

  /// No description provided for @settingsPrivacyShowBadges.
  ///
  /// In es, this message translates to:
  /// **'Mostrar insignias en mi perfil'**
  String get settingsPrivacyShowBadges;

  /// No description provided for @settingsPrivacyTitle.
  ///
  /// In es, this message translates to:
  /// **'Privacidad y seguridad'**
  String get settingsPrivacyTitle;

  /// No description provided for @settingsPrivacyUseLocation.
  ///
  /// In es, this message translates to:
  /// **'Usar ubicación al explorar'**
  String get settingsPrivacyUseLocation;

  /// No description provided for @settingsPrivacyUseLocationDescription.
  ///
  /// In es, this message translates to:
  /// **'Para verte en el mapa durante un recorrido'**
  String get settingsPrivacyUseLocationDescription;

  /// No description provided for @settingsSupportBackToHelp.
  ///
  /// In es, this message translates to:
  /// **'Volver a Ayuda'**
  String get settingsSupportBackToHelp;

  /// No description provided for @settingsSupportDemoNote.
  ///
  /// In es, this message translates to:
  /// **'Demostración: por ahora el mensaje no sale de tu teléfono.'**
  String get settingsSupportDemoNote;

  /// No description provided for @settingsSupportMessage.
  ///
  /// In es, this message translates to:
  /// **'Mensaje'**
  String get settingsSupportMessage;

  /// No description provided for @settingsSupportMessageHint.
  ///
  /// In es, this message translates to:
  /// **'Qué pasó, en qué circuito y cuándo'**
  String get settingsSupportMessageHint;

  /// No description provided for @settingsSupportMessageRequired.
  ///
  /// In es, this message translates to:
  /// **'Escribe tu mensaje'**
  String get settingsSupportMessageRequired;

  /// No description provided for @settingsSupportReplyTo.
  ///
  /// In es, this message translates to:
  /// **'Te responderemos a {email}.'**
  String settingsSupportReplyTo(String email);

  /// No description provided for @settingsSupportSend.
  ///
  /// In es, this message translates to:
  /// **'Enviar consulta'**
  String get settingsSupportSend;

  /// No description provided for @settingsSupportSentMessage.
  ///
  /// In es, this message translates to:
  /// **'El equipo de soporte te responderá a {email}.'**
  String settingsSupportSentMessage(String email);

  /// No description provided for @settingsSupportSentPanelTitle.
  ///
  /// In es, this message translates to:
  /// **'Tu consulta está lista'**
  String get settingsSupportSentPanelTitle;

  /// No description provided for @settingsSupportSentTitle.
  ///
  /// In es, this message translates to:
  /// **'Consulta enviada'**
  String get settingsSupportSentTitle;

  /// No description provided for @settingsSupportSubject.
  ///
  /// In es, this message translates to:
  /// **'Asunto'**
  String get settingsSupportSubject;

  /// No description provided for @settingsSupportSubjectHint.
  ///
  /// In es, this message translates to:
  /// **'Ej. Consulta sobre mi reserva'**
  String get settingsSupportSubjectHint;

  /// No description provided for @settingsSupportSubjectRequired.
  ///
  /// In es, this message translates to:
  /// **'Cuéntanos de qué se trata'**
  String get settingsSupportSubjectRequired;

  /// No description provided for @sharedAddToCircuit.
  ///
  /// In es, this message translates to:
  /// **'Añadir a un circuito'**
  String get sharedAddToCircuit;

  /// No description provided for @sharedAlwaysUseOption.
  ///
  /// In es, this message translates to:
  /// **'Usar siempre esta opción'**
  String get sharedAlwaysUseOption;

  /// No description provided for @sharedBadgeEarnedSubtitle.
  ///
  /// In es, this message translates to:
  /// **'{category} · ¡Sigue así!'**
  String sharedBadgeEarnedSubtitle(String category);

  /// No description provided for @sharedBadgeEarnedTitle.
  ///
  /// In es, this message translates to:
  /// **'+1 insignia'**
  String get sharedBadgeEarnedTitle;

  /// No description provided for @sharedChangeArrivalTime.
  ///
  /// In es, this message translates to:
  /// **'Cambiar hora de llegada, {time}'**
  String sharedChangeArrivalTime(String time);

  /// No description provided for @sharedCloseHint.
  ///
  /// In es, this message translates to:
  /// **'cerrar'**
  String get sharedCloseHint;

  /// No description provided for @sharedContinueTrip.
  ///
  /// In es, this message translates to:
  /// **'Seguir el viaje'**
  String get sharedContinueTrip;

  /// No description provided for @sharedCreativeBannerBody.
  ///
  /// In es, this message translates to:
  /// **'Lo creó la {organizer}. Se hace en grupo: te inscribes en un horario publicado por un guía certificado.'**
  String sharedCreativeBannerBody(String organizer);

  /// No description provided for @sharedCreativeBannerBodyNoOrganizer.
  ///
  /// In es, this message translates to:
  /// **'Lo creó una alcaldía. Se hace en grupo: te inscribes en un horario publicado por un guía certificado.'**
  String get sharedCreativeBannerBodyNoOrganizer;

  /// No description provided for @sharedCreativeBannerTitle.
  ///
  /// In es, this message translates to:
  /// **'Circuito creativo oficial'**
  String get sharedCreativeBannerTitle;

  /// No description provided for @sharedCreativeCircuitBadge.
  ///
  /// In es, this message translates to:
  /// **'Circuito creativo'**
  String get sharedCreativeCircuitBadge;

  /// No description provided for @sharedCreativeCityMedal.
  ///
  /// In es, this message translates to:
  /// **'Medalla de {city}'**
  String sharedCreativeCityMedal(String city);

  /// No description provided for @sharedCreativeExtraBadges.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{+1 insignia extra} other{+{count} insignias extra}}'**
  String sharedCreativeExtraBadges(int count);

  /// No description provided for @sharedDirectionsWithTitle.
  ///
  /// In es, this message translates to:
  /// **'Cómo llegar con...'**
  String get sharedDirectionsWithTitle;

  /// No description provided for @sharedDragToReorder.
  ///
  /// In es, this message translates to:
  /// **'Arrastrar para cambiar el orden'**
  String get sharedDragToReorder;

  /// No description provided for @sharedDropWhyWeAsk.
  ///
  /// In es, this message translates to:
  /// **'Nos ayuda a mejorar los circuitos y a que cada lugar sepa qué pasó.'**
  String get sharedDropWhyWeAsk;

  /// No description provided for @sharedEndTrip.
  ///
  /// In es, this message translates to:
  /// **'Finalizar'**
  String get sharedEndTrip;

  /// No description provided for @sharedFilterAll.
  ///
  /// In es, this message translates to:
  /// **'Todas'**
  String get sharedFilterAll;

  /// No description provided for @sharedHidePassword.
  ///
  /// In es, this message translates to:
  /// **'Ocultar contraseña'**
  String get sharedHidePassword;

  /// No description provided for @sharedHiredCoordinate.
  ///
  /// In es, this message translates to:
  /// **'Coordina el punto de encuentro por el chat.'**
  String get sharedHiredCoordinate;

  /// No description provided for @sharedHiredGoToChat.
  ///
  /// In es, this message translates to:
  /// **'Ir al chat'**
  String get sharedHiredGoToChat;

  /// No description provided for @sharedHiredName.
  ///
  /// In es, this message translates to:
  /// **'¡Contrataste a {name}!'**
  String sharedHiredName(String name);

  /// No description provided for @sharedHiredTeamReady.
  ///
  /// In es, this message translates to:
  /// **'¡Tu equipo está listo!'**
  String get sharedHiredTeamReady;

  /// No description provided for @sharedItineraryEnds.
  ///
  /// In es, this message translates to:
  /// **'Termina aprox. {time}'**
  String sharedItineraryEnds(String time);

  /// No description provided for @sharedItineraryFreeTime.
  ///
  /// In es, this message translates to:
  /// **'{travel} · {duration} libres'**
  String sharedItineraryFreeTime(String travel, String duration);

  /// No description provided for @sharedItineraryTravelTime.
  ///
  /// In es, this message translates to:
  /// **'{duration} de traslados'**
  String sharedItineraryTravelTime(String duration);

  /// No description provided for @sharedItineraryWarningsTitle.
  ///
  /// In es, this message translates to:
  /// **'Para tener en cuenta'**
  String get sharedItineraryWarningsTitle;

  /// No description provided for @sharedMapStart.
  ///
  /// In es, this message translates to:
  /// **'Inicio'**
  String get sharedMapStart;

  /// No description provided for @sharedNationalityNoResults.
  ///
  /// In es, this message translates to:
  /// **'No encontramos ese país'**
  String get sharedNationalityNoResults;

  /// No description provided for @sharedNationalitySearchHint.
  ///
  /// In es, this message translates to:
  /// **'Busca tu país'**
  String get sharedNationalitySearchHint;

  /// No description provided for @sharedNationalityTitle.
  ///
  /// In es, this message translates to:
  /// **'Tu nacionalidad'**
  String get sharedNationalityTitle;

  /// No description provided for @sharedNavProfile.
  ///
  /// In es, this message translates to:
  /// **'Perfil'**
  String get sharedNavProfile;

  /// No description provided for @sharedNewCircuitCreate.
  ///
  /// In es, this message translates to:
  /// **'Crear'**
  String get sharedNewCircuitCreate;

  /// No description provided for @sharedNewCircuitEmpty.
  ///
  /// In es, this message translates to:
  /// **'Ponle un nombre a tu circuito'**
  String get sharedNewCircuitEmpty;

  /// No description provided for @sharedNewCircuitHint.
  ///
  /// In es, this message translates to:
  /// **'Ej. Fin de semana en el sur'**
  String get sharedNewCircuitHint;

  /// No description provided for @sharedNewCircuitTitle.
  ///
  /// In es, this message translates to:
  /// **'Nuevo circuito'**
  String get sharedNewCircuitTitle;

  /// No description provided for @sharedNewCircuitTooShort.
  ///
  /// In es, this message translates to:
  /// **'Usa al menos 3 caracteres'**
  String get sharedNewCircuitTooShort;

  /// No description provided for @sharedOpenAppFailed.
  ///
  /// In es, this message translates to:
  /// **'No se pudo abrir {app}'**
  String sharedOpenAppFailed(String app);

  /// No description provided for @sharedOpenWithTitle.
  ///
  /// In es, this message translates to:
  /// **'Abrir circuito con...'**
  String get sharedOpenWithTitle;

  /// No description provided for @sharedRemoveFromSaved.
  ///
  /// In es, this message translates to:
  /// **'Quitar de guardados'**
  String get sharedRemoveFromSaved;

  /// No description provided for @sharedReorderHint.
  ///
  /// In es, this message translates to:
  /// **'Arrastra cada parada a su lugar. Los horarios del itinerario se recalculan solos.'**
  String get sharedReorderHint;

  /// No description provided for @sharedReorderSave.
  ///
  /// In es, this message translates to:
  /// **'Guardar orden'**
  String get sharedReorderSave;

  /// No description provided for @sharedReorderTitle.
  ///
  /// In es, this message translates to:
  /// **'Ordenar paradas'**
  String get sharedReorderTitle;

  /// No description provided for @sharedReviewsCount.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{(1 reseña)} other{({count} reseñas)}}'**
  String sharedReviewsCount(int count);

  /// No description provided for @sharedSearchByVoice.
  ///
  /// In es, this message translates to:
  /// **'Buscar por voz'**
  String get sharedSearchByVoice;

  /// No description provided for @sharedShowPassword.
  ///
  /// In es, this message translates to:
  /// **'Mostrar contraseña'**
  String get sharedShowPassword;

  /// No description provided for @sharedSkip.
  ///
  /// In es, this message translates to:
  /// **'Saltar'**
  String get sharedSkip;

  /// No description provided for @sharedStopBadge.
  ///
  /// In es, this message translates to:
  /// **'Insignia'**
  String get sharedStopBadge;

  /// No description provided for @sharedTimePickerHour.
  ///
  /// In es, this message translates to:
  /// **'Hora'**
  String get sharedTimePickerHour;

  /// No description provided for @sharedTimePickerMinutes.
  ///
  /// In es, this message translates to:
  /// **'Minutos'**
  String get sharedTimePickerMinutes;

  /// No description provided for @sharedTripAllStopsDone.
  ///
  /// In es, this message translates to:
  /// **'Ya pasaste por todas las paradas. Toca Finalizar para cerrar el viaje.'**
  String get sharedTripAllStopsDone;

  /// No description provided for @sharedTripArrivedAt.
  ///
  /// In es, this message translates to:
  /// **'Llegaste a las {time}'**
  String sharedTripArrivedAt(String time);

  /// No description provided for @sharedTripConflictBody.
  ///
  /// In es, this message translates to:
  /// **'Estás recorriendo {title}. Sólo se puede seguir un circuito a la vez: finalízalo para comenzar este.'**
  String sharedTripConflictBody(String title);

  /// No description provided for @sharedTripConflictEndAndStart.
  ///
  /// In es, this message translates to:
  /// **'Finalizar ese y comenzar este'**
  String get sharedTripConflictEndAndStart;

  /// No description provided for @sharedTripConflictGoToActive.
  ///
  /// In es, this message translates to:
  /// **'Ir al viaje en curso'**
  String get sharedTripConflictGoToActive;

  /// No description provided for @sharedTripConflictTitle.
  ///
  /// In es, this message translates to:
  /// **'Ya tienes un viaje en curso'**
  String get sharedTripConflictTitle;

  /// No description provided for @sharedTripDelayed.
  ///
  /// In es, this message translates to:
  /// **'Vas {duration} atrasado'**
  String sharedTripDelayed(String duration);

  /// No description provided for @sharedTripEndSubtitle.
  ///
  /// In es, this message translates to:
  /// **'¿Por qué no fuiste? Es opcional. Nos ayuda a mejorar los circuitos y a que cada lugar sepa qué pasó.'**
  String get sharedTripEndSubtitle;

  /// No description provided for @sharedTripEndTitle.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{Te quedó 1 parada sin visitar} other{Te quedaron {count} paradas sin visitar}}'**
  String sharedTripEndTitle(int count);

  /// No description provided for @sharedTripInProgress.
  ///
  /// In es, this message translates to:
  /// **'Viaje en curso · {checked}/{total} paradas confirmadas'**
  String sharedTripInProgress(int checked, int total);

  /// No description provided for @sharedTripNextDelay.
  ///
  /// In es, this message translates to:
  /// **'Siguiente · {delay}'**
  String sharedTripNextDelay(String delay);

  /// No description provided for @sharedTripNextStop.
  ///
  /// In es, this message translates to:
  /// **'Siguiente: {name} · {time}'**
  String sharedTripNextStop(String name, String time);

  /// No description provided for @sharedTripOnTime.
  ///
  /// In es, this message translates to:
  /// **'Vas a tiempo'**
  String get sharedTripOnTime;

  /// No description provided for @sharedTripSkippedReason.
  ///
  /// In es, this message translates to:
  /// **'Saltada · {reason}'**
  String sharedTripSkippedReason(String reason);

  /// No description provided for @sharedVerificationCode.
  ///
  /// In es, this message translates to:
  /// **'Código de verificación'**
  String get sharedVerificationCode;

  /// No description provided for @stopDetailAddedToCircuit.
  ///
  /// In es, this message translates to:
  /// **'Añadida a este circuito'**
  String get stopDetailAddedToCircuit;

  /// No description provided for @stopDetailAddToCircuit.
  ///
  /// In es, this message translates to:
  /// **'Añadir a un circuito'**
  String get stopDetailAddToCircuit;

  /// No description provided for @stopDetailBadgeAwarded.
  ///
  /// In es, this message translates to:
  /// **'Esta parada otorga una insignia de {category}'**
  String stopDetailBadgeAwarded(String category);

  /// No description provided for @stopDetailBadgeEarned.
  ///
  /// In es, this message translates to:
  /// **'Insignia de {category} obtenida'**
  String stopDetailBadgeEarned(String category);

  /// No description provided for @stopDetailCircuitCreated.
  ///
  /// In es, this message translates to:
  /// **'Circuito \"{title}\" creado'**
  String stopDetailCircuitCreated(String title);

  /// No description provided for @stopDetailConfirmed.
  ///
  /// In es, this message translates to:
  /// **'¡Parada confirmada!'**
  String get stopDetailConfirmed;

  /// No description provided for @stopDetailMoreOptions.
  ///
  /// In es, this message translates to:
  /// **'Más opciones'**
  String get stopDetailMoreOptions;

  /// No description provided for @stopDetailNewCircuit.
  ///
  /// In es, this message translates to:
  /// **'Crear circuito nuevo'**
  String get stopDetailNewCircuit;

  /// No description provided for @stopDetailNewCircuitHint.
  ///
  /// In es, this message translates to:
  /// **'Y añadir esta parada ahí'**
  String get stopDetailNewCircuitHint;

  /// No description provided for @stopDetailNoCircuits.
  ///
  /// In es, this message translates to:
  /// **'Todavía no tienes circuitos'**
  String get stopDetailNoCircuits;

  /// No description provided for @stopDetailOpenHours.
  ///
  /// In es, this message translates to:
  /// **'Abierto de {hours}'**
  String stopDetailOpenHours(String hours);

  /// No description provided for @stopDetailQrAim.
  ///
  /// In es, this message translates to:
  /// **'Apunta la cámara al código QR de la parada'**
  String get stopDetailQrAim;

  /// No description provided for @stopDetailQrDemoHint.
  ///
  /// In es, this message translates to:
  /// **'Escanéalo desde el detalle de esta parada para reclamar su insignia.'**
  String get stopDetailQrDemoHint;

  /// No description provided for @stopDetailQrDemoTitle.
  ///
  /// In es, this message translates to:
  /// **'Código QR (demo)'**
  String get stopDetailQrDemoTitle;

  /// No description provided for @stopDetailQrWrongStop.
  ///
  /// In es, this message translates to:
  /// **'Ese código no es de esta parada'**
  String get stopDetailQrWrongStop;

  /// No description provided for @stopDetailSavedIn.
  ///
  /// In es, this message translates to:
  /// **'Guardado en'**
  String get stopDetailSavedIn;

  /// No description provided for @stopDetailScanQr.
  ///
  /// In es, this message translates to:
  /// **'Escanear código QR'**
  String get stopDetailScanQr;

  /// No description provided for @stopDetailShowDemoQr.
  ///
  /// In es, this message translates to:
  /// **'Ver código de prueba'**
  String get stopDetailShowDemoQr;

  /// No description provided for @utilAdvisorAddTitle.
  ///
  /// In es, this message translates to:
  /// **'Agregar {stop}'**
  String utilAdvisorAddTitle(String stop);

  /// No description provided for @utilAdvisorExtraInterestMessage.
  ///
  /// In es, this message translates to:
  /// **'Te sobra {slack} en el día. Como te interesa {category}, agrega {stop}: {duration} de visita, {leg}.'**
  String utilAdvisorExtraInterestMessage(
    String slack,
    String category,
    String stop,
    String duration,
    String leg,
  );

  /// No description provided for @utilAdvisorExtraMessage.
  ///
  /// In es, this message translates to:
  /// **'Te sobra {slack} en el día. Agrega {stop}: {duration} de visita, {leg}.'**
  String utilAdvisorExtraMessage(
    String slack,
    String stop,
    String duration,
    String leg,
  );

  /// No description provided for @utilAdvisorFirstStopNote.
  ///
  /// In es, this message translates to:
  /// **'es la primera parada'**
  String get utilAdvisorFirstStopNote;

  /// No description provided for @utilAdvisorLunchMessage.
  ///
  /// In es, this message translates to:
  /// **'Tu día pasa por el mediodía y no tiene parada para comer. En {stop} llegarías a las {arrival} ({leg}).'**
  String utilAdvisorLunchMessage(String stop, String arrival, String leg);

  /// No description provided for @utilAdvisorLunchTitle.
  ///
  /// In es, this message translates to:
  /// **'Almorzar en {stop}'**
  String utilAdvisorLunchTitle(String stop);

  /// No description provided for @utilAdvisorRemoveClosedMessage.
  ///
  /// In es, this message translates to:
  /// **'{stop} cierra a las {closes} y no alcanzarías a visitarla: saldrías a las {departure}'**
  String utilAdvisorRemoveClosedMessage(
    String stop,
    String closes,
    String departure,
  );

  /// No description provided for @utilAdvisorRemoveEndsLateMessage.
  ///
  /// In es, this message translates to:
  /// **'Terminarías a las {lateEnd}, ya de noche. Si quitas {stop}, terminas a las {end}'**
  String utilAdvisorRemoveEndsLateMessage(
    String lateEnd,
    String stop,
    String end,
  );

  /// No description provided for @utilAdvisorRemoveTitle.
  ///
  /// In es, this message translates to:
  /// **'Quitar {stop}'**
  String utilAdvisorRemoveTitle(String stop);

  /// No description provided for @utilAdvisorRemoveTooLongMessage.
  ///
  /// In es, this message translates to:
  /// **'Tu día duraría {duration} y con ritmo {pace} conviene no pasar de {maxDuration}. Si quitas {stop}, terminas a las {end}'**
  String utilAdvisorRemoveTooLongMessage(
    String duration,
    String pace,
    String maxDuration,
    String stop,
    String end,
  );

  /// No description provided for @utilAdvisorReorderMessage.
  ///
  /// In es, this message translates to:
  /// **'Si cambias el orden de las paradas ahorras {saved} de traslado.'**
  String utilAdvisorReorderMessage(String saved);

  /// No description provided for @utilAdvisorReorderTitle.
  ///
  /// In es, this message translates to:
  /// **'Cambiar el orden'**
  String get utilAdvisorReorderTitle;

  /// No description provided for @utilAdvisorStartLaterMessage.
  ///
  /// In es, this message translates to:
  /// **'Llegarías a {stop} a las {arrival} y abre a las {opens} Si sales a las {startTime}, llegas con todo abierto.'**
  String utilAdvisorStartLaterMessage(
    String stop,
    String arrival,
    String opens,
    String startTime,
  );

  /// No description provided for @utilAdvisorStartLaterTitle.
  ///
  /// In es, this message translates to:
  /// **'Salir a las {startTime}'**
  String utilAdvisorStartLaterTitle(String startTime);

  /// No description provided for @utilAdvisorToStartNote.
  ///
  /// In es, this message translates to:
  /// **'para empezar'**
  String get utilAdvisorToStartNote;

  /// No description provided for @utilAdvisorVehicleMessage.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{Hay un tramo} other{Hay {count} tramos}} de más de {km} km a pie. En vehículo ahorras {saved} y los cortos los sigues caminando.'**
  String utilAdvisorVehicleMessage(int count, String km, String saved);

  /// No description provided for @utilAdvisorVehicleTitle.
  ///
  /// In es, this message translates to:
  /// **'Moverte en vehículo'**
  String get utilAdvisorVehicleTitle;

  /// No description provided for @utilMedalBronze.
  ///
  /// In es, this message translates to:
  /// **'Bronce'**
  String get utilMedalBronze;

  /// No description provided for @utilMedalGold.
  ///
  /// In es, this message translates to:
  /// **'Oro'**
  String get utilMedalGold;

  /// No description provided for @utilMedalNone.
  ///
  /// In es, this message translates to:
  /// **'Sin medalla'**
  String get utilMedalNone;

  /// No description provided for @utilMedalSilver.
  ///
  /// In es, this message translates to:
  /// **'Plata'**
  String get utilMedalSilver;

  /// No description provided for @utilPlannerArrivesAfterClosing.
  ///
  /// In es, this message translates to:
  /// **'Llegarías a {stop} a las {arrival}, cuando ya cerró (cierra a las {closes}).'**
  String utilPlannerArrivesAfterClosing(
    String stop,
    String arrival,
    String closes,
  );

  /// No description provided for @utilPlannerArrivesBeforeOpening.
  ///
  /// In es, this message translates to:
  /// **'Llegarías a {stop} a las {arrival} y abre a las {opens}'**
  String utilPlannerArrivesBeforeOpening(
    String stop,
    String arrival,
    String opens,
  );

  /// No description provided for @utilPlannerEndsLate.
  ///
  /// In es, this message translates to:
  /// **'Terminarías a las {end}, ya de noche.'**
  String utilPlannerEndsLate(String end);

  /// No description provided for @utilPlannerLeavesAfterClosing.
  ///
  /// In es, this message translates to:
  /// **'{stop} cierra a las {closes} y saldrías a las {departure}'**
  String utilPlannerLeavesAfterClosing(
    String stop,
    String closes,
    String departure,
  );

  /// No description provided for @utilPlannerLongWalk.
  ///
  /// In es, this message translates to:
  /// **'De {origin} a {destination} son {distance} a pie ({duration}). Si prefieres, haz ese tramo en taxi o en vehículo.'**
  String utilPlannerLongWalk(
    String origin,
    String destination,
    String distance,
    String duration,
  );

  /// No description provided for @utilPlannerMissedTime.
  ///
  /// In es, this message translates to:
  /// **'No alcanzas a llegar a {stop} a las {fixed}: llegarías a las {arrival}.'**
  String utilPlannerMissedTime(String stop, String fixed, String arrival);

  /// No description provided for @validatorEmailInvalid.
  ///
  /// In es, this message translates to:
  /// **'El correo no es válido'**
  String get validatorEmailInvalid;

  /// No description provided for @validatorEmailRequired.
  ///
  /// In es, this message translates to:
  /// **'Ingresa tu correo electrónico'**
  String get validatorEmailRequired;

  /// No description provided for @validatorNewPasswordRules.
  ///
  /// In es, this message translates to:
  /// **'Usa al menos 8 caracteres, una mayúscula y un número'**
  String get validatorNewPasswordRules;

  /// No description provided for @validatorPasswordMinLength.
  ///
  /// In es, this message translates to:
  /// **'Mínimo {count} caracteres'**
  String validatorPasswordMinLength(int count);

  /// No description provided for @validatorPasswordRequired.
  ///
  /// In es, this message translates to:
  /// **'Ingresa tu contraseña'**
  String get validatorPasswordRequired;

  /// No description provided for @validatorPhoneInvalid.
  ///
  /// In es, this message translates to:
  /// **'El teléfono no es válido'**
  String get validatorPhoneInvalid;

  /// No description provided for @validatorPhoneRequired.
  ///
  /// In es, this message translates to:
  /// **'Ingresa un teléfono de contacto'**
  String get validatorPhoneRequired;

  /// No description provided for @validatorUsernameInvalid.
  ///
  /// In es, this message translates to:
  /// **'De 3 a 20 letras, números, puntos o guiones bajos'**
  String get validatorUsernameInvalid;

  /// No description provided for @validatorUsernameRequired.
  ///
  /// In es, this message translates to:
  /// **'Ingresa un nombre de usuario'**
  String get validatorUsernameRequired;

  /// No description provided for @welcomeGuideSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Accede o postula tus servicios'**
  String get welcomeGuideSubtitle;

  /// No description provided for @welcomeSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Elige cómo quieres continuar.'**
  String get welcomeSubtitle;

  /// No description provided for @welcomeTitle.
  ///
  /// In es, this message translates to:
  /// **'Bienvenido'**
  String get welcomeTitle;

  /// No description provided for @welcomeTouristSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Explora y organiza tus viajes'**
  String get welcomeTouristSubtitle;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
