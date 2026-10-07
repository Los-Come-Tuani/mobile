// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get assistantAiTag => 'AI';

  @override
  String get assistantAllGood => 'That looks good. Shall we save it?';

  @override
  String assistantAppliedAdd(String stop) {
    return 'You added $stop';
  }

  @override
  String assistantAppliedLunch(String stop) {
    return 'You have lunch at $stop';
  }

  @override
  String assistantAppliedRemove(String stop) {
    return 'You removed $stop';
  }

  @override
  String assistantAppliedReorder(String saved) {
    return 'You changed the order: you save $saved';
  }

  @override
  String assistantAppliedStartLater(String time) {
    return 'You leave at $time';
  }

  @override
  String get assistantAppliedVehicle => 'You\'re getting around by vehicle';

  @override
  String get assistantApply => 'Apply';

  @override
  String get assistantAskCity => 'Which city are you going to?';

  @override
  String get assistantAskInterests =>
      'What interests you most? You can pick several things.';

  @override
  String get assistantAskPace => 'How do you want your day?';

  @override
  String get assistantAskStartTime => 'What time do you want to start?';

  @override
  String assistantDefaultTitle(String city) {
    return 'My day in $city';
  }

  @override
  String get assistantDismiss => 'No, thanks';

  @override
  String assistantIntroCircuit(String title, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count stops',
      one: '1 stop',
    );
    return 'Hi! I\'m the K\'Plan assistant. I\'ll organize \"$title\" ($_temp0), counting the travel time and the schedule of each place.';
  }

  @override
  String get assistantIntroScratch =>
      'Hi! I\'m the K\'Plan assistant. I\'ll put together a day with real schedules, counting the travel time between each place.';

  @override
  String get assistantNoPreference => 'I don\'t mind';

  @override
  String assistantProposalCircuit(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count stops',
      one: '1 stop',
    );
    return 'Done. I worked out every transfer and the time you arrive at your $_temp0.';
  }

  @override
  String assistantProposalEmpty(String city) {
    return 'I couldn\'t find stops in $city that fit your day. Try a different pace or an earlier start.';
  }

  @override
  String assistantProposalScratch(String city, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count stops',
      one: '1 stop',
    );
    return 'Done. I built you a day in $city with $_temp0, in the order that needs the least travel.';
  }

  @override
  String assistantProposalTitle(String mode, String pace) {
    return 'Your day · $mode · $pace pace';
  }

  @override
  String get assistantSave => 'Save itinerary';

  @override
  String get assistantSaved => 'All set! We saved your itinerary';

  @override
  String assistantSuggestionsIntro(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'I have $count suggestions to improve it:',
      one: 'I have 1 suggestion to improve it:',
    );
    return '$_temp0';
  }

  @override
  String get assistantThinking => 'Calculating transfers and schedules…';

  @override
  String get assistantTitle => 'K\'Plan assistant';

  @override
  String get bookingAdults => 'Adults';

  @override
  String get bookingBadges => 'Badges';

  @override
  String get bookingBadgesSoon => 'Badges: coming soon';

  @override
  String bookingBudgetLine(String summary) {
    return 'Budget: $summary';
  }

  @override
  String get bookingChildren => 'Children';

  @override
  String bookingChildrenCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count children',
      one: '1 child',
    );
    return '$_temp0';
  }

  @override
  String get bookingCircuitNotFound => 'We couldn\'t find this circuit';

  @override
  String get bookingConfirmed => 'All set! Your circuit is booked';

  @override
  String get bookingConfirmedWithProposal =>
      'All set! Your circuit is booked and your proposal is now published for guides';

  @override
  String get bookingDaySchedule => 'Schedule for the day';

  @override
  String get bookingDetailsTitle => 'Booking details';

  @override
  String bookingDurationEnds(String duration, String time) {
    return '$duration · ends around $time';
  }

  @override
  String get bookingEstimatedDuration => 'Estimated duration';

  @override
  String get bookingGoBack => 'Go back';

  @override
  String get bookingGroup => 'Group';

  @override
  String get bookingGuideOrTranslator => 'Guide or translator';

  @override
  String get bookingGuideRowAdd => 'Add';

  @override
  String bookingGuideSummary(String need, int hours) {
    return '$need · ${hours}h';
  }

  @override
  String get bookingIncludes => 'Includes';

  @override
  String get bookingMeetingPoint => 'Meeting point';

  @override
  String get bookingNeedBilingualSubtitle =>
      'Explains the whole tour in your language.';

  @override
  String get bookingNeedBilingualTitle => 'Guide who speaks your language';

  @override
  String get bookingNeedGuideTranslatorSubtitle =>
      'A local guide and someone who translates for you on the spot.';

  @override
  String get bookingNeedGuideTranslatorTitle => 'Local guide + translator';

  @override
  String get bookingNeedLocalGuideSubtitle => 'Gives you the tour in Spanish.';

  @override
  String get bookingNeedTranslatorOnlySubtitle =>
      'You explore on your own with someone who translates for you.';

  @override
  String get bookingNeedTranslatorOnlyTitle => 'Translator only';

  @override
  String get bookingNoGuideOrTranslator => 'No guide or translator';

  @override
  String get bookingOwnCircuitNote =>
      'You built this one yourself, so there\'s no price per person: you only pay for the guide or translator you hire.';

  @override
  String get bookingProposalBudget => 'Budget you offer';

  @override
  String get bookingProposalBudgetHint =>
      'Each guide accepts it or suggests their own price when applying.';

  @override
  String get bookingProposalDuration => 'Service duration';

  @override
  String get bookingProposalFewerHours => 'Fewer hours';

  @override
  String get bookingProposalIntro =>
      'Guides will see your proposal and apply. You review their profiles and choose who to hire.';

  @override
  String bookingProposalItineraryLasts(String duration) {
    return 'Your itinerary lasts $duration.';
  }

  @override
  String get bookingProposalLodgingHint =>
      'More than one day of touring: if you provide lodging, the price goes down.';

  @override
  String get bookingProposalLodgingTitle =>
      'Will you provide lodging for the guide?';

  @override
  String bookingProposalMinHoursGuide(int hours) {
    return 'Minimum $hours hours with a guide.';
  }

  @override
  String bookingProposalMinHoursTranslator(int hours) {
    return 'Minimum $hours hours with a translator only.';
  }

  @override
  String get bookingProposalMoreHours => 'More hours';

  @override
  String get bookingProposalNote =>
      'When you book, we publish your proposal: guides apply and you choose who to hire.';

  @override
  String get bookingProposalTitle => 'Proposal for a guide or translator';

  @override
  String get bookingProposalTransport => 'Transport';

  @override
  String get bookingProposalVehicleWarning =>
      'This tour is done by vehicle: on foot, some stretches are very long and there isn\'t enough time in the day.';

  @override
  String get bookingProposalWhatYouNeed => 'What do you need?';

  @override
  String get bookingProposalYourLanguage => 'Your language';

  @override
  String get bookingRecommendations => 'Recommendations';

  @override
  String get bookingRemove => 'Remove';

  @override
  String bookingScheduleSummary(String start, String mode, String end) {
    return 'Leaving at $start · $mode · ends around $end';
  }

  @override
  String get bookingServiceFee => 'Service fee (20%)';

  @override
  String get bookingStartTime => 'Start time';

  @override
  String get bookingSubtotal => 'Subtotal';

  @override
  String get bookingTitle => 'Book';

  @override
  String get bookingTourInfoTitle => 'Tour information';

  @override
  String get bookingTourNotes => 'Tour notes';

  @override
  String get bookingTransportGuide => 'The guide provides it';

  @override
  String get bookingTransportOnFoot => 'On foot';

  @override
  String get bookingTransportTourist => 'I provide the transport';

  @override
  String get categoryAdventure => 'Adventure';

  @override
  String get categoryCity => 'City';

  @override
  String get categoryCulture => 'Culture';

  @override
  String get categoryFair => 'Fair';

  @override
  String get categoryFood => 'Food';

  @override
  String get categoryHistory => 'History';

  @override
  String get categoryNature => 'Nature';

  @override
  String get categoryTradition => 'Tradition';

  @override
  String get circuitDetailAllReviewsSoon => 'All reviews: coming soon';

  @override
  String circuitDetailBadgesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count badges',
      one: '1 badge',
    );
    return '$_temp0';
  }

  @override
  String get circuitDetailBook => 'Book circuit';

  @override
  String circuitDetailCommentsTitle(int count) {
    return 'Reviews ($count)';
  }

  @override
  String get circuitDetailDownloadSoon =>
      'Download for offline use: coming soon';

  @override
  String get circuitDetailDownloadTooltip => 'Download for offline use';

  @override
  String get circuitDetailLeavingAt => 'If you leave at…';

  @override
  String get circuitDetailOrderSaved =>
      'Order saved: the itinerary was recalculated';

  @override
  String circuitDetailPricePerAdult(String price) {
    return '$price per adult';
  }

  @override
  String get circuitDetailReorder => 'Reorder';

  @override
  String get circuitDetailSeeAll => 'See all';

  @override
  String get circuitDetailSeeTimes => 'See available times';

  @override
  String circuitDetailSkipWhy(String stop) {
    return 'Why are you skipping $stop?';
  }

  @override
  String get circuitDetailStartTrip => 'Start trip';

  @override
  String circuitDetailStopsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count stops',
      one: '1 stop',
    );
    return '$_temp0';
  }

  @override
  String circuitDetailStopsTitle(int count) {
    return 'Route stops ($count)';
  }

  @override
  String get circuitDetailTodayRoute => 'Your route today';

  @override
  String get circuitDetailTripEnded => 'Trip ended';

  @override
  String circuitDetailTripStarted(String stop) {
    return 'Trip started! Head to $stop';
  }

  @override
  String get commonAccept => 'OK';

  @override
  String get commonBack => 'Back';

  @override
  String get commonBackToHome => 'Back to home';

  @override
  String get commonBirthDate => 'Date of birth';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonChangePassword => 'Change password';

  @override
  String get commonChooseCountry => 'Choose your country';

  @override
  String get commonClose => 'Close';

  @override
  String get commonContinue => 'Continue';

  @override
  String get commonCoupons => 'Coupons';

  @override
  String get commonCreateAccount => 'Create account';

  @override
  String get commonCreativeCircuits => 'Creative circuits';

  @override
  String get commonDate => 'Date';

  @override
  String get commonDone => 'Done';

  @override
  String get commonEmail => 'Email';

  @override
  String get commonFullName => 'Full name';

  @override
  String get commonGuide => 'Guide';

  @override
  String get commonHome => 'Home';

  @override
  String get commonLocalGuide => 'Local guide';

  @override
  String get commonLogout => 'Log out';

  @override
  String get commonMyCircuits => 'My circuits';

  @override
  String get commonMyMedals => 'My medals';

  @override
  String get commonMyTrips => 'My trips';

  @override
  String get commonNationality => 'Nationality';

  @override
  String get commonNewPassword => 'New password';

  @override
  String get commonNewPasswordHelper =>
      'Use at least 8 characters, one uppercase letter and one number.';

  @override
  String get commonNext => 'Next';

  @override
  String get commonNotifications => 'Notifications';

  @override
  String get commonPassword => 'Password';

  @override
  String get commonPasswordsDontMatch => 'The passwords don\'t match';

  @override
  String get commonRepeatPassword => 'Repeat the password';

  @override
  String get commonResendCode => 'Resend code';

  @override
  String get commonRetry => 'Try again';

  @override
  String get commonSave => 'Save';

  @override
  String get commonSaved => 'Saved';

  @override
  String get commonSeeOnMap => 'See on the map';

  @override
  String get commonSettings => 'Settings';

  @override
  String get commonSomethingWentWrong => 'Something went wrong, try again';

  @override
  String get commonTotal => 'Total';

  @override
  String get commonTourist => 'Tourist';

  @override
  String get commonTranslator => 'Translator';

  @override
  String get commonViewProfile => 'View profile';

  @override
  String couponsBalanceLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'badges available to redeem',
      one: 'badge available to redeem',
    );
    return '$_temp0';
  }

  @override
  String get couponsRedeemButton => 'REDEEM';

  @override
  String get couponsRedeemConfirm => 'Redeem';

  @override
  String get couponsRedeemed => 'Coupon redeemed! Show it when you book.';

  @override
  String get couponsRedeemedLabel => 'Redeemed';

  @override
  String get couponsRedeemFailed => 'We couldn\'t redeem the coupon';

  @override
  String couponsRedeemMessage(int cost) {
    String _temp0 = intl.Intl.pluralLogic(
      cost,
      locale: localeName,
      other: '$cost badges will be deducted from your balance.',
      one: '1 badge will be deducted from your balance.',
    );
    return '$_temp0';
  }

  @override
  String couponsRedeemTitle(String title) {
    return 'Redeem \"$title\"?';
  }

  @override
  String get eventDetailFreeEntry => 'Free entry';

  @override
  String get forgotPasswordCodeMissing =>
      'Enter the 6-digit code we emailed you.';

  @override
  String get forgotPasswordCodeResent =>
      'If a minute has passed since the last one, we sent you another code.';

  @override
  String forgotPasswordCodeSentTo(String email) {
    return 'If $email has an account, we sent it a 6-digit code. It expires in 15 minutes.';
  }

  @override
  String get forgotPasswordCodeSubtitle =>
      'Enter your email and we\'ll send you a 6-digit code.';

  @override
  String get forgotPasswordCodeTitle => 'Enter the code';

  @override
  String get forgotPasswordDemoNote =>
      'Demo: emails aren\'t being sent yet; any 6-digit code works.';

  @override
  String get forgotPasswordSendCode => 'Send code';

  @override
  String get forgotPasswordTitle => 'Forgot your password?';

  @override
  String get forgotPasswordUpdated =>
      'Password updated. Log in with the new one.';

  @override
  String get forgotPasswordUseAnotherEmail => 'Use another email';

  @override
  String formatAdults(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count adults',
      one: '$count adult',
    );
    return '$_temp0';
  }

  @override
  String get formatAm => 'AM';

  @override
  String formatChildren(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count children',
      one: '$count child',
    );
    return '$_temp0';
  }

  @override
  String formatCompactDate(String weekday, String dayAndMonth) {
    return '$weekday, $dayAndMonth';
  }

  @override
  String formatDayAndMonth(int day, String month) {
    return '$month $day';
  }

  @override
  String formatDaysAgo(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days ago',
      one: '1 day ago',
    );
    return '$_temp0';
  }

  @override
  String formatHoursAgo(int hours) {
    return '$hours h ago';
  }

  @override
  String get formatLessThanOneMinute => 'less than 1 min';

  @override
  String formatMinutesAgo(int minutes) {
    return '$minutes min ago';
  }

  @override
  String get formatNoPeople => 'No people';

  @override
  String get formatNow => 'now';

  @override
  String formatPeople(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count people',
      one: '$count person',
    );
    return '$_temp0';
  }

  @override
  String get formatPm => 'PM';

  @override
  String formatShortDate(int day, String month, int year) {
    return '$month $day, $year';
  }

  @override
  String get formatToday => 'Today';

  @override
  String get formatTomorrow => 'Tomorrow';

  @override
  String formatWeekdayDate(String weekday, String dayAndMonth) {
    return '$weekday, $dayAndMonth';
  }

  @override
  String get formatYesterday => 'Yesterday';

  @override
  String groupSlotsAdultsLine(int count, String price) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count adults',
      one: '1 adult',
    );
    return '$_temp0 × $price';
  }

  @override
  String get groupSlotsCertifiedGuide => 'Certified guide';

  @override
  String groupSlotsChildrenLine(int count, String price) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count children',
      one: '1 child',
    );
    return '$_temp0 × $price';
  }

  @override
  String get groupSlotsConfirm => 'Confirm';

  @override
  String groupSlotsDuration(String duration) {
    return 'Duration: $duration';
  }

  @override
  String get groupSlotsEmpty =>
      'There are no times published for this circuit yet. Check back soon.';

  @override
  String groupSlotsEndsAround(String time) {
    return 'Ends around $time';
  }

  @override
  String groupSlotsEnrolled(String date, String time) {
    return 'All set! Your group is enrolled for $date at $time';
  }

  @override
  String groupSlotsEnrolledWithGroup(String people) {
    return 'Enrolled with your group · $people';
  }

  @override
  String groupSlotsEnrollMe(String people) {
    return 'Enroll · $people';
  }

  @override
  String get groupSlotsEnrollTitle => 'Enroll in this time slot';

  @override
  String get groupSlotsFull => 'Full';

  @override
  String groupSlotsGroupDoesNotFit(String people) {
    return 'Your group doesn\'t fit ($people)';
  }

  @override
  String groupSlotsGroupNote(int capacity) {
    return 'It\'s a group of up to $capacity people: you\'ll share the tour with people you don\'t know.';
  }

  @override
  String groupSlotsJoined(int joined, int capacity) {
    return '$joined of $capacity people enrolled';
  }

  @override
  String groupSlotsMeetingPoint(String place) {
    return 'Meeting point: $place';
  }

  @override
  String get groupSlotsNoSpots => 'No spots left';

  @override
  String get groupSlotsNoSpotsLeft =>
      'There aren\'t enough spots left in that time slot';

  @override
  String get groupSlotsNoTransport => 'No transport';

  @override
  String get groupSlotsPeople => 'People';

  @override
  String groupSlotsPrices(String adult, String child) {
    return '$adult per adult · $child per child';
  }

  @override
  String get groupSlotsPublishedHint =>
      'Each guide sets the time, the capacity and whether they provide transport.';

  @override
  String get groupSlotsPublishedTitle => 'Times published by guides';

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
    return '$date · $time · with $guide';
  }

  @override
  String groupSlotsSpotsLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count spots left',
      one: '1 spot left',
    );
    return '$_temp0';
  }

  @override
  String get groupSlotsTitle => 'Available times';

  @override
  String get groupSlotsTransportIncluded => 'Transport included';

  @override
  String get groupSlotsYourGroup => 'Your group';

  @override
  String get guideAccessAppBarSemantics => 'K’Plan, guides';

  @override
  String get guideAccessAppBarTitle => 'K’Plan  /  Guides';

  @override
  String get guideAccessAttachFile => 'Attach file';

  @override
  String get guideAccessBackToDocuments => 'Go back and review documents';

  @override
  String get guideAccessCityError => 'Choose the city where you work';

  @override
  String get guideAccessCityHint => 'Choose a city';

  @override
  String get guideAccessCityLabel => 'City';

  @override
  String get guideAccessCodeRejected =>
      'The code is invalid or has expired. Check it or request a new one.';

  @override
  String guideAccessCodeResent(String email) {
    return 'We sent a new code to $email. Use the most recent one.';
  }

  @override
  String guideAccessCodeSent(String email) {
    return 'We sent a 6-digit code to $email.';
  }

  @override
  String get guideAccessCodeTitle => 'Enter the verification code';

  @override
  String get guideAccessConfirmPasswordHint => 'Repeat your password';

  @override
  String get guideAccessConfirmPasswordLabel => 'Confirm your password';

  @override
  String get guideAccessConsentError =>
      'Authorize the review of your documents to send the request.';

  @override
  String get guideAccessConsentLabel =>
      'I authorize the K’Plan team to review my information and documents to evaluate this request.';

  @override
  String get guideAccessCountryCodeTooltip => 'Country code';

  @override
  String get guideAccessCountryCostaRica => 'Costa Rica';

  @override
  String get guideAccessCountryElSalvador => 'El Salvador';

  @override
  String get guideAccessCountryGuatemala => 'Guatemala';

  @override
  String get guideAccessCountryHonduras => 'Honduras';

  @override
  String get guideAccessCountryMexico => 'Mexico';

  @override
  String get guideAccessCountryNicaragua => 'Nicaragua';

  @override
  String get guideAccessCountryPanama => 'Panama';

  @override
  String get guideAccessCountrySpain => 'Spain';

  @override
  String get guideAccessCountryUnitedStatesOrCanada =>
      'United States or Canada';

  @override
  String get guideAccessCoverageError => 'Choose where you work';

  @override
  String get guideAccessCoverageLabel => 'Where you work';

  @override
  String get guideAccessCoverageLocalSubtitle =>
      'For example, a local guide certified there.';

  @override
  String get guideAccessCoverageLocalTitle => 'In one city';

  @override
  String get guideAccessCoverageNationalSubtitle =>
      'For example, an INTUR national guide.';

  @override
  String get guideAccessCoverageNationalTitle => 'Across the country';

  @override
  String guideAccessCoverageSummaryLocal(String city) {
    return 'Only in $city';
  }

  @override
  String get guideAccessCoverageSummaryNational => 'Anywhere in Nicaragua';

  @override
  String get guideAccessCreateAccountAndSend => 'Create account and send';

  @override
  String get guideAccessDocumentAccepted => 'Accepted';

  @override
  String get guideAccessDocumentAlreadyExpired =>
      'This document has expired: upload a valid one';

  @override
  String get guideAccessDocumentAttached => 'Attached · Pending review';

  @override
  String get guideAccessDocumentAttachFile => 'Attach the file';

  @override
  String get guideAccessDocumentCouldNotAccept => 'we couldn’t accept it';

  @override
  String get guideAccessDocumentExpiresBeforeIssued =>
      'The expiry date must be after the issue date';

  @override
  String get guideAccessDocumentExpiresOn => 'Expires on';

  @override
  String get guideAccessDocumentExpiresOnOptional => 'Expires on · Optional';

  @override
  String get guideAccessDocumentExpiresRequired => 'Choose the expiry date';

  @override
  String get guideAccessDocumentIssuedFuture =>
      'The issue date can’t be in the future';

  @override
  String get guideAccessDocumentIssuedOn => 'Issued on';

  @override
  String get guideAccessDocumentIssuedRequired => 'Choose the issue date';

  @override
  String get guideAccessDocumentKept =>
      'Carries over to the new application as is';

  @override
  String get guideAccessDocumentKeptAccepted =>
      'Accepted: carries over to the new application as is';

  @override
  String get guideAccessDocumentNoExpiry => 'Doesn’t expire';

  @override
  String get guideAccessDocumentNumber => 'Document number';

  @override
  String get guideAccessDocumentNumberHint => 'As it appears on the document';

  @override
  String get guideAccessDocumentNumberRequired => 'Enter the document number';

  @override
  String get guideAccessDocumentPending => 'Not reviewed yet';

  @override
  String guideAccessDocumentRejected(String reason) {
    return 'Rejected: $reason';
  }

  @override
  String guideAccessDocumentRejectedByUs(String reason) {
    return 'We rejected it: $reason';
  }

  @override
  String get guideAccessDocumentsCorrectSubtitle =>
      'Upload again what we rejected. What we accepted carries over as is.';

  @override
  String get guideAccessDocumentsCorrectTitle => 'Fix your documents';

  @override
  String get guideAccessDocumentsSubtitle =>
      'Attach a clear photo or a PDF of each one, with its dates. Only the review team will see them.';

  @override
  String get guideAccessDocumentsTitle => 'Your documents';

  @override
  String get guideAccessDocumentUploadAgain => 'upload it again';

  @override
  String get guideAccessDocumentValid => 'Valid';

  @override
  String get guideAccessEmailHelper =>
      'Use one that doesn’t already have a K’Plan account.';

  @override
  String get guideAccessEmailHint => 'you@email.com';

  @override
  String get guideAccessEmailLabel => 'Email';

  @override
  String get guideAccessExperienceHint =>
      'E.g. 3 years leading colonial history tours';

  @override
  String get guideAccessExperienceLabel => 'Introduce yourself to tourists';

  @override
  String get guideAccessExperienceRequired => 'Tell us about your experience';

  @override
  String get guideAccessExperienceSubtitle =>
      'Your certification defines how far you can guide travelers.';

  @override
  String get guideAccessFileFormats => 'PDF, JPG or PNG';

  @override
  String get guideAccessFilePickerFailed =>
      'We couldn\'t open your files. Try again.';

  @override
  String get guideAccessFileSizeProblem =>
      'The file is larger than 10 MB. Choose a smaller one.';

  @override
  String get guideAccessFileTypeProblem => 'Attach a PDF, JPG or PNG file.';

  @override
  String get guideAccessIdentitySubtitle =>
      'Use your details exactly as they appear on your ID card. Your guide or translator account is created with this email.';

  @override
  String get guideAccessIdentityTitle => 'Tell us who you are';

  @override
  String get guideAccessLanguagesError => 'Choose at least one language';

  @override
  String get guideAccessLanguagesLabel => 'Languages';

  @override
  String get guideAccessNameHint => 'First and last name';

  @override
  String get guideAccessNameRequired => 'Enter your full name';

  @override
  String get guideAccessPasswordHint => 'Enter your password';

  @override
  String get guideAccessPasswordSubtitle =>
      'Your email is verified. Create a password: when you send it, we upload your documents and your application goes into review.';

  @override
  String get guideAccessPasswordTitle => 'Protect your account';

  @override
  String get guideAccessPhoneLabel => 'Contact phone';

  @override
  String get guideAccessProfileMissing =>
      'Choose your date of birth and your nationality.';

  @override
  String guideAccessProgressLabel(int step, int total) {
    return 'APPLICATION  ·  STEP $step OF $total';
  }

  @override
  String guideAccessProgressSemantics(int step, int total) {
    return 'Application, step $step of $total';
  }

  @override
  String guideAccessRemoveFile(String name) {
    return 'Remove $name';
  }

  @override
  String get guideAccessReviewAccount => 'Your account';

  @override
  String get guideAccessReviewCorrectionTitle => 'Review your correction';

  @override
  String get guideAccessReviewDocuments =>
      'Documents you’re sending · To be verified';

  @override
  String get guideAccessReviewServices => 'What you offer';

  @override
  String get guideAccessReviewSubtitle =>
      'Confirm your information before sending it.';

  @override
  String get guideAccessReviewTitle => 'Review your application';

  @override
  String get guideAccessReviewVehicle => 'Drives tourists in their vehicle';

  @override
  String get guideAccessSendCorrection => 'Send correction';

  @override
  String get guideAccessSendRequest => 'Send request';

  @override
  String get guideAccessServiceGuide => 'Tour guide';

  @override
  String get guideAccessServicesCorrectingSubtitle =>
      'Check your details: you can change them before sending again.';

  @override
  String get guideAccessServicesError => 'Choose at least one';

  @override
  String get guideAccessServicesLabel => 'You offer';

  @override
  String get guideAccessServicesTitle => 'What you offer and where';

  @override
  String get guideAccessStartApply => 'Apply';

  @override
  String get guideAccessStartChecklistCredential =>
      'Your INTUR license if you are a guide, or your language certificate if you are a translator';

  @override
  String get guideAccessStartChecklistEmail =>
      'An email that doesn’t already have a K’Plan account';

  @override
  String get guideAccessStartChecklistId => 'Your ID card and police record';

  @override
  String get guideAccessStartChecklistLabel => 'Have these ready';

  @override
  String get guideAccessStartChecklistVehicle =>
      'Your driver’s license and insurance if you drive tourists in your vehicle';

  @override
  String get guideAccessStartContinueAsTourist => 'Continue as a tourist';

  @override
  String get guideAccessStartNotice =>
      'The K’Plan team will review your information before enabling your access.';

  @override
  String get guideAccessStartSignOutToApply => 'Sign out to apply';

  @override
  String get guideAccessStartSubtitle =>
      'Apply to offer your services as a tour guide or a translator.';

  @override
  String get guideAccessStartTitle => 'Share your territory';

  @override
  String get guideAccessStartTouristNotice =>
      'Your K’Plan account is a tourist account. To offer your services you need a separate account with a different email: sign out of this one and apply.';

  @override
  String get guideAccessStatusApprovedSubtitle =>
      'Your application was approved: tourists can now find you on K’Plan.';

  @override
  String get guideAccessStatusApprovedTitle => 'Guide access enabled';

  @override
  String get guideAccessStatusEnterAsGuide => 'Enter as a guide';

  @override
  String guideAccessStatusMissing(String items) {
    return 'Missing: $items.';
  }

  @override
  String get guideAccessStatusPendingNotice =>
      'Guide access will only be available if your application is approved. We’ll let you know by email.';

  @override
  String get guideAccessStatusPendingSubtitle =>
      'The K’Plan team is reviewing your documents.';

  @override
  String get guideAccessStatusPendingTitle => 'Request under review';

  @override
  String get guideAccessStatusReceivedSubtitle =>
      'We got your application. The team reviews them in the order they arrive.';

  @override
  String get guideAccessStatusRejectedSubtitle =>
      'Check what needs to be fixed.';

  @override
  String get guideAccessStatusRejectedTitle =>
      'We couldn’t approve your application';

  @override
  String get guideAccessStatusRenewalApprovedSubtitle =>
      'Your new documents are now valid.';

  @override
  String get guideAccessStatusRenewalApprovedTitle => 'Renewal approved';

  @override
  String get guideAccessStatusRenewalPendingTitle => 'Renewal under review';

  @override
  String get guideAccessStatusResubmit => 'Fix and send again';

  @override
  String guideAccessStatusTeamNote(String note) {
    return 'Note from the team: $note';
  }

  @override
  String get guideAccessVehicleSubtitle =>
      'We’ll ask for your driver’s license and your vehicle insurance.';

  @override
  String get guideAccessVehicleTitle => 'I drive tourists in my vehicle';

  @override
  String get guideAccessVerify => 'Verify';

  @override
  String get guideAppBalanceAvailable => 'Available to withdraw';

  @override
  String guideAppBalanceCommissionNote(int percent) {
    return 'K’Plan takes $percent% of each trip. The rest is yours.';
  }

  @override
  String get guideAppBalanceEmptyHint =>
      'When you finish a trip, your earnings show up here so you can withdraw them.';

  @override
  String get guideAppBalanceEmptyMessage =>
      'Here you\'ll see what you receive for each trip and your withdrawals.';

  @override
  String get guideAppBalanceEmptyTitle => 'No transactions yet';

  @override
  String get guideAppBalanceMovements => 'Transactions';

  @override
  String get guideAppBalanceNothingPending => 'Nothing pending for now';

  @override
  String guideAppBalancePayoutBreakdown(String price, String commission) {
    return 'Price $price · commission $commission';
  }

  @override
  String guideAppBalancePending(String amount, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count upcoming trips',
      one: '1 upcoming trip',
    );
    return '$amount pending from $_temp0';
  }

  @override
  String get guideAppBalanceTitle => 'Balance';

  @override
  String guideAppBalanceToAccount(String account) {
    return 'To $account';
  }

  @override
  String guideAppBalanceWithdrawalDeposited(String date) {
    return '$date · Deposited';
  }

  @override
  String guideAppBalanceWithdrawalProcessing(String date) {
    return '$date · Processing';
  }

  @override
  String guideAppBalanceWithdrawalSent(String amount) {
    return 'Withdrawal of $amount is on its way';
  }

  @override
  String guideAppBalanceWithdrawalTo(String account) {
    return 'Withdrawal to $account';
  }

  @override
  String get guideAppBarModeTag => 'Guides';

  @override
  String get guideAppChatsEmptyMessage =>
      'When a tourist hires you, you\'ll arrange the meeting point here.';

  @override
  String get guideAppChatsEmptyTitle => 'You have no conversations yet';

  @override
  String get guideAppChatsNoMessages => 'No messages';

  @override
  String guideAppChatsUnread(int count) {
    return '$count unread';
  }

  @override
  String guideAppChatsYou(String text) {
    return 'You: $text';
  }

  @override
  String get guideAppDocumentExpired => 'Expired';

  @override
  String get guideAppDocumentInReview => 'Under review';

  @override
  String get guideAppDocumentRejected => 'Rejected';

  @override
  String get guideAppDocumentValidNoExpiry => 'Valid · doesn\'t expire';

  @override
  String guideAppDocumentValidUntil(String date) {
    return 'Valid · expires on $date';
  }

  @override
  String get guideAppEarningsLabelDone => 'You received';

  @override
  String get guideAppEarningsLabelUpcoming => 'You receive';

  @override
  String get guideAppHomeATourist => 'A tourist';

  @override
  String get guideAppHomeAvailable => 'Available';

  @override
  String get guideAppHomeDefaultName => 'guide';

  @override
  String guideAppHomeEmptyLocal(String city) {
    return 'No new proposals in $city';
  }

  @override
  String get guideAppHomeEmptyMessage =>
      'When a tourist posts one, it will show up here.';

  @override
  String get guideAppHomeEmptyNational => 'No new proposals for now';

  @override
  String guideAppHomeGreeting(String name) {
    return 'Hi, $name';
  }

  @override
  String guideAppHomeHiredNotice(
    String who,
    String circuit,
    String day,
    String time,
  ) {
    return '$who hired you for $circuit! $day · $time';
  }

  @override
  String get guideAppHomeLoadingProposals => 'Loading proposals';

  @override
  String get guideAppHomeNextTrip => 'Next trip';

  @override
  String get guideAppHomePending => 'Pending';

  @override
  String get guideAppHomeProposals => 'Proposals for you';

  @override
  String guideAppHomeProposalsLocal(String city) {
    return 'You only see proposals from $city, where you\'re certified.';
  }

  @override
  String get guideAppHomeProposalsNational =>
      'From all over the country, in the languages you speak.';

  @override
  String guideAppHoursShort(int hours) {
    return '$hours h';
  }

  @override
  String get guideAppJobApplicationSent => 'Application sent';

  @override
  String get guideAppJobApplicationTitle => 'Your application';

  @override
  String get guideAppJobApplied => 'Applied';

  @override
  String guideAppJobAppliedNotice(String price, String name) {
    return 'You applied for $price. $name is deciding, and we\'ll let you know on Home.';
  }

  @override
  String get guideAppJobApply => 'Apply';

  @override
  String guideAppJobHiredNotice(String name) {
    return '$name hired you! It\'s now one of your trips.';
  }

  @override
  String get guideAppJobLodging => 'The tourist provides your lodging';

  @override
  String get guideAppJobMessageHint =>
      'Tell them why you\'re a great fit for this tour';

  @override
  String guideAppJobMessageLabel(String name) {
    return 'Message for $name';
  }

  @override
  String get guideAppJobNotFoundMessage => 'The tourist may have withdrawn it.';

  @override
  String get guideAppJobNotFoundTitle => 'We couldn\'t find this proposal';

  @override
  String get guideAppJobPostedBy => 'Posted by';

  @override
  String guideAppJobPriceHelper(String amount) {
    return 'The tourist is offering $amount. You can suggest a different price.';
  }

  @override
  String get guideAppJobPriceLabel => 'Your price (C\$)';

  @override
  String get guideAppJobPriceRequired => 'Enter your price in córdobas';

  @override
  String guideAppJobPublished(String timeAgo) {
    return 'Posted $timeAgo';
  }

  @override
  String get guideAppJobRowBudget => 'budget';

  @override
  String get guideAppJobRowYourPrice => 'your price';

  @override
  String guideAppJobTakenNotice(String name) {
    return '$name hired another guide. There are more proposals on Home.';
  }

  @override
  String get guideAppJobTitle => 'Proposal';

  @override
  String get guideAppJobTouristBudget => 'tourist\'s budget';

  @override
  String guideAppJobWouldReceive(String amount) {
    return 'You\'d receive $amount after the 20% fee.';
  }

  @override
  String guideAppJobYouReceiveAfterFee(String amount) {
    return 'You receive $amount after the 20% K’Plan fee';
  }

  @override
  String get guideAppMoneyAgreedPrice => 'Agreed price';

  @override
  String guideAppMoneyCommission(int percent) {
    return 'K’Plan commission ($percent%)';
  }

  @override
  String get guideAppNavChats => 'Chats';

  @override
  String guideAppNavChatsUnread(int count) {
    return 'Chats, $count unread';
  }

  @override
  String get guideAppNavProfile => 'Profile';

  @override
  String get guideAppNavTrips => 'Trips';

  @override
  String guideAppProfileAvailable(String amount) {
    return 'Available $amount';
  }

  @override
  String get guideAppProfileBalanceHint => 'What you receive from your trips';

  @override
  String get guideAppProfileDocuments => 'My documents';

  @override
  String get guideAppProfileEdit => 'Edit my profile';

  @override
  String get guideAppProfileEditHint =>
      'Photo, introduction, phone and languages';

  @override
  String get guideAppProfileNoReviews => 'No reviews from tourists yet';

  @override
  String get guideAppProfileRenewalInReview =>
      'You have a renewal under review.';

  @override
  String guideAppProfileSpeaks(String languages) {
    return 'Speaks $languages';
  }

  @override
  String guideAppProfileSuspended(String documents) {
    return 'Your profile is suspended: $documents expired. Renew it to show up for tourists again.';
  }

  @override
  String get guideAppProfileSuspendedADocument => 'a document';

  @override
  String get guideAppRateCommentHint =>
      'Tell us how it went: punctuality, attitude, whether they followed directions…';

  @override
  String get guideAppRateMissingStars => 'Choose how many stars to give';

  @override
  String guideAppRateQuestion(String name) {
    return 'How was it working with $name?';
  }

  @override
  String get guideAppRateSent =>
      'Rating sent. Thanks for helping other guides.';

  @override
  String guideAppRateStars(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count stars',
      one: '1 star',
    );
    return '$_temp0';
  }

  @override
  String get guideAppRateSubmit => 'Send rating';

  @override
  String guideAppRateTourist(String name) {
    return 'Rate $name';
  }

  @override
  String get guideAppRateVisibility =>
      'Only other guides will see your rating.';

  @override
  String guideAppRatingAverage(String average) {
    return '$average from guides';
  }

  @override
  String guideAppRatingAverageNamed(String average, String name) {
    return '$average from guides · $name';
  }

  @override
  String get guideAppRatingNone => 'No ratings from guides';

  @override
  String guideAppRatingNoneNamed(String name) {
    return 'No ratings from guides · $name';
  }

  @override
  String get guideAppSeeProposals => 'See proposals';

  @override
  String guideAppServiceHours(int hours) {
    return '$hours-hour service';
  }

  @override
  String get guideAppTheTourist => 'the tourist';

  @override
  String get guideAppTheTouristCapital => 'The tourist';

  @override
  String get guideAppThreadEmpty => 'Write to agree on the meeting point.';

  @override
  String get guideAppThreadHint => 'Write a message…';

  @override
  String get guideAppThreadSend => 'Send';

  @override
  String get guideAppThreadTitle => 'Conversation';

  @override
  String guideAppTouristNoRatingsMessage(String name) {
    return 'When a guide finishes a trip with $name, their feedback will show up here.';
  }

  @override
  String get guideAppTouristNoRatingsTitle => 'No ratings yet';

  @override
  String get guideAppTouristNotFoundMessage =>
      'They may have closed their account.';

  @override
  String get guideAppTouristNotFoundTitle => 'We couldn\'t find this tourist';

  @override
  String guideAppTouristRatedAlready(String name) {
    return 'You already rated $name. If you travel together again, you can rate them again.';
  }

  @override
  String guideAppTouristRatedFor(String circuit, String date) {
    return 'For $circuit on $date.';
  }

  @override
  String guideAppTouristRateLater(String name) {
    return 'You\'ll be able to rate $name once you finish a trip together.';
  }

  @override
  String guideAppTouristRatingCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count guides',
      one: '1 guide',
    );
    return 'from $_temp0';
  }

  @override
  String guideAppTouristRatingsNotice(String name) {
    return 'Only K’Plan guides can see these ratings. $name can\'t see them.';
  }

  @override
  String get guideAppTouristRatingsTitle => 'Ratings from guides';

  @override
  String guideAppTouristSince(String country, int year) {
    return '$country · On K’Plan since $year';
  }

  @override
  String guideAppTouristTileDetails(String country, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count trips',
      one: '1 trip',
    );
    return '$country · $_temp0 with K’Plan';
  }

  @override
  String guideAppTouristTrips(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count trips with K’Plan',
      one: '1 trip with K’Plan',
    );
    return '$_temp0';
  }

  @override
  String get guideAppTransportGuide => 'You provide the transportation';

  @override
  String get guideAppTransportOnFoot => 'Walking tour';

  @override
  String get guideAppTransportTourist =>
      'The tourist provides the transportation';

  @override
  String guideAppTripMeetingPending(String city) {
    return '$city · Meeting point to be agreed in the chat';
  }

  @override
  String guideAppTripMessageTourist(String name) {
    return 'Message $name';
  }

  @override
  String get guideAppTripNotFoundMessage =>
      'Check your trips in the Trips tab.';

  @override
  String get guideAppTripNotFoundTitle => 'We couldn\'t find this trip';

  @override
  String get guideAppTripPayment => 'Payment';

  @override
  String get guideAppTripPaymentNote =>
      'It moves to your balance when the trip ends.';

  @override
  String get guideAppTripRate => 'Rate';

  @override
  String guideAppTripRated(String name) {
    return 'You already rated $name for this trip.';
  }

  @override
  String get guideAppTripsEmptyDoneMessage =>
      'After each trip, you can rate the tourist to help other guides.';

  @override
  String get guideAppTripsEmptyDoneTitle =>
      'Trips you finish will show up here';

  @override
  String get guideAppTripsEmptyUpcomingMessage =>
      'Apply to a proposal from Home. When a tourist hires you, the trip shows up here.';

  @override
  String get guideAppTripsEmptyUpcomingTitle =>
      'You have no upcoming trips yet';

  @override
  String get guideAppTripsTabDone => 'Completed';

  @override
  String guideAppTripsTabDoneToRate(int count) {
    return 'Completed · $count to rate';
  }

  @override
  String get guideAppTripsTabUpcoming => 'Upcoming';

  @override
  String get guideAppTripStatusDone => 'Completed';

  @override
  String get guideAppTripStatusUpcoming => 'Upcoming';

  @override
  String get guideAppTripTitle => 'Trip';

  @override
  String get guideAppTripViewChat => 'View conversation';

  @override
  String get guideAppViewTrip => 'View trip';

  @override
  String get guideAppWithdraw => 'Withdraw';

  @override
  String get guideAppWithdrawAmountLabel => 'Amount (C\$)';

  @override
  String get guideAppWithdrawAmountRequired =>
      'Enter how much you want to withdraw';

  @override
  String guideAppWithdrawAvailable(String amount) {
    return 'Available: $amount';
  }

  @override
  String get guideAppWithdrawNotice =>
      'We\'ll let you know here when it reaches your account.';

  @override
  String guideAppWithdrawOverBalance(String amount) {
    return 'You only have $amount available';
  }

  @override
  String get guideAppWithdrawToAccount => 'To your account';

  @override
  String guideAppYouReceive(String amount) {
    return 'You receive $amount';
  }

  @override
  String guideAppYouReceived(String amount) {
    return 'You received $amount';
  }

  @override
  String guideChatAgreedPrice(String price) {
    return 'Agreed price: $price · Payment and booking: to be decided';
  }

  @override
  String get guideChatEmpty => 'Write to coordinate the meeting point.';

  @override
  String get guideChatMessageHint => 'Write a message…';

  @override
  String guideChatNamePair(String first, String second) {
    return '$first and $second';
  }

  @override
  String get guideProfileAcceptsBudget => 'Accepts your budget';

  @override
  String get guideProfileAppliedAsGuide =>
      'Applied to your proposal as a guide';

  @override
  String get guideProfileAppliedAsTranslator =>
      'Applied to your proposal as a translator';

  @override
  String get guideProfileChat => 'Chat';

  @override
  String get guideProfileHasVehicle => 'Has their own vehicle';

  @override
  String get guideProfileHiredAsGuide => 'Hired as a guide';

  @override
  String get guideProfileHiredAsTranslator => 'Hired as a translator';

  @override
  String guideProfileHireFor(String price) {
    return 'Hire for $price';
  }

  @override
  String guideProfileLessThanBudget(String amount) {
    return '$amount less than your budget';
  }

  @override
  String guideProfileMoreThanBudget(String amount) {
    return '$amount more than your budget';
  }

  @override
  String get guideProfileNoTransport => 'Doesn\'t provide transportation';

  @override
  String get guideProfileNoVehicle => 'No vehicle of their own';

  @override
  String get guideProfileOffersTransport =>
      'Provides transportation for your group';

  @override
  String get guideProfilePaymentPending => 'Payment and booking: to be decided';

  @override
  String guideProfileReviewsCount(int count) {
    return 'Reviews ($count)';
  }

  @override
  String get guideProfileTitle => 'Guide profile';

  @override
  String get guideRequestApplicationsTitle => 'Applications';

  @override
  String guideRequestApplicationsTitleCount(int count) {
    return 'Applications ($count)';
  }

  @override
  String get guideRequestApplicationUnavailable =>
      'This application is no longer available';

  @override
  String guideRequestBudget(String total) {
    return 'Budget: $total';
  }

  @override
  String guideRequestBudgetBoth(String total, String guide, String translator) {
    return 'Budget: $total (guide $guide + translator $translator)';
  }

  @override
  String get guideRequestCancelAction => 'Withdraw proposal';

  @override
  String get guideRequestCancelConfirm => 'Withdraw';

  @override
  String get guideRequestCancelMessage =>
      'Guides will no longer be able to apply. Your circuit is still booked.';

  @override
  String get guideRequestCancelTitle => 'Withdraw your proposal?';

  @override
  String get guideRequestGoToChat => 'Go to chat';

  @override
  String get guideRequestGuidesTitle => 'Guides';

  @override
  String guideRequestGuidesTitleCount(int count) {
    return 'Guides ($count)';
  }

  @override
  String get guideRequestHire => 'Hire';

  @override
  String get guideRequestHired => 'Hired';

  @override
  String guideRequestHireMessageGuide(String price) {
    return 'They\'ll be your guide for $price. All other applications for this role will be dismissed.';
  }

  @override
  String guideRequestHireMessageTranslator(String price) {
    return 'They\'ll be your translator for $price. All other applications for this role will be dismissed.';
  }

  @override
  String get guideRequestHireNextGuide => 'All set! Now choose your guide.';

  @override
  String get guideRequestHireNextTranslator =>
      'All set! Now choose your translator.';

  @override
  String guideRequestHireTitle(String name) {
    return 'Hire $name?';
  }

  @override
  String get guideRequestLodgingProvided => 'You provide lodging for the guide';

  @override
  String get guideRequestNoneSubtitle =>
      'Publish one when you book a circuit, from \"Guide or translator\".';

  @override
  String get guideRequestNoneTitle => 'You have no active proposal';

  @override
  String get guideRequestNoTransport => 'No transport';

  @override
  String get guideRequestOffersTransport => 'Provides transportation';

  @override
  String guideRequestPriceLess(String amount) {
    return '$amount less';
  }

  @override
  String guideRequestPriceMore(String amount) {
    return '$amount more';
  }

  @override
  String get guideRequestPriceYourBudget => 'Your budget';

  @override
  String get guideRequestRoleBoth => 'Guide and translator';

  @override
  String get guideRequestStatusCancelledSubtitle =>
      'Guides can no longer apply.';

  @override
  String get guideRequestStatusCancelledTitle => 'You withdrew this proposal';

  @override
  String get guideRequestStatusExpiredSubtitle =>
      'You didn\'t hire anyone in time. You can publish another one when you book.';

  @override
  String get guideRequestStatusExpiredTitle => 'Your proposal expired';

  @override
  String guideRequestStatusHiredSubtitle(String price) {
    return 'You agreed on $price for the service.';
  }

  @override
  String get guideRequestStatusHiredTitle =>
      'All set! You have someone to accompany you';

  @override
  String guideRequestStatusOpenSubtitle(String remaining) {
    return 'Guides can already see it. Expires in $remaining.';
  }

  @override
  String get guideRequestStatusOpenTitle =>
      'Published · receiving applications';

  @override
  String get guideRequestTeamTitle => 'Your team';

  @override
  String get guideRequestTitle => 'Your proposal';

  @override
  String get guideRequestTranslatorsTitle => 'Translators';

  @override
  String guideRequestTranslatorsTitleCount(int count) {
    return 'Translators ($count)';
  }

  @override
  String get guideRequestTransportGuide =>
      'The guide provides the transportation';

  @override
  String get guideRequestTransportOnFoot => 'Walking tour';

  @override
  String get guideRequestTransportTourist => 'You provide the transportation';

  @override
  String get guideRequestWaitingGuides =>
      'Waiting for applications from guides. We\'ll let you know here as soon as someone applies.';

  @override
  String get guideRequestWaitingTranslators =>
      'Waiting for applications from translators. We\'ll let you know here as soon as someone applies.';

  @override
  String guideRequestWaitingTranslatorsLanguage(String language) {
    return 'Waiting for applications from $language translators. We\'ll let you know here as soon as someone applies.';
  }

  @override
  String guideRequestYearsExperience(int years) {
    String _temp0 = intl.Intl.pluralLogic(
      years,
      locale: localeName,
      other: '$years years of experience',
      one: '1 year of experience',
    );
    return '$_temp0';
  }

  @override
  String get homeActiveTripAllVisited =>
      'You\'ve passed every stop · tap to end the trip';

  @override
  String homeActiveTripNext(String stop, String time, String delay) {
    return 'Next: $stop · $time · $delay';
  }

  @override
  String homeActiveTripTitle(String title) {
    return 'Trip in progress: $title';
  }

  @override
  String get homeActiveTripViewMap => 'View map';

  @override
  String homeCircuitBonus(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '+$count extra badges and a medal',
      one: '+1 extra badge and a medal',
    );
    return '$_temp0';
  }

  @override
  String homeCircuitStops(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count stops',
      one: '1 stop',
    );
    return '$_temp0';
  }

  @override
  String get homeDrawerBecomeGuide => 'Become a guide on K’Plan';

  @override
  String homeDrawerComingSoon(String label) {
    return '$label: coming soon';
  }

  @override
  String get homeDrawerGuideMode => 'Guide mode';

  @override
  String get homeDrawerTranslatorMode => 'Translator mode';

  @override
  String get homeEmptySearchMessage =>
      'Try another word or check how it\'s spelled.';

  @override
  String get homeEmptySearchTitle => 'We didn\'t find anything for that search';

  @override
  String get homeEmptyStopsMessage => 'Try another category or another search.';

  @override
  String get homeEmptyStopsTitle => 'No stops match';

  @override
  String get homeGuideRequestApplicationsHint =>
      'Tap to review them and choose';

  @override
  String homeGuideRequestApplicationsTitle(int count, String circuit) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count applications for $circuit',
      one: '1 application for $circuit',
    );
    return '$_temp0';
  }

  @override
  String get homeGuideRequestHiredHint => 'Tap to chat';

  @override
  String homeGuideRequestHiredTitle(String names, String circuit) {
    return 'You hired $names for $circuit';
  }

  @override
  String homeGuideRequestNamesJoin(String first, String second) {
    return '$first and $second';
  }

  @override
  String get homeGuideRequestPublishedHint => 'Waiting for guides to apply';

  @override
  String homeGuideRequestPublishedTitle(String circuit) {
    return 'Your proposal for $circuit is published';
  }

  @override
  String homeRewardsAvailable(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'You have $count badges to redeem',
      one: 'You have 1 badge to redeem',
    );
    return '$_temp0';
  }

  @override
  String get homeRewardsEarn => 'Earn badges by visiting stops';

  @override
  String get homeRewardsHint => 'Redeem them for coupons and discounts';

  @override
  String get homeSearchHint => 'What do you want to discover?';

  @override
  String get homeSectionCircuits => 'Full circuits';

  @override
  String get homeSectionEvents => 'Upcoming events';

  @override
  String get homeSectionStops => 'Featured stops';

  @override
  String homeStopCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count stops',
      one: '1 stop',
    );
    return '$_temp0';
  }

  @override
  String get homeTabCircuits => 'Circuits';

  @override
  String get homeTabEvents => 'Events';

  @override
  String get homeTabForYou => 'For you';

  @override
  String get homeTabStops => 'Stops';

  @override
  String get homeTitle => 'Discover your next plan';

  @override
  String get homeTopBarMenu => 'Menu';

  @override
  String get homeUpcomingTripHint => 'Tap to see the circuit details';

  @override
  String homeUpcomingTripTitle(String circuit, String date) {
    return 'Your trip to $circuit is on $date';
  }

  @override
  String get languageChoiceNote => 'You can change it later in Settings.';

  @override
  String get languageChoiceTitle => 'Choose your language';

  @override
  String get languageNameEnglish => 'English';

  @override
  String get languageNameFrench => 'French';

  @override
  String get languageNameGerman => 'German';

  @override
  String get languageNameItalian => 'Italian';

  @override
  String get languageNamePortuguese => 'Portuguese';

  @override
  String get languageNameSpanish => 'Spanish';

  @override
  String get languagePlaceNamesNote =>
      'Place names keep their original language.';

  @override
  String get languageSettingsHeading => 'App language';

  @override
  String get languageSettingsTitle => 'Language';

  @override
  String get loginApplyAsGuide => 'Apply';

  @override
  String get loginApplyAsGuideButton => 'Apply as a guide';

  @override
  String get loginContinueWithGoogle => 'Continue with Google';

  @override
  String get loginForgotPassword => 'Forgot your password?';

  @override
  String get loginGoogleProfileFailed =>
      'We couldn\'t complete your profile, try again';

  @override
  String get loginGoogleProfileSubtitle =>
      'Google doesn\'t share these details and we need them to create your account. You must be over 18.';

  @override
  String get loginGoogleProfileTitle => 'Complete your profile';

  @override
  String get loginGuideAccountHint =>
      'Log in with the account you used to apply as a guide or translator.';

  @override
  String get loginGuideNotYet => 'Not a guide on K’Plan yet?';

  @override
  String get loginMissingAccountGuide =>
      'Do you want to create a guide account?';

  @override
  String get loginMissingAccountTitle => 'We couldn\'t find this account';

  @override
  String get loginMissingAccountTourist =>
      'Do you want to create a tourist account?';

  @override
  String get loginNoAccount => 'Don\'t have an account?';

  @override
  String get loginSubmit => 'Log in';

  @override
  String get loginTwoFactorCodeHint => 'Code';

  @override
  String get loginTwoFactorCodeRequired =>
      'Enter the 6-digit code or a recovery code';

  @override
  String get loginTwoFactorSubtitle =>
      'Enter the 6-digit code from your authenticator app. If you lost your phone, use one of your recovery codes.';

  @override
  String get loginTwoFactorTitle => 'Verify it\'s you';

  @override
  String get loginTwoFactorVerify => 'Verify';

  @override
  String medalsBalanceAvailable(int count) {
    return '$count available';
  }

  @override
  String medalsBalanceEarned(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count badges',
      one: '1 badge',
    );
    return '$_temp0';
  }

  @override
  String medalsBalanceNote(String earned, String available) {
    return 'You earned $earned in total: that\'s what counts toward your medals, and it doesn\'t go down when you spend badges. You have $available to redeem in Coupons.';
  }

  @override
  String medalsBalanceNoteSpent(String earned, String available, int spent) {
    return 'You earned $earned in total: that\'s what counts toward your medals, and it doesn\'t go down when you spend badges. You have $available to redeem in Coupons ($spent already spent).';
  }

  @override
  String get medalsByCategory => 'Medals by category';

  @override
  String get medalsByCategoryNote =>
      'You earn badges by visiting stops that award them.';

  @override
  String get medalsCityEarned => 'Medal earned';

  @override
  String medalsCityLocked(String city) {
    return 'Complete a creative circuit in $city';
  }

  @override
  String get medalsCreativeCities => 'Creative city medals';

  @override
  String get medalsCreativeCitiesNote =>
      'You earn them by completing a creative circuit in that city.';

  @override
  String get medalsMaxLevel => 'Top level reached!';

  @override
  String medalsOverall(String tier) {
    return 'Overall medal: $tier';
  }

  @override
  String medalsTierMax(String tier) {
    return '$tier · top level';
  }

  @override
  String medalsTierToNext(String tier, int count) {
    return '$tier · $count more to level up';
  }

  @override
  String medalsToNextOverall(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'You need $count more badges for the next medal',
      one: 'You need 1 more badge for the next medal',
    );
    return '$_temp0';
  }

  @override
  String get modelDropReasonClosed => 'It was closed';

  @override
  String get modelDropReasonNoTime => 'Not enough time';

  @override
  String get modelDropReasonNotInterested => 'Not interested';

  @override
  String get modelDropReasonOther => 'Another reason';

  @override
  String get modelDropReasonTooExpensive => 'Too expensive';

  @override
  String get modelDropReasonTooFar => 'Too far or no transport';

  @override
  String get modelDropReasonWeather => 'Because of the weather';

  @override
  String modelGuideCoverageLocalCity(String city) {
    return 'Local guide · $city';
  }

  @override
  String get modelGuideCoverageNational => 'National guide';

  @override
  String modelLegFixed(String duration) {
    return '$duration transfer';
  }

  @override
  String get modelLegNoTransfer => 'No transfer';

  @override
  String get modelLegSamePlace => 'Steps away';

  @override
  String modelLegVehicle(String duration) {
    return '$duration by vehicle';
  }

  @override
  String modelLegWalking(String duration) {
    return '$duration on foot';
  }

  @override
  String modelNeedBilingualGuide(String language) {
    return 'Guide who speaks $language';
  }

  @override
  String get modelNeedBilingualGuideShort => 'Bilingual guide';

  @override
  String get modelNeedGuideAndTranslatorShort => 'Guide + translator';

  @override
  String modelNeedLocalGuideAndTranslator(String language) {
    return 'Local guide + translator ($language)';
  }

  @override
  String modelNeedTranslatorOnly(String language) {
    return 'Translator ($language)';
  }

  @override
  String get modelNeedTranslatorOnlyShort => 'Translator only';

  @override
  String get modelNeedYourLanguage => 'your language';

  @override
  String get modelPaceBalanced => 'Balanced';

  @override
  String get modelPaceIntense => 'Intense';

  @override
  String get modelPaceRelaxed => 'Relaxed';

  @override
  String get modelTravelModeVehicle => 'By vehicle';

  @override
  String get modelTravelModeWalking => 'On foot';

  @override
  String get myCircuitAiMessage =>
      'It asks how you want your day, works out the transfers and suggests what to remove or add.';

  @override
  String get myCircuitAiTitle => 'Organize with AI';

  @override
  String myCircuitArrivalAt(String stop) {
    return 'Arrival time at $stop';
  }

  @override
  String get myCircuitDepartureTime => 'Departure time';

  @override
  String get myCircuitEmpty => 'This circuit has no stops yet';

  @override
  String get myCircuitEmptyMessage =>
      'On any stop, tap \"Add to a circuit\" and choose this one.';

  @override
  String get myCircuitExploreStops => 'Explore stops';

  @override
  String get myCircuitFixedTime => 'Fixed time';

  @override
  String get myCircuitFixedTimeRemove => 'Remove';

  @override
  String myCircuitMissedFixedTime(String time) {
    return 'You wanted to arrive at $time';
  }

  @override
  String get myCircuitProposalNote =>
      'Since you built it yourself, you can post a proposal for guides or translators to apply.';

  @override
  String myCircuitRemoved(String stop) {
    return '$stop was removed from the circuit';
  }

  @override
  String get myCircuitRemoveTooltip => 'Remove from circuit';

  @override
  String myCircuitRemoveWhy(String stop) {
    return 'Why are you removing $stop?';
  }

  @override
  String get myCircuitReorderHint =>
      'Tap a stop\'s time to change it, and drag the stop to change the order.';

  @override
  String get myCircuitSchedule => 'Schedule circuit';

  @override
  String myCircuitSkipWhy(String stop) {
    return 'Why are you skipping $stop?';
  }

  @override
  String get myCircuitStartTrip => 'Start trip';

  @override
  String get myCircuitStopsHeader => 'Stops on the route';

  @override
  String get myCircuitTimeHint => 'Tap a stop\'s time to change it.';

  @override
  String get myCircuitTodayRoute => 'Your route today';

  @override
  String get myCircuitTransport => 'Transport';

  @override
  String get myCircuitTravelQuestion => 'How are you getting around?';

  @override
  String get myCircuitTripEnded => 'Trip ended';

  @override
  String myCircuitTripStarted(String stop) {
    return 'Trip started! Head to $stop';
  }

  @override
  String get myCircuitUndo => 'Undo';

  @override
  String get myCircuitYourDay => 'Your day';

  @override
  String get myTripsAiSubtitle => 'Plans your day with schedules and transfers';

  @override
  String get myTripsAiTitle => 'Plan your trip with AI';

  @override
  String get myTripsAllVisited => 'You\'ve passed every stop';

  @override
  String get myTripsAllVisitedHint => 'Open the details to end the trip';

  @override
  String myTripsArrival(String time, String delay) {
    return 'Arrival $time · $delay';
  }

  @override
  String myTripsBookingConfirmed(String people) {
    return 'Booking confirmed · $people';
  }

  @override
  String myTripsBookingDeparture(String time) {
    return 'Departure $time';
  }

  @override
  String get myTripsCircuitsEmpty =>
      'You haven\'t built any yet. The ones you create show up here, ready to edit, book or go out and explore.';

  @override
  String get myTripsContactGuide => 'Contact my guide';

  @override
  String get myTripsContactTranslator => 'Contact my translator';

  @override
  String get myTripsCreateSubtitle => 'You choose the stops and the order';

  @override
  String get myTripsCreateTitle => 'Create a circuit from scratch';

  @override
  String get myTripsDeleteConfirm => 'Delete';

  @override
  String get myTripsDeleteMessage =>
      'Its saved stops will be deleted. This can\'t be undone.';

  @override
  String myTripsDeleteTitle(String title) {
    return 'Delete \"$title\"?';
  }

  @override
  String myTripsDeleteTooltip(String title) {
    return 'Delete $title';
  }

  @override
  String get myTripsExploreCircuits => 'Explore circuits';

  @override
  String myTripsGuideRoleLanguages(String role, String languages) {
    return '$role · $languages';
  }

  @override
  String get myTripsHeadline => 'Your next destination is waiting';

  @override
  String myTripsNextStop(String stop) {
    return 'Next: $stop';
  }

  @override
  String get myTripsOngoingEmptyMessage =>
      'When you start a circuit, you\'ll see your next stop, your arrival time and the map here.';

  @override
  String get myTripsOngoingEmptyTitle => 'No tour in progress';

  @override
  String get myTripsOpenMap => 'Open the map';

  @override
  String get myTripsPlanAnother => 'Plan another trip';

  @override
  String myTripsProgress(int visited, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '$visited of $total stops',
      one: '$visited of 1 stop',
    );
    return '$_temp0';
  }

  @override
  String myTripsProgressSemantics(int visited, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: 'You\'ve completed $visited of $total stops',
      one: 'You\'ve completed $visited of 1 stop',
    );
    return '$_temp0';
  }

  @override
  String get myTripsSeeDetails => 'See route details';

  @override
  String get myTripsSeeUpcoming => 'See my upcoming trips';

  @override
  String get myTripsTabOngoing => 'In progress';

  @override
  String get myTripsTabUpcoming => 'Upcoming';

  @override
  String get myTripsUpcomingEmptyMessage =>
      'Pick a circuit and plan your first outing. You\'ll find the details of every trip here.';

  @override
  String get myTripsUpcomingEmptyOrAi => 'Or plan your trip with AI';

  @override
  String get myTripsUpcomingEmptyTitle => 'Your story is about to begin';

  @override
  String get myTripsYourCircuits => 'Your circuits';

  @override
  String myTripsYourCircuitsCount(int count) {
    return 'Your circuits · $count';
  }

  @override
  String get myTripsYourGuide => 'Your guide';

  @override
  String get myTripsYourTranslator => 'Your translator';

  @override
  String get profileCouponsSubtitle => 'Perks from local businesses';

  @override
  String get profileGuestName => 'Guest';

  @override
  String get profileMedalsSubtitle => 'Keepsakes from your tours';

  @override
  String get profileMyCoupons => 'My coupons';

  @override
  String get profileNotificationsSubtitle =>
      'Updates on your trips and bookings';

  @override
  String get profilePersonalData => 'Personal details';

  @override
  String get profilePersonalDataSubtitle => 'Name and contact details';

  @override
  String get profileSavedSubtitle =>
      'Circuits, places and events you bookmarked';

  @override
  String get profileSettingsSubtitle => 'Account, language and privacy';

  @override
  String get profileStatBadges => 'Badges';

  @override
  String get profileTitle => 'My profile';

  @override
  String registerAdultOnly(int age) {
    return 'You must be over $age to create an account';
  }

  @override
  String get registerBirthDatePartDay => 'Day';

  @override
  String get registerBirthDatePartMonth => 'Month';

  @override
  String get registerBirthDatePartYear => 'Year';

  @override
  String get registerBirthDateSubtitle =>
      'Your birth date stays private and helps us give you a better experience';

  @override
  String get registerBirthDateTitle => 'When were you born?';

  @override
  String registerCodeSent(String email) {
    return 'We sent a 6-digit code to $email';
  }

  @override
  String get registerCodeTitle => 'Enter the verification code';

  @override
  String get registerEmailSubtitle =>
      'We\'ll use it to verify your account. Your information will stay private.';

  @override
  String get registerEmailTitle => 'Enter your email';

  @override
  String get registerLoginAction => 'Log in';

  @override
  String registerLoginLink(String action) {
    return 'Already have an account? $action';
  }

  @override
  String get registerNameLabel => 'Name';

  @override
  String get registerNameRequired => 'Enter your name';

  @override
  String get registerNameTitle => 'What\'s your name?';

  @override
  String get registerNationalityLabel => 'Country';

  @override
  String get registerNationalitySubtitle =>
      'Your nationality is private: it helps us recommend things better and comply with the law.';

  @override
  String get registerNationalityTitle => 'Where are you from?';

  @override
  String get registerPasswordRuleLength => '8 characters';

  @override
  String registerPasswordRuleMet(String rule) {
    return '$rule: met';
  }

  @override
  String get registerPasswordRuleNumber => 'One number';

  @override
  String registerPasswordRulePending(String rule) {
    return '$rule: pending';
  }

  @override
  String get registerPasswordRuleUpper => 'One uppercase letter';

  @override
  String get registerPasswordSubtitle =>
      'Use at least 8 characters, one uppercase letter and one number.';

  @override
  String get registerPasswordTitle => 'Create a password';

  @override
  String get registerUsernameLabel => 'Username';

  @override
  String get registerUsernameSubtitle => 'This name will be visible in K’Plan';

  @override
  String get registerUsernameTitle => 'Create a username';

  @override
  String get repoAccessDemoExperienceLocal =>
      '6 years in Granada: colonial history and food.';

  @override
  String get repoAccessDemoExperienceNational =>
      '9 years of tours on colonial architecture and legends.';

  @override
  String get repoAccessSignInFirst => 'Log in first';

  @override
  String get repoApplicantDefaultMessage =>
      'I\'d love to join you on this tour!';

  @override
  String get repoApplicantHasVehicle => 'I have my own vehicle for your group.';

  @override
  String repoApplicantStrengths(String specialties) {
    return 'My specialty: $specialties.';
  }

  @override
  String repoApplicantTourInLanguage(String language) {
    return 'I can lead the whole tour in $language.';
  }

  @override
  String get repoApplicantTranslatorMessage =>
      'I translate in real time throughout the tour.';

  @override
  String repoApplicantTranslatorMessageToLanguage(String language) {
    return 'I translate in real time from Spanish to $language throughout the tour.';
  }

  @override
  String get repoAuthAccountCreated =>
      'Your account was created. Log in to continue.';

  @override
  String get repoAuthAccountNotFound => 'We couldn\'t find this account';

  @override
  String get repoAuthGoogleFailed =>
      'We couldn\'t sign you in with Google, try again';

  @override
  String get repoAuthInvalidCode => 'That code isn\'t valid';

  @override
  String get repoAuthMissingData =>
      'Some details are missing to create the account';

  @override
  String get repoAuthWrongCredentials => 'Incorrect email or password';

  @override
  String get repoChatReplyMeetingPoint =>
      'Perfect, see you at the meeting point. I\'ll be on time!';

  @override
  String get repoChatReplyQuestions =>
      'Any questions before the tour, message me here.';

  @override
  String get repoChatReplyWelcome =>
      'Hi! I\'d be happy to join you on the tour.';

  @override
  String get repoInboxReplyEarlier => 'Can we start 15 minutes earlier?';

  @override
  String get repoInboxReplyNoted => 'Great, thanks for letting us know.';

  @override
  String get repoInboxReplySeeYou => 'We\'ll be there. See you!';

  @override
  String get repoInboxReplyThanks => 'Perfect, thanks!';

  @override
  String get repoInlineLanguageEnglish => 'English';

  @override
  String get repoInlineLanguageFrench => 'French';

  @override
  String get repoInlineLanguageGerman => 'German';

  @override
  String get repoInlineLanguageItalian => 'Italian';

  @override
  String get repoInlineLanguagePortuguese => 'Portuguese';

  @override
  String get repoInlineLanguageSpanish => 'Spanish';

  @override
  String get repoNetworkCommunicationError =>
      'There was a problem communicating with the server';

  @override
  String get repoNetworkConnectionTimeout => 'Connection timed out';

  @override
  String get repoNetworkNoConnection => 'No internet connection';

  @override
  String repoNetworkRetryIn(String message, String wait) {
    return '$message You can try again in $wait.';
  }

  @override
  String get repoNetworkServerTimeout => 'The server took too long to respond';

  @override
  String get repoNetworkSessionExpired => 'Session expired, log in again';

  @override
  String get repoNetworkTooManyAttempts =>
      'Too many attempts. Wait a moment and try again';

  @override
  String repoNetworkWaitMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count minutes',
      one: '1 minute',
    );
    return '$_temp0';
  }

  @override
  String repoNetworkWaitSeconds(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count seconds',
      one: '1 second',
    );
    return '$_temp0';
  }

  @override
  String get repoNotificationBookingChanges => 'Changes to my bookings';

  @override
  String get repoNotificationNewsAndBenefits => 'Perks and news';

  @override
  String get repoNotificationSavedEvents => 'Saved events';

  @override
  String get repoNotificationTripReminders => 'Trip reminders';

  @override
  String repoSpecialtiesPair(String first, String second) {
    return '$first and $second';
  }

  @override
  String get repoTouristNotFound => 'We couldn\'t find this tourist';

  @override
  String get repoTouristRateOnce =>
      'You can only rate once, after the trip ends';

  @override
  String get repoTouristRateStars => 'Choose 1 to 5 stars';

  @override
  String get repoTouristRatingToday => 'today';

  @override
  String repoWorkAmountExceedsAvailable(String amount) {
    return 'You only have $amount available';
  }

  @override
  String get repoWorkAmountInvalid => 'Enter an amount greater than zero';

  @override
  String get repoWorkGuideFallbackName => 'K’Plan guide';

  @override
  String repoWorkHireGreeting(String circuitTitle) {
    return 'Hi! I hired you for $circuitTitle. Where should we meet?';
  }

  @override
  String get repoWorkJobNotFound => 'We couldn\'t find this proposal';

  @override
  String get repoWorkJobNotOpen => 'You can no longer apply to this proposal';

  @override
  String get repoWorkPriceInvalid => 'Enter a price greater than zero';

  @override
  String get repoWorkSampleBankAccount => 'Sample account •••• 0000';

  @override
  String get repoWorkWithdrawLoginRequired => 'Log in as a guide to withdraw';

  @override
  String get routeMapAllowLocationInSettings =>
      'Allow location in your settings to see yourself on the map';

  @override
  String get routeMapAlreadyHere => 'You\'re already here';

  @override
  String routeMapArrival(String time) {
    return 'Arrival $time';
  }

  @override
  String routeMapArrivalDelay(String time, String delay) {
    return 'Arrival $time · $delay';
  }

  @override
  String routeMapBadgeEarned(String category) {
    return '$category badge earned';
  }

  @override
  String routeMapBadgeToEarn(String category) {
    return 'Scan its QR code to earn the $category badge';
  }

  @override
  String get routeMapCenterPlace => 'Center on this place';

  @override
  String get routeMapDemoQrTooltip => 'View test code';

  @override
  String get routeMapDirections => 'Get directions';

  @override
  String routeMapDistanceFromYou(String distance, String label) {
    return '$distance from you · $label';
  }

  @override
  String get routeMapEndTrip => 'End trip';

  @override
  String get routeMapFreeEntry => 'Free entry';

  @override
  String routeMapGoToNext(String name) {
    return 'Go to next: $name';
  }

  @override
  String get routeMapLocationHint =>
      'Turn on your location to see yourself on the map';

  @override
  String get routeMapLocationOffInSettings =>
      'You turned location off in Settings';

  @override
  String get routeMapMyCircuit => 'My circuit';

  @override
  String get routeMapMyLocation => 'My location';

  @override
  String routeMapNextStop(String name) {
    return 'Next: $name';
  }

  @override
  String get routeMapNextStopOverline => 'Next stop';

  @override
  String get routeMapNoLocation =>
      'Without your location, the map can\'t show you';

  @override
  String get routeMapNoStops => 'This circuit has no stops yet';

  @override
  String routeMapOpenHours(String hours) {
    return 'Open $hours';
  }

  @override
  String get routeMapOverlineEvent => 'Event';

  @override
  String get routeMapOverlineStop => 'Stop';

  @override
  String get routeMapScanQr => 'Scan QR code';

  @override
  String get routeMapSearchingLocation => 'Finding your location…';

  @override
  String get routeMapSettingsAction => 'Settings';

  @override
  String get routeMapShowWholeRoute => 'See the whole route';

  @override
  String routeMapStopCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count stops',
      one: '1 stop',
    );
    return '$_temp0';
  }

  @override
  String routeMapStopOfTotal(int number, int total) {
    return 'Stop $number of $total';
  }

  @override
  String routeMapStopSkipped(int number) {
    return 'Stop $number · Skipped';
  }

  @override
  String routeMapStopVisited(int number) {
    return 'Stop $number · Visited';
  }

  @override
  String routeMapSuggestedVisit(String duration) {
    return 'Suggested visit: $duration';
  }

  @override
  String get routeMapTapStopHint => 'Tap a stop to see its info';

  @override
  String get routeMapTips => 'Tips';

  @override
  String get routeMapTripComplete => 'Route complete!';

  @override
  String get routeMapTripEnded => 'Trip ended';

  @override
  String get routeMapTurnOn => 'Turn on';

  @override
  String get routeMapTurnOnPhoneLocation =>
      'Turn on your phone\'s location to see yourself on the map';

  @override
  String routeMapVisitConfirmed(String name) {
    return 'Visit to $name confirmed!';
  }

  @override
  String routeMapWhySkip(String name) {
    return 'Why are you skipping $name?';
  }

  @override
  String get routeMapYouSkipped => 'You skipped it';

  @override
  String routeMapYouSkippedReason(String reason) {
    return 'You skipped it · $reason';
  }

  @override
  String get savedEmpty => 'You haven\'t saved anything yet';

  @override
  String get savedEmptyMessage =>
      'Tap the bookmark on a circuit, a stop or an event and you\'ll find it here.';

  @override
  String get savedHeadline => 'Your next discoveries';

  @override
  String get savedSectionPlaces => 'Places';

  @override
  String get settingsAccountAddName => 'Add your name';

  @override
  String get settingsAccountChangePasswordSubtitle =>
      'With your current password';

  @override
  String get settingsAccountLoginEmail => 'Login email';

  @override
  String get settingsAccountNameRequired => 'Enter your name';

  @override
  String get settingsAccountNameTitle => 'Your name';

  @override
  String get settingsAccountPersonalData => 'Personal details';

  @override
  String get settingsAccountTitle => 'Account';

  @override
  String get settingsAccountTwoFactorOff =>
      'Asks for an extra code when you log in';

  @override
  String get settingsAccountTwoFactorOn => 'On';

  @override
  String get settingsAccountTwoFactorTitle => 'Two-step verification';

  @override
  String get settingsBookingHelpBody =>
      'In My trips you can see the date, departure time, number of people and, if you hired one, your guide. Before canceling, check the service terms in the circuit details.';

  @override
  String get settingsBookingHelpHeading => 'Find your trip details';

  @override
  String get settingsBookingHelpTitle => 'Help with my booking';

  @override
  String get settingsBookingHelpViewTrips => 'View my trips';

  @override
  String get settingsChangePassword => 'Change password';

  @override
  String get settingsContactSupport => 'Contact support';

  @override
  String get settingsDataUsageBody =>
      'Your location is used to show you on the map during a tour. You can turn it off in Privacy. Your email and name are used to manage your account and bookings.';

  @override
  String get settingsDataUsageHeading => 'You decide what to share';

  @override
  String get settingsDataUsageRightsBody =>
      'You can ask for a copy of your data, or ask us to delete it, by writing to the support team.';

  @override
  String get settingsDataUsageRightsTitle => 'Your rights';

  @override
  String get settingsDataUsageTitle => 'How we use your data';

  @override
  String get settingsDataUsageWriteSupport => 'Message support';

  @override
  String get settingsHelpBookingSubtitle => 'Confirmations and cancellations';

  @override
  String get settingsHelpBookingTitle => 'My booking';

  @override
  String get settingsHelpContactSubtitle => 'Tell us what happened';

  @override
  String get settingsHelpHeading => 'How can we help you?';

  @override
  String get settingsHelpPrivacySubtitle => 'Controls for your data';

  @override
  String get settingsHelpPrivacyTitle => 'Privacy';

  @override
  String get settingsHelpTitle => 'Help and support';

  @override
  String get settingsHomeAccount => 'Account';

  @override
  String get settingsHomeAccountSubtitle => 'Details and access';

  @override
  String get settingsHomeHelp => 'Help and support';

  @override
  String get settingsHomeHelpSubtitle => 'Questions and contact';

  @override
  String get settingsHomeNotificationsOff => 'All alerts are off';

  @override
  String get settingsHomeNotificationsOn => 'Trips, bookings and events';

  @override
  String get settingsHomePrivacy => 'Privacy and security';

  @override
  String get settingsHomePrivacySubtitle => 'Location and personal data';

  @override
  String get settingsLogoutNote =>
      'Your saved items and trips stay linked to your account.';

  @override
  String get settingsLogoutTitle => 'Log out of your account?';

  @override
  String get settingsNotificationsHeading => 'Stay in the loop';

  @override
  String get settingsNotificationsPermissionNote =>
      'You can change the notification permission in your phone\'s settings.';

  @override
  String get settingsPasswordChangeCurrent => 'Current password';

  @override
  String get settingsPasswordChangeCurrentRequired =>
      'Enter your current password';

  @override
  String get settingsPasswordChangedDemoNote =>
      'Demo: there\'s no server to save it.';

  @override
  String get settingsPasswordChangedLogInAgain =>
      'Password updated. Log in again.';

  @override
  String get settingsPasswordChangedMessage =>
      'Your new password is ready to use.';

  @override
  String get settingsPasswordChangedTitle => 'Password updated';

  @override
  String get settingsPasswordChangeIntro =>
      'For your security, when you change it we\'ll log you out on all your devices and you\'ll need to log in again.';

  @override
  String get settingsPasswordChangeRepeat => 'Repeat the new password';

  @override
  String get settingsPasswordResetBackToAccount => 'Back to Account';

  @override
  String get settingsPrivacyAccountSecurity => 'Account security';

  @override
  String get settingsPrivacyDataUsageSubtitle => 'Information and controls';

  @override
  String get settingsPrivacyPersonalize => 'Personalize recommendations';

  @override
  String get settingsPrivacyPersonalizeDescription =>
      'Based on the circuits you save and take';

  @override
  String get settingsPrivacyShowBadges => 'Show badges on my profile';

  @override
  String get settingsPrivacyTitle => 'Privacy and security';

  @override
  String get settingsPrivacyUseLocation => 'Use location while exploring';

  @override
  String get settingsPrivacyUseLocationDescription =>
      'To see yourself on the map during a tour';

  @override
  String get settingsSupportBackToHelp => 'Back to Help';

  @override
  String get settingsSupportDemoNote =>
      'Demo: for now the message doesn\'t leave your phone.';

  @override
  String get settingsSupportMessage => 'Message';

  @override
  String get settingsSupportMessageHint =>
      'What happened, on which circuit, and when';

  @override
  String get settingsSupportMessageRequired => 'Write your message';

  @override
  String settingsSupportReplyTo(String email) {
    return 'We\'ll reply to $email.';
  }

  @override
  String get settingsSupportSend => 'Send message';

  @override
  String settingsSupportSentMessage(String email) {
    return 'The support team will reply to $email.';
  }

  @override
  String get settingsSupportSentPanelTitle => 'You\'re all set';

  @override
  String get settingsSupportSentTitle => 'Message sent';

  @override
  String get settingsSupportSubject => 'Subject';

  @override
  String get settingsSupportSubjectHint => 'E.g. Question about my booking';

  @override
  String get settingsSupportSubjectRequired => 'Tell us what it\'s about';

  @override
  String get sharedAddToCircuit => 'Add to a circuit';

  @override
  String get sharedAlwaysUseOption => 'Always use this option';

  @override
  String sharedBadgeEarnedSubtitle(String category) {
    return '$category · Keep it up!';
  }

  @override
  String get sharedBadgeEarnedTitle => '+1 badge';

  @override
  String sharedChangeArrivalTime(String time) {
    return 'Change arrival time, $time';
  }

  @override
  String get sharedCloseHint => 'close';

  @override
  String get sharedContinueTrip => 'Continue trip';

  @override
  String sharedCreativeBannerBody(String organizer) {
    return 'Created by $organizer. You do it in a group: sign up for a time slot published by a certified guide.';
  }

  @override
  String get sharedCreativeBannerBodyNoOrganizer =>
      'Created by a city hall. You do it in a group: sign up for a time slot published by a certified guide.';

  @override
  String get sharedCreativeBannerTitle => 'Official creative circuit';

  @override
  String get sharedCreativeCircuitBadge => 'Creative circuit';

  @override
  String sharedCreativeCityMedal(String city) {
    return '$city medal';
  }

  @override
  String sharedCreativeExtraBadges(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '+$count extra badges',
      one: '+1 extra badge',
    );
    return '$_temp0';
  }

  @override
  String get sharedDirectionsWithTitle => 'Get directions with...';

  @override
  String get sharedDragToReorder => 'Drag to reorder';

  @override
  String get sharedDropWhyWeAsk =>
      'It helps us improve circuits and lets each place know what happened.';

  @override
  String get sharedEndTrip => 'End trip';

  @override
  String get sharedFilterAll => 'All';

  @override
  String get sharedHidePassword => 'Hide password';

  @override
  String get sharedHiredCoordinate => 'Arrange the meeting point in the chat.';

  @override
  String get sharedHiredGoToChat => 'Go to chat';

  @override
  String sharedHiredName(String name) {
    return 'You hired $name!';
  }

  @override
  String get sharedHiredTeamReady => 'Your team is ready!';

  @override
  String sharedItineraryEnds(String time) {
    return 'Ends around $time';
  }

  @override
  String sharedItineraryFreeTime(String travel, String duration) {
    return '$travel · $duration free';
  }

  @override
  String sharedItineraryTravelTime(String duration) {
    return '$duration of travel';
  }

  @override
  String get sharedItineraryWarningsTitle => 'Keep in mind';

  @override
  String get sharedMapStart => 'Start';

  @override
  String get sharedNationalityNoResults => 'We couldn’t find that country';

  @override
  String get sharedNationalitySearchHint => 'Search for your country';

  @override
  String get sharedNationalityTitle => 'Your nationality';

  @override
  String get sharedNavProfile => 'Profile';

  @override
  String get sharedNewCircuitCreate => 'Create';

  @override
  String get sharedNewCircuitEmpty => 'Give your circuit a name';

  @override
  String get sharedNewCircuitHint => 'e.g. Weekend in the south';

  @override
  String get sharedNewCircuitTitle => 'New circuit';

  @override
  String sharedOpenAppFailed(String app) {
    return 'Couldn\'t open $app';
  }

  @override
  String get sharedOpenWithTitle => 'Open circuit with...';

  @override
  String get sharedRemoveFromSaved => 'Remove from saved';

  @override
  String get sharedReorderHint =>
      'Drag each stop into place. Itinerary times update automatically.';

  @override
  String get sharedReorderSave => 'Save order';

  @override
  String get sharedReorderTitle => 'Reorder stops';

  @override
  String sharedReviewsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '($count reviews)',
      one: '(1 review)',
    );
    return '$_temp0';
  }

  @override
  String get sharedSearchByVoice => 'Search by voice';

  @override
  String get sharedShowPassword => 'Show password';

  @override
  String get sharedSkip => 'Skip';

  @override
  String get sharedStopBadge => 'Badge';

  @override
  String get sharedTimePickerHour => 'Hour';

  @override
  String get sharedTimePickerMinutes => 'Minutes';

  @override
  String get sharedTripAllStopsDone =>
      'You\'ve been through all the stops. Tap End trip to finish.';

  @override
  String sharedTripArrivedAt(String time) {
    return 'You arrived at $time';
  }

  @override
  String sharedTripConflictBody(String title) {
    return 'You\'re on $title right now. You can only follow one circuit at a time, so end it to start this one.';
  }

  @override
  String get sharedTripConflictEndAndStart => 'End that one and start this one';

  @override
  String get sharedTripConflictGoToActive => 'Go to your current trip';

  @override
  String get sharedTripConflictTitle => 'You already have a trip in progress';

  @override
  String sharedTripDelayed(String duration) {
    return 'You\'re running $duration late';
  }

  @override
  String get sharedTripEndSubtitle =>
      'Why didn\'t you go? It\'s optional. It helps us improve circuits and lets each place know what happened.';

  @override
  String sharedTripEndTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'You left $count stops unvisited',
      one: 'You left 1 stop unvisited',
    );
    return '$_temp0';
  }

  @override
  String sharedTripInProgress(int checked, int total) {
    return 'Trip in progress · $checked/$total stops confirmed';
  }

  @override
  String sharedTripNextDelay(String delay) {
    return 'Next · $delay';
  }

  @override
  String sharedTripNextStop(String name, String time) {
    return 'Next: $name · $time';
  }

  @override
  String get sharedTripOnTime => 'You\'re on time';

  @override
  String sharedTripSkippedReason(String reason) {
    return 'Skipped · $reason';
  }

  @override
  String get sharedVerificationCode => 'Verification code';

  @override
  String get stopDetailAddedToCircuit => 'Added to this circuit';

  @override
  String get stopDetailAddToCircuit => 'Add to a circuit';

  @override
  String stopDetailBadgeAwarded(String category) {
    return 'This stop awards a $category badge';
  }

  @override
  String stopDetailBadgeEarned(String category) {
    return '$category badge earned';
  }

  @override
  String stopDetailCircuitCreated(String title) {
    return 'Circuit \"$title\" created';
  }

  @override
  String get stopDetailConfirmed => 'Stop confirmed!';

  @override
  String get stopDetailMoreOptions => 'More options';

  @override
  String get stopDetailNewCircuit => 'Create new circuit';

  @override
  String get stopDetailNewCircuitHint => 'And add this stop to it';

  @override
  String get stopDetailNoCircuits => 'You don\'t have any circuits yet';

  @override
  String stopDetailOpenHours(String hours) {
    return 'Open $hours';
  }

  @override
  String get stopDetailQrAim => 'Point the camera at the stop\'s QR code';

  @override
  String get stopDetailQrDemoHint =>
      'Scan it from this stop\'s details to claim its badge.';

  @override
  String get stopDetailQrDemoTitle => 'QR code (demo)';

  @override
  String get stopDetailQrWrongStop => 'That code isn\'t for this stop';

  @override
  String get stopDetailSavedIn => 'Saved in';

  @override
  String get stopDetailScanQr => 'Scan QR code';

  @override
  String get stopDetailShowDemoQr => 'View test code';

  @override
  String utilAdvisorAddTitle(String stop) {
    return 'Add $stop';
  }

  @override
  String utilAdvisorExtraInterestMessage(
    String slack,
    String category,
    String stop,
    String duration,
    String leg,
  ) {
    return 'You have $slack to spare today. Since you\'re interested in $category, add $stop: $duration to visit, $leg.';
  }

  @override
  String utilAdvisorExtraMessage(
    String slack,
    String stop,
    String duration,
    String leg,
  ) {
    return 'You have $slack to spare today. Add $stop: $duration to visit, $leg.';
  }

  @override
  String get utilAdvisorFirstStopNote => 'it\'s the first stop';

  @override
  String utilAdvisorLunchMessage(String stop, String arrival, String leg) {
    return 'Your day runs through midday and has no stop to eat. At $stop you\'d arrive at $arrival ($leg).';
  }

  @override
  String utilAdvisorLunchTitle(String stop) {
    return 'Have lunch at $stop';
  }

  @override
  String utilAdvisorRemoveClosedMessage(
    String stop,
    String closes,
    String departure,
  ) {
    return '$stop closes at $closes and you wouldn\'t have time to visit it: you\'d leave at $departure.';
  }

  @override
  String utilAdvisorRemoveEndsLateMessage(
    String lateEnd,
    String stop,
    String end,
  ) {
    return 'You\'d finish at $lateEnd, after dark. If you remove $stop, you finish at $end.';
  }

  @override
  String utilAdvisorRemoveTitle(String stop) {
    return 'Remove $stop';
  }

  @override
  String utilAdvisorRemoveTooLongMessage(
    String duration,
    String pace,
    String maxDuration,
    String stop,
    String end,
  ) {
    return 'Your day would last $duration, and with the pace set to $pace it\'s best not to go over $maxDuration. If you remove $stop, you finish at $end.';
  }

  @override
  String utilAdvisorReorderMessage(String saved) {
    return 'If you change the order of the stops, you save $saved of travel time.';
  }

  @override
  String get utilAdvisorReorderTitle => 'Change the order';

  @override
  String utilAdvisorStartLaterMessage(
    String stop,
    String arrival,
    String opens,
    String startTime,
  ) {
    return 'You\'d get to $stop at $arrival, but it opens at $opens. If you leave at $startTime, everything will be open when you arrive.';
  }

  @override
  String utilAdvisorStartLaterTitle(String startTime) {
    return 'Leave at $startTime';
  }

  @override
  String get utilAdvisorToStartNote => 'to start with';

  @override
  String utilAdvisorVehicleMessage(int count, String km, String saved) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'There are $count stretches',
      one: 'There\'s one stretch',
    );
    return '$_temp0 of more than $km km on foot. By vehicle you save $saved, and you keep walking the short ones.';
  }

  @override
  String get utilAdvisorVehicleTitle => 'Get around by vehicle';

  @override
  String get utilMedalBronze => 'Bronze';

  @override
  String get utilMedalGold => 'Gold';

  @override
  String get utilMedalNone => 'No medal';

  @override
  String get utilMedalSilver => 'Silver';

  @override
  String utilPlannerArrivesAfterClosing(
    String stop,
    String arrival,
    String closes,
  ) {
    return 'You\'d get to $stop at $arrival, after it has closed (it closes at $closes).';
  }

  @override
  String utilPlannerArrivesBeforeOpening(
    String stop,
    String arrival,
    String opens,
  ) {
    return 'You\'d get to $stop at $arrival, but it opens at $opens.';
  }

  @override
  String utilPlannerEndsLate(String end) {
    return 'You\'d finish at $end, after dark.';
  }

  @override
  String utilPlannerLeavesAfterClosing(
    String stop,
    String closes,
    String departure,
  ) {
    return '$stop closes at $closes and you\'d leave at $departure.';
  }

  @override
  String utilPlannerLongWalk(
    String origin,
    String destination,
    String distance,
    String duration,
  ) {
    return 'From $origin to $destination it\'s $distance on foot ($duration). If you prefer, take a taxi or a vehicle for that stretch.';
  }

  @override
  String utilPlannerMissedTime(String stop, String fixed, String arrival) {
    return 'You won\'t make it to $stop by $fixed: you\'d arrive at $arrival.';
  }

  @override
  String get validatorEmailInvalid => 'That email is not valid';

  @override
  String get validatorEmailRequired => 'Enter your email';

  @override
  String get validatorNewPasswordRules =>
      'Use at least 8 characters, one uppercase letter and one number';

  @override
  String validatorPasswordMinLength(int count) {
    return 'At least $count characters';
  }

  @override
  String get validatorPasswordRequired => 'Enter your password';

  @override
  String get validatorPhoneInvalid => 'That phone number is not valid';

  @override
  String get validatorPhoneRequired => 'Enter a contact phone number';

  @override
  String get validatorUsernameInvalid =>
      '3 to 20 letters, numbers, dots or underscores';

  @override
  String get validatorUsernameRequired => 'Enter a username';

  @override
  String get welcomeGuideSubtitle => 'Log in or apply to offer your services';

  @override
  String get welcomeSubtitle => 'Choose how you want to continue.';

  @override
  String get welcomeTitle => 'Welcome';

  @override
  String get welcomeTouristSubtitle => 'Explore and plan your trips';
}
