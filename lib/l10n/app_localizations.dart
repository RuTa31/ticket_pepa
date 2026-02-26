import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;
  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static const List<Locale> supportedLocales = [
    Locale('mn'),
    Locale('en'),
  ];

  String _t(String key) {
    return (_strings[locale.languageCode] ?? _strings['mn']!)[key] ?? key;
  }

  // ─── App ───────────────────────────────────────────────────
  String get appTitle => _t('appTitle');
  String get poweredBy => _t('poweredBy');

  // ─── Auth ──────────────────────────────────────────────────
  String get welcome => _t('welcome');
  String get loginSubtitle => _t('loginSubtitle');
  String get username => _t('username');
  String get enterUsername => _t('enterUsername');
  String get password => _t('password');
  String get enterPassword => _t('enterPassword');
  String get login => _t('login');
  String get invalidCredentials => _t('invalidCredentials');

  // ─── Navigation ────────────────────────────────────────────
  String get navHome => _t('navHome');
  String get navScanner => _t('navScanner');
  String get navSales => _t('navSales');
  String get navProfile => _t('navProfile');

  // ─── Home ──────────────────────────────────────────────────
  String get totalEvents => _t('totalEvents');
  String get totalTickets => _t('totalTickets');
  String get currentlyRunning => _t('currentlyRunning');
  String get upcomingEvent => _t('upcomingEvent');
  String get allEvents => _t('allEvents');
  String get allTickets => _t('allTickets');
  String get scanned => _t('scanned');
  String get unscanned => _t('unscanned');
  String get noScannedTickets => _t('noScannedTickets');
  String get noUnscannedTickets => _t('noUnscannedTickets');
  String get noTicketsFound => _t('noTicketsFound');
  String get allTicketsLoaded => _t('allTicketsLoaded');
  String get ticketIdLabel => _t('ticketIdLabel');
  String get ticketDetails => _t('ticketDetails');
  String get event => _t('event');
  String get ticketType => _t('ticketType');
  String get ticketId => _t('ticketId');
  String get bookingId => _t('bookingId');
  String get customerPhone => _t('customerPhone');
  String get paymentStatus => _t('paymentStatus');
  String get scanStatus => _t('scanStatus');
  String get failedToUpdateTicketStatus => _t('failedToUpdateTicketStatus');
  String get retry => _t('retry');
  String get noDataAvailable => _t('noDataAvailable');

  String ticketStatusUpdated(String status) {
    final mn = 'Билетийн төлөв өөрчлөгдлөө: $status';
    final en = 'Ticket status updated to $status';
    return locale.languageCode == 'en' ? en : mn;
  }

  String scanStatusLabel(String status) {
    if (locale.languageCode == 'en') return status.toUpperCase();
    switch (status.toLowerCase()) {
      case 'scanned':
        return 'УНШИГДСАН';
      case 'unscanned':
        return 'УНШИГДААГҮЙ';
      default:
        return status.toUpperCase();
    }
  }

  // ─── Scanner ───────────────────────────────────────────────
  String get switchCamera => _t('switchCamera');
  String get toggleTorch => _t('toggleTorch');
  String get verifying => _t('verifying');

  // ─── QR Result ─────────────────────────────────────────────
  String get result => _t('result');
  String get history => _t('history');
  String get ticketVerified => _t('ticketVerified');
  String get ticketAlreadyScanned => _t('ticketAlreadyScanned');
  String get codeScanned => _t('codeScanned');
  String get fakeOrUnauthorizedTicket => _t('fakeOrUnauthorizedTicket');
  String get qrCodeData => _t('qrCodeData');
  String get scanAgain => _t('scanAgain');
  String get backToHome => _t('backToHome');
  String get verified => _t('verified');
  String get alert => _t('alert');

  String bookingLabel(String id) {
    final mn = 'Захиалга: $id';
    final en = 'Booking: $id';
    return locale.languageCode == 'en' ? en : mn;
  }

  String scannedByLabel(String name) {
    final mn = 'Уншсан: $name';
    final en = 'Scanned by: $name';
    return locale.languageCode == 'en' ? en : mn;
  }

  String scannedAtLabel(String time) {
    final mn = 'Уншсан огноо: $time';
    final en = 'Scanned at: $time';
    return locale.languageCode == 'en' ? en : mn;
  }

  // ─── Permission ────────────────────────────────────────────
  String get cameraPermissionText => _t('cameraPermissionText');
  String get letsGetStarted => _t('letsGetStarted');

  // ─── Profile ───────────────────────────────────────────────
  String get settings => _t('settings');
  String get appPreferences => _t('appPreferences');
  String get logout => _t('logout');
  String get logoutTitle => _t('logoutTitle');
  String get logoutContent => _t('logoutContent');
  String get cancel => _t('cancel');
  String get guestUser => _t('guestUser');

  // ─── History ───────────────────────────────────────────────
  String get scanHistory => _t('scanHistory');
  String get clearAll => _t('clearAll');
  String get clearHistoryTitle => _t('clearHistoryTitle');
  String get clearHistoryContent => _t('clearHistoryContent');
  String get clear => _t('clear');
  String get noScansYet => _t('noScansYet');
  String get all => _t('all');
  String get today => _t('today');
  String get unknownEvent => _t('unknownEvent');
  String get ticketIdShort => _t('ticketIdShort');
  String get delete => _t('delete');
  String get copiedToClipboard => _t('copiedToClipboard');

  // ─── Settings ──────────────────────────────────────────────
  String get vibration => _t('vibration');
  String get vibrateOnScanSuccess => _t('vibrateOnScanSuccess');
  String get theme => _t('theme');
  String get chooseAppAppearance => _t('chooseAppAppearance');
  String get systemTheme => _t('systemTheme');
  String get lightTheme => _t('lightTheme');
  String get darkTheme => _t('darkTheme');
  String get restartApp => _t('restartApp');

  // ─── Sales ─────────────────────────────────────────────────
  String get sales => _t('sales');
  String get noEventsFound => _t('noEventsFound');
  String get noPlansAvailable => _t('noPlansAvailable');
  String get select => _t('select');

  // ─── Invoice ───────────────────────────────────────────────
  String get invoice => _t('invoice');
  String get plan => _t('plan');
  String get unitPrice => _t('unitPrice');
  String get ticketCount => _t('ticketCount');
  String get totalAmount => _t('totalAmount');
  String get contactInfo => _t('contactInfo');
  String get phoneNumber => _t('phoneNumber');
  String get email => _t('email');
  String get createInvoice => _t('createInvoice');
  String get waitingForPayment => _t('waitingForPayment');
  String get checkPayment => _t('checkPayment');
  String get checking => _t('checking');
  String get totalPayAmount => _t('totalPayAmount');
  String get paymentSuccess => _t('paymentSuccess');
  String get paymentFailed => _t('paymentFailed');
  String get retryPayment => _t('retryPayment');
  String get copied => _t('copied');
  String get back => _t('back');

  String orderNumberLabel(String id) {
    final mn = 'Захиалгын дугаар: $id';
    final en = 'Order number: $id';
    return locale.languageCode == 'en' ? en : mn;
  }

  String serialLabel(String serial) {
    return 'Serial: $serial';
  }

  // ─── String tables ─────────────────────────────────────────

  static const Map<String, Map<String, String>> _strings = {
    'mn': {
      // App
      'appTitle': 'Pepa Ticket',
      'poweredBy': 'KreativDev-ийн бүтээл',

      // Auth
      'welcome': 'Тавтай морилно уу',
      'loginSubtitle': 'QR уншигч ашиглахын тулд нэвтэрнэ үү',
      'username': 'Нэвтрэх нэр',
      'enterUsername': 'Нэвтрэх нэрийг оруулна уу',
      'password': 'Нууц үг',
      'enterPassword': 'Нууц үгийг оруулна уу',
      'login': 'Нэвтрэх',
      'invalidCredentials': 'Нэвтрэх нэр эсвэл нууц үг буруу',

      // Navigation
      'navHome': 'Нүүр',
      'navScanner': 'Уншигч',
      'navSales': 'Борлуулалт',
      'navProfile': 'Профайл',

      // Home
      'totalEvents': 'Нийт арга хэмжээ',
      'totalTickets': 'Нийт билет',
      'currentlyRunning': 'Явагдаж байна',
      'upcomingEvent': 'Удахгүй болох',
      'allEvents': 'Бүх арга хэмжээ',
      'allTickets': 'Бүгд',
      'scanned': 'Уншигдсан',
      'unscanned': 'Уншигдаагүй',
      'noScannedTickets': 'Уншигдсан билет байхгүй',
      'noUnscannedTickets': 'Уншигдаагүй билет байхгүй',
      'noTicketsFound': 'Билет олдсонгүй',
      'allTicketsLoaded': 'Бүх билет ачаалагдсан',
      'ticketIdLabel': 'Билетийн дугаар: ',
      'ticketDetails': 'Билетийн дэлгэрэнгүй',
      'event': 'Арга хэмжээ',
      'ticketType': 'Билетийн төрөл',
      'ticketId': 'Билетийн дугаар',
      'bookingId': 'Захиалгын дугаар',
      'customerPhone': 'Үйлчлүүлэгчийн утас',
      'paymentStatus': 'Төлбөрийн төлөв',
      'scanStatus': 'Уншилтын төлөв',
      'failedToUpdateTicketStatus': 'Билетийн төлөвийг өөрчлөхөд алдаа гарлаа',
      'retry': 'Дахин оролдох',
      'noDataAvailable': 'Мэдээлэл байхгүй байна',

      // Scanner
      'switchCamera': 'Камер солих',
      'toggleTorch': 'Гэрэл',
      'verifying': 'Шалгаж байна...',

      // QR Result
      'result': 'Үр дүн',
      'history': 'Түүх',
      'ticketVerified': 'БИЛЕТ БАТАЛГААЖЛАА',
      'ticketAlreadyScanned': 'БИЛЕТ АЛЬ ХЭДИЙН УНШИГДСАН',
      'codeScanned': 'Код уншигдлаа!',
      'fakeOrUnauthorizedTicket': 'Энэ хуурамч эсвэл зөвшөөрөлгүй билет!',
      'qrCodeData': 'QR кодын мэдээлэл',
      'scanAgain': 'Дахин унших',
      'backToHome': 'Нүүр хуудас руу буцах',
      'verified': 'Баталгаажсан',
      'alert': 'Анхааруулга',

      // Permission
      'cameraPermissionText':
          'QR код уншихын тулд камерын зөвшөөрлийг олгоно уу',
      'letsGetStarted': 'Эхлэх',

      // Profile
      'settings': 'Тохиргоо',
      'appPreferences': 'Апп-ын тохиргоо',
      'logout': 'Гарах',
      'logoutTitle': 'Гарах уу?',
      'logoutContent': 'Та дахин нэвтрэх шаардлагатай болно.',
      'cancel': 'Цуцлах',
      'guestUser': 'Зочин хэрэглэгч',

      // History
      'scanHistory': 'Уншилтын түүх',
      'clearAll': 'Бүгдийг устгах',
      'clearHistoryTitle': 'Түүхийг устгах уу?',
      'clearHistoryContent': 'Хадгалагдсан бүх уншилт устгагдана.',
      'clear': 'Устгах',
      'noScansYet': 'Уншилт байхгүй байна',
      'all': 'Бүгд',
      'today': 'Өнөөдөр',
      'unknownEvent': 'Тодорхойгүй арга хэмжээ',
      'ticketIdShort': 'Билетийн дугаар:',
      'delete': 'Устгах',
      'copiedToClipboard': 'Хуулагдлаа',

      // Settings
      'vibration': 'Чичиргээ',
      'vibrateOnScanSuccess': 'Амжилттай уншихад чичиргэх',
      'theme': 'Загвар',
      'chooseAppAppearance': 'Апп-ын харагдах байдал',
      'systemTheme': 'Систем',
      'lightTheme': 'Цайвар',
      'darkTheme': 'Харанхуй',
      'restartApp': 'Апп дахин эхлүүлэх',

      // Sales
      'sales': 'Борлуулалт',
      'noEventsFound': 'Арга хэмжээ олдсонгүй',
      'noPlansAvailable': 'Төлөвлөгөө байхгүй байна',
      'select': 'Сонгох',

      // Invoice
      'invoice': 'Нэхэмжлэл',
      'plan': 'Төлөвлөгөө',
      'unitPrice': 'Нэгж үнэ',
      'ticketCount': 'Билетийн тоо',
      'totalAmount': 'Нийт дүн',
      'contactInfo': 'Холбоо барих',
      'phoneNumber': 'Утасны дугаар',
      'email': 'И-мэйл',
      'createInvoice': 'Нэхэмжлэл үүсгэх',
      'waitingForPayment': 'Төлбөр хүлээгдэж байна...',
      'checkPayment': 'Төлбөр шалгах',
      'checking': 'Шалгаж байна...',
      'totalPayAmount': 'Нийт төлөх дүн',
      'paymentSuccess': 'Төлбөр амжилттай төлөгдлөө',
      'paymentFailed': 'Төлбөр амжилтгүй',
      'retryPayment': 'Дахин оролдох',
      'copied': 'Хуулагдлаа',
      'back': 'Буцах',
    },
    'en': {
      // App
      'appTitle': 'Pepa Ticket',
      'poweredBy': 'Powered by KreativDev',

      // Auth
      'welcome': 'Welcome',
      'loginSubtitle': 'Login to access the QR Scanner',
      'username': 'Username',
      'enterUsername': 'Enter your username',
      'password': 'Password',
      'enterPassword': 'Enter your password',
      'login': 'Login',
      'invalidCredentials': 'Invalid credentials',

      // Navigation
      'navHome': 'Home',
      'navScanner': 'Scanner',
      'navSales': 'Sales',
      'navProfile': 'Profile',

      // Home
      'totalEvents': 'Total Events',
      'totalTickets': 'Total Tickets',
      'currentlyRunning': 'Currently Running',
      'upcomingEvent': 'Upcoming Event',
      'allEvents': 'All Events',
      'allTickets': 'All Tickets',
      'scanned': 'Scanned',
      'unscanned': 'Unscanned',
      'noScannedTickets': 'No scanned tickets',
      'noUnscannedTickets': 'No unscanned tickets',
      'noTicketsFound': 'No tickets found',
      'allTicketsLoaded': 'All tickets loaded',
      'ticketIdLabel': 'Ticket ID: ',
      'ticketDetails': 'Ticket Details',
      'event': 'Event',
      'ticketType': 'Ticket Type',
      'ticketId': 'Ticket ID',
      'bookingId': 'Booking ID',
      'customerPhone': 'Customer Phone',
      'paymentStatus': 'Payment Status',
      'scanStatus': 'Scan Status',
      'failedToUpdateTicketStatus': 'Failed to update ticket status',
      'retry': 'Retry',
      'noDataAvailable': 'No data available',

      // Scanner
      'switchCamera': 'Switch Camera',
      'toggleTorch': 'Toggle Torch',
      'verifying': 'Verifying...',

      // QR Result
      'result': 'Result',
      'history': 'History',
      'ticketVerified': 'TICKET VERIFIED',
      'ticketAlreadyScanned': 'TICKET ALREADY SCANNED',
      'codeScanned': 'Code Scanned!',
      'fakeOrUnauthorizedTicket': 'This is a fake or unauthorized ticket!',
      'qrCodeData': 'QR Code Data',
      'scanAgain': 'Scan Again',
      'backToHome': 'Back to Home',
      'verified': 'Verified',
      'alert': 'Alert',

      // Permission
      'cameraPermissionText':
          'Please give access to your Camera so that we can scan and provide what is inside the code',
      'letsGetStarted': "Let's Get Started",

      // Profile
      'settings': 'Settings',
      'appPreferences': 'App preferences',
      'logout': 'Logout',
      'logoutTitle': 'Logout?',
      'logoutContent': 'You will need to login again.',
      'cancel': 'Cancel',
      'guestUser': 'Guest User',

      // History
      'scanHistory': 'Scan History',
      'clearAll': 'Clear All',
      'clearHistoryTitle': 'Clear history?',
      'clearHistoryContent': 'This will remove all saved scans.',
      'clear': 'Clear',
      'noScansYet': 'No scans yet',
      'all': 'All',
      'today': 'Today',
      'unknownEvent': 'Unknown Event',
      'ticketIdShort': 'Ticket ID:',
      'delete': 'Delete',
      'copiedToClipboard': 'Copied to clipboard',

      // Settings
      'vibration': 'Vibration',
      'vibrateOnScanSuccess': 'Vibrate on scan success',
      'theme': 'Theme',
      'chooseAppAppearance': 'Choose app appearance',
      'systemTheme': 'System',
      'lightTheme': 'Light',
      'darkTheme': 'Dark',
      'restartApp': 'Restart App',

      // Sales
      'sales': 'Sales',
      'noEventsFound': 'No events found',
      'noPlansAvailable': 'No plans available',
      'select': 'Select',

      // Invoice
      'invoice': 'Invoice',
      'plan': 'Plan',
      'unitPrice': 'Unit Price',
      'ticketCount': 'Ticket Count',
      'totalAmount': 'Total Amount',
      'contactInfo': 'Contact Info',
      'phoneNumber': 'Phone Number',
      'email': 'Email',
      'createInvoice': 'Create Invoice',
      'waitingForPayment': 'Waiting for payment...',
      'checkPayment': 'Check Payment',
      'checking': 'Checking...',
      'totalPayAmount': 'Total to Pay',
      'paymentSuccess': 'Payment successful',
      'paymentFailed': 'Payment failed',
      'retryPayment': 'Retry',
      'copied': 'Copied',
      'back': 'Back',
    },
  };
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      ['mn', 'en'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async =>
      AppLocalizations(locale);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
