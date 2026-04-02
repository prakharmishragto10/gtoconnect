import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/colors.dart';
import '../../services/auth_service.dart';

class EmployeesScreen extends StatefulWidget {
  const EmployeesScreen({super.key});

  @override
  State<EmployeesScreen> createState() => _EmployeesScreenState();
}

class _EmployeesScreenState extends State<EmployeesScreen> {
  bool _loading = true;
  List<dynamic> _employees = [];

  @override
  void initState() {
    super.initState();
    _loadEmployees();
  }

  Future<void> _loadEmployees() async {
    try {
      final data = await AuthService.getEmployees();
      setState(() {
        _employees = data;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: kDeepBlue));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Team',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: kDeepBlue,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: kDeepBlue,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.add, size: 14, color: Colors.white),
                    const SizedBox(width: 4),
                    Text(
                      'Add Employee',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${_employees.length} team members',
            style: GoogleFonts.plusJakartaSans(fontSize: 12, color: kTealGray),
          ),
          const SizedBox(height: 16),

          if (_employees.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  'No employees found',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: kTealGray,
                  ),
                ),
              ),
            )
          else
            ..._employees.map((e) => _EmployeeCard(emp: e)),
        ],
      ),
    );
  }
}

class _EmployeeCard extends StatelessWidget {
  final Map<String, dynamic> emp;
  const _EmployeeCard({required this.emp});

  @override
  Widget build(BuildContext context) {
    final name = emp['name'] ?? '—';
    final role = emp['designation'] ?? '—';
    final loc = emp['location'] ?? '—';
    final salary = emp['base_salary'];

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: kBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: kInfoBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                (name as String).substring(0, 1),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: kDeepBlue,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: kDeepBlue,
                  ),
                ),
                Text(
                  role,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: kTealGray,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 11,
                      color: kBlueGray,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      loc,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        color: kBlueGray,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Icon(
                      Icons.account_balance_wallet_outlined,
                      size: 11,
                      color: kBlueGray,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      salary != null ? '₹${salary.toString()}' : '—',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: kDeepBlue,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: kSuccessBg,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Active',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: kForest,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
