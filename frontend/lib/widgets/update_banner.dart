import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/update_service.dart';

class UpdateBanner extends StatefulWidget {
  final UpdateStatus updateStatus;
  final VoidCallback? onDismiss;

  const UpdateBanner({
    super.key,
    required this.updateStatus,
    this.onDismiss,
  });

  @override
  State<UpdateBanner> createState() => _UpdateBannerState();
}

class _UpdateBannerState extends State<UpdateBanner> {
  bool _isDismissed = false;

  Future<void> _openReleaseUrl() async {
    final urlStr = widget.updateStatus.releaseUrl ??
        'https://github.com/Starry03/mschool/releases/latest';
    final uri = Uri.parse(urlStr);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isDismissed || !widget.updateStatus.hasUpdate) {
      return const SizedBox.shrink();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final status = widget.updateStatus;

    String title;
    String subtitle;
    if (status.bothNeedUpdate) {
      title = 'Aggiornamento disponibile (v${status.latestReleaseVersion})';
      subtitle =
          'Sia il client (v${status.currentClientVersion}) che il server (v${status.currentServerVersion ?? "?"}) possono essere aggiornati.';
    } else if (status.clientNeedsUpdate) {
      title = 'Nuova versione Client disponibile (v${status.latestReleaseVersion})';
      subtitle =
          'La tua versione attuale è v${status.currentClientVersion}. Scarica l\'aggiornamento.';
    } else {
      title = 'Nuova versione Server disponibile (v${status.latestReleaseVersion})';
      subtitle =
          'Il backend attuale è fermo alla v${status.currentServerVersion ?? "?"}. Aggiorna i container.';
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1E293B).withValues(alpha: 0.95)
            : const Color(0xFFFEF3C7).withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark
              ? const Color(0xFFF59E0B).withValues(alpha: 0.5)
              : const Color(0xFFF59E0B).withValues(alpha: 0.8),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF59E0B).withValues(alpha: isDark ? 0.15 : 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.system_update_rounded,
              color: Color(0xFFD97706),
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: isDark ? Colors.white : const Color(0xFF92400E),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: isDark ? Colors.white70 : const Color(0xFF78350F),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          TextButton.icon(
            style: TextButton.styleFrom(
              backgroundColor: const Color(0xFFF59E0B),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: _openReleaseUrl,
            icon: const Icon(Icons.open_in_new, size: 14),
            label: const Text(
              'Dettagli',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: Icon(
              Icons.close,
              size: 18,
              color: isDark ? Colors.white54 : Colors.black54,
            ),
            tooltip: 'Chiudi notifica',
            onPressed: () {
              setState(() => _isDismissed = true);
              widget.onDismiss?.call();
            },
          ),
        ],
      ),
    );
  }
}
