import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/route_response.dart';
import '../models/transport_option.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/ai_suggestion_card.dart';
import '../widgets/transport_card.dart';
import 'class_selection_screen.dart';
import 'seat_selection_screen.dart';

class ResultsScreen extends StatefulWidget {
  final String origin;
  final String destination;
  final String travelDate;
  final String preferredTimeSlot;

  const ResultsScreen({
    super.key,
    required this.origin,
    required this.destination,
    required this.travelDate,
    required this.preferredTimeSlot,
  });

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  String? _error;
  RouteResponse? _routeResponse;
  String _selectedFilter = 'All';
  String _selectedTimeFilter = 'Any Time';
  String _selectedSort = 'Earliest Departure';

  @override
  void initState() {
    super.initState();
    _fetchRoutes();
  }

  Future<void> _fetchRoutes() async {
    try {
      final response = await _apiService.suggestRoute(
          widget.origin, widget.destination, 'FASTEST', widget.travelDate, widget.preferredTimeSlot);
      if (mounted) {
        setState(() {
          _routeResponse = response;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final int routeCount = _routeResponse?.options.length ?? 0;
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${widget.origin} → ${widget.destination}'),
            if (_routeResponse != null)
              Text(
                '${widget.travelDate} · $routeCount routes',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.sort),
            onPressed: _showSortBottomSheet,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Error: $_error'))
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_routeResponse == null ||
        !_routeResponse!.routeFound ||
        _routeResponse!.options.isEmpty) {
      return const Center(child: Text('No routes found for this journey.'));
    }

    final options = _routeResponse!.options;
    final bool hasLaunch = options.any((o) => o.type == 'LAUNCH');
    final aiSuggestion = _routeResponse!.aiSuggestion;

    List<TransportOption> filteredOptions = List.from(options);
    if (_selectedFilter != 'All') {
      filteredOptions = filteredOptions
          .where((o) => o.type == _selectedFilter.toUpperCase())
          .toList();
    }

    if (_selectedTimeFilter != 'Any Time') {
      filteredOptions = filteredOptions.where((o) {
        int mins = _parseTimeMinutes(o.departureTime);
        if (_selectedTimeFilter == 'Morning') return mins >= 8 * 60 && mins < 12 * 60;
        if (_selectedTimeFilter == 'Afternoon') return mins >= 12 * 60 && mins < 17 * 60;
        if (_selectedTimeFilter == 'Evening') return mins >= 17 * 60 && mins < 21 * 60;
        if (_selectedTimeFilter == 'Night') return mins >= 21 * 60 || mins < 5 * 60;
        return true;
      }).toList();
    }

    // Sorting
    filteredOptions.sort((a, b) {
      if (_selectedSort == 'Lowest Price') {
        return a.price.compareTo(b.price);
      } else if (_selectedSort == 'Fastest Route') {
        return a.durationMinutes.compareTo(b.durationMinutes);
      } else if (_selectedSort == 'Earliest Departure') {
        return _parseTimeMinutes(a.departureTime).compareTo(_parseTimeMinutes(b.departureTime));
      }
      return 0;
    });

    // Always put AI pick at the top if present in filtered list
    if (aiSuggestion != null) {
      final aiIndex = filteredOptions.indexWhere((o) => o.id == aiSuggestion.recommendedId);
      if (aiIndex > 0) {
        final aiOption = filteredOptions.removeAt(aiIndex);
        filteredOptions.insert(0, aiOption);
      }
    }

    return Column(
      children: [
        if (aiSuggestion != null)
          AiSuggestionCard(suggestion: aiSuggestion)
              .animate()
              .fadeIn()
              .slideY(begin: -0.1),

        // Filters
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              _buildFilterTab('All'),
              _buildFilterTab('Bus'),
              _buildFilterTab('Train'),
              if (hasLaunch) _buildFilterTab('Launch'),
              const SizedBox(width: 8),
              Container(width: 1, height: 24, color: Colors.grey.shade300),
              const SizedBox(width: 8),
              _buildTimeFilterTab('Any Time'),
              _buildTimeFilterTab('Morning'),
              _buildTimeFilterTab('Afternoon'),
              _buildTimeFilterTab('Evening'),
              _buildTimeFilterTab('Night'),
            ],
          ),
        ),

        // Results List
        Expanded(
          child: filteredOptions.isEmpty
              ? const Center(child: Text('No routes match your filters.'))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filteredOptions.length,
                  itemBuilder: (context, index) {
                    final option = filteredOptions[index];
                    final isAiPick = aiSuggestion != null &&
                        aiSuggestion.recommendedId == option.id;

                    return TransportCard(
                      option: option,
                      isAiPick: isAiPick,
                      onTap: () {
                        if (option.type == 'TRAIN') {
                          Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => ClassSelectionScreen(option: option),
                          ));
                        } else {
                          Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => SeatSelectionScreen(option: option),
                          ));
                        }
                      },
                    )
                        .animate()
                        .fadeIn(delay: Duration(milliseconds: 100 * index))
                        .slideX();
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildFilterTab(String label) {
    final isActive = _selectedFilter == label;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = label),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: isActive ? AppTheme.primary : Colors.grey.shade300),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : AppTheme.textDark,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildTimeFilterTab(String label) {
    final isActive = _selectedTimeFilter == label;
    return GestureDetector(
      onTap: () => setState(() => _selectedTimeFilter = label),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.secondary.withValues(alpha: 0.1) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: isActive ? AppTheme.secondary : Colors.grey.shade300),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? AppTheme.secondary : AppTheme.textGrey,
            fontSize: 12,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  void _showSortBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Text('Sort by',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                _buildSortOption('Earliest Departure'),
                _buildSortOption('Lowest Price'),
                _buildSortOption('Fastest Route'),
                _buildSortOption('Most Comfortable'),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSortOption(String label) {
    return ListTile(
      title: Text(label),
      trailing: _selectedSort == label
          ? const Icon(Icons.check, color: AppTheme.primary)
          : null,
      onTap: () {
        setState(() => _selectedSort = label);
        Navigator.pop(context);
      },
    );
  }

  int _parseTimeMinutes(String time) {
    try {
      final parts = time.split(':');
      return int.parse(parts[0]) * 60 + int.parse(parts[1]);
    } catch (_) {
      return 0;
    }
  }
}
