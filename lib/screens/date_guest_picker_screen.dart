import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class DatePickerResult {
  const DatePickerResult({
    required this.dateRangeText,
    required this.checkInDate,
    required this.checkOutDate,
    required this.adults,
    required this.children,
  });

  final String dateRangeText;
  final DateTime checkInDate;
  final DateTime checkOutDate;
  final int adults;
  final int children;
}

class DateGuestPickerScreen extends StatefulWidget {
  const DateGuestPickerScreen({
    super.key,
    this.initialStartDate,
    this.initialEndDate,
    this.initialAdults = 2,
    this.initialChildren = 0,
  });

  final DateTime? initialStartDate;
  final DateTime? initialEndDate;
  final int initialAdults;
  final int initialChildren;

  @override
  State<DateGuestPickerScreen> createState() => _DateGuestPickerScreenState();
}

class _DateGuestPickerScreenState extends State<DateGuestPickerScreen> {
  static const _monthNames = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  static const _monthAbbreviations = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  late DateTime _today;
  late DateTime _displayedMonth;
  late DateTime _selectedStartDate;
  DateTime? _selectedEndDate;
  late int _adults;
  late int _children;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _today = DateTime(now.year, now.month, now.day);
    final start = _dateOnly(
      widget.initialStartDate ?? _today.add(const Duration(days: 1)),
    );
    _selectedStartDate = start.isBefore(_today)
        ? _today
        : start;
    final end = widget.initialEndDate == null
        ? _selectedStartDate.add(const Duration(days: 2))
        : _dateOnly(widget.initialEndDate!);
    _selectedEndDate = end.isAfter(_selectedStartDate) ? end : null;
    _displayedMonth = DateTime(
      _selectedStartDate.year,
      _selectedStartDate.month,
    );
    _adults = widget.initialAdults < 1 ? 1 : widget.initialAdults;
    _children = widget.initialChildren < 0 ? 0 : widget.initialChildren;
  }

  DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

  bool _isSameDay(DateTime first, DateTime second) =>
      first.year == second.year &&
      first.month == second.month &&
      first.day == second.day;

  String _formatDate(DateTime date) =>
      '${_monthAbbreviations[date.month - 1]} ${date.day.toString().padLeft(2, '0')}, ${date.year}';

  void _selectDate(DateTime date) {
    if (date.isBefore(_today)) return;
    setState(() {
      if (_selectedEndDate != null ||
          !date.isAfter(_selectedStartDate)) {
        _selectedStartDate = date;
        _selectedEndDate = null;
      } else {
        _selectedEndDate = date;
      }
    });
  }

  void _applySelection() {
    final end = _selectedEndDate;
    if (end == null) return;
    final range = _selectedStartDate.month == end.month &&
            _selectedStartDate.year == end.year
        ? '${_monthAbbreviations[_selectedStartDate.month - 1]} ${_selectedStartDate.day.toString().padLeft(2, '0')} - ${end.day.toString().padLeft(2, '0')}, ${end.year}'
        : '${_formatDate(_selectedStartDate)} - ${_formatDate(end)}';
    Navigator.pop(
      context,
      DatePickerResult(
        dateRangeText: range,
        checkInDate: _selectedStartDate,
        checkOutDate: end,
        adults: _adults,
        children: _children,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final latestMonth = DateTime(_today.year + 2, _today.month);
    final currentMonth = DateTime(_today.year, _today.month);
    final canGoBack = _displayedMonth.isAfter(currentMonth);
    final canGoForward = _displayedMonth.isBefore(latestMonth);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Close',
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Select Dates & Guests',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: AppColors.primaryDark,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_monthNames[_displayedMonth.month - 1]} ${_displayedMonth.year}',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryDark,
                  ),
                ),
                Row(
                  children: [
                    _monthButton(
                      icon: Icons.chevron_left,
                      enabled: canGoBack,
                      onPressed: () => setState(
                        () => _displayedMonth = DateTime(
                          _displayedMonth.year,
                          _displayedMonth.month - 1,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _monthButton(
                      icon: Icons.chevron_right,
                      enabled: canGoForward,
                      onPressed: () => setState(
                        () => _displayedMonth = DateTime(
                          _displayedMonth.year,
                          _displayedMonth.month + 1,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _CalendarHeaderDay('SUN'),
                _CalendarHeaderDay('MON'),
                _CalendarHeaderDay('TUE'),
                _CalendarHeaderDay('WED'),
                _CalendarHeaderDay('THU'),
                _CalendarHeaderDay('FRI'),
                _CalendarHeaderDay('SAT'),
              ],
            ),
            const SizedBox(height: 12),
            _buildCalendarGrid(),
            const SizedBox(height: 24),
            const Text(
              'Guests',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryDark,
              ),
            ),
            const SizedBox(height: 14),
            _buildGuestRow(
              title: 'Adults',
              subtitle: 'Ages 13 and above',
              count: _adults,
              onDecrement: () {
                if (_adults > 1) setState(() => _adults--);
              },
              onIncrement: () => setState(() => _adults++),
            ),
            const Divider(height: 24, color: AppColors.borderLight),
            _buildGuestRow(
              title: 'Children',
              subtitle: 'Ages 2 - 12',
              count: _children,
              onDecrement: () {
                if (_children > 0) setState(() => _children--);
              },
              onIncrement: () => setState(() => _children++),
            ),
            const SizedBox(height: 24),
            const Text(
              'STAY DURATION',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              _selectedEndDate == null
                  ? '${_formatDate(_selectedStartDate)} - Select check-out'
                  : '${_formatDate(_selectedStartDate)} - ${_formatDate(_selectedEndDate!)}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryDark,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '$_adults Adults, $_children Children',
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _selectedEndDate == null ? null : _applySelection,
                child: const Text('APPLY DATES & GUESTS'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _monthButton({
    required IconData icon,
    required bool enabled,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: 38,
      height: 38,
      child: OutlinedButton(
        onPressed: enabled ? onPressed : null,
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.zero,
          shape: const CircleBorder(),
          side: const BorderSide(color: AppColors.borderLight),
          backgroundColor: Colors.white,
        ),
        child: Icon(icon, size: 20),
      ),
    );
  }

  Widget _buildCalendarGrid() {
    final firstOfMonth = DateTime(
      _displayedMonth.year,
      _displayedMonth.month,
    );
    final firstWeekdayOffset = firstOfMonth.weekday % 7;
    final firstVisibleDate = firstOfMonth.subtract(
      Duration(days: firstWeekdayOffset),
    );

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 42,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisSpacing: 4,
        crossAxisSpacing: 0,
        childAspectRatio: 1,
      ),
      itemBuilder: (context, index) {
        final date = firstVisibleDate.add(Duration(days: index));
        final inCurrentMonth = date.month == _displayedMonth.month;
        final isStart = _isSameDay(date, _selectedStartDate);
        final isEnd = _selectedEndDate != null &&
            _isSameDay(date, _selectedEndDate!);
        final isInRange = _selectedEndDate != null &&
            date.isAfter(_selectedStartDate) &&
            date.isBefore(_selectedEndDate!);
        final isPast = date.isBefore(_today);
        final selectable = inCurrentMonth && !isPast;
        final isSelected = isStart || isEnd;

        return GestureDetector(
          onTap: selectable ? () => _selectDate(date) : null,
          child: Container(
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primaryNavy
                  : isInRange
                  ? AppColors.inputBackground
                  : Colors.transparent,
              shape: isSelected ? BoxShape.circle : BoxShape.rectangle,
            ),
            alignment: Alignment.center,
            child: Text(
              '${date.day}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected || isInRange
                    ? FontWeight.bold
                    : FontWeight.normal,
                color: isSelected
                    ? Colors.white
                    : !inCurrentMonth || isPast
                    ? Colors.grey.shade400
                    : AppColors.textPrimary,
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
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryDark,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Decrease $title',
          onPressed: onDecrement,
          icon: const Icon(Icons.remove_circle_outline),
        ),
        SizedBox(
          width: 26,
          child: Text(
            '$count',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryDark,
            ),
          ),
        ),
        IconButton(
          tooltip: 'Increase $title',
          onPressed: onIncrement,
          icon: const Icon(Icons.add_circle_outline),
        ),
      ],
    );
  }
}

class _CalendarHeaderDay extends StatelessWidget {
  const _CalendarHeaderDay(this.day);

  final String day;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 36,
    child: Text(
      day,
      textAlign: TextAlign.center,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        color: AppColors.textSecondary,
      ),
    ),
  );
}
