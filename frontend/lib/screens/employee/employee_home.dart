import 'package:flutter/material.dart';
import '../../models/user.dart';
import '../../widgets/app_shell.dart';
import 'emp_attendance.dart';
import 'emp_dashboard.dart';
import 'emp_reimbursement.dart';
import 'emp_salary.dart';
import 'emp_travel.dart';

const List<ShellNavItem> _navItems = [
  (icon: Icons.dashboard_outlined, activeIcon: Icons.dashboard, label: 'Home'),
  (
    icon: Icons.access_time_outlined,
    activeIcon: Icons.access_time,
    label: 'Attendance',
  ),
  (icon: Icons.receipt_outlined, activeIcon: Icons.receipt, label: 'Claims'),
  (icon: Icons.payments_outlined, activeIcon: Icons.payments, label: 'Salary'),
  (icon: Icons.flight_outlined, activeIcon: Icons.flight, label: 'Travel'),
];

class EmployeeHome extends StatefulWidget {
  final UserModel user;
  const EmployeeHome({super.key, required this.user});

  @override
  State<EmployeeHome> createState() => _EmployeeHomeState();
}

class _EmployeeHomeState extends State<EmployeeHome> {
  late final _screens = <Widget>[
    EmpDashboard(user: widget.user),
    EmpAttendance(user: widget.user),
    EmpReimbursement(user: widget.user),
    EmpSalary(user: widget.user),
    EmpTravel(user: widget.user),
  ];

  @override
  Widget build(BuildContext context) {
    return AppShell(user: widget.user, items: _navItems, screens: _screens);
  }
}
