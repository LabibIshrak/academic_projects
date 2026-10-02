import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'explore_screen.dart';
import 'my_bookings_screen.dart';
import 'profile_screen.dart';
import 'results_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  String _userName = '';
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    final name = await _authService.getName();
    if (mounted) {
      setState(() {
        _userName = name ?? 'Traveler';
      });
    }
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      _SearchTab(
          userName: _userName, onNavigateToExplore: () => _onTabTapped(1)),
      const ExploreScreen(),
      const MyBookingsScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border:
              Border(top: BorderSide(color: Colors.grey.shade200, width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _onTabTapped,
          items: const [
            BottomNavigationBarItem(
                icon: Icon(Icons.search_rounded), label: 'Search'),
            BottomNavigationBarItem(
                icon: Icon(Icons.explore_rounded), label: 'Explore'),
            BottomNavigationBarItem(
                icon: Icon(Icons.confirmation_number_rounded),
                label: 'Tickets'),
            BottomNavigationBarItem(
                icon: Icon(Icons.person_rounded), label: 'Profile'),
          ],
        ),
      ),
    );
  }
}

class _SearchTab extends StatefulWidget {
  final String userName;
  final VoidCallback onNavigateToExplore;

  const _SearchTab({required this.userName, required this.onNavigateToExplore});

  @override
  State<_SearchTab> createState() => _SearchTabState();
}

class _SearchTabState extends State<_SearchTab> {
  final ApiService _apiService = ApiService();
  List<String> _cities = [];
  String? _selectedOrigin;
  String? _selectedDestination;
  bool _isLoadingCities = true;
  DateTime _selectedDate = DateTime.now();
  String _selectedTimeSlot = 'Any Time';
  double _swapRotation = 0.0;

  @override
  void initState() {
    super.initState();
    _loadCitiesAndPrefs();
  }

  Future<void> _loadCitiesAndPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastOrigin = prefs.getString('lastOrigin');
      final lastDest = prefs.getString('lastDest');

      final cities = await _apiService.getCities();
      if (mounted) {
        setState(() {
          _cities = cities;
          if (_cities.isNotEmpty) {
            if (lastOrigin != null && _cities.contains(lastOrigin)) {
              _selectedOrigin = lastOrigin;
            } else {
              _selectedOrigin = _cities.contains('Pabna') ? 'Pabna' : _cities[0];
            }
            if (lastDest != null && _cities.contains(lastDest)) {
              _selectedDestination = lastDest;
            } else {
              _selectedDestination = _cities.contains('Dhaka') ? 'Dhaka' : (_cities.length > 1 ? _cities[1] : _cities[0]);
            }
          }
          _isLoadingCities = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingCities = false);
      }
    }
  }

  void _swapCities() {
    setState(() {
      final temp = _selectedOrigin;
      _selectedOrigin = _selectedDestination;
      _selectedDestination = temp;
      _swapRotation += 0.5; // half turn
    });
  }

  void _search() async {
    if (_selectedOrigin == null || _selectedDestination == null) return;
    if (_selectedOrigin == _selectedDestination) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Origin and destination cannot be the same')));
      return;
    }
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('lastOrigin', _selectedOrigin!);
    await prefs.setString('lastDest', _selectedDestination!);

    final dateStr = "${_selectedDate.day.toString().padLeft(2, '0')} ${_getMonthName(_selectedDate.month)} ${_selectedDate.year}";

    if (mounted) {
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => ResultsScreen(
          origin: _selectedOrigin!,
          destination: _selectedDestination!,
          travelDate: dateStr,
          preferredTimeSlot: _selectedTimeSlot,
        ),
      ));
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: now,
      lastDate: now.add(const Duration(days: 7)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primary,
              onPrimary: Colors.white,
              onSurface: AppTheme.textDark,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  void _setRoute(String origin, String destination) {
    if (_cities.contains(origin) && _cities.contains(destination)) {
      setState(() {
        _selectedOrigin = origin;
        _selectedDestination = destination;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Determine greeting based on time
    final hour = DateTime.now().hour;
    String greeting = 'Good evening';
    if (hour < 12) {
      greeting = 'Good morning';
    } else if (hour < 17) {
      greeting = 'Good afternoon';
    }

    // Extract first name
    final firstName = widget.userName.split(' ').first;

    final String dateString = _selectedDate.day == DateTime.now().day &&
            _selectedDate.month == DateTime.now().month &&
            _selectedDate.year == DateTime.now().year
        ? "Today, ${_selectedDate.day.toString().padLeft(2, '0')} ${_getMonthName(_selectedDate.month)}"
        : "${_getDayName(_selectedDate.weekday)}, ${_selectedDate.day.toString().padLeft(2, '0')} ${_getMonthName(_selectedDate.month)}";

    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'BongoJatra',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primary,
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(left: 4, bottom: 8),
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: AppTheme.secondary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                '$greeting, $firstName',
                style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primary),
              ),
              const SizedBox(height: 24),
              Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      // FROM
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined,
                              color: Colors.grey),
                          const SizedBox(width: 16),
                          Expanded(
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                isExpanded: true,
                                value: _selectedOrigin,
                                hint: const Text('From'),
                                items: _cities
                                    .map((city) => DropdownMenuItem(
                                        value: city,
                                        child: Text(city,
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 18))))
                                    .toList(),
                                onChanged: (v) {
                                  if (v != null) {
                                    setState(() => _selectedOrigin = v);
                                  }
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                      // Divider with Swap button
                      Row(
                        children: [
                          const SizedBox(width: 12),
                          const SizedBox(height: 40, child: VerticalDivider()),
                          const Spacer(),
                          AnimatedRotation(
                            turns: _swapRotation,
                            duration: const Duration(milliseconds: 300),
                            child: IconButton(
                              onPressed: _swapCities,
                              icon: const Icon(Icons.swap_vert,
                                  color: AppTheme.secondary),
                              style: IconButton.styleFrom(
                                backgroundColor:
                                    AppTheme.secondary.withValues(alpha: 0.1),
                              ),
                            ),
                          ),
                        ],
                      ),
                      // TO
                      Row(
                        children: [
                          const Icon(Icons.location_on,
                              color: AppTheme.primary),
                          const SizedBox(width: 16),
                          Expanded(
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                isExpanded: true,
                                value: _selectedDestination,
                                hint: const Text('To'),
                                items: _cities
                                    .map((city) => DropdownMenuItem(
                                        value: city,
                                        child: Text(city,
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 18))))
                                    .toList(),
                                onChanged: (v) {
                                  if (v != null) {
                                    setState(() => _selectedDestination = v);
                                  }
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      // Date
                      InkWell(
                        onTap: _pickDate,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today_outlined,
                                  color: AppTheme.primary),
                              const SizedBox(width: 16),
                              Text(dateString,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold, fontSize: 16)),
                            ],
                          ),
                        ),
                      ),
                      const Divider(height: 16),
                      // Preferred Time Dropdown
                      Row(
                        children: [
                          const Icon(Icons.access_time, color: Colors.grey),
                          const SizedBox(width: 16),
                          Expanded(
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                isExpanded: true,
                                value: _selectedTimeSlot,
                                items: [
                                  'Any Time',
                                  'Early Morning (5AM–8AM)',
                                  'Morning (8AM–12PM)',
                                  'Afternoon (12PM–5PM)',
                                  'Evening (5PM–9PM)',
                                  'Night (9PM–5AM)'
                                ]
                                    .map((slot) => DropdownMenuItem(
                                        value: slot, child: Text(slot)))
                                    .toList(),
                                onChanged: (v) {
                                  if (v != null) {
                                    setState(() => _selectedTimeSlot = v);
                                  }
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoadingCities || _selectedOrigin == _selectedDestination ? null : _search,
                          child: const Text('Search'),
                        ),
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn().slideY(begin: 0.1),
              const SizedBox(height: 32),
              const Text(
                'POPULAR ROUTES',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey),
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildRouteChip('Pabna', 'Dhaka'),
                    _buildRouteChip('Pabna', 'Rajshahi'),
                    _buildRouteChip('Pabna', 'Bogura'),
                    _buildRouteChip('Pabna', 'Rangpur'),
                    _buildRouteChip('Pabna', 'Khulna'),
                  ],
                ),
              ).animate().fadeIn(delay: 200.ms),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRouteChip(String origin, String destination) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ActionChip(
        label: Text('$origin → $destination',
            style: const TextStyle(color: AppTheme.textDark)),
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: Colors.grey.shade300)),
        onPressed: () => _setRoute(origin, destination),
      ),
    );
  }

  String _getMonthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }

  String _getDayName(int weekday) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[weekday - 1];
  }
}
