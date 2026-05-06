// ============================================================
// screens/dashboard_screen.dart
// Main app shell with bottom navigation bar (4 screens)
// ============================================================
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/event_provider.dart';
import '../providers/check_in_provider.dart';
import '../providers/dashboard_provider.dart';
import '../widgets/capacity_indicator.dart';
import '../widgets/stat_card.dart';
import '../utils/app_theme.dart';
import '../services/sync_service.dart';
import 'event_setup_screen.dart';
import 'check_in_screen.dart';
import 'logs_search_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    // Start background sync
    SyncService.startPeriodicSync();
    // Initial dashboard refresh
    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshDashboard());
  }

  @override
  void dispose() {
    SyncService.stopSync();
    super.dispose();
  }

  void _refreshDashboard() {
    final eventProvider = context.read<EventProvider>();
    final dashProv = context.read<DashboardProvider>();
    if (eventProvider.selectedEvent != null) {
      dashProv.refresh(eventProvider.selectedEvent!);
    }
  }

  Widget _buildDashboardContent() {
    return Consumer3<EventProvider, CheckInProvider, DashboardProvider>(
      builder: (context, eventProv, checkInProv, dashProv, _) {
        final event = eventProv.selectedEvent;

        if (event == null) {
          return _buildEmptyState(context);
        }

        // Keep dashboard in sync
        WidgetsBinding.instance.addPostFrameCallback((_) {
          dashProv.refresh(event);
        });

        return RefreshIndicator(
          onRefresh: () async => dashProv.refresh(event),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // --- Premium Header ---
                Stack(
                  children: [
                    Container(
                      height: 140,
                      decoration: const BoxDecoration(
                        color: AppTheme.primaryColor,
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(32),
                          bottomRight: Radius.circular(32),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('WELCOME BACK',
                              style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 2)),
                          const SizedBox(height: 4),
                          const Text('Event Dashboard',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -1)),
                          const SizedBox(height: 24),
                          // Active Event Card
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: const Icon(Icons.event_available, color: AppTheme.primaryColor),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(event.name,
                                          style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w800,
                                              color: AppTheme.primaryColor)),
                                      Text(_formatDateTime(event.dateTime),
                                          style: TextStyle(
                                              fontSize: 13, color: Colors.grey.shade600)),
                                    ],
                                  ),
                                ),
                                if (eventProv.events.length > 1)
                                  IconButton(
                                    onPressed: () => _showEventSelector(context, eventProv),
                                    icon: const Icon(Icons.swap_horiz, color: AppTheme.primaryColor),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // --- Live Tracking Card ---
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Live Tracking',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                              Icon(Icons.radar, color: AppTheme.successColor, size: 18),
                            ],
                          ),
                          const SizedBox(height: 24),
                          CapacityIndicator(
                            checkedIn: dashProv.checkedIn,
                            maxCapacity: dashProv.maxCapacity,
                            status: dashProv.crowdStatus,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // --- Metrics Grid ---
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        childAspectRatio: 1.5,
                        mainAxisSpacing: 0,
                        crossAxisSpacing: 0,
                        children: [
                          StatCard(
                            label: 'Registered',
                            value: '${dashProv.totalParticipants}',
                            icon: Icons.people_outline,
                            color: AppTheme.primaryColor,
                          ),
                          StatCard(
                            label: 'Checked In',
                            value: '${dashProv.checkedIn}',
                            icon: Icons.check_circle_outline,
                            color: AppTheme.successColor,
                          ),
                          StatCard(
                            label: 'Available',
                            value: '${dashProv.remaining}',
                            icon: Icons.event_seat_outlined,
                            color: AppTheme.warningColor,
                          ),
                          StatCard(
                            label: 'Capacity',
                            value: '${dashProv.maxCapacity}',
                            icon: Icons.groups_outlined,
                            color: AppTheme.secondaryColor,
                          ),
                        ],
                      );
                    },
                  ),
                ),

                const SizedBox(height: 16),

                // --- Action Button ---
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: ElevatedButton.icon(
                    onPressed: () => setState(() => _selectedIndex = 2),
                    icon: const Icon(Icons.qr_code_scanner),
                    label: const Text('Open Scanner'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_busy, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          const Text('No events yet.',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          const Text('Create your first event to get started.',
              style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Create Event'),
            onPressed: () => setState(() => _selectedIndex = 1),
          ),
        ],
      ),
    );
  }

  void _showEventSelector(BuildContext context, EventProvider provider) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => ListView.builder(
        shrinkWrap: true,
        itemCount: provider.events.length,
        itemBuilder: (_, i) {
          final e = provider.events[i];
          final isSelected = provider.selectedEvent?.id == e.id;
          return ListTile(
            title: Text(e.name, style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(_formatDateTime(e.dateTime)),
            leading: Icon(Icons.event,
                color: isSelected ? AppTheme.primaryColor : Colors.grey),
            trailing: isSelected
                ? const Icon(Icons.check, color: AppTheme.primaryColor)
                : null,
            onTap: () {
              provider.selectEvent(e);
              _refreshDashboard();
              Navigator.pop(context);
            },
          );
        },
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final h = dt.hour > 12 ? dt.hour - 12 : dt.hour == 0 ? 12 : dt.hour;
    final m = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}  •  $h:$m $ampm';
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      _buildDashboardContent(),
      const EventSetupScreen(),
      const CheckInScreen(),
      const LogsSearchScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Event Check-in'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () {},
            tooltip: 'Notifications',
          ),
        ],
      ),
      body: IndexedStack(index: _selectedIndex, children: screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (i) {
          setState(() => _selectedIndex = i);
          if (i == 0) _refreshDashboard();
        },
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard),
              label: 'Dashboard'),
          BottomNavigationBarItem(
              icon: Icon(Icons.event_outlined),
              activeIcon: Icon(Icons.event),
              label: 'Event'),
          BottomNavigationBarItem(
              icon: Icon(Icons.qr_code_scanner_outlined),
              activeIcon: Icon(Icons.qr_code_scanner),
              label: 'Check-in'),
          BottomNavigationBarItem(
              icon: Icon(Icons.list_alt_outlined),
              activeIcon: Icon(Icons.list_alt),
              label: 'Logs'),
        ],
      ),
    );
  }
}
