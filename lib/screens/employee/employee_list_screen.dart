import 'package:flutter/material.dart';

import '../../models/user_profile.dart';
import '../../services/firestore_service.dart';
import '../../utils/team_scope.dart';
import 'add_employee_screen.dart';
import 'employee_detail_screen.dart';
import '../../widgets/user_avatar.dart';

class EmployeeListScreen extends StatefulWidget {
  final UserProfile adminProfile;
  final bool teamScoped;
  final bool embedded;

  const EmployeeListScreen({
    super.key,
    required this.adminProfile,
    this.teamScoped = false,
    this.embedded = false,
  });

  @override
  State<EmployeeListScreen> createState() => _EmployeeListScreenState();
}

class _EmployeeListScreenState extends State<EmployeeListScreen> {
  final _firestoreService = FirestoreService();
  final _searchController = TextEditingController();

  String _searchQuery = '';
  String _selectedStatusFilter = 'ALL';
  String _selectedDepartmentFilter = 'ALL';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<UserProfile> _filterEmployees(List<UserProfile> list) {
    return list.where((emp) {
      // 1. Search Query Filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchName = emp.name.toLowerCase().contains(query);
        final matchEmail = emp.email.toLowerCase().contains(query);
        final matchId = emp.employeeId.toLowerCase().contains(query);
        final matchDept = emp.department.toLowerCase().contains(query);
        final matchDesig = emp.designation.toLowerCase().contains(query);
        if (!matchName && !matchEmail && !matchId && !matchDept && !matchDesig) {
          return false;
        }
      }

      // 2. Status Filter
      if (_selectedStatusFilter != 'ALL') {
        if (emp.status.toUpperCase() != _selectedStatusFilter) {
          return false;
        }
      }

      // 3. Department Filter
      if (_selectedDepartmentFilter != 'ALL') {
        if (emp.department.toLowerCase() !=
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

    final canAdd = widget.adminProfile.isPeopleOps;

    void openAddEmployee() {
      Navigator.of(context, rootNavigator: true).push(
        MaterialPageRoute(
          builder: (_) => AddEmployeeScreen(
            adminProfile: widget.adminProfile,
          ),
        ),
      );
    }
    return Scaffold(
      appBar: widget.embedded
          ? null
          : AppBar(
        title: Text(widget.teamScoped ? 'My Team' : 'Employees Directory'),
        actions: [
          if (canAdd)
          IconButton(
            tooltip: 'Add Employee',
            icon: const Icon(Icons.person_add_alt_1),
            onPressed: openAddEmployee,
          ),
        ],
      ),
      floatingActionButton: canAdd
          ? FloatingActionButton.extended(
        onPressed: openAddEmployee,
        icon: const Icon(Icons.add),
        label: const Text('Add Employee'),
      )
          : null,
      body: Column(
        children: [
          // Search & Filters Header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            color: theme.colorScheme.surface,
            child: Column(
              children: [
                // Search Bar
                TextField(
                  controller: _searchController,
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val.trim();
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Search by name, ID, department...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
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
                      // Status Filters
                      _buildFilterChip('All Status', 'ALL', _selectedStatusFilter,
                          (v) => setState(() => _selectedStatusFilter = v)),
                      const SizedBox(width: 8),
                      _buildFilterChip('Active', 'ACTIVE', _selectedStatusFilter,
                          (v) => setState(() => _selectedStatusFilter = v)),
                      const SizedBox(width: 8),
                      _buildFilterChip('Suspended', 'SUSPENDED',
                          _selectedStatusFilter,
                          (v) => setState(() => _selectedStatusFilter = v)),
                      const SizedBox(width: 16),
                      Container(height: 20, width: 1, color: Colors.grey.shade300),
                      const SizedBox(width: 16),

                      // Department Filters
                      _buildFilterChip('All Depts', 'ALL',
                          _selectedDepartmentFilter,
                          (v) => setState(() => _selectedDepartmentFilter = v)),
                      const SizedBox(width: 8),
                      _buildFilterChip('Software Engineering',
                          'Software Engineering', _selectedDepartmentFilter,
                          (v) => setState(() => _selectedDepartmentFilter = v)),
                      const SizedBox(width: 8),
                      _buildFilterChip('Product & UI/UX', 'Product & UI/UX',
                          _selectedDepartmentFilter,
                          (v) => setState(() => _selectedDepartmentFilter = v)),
                      const SizedBox(width: 8),
                      _buildFilterChip('DevOps & Cloud', 'DevOps & Cloud',
                          _selectedDepartmentFilter,
                          (v) => setState(() => _selectedDepartmentFilter = v)),
                      const SizedBox(width: 8),
                      _buildFilterChip('Quality Assurance (QA)',
                          'Quality Assurance (QA)', _selectedDepartmentFilter,
                          (v) => setState(() => _selectedDepartmentFilter = v)),
                      const SizedBox(width: 8),
                      _buildFilterChip('IT Support & Security',
                          'IT Support & Security', _selectedDepartmentFilter,
                          (v) => setState(() => _selectedDepartmentFilter = v)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Employee List from Firestore Stream
          Expanded(
            child: StreamBuilder<List<UserProfile>>(
              stream: _firestoreService.streamCompanyEmployees(
                widget.adminProfile.companyId,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline,
                              size: 48, color: Colors.red),
                          const SizedBox(height: 12),
                          Text('Failed to load employees: ${snapshot.error}'),
                        ],
                      ),
                    ),
                  );
                }

                final scoped = widget.teamScoped
                    ? TeamScope.reportsFor(widget.adminProfile, snapshot.data ?? [])
                    : (snapshot.data ?? []);
                final employees = _filterEmployees(scoped);

                if (scoped.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.people_outline_rounded,
                            size: 72,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No Employees Registered Yet',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tap the button below to onboard your first team member.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                          const SizedBox(height: 24),
                          FilledButton.icon(
                            onPressed: openAddEmployee,
                            icon: const Icon(Icons.person_add_alt_1),
                            label: const Text('Add Employee'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                if (employees.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off_rounded,
                            size: 48, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        const Text(
                          'No matching employees found.',
                          style: TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                              _selectedStatusFilter = 'ALL';
                              _selectedDepartmentFilter = 'ALL';
                            });
                          },
                          child: const Text('Clear Filters'),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
                  itemCount: employees.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final emp = employees[index];
                    return _EmployeeCard(
                      employee: emp,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                EmployeeDetailScreen(employee: emp),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
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
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }
}

class _EmployeeCard extends StatelessWidget {
  final UserProfile employee;
  final VoidCallback onTap;

  const _EmployeeCard({
    required this.employee,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isActive = employee.isActive;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              UserAvatar(
                avatarUrl: employee.avatarUrl,
                name: employee.name,
                radius: 24,
                backgroundColor: isActive
                    ? theme.colorScheme.primaryContainer
                    : Colors.red.shade100,
                textColor: isActive
                    ? theme.colorScheme.primary
                    : Colors.red.shade800,
                fontSize: 20,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            employee.name,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (employee.employeeId.isNotEmpty) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Text(
                              employee.employeeId,
                              style: const TextStyle(
                                fontSize: 10,
                                fontFamily: 'monospace',
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                        ],
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isActive ? Colors.green : Colors.red,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${employee.designation} • ${employee.department}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      employee.email,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
