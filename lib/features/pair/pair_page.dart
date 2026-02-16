import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:proballdev/core/constants/app_constants.dart';
import 'package:proballdev/core/utils/logout_helper.dart';
import 'package:proballdev/models/app_error.dart';
import 'package:proballdev/models/discovered_device.dart';
import 'package:proballdev/models/paired_device.dart';
import 'package:proballdev/services/device_service.dart';

/// Pair Device screen. Two sections: My Devices (from API) and Other Devices (from BLE/mock scan).
class PairPage extends StatefulWidget {
  const PairPage({super.key});

  @override
  State<PairPage> createState() => _PairPageState();
}

class _PairPageState extends State<PairPage> {
  List<PairedDevice>? _myDevices;
  List<DiscoveredDevice> _otherDevices = [];
  StreamSubscription<List<DiscoveredDevice>>? _discoveredSubscription;
  DeviceService? _deviceService;
  String? _pairingDeviceId;
  String? _errorMessage;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _deviceService ??= context.read<DeviceService>();
    final deviceService = _deviceService!;

    if (_myDevices == null) {
      deviceService.fetchMyDevices().then((list) {
        if (mounted) {
          setState(() {
            _myDevices = list;
            _filterOtherDevices();
          });
        }
      }).catchError((_) {
        if (mounted) setState(() => _myDevices = []);
      });
    }

    _discoveredSubscription ??= deviceService.discoveredStream.listen((list) {
      if (!mounted) return;
      setState(() {
        _otherDevices = list;
        _filterOtherDevices();
      });
    });

    deviceService.startScan();
  }

  @override
  void dispose() {
    _deviceService?.stopScan();
    _discoveredSubscription?.cancel();
    super.dispose();
  }

  void _filterOtherDevices() {
    final myIds = (_myDevices ?? []).map((d) => d.deviceId).toSet();
    _otherDevices =
        _otherDevices.where((d) => !myIds.contains(d.deviceId)).toList();
  }

  Future<void> _continueWithMyDevice(PairedDevice device) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.pairedDeviceIdKey, device.deviceId);
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/');
    }
  }

  Future<void> _pairOtherDevice(DiscoveredDevice device) async {
    final deviceService = context.read<DeviceService>();
    setState(() {
      _pairingDeviceId = device.deviceId;
      _errorMessage = null;
    });
    try {
      await deviceService.pairDevice(
        deviceId: device.deviceId,
        deviceName: device.name,
      );
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.pairedDeviceIdKey, device.deviceId);
      final refreshed = await deviceService.fetchMyDevices();
      if (mounted) {
        setState(() {
          _myDevices = refreshed;
          _pairingDeviceId = null;
          final myIds = refreshed.map((d) => d.deviceId).toSet();
          _otherDevices =
              _otherDevices.where((d) => !myIds.contains(d.deviceId)).toList();
        });
        Navigator.of(context).pushReplacementNamed('/');
      }
    } on AppError catch (e) {
      if (mounted) {
        final message = e.apiCode == 'device_owned_by_other'
            ? 'Already paired to another account'
            : e.apiCode == 'device_already_paired'
                ? 'One device per account for MVP'
                : e.userMessage;
        setState(() {
          _pairingDeviceId = null;
          _errorMessage = message;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _pairingDeviceId = null;
          _errorMessage = 'Pairing failed. Please try again.';
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
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'logout') performLogout(context);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, size: 20),
                    SizedBox(width: 12),
                    Text('Logout'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'My Devices',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              if (_myDevices == null)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_myDevices!.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    'No devices paired yet.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                )
              else
                ..._myDevices!.map(
                  (d) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _DeviceCard(
                      title: d.nickname ?? 'Unknown device',
                      subtitle: d.deviceId,
                      leading: const Icon(Icons.check_circle, color: Colors.green),
                      trailing: ElevatedButton(
                        onPressed: () => _continueWithMyDevice(d),
                        child: const Text('Connect / Continue'),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 24),
              Text(
                'Other Devices',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Select a nearby device to pair',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _otherDevices.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.bluetooth_searching,
                                size: 64,
                                color: theme.colorScheme.outline,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No nearby devices found. Turn on ball & enable Bluetooth.',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _otherDevices.length,
                        itemBuilder: (context, index) {
                          final d = _otherDevices[index];
                          final isPairing = _pairingDeviceId == d.deviceId;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _DeviceCard(
                              title: d.name ?? 'Unknown device',
                              subtitle: d.deviceId,
                              leading: isPairing
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2),
                                    )
                                  : const Icon(Icons.bluetooth_connected),
                              onTap: _pairingDeviceId != null
                                  ? null
                                  : () => _pairOtherDevice(d),
                            ),
                          );
                        },
                      ),
              ),
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

class _DeviceCard extends StatelessWidget {
  const _DeviceCard({
    required this.title,
    required this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      leading: leading,
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: trailing,
      onTap: onTap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      tileColor: theme.colorScheme.surfaceContainerLow,
    );
  }
}
