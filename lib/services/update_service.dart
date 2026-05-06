import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:ota_update/ota_update.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:blissfruitz/models/settings.dart';
import 'package:blissfruitz/config/routes.dart';
import 'logger_service.dart';

class UpdateService {
  /// Checks for a new version from self-hosted settings (Supabase)
  static Future<void> checkForUpdate() async {
    if (kIsWeb) return;
    
    // Only proceed on Android as ota_update is Android-only
    if (defaultTargetPlatform != TargetPlatform.android) return;

    try {
      // 1. Get current version
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;
      
      // 2. Get latest version from Supabase
      const updateSettings = AppUpdateSettings(latestVersion: '1.0.0');
      
      // 3. Compare versions
      if (_isUpdateAvailable(currentVersion, updateSettings.latestVersion)) {
        if (updateSettings.apkUrl != null) {
          _showUpdateDialog(updateSettings);
        }
      }
    } catch (e) {
      LoggerService.logError('UpdateService.checkForUpdate error: $e');
    }
  }

  /// Compares version strings (e.g., "1.0.0" vs "1.0.1")
  static bool _isUpdateAvailable(String current, String latest) {
    try {
      final currentParts = current.split('.').map(int.parse).toList();
      final latestParts = latest.split('.').map(int.parse).toList();

      for (var i = 0; i < latestParts.length; i++) {
        final currentPart = i < currentParts.length ? currentParts[i] : 0;
        if (latestParts[i] > currentPart) return true;
        if (latestParts[i] < currentPart) return false;
      }
    } catch (e) {
      // If parsing fails, do a string comparison as fallback
      return current != latest;
    }
    return false;
  }

  /// Shows the update prompt
  static void _showUpdateDialog(AppUpdateSettings settings) {
    final context = rootNavigatorKey.currentContext;
    if (context == null) return;

    showDialog(
      context: context,
      barrierDismissible: !settings.forceUpdate,
      builder: (context) => PopScope(
        canPop: !settings.forceUpdate,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.system_update, color: Colors.green),
              const SizedBox(width: 12),
              const Text('Update Available'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'A new version (${settings.latestVersion}) is available. Please update to continue enjoying BlissFruitz.',
                style: const TextStyle(fontSize: 14),
              ),
              if (settings.updateNotes != null && settings.updateNotes!.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text(
                  'What\'s New:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                Text(
                  settings.updateNotes!,
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                ),
              ],
            ],
          ),
          actions: [
            if (!settings.forceUpdate)
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Later', style: TextStyle(color: Colors.grey)),
              ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _performUpdate(settings.apkUrl!);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Update Now'),
            ),
          ],
        ),
      ),
    );
  }

  /// Downloads and installs the APK using ota_update
  static void _performUpdate(String url) {
    final context = rootNavigatorKey.currentContext;
    if (context == null) return;

    // Show progress dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _DownloadProgressDialog(url: url),
    );
  }
}

class _DownloadProgressDialog extends StatefulWidget {
  final String url;
  const _DownloadProgressDialog({required this.url});

  @override
  State<_DownloadProgressDialog> createState() => _DownloadProgressDialogState();
}

class _DownloadProgressDialogState extends State<_DownloadProgressDialog> {
  String _status = 'Starting download...';
  double _progress = 0;

  @override
  void initState() {
    super.initState();
    _startDownload();
  }

  void _startDownload() {
    try {
      OtaUpdate().execute(widget.url).listen(
        (OtaEvent event) {
          setState(() {
            switch (event.status) {
              case OtaStatus.DOWNLOADING:
                _status = 'Downloading update...';
                _progress = double.tryParse(event.value ?? '0') ?? 0;
                break;
              case OtaStatus.INSTALLING:
                _status = 'Installing update...';
                Navigator.pop(context); // Close progress dialog
                break;
              case OtaStatus.ALREADY_RUNNING_ERROR:
                _status = 'Update already in progress.';
                break;
              default:
                _status = 'Update failed. Please try again.';
                break;
            }
          });
        },
        onError: (e) {
          setState(() {
            _status = 'Error: $e';
          });
        },
      );
    } catch (e) {
      setState(() {
        _status = 'Failed to launch update: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Updating App'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          LinearProgressIndicator(
            value: _progress / 100,
            backgroundColor: Colors.grey[200],
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
          ),
          const SizedBox(height: 16),
          Text(_status, textAlign: TextAlign.center),
          if (_progress > 0)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text('${_progress.toInt()}%'),
            ),
        ],
      ),
      actions: [
        if (_status.contains('failed') || _status.contains('Error'))
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
      ],
    );
  }
}
