import 'package:flutter/material.dart';

import '../../models/leave_request.dart';
import '../../models/user_profile.dart';
import '../../services/firestore_service.dart';

class AdminLeaveScreen extends StatefulWidget {
  final UserProfile adminProfile;

  const AdminLeaveScreen({
    super.key,
    required this.adminProfile,
  });

  @override
  State<AdminLeaveScreen> createState() => _AdminLeaveScreenState();
}

class _AdminLeaveScreenState extends State<AdminLeaveScreen> {
  final _firestoreService = FirestoreService();
  final _searchController = TextEditingController();

  String _searchQuery = '';
  String _selectedStatusFilter = 'PENDING'; // Default to Pending for admin ease
  String _selectedTypeFilter = 'ALL';
  String _selectedDepartmentFilter = 'ALL';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _handleReview(LeaveRequest request, String newStatus) async {
    final commentController = TextEditingController();
    final isApproval = newStatus == 'APPROVED';

    final shouldProceed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isApproval ? 'Approve Leave Request?' : 'Reject Leave Request?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${request.employeeName} has requested ${request.totalDays} ${request.totalDays == 1 ? "day" : "days"} of ${request.displayLeaveType} (${request.formattedDateRange}).',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: commentController,
              decoration: InputDecoration(
                labelText: isApproval
                    ? 'Approval Note (Optional)'
                    : 'Rejection Reason (Optional)',
                hintText: isApproval
                    ? 'e.g. Approved. Please coordinate duties.'
                    : 'e.g. Insufficient coverage on that day.',
                border: const OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: isApproval ? Colors.green : Colors.red,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(isApproval ? 'Confirm Approval' : 'Confirm Rejection'),
          ),
        ],
      ),
    );

    if (shouldProceed != true) return;

    try {
      await _firestoreService.reviewLeaveRequest(
        requestId: request.id,
        status: newStatus,
        reviewedBy: widget.adminProfile.uid,
        reviewedByName: widget.adminProfile.name,
        reviewComment: commentController.text.trim(),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Leave request marked as $newStatus for ${request.employeeName}.',
          ),
          backgroundColor: isApproval ? Colors.green : Colors.orange.shade800,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update leave request: $e'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  List<LeaveRequest> _filterRequests(List<LeaveRequest> list) {
    return list.where((req) {
      // 1. Search Query
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchName = req.employeeName.toLowerCase().contains(query);
        final matchId = req.employeeId.toLowerCase().contains(query);
        final matchDept = req.department.toLowerCase().contains(query);
        final matchReason = req.reason.toLowerCase().contains(query);
        if (!matchName && !matchId && !matchDept && !matchReason) return false;
      }

      // 2. Status Filter
      if (_selectedStatusFilter != 'ALL') {
        if (req.status.toUpperCase() != _selectedStatusFilter) return false;
      }

      // 3. Type Filter
      if (_selectedTypeFilter != 'ALL') {
        if (req.leaveType.toUpperCase() != _selectedTypeFilter) return false;
      }

      // 4. Department Filter
      if (_selectedDepartmentFilter != 'ALL') {
        if (req.department.toLowerCase() !=
            _selectedDepartmentFilter.toLowerCase()) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Leave Management & Approvals'),
      ),
      body: StreamBuilder<List<LeaveRequest>>(
        stream: _firestoreService
            .streamCompanyLeaveRequests(widget.adminProfile.companyId),
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
          final filteredRequests = _filterRequests(allRequests);

          final pendingCount = allRequests.where((r) => r.isPending).length;
          final approvedCount = allRequests.where((r) => r.isApproved).length;
          final rejectedCount = allRequests.where((r) => r.isRejected).length;
          final totalCount = allRequests.length;

          return Column(
            children: [
              // Metrics Summary Header
              Container(
                padding: const EdgeInsets.all(16),
                color: theme.colorScheme.surface,
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _MetricTile(
                            label: 'Pending',
                            value: '$pendingCount',
                            color: Colors.orange,
                            icon: Icons.pending_actions,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _MetricTile(
                            label: 'Approved',
                            value: '$approvedCount',
                            color: Colors.green,
                            icon: Icons.check_circle_outline,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _MetricTile(
                            label: 'Rejected',
                            value: '$rejectedCount',
                            color: Colors.red,
                            icon: Icons.cancel_outlined,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _MetricTile(
                            label: 'Total',
                            value: '$totalCount',
                            color: Colors.blue,
                            icon: Icons.list_alt,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Search Bar
                    TextField(
                      controller: _searchController,
                      onChanged: (val) {
                        setState(() => _searchQuery = val.trim());
                      },
                      decoration: InputDecoration(
                        hintText: 'Search by employee name or reason...',
                        prefixIcon: const Icon(Icons.search, size: 20),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Horizontal Filter Chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildFilterChip(
                            'Pending ($pendingCount)',
                            'PENDING',
                            _selectedStatusFilter,
                            (v) => setState(() => _selectedStatusFilter = v),
                          ),
                          const SizedBox(width: 6),
                          _buildFilterChip(
                            'Approved ($approvedCount)',
                            'APPROVED',
                            _selectedStatusFilter,
                            (v) => setState(() => _selectedStatusFilter = v),
                          ),
                          const SizedBox(width: 6),
                          _buildFilterChip(
                            'Rejected ($rejectedCount)',
                            'REJECTED',
                            _selectedStatusFilter,
                            (v) => setState(() => _selectedStatusFilter = v),
                          ),
                          const SizedBox(width: 6),
                          _buildFilterChip(
                            'All Status',
                            'ALL',
                            _selectedStatusFilter,
                            (v) => setState(() => _selectedStatusFilter = v),
                          ),
                          const SizedBox(width: 12),
                          Container(
                              height: 18, width: 1, color: Colors.grey.shade300),
                          const SizedBox(width: 12),
                          _buildFilterChip(
                            'All Types',
                            'ALL',
                            _selectedTypeFilter,
                            (v) => setState(() => _selectedTypeFilter = v),
                          ),
                          const SizedBox(width: 6),
                          _buildFilterChip(
                            'Casual',
                            'CASUAL',
                            _selectedTypeFilter,
                            (v) => setState(() => _selectedTypeFilter = v),
                          ),
                          const SizedBox(width: 6),
                          _buildFilterChip(
                            'Sick',
                            'SICK',
                            _selectedTypeFilter,
                            (v) => setState(() => _selectedTypeFilter = v),
                          ),
                          const SizedBox(width: 6),
                          _buildFilterChip(
                            'Annual',
                            'ANNUAL',
                            _selectedTypeFilter,
                            (v) => setState(() => _selectedTypeFilter = v),
                          ),
                          const SizedBox(width: 12),
                          Container(
                              height: 18, width: 1, color: Colors.grey.shade300),
                          const SizedBox(width: 12),
                          _buildFilterChip(
                            'All Depts',
                            'ALL',
                            _selectedDepartmentFilter,
                            (v) => setState(() => _selectedDepartmentFilter = v),
                          ),
                          const SizedBox(width: 6),
                          _buildFilterChip(
                            'Software Engineering',
                            'Software Engineering',
                            _selectedDepartmentFilter,
                            (v) => setState(() => _selectedDepartmentFilter = v),
                          ),
                          const SizedBox(width: 6),
                          _buildFilterChip(
                            'Product & UI/UX',
                            'Product & UI/UX',
                            _selectedDepartmentFilter,
                            (v) => setState(() => _selectedDepartmentFilter = v),
                          ),
                          const SizedBox(width: 6),
                          _buildFilterChip(
                            'DevOps & Cloud',
                            'DevOps & Cloud',
                            _selectedDepartmentFilter,
                            (v) => setState(() => _selectedDepartmentFilter = v),
                          ),
                          const SizedBox(width: 6),
                          _buildFilterChip(
                            'Quality Assurance (QA)',
                            'Quality Assurance (QA)',
                            _selectedDepartmentFilter,
                            (v) => setState(() => _selectedDepartmentFilter = v),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // Request Cards List
              Expanded(
                child: allRequests.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.beach_access_outlined,
                                size: 64,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'No Leave Applications Found',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Leave applications submitted by team members will appear here for review.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        ),
                      )
                    : filteredRequests.isEmpty
                        ? Center(
                            child: Text(
                              'No leave requests matching your filters.',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: filteredRequests.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final req = filteredRequests[index];
                              return _AdminLeaveCard(
                                request: req,
                                onApprove: () =>
                                    _handleReview(req, 'APPROVED'),
                                onReject: () =>
                                    _handleReview(req, 'REJECTED'),
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

  Widget _buildFilterChip(
    String label,
    String value,
    String currentValue,
    Function(String) onSelected,
  ) {
    final isSelected = currentValue.toUpperCase() == value.toUpperCase();
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onSelected(value),
      visualDensity: VisualDensity.compact,
      labelStyle: TextStyle(
        fontSize: 11,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  final String label;
  final String value;
  final MaterialColor color;
  final IconData icon;

  const _MetricTile({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: BoxDecoration(
        color: color.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.shade200),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color.shade900,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            label,
            style: TextStyle(fontSize: 10, color: color.shade800),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _AdminLeaveCard extends StatelessWidget {
  final LeaveRequest request;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _AdminLeaveCard({
    required this.request,
    required this.onApprove,
    required this.onReject,
  });

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

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Employee Name & ID & Status
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor:
                      Theme.of(context).colorScheme.primaryContainer,
                  child: Text(
                    request.employeeName.isNotEmpty
                        ? request.employeeName[0].toUpperCase()
                        : 'E',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              request.employeeName,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (request.employeeId.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: Text(
                                request.employeeId,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontFamily: 'monospace',
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        request.department,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border:
                        Border.all(color: statusColor.withValues(alpha: 0.4)),
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
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),

            // Leave Info: Type & Dates
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Text(
                    request.displayLeaveType,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade900,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Icon(Icons.calendar_today, size: 14, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  request.formattedDateRange,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '(${request.totalDays} ${request.totalDays == 1 ? "day" : "days"})',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Reason
            Text(
              'Reason: ${request.reason}',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade800),
            ),

            // Remark if available
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

            // Action Buttons for PENDING
            if (request.isPending) ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red.shade700,
                        side: BorderSide(color: Colors.red.shade300),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      onPressed: onReject,
                      icon: const Icon(Icons.close_rounded, size: 18),
                      label: const Text('Reject'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.green.shade700,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      onPressed: onApprove,
                      icon: const Icon(Icons.check_rounded, size: 18),
                      label: const Text('Approve'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
