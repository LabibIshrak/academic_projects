import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import '../models/booking.dart';
import '../models/route_response.dart';
import '../models/transport_option.dart';
import '../models/train_class.dart';
import 'auth_service.dart';

class ApiService {
  // Android emulator  -> http://10.0.2.2:8081/api
  // iOS simulator     -> http://localhost:8081/api
  // Physical device   -> http://YOUR_PC_IP:8081/api
  // Web browser       -> http://localhost:8081/api
  static const String baseUrl = 'http://localhost:8081/api';

  static const List<String> _defaultCities = [
    'Pabna',
    'Dhaka',
    'Chattogram',
    'Sylhet',
    'Rajshahi',
    'Khulna',
    'Barishal',
    'Rangpur',
    'Mymensingh',
  ];

  final AuthService _authService = AuthService();

  // ── In-memory offline booking store ──
  static final List<Map<String, dynamic>> _offlineBookings = [];

  Future<Map<String, String>> _getHeaders() async {
    final token = await _authService.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<Map<String, dynamic>> loginWithGoogle(
      String email, String name, String idToken) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/google'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'name': name,
        'idToken': idToken,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to login');
    }
  }

  Future<List<String>> getCities() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/cities'));
      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        return data.cast<String>();
      }
    } catch (_) {
      // Ignore backend errors and use the local city list.
    }
    return _defaultCities;
  }

  Future<RouteResponse> suggestRoute(
      String origin, String destination, String preference, String travelDate, String preferredTimeSlot) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/route/suggest'),
        headers: await _getHeaders(),
        body: jsonEncode({
          'origin': origin,
          'destination': destination,
          'preference': preference,
          'travelDate': travelDate,
          'preferredTimeSlot': preferredTimeSlot,
        }),
      );

      if (response.statusCode == 200) {
        return RouteResponse.fromJson(jsonDecode(response.body));
      }
    } catch (_) {
      // Ignore backend errors and return a local fallback route.
    }

    return _buildLocalRouteResponse(origin, destination, preference, travelDate);
  }

  RouteResponse _buildLocalRouteResponse(
      String origin, String destination, String preference, String travelDate) {
    final List<TransportOption> options = [
      TransportOption(
        id: 'bus_${origin}_$destination',
        type: 'BUS',
        name: 'Express Bus',
        classType: 'AC Sleeper',
        origin: origin,
        destination: destination,
        price: 650,
        durationMinutes: 360,
        departureTime: '09:00',
        arrivalTime: '15:00',
        amenities: ['AC', 'Wi-Fi', 'Water'],
        operator: 'Bongo Travels',
        totalSeats: 40,
        availableSeats: 10,
        seatLayout: '3-2',
        journeyDate: travelDate,
      ),
      TransportOption(
        id: 'bus2_${origin}_$destination',
        type: 'BUS',
        name: 'Night Coach',
        classType: 'Non-AC',
        origin: origin,
        destination: destination,
        price: 420,
        durationMinutes: 390,
        departureTime: '22:00',
        arrivalTime: '04:30',
        amenities: ['Recliner', 'Blanket'],
        operator: 'Shohag Paribahan',
        totalSeats: 40,
        availableSeats: 15,
        seatLayout: '3-2',
        journeyDate: travelDate,
      ),
      TransportOption(
        id: 'train_${origin}_$destination',
        type: 'TRAIN',
        name: 'Intercity Express',
        classType: 'AC Chair',
        origin: origin,
        destination: destination,
        price: 520,
        durationMinutes: 420,
        departureTime: '07:30',
        arrivalTime: '14:30',
        amenities: ['AC', 'Charging', 'Snack'],
        operator: 'Rail Bangladesh',
        totalSeats: 80,
        availableSeats: 24,
        seatLayout: '2-2',
        journeyDate: travelDate,
        classes: [
          TrainClass(
            classType: 'SHOBHON_CHAIR',
            classLabel: 'Shobhon Chair',
            price: 260,
            coaches: [
              Coach(
                coachId: 'KHA',
                coachLabel: 'Coach KHA',
                totalSeats: 60,
                availableSeats: 18,
                layout: 'SHOBHON_CHAIR',
              ),
              Coach(
                coachId: 'GA',
                coachLabel: 'Coach GA',
                totalSeats: 60,
                availableSeats: 6,
                layout: 'SHOBHON_CHAIR',
              ),
            ],
          ),
          TrainClass(
            classType: 'SNIGDHA',
            classLabel: 'Snigdha (AC)',
            price: 695,
            coaches: [
              Coach(
                coachId: 'KA',
                coachLabel: 'Coach KA',
                totalSeats: 52,
                availableSeats: 12,
                layout: 'SNIGDHA',
              ),
            ],
          ),
          TrainClass(
            classType: 'AC_BERTH',
            classLabel: 'AC Berth',
            price: 1247,
            coaches: [
              Coach(
                coachId: 'HA',
                coachLabel: 'Coach HA',
                totalSeats: 40,
                availableSeats: 4,
                layout: 'AC_BERTH',
              ),
            ],
          ),
        ],
      ),
    ];

    if ((origin == 'Dhaka' && destination == 'Chattogram') ||
        (origin == 'Chattogram' && destination == 'Dhaka') ||
        (origin == 'Dhaka' && destination == 'Barishal') ||
        (origin == 'Barishal' && destination == 'Dhaka')) {
      options.add(
        TransportOption(
          id: 'launch_${origin}_$destination',
          type: 'LAUNCH',
          name: 'Launch Service',
          classType: 'First Class',
          origin: origin,
          destination: destination,
          price: 780,
          durationMinutes: 540,
          departureTime: '10:00',
          arrivalTime: '19:00',
          amenities: ['Cabin', 'Food', 'AC'],
          operator: 'River Cruisers',
          totalSeats: 60,
          availableSeats: 18,
          seatLayout: '1-2',
          journeyDate: travelDate,
        ),
      );
    }

    return RouteResponse(
      routeFound: true,
      origin: origin,
      destination: destination,
      preference: preference,
      options: options,
      aiSuggestion: AISuggestion(
        recommendation:
            'Choose the Express Bus for the best balance of price and comfort.',
        recommendedId: options.first.id,
        reason: 'It has a strong route schedule and good onboard amenities.',
        tip: 'Book as soon as possible for the best seats.',
      ),
    );
  }

  // ── Seats: full offline fallback ──
  Future<Map<String, dynamic>> getSeats(String optionId, {String? classType, String? coachId}) async {
    try {
      String url = '$baseUrl/seats/$optionId';
      if (classType != null) {
        url += '/$classType';
        if (coachId != null) {
          url += '/$coachId';
        }
      }
      final response = await http.get(
        Uri.parse(url),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (_) {
      // Backend unreachable — use offline seat data
    }

    return _buildOfflineSeats(optionId, classType);
  }

  Map<String, dynamic> _buildOfflineSeats(String optionId, String? classType) {
    final bool isTrain = optionId.startsWith('train');
    final bool isLaunch = optionId.startsWith('launch');

    String layoutType = 'BUS_2x2';
    if (isTrain) {
      layoutType = 'SHOBHON_CHAIR';
    } else if (isLaunch) {
      layoutType = 'LAUNCH_DECK';
    }

    final int totalSeats = isTrain ? 60 : (isLaunch ? 40 : 40);
    final rng = Random(optionId.hashCode);
    final List<Map<String, dynamic>> seats = [];

    if (layoutType == 'BUS_2x2') {
      final List<String> pos = ['A', 'B', 'C', 'D'];
      for (int row = 1; row <= 10; row++) {
        for (String p in pos) {
          final String id = '$row$p';
          final bool isAvail = rng.nextDouble() > 0.25;
          final bool isWindow = p == 'A' || p == 'D';
          seats.add({
            'id': id,
            'row': row,
            'position': p,
            'isWindow': isWindow,
            'status': isAvail ? 'AVAILABLE' : 'OCCUPIED',
          });
        }
      }
    } else if (layoutType == 'SHOBHON_CHAIR') {
      final List<String> pos = ['W1', 'W2', 'M1', 'M2'];
      for (int row = 1; row <= 15; row++) {
        for (String p in pos) {
          final String id = '$row$p';
          final bool isAvail = rng.nextDouble() > 0.25;
          final bool isWindow = p.startsWith('W');
          seats.add({
            'id': id,
            'row': row,
            'position': p,
            'isWindow': isWindow,
            'status': isAvail ? 'AVAILABLE' : 'OCCUPIED',
          });
        }
      }
    } else {
      // LAUNCH_DECK
      for (int i = 1; i <= totalSeats; i++) {
        final String id = 'D$i';
        final bool isAvail = rng.nextDouble() > 0.25;
        seats.add({
          'id': id,
          'row': (i / 4).ceil(),
          'position': 'Deck',
          'isWindow': false,
          'status': isAvail ? 'AVAILABLE' : 'OCCUPIED',
        });
      }
    }

    return {
      'layoutType': layoutType,
      'seats': seats,
      'totalSeats': totalSeats,
      'availableCount': seats.where((s) => s['status'] == 'AVAILABLE').length,
    };
  }

  // ── Booking: full offline fallback ──
  Future<Map<String, dynamic>> confirmBooking(
      String optionId, String seatId, String paymentMethod, {String? classType, String? coachId, String? journeyDate}) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/booking/confirm'),
        headers: await _getHeaders(),
        body: jsonEncode({
          'optionId': optionId,
          'seatId': seatId,
          'paymentMethod': paymentMethod,
          if (classType != null) 'classType': classType,
          if (coachId != null) 'coachId': coachId,
          if (journeyDate != null) 'journeyDate': journeyDate,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (_) {
      // Backend unreachable — confirm offline
    }

    return _confirmOfflineBooking(optionId, seatId, paymentMethod, classType, coachId, journeyDate);
  }

  Map<String, dynamic> _confirmOfflineBooking(
      String optionId, String seatId, String paymentMethod,
      String? classType, String? coachId, String? journeyDate) {
    final bookingId = 'BJ-${DateTime.now().millisecondsSinceEpoch}';

    // Parse the optionId format: type_origin_destination
    final parts = optionId.split('_');
    final type = parts[0].toUpperCase();
    final origin = parts.length > 1 ? parts[1] : 'Unknown';
    final destination = parts.length > 2 ? parts.sublist(2).join('_') : 'Unknown';

    final Map<String, dynamic> booking = {
      'bookingId': bookingId,
      'optionId': optionId,
      'type': type == 'BUS2' ? 'BUS' : type,
      'name': type == 'TRAIN' ? 'Intercity Express' : (type == 'LAUNCH' ? 'Launch Service' : 'Express Bus'),
      'origin': origin,
      'destination': destination,
      'seatId': seatId,
      'seatClass': classType ?? (type == 'TRAIN' ? 'AC Chair' : 'AC Sleeper'),
      'coachId': coachId,
      'price': type == 'TRAIN' ? 520 : (type == 'LAUNCH' ? 780 : 650),
      'paymentMethod': paymentMethod,
      'departureTime': type == 'TRAIN' ? '07:30' : '09:00',
      'arrivalTime': type == 'TRAIN' ? '14:30' : '15:00',
      'operator': type == 'TRAIN' ? 'Rail Bangladesh' : (type == 'LAUNCH' ? 'River Cruisers' : 'Bongo Travels'),
      'journeyDate': journeyDate,
      'bookedAt': DateTime.now().toIso8601String(),
      'status': 'CONFIRMED',
    };

    _offlineBookings.add(booking);

    return {
      'success': true,
      'bookingId': bookingId,
    };
  }

  Future<List<Booking>> getBookingHistory() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/booking/history'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        return data.map((e) => Booking.fromJson(e)).toList();
      }
    } catch (_) {
      // Backend unreachable — return offline bookings
    }

    return _offlineBookings.map((e) => Booking.fromJson(e)).toList();
  }

  Future<bool> cancelBooking(String bookingId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/booking/cancel'),
        headers: await _getHeaders(),
        body: jsonEncode({
          'bookingId': bookingId,
        }),
      );

      if (response.statusCode == 200) {
        final res = jsonDecode(response.body);
        return res['success'] == true;
      }
    } catch (_) {
      // Backend unreachable — cancel offline
    }

    _offlineBookings.removeWhere((b) => b['bookingId'] == bookingId);
    return true;
  }
}
