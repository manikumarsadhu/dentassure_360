import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/shift_policy.dart';

class OfficeTimingsValue {
  final String timezone;
  final List<int> workDays;
  final double fullDayHours;
  final double halfDayHours;
  final ShiftTemplate dayShift;
  final ShiftTemplate nightShift;

  const OfficeTimingsValue({
    this.timezone = 'Asia/Kolkata',
    this.workDays = const [1, 2, 3, 4, 5],
    this.fullDayHours = 8,
    this.halfDayHours = 4,
    this.dayShift = ShiftTemplate.dayDefault,
    this.nightShift = ShiftTemplate.nightDefault,
  });

  OfficeTimingsValue copyWith({
    String? timezone,
    List<int>? workDays,
    double? fullDayHours,
    double? halfDayHours,
    ShiftTemplate? dayShift,
    ShiftTemplate? nightShift,
  }) {
    return OfficeTimingsValue(
      timezone: timezone ?? this.timezone,
      workDays: workDays ?? this.workDays,
      fullDayHours: fullDayHours ?? this.fullDayHours,
      halfDayHours: halfDayHours ?? this.halfDayHours,
      dayShift: dayShift ?? this.dayShift,
      nightShift: nightShift ?? this.nightShift,
    );
  }
}

class OfficeTimingsFields extends StatelessWidget {
  final OfficeTimingsValue value;
  final ValueChanged<OfficeTimingsValue> onChanged;

  const OfficeTimingsFields({
    super.key,
    required this.value,
    required this.onChanged,
  });

  static const _days = [
    (1, 'Mon'),
    (2, 'Tue'),
    (3, 'Wed'),
    (4, 'Thu'),
    (5, 'Fri'),
    (6, 'Sat'),
    (7, 'Sun'),
  ];

  Future<void> _pickTime(
    BuildContext context, {
    required String hm,
    required ValueChanged<String> onPicked,
  }) async {
    final minutes = ShiftTemplate.parseHm(hm);
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60),
    );
    if (picked == null) return;
    onPicked(ShiftTemplate.formatHm(picked.hour * 60 + picked.minute));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<String>(
          initialValue: const [
            'Asia/Kolkata',
            'UTC',
            'Asia/Dubai',
            'America/New_York',
          ].contains(value.timezone)
              ? value.timezone
              : 'Asia/Kolkata',
          decoration: const InputDecoration(
            labelText: 'Timezone',
            prefixIcon: Icon(Icons.public_outlined),
            border: OutlineInputBorder(),
          ),
          items: const [
            DropdownMenuItem(value: 'Asia/Kolkata', child: Text('Asia/Kolkata (IST)')),
            DropdownMenuItem(value: 'UTC', child: Text('UTC')),
            DropdownMenuItem(value: 'Asia/Dubai', child: Text('Asia/Dubai')),
            DropdownMenuItem(value: 'America/New_York', child: Text('America/New_York')),
          ],
          onChanged: (v) {
            if (v != null) onChanged(value.copyWith(timezone: v));
          },
        ),
        const SizedBox(height: 12),
        Text('Working days', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final day in _days)
              FilterChip(
                label: Text(day.$2),
                selected: value.workDays.contains(day.$1),
                onSelected: (selected) {
                  final next = [...value.workDays];
                  if (selected) {
                    if (!next.contains(day.$1)) next.add(day.$1);
                  } else {
                    next.remove(day.$1);
                  }
                  next.sort();
                  onChanged(value.copyWith(workDays: next.isEmpty ? [1, 2, 3, 4, 5] : next));
                },
              ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                initialValue: value.fullDayHours.toStringAsFixed(0),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Full-day hours',
                  border: OutlineInputBorder(),
                ),
                onChanged: (v) {
                  final n = double.tryParse(v);
                  if (n != null && n > 0) {
                    onChanged(value.copyWith(fullDayHours: n));
                  }
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                initialValue: value.halfDayHours.toStringAsFixed(0),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Half-day under (hrs)',
                  border: OutlineInputBorder(),
                ),
                onChanged: (v) {
                  final n = double.tryParse(v);
                  if (n != null && n > 0) {
                    onChanged(value.copyWith(halfDayHours: n));
                  }
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Text('Day shift', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        _ShiftRow(
          start: value.dayShift.startHm,
          end: value.dayShift.endHm,
          grace: value.dayShift.graceMinutes,
          onStart: () => _pickTime(
            context,
            hm: value.dayShift.startHm,
            onPicked: (hm) => onChanged(
              value.copyWith(dayShift: value.dayShift.copyWith(startHm: hm)),
            ),
          ),
          onEnd: () => _pickTime(
            context,
            hm: value.dayShift.endHm,
            onPicked: (hm) => onChanged(
              value.copyWith(dayShift: value.dayShift.copyWith(endHm: hm)),
            ),
          ),
          onGrace: (g) => onChanged(
            value.copyWith(dayShift: value.dayShift.copyWith(graceMinutes: g)),
          ),
        ),
        const SizedBox(height: 12),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Enable night shift template'),
          subtitle: const Text('For staff assigned Night. Shift date stays on the start day.'),
          value: value.nightShift.enabled,
          onChanged: (on) => onChanged(
            value.copyWith(nightShift: value.nightShift.copyWith(enabled: on)),
          ),
        ),
        if (value.nightShift.enabled)
          _ShiftRow(
            start: value.nightShift.startHm,
            end: value.nightShift.endHm,
            grace: value.nightShift.graceMinutes,
            onStart: () => _pickTime(
              context,
              hm: value.nightShift.startHm,
              onPicked: (hm) => onChanged(
                value.copyWith(
                  nightShift: value.nightShift.copyWith(
                    startHm: hm,
                    crossesMidnight: true,
                  ),
                ),
              ),
            ),
            onEnd: () => _pickTime(
              context,
              hm: value.nightShift.endHm,
              onPicked: (hm) => onChanged(
                value.copyWith(
                  nightShift: value.nightShift.copyWith(
                    endHm: hm,
                    crossesMidnight: true,
                  ),
                ),
              ),
            ),
            onGrace: (g) => onChanged(
              value.copyWith(
                nightShift: value.nightShift.copyWith(graceMinutes: g),
              ),
            ),
          ),
      ],
    );
  }
}

class _ShiftRow extends StatelessWidget {
  final String start;
  final String end;
  final int grace;
  final VoidCallback onStart;
  final VoidCallback onEnd;
  final ValueChanged<int> onGrace;

  const _ShiftRow({
    required this.start,
    required this.end,
    required this.grace,
    required this.onStart,
    required this.onEnd,
    required this.onGrace,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: onStart,
            child: Text('Start $start'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton(
            onPressed: onEnd,
            child: Text('End $end'),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 88,
          child: TextFormField(
            initialValue: '$grace',
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              labelText: 'Grace m',
              border: OutlineInputBorder(),
            ),
            onChanged: (v) => onGrace(int.tryParse(v) ?? 0),
          ),
        ),
      ],
    );
  }
}
