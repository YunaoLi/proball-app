import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:proballdev/core/utils/logout_helper.dart';
import 'package:proballdev/models/ai_report.dart';
import 'package:proballdev/models/app_error.dart';
import 'package:proballdev/services/report_service.dart';

/// Report detail for a session. Polls until READY, then shows content.
class ReportDetailPage extends StatefulWidget {
  const ReportDetailPage({super.key, required this.sessionId});

  final String sessionId;

  @override
  State<ReportDetailPage> createState() => _ReportDetailPageState();
}

class _ReportDetailPageState extends State<ReportDetailPage> {
  AiReport? _report;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _poll();
  }

  Future<void> _poll() async {
    try {
      final reportService = context.read<ReportService>();
      final res = await reportService.pollReport(
        widget.sessionId,
        interval: const Duration(seconds: 2),
        timeout: const Duration(seconds: 60),
      );
      if (mounted) {
        setState(() {
          _report = AiReport.fromBackendJson(res);
          _loading = false;
        });
      }
    } on AppError catch (e) {
      if (mounted) {
        setState(() {
          _error = e.userMessage;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load report.';
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
        title: const Text('Report'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
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
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
                        const SizedBox(height: 16),
                        Text(_error!, textAlign: TextAlign.center),
                      ],
                    ),
                  ),
                )
              : _report != null
                  ? SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: _buildContent(theme, _report!),
                    )
                  : const SizedBox.shrink(),
    );
  }

  Widget _buildContent(ThemeData theme, AiReport report) {
    if (report.status == 'FAILED') {
      return Text(
        report.failureReason ?? 'Report generation failed.',
        style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.error),
      );
    }
    final content = report.contentJson;
    if (content == null) return const SizedBox.shrink();
    final pretty = const JsonEncoder.withIndent('  ').convert(content);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (content['summaryTitle'] != null)
          Text(
            content['summaryTitle'] as String,
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
        if (content['summary'] != null) ...[
          const SizedBox(height: 12),
          Text(
            content['summary'] as String,
            style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
          ),
        ],
        const SizedBox(height: 24),
        Text(
          'Raw JSON',
          style: theme.textTheme.titleSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(12),
          ),
          child: SelectableText(
            pretty,
            style: theme.textTheme.bodySmall?.copyWith(
              fontFamily: 'monospace',
            ),
          ),
        ),
      ],
    );
  }
}
