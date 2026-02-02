import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:proballdev/models/app_error.dart';
import 'package:proballdev/services/error_manager.dart';

/// Global error display: banners for warnings, blocking dialog for critical.
/// Listens to [ErrorManager] and shows UI once per state change.
class ErrorOverlay extends StatefulWidget {
  const ErrorOverlay({super.key, required this.child});

  final Widget child;

  @override
  State<ErrorOverlay> createState() => _ErrorOverlayState();
}

class _ErrorOverlayState extends State<ErrorOverlay> {
  StreamSubscription<AppError>? _subscription;
  AppError? _bannerError;
  bool _showingDialog = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final manager = context.read<ErrorManager>();
    _subscription?.cancel();
    _subscription = manager.errorStream.listen(_onError);
  }

  void _onError(AppError error) {
    if (!mounted) return;

    switch (error.severity) {
      case AppErrorSeverity.info:
        _showSnackbar(error);
        break;
      case AppErrorSeverity.warning:
        _showBanner(error);
        break;
      case AppErrorSeverity.critical:
        _showBlockingDialog(error);
        break;
    }
  }

  void _showSnackbar(AppError error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error.userMessage),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showBanner(AppError error) {
    setState(() => _bannerError = error);
  }

  void _dismissBanner() {
    setState(() => _bannerError = null);
    context.read<ErrorManager>().clearLast();
  }

  Future<void> _showBlockingDialog(AppError error) async {
    if (_showingDialog || !mounted) return;
    _showingDialog = true;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Battery Depleted'),
        content: Text(error.userMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );

    if (!mounted) return;
    _showingDialog = false;
    context.read<ErrorManager>().clearLast();

    // Pop back to root (e.g. exit CurrentPlaySessionPage)
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_bannerError != null)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _Banner(
              message: _bannerError!.userMessage,
              onDismiss: _dismissBanner,
            ),
          ),
      ],
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.message, required this.onDismiss});

  final String message;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      elevation: 4,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        color: theme.colorScheme.errorContainer,
        child: SafeArea(
          bottom: false,
          child: Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: theme.colorScheme.onErrorContainer,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onErrorContainer,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: onDismiss,
                color: theme.colorScheme.onErrorContainer,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
