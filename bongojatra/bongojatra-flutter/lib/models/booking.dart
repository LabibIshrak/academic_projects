class Booking {
  final String bookingId;
  final String optionId;
  final String transportName;
  final String type;
  final String origin;
  final String destination;
  final String seatId;
  final String seatClass;
  final String? coachId;
  final int price;
  final String departureTime;
  final String arrivalTime;
  final String operator;
  final String paymentMethod;
  final String status;
  final String bookedAt;
  final String? journeyDate;

  Booking({
    required this.bookingId,
    required this.optionId,
    required this.transportName,
    required this.type,
    required this.origin,
    required this.destination,
    required this.seatId,
    required this.seatClass,
    this.coachId,
    required this.price,
    required this.departureTime,
    required this.arrivalTime,
    required this.operator,
    required this.paymentMethod,
    required this.status,
    required this.bookedAt,
    this.journeyDate,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      bookingId: json['bookingId'] ?? '',
      optionId: json['optionId'] ?? '',
      transportName: json['transportName'] ?? '',
      type: json['type'] ?? '',
      origin: json['origin'] ?? '',
      destination: json['destination'] ?? '',
      seatId: json['seatId'] ?? '',
      seatClass: json['seatClass'] ?? '',
      coachId: json['coachId'],
      price: json['price'] ?? 0,
      departureTime: json['departureTime'] ?? '',
      arrivalTime: json['arrivalTime'] ?? '',
      operator: json['operator'] ?? '',
      paymentMethod: json['paymentMethod'] ?? '',
      status: json['status'] ?? '',
      bookedAt: json['bookedAt'] ?? '',
      journeyDate: json['journeyDate'],
    );
  }
}
