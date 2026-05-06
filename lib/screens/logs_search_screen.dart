// ============================================================
// screens/logs_search_screen.dart
// Check-in logs with real-time search by name or ID
// ============================================================
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/event_provider.dart';
import '../providers/check_in_provider.dart';
import '../models/check_in_log_model.dart';
import '../utils/app_theme.dart';

class LogsSearchScreen extends StatefulWidget {
  const LogsSearchScreen({super.key});

  @override
  State<LogsSearchScreen> createState() => _LogsSearchScreenState();
}

class _LogsSearchScreenState extends State<LogsSearchScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _searchCtrl.addListener(() => setState(() => _query = _searchCtrl.text));
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<EventProvider, CheckInProvider>(
      builder: (context, eventProv, checkInProv, _) {
        final event = eventProv.selectedEvent;

        if (event == null) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.event_busy, size: 64, color: Colors.grey),
                SizedBox(height: 12),
                Text('No event selected.',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600)),
                SizedBox(height: 6),
                Text('Create or select an event first.',
                    style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }

        final logs = checkInProv.getLogsForEvent(event.id);
        final participants = _query.trim().isEmpty
            ? checkInProv.getParticipantsForEvent(event.id)
            : checkInProv.search(event.id, _query);

        return Column(
          children: [
            // Search Area
            Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: TextField(
                controller: _searchCtrl,
                decoration: InputDecoration(
                  hintText: 'Search by name or ID…',
                  prefixIcon: const Icon(Icons.search, color: AppTheme.primaryColor),
                  suffixIcon: _query.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () => _searchCtrl.clear(),
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
            ),

            // Premium Tabs
            Container(
              color: Colors.white,
              child: TabBar(
                controller: _tabController,
                labelColor: AppTheme.primaryColor,
                unselectedLabelColor: Colors.grey,
                indicatorWeight: 3,
                indicatorPadding: const EdgeInsets.symmetric(horizontal: 16),
                tabs: [
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.history, size: 16),
                        const SizedBox(width: 8),
                        Text('LOGS (${logs.length})', style: const TextStyle(fontWeight: FontWeight.w900)),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.people_alt_outlined, size: 16),
                        const SizedBox(width: 8),
                        Text('LIST (${participants.length})', style: const TextStyle(fontWeight: FontWeight.w900)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // ---- Logs Tab ----
                  logs.isEmpty
                      ? _buildEmpty('No check-ins recorded yet.')
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          itemCount: logs.length,
                          itemBuilder: (_, i) =>
                              _LogTile(log: logs[i]),
                        ),

                  // ---- Participants Tab ----
                  participants.isEmpty
                      ? _buildEmpty('No participants found.')
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          itemCount: participants.length,
                          itemBuilder: (_, i) {
                            final p = participants[i];
                            final log = logs
                                .where((l) =>
                                    l.participantId == p.id)
                                .toList();
                            final checkInTime = log.isNotEmpty
                                ? DateFormat('hh:mm a')
                                    .format(log.first.timestamp)
                                : null;

                            return Card(
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                leading: CircleAvatar(
                                  radius: 24,
                                  backgroundColor: p.isCheckedIn
                                      ? AppTheme.successColor.withOpacity(0.1)
                                      : Colors.grey.withOpacity(0.05),
                                  child: Icon(
                                    p.isCheckedIn
                                        ? Icons.how_to_reg
                                        : Icons.person_outline,
                                    color: p.isCheckedIn
                                        ? AppTheme.successColor
                                        : Colors.grey.shade400,
                                  ),
                                ),
                                title: Text(p.name,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w900,
                                        fontSize: 16)),
                                subtitle: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text('ID: ${p.id}',
                                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
                                    if (checkInTime != null)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 4.0),
                                        child: Text('Entered at $checkInTime',
                                            style: const TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w800,
                                                color: AppTheme.successColor)),
                                      ),
                                  ],
                                ),
                                trailing: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: p.isCheckedIn
                                        ? AppTheme.successColor.withOpacity(0.12)
                                        : Colors.grey.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(100),
                                  ),
                                  child: Text(
                                    p.isCheckedIn ? 'CHECKED' : 'PENDING',
                                    style: TextStyle(
                                      color: p.isCheckedIn
                                          ? AppTheme.successColor
                                          : Colors.grey.shade600,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEmpty(String msg) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text(msg, style: TextStyle(color: Colors.grey.shade600)),
        ],
      ),
    );
  }
}

class _LogTile extends StatelessWidget {
  final CheckInLogModel log;

  const _LogTile({required this.log});

  @override
  Widget build(BuildContext context) {
    final isQR = log.method == CheckInMethod.qr;
    final formattedTime =
        DateFormat('dd MMM yyyy  hh:mm a').format(log.timestamp);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppTheme.successColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            isQR ? Icons.qr_code_scanner : Icons.keyboard_alt_outlined,
            color: AppTheme.successColor,
            size: 20,
          ),
        ),
        title: Text(
          log.participantName,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ID: ${log.participantId}',
                style: const TextStyle(fontSize: 12)),
            Text(formattedTime,
                style:
                    TextStyle(fontSize: 11, color: Colors.grey.shade500)),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: (isQR ? AppTheme.primaryColor : AppTheme.secondaryColor)
                    .withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                isQR ? 'QR' : 'Manual',
                style: TextStyle(
                  color:
                      isQR ? AppTheme.primaryColor : AppTheme.secondaryColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Icon(
              log.isSynced ? Icons.cloud_done : Icons.cloud_upload_outlined,
              size: 14,
              color: log.isSynced ? AppTheme.successColor : Colors.grey,
            ),
          ],
        ),
      ),
    );
  }
}
