// ============================================================
// screens/check_in_screen.dart
// QR Scanner + Manual ID entry check-in screen
// ============================================================
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../models/check_in_log_model.dart';
import '../providers/event_provider.dart';
import '../providers/check_in_provider.dart';
import '../providers/dashboard_provider.dart';
import '../services/qr_service.dart';
import '../utils/app_theme.dart';


class CheckInScreen extends StatefulWidget {
  const CheckInScreen({super.key});

  @override
  State<CheckInScreen> createState() => _CheckInScreenState();
}

class _CheckInScreenState extends State<CheckInScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final _manualCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isProcessing = false;
  bool _scannerActive = true;
  String _feedbackMsg = '';
  bool _feedbackSuccess = false;
  MobileScannerController? _scanCtrl;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _scanCtrl = MobileScannerController();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _manualCtrl.dispose();
    _scanCtrl?.dispose();
    super.dispose();
  }

  Future<void> _handleCheckIn(String participantId, CheckInMethod method) async {
    if (_isProcessing) return;

    final eventProv = context.read<EventProvider>();
    final checkInProv = context.read<CheckInProvider>();
    final dashProv = context.read<DashboardProvider>();
    final event = eventProv.selectedEvent;

    if (event == null) {
      _showFeedback('Please select an event first.', false);
      return;
    }

    setState(() => _isProcessing = true);

    try {
      CheckInResult result;
      if (method == CheckInMethod.qr) {
        result = await checkInProv.checkInByQR(
          rawQrValue: participantId,
          eventId: event.id,
          maxCapacity: event.maxCapacity,
        );
      } else {
        result = await checkInProv.checkInManual(
          participantId: participantId,
          eventId: event.id,
          maxCapacity: event.maxCapacity,
        );
      }

      // Refresh dashboard stats
      dashProv.refresh(event);

      _showFeedback(result.message, result.success);

      if (method == CheckInMethod.manual && result.success) {
        _manualCtrl.clear();
      }

      // Re-enable scanner after 2.5s
      if (method == CheckInMethod.qr) {
        await Future.delayed(const Duration(milliseconds: 2500));
        if (mounted) setState(() => _scannerActive = true);
      }
    } catch (e) {
      _showFeedback('An unexpected error occurred: $e', false);
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _showFeedback(String msg, bool success) {
    setState(() {
      _feedbackMsg = msg;
      _feedbackSuccess = success;
    });
  }


  @override
  Widget build(BuildContext context) {
    final event = context.watch<EventProvider>().selectedEvent;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('CHECK-IN PORTAL'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          indicatorWeight: 4,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(icon: Icon(Icons.qr_code_scanner, size: 20), text: 'SCAN'),
            Tab(icon: Icon(Icons.keyboard_alt_outlined, size: 20), text: 'MANUAL'),
            Tab(icon: Icon(Icons.person_add_alt, size: 20), text: 'NEW'),
            Tab(icon: Icon(Icons.qr_code, size: 20), text: 'CODES'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Event Context Banner
          if (event != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.05),
                border: Border(bottom: BorderSide(color: AppTheme.primaryColor.withOpacity(0.1))),
              ),
              child: Row(
                children: [
                  const Icon(Icons.event_seat, color: AppTheme.primaryColor, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      event.name.toUpperCase(),
                      style: const TextStyle(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.w900,
                          fontSize: 11,
                          letterSpacing: 1),
                    ),
                  ),
                  _buildSyncIndicator(),
                ],
              ),
            ),

          // Feedback Banner
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: _feedbackMsg.isNotEmpty ? 60 : 0,
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: _feedbackSuccess ? AppTheme.successColor : AppTheme.dangerColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: (_feedbackSuccess ? AppTheme.successColor : AppTheme.dangerColor).withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: _feedbackMsg.isNotEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Icon(_feedbackSuccess ? Icons.check_circle : Icons.error, color: Colors.white),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _feedbackMsg,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white, size: 18),
                          onPressed: () => _showFeedback('', false),
                        ),
                      ],
                    ),
                  )
                : null,
          ),

          Expanded(
            child: event == null
                ? _buildNoEventMessage()
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildQRScanner(event),
                      _buildManualEntry(event),
                      _buildRegistrationForm(event),
                      _buildQRDisplay(event),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSyncIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.2)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.wifi, size: 10, color: AppTheme.successColor),
          SizedBox(width: 4),
          Text('OFFLINE-READY', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildQRScanner(dynamic event) {
    return Stack(
      children: [
        if (_scannerActive)
          MobileScanner(
            controller: _scanCtrl,
            onDetect: (capture) {
              final barcodes = capture.barcodes;
              if (barcodes.isEmpty) return;
              final raw = barcodes.first.rawValue ?? '';
              if (raw.isNotEmpty && _scannerActive) {
                setState(() => _scannerActive = false);
                _handleCheckIn(raw, CheckInMethod.qr);
              }
            },
          )
        else
          Container(
            color: Colors.black87,
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.white),
                  SizedBox(height: 16),
                  Text('Processing…',
                      style: TextStyle(color: Colors.white70, fontSize: 16)),
                ],
              ),
            ),
          ),
        // Scan frame overlay
        if (_scannerActive)
          Center(
            child: Container(
              width: 230,
              height: 230,
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.primaryColor, width: 3),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.8),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(12),
                        bottomRight: Radius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Align QR Code in frame',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildManualEntry(dynamic event) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            _buildManualEntryForm(event),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            _buildTestHelpers(event),
          ],
        ),
      ),
    );
  }

  Widget _buildManualEntryForm(dynamic event) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.badge_outlined,
              size: 64, color: AppTheme.primaryColor),
          const SizedBox(height: 20),
          const Text('Enter Participant ID',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(
            'Type the participant\'s unique ID to check them in.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 28),
          TextFormField(
            controller: _manualCtrl,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(
              labelText: 'Participant ID',
              prefixIcon: Icon(Icons.person_search_outlined),
              hintText: 'e.g. P001',
            ),
            validator: (v) => v == null || v.trim().length < 3
                ? 'Enter a valid ID (min 3 chars)'
                : null,
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: _isProcessing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.how_to_reg),
              label: Text(_isProcessing ? 'Processing…' : 'Check In'),
              onPressed: _isProcessing
                  ? null
                  : () {
                      if (_formKey.currentState!.validate()) {
                        _handleCheckIn(
                            _manualCtrl.text.trim(), CheckInMethod.manual);
                      }
                    },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTestHelpers(dynamic event) {
    return Column(
      children: [
        const Text('Testing Tools (Simulation)',
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.qr_code_scanner),
                label: const Text('Simulate QR (P001)'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.orange.shade700,
                  side: BorderSide(color: Colors.orange.shade300),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: _isProcessing
                    ? null
                    : () {
                        _manualCtrl.text = 'P001';
                        _handleCheckIn(
                            QRService.generatePayload('P001'), CheckInMethod.qr);
                      },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.person_add_alt_1),
                label: const Text('Register P001'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.green.shade700,
                  side: BorderSide(color: Colors.green.shade300),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: _isProcessing
                    ? null
                    : () async {
                        await context.read<CheckInProvider>().registerParticipant(
                              id: 'P001',
                              name: 'Test User (P001)',
                              eventId: event.id,
                            );
                        _showFeedback('P001 registered for this event!', true);
                      },
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Use "Register P001" first to avoid the "Different Event" error.',
          style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildRegistrationForm(dynamic event) {
    final nameCtrl = TextEditingController();
    final idCtrl = TextEditingController();
    final regFormKey = GlobalKey<FormState>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: regFormKey,
        child: Column(
          children: [
            const Icon(Icons.person_add_outlined,
                size: 64, color: AppTheme.primaryColor),
            const SizedBox(height: 16),
            const Text('Register Participant',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text('Register them for ${event.name}',
                style: TextStyle(color: Colors.grey.shade600)),
            const SizedBox(height: 32),
            TextFormField(
              controller: idCtrl,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: 'Participant ID',
                prefixIcon: Icon(Icons.badge),
                hintText: 'e.g. P001',
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Enter an ID' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: nameCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Full Name',
                prefixIcon: Icon(Icons.person),
                hintText: 'e.g. John Doe',
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Enter a name' : null,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                child: const Text('Register & Save'),
                onPressed: () async {
                  if (regFormKey.currentState!.validate()) {
                    await context.read<CheckInProvider>().registerParticipant(
                          id: idCtrl.text.trim(),
                          name: nameCtrl.text.trim(),
                          eventId: event.id,
                        );
                    _showFeedback('Registered ${nameCtrl.text.trim()}!', true);
                    idCtrl.clear();
                    nameCtrl.clear();
                    _tabController.animateTo(1); // Go back to manual tab
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQRDisplay(dynamic event) {
    final participants =
        context.read<CheckInProvider>().getParticipantsForEvent(event.id);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Text(
            'Participant QR Codes',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            'Show these to participants for scanning',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              itemCount: participants.isEmpty ? 1 : participants.take(10).length,
              itemBuilder: (_, i) {
                if (participants.isEmpty) {
                  return const Center(
                      child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Text('No participants yet.'),
                  ));
                }
                final p = participants[i];
                final payload = QRService.generatePayload(p.id);
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        QrImageView(
                          data: payload,
                          version: QrVersions.auto,
                          size: 80,
                          eyeStyle: const QrEyeStyle(
                            eyeShape: QrEyeShape.square,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(p.name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15)),
                              Text('ID: ${p.id}',
                                  style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 12)),
                              Text(p.email,
                                  style: const TextStyle(fontSize: 12)),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: p.isCheckedIn
                                      ? AppTheme.successColor.withOpacity(0.15)
                                      : Colors.grey.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  p.isCheckedIn ? '✓ Checked In' : 'Pending',
                                  style: TextStyle(
                                    color: p.isCheckedIn
                                        ? AppTheme.successColor
                                        : Colors.grey,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoEventMessage() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_busy, size: 64, color: Colors.grey),
          SizedBox(height: 12),
          Text('No event selected.',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          SizedBox(height: 6),
          Text('Go to Event tab to create or select an event.',
              style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}
