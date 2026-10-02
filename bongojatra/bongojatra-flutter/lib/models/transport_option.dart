import 'train_class.dart';

/// Model representing a single transport option.
class TransportOption {
  final String id;
  final String type;
  final String name;
  final String classType;
  final String origin;
  final String destination;
  final int price;
  final int durationMinutes;
  final String departureTime;
  final String arrivalTime;
  final List<String> amenities;
  final String operator;
  final int totalSeats;
  final int availableSeats;
  final String seatLayout;
  final List<TrainClass> classes;
  final String? journeyDate;

  TransportOption({
    required this.id,
    required this.type,
    required this.name,
    required this.classType,
    required this.origin,
    required this.destination,
    required this.price,
    required this.durationMinutes,
    required this.departureTime,
    required this.arrivalTime,
    required this.amenities,
    required this.operator,
    required this.totalSeats,
    required this.availableSeats,
    required this.seatLayout,
    this.classes = const [],
    this.journeyDate,
  });

  factory TransportOption.fromJson(Map<String, dynamic> json) {
    return TransportOption(
      id: json['id'] ?? '',
      type: json['type'] ?? '',
      name: json['name'] ?? '',
      classType: json['classType'] ?? '',
      origin: json['origin'] ?? '',
      destination: json['destination'] ?? '',
      price: json['price'] ?? 0,
      durationMinutes: json['durationMinutes'] ?? 0,
      departureTime: json['departureTime'] ?? '',
      arrivalTime: json['arrivalTime'] ?? '',
      amenities: List<String>.from(json['amenities'] ?? []),
      operator: json['operator'] ?? '',
      totalSeats: json['totalSeats'] ?? 0,
      availableSeats: json['availableSeats'] ?? 0,
      seatLayout: json['seatLayout'] ?? '',
      classes: (json['classes'] as List<dynamic>?)
              ?.map((e) => TrainClass.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      journeyDate: json['journeyDate'],
    );
  }

  /// Human-readable duration string
  String get durationText {
    int hours = durationMinutes ~/ 60;
    int mins = durationMinutes % 60;
    if (hours > 0 && mins > 0) return '${hours}h ${mins}m';
    if (hours > 0) return '${hours}h';
    return '${mins}m';
  }
}
