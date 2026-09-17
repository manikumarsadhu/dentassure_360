import 'package:flutter/material.dart';

import '../../models/leave_balance.dart';
import '../../models/leave_request.dart';
import '../../models/user_profile.dart';
import '../../services/firestore_service.dart';
import 'apply_leave_screen.dart';
import '../../theme/app_motion.dart';

class EmployeeLeaveScreen extends StatefulWidget {
  final UserProfile employee;

  const EmployeeLeaveScreen({super.key, required this.employee});

  @override
  State<EmployeeLeaveScreen> createState() => _EmployeeLeaveScreenState();
}

class _EmployeeLeaveScreenState extends State<EmployeeLeaveScreen> {
  final _firestoreService = FirestoreService();
  String _selectedFilter = 'ALL';

  List<LeaveRequest> _filterRequests(List<LeaveRequest> list) {
    if (_selectedFilter == 'ALL') return list;
    return list
        .where((r) => r.status.toUpperCase() == _selectedFilter.toUpperCase())
        .toList();
  }

  Future<void> _cancelRequest(LeaveRequest request) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Leave Request?'),
        content: const Text(
          'Are you sure you want to withdraw this pending leave application?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _firestoreService.cancelLeaveRequest(request.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Leave request cancelled.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to cancel: $e'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('My Leave Management')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Open Apply Leave
          _openApplyLeave(const LeaveBalance());
        },
        icon: const Icon(Icons.add),
        label: const Text('Apply Leave'),
      ),
      body: StreamBuilder<List<LeaveRequest>>(
        stream: _firestoreService.streamEmployeeLeaveRequests(
          widget.employee.uid,
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text('Failed to load leaves: ${snapshot.error}'),
              ),
            );
          }

          final allRequests = snapshot.data ?? [];
          final balance = LeaveBalance.fromApprovedRequests(allRequests);
          final filteredRequests = _filterRequests(allRequests);

          return Column(
            children: [
              // Available Leave Balance Section
              Container(
                padding: const EdgeInsets.all(16),
                color: theme.colorScheme.surface,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Available Leave Quota',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _BalanceCard(
                            label: 'Casual',
                            available: balance.availableCasual,
                            total: balance.totalCasual,
                            color: Colors.blue,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _BalanceCard(
                            label: 'Sick',
                            available: balance.availableSick,
                            total: balance.totalSick,
                            color: Colors.orange,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _BalanceCard(
                            label: 'Annual',
                            available: balance.availableAnnual,
                            total: balance.totalAnnual,
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _BalanceCard(
                            label: 'Unpaid',
                            available: balance.usedUnpaid,
                            total: balance.usedUnpaid,
                            isUnlimited: true,
                            color: Colors.purple,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Filter Chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildFilterChip('All Requests', 'ALL'),
                          const SizedBox(width: 6),
                          _buildFilterChip('Pending', 'PENDING'),
                          const SizedBox(width: 6),
                          _buildFilterChip('Approved', 'APPROVED'),
                          const SizedBox(width: 6),
                          _buildFilterChip('Rejected', 'REJECTED'),
                          const SizedBox(width: 6),
                          _buildFilterChip('Cancelled', 'CANCELLED'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // Requests List
              Expanded(
                child: allRequests.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.event_available_outlined,
                                size: 64,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'No Leave Applications Yet',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Need time off? Tap Apply Leave to submit a request to your manager.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey.shade600),
                              ),
                              const SizedBox(height: 20),
                              FilledButton.icon(
                                onPressed: () => _openApplyLeave(balance),
                                icon: const Icon(Icons.add),
                                label: const Text('Apply Leave'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : filteredRequests.isEmpty
                    ? Center(
                        child: Text(
                          'No leave requests matching "$_selectedFilter"',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
                        itemCount: filteredRequests.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final req = filteredRequests[index];
                          return _LeaveRequestCard(
                            request: req,
                            onCancel: () => _cancelRequest(req),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _openApplyLeave(LeaveBalance balance) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ApplyLeaveScreen(
          employee: widget.employee,
          currentBalance: balance,
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String statusKey) {
    final isSelected = _selectedFilter == statusKey;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => _selectedFilter = statusKey),
      visualDensity: VisualDensity.compact,
      labelStyle: TextStyle(
        fontSize: 11,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  final String label;
  final int available;
  final int total;
  final bool isUnlimited;
  final MaterialColor color;

  const _BalanceCard({
    required this.label,
    required this.available,
    required this.total,
    this.isUnlimited = false,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      decoration: BoxDecoration(
        color: color.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.shade200),
      ),
      child: Column(
        children: [
          Text(
            isUnlimited ? '$available used' : '$available left',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: color.shade900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: color.shade800,
            ),
          ),
          if (!isUnlimited)
            Text(
              'of $total total',
              style: TextStyle(fontSize: 9, color: Colors.grey.shade600),
            ),
        ],
      ),
    );
  }
}

class _LeaveRequestCard extends StatelessWidget {
  final LeaveRequest request;
  final VoidCallback onCancel;

  const _LeaveRequestCard({required this.request, required this.onCancel});

  Color _getStatusColor() {
    switch (request.status.toUpperCase()) {
      case 'APPROVED':
        return Colors.green;
      case 'PENDING':
        return Colors.orange;
      case 'REJECTED':
        return Colors.red;
      case 'CANCELLED':
        return Colors.grey;
      default:
        return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor();

    return MotionCard(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row: Type and Status Badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          request.displayLeaveType,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context)
                                .colorScheme
                                .onPrimaryContainer,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${request.totalDays} ${request.totalDays == 1 ? "day" : "days"}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: statusColor.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Text(
                      request.status,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Date Range
              Row(
                children: [
                  const Icon(Icons.date_range, size: 16, color: Colors.grey),
                  const SizedBox(width: 6),
                  Text(
                    request.formattedDateRange,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Reason Text
              Text(
                request.reason,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade800),
              ),

              // Reviewer comments if reviewed
              if (request.reviewComment != null &&
                  request.reviewComment!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Remark by ${request.reviewedByName ?? "Admin"}: "${request.reviewComment}"',
                    style: TextStyle(
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                      color: Colors.grey.shade800,
                    ),
                  ),
                ),
              ],

              // Cancel button if pending
              if (request.isPending) ...[
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red.shade700,
                      visualDensity: VisualDensity.compact,
                    ),
                    onPressed: onCancel,
                    icon: const Icon(Icons.cancel_outlined, size: 16),
                    label: const Text('Cancel Request'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
