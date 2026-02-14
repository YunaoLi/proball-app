import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:proballdev/services/auth_state.dart';

/// Listens to AuthStateNotifier.needsReauth and navigates to root when re-login is required.
class ReauthListener extends StatefulWidget {
  const ReauthListener({super.key, required this.child});

  final Widget child;

  @override
  State<ReauthListener> createState() => _ReauthListenerState();
}

class _ReauthListenerState extends State<ReauthListener> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final state = context.read<AuthStateNotifier>();
    state.removeListener(_onAuthStateChanged);
    state.addListener(_onAuthStateChanged);
    if (state.needsReauth) _onAuthStateChanged();
  }

  @override
  void dispose() {
    context.read<AuthStateNotifier>().removeListener(_onAuthStateChanged);
    super.dispose();
  }

  void _onAuthStateChanged() {
    final state = context.read<AuthStateNotifier>();
    if (state.needsReauth && mounted) {
      state.clearNeedsReauth();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.of(context).pushNamedAndRemoveUntil('/', (_) => false);
      });
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
