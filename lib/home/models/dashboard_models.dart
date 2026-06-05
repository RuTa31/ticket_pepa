// ─── Dashboard response: GET /api/v1/scanner/dashboard ───────────────────────

class DashboardSummary {
  final int assignedEvents;
  final int duplicateScansByMe;
  final int scanLogsByMe;
  final int scannedTicketsByMe;

  DashboardSummary({
    required this.assignedEvents,
    required this.duplicateScansByMe,
    required this.scanLogsByMe,
    required this.scannedTicketsByMe,
  });

  factory DashboardSummary.fromJson(Map<String, dynamic> json) {
    return DashboardSummary(
      assignedEvents: (json['assigned_events'] as num?)?.toInt() ?? 0,
      duplicateScansByMe: (json['duplicate_scans_by_me'] as num?)?.toInt() ?? 0,
      scanLogsByMe: (json['scan_logs_by_me'] as num?)?.toInt() ?? 0,
      scannedTicketsByMe: (json['scanned_tickets_by_me'] as num?)?.toInt() ?? 0,
    );
  }
}

class DashboardPlan {
  final int id;
  final String name;
  final int scanLogsByMe;
  final int scannedTicketsByMe;

  DashboardPlan({
    required this.id,
    required this.name,
    required this.scanLogsByMe,
    required this.scannedTicketsByMe,
  });

  factory DashboardPlan.fromJson(Map<String, dynamic> json) {
    return DashboardPlan(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name']?.toString() ?? '',
      scanLogsByMe: (json['scan_logs_by_me'] as num?)?.toInt() ?? 0,
      scannedTicketsByMe: (json['scanned_tickets_by_me'] as num?)?.toInt() ?? 0,
    );
  }
}

class DashboardEvent {
  final int id;
  final String name;
  final int duplicateScansByMe;
  final int scanLogsByMe;
  final int scannedTicketsByMe;
  final List<DashboardPlan> plans;

  DashboardEvent({
    required this.id,
    required this.name,
    required this.duplicateScansByMe,
    required this.scanLogsByMe,
    required this.scannedTicketsByMe,
    required this.plans,
  });

  factory DashboardEvent.fromJson(Map<String, dynamic> json) {
    return DashboardEvent(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name']?.toString() ?? '',
      duplicateScansByMe: (json['duplicate_scans_by_me'] as num?)?.toInt() ?? 0,
      scanLogsByMe: (json['scan_logs_by_me'] as num?)?.toInt() ?? 0,
      scannedTicketsByMe: (json['scanned_tickets_by_me'] as num?)?.toInt() ?? 0,
      plans: json['plans'] is List
          ? (json['plans'] as List)
                .map((e) => DashboardPlan.fromJson(e as Map<String, dynamic>))
                .toList()
          : [],
    );
  }
}

class DashboardStaff {
  final int id;
  final String name;
  final String username;

  DashboardStaff({required this.id, required this.name, required this.username});

  factory DashboardStaff.fromJson(Map<String, dynamic> json) {
    return DashboardStaff(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
    );
  }
}

class DashboardData {
  final List<DashboardEvent> events;
  final DashboardStaff staff;
  final DashboardSummary summary;

  DashboardData({
    required this.events,
    required this.staff,
    required this.summary,
  });

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    return DashboardData(
      events: json['events'] is List
          ? (json['events'] as List)
                .map((e) => DashboardEvent.fromJson(e as Map<String, dynamic>))
                .toList()
          : [],
      staff: json['staff'] != null
          ? DashboardStaff.fromJson(json['staff'] as Map<String, dynamic>)
          : DashboardStaff(id: 0, name: '', username: ''),
      summary: json['summary'] != null
          ? DashboardSummary.fromJson(json['summary'] as Map<String, dynamic>)
          : DashboardSummary(
              assignedEvents: 0,
              duplicateScansByMe: 0,
              scanLogsByMe: 0,
              scannedTicketsByMe: 0,
            ),
    );
  }
}

// ─── Event detail: GET /api/v1/scanner/events/{id} ────────────────────────────

class EventDetailPlan {
  final int id;
  final String name;
  final double basePrice;
  final double price;
  final String currency;
  final bool isActive;
  final bool isContinuous;
  final int quantitySold;
  final int quantityTotal;
  final int scannedTickets;
  final int ticketsTotal;

  EventDetailPlan({
    required this.id,
    required this.name,
    required this.basePrice,
    required this.price,
    required this.currency,
    required this.isActive,
    required this.isContinuous,
    required this.quantitySold,
    required this.quantityTotal,
    required this.scannedTickets,
    required this.ticketsTotal,
  });

  factory EventDetailPlan.fromJson(Map<String, dynamic> json) {
    return EventDetailPlan(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name']?.toString() ?? '',
      basePrice: (json['base_price'] as num?)?.toDouble() ?? 0.0,
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency']?.toString() ?? 'MNT',
      isActive: json['is_active'] == 1 || json['is_active'] == true,
      isContinuous: json['is_continuous'] == true,
      quantitySold: (json['quantity_sold'] as num?)?.toInt() ?? 0,
      quantityTotal: (json['quantity_total'] as num?)?.toInt() ?? 0,
      scannedTickets: (json['scanned_tickets'] as num?)?.toInt() ?? 0,
      ticketsTotal: (json['tickets_total'] as num?)?.toInt() ?? 0,
    );
  }
}

class EventDetail {
  final int id;
  final String name;
  final String slug;
  final String? picture;
  final String? venue;
  final int eventDate;
  final int endDate;
  final List<EventDetailPlan> plans;
  final int scanLogs;
  final int scannedTickets;
  final int ticketsTotal;

  EventDetail({
    required this.id,
    required this.name,
    required this.slug,
    this.picture,
    this.venue,
    required this.eventDate,
    required this.endDate,
    required this.plans,
    required this.scanLogs,
    required this.scannedTickets,
    required this.ticketsTotal,
  });

  DateTime get eventDateTime =>
      DateTime.fromMillisecondsSinceEpoch(eventDate * 1000);
  DateTime get endDateTime =>
      DateTime.fromMillisecondsSinceEpoch(endDate * 1000);

  factory EventDetail.fromJson(Map<String, dynamic> json) {
    return EventDetail(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      picture: json['picture']?.toString(),
      venue: json['venue']?.toString(),
      eventDate: (json['event_date'] as num?)?.toInt() ?? 0,
      endDate: (json['end_date'] as num?)?.toInt() ?? 0,
      plans: json['plans'] is List
          ? (json['plans'] as List)
                .map(
                  (e) => EventDetailPlan.fromJson(e as Map<String, dynamic>),
                )
                .toList()
          : [],
      scanLogs: (json['scan_logs'] as num?)?.toInt() ?? 0,
      scannedTickets: (json['scanned_tickets'] as num?)?.toInt() ?? 0,
      ticketsTotal: (json['tickets_total'] as num?)?.toInt() ?? 0,
    );
  }
}

// ─── Scan response: POST /api/v1/scanner/tickets/scan ─────────────────────────

class ScanCustomFormField {
  final int fieldId;
  final String label;
  final String type;
  final String value;

  ScanCustomFormField({
    required this.fieldId,
    required this.label,
    required this.type,
    required this.value,
  });

  factory ScanCustomFormField.fromJson(Map<String, dynamic> json) {
    return ScanCustomFormField(
      fieldId: (json['field_id'] as num?)?.toInt() ?? 0,
      label: json['label']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      value: json['value']?.toString() ?? '',
    );
  }
}

class ScanCustomForm {
  final int formId;
  final String name;
  final List<ScanCustomFormField> fields;

  ScanCustomForm({
    required this.formId,
    required this.name,
    required this.fields,
  });

  factory ScanCustomForm.fromJson(Map<String, dynamic> json) {
    return ScanCustomForm(
      formId: (json['form_id'] as num?)?.toInt() ?? 0,
      name: json['name']?.toString() ?? '',
      fields: json['fields'] is List
          ? (json['fields'] as List)
                .map(
                  (e) =>
                      ScanCustomFormField.fromJson(e as Map<String, dynamic>),
                )
                .toList()
          : [],
    );
  }
}

class ScanResultStaff {
  final int id;
  final String name;
  final String username;

  ScanResultStaff({required this.id, required this.name, required this.username});

  factory ScanResultStaff.fromJson(Map<String, dynamic> json) {
    return ScanResultStaff(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
    );
  }
}

class ScanResultInfo {
  final int acceptedCount;
  final int? firstScannedAt;
  final ScanResultStaff? firstStaff;
  final int? lastScannedAt;
  final ScanResultStaff? lastStaff;
  final int scanCount;
  final bool scanned;

  ScanResultInfo({
    required this.acceptedCount,
    this.firstScannedAt,
    this.firstStaff,
    this.lastScannedAt,
    this.lastStaff,
    required this.scanCount,
    required this.scanned,
  });

  factory ScanResultInfo.fromJson(Map<String, dynamic> json) {
    return ScanResultInfo(
      acceptedCount: (json['accepted_count'] as num?)?.toInt() ?? 0,
      firstScannedAt: (json['first_scanned_at'] as num?)?.toInt(),
      firstStaff: json['first_staff'] != null
          ? ScanResultStaff.fromJson(
              json['first_staff'] as Map<String, dynamic>,
            )
          : null,
      lastScannedAt: (json['last_scanned_at'] as num?)?.toInt(),
      lastStaff: json['last_staff'] != null
          ? ScanResultStaff.fromJson(
              json['last_staff'] as Map<String, dynamic>,
            )
          : null,
      scanCount: (json['scan_count'] as num?)?.toInt() ?? 0,
      scanned: json['scanned'] == true,
    );
  }
}

class ScanTicketInfo {
  final String code;
  final String event;
  final int eventId;
  final String plan;
  final int planId;
  final String? email;
  final String ticketStatus;

  ScanTicketInfo({
    required this.code,
    required this.event,
    required this.eventId,
    required this.plan,
    required this.planId,
    this.email,
    required this.ticketStatus,
  });

  factory ScanTicketInfo.fromJson(Map<String, dynamic> json) {
    return ScanTicketInfo(
      code: json['code']?.toString() ?? '',
      event: json['event']?.toString() ?? '',
      eventId: (json['event_id'] as num?)?.toInt() ?? 0,
      plan: json['plan']?.toString() ?? '',
      planId: (json['plan_id'] as num?)?.toInt() ?? 0,
      email: json['email']?.toString(),
      ticketStatus: json['status']?.toString() ?? '',
    );
  }
}

class ScanTicketResult {
  final String status;
  final String message;
  final bool accepted;
  final ScanCustomForm? customForm;
  final ScanResultInfo? scan;
  final ScanTicketInfo? ticket;

  ScanTicketResult({
    required this.status,
    required this.message,
    required this.accepted,
    this.customForm,
    this.scan,
    this.ticket,
  });

  bool get isAccepted => status == 'accepted';
  bool get isDuplicate => status == 'duplicate';
  bool get isInvalid => status == 'invalid';
  bool get isWrongEvent => status == 'wrong_event';

  factory ScanTicketResult.fromJson(Map<String, dynamic> json) {
    return ScanTicketResult(
      status: json['status']?.toString() ?? 'invalid',
      message: json['message']?.toString() ?? '',
      accepted: json['accepted'] == true,
      customForm: json['custom_form'] != null
          ? ScanCustomForm.fromJson(
              json['custom_form'] as Map<String, dynamic>,
            )
          : null,
      scan: json['scan'] != null
          ? ScanResultInfo.fromJson(json['scan'] as Map<String, dynamic>)
          : null,
      ticket: json['ticket'] != null
          ? ScanTicketInfo.fromJson(json['ticket'] as Map<String, dynamic>)
          : null,
    );
  }
}
