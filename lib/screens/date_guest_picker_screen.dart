import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class DatePickerResult {
  final String dateRangeText; // e.g. "Oct 12 — Oct 16, 2024"
  final String checkInDate; // e.g. "Oct 12, 2024"
  final String checkOutDate; // e.g. "Oct 16, 2024"
  final int adults;
  final int children;

  DatePickerResult({
    required this.dateRangeText,
    required this.checkInDate,
    required this.checkOutDate,
    required this.adults,
    required this.children,
  });
}

class DateGuestPickerScreen extends StatefulWidget {
  const DateGuestPickerScreen({super.key});

  @override
  State<DateGuestPickerScreen> createState() => _DateGuestPickerScreenState();
}

class _DateGuestPickerScreenState extends State<DateGuestPickerScreen> {
  int _adults = 2;
  int _children = 0;

  int _selectedStartDay = 12;
  int _selectedEndDay = 16;
  int _currentMonthIndex = 0; // 0: Oct 2024, 1: Nov 2024

  final List<String> _months = ['October 2024', 'November 2024'];

  void _onDaySelected(int day) {
    setState(() {
      if (_selectedStartDay == 0 || (_selectedStartDay != 0 && _selectedEndDay != 0)) {
        _selectedStartDay = day;
        _selectedEndDay = 0;
      } else if (day < _selectedStartDay) {
        _selectedStartDay = day;
        _selectedEndDay = 0;
      } else {
        _selectedEndDay = day;
      }
    });
  }

  String get _currentMonthName => _months[_currentMonthIndex].split(' ')[0];
  String get _currentYear => _months[_currentMonthIndex].split(' ')[1];

  void _applySelection() {
    final startDay = _selectedStartDay > 0 ? _selectedStartDay : 12;
    final endDay = _selectedEndDay > 0
        ? _selectedEndDay
        : (startDay + 4 > 31 ? 31 : startDay + 4);

    final monthName = _currentMonthName.substring(0, 3);
    final year = _currentYear;

    final startDayStr = startDay.toString().padLeft(2, '0');
    final endDayStr = endDay.toString().padLeft(2, '0');

    final dateRangeText = '$monthName $startDayStr — $monthName $endDayStr, $year';
    final checkIn = '$monthName $startDayStr, $year';
    final checkOut = '$monthName $endDayStr, $year';

    final result = DatePickerResult(
      dateRangeText: dateRangeText,
      checkInDate: checkIn,
      checkOutDate: checkOut,
      adults: _adults,
      children: _children,
    );

    Navigator.pop(context, result);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Select Dates & Accompaniments',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: AppColors.primaryDark,
          ),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Month Header with Chevrons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _months[_currentMonthIndex],
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryDark,
                  ),
                ),
                Row(
                  children: [
                    InkWell(
                      onTap: () {
                        if (_currentMonthIndex > 0) {
                          setState(() => _currentMonthIndex--);
                        }
                      },
                      borderRadius: BorderRadius.circular(18),
                      child: _buildCircleArrow(Icons.chevron_left),
                    ),
                    const SizedBox(width: 10),
                    InkWell(
                      onTap: () {
                        if (_currentMonthIndex < _months.length - 1) {
                          setState(() => _currentMonthIndex++);
                        }
                      },
                      borderRadius: BorderRadius.circular(18),
                      child: _buildCircleArrow(Icons.chevron_right),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Calendar Days Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: const [
                _CalendarHeaderDay('SUN'),
                _CalendarHeaderDay('MON'),
                _CalendarHeaderDay('TUE'),
                _CalendarHeaderDay('WED'),
                _CalendarHeaderDay('THU'),
                _CalendarHeaderDay('FRI'),
                _CalendarHeaderDay('SAT'),
              ],
            ),
            const SizedBox(height: 16),

            // Calendar Grid Days
            _buildCalendarGrid(),
            const SizedBox(height: 28),

            // Accompaniments Header
            const Text(
              'Accompaniments',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryDark,
              ),
            ),
            const SizedBox(height: 16),

            // Adults Row
            _buildGuestRow(
              title: 'Adults',
              subtitle: 'Ages 13 and above',
              count: _adults,
              onDecrement: () {
                if (_adults > 1) setState(() => _adults--);
              },
              onIncrement: () {
                setState(() => _adults++);
              },
            ),
            const Divider(height: 24, color: AppColors.borderLight),

            // Children Row
            _buildGuestRow(
              title: 'Children',
              subtitle: 'Ages 2 - 12',
              count: _children,
              onDecrement: () {
                if (_children > 0) setState(() => _children--);
              },
              onIncrement: () {
                setState(() => _children++);
              },
            ),
            const SizedBox(height: 24),

            // Stay Duration Footer Summary
            const Text(
              'STAY DURATION',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '$_currentMonthName ${_selectedStartDay > 0 ? _selectedStartDay : 12} — $_currentMonthName ${_selectedEndDay > 0 ? _selectedEndDay : (_selectedStartDay > 0 ? _selectedStartDay + 4 : 16)}, $_currentYear',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryDark,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${_adults.toString().padLeft(2, '0')} Adults, ${_children.toString().padLeft(2, '0')} Children',
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),

            // Apply Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _applySelection,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryNavy,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'APPLY DATES & GUESTS',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildCircleArrow(IconData icon) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.borderLight),
        color: Colors.white,
      ),
      child: Icon(icon, color: AppColors.textPrimary, size: 20),
    );
  }

  List<String> _calendarDaysForMonth() {
    if (_currentMonthIndex == 1) {
      return [
        '28', '29', '30', '31', '1', '2', '3',
        '4', '5', '6', '7', '8', '9', '10',
        '11', '12', '13', '14', '15', '16', '17',
        '18', '19', '20', '21', '22', '23', '24',
        '25', '26', '27', '28', '29', '30', '1',
      ];
    }

    return [
      '29', '30', '1', '2', '3', '4', '5',
      '6', '7', '8', '9', '10', '11', '12',
      '13', '14', '15', '16', '17', '18', '19',
      '20', '21', '22', '23', '24', '25', '26',
      '27', '28', '29', '30', '31', '', ''
    ];
  }

  Widget _buildCalendarGrid() {
    final days = _calendarDaysForMonth();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 35,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisSpacing: 8,
        crossAxisSpacing: 0,
        childAspectRatio: 1.1,
      ),
      itemBuilder: (context, index) {
        final day = days[index];
        final isMuted = (index < 2); // 29, 30 of previous month
        final dayNum = int.tryParse(day);

        if (day.isEmpty) return const SizedBox();

        bool isStartDate = dayNum == _selectedStartDay && !isMuted;
        bool isEndDate = dayNum == _selectedEndDay && !isMuted;
        bool isInRange = dayNum != null &&
            _selectedStartDay > 0 &&
            _selectedEndDay > 0 &&
            dayNum > _selectedStartDay &&
            dayNum < _selectedEndDay &&
            !isMuted;

        BoxDecoration? decoration;
        Color textColor = AppColors.textPrimary;

        if (isMuted) {
          textColor = Colors.grey.shade300;
        }

        if (isInRange) {
          decoration = BoxDecoration(
            color: Colors.grey.shade200,
          );
        } else if (isStartDate || isEndDate) {
          decoration = const BoxDecoration(
            color: AppColors.primaryNavy,
            shape: BoxShape.circle,
          );
          textColor = Colors.white;
        }

        return GestureDetector(
          onTap: isMuted || dayNum == null ? null : () => _onDaySelected(dayNum),
          child: Center(
            child: Container(
              width: isStartDate || isEndDate ? 36 : double.infinity,
              height: isStartDate || isEndDate ? 36 : double.infinity,
              alignment: Alignment.center,
              decoration: decoration,
              child: Text(
                day,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: (isStartDate || isEndDate || isInRange)
                      ? FontWeight.bold
                      : FontWeight.w400,
                  color: textColor,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildGuestRow({
    required String title,
    required String subtitle,
    required int count,
    required VoidCallback onDecrement,
    required VoidCallback onIncrement,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryDark,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        Row(
          children: [
            InkWell(
              onTap: onDecrement,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.borderLight, width: 1.2),
                ),
                child: const Icon(Icons.remove, size: 20, color: AppColors.textPrimary),
              ),
            ),
            SizedBox(
              width: 48,
              child: Text(
                count.toString().padLeft(2, '0'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryDark,
                ),
              ),
            ),
            InkWell(
              onTap: onIncrement,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.borderLight, width: 1.2),
                ),
                child: const Icon(Icons.add, size: 20, color: AppColors.textPrimary),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _CalendarHeaderDay extends StatelessWidget {
  final String day;
  const _CalendarHeaderDay(this.day);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 36,
      child: Text(
        day,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}
