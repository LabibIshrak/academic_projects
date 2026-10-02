import 'package:flutter/material.dart';
import '../models/transport_option.dart';
import '../models/seat.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/seat_widget.dart';
import 'payment_method_screen.dart';

class SeatSelectionScreen extends StatefulWidget {
  final TransportOption option;
  final String? classType;
  final String? coachId;
  final String? coachLabel;

  const SeatSelectionScreen({
    super.key,
    required this.option,
    this.classType,
    this.coachId,
    this.coachLabel,
  });

  @override
  State<SeatSelectionScreen> createState() => _SeatSelectionScreenState();
}

class _SeatSelectionScreenState extends State<SeatSelectionScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  String? _error;
  List<Seat> _seats = [];
  Seat? _selectedSeat;
  String _layoutType = '';
  int _availableCount = 0;

  @override
  void initState() {
    super.initState();
    _fetchSeats();
  }

  Future<void> _fetchSeats() async {
    try {
      final response = await _apiService.getSeats(
        widget.option.id,
        classType: widget.classType,
        coachId: widget.coachId,
      );
      if (mounted) {
        setState(() {
          _layoutType = response['layoutType'];
          _availableCount = response['availableCount'] ?? 0;
          final seatsData = response['seats'] as List<dynamic>;
          _seats = seatsData.map((e) => Seat.fromJson(e)).toList();
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

  void _onSeatTap(Seat seat) {
    setState(() {
      if (_selectedSeat?.id == seat.id) {
        _selectedSeat = null; // deselect
      } else {
        _selectedSeat = seat; // select
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Seat'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Error: $_error'))
              : Column(
                  children: [
                    _buildInfoBar(),
                    Expanded(child: _buildSeatMap()),
                    _buildLegend(),
                  ],
                ),
      bottomNavigationBar: _buildStickyBottomBar(),
    );
  }

  Widget _buildInfoBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.option.name,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16)),
              Text('${widget.option.origin} → ${widget.option.destination}',
                  style: const TextStyle(color: Colors.grey)),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                    widget.coachLabel != null
                        ? '${widget.classType} — ${widget.coachLabel}'
                        : widget.option.classType,
                    style: const TextStyle(
                        fontSize: 10, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 4),
              Text('$_availableCount available',
                  style: const TextStyle(
                      color: AppTheme.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSeatMap() {
    if (_layoutType == 'BUS_2x2') {
      return _buildBusLayout();
    } else if (_layoutType == 'SHOBHON') {
      return _buildShobhonLayout();
    } else if (_layoutType == 'SHOBHON_CHAIR' || _layoutType == 'FIRST_SEAT' || _layoutType == 'SNIGDHA' || _layoutType == 'TRAIN_2x2') {
      int rows = _layoutType == 'SHOBHON_CHAIR' ? 15 : 13;
      return _buildTrain2x2Layout(rows);
    } else if (_layoutType == 'AC_BERTH') {
      return _buildACBerthLayout();
    } else if (_layoutType == 'AC_FIRST') {
      return _buildACFirstLayout();
    } else if (_layoutType == 'LAUNCH_DECK') {
      return _buildLaunchDeckLayout();
    } else if (_layoutType == 'LAUNCH_CABIN') {
      return _buildLaunchCabinLayout();
    }
    return Center(child: Text('Unknown layout: $_layoutType'));
  }

  Widget _buildBusLayout() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300, width: 2),
          borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(40),
              topRight: Radius.circular(40),
              bottomLeft: Radius.circular(16),
              bottomRight: Radius.circular(16)),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.directions_bus, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 20),
            for (int row = 1; row <= 10; row++)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        _buildSeatByPos(row, 'A'),
                        const SizedBox(width: 8),
                        _buildSeatByPos(row, 'B'),
                      ],
                    ),
                    const SizedBox(width: 32),
                    Row(
                      children: [
                        _buildSeatByPos(row, 'C'),
                        const SizedBox(width: 8),
                        _buildSeatByPos(row, 'D'),
                      ],
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildShobhonLayout() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.arrow_upward, color: Colors.grey),
              SizedBox(width: 8),
              Text('Direction of travel', style: TextStyle(color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 20),
          for (int row = 1; row <= 16; row++)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  SizedBox(
                      width: 24,
                      child: Text('$row',
                          style: const TextStyle(
                              color: Colors.grey,
                              fontWeight: FontWeight.bold))),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            _buildSeatByPos(row, 'A', size: 46),
                            const SizedBox(width: 4),
                            _buildSeatByPos(row, 'B', size: 46),
                          ],
                        ),
                        const SizedBox(width: 16),
                        Row(
                          children: [
                            _buildSeatByPos(row, 'C', size: 46),
                            const SizedBox(width: 4),
                            _buildSeatByPos(row, 'D', size: 46),
                            const SizedBox(width: 4),
                            _buildSeatByPos(row, 'E', size: 46),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTrain2x2Layout(int numRows) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.arrow_upward, color: Colors.grey),
              SizedBox(width: 8),
              Text('Direction of travel', style: TextStyle(color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 20),
          for (int row = 1; row <= numRows; row++)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  SizedBox(
                      width: 24,
                      child: Text('$row',
                          style: const TextStyle(
                              color: Colors.grey,
                              fontWeight: FontWeight.bold))),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            _buildSeatByPos(row, 'W1'),
                            const SizedBox(width: 8),
                            _buildSeatByPos(row, 'M1'),
                          ],
                        ),
                        const SizedBox(width: 32),
                        Row(
                          children: [
                            _buildSeatByPos(row, 'M2'),
                            const SizedBox(width: 8),
                            _buildSeatByPos(row, 'W2'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildACBerthLayout() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          for (int bay = 1; bay <= 20; bay++)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                children: [
                  SizedBox(
                      width: 60,
                      child: Text('Bay $bay',
                          style: const TextStyle(
                              color: Colors.grey,
                              fontWeight: FontWeight.bold))),
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(child: _buildBerthSeat('${bay}L', 'Lower')),
                        const SizedBox(width: 16),
                        Expanded(child: _buildBerthSeat('${bay}U', 'Upper')),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildACFirstLayout() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Wrap(
        spacing: 16,
        runSpacing: 16,
        children: [
          for (int comp = 1; comp <= 6; comp++)
            Container(
              width: MediaQuery.of(context).size.width / 2 - 32,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade400, width: 2),
                  borderRadius: BorderRadius.circular(16)),
              child: Column(
                children: [
                  Text('COMP-$comp',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.grey)),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildBerthSeat('C$comp-1L', 'L', size: 50),
                      _buildBerthSeat('C$comp-2L', 'L', size: 50),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildBerthSeat('C$comp-1U', 'U', size: 50),
                      _buildBerthSeat('C$comp-2U', 'U', size: 50),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBerthSeat(String id, String label, {double size = 80}) {
    final seat = _seats.firstWhere((s) => s.id == id,
        orElse: () => Seat(
            id: id, row: 0, position: '', isWindow: false, status: 'UNKNOWN'));
    if (seat.status == 'UNKNOWN') return SizedBox(height: size);

    bool isAvailable = seat.status == 'AVAILABLE';
    bool isSelected = _selectedSeat?.id == seat.id;
    bool isLower = label.contains('L');

    return GestureDetector(
      onTap: isAvailable ? () => _onSeatTap(seat) : null,
      child: Container(
        height: size,
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primary
              : (isAvailable
                  ? (isLower ? AppTheme.primary.withValues(alpha: 0.1) : AppTheme.primary.withValues(alpha: 0.05))
                  : Colors.grey.shade200),
          border: Border.all(
              color: isSelected
                  ? AppTheme.primary
                  : (isAvailable ? AppTheme.primary.withValues(alpha: 0.5) : Colors.grey.shade400)),
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label,
                style: TextStyle(
                    color: isSelected ? Colors.white : (isAvailable ? AppTheme.textDark : Colors.grey),
                    fontSize: 12,
                    fontWeight: FontWeight.bold)),
            Text(id,
                style: TextStyle(
                    color: isSelected ? Colors.white70 : Colors.grey,
                    fontSize: 10)),
          ],
        ),
      ),
    );
  }

  Widget _buildLaunchDeckLayout() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Text('Open Deck Area',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 20),
          for (int row = 1; row <= 6; row++)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  for (int col = 1; col <= 8; col++)
                    _buildSeatById('D${(row - 1) * 8 + col}', size: 36),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLaunchCabinLayout() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          for (int row = 1; row <= (_seats.length / 2).ceil(); row++)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: _buildCabinSeat('C${(row - 1) * 2 + 1}')),
                  const SizedBox(width: 16),
                  if ((row - 1) * 2 + 2 <= _seats.length)
                    Expanded(child: _buildCabinSeat('C${(row - 1) * 2 + 2}'))
                  else
                    const Expanded(child: SizedBox()),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSeatByPos(int row, String position, {double size = 52}) {
    final id = '$row$position';
    return _buildSeatById(id, size: size);
  }

  Widget _buildSeatById(String id, {double size = 52}) {
    final seat = _seats.firstWhere((s) => s.id == id,
        orElse: () => Seat(
            id: id, row: 0, position: '', isWindow: false, status: 'UNKNOWN'));
    if (seat.status == 'UNKNOWN') return SizedBox(width: size, height: size);
    return SeatWidget(
      seat: seat,
      isSelected: _selectedSeat?.id == seat.id,
      onTap: () => _onSeatTap(seat),
      size: size,
      label: id,
    );
  }

  Widget _buildCabinSeat(String id) {
    final seat = _seats.firstWhere((s) => s.id == id,
        orElse: () => Seat(
            id: id, row: 0, position: '', isWindow: false, status: 'UNKNOWN'));
    if (seat.status == 'UNKNOWN') return const SizedBox();

    bool isAvailable = seat.status == 'AVAILABLE';
    bool isSelected = _selectedSeat?.id == seat.id;

    return GestureDetector(
      onTap: isAvailable ? () => _onSeatTap(seat) : null,
      child: Container(
        height: 80,
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primary
              : (isAvailable ? Colors.white : Colors.grey.shade200),
          border: Border.all(
              color: isAvailable ? AppTheme.primary : Colors.grey.shade400,
              width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(id,
                style: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : (isAvailable ? AppTheme.textDark : Colors.grey),
                    fontWeight: FontWeight.bold,
                    fontSize: 18)),
            Text(isAvailable ? 'Cabin' : 'Booked',
                style: TextStyle(
                    color: isSelected
                        ? Colors.white70
                        : (isAvailable ? AppTheme.primary : Colors.grey),
                    fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _legendItem(Colors.white, AppTheme.primary, 'Available'),
          const SizedBox(width: 24),
          _legendItem(
              const Color(0xFFE8ECEF), Colors.grey.shade400, 'Occupied'),
          const SizedBox(width: 24),
          _legendItem(AppTheme.primary, AppTheme.primary, 'Selected'),
        ],
      ),
    );
  }

  Widget _legendItem(Color bgColor, Color borderColor, String label) {
    return Row(
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
              color: bgColor,
              border: Border.all(color: borderColor),
              borderRadius: BorderRadius.circular(4)),
        ),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildStickyBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16)
          .copyWith(bottom: MediaQuery.of(context).padding.bottom + 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              offset: const Offset(0, -4),
              blurRadius: 10)
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_selectedSeat != null ? 'Selected Seat' : 'Select a seat',
                  style: const TextStyle(color: Colors.grey, fontSize: 12)),
              if (_selectedSeat != null)
                Text(_selectedSeat!.id,
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primary)),
            ],
          ),
          ElevatedButton(
            onPressed: _selectedSeat == null
                ? null
                : () {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => PaymentMethodScreen(
                        option: widget.option,
                        seatId: _selectedSeat!.id,
                        classType: widget.classType,
                        coachId: widget.coachId,
                      ),
                    ));
                  },
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }
}
