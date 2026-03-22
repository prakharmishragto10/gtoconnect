import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/colors.dart';

class AttendanceScreen extends StatelessWidget {
  const AttendanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final employees = [
      {
        'name': 'Prakhar Mishra',
        'role': 'Backend Dev',
        'location': 'Lucknow',
        'status': 'present',
        'in': '09:02 AM',
        'out': '—',
        'present': 11,
        'absent': 1,
        'late': 1,
      },
      {
        'name': 'Chandanmuri Nida',
        'role': 'Web Dev',
        'location': 'Noida',
        'status': 'absent',
        'in': '—',
        'out': '—',
        'present': 9,
        'absent': 3,
        'late': 0,
      },
      {
        'name': 'Aditya Sharma',
        'role': 'Reg. Mktg Mgr',
        'location': 'Noida',
        'status': 'absent',
        'in': '—',
        'out': '—',
        'present': 10,
        'absent': 2,
        'late': 0,
      },
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'MARCH 2026',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: kTealGray,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Team Attendance',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: kDeepBlue,
            ),
          ),
          const SizedBox(height: 16),

          // Summary row
          Row(
            children: [
              _SummaryChip(
                label: 'Present',
                value: '1',
                color: kForest,
                bg: kSuccessBg,
              ),
              const SizedBox(width: 8),
              _SummaryChip(
                label: 'Absent',
                value: '2',
                color: kDanger,
                bg: kDangerBg,
              ),
              const SizedBox(width: 8),
              _SummaryChip(
                label: 'Total',
                value: '3',
                color: kDeepBlue,
                bg: kInfoBg,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Employee cards
          ...employees.map((e) => _EmployeeAttCard(emp: e)),
        ],
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final String label, value;
  final Color color, bg;
  const _SummaryChip({
    required this.label,
    required this.value,
    required this.color,
    required this.bg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmployeeAttCard extends StatelessWidget {
  final Map<String, dynamic> emp;
  const _EmployeeAttCard({required this.emp});

  @override
  Widget build(BuildContext context) {
    final isPresent = emp['status'] == 'present';
    final isLate = emp['status'] == 'late';
    Color sc = isPresent
        ? kForest
        : isLate
        ? kWarn
        : kDanger;
    Color sb = isPresent
        ? kSuccessBg
        : isLate
        ? kWarnBg
        : kDangerBg;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: kBorder),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: kInfoBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    (emp['name'] as String).substring(0, 1),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: kDeepBlue,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      emp['name'],
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: kDeepBlue,
                      ),
                    ),
                    Text(
                      '${emp['role']} · ${emp['location']}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        color: kTealGray,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: sb,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  emp['status'],
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: sc,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _InfoChip(icon: Icons.login, label: 'In', value: emp['in']),
              const SizedBox(width: 8),
              _InfoChip(icon: Icons.logout, label: 'Out', value: emp['out']),
              const Spacer(),
              _MiniStat(
                label: 'Present',
                value: '${emp['present']}',
                color: kForest,
              ),
              const SizedBox(width: 8),
              _MiniStat(
                label: 'Absent',
                value: '${emp['absent']}',
                color: kDanger,
              ),
              const SizedBox(width: 8),
              _MiniStat(label: 'Late', value: '${emp['late']}', color: kWarn),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _InfoChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: kOffWhite,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Icon(icon, size: 12, color: kTealGray),
          const SizedBox(width: 4),
          Text(
            '$label: ',
            style: GoogleFonts.plusJakartaSans(fontSize: 10, color: kTealGray),
          ),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: kDeepBlue,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label, value;
  final Color color;
  const _MiniStat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(fontSize: 9, color: kTealGray),
        ),
      ],
    );
  }
}
