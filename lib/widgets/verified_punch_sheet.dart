import 'package:flutter/material.dart';

import '../models/punch_capture.dart';
import '../services/punch_context_service.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import 'user_avatar.dart';

enum PunchAction { clockIn, clockOut }

Future<PunchCapture?> showVerifiedPunchSheet({
  required BuildContext context,
  required PunchAction action,
  String workMode = 'OFFICE',
}) {
  return showModalBottomSheet<PunchCapture>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => VerifiedPunchSheet(action: action, workMode: workMode),
  );
}

class VerifiedPunchSheet extends StatefulWidget {
  final PunchAction action;
  final String workMode;

  const VerifiedPunchSheet({
    super.key,
    required this.action,
    this.workMode = 'OFFICE',
  });

  @override
  State<VerifiedPunchSheet> createState() => _VerifiedPunchSheetState();
}

class _VerifiedPunchSheetState extends State<VerifiedPunchSheet> {
  final _storage = StorageService();
  final _contextService = PunchContextService();

  String? _faceUrl;
  PunchCapture? _preview;
  String? _error;
  bool _capturingFace = false;
  bool _readingContext = false;
  bool _submitting = false;

  bool get _isOut => widget.action == PunchAction.clockOut;

  Future<void> _captureFace() async {
    setState(() {
      _capturingFace = true;
      _error = null;
    });
    try {
      final file = await _storage.captureFaceSelfie();
      if (file == null) return;
      final bytes = await file.readAsBytes();
      final ext = file.name.contains('.') ? file.name.split('.').last : 'jpg';
      final url = await _storage.encodeImageAsDataUrl(
        bytes: bytes,
        fileExtension: ext,
      );
      if (!mounted) return;
      setState(() => _faceUrl = url);
      await _refreshContext(url);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _capturingFace = false);
    }
  }

  Future<void> _refreshContext(String faceUrl) async {
    setState(() {
      _readingContext = true;
      _error = null;
    });
    try {
      final capture = await _contextService.collect(facePhotoUrl: faceUrl);
      if (!mounted) return;
      setState(() => _preview = capture);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _readingContext = false);
    }
  }

  void _confirm() {
    final capture = _preview;
    if (capture == null || !capture.isComplete) return;
    setState(() => _submitting = true);
    Navigator.of(context).pop(capture);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ready = _preview?.isComplete == true && !_readingContext;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 4,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _isOut ? 'Verify clock-out' : 'Verify clock-in',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              widget.workMode.toUpperCase() == 'WFH'
                  ? 'Work-from-home punch: live face and GPS are required. Office Wi-Fi is optional.'
                  : widget.workMode.toUpperCase() == 'FREELANCE'
                  ? 'Freelance punch: hours are stored. Late and half-day policy will not apply.'
                  : 'Office/hybrid punch: live face, GPS, and Wi-Fi / IP so this stamp cannot be faked from somewhere else.',
              style: TextStyle(color: Colors.grey.shade700, height: 1.4),
            ),
            const SizedBox(height: 20),
            Center(
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _capturingFace ? null : _captureFace,
                    child: CircleAvatar(
                      radius: 64,
                      backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
                      backgroundImage: getUserAvatarImageProvider(_faceUrl),
                      child: _faceUrl == null
                          ? Icon(
                              Icons.face_retouching_natural_rounded,
                              size: 48,
                              color: AppTheme.primary,
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _capturingFace ? null : _captureFace,
                    icon: _capturingFace
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.camera_front_rounded),
                    label: Text(
                      _faceUrl == null ? 'Capture face' : 'Retake selfie',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _StatusTile(
              icon: Icons.my_location_rounded,
              color: AppTheme.primary,
              title: 'GPS location',
              subtitle: _readingContext
                  ? 'Locking GPS…'
                  : (_preview?.gpsLabel ?? 'Capture your face to read GPS'),
              ok: _preview?.hasGps == true,
              loading: _readingContext,
            ),
            const SizedBox(height: 10),
            _StatusTile(
              icon: Icons.wifi_rounded,
              color: AppTheme.secondary,
              title: widget.workMode.toUpperCase() == 'WFH'
                  ? 'Wi-Fi (optional for WFH)'
                  : 'Wi-Fi & network',
              subtitle: _readingContext
                  ? 'Reading network…'
                  : widget.workMode.toUpperCase() == 'WFH'
                      ? (_preview?.networkLabel ??
                          'Office SSID is not required for work-from-home')
                      : (_preview?.networkLabel ??
                          'Office Wi-Fi name, BSSID, and IP are stored with the punch'),
              ok: widget.workMode.toUpperCase() == 'WFH'
                  ? _preview != null
                  : _preview?.hasWifi == true ||
                      (_preview?.ipAddress.isNotEmpty ?? false),
              loading: _readingContext,
            ),
            if (_preview != null && !_preview!.hasWifi) ...[
              const SizedBox(height: 8),
              Text(
                widget.workMode.toUpperCase() == 'WFH'
                    ? 'Office Wi-Fi is optional for WFH. Face and GPS are still required.'
                    : 'Browsers cannot expose Wi-Fi SSID. On Android/iOS the office network name is stored. Your public IP is still recorded on web.',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Text(
                  _error!,
                  style: TextStyle(color: Colors.red.shade800),
                ),
              ),
            ],
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: ready && !_submitting ? _confirm : null,
              icon: const Icon(Icons.verified_rounded),
              label: Text(
                _isOut ? 'Confirm clock-out' : 'Confirm clock-in',
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _submitting ? null : () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final bool ok;
  final bool loading;

  const _StatusTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.ok,
    required this.loading,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.12),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                ),
              ],
            ),
          ),
          if (loading)
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            Icon(
              ok ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
              color: ok ? AppTheme.secondary : Colors.grey.shade400,
            ),
        ],
      ),
    );
  }
}

class PunchProofRow extends StatelessWidget {
  final PunchCapture? clockIn;
  final PunchCapture? clockOut;
  final bool compact;

  const PunchProofRow({
    super.key,
    this.clockIn,
    this.clockOut,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (clockIn == null && clockOut == null) return const SizedBox.shrink();
    return InkWell(
      onTap: () => showPunchProofDialog(
        context,
        clockIn: clockIn,
        clockOut: clockOut,
      ),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Row(
          children: [
            if (clockIn != null)
              _Thumb(label: compact ? 'In' : 'In selfie', capture: clockIn!),
            if (clockIn != null && clockOut != null) const SizedBox(width: 10),
            if (clockOut != null)
              _Thumb(label: compact ? 'Out' : 'Out selfie', capture: clockOut!),
            const SizedBox(width: 8),
            Icon(Icons.my_location, size: 14, color: Colors.grey.shade700),
            const SizedBox(width: 4),
            Icon(
              Icons.wifi,
              size: 14,
              color: (clockIn?.hasWifi == true || clockOut?.hasWifi == true)
                  ? AppTheme.secondary
                  : Colors.grey.shade500,
            ),
            const SizedBox(width: 6),
            Text(
              'Verified punch',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Colors.grey.shade800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  final String label;
  final PunchCapture capture;

  const _Thumb({required this.label, required this.capture});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: 14,
          backgroundColor: Colors.grey.shade200,
          backgroundImage: getUserAvatarImageProvider(capture.facePhotoUrl),
          child: capture.hasFace
              ? null
              : const Icon(Icons.person, size: 14),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

Future<void> showPunchProofDialog(
  BuildContext context, {
  PunchCapture? clockIn,
  PunchCapture? clockOut,
}) {
  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Punch verification'),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (clockIn != null) _ProofBlock(title: 'Clock in', capture: clockIn),
              if (clockIn != null && clockOut != null) const SizedBox(height: 16),
              if (clockOut != null)
                _ProofBlock(title: 'Clock out', capture: clockOut),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Close'),
        ),
      ],
    ),
  );
}

class _ProofBlock extends StatelessWidget {
  final String title;
  final PunchCapture capture;

  const _ProofBlock({required this.title, required this.capture});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 10),
        Center(
          child: CircleAvatar(
            radius: 48,
            backgroundColor: Colors.grey.shade200,
            backgroundImage: getUserAvatarImageProvider(capture.facePhotoUrl),
            child: capture.hasFace ? null : const Icon(Icons.person, size: 36),
          ),
        ),
        const SizedBox(height: 12),
        _line(Icons.my_location_rounded, capture.gpsLabel),
        _line(Icons.wifi_rounded, capture.wifiLabel),
        if (capture.wifiBssid.isNotEmpty)
          _line(Icons.router_outlined, 'BSSID ${capture.wifiBssid}'),
        if (capture.ipAddress.isNotEmpty)
          _line(Icons.public_rounded, 'IP ${capture.ipAddress}'),
        if (capture.localIp.isNotEmpty)
          _line(Icons.lan_outlined, 'LAN ${capture.localIp}'),
        if (capture.platform.isNotEmpty)
          _line(Icons.devices_outlined, capture.platform),
      ],
    );
  }

  Widget _line(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade700),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }
}
