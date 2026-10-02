import 'transport_option.dart';

/// Model representing the full API response for a route search.
class RouteResponse {
  final bool routeFound;
  final String? error;
  final String? origin;
  final String? destination;
  final String? preference;
  final List<TransportOption> options;
  final AISuggestion? aiSuggestion;

  RouteResponse({
    required this.routeFound,
    this.error,
    this.origin,
    this.destination,
    this.preference,
    required this.options,
    this.aiSuggestion,
  });

  factory RouteResponse.fromJson(Map<String, dynamic> json) {
    return RouteResponse(
      routeFound: json['routeFound'] ?? false,
      error: json['error'],
      origin: json['origin'],
      destination: json['destination'],
      preference: json['preference'],
      options: (json['options'] as List<dynamic>?)
              ?.map((e) => TransportOption.fromJson(e))
              .toList() ??
          [],
      aiSuggestion: json['aiSuggestion'] != null
          ? AISuggestion.fromJson(json['aiSuggestion'])
          : null,
    );
  }
}

/// Model for the AI suggestion portion of the response.
class AISuggestion {
  final String recommendation;
  final String recommendedId;
  final String reason;
  final String tip;

  AISuggestion({
    required this.recommendation,
    required this.recommendedId,
    required this.reason,
    required this.tip,
  });

  factory AISuggestion.fromJson(Map<String, dynamic> json) {
    return AISuggestion(
      recommendation: json['recommendation'] ?? '',
      recommendedId: json['recommendedId'] ?? '',
      reason: json['reason'] ?? '',
      tip: json['tip'] ?? '',
    );
  }
}
