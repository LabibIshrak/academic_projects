class Coach {
  final String coachId;
  final String coachLabel;
  final int totalSeats;
  final int availableSeats;
  final String layout;

  Coach({
    required this.coachId,
    required this.coachLabel,
    required this.totalSeats,
    required this.availableSeats,
    required this.layout,
  });

  factory Coach.fromJson(Map<String, dynamic> json) {
    return Coach(
      coachId: json['coachId'] ?? '',
      coachLabel: json['coachLabel'] ?? '',
      totalSeats: json['totalSeats'] ?? 0,
      availableSeats: json['availableSeats'] ?? 0,
      layout: json['layout'] ?? '',
    );
  }
}

class TrainClass {
  final String classType;
  final String classLabel;
  final int price;
  final List<Coach> coaches;

  TrainClass({
    required this.classType,
    required this.classLabel,
    required this.price,
    required this.coaches,
  });

  factory TrainClass.fromJson(Map<String, dynamic> json) {
    return TrainClass(
      classType: json['classType'] ?? '',
      classLabel: json['classLabel'] ?? '',
      price: json['price'] ?? 0,
      coaches: (json['coaches'] as List<dynamic>?)
              ?.map((e) => Coach.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
