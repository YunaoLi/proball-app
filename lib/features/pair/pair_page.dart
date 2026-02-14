import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:proballdev/core/constants/app_constants.dart';
import 'package:proballdev/models/app_error.dart';
import 'package:proballdev/services/device_service.dart';

/// Mock scan list: 2 hardcoded UUIDs. Choose one to pair.
class PairPage extends StatefulWidget {
  const PairPage({super.key});

  @override
  State<PairPage> createState() => _PairPageState();
}

class _PairPageState extends State<PairPage> {
  static const List<Map<String, String>> _mockDevices = [
    {'id': '550e8400-e29b-41d4-a716-446655440000', 'name': 'Pro Ball Alpha'},
    {'id': '660e8400-e29b-41d4-a716-446655440001', 'name': 'Pro Ball Beta'},
  ];

  bool _loading = false;
  String? _errorMessage;

  Future<void> _pair(String deviceId, String deviceName) async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    try {
      final deviceService = context.read<DeviceService>();
      await deviceService.pairDevice(deviceId: deviceId, deviceName: deviceName);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.pairedDeviceIdKey, deviceId);
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/');
      }
    } on AppError catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.userMessage;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Pairing failed. Please try again.';
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pair Device'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Select a device to pair',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              ..._mockDevices.map((d) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      title: Text(d['name']!),
                      subtitle: Text(d['id']!),
                      trailing: _loading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.bluetooth_connected),
                      onTap: _loading
                          ? null
                          : () => _pair(d['id']!, d['name']!),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      tileColor: theme.colorScheme.surfaceContainerLow,
                    ),
                  )),
              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                Text(
                  _errorMessage!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
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
