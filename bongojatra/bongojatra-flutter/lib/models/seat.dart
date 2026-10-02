class Seat {
  final String id;
  final int row;
  final String position;
  final bool isWindow;
  final String status;

  Seat({
    required this.id,
    required this.row,
    required this.position,
    required this.isWindow,
    required this.status,
  });

  factory Seat.fromJson(Map<String, dynamic> json) {
    return Seat(
      id: json['id'] ?? '',
      row: json['row'] ?? 0,
      position: json['position'] ?? '',
      isWindow: json['isWindow'] ?? false,
      status: json['status'] ?? 'AVAILABLE',
    );
  }
}
