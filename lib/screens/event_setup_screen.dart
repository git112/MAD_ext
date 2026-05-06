// ============================================================
// screens/event_setup_screen.dart
// Create / view / delete events
// ============================================================
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/event_provider.dart';
import '../providers/check_in_provider.dart';
import '../providers/dashboard_provider.dart';
import '../services/hive_service.dart';
import '../utils/app_theme.dart';
import '../utils/validators.dart';
import '../models/event_model.dart';

class EventSetupScreen extends StatefulWidget {
  const EventSetupScreen({super.key});

  @override
  State<EventSetupScreen> createState() => _EventSetupScreenState();
}

class _EventSetupScreenState extends State<EventSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _capacityCtrl = TextEditingController();
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 7));
  TimeOfDay _selectedTime = const TimeOfDay(hour: 9, minute: 0);
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _capacityCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    final eventDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    final eventProv = context.read<EventProvider>();
    final dashProv = context.read<DashboardProvider>();

    await eventProv.createEvent(
      name: _nameCtrl.text.trim(),
      dateTime: eventDateTime,
      maxCapacity: int.parse(_capacityCtrl.text.trim()),
      description: _descCtrl.text.trim(),
    );

    if (mounted) {
      final event = eventProv.selectedEvent;
      if (event != null) {
        dashProv.refresh(event);
      }
    }

    _nameCtrl.clear();
    _descCtrl.clear();
    _capacityCtrl.clear();

    setState(() => _isSubmitting = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✓ Event created successfully!'),
          backgroundColor: AppTheme.successColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // --- Premium Setup Header ---
          Container(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(bottomLeft: Radius.circular(32), bottomRight: Radius.circular(32)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('EVENT CONFIGURATION',
                    style: TextStyle(
                        color: AppTheme.primaryColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2)),
                const SizedBox(height: 8),
                const Text('Create New Event',
                    style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1)),
                const SizedBox(height: 24),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _nameCtrl,
                        validator: Validators.eventName,
                        decoration: const InputDecoration(
                          labelText: 'Event Name',
                          prefixIcon: Icon(Icons.drive_file_rename_outline),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _capacityCtrl,
                        validator: Validators.capacity,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Max Capacity',
                          prefixIcon: Icon(Icons.people_alt_outlined),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.calendar_today, size: 18),
                              label: Text(_formatDate(_selectedDate)),
                              onPressed: _pickDate,
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: Colors.grey.shade300),
                                padding: const EdgeInsets.symmetric(vertical: 18),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.schedule, size: 18),
                              label: Text(_selectedTime.format(context)),
                              onPressed: _pickTime,
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: Colors.grey.shade300),
                                padding: const EdgeInsets.symmetric(vertical: 18),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: _isSubmitting
                              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Icon(Icons.add_circle_outline),
                          label: Text(_isSubmitting ? 'CREATING...' : 'CREATE EVENT'),
                          onPressed: _isSubmitting ? null : _submit,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // --- Existing Events Section ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                const Text('RECENT EVENTS',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1)),
                const Spacer(),
                Consumer<EventProvider>(builder: (context, p, _) => Text('${p.events.length} total', style: const TextStyle(fontSize: 11, color: Colors.grey))),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const SizedBox(height: 32),
          const Divider(),
          const SizedBox(height: 12),

          // ---- Events List ----
          Text('Existing Events',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Consumer<EventProvider>(
            builder: (context, provider, _) {
              if (provider.events.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: Text('No events created yet.',
                        style: TextStyle(color: Colors.grey.shade500)),
                  ),
                );
              }
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: provider.events.length,
                itemBuilder: (_, i) {
                  final event = provider.events[i];
                  final isSelected = provider.selectedEvent?.id == event.id;
                  return _EventCard(
                    event: event,
                    isSelected: isSelected,
                    onSelect: () {
                      provider.selectEvent(event);
                      context.read<DashboardProvider>().refresh(event);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text('Active: ${event.name}'),
                        behavior: SnackBarBehavior.floating,
                      ));
                    },
                    onDelete: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text('Delete Event'),
                          content: Text(
                              'Delete "${event.name}"? This cannot be undone.'),
                          actions: [
                            TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Cancel')),
                            TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('Delete',
                                    style:
                                        TextStyle(color: AppTheme.dangerColor))),
                          ],
                        ),
                      );
                      if (confirm == true && context.mounted) {
                        await context
                            .read<EventProvider>()
                            .deleteEvent(event.id);
                      }
                    },
                  );
                },
              );
            },
          ),
          const SizedBox(height: 48),
          const Divider(),
          const SizedBox(height: 16),
          _buildDangerZone(),
        ],
      ),
    );
  }

  Widget _buildDangerZone() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Danger Zone',
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.dangerColor)),
        const SizedBox(height: 8),
        Text(
          'Use these tools to reset your test data. Warning: This cannot be undone.',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          icon: const Icon(Icons.delete_forever),
          label: const Text('Hard Reset: Clear All Data'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppTheme.dangerColor,
            side: const BorderSide(color: AppTheme.dangerColor),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          onPressed: () async {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (_) => AlertDialog(
                title: const Text('Confirm Hard Reset'),
                content: const Text(
                    'This will PERMANENTLY delete all events, participants, and check-in logs. Are you sure?'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel')),
                  TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('RESET EVERYTHING',
                          style: TextStyle(color: AppTheme.dangerColor))),
                ],
              ),
            );

            if (confirm == true && mounted) {
              await HiveService.clearAllData();
              // Refresh state
              if (mounted) {
                context.read<EventProvider>().loadEvents();
                context.read<CheckInProvider>().loadData();
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Database wiped clean!'),
                    backgroundColor: Colors.black));
              }
            }
          },
        ),
      ],
    );
  }
}

class _EventCard extends StatelessWidget {
  final EventModel event;
  final bool isSelected;
  final VoidCallback onSelect;
  final VoidCallback onDelete;

  const _EventCard({
    required this.event,
    required this.isSelected,
    required this.onSelect,
    required this.onDelete,
  });  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryColor : Colors.grey.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(Icons.event_note, color: isSelected ? Colors.white : Colors.grey),
        ),
        title: Text(event.name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.groups_outlined, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text('Capacity: ${event.maxCapacity}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              ],
            ),
            if (isSelected)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.successColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: const Text('ACTIVE NOW', style: TextStyle(color: AppTheme.successColor, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1)),
                ),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isSelected)
              IconButton(
                icon: const Icon(Icons.radio_button_unchecked, color: Colors.grey),
                onPressed: onSelect,
              ),
            IconButton(
              icon: Icon(Icons.delete_outline, color: Colors.red.shade300),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}
