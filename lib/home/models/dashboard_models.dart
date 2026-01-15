class EventData {
  final String id;
  final String slug;
  final String title;
  final String thumbnail;
  final String date;
  final String? time;
  final String dateType;
  final String duration;
  final String organizer;
  final String eventType;
  final String? address;
  final String startPrice;
  final String wishlist;
  final List<EventDate>? dates;

  EventData({
    required this.id,
    required this.slug,
    required this.title,
    required this.thumbnail,
    required this.date,
    this.time,
    required this.dateType,
    required this.duration,
    required this.organizer,
    required this.eventType,
    this.address,
    required this.startPrice,
    required this.wishlist,
    this.dates,
  });

  factory EventData.fromJson(Map<String, dynamic> json) {
    return EventData(
      id: json['id']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      thumbnail: json['thumbnail']?.toString() ?? '',
      date: json['date']?.toString() ?? '',
      time: json['time']?.toString(),
      dateType: json['date_type']?.toString() ?? '',
      duration: json['duration']?.toString() ?? '',
      organizer: json['organizer']?.toString() ?? '',
      eventType: json['event_type']?.toString() ?? '',
      address: json['address']?.toString(),
      startPrice: json['start_price']?.toString() ?? '',
      wishlist: json['wishlist']?.toString() ?? '',
      dates: json['dates'] != null
          ? (json['dates'] as List)
                .map((e) => EventDate.fromJson(e as Map<String, dynamic>))
                .toList()
          : null,
    );
  }
}

class EventDate {
  final int id;
  final String eventId;
  final String startDate;
  final String startTime;
  final String endDate;
  final String endTime;
  final String duration;

  EventDate({
    required this.id,
    required this.eventId,
    required this.startDate,
    required this.startTime,
    required this.endDate,
    required this.endTime,
    required this.duration,
  });

  factory EventDate.fromJson(Map<String, dynamic> json) {
    return EventDate(
      id: (json['id'] as num?)?.toInt() ?? 0,
      eventId: json['event_id']?.toString() ?? '',
      startDate: json['start_date']?.toString() ?? '',
      startTime: json['start_time']?.toString() ?? '',
      endDate: json['end_date']?.toString() ?? '',
      endTime: json['end_time']?.toString() ?? '',
      duration: json['duration']?.toString() ?? '',
    );
  }
}

class TicketData {
  final String bookingId;
  final String eventId;
  final String eventName;
  final String ticketName;
  final String ticketId;
  final String customerPhone;
  final String paymentStatus;
  final String scanStatus;

  TicketData({
    required this.bookingId,
    required this.eventId,
    required this.eventName,
    required this.ticketName,
    required this.ticketId,
    required this.customerPhone,
    required this.paymentStatus,
    required this.scanStatus,
  });

  factory TicketData.fromJson(Map<String, dynamic> json) {
    return TicketData(
      bookingId: json['booking_id']?.toString() ?? '',
      eventId: json['event_id']?.toString() ?? '',
      eventName: json['event_name']?.toString() ?? '',
      ticketName: json['ticket_name']?.toString() ?? '',
      ticketId: json['ticket_id']?.toString() ?? '',
      customerPhone: json['customer_phone']?.toString() ?? '',
      paymentStatus: json['payment_status']?.toString() ?? '',
      scanStatus: json['scan_status']?.toString() ?? '',
    );
  }

  bool get isScanned => scanStatus.toLowerCase() == 'scanned';
}

class DashboardData {
  final List<EventData> events;
  final int totalAttendeesTickets;
  final int totalScannedTickets;
  final int totalUnscannedTickets;
  final List<TicketData> scannedTickets;
  final List<TicketData> unscannedTickets;
  final List<TicketData> allTickets;

  DashboardData({
    required this.events,
    required this.totalAttendeesTickets,
    required this.totalScannedTickets,
    required this.totalUnscannedTickets,
    required this.scannedTickets,
    required this.unscannedTickets,
    required this.allTickets,
  });

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    final eventsData = json['events'] as Map<String, dynamic>?;

    return DashboardData(
      events: eventsData != null && eventsData['events'] is List
          ? (eventsData['events'] as List)
                .map((e) => EventData.fromJson(e as Map<String, dynamic>))
                .toList()
          : [],
      totalAttendeesTickets:
          (eventsData?['total_attendees_tickets'] as num?)?.toInt() ?? 0,
      totalScannedTickets:
          (eventsData?['total_scanned_tickets'] as num?)?.toInt() ?? 0,
      totalUnscannedTickets:
          (eventsData?['total_unscanned_tickets'] as num?)?.toInt() ?? 0,
      scannedTickets:
          eventsData != null && eventsData['scanned_tickets'] is List
          ? (eventsData['scanned_tickets'] as List)
                .map((e) => TicketData.fromJson(e as Map<String, dynamic>))
                .toList()
          : [],
      unscannedTickets:
          eventsData != null && eventsData['unscanned_tickets'] is List
          ? (eventsData['unscanned_tickets'] as List)
                .map((e) => TicketData.fromJson(e as Map<String, dynamic>))
                .toList()
          : [],
      allTickets: eventsData != null && eventsData['all_tickets'] is List
          ? (eventsData['all_tickets'] as List)
                .map((e) => TicketData.fromJson(e as Map<String, dynamic>))
                .toList()
          : [],
    );
  }
}
