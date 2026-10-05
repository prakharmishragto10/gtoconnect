import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/colors.dart';
import '../../services/travel_service.dart';

class AdminTravelScreen extends StatefulWidget {
  const AdminTravelScreen({super.key});

  @override
  State<AdminTravelScreen> createState() => _AdminTravelScreenState();
}

class _AdminTravelScreenState extends State<AdminTravelScreen> {
  bool _loading = true;
  String? _error;

  // Filter: all | pending | approved | rejected
  String _filter = 'all';

  List<Map<String, dynamic>> _all = [];

  static const _monthNames = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await TravelService.getAllRequests();
      if (mounted) setState(() { _all = data; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  List<Map<String, dynamic>> get _filtered {
    if (_filter == 'all') return _all;
    return _all.where((r) => r['status'] == _filter).toList();
  }

  String _fmtDate(String iso) {
    final dt = DateTime.tryParse(iso);
    if (dt == null) return iso;
    return '${dt.day} ${_monthNames[dt.month - 1]} ${dt.year}';
  }

  Future<void> _updateStatus(Map<String, dynamic> req, String status) async {
    final id = req['id'].toString();
    final name = (req['users'] as Map?)?['name'] ?? 'this employee';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text(
          '${status == 'approved' ? 'Approve' : 'Reject'} Request?',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            color: kDeepBlue,
            fontSize: 16,
          ),
        ),
        content: Text(
          'Are you sure you want to ${status == 'approved' ? 'approve' : 'reject'} '
          "the travel request from $name?",
          style: GoogleFonts.plusJakartaSans(fontSize: 13, color: kTealGray),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.plusJakartaSans(color: kBlueGray),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  status == 'approved' ? kForest : kDanger,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              status == 'approved' ? 'Approve' : 'Reject',
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await TravelService.updateStatus(id, status);
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Request ${status == 'approved' ? 'approved' : 'rejected'}'),
            backgroundColor: status == 'approved' ? kForest : kDanger,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: kDanger),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final pending = _all.where((r) => r['status'] == 'pending').length;

    return RefreshIndicator(
      color: kDeepBlue,
      onRefresh: _load,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Travel Requests',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: kDeepBlue,
                            ),
                          ),
                          Text(
                            'Review & approve employee travel',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: kTealGray,
                            ),
                          ),
                        ],
                      ),
                      if (pending > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: kWarnBg,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.schedule,
                                size: 13,
                                color: kWarn,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '$pending Pending',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: kWarn,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Filter chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _chip('all', 'All'),
                        const SizedBox(width: 8),
                        _chip('pending', 'Pending'),
                        const SizedBox(width: 8),
                        _chip('approved', 'Approved'),
                        const SizedBox(width: 8),
                        _chip('rejected', 'Rejected'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),

          // Body
          if (_loading)
            const SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(color: kDeepBlue),
              ),
            )
          else if (_error != null)
            SliverFillRemaining(
              child: Center(
                child: Text(
                  _error!,
                  style: GoogleFonts.plusJakartaSans(color: kDanger),
                ),
              ),
            )
          else if (_filtered.isEmpty)
            SliverFillRemaining(child: _emptyState())
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) => Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: _buildCard(_filtered[i]),
                ),
                childCount: _filtered.length,
              ),
            ),
        ],
      ),
    );
  }

  Widget _chip(String value, String label) {
    final active = _filter == value;
    return GestureDetector(
      onTap: () => setState(() => _filter = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: active ? kDeepBlue : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: active ? kDeepBlue : kBorder),
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: active ? Colors.white : kTealGray,
          ),
        ),
      ),
    );
  }

  Widget _buildCard(Map<String, dynamic> req) {
    final status = req['status'] as String? ?? 'pending';
    final isPending = status == 'pending';
    final place = req['place'] as String? ?? '—';
    final work = req['work'] as String? ?? '—';
    final reason = req['reason'] as String? ?? '—';
    final start = req['start_date'] as String? ?? '';
    final end = req['end_date'] as String? ?? '';
    final user = req['users'] as Map?;
    final empName = user?['name'] as String? ?? 'Unknown';
    final empEmail = user?['email'] as String? ?? '';
    final created = req['created_at'] as String? ?? '';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Employee + status
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: kInfoBg,
                child: Text(
                  empName.isNotEmpty ? empName[0].toUpperCase() : '?',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: kDeepBlue,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      empName,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: kDeepBlue,
                      ),
                    ),
                    if (empEmail.isNotEmpty)
                      Text(
                        empEmail,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: kBlueGray,
                        ),
                      ),
                  ],
                ),
              ),
              TravelStatusBadge(status),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: kBorder),
          const SizedBox(height: 12),

          _infoRow(
            Icons.event_outlined,
            'Travel Date',
            start.isNotEmpty ? _fmtDate(start) : '—',
          ),
          const SizedBox(height: 6),
          _infoRow(
            Icons.date_range_outlined,
            'Period',
            (start.isNotEmpty && end.isNotEmpty)
                ? '${_fmtDate(start)} → ${_fmtDate(end)}'
                : '—',
          ),
          const SizedBox(height: 6),
          _infoRow(Icons.place_outlined, 'Place', place),
          const SizedBox(height: 6),
          _infoRow(Icons.work_outline, 'Work', work),
          const SizedBox(height: 6),
          _infoRow(Icons.info_outline, 'Reason', reason),
          if (created.isNotEmpty) ...[
            const SizedBox(height: 6),
            _infoRow(
              Icons.schedule,
              'Submitted',
              _fmtDate(
                created.length > 10 ? created.substring(0, 10) : created,
              ),
            ),
          ],

          // Action buttons (only for pending)
          if (isPending) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _updateStatus(req, 'rejected'),
                    icon: const Icon(
                      Icons.close,
                      size: 14,
                      color: kDanger,
                    ),
                    label: Text(
                      'Reject',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: kDanger,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: kDanger),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(9),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _updateStatus(req, 'approved'),
                    icon: const Icon(
                      Icons.check,
                      size: 14,
                      color: Colors.white,
                    ),
                    label: Text(
                      'Approve',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kForest,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(9),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: kBlueGray),
          const SizedBox(width: 6),
          Text(
            '$label: ',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: kBlueGray,
              fontWeight: FontWeight.w500,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: kDeepBlue,
              ),
            ),
          ),
        ],
      );

  Widget _emptyState() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.flight_outlined, size: 52, color: kBorder),
            const SizedBox(height: 14),
            Text(
              'No travel requests',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                color: kBlueGray,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _filter == 'all'
                  ? 'Employees haven\'t submitted any yet'
                  : 'No $_filter requests found',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: kBlueGray,
              ),
            ),
          ],
        ),
      );
}
