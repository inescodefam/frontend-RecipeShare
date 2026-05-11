import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared/shared.dart';

import 'admin_recipes_tab.dart';

class AdminReportsTab extends StatefulWidget {
  const AdminReportsTab({super.key});

  @override
  State<AdminReportsTab> createState() => _AdminReportsTabState();
}

class _AdminReportsTabState extends State<AdminReportsTab> {
  List<AdminReportSummary> _reports = const [];
  bool _loading = true;
  String? _error;
  int _page = 1;
  final int _pageSize = 10;
  int _totalCount = 0;
  bool _hasNextPage = false;
  ReportStatus? _statusFilter;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({int? page}) async {
    final nextPage = page ?? _page;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await context.read<RecipeShareServices>().admin.getAdminReports(
            pageNumber: nextPage,
            pageSize: _pageSize,
            status: _statusFilter,
          );
      if (!mounted) return;
      setState(() {
        _reports = result.items;
        _page = result.pageNumber;
        _totalCount = result.totalCount;
        _hasNextPage = result.hasNextPage;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _openReport(AdminReportSummary report) async {
    try {
      final detail = await context.read<RecipeShareServices>().admin.getAdminReportById(report.id);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) => _ReportDetailDialog(
          detail: detail,
          onDismiss: () => context.read<RecipeShareServices>().admin.dismissAdminReport(detail.id),
          onResolve: ({
            required AdminAction contentAction,
            required AdminAction userAction,
            String? adminNote,
          }) =>
              context.read<RecipeShareServices>().admin.resolveAdminReport(
                    detail.id,
                    contentAction: contentAction,
                    userAction: userAction,
                    adminNote: adminNote,
                  ),
        ),
      );
      if (!mounted) return;
      await _load(page: _page);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_error!, style: const TextStyle(color: AppColors.error)),
              const SizedBox(height: 16),
              FilledButton(onPressed: _load, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _load(page: _page),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          DropdownButtonFormField<ReportStatus?>(
            key: ValueKey(_statusFilter),
            initialValue: _statusFilter,
            decoration: const InputDecoration(
              labelText: 'Status filter',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: null, child: Text('All')),
              DropdownMenuItem(value: ReportStatus.pending, child: Text('Pending')),
              DropdownMenuItem(value: ReportStatus.resolved, child: Text('Resolved')),
              DropdownMenuItem(value: ReportStatus.dismissed, child: Text('Dismissed')),
            ],
            onChanged: (value) {
              setState(() => _statusFilter = value);
              _load(page: 1);
            },
          ),
          const SizedBox(height: 16),
          PagerBar(
            page: _page,
            pageSize: _pageSize,
            totalCount: _totalCount,
            hasNextPage: _hasNextPage,
            onPrevious: _page > 1 ? () => _load(page: _page - 1) : null,
            onNext: _hasNextPage ? () => _load(page: _page + 1) : null,
          ),
          const SizedBox(height: 16),
          if (_reports.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Text('No reports found.'),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                return Scrollbar(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minWidth: constraints.maxWidth),
                      child: DataTable(
                        columns: const [
                          DataColumn(label: Text('ID')),
                          DataColumn(label: Text('Target')),
                          DataColumn(label: Text('Reporter')),
                          DataColumn(label: Text('Reported user')),
                          DataColumn(label: Text('Reason')),
                          DataColumn(label: Text('Status')),
                          DataColumn(label: Text('Created')),
                          DataColumn(label: Text('Actions')),
                        ],
                        rows: _reports.map((report) {
                          return DataRow(
                            cells: [
                              DataCell(Text('${report.id}')),
                              DataCell(Text('${report.targetType.name} #${report.targetId}')),
                              DataCell(Text(report.reporterUsername)),
                              DataCell(Text(report.reportedUsername)),
                              DataCell(Text(report.reason.name)),
                              DataCell(Text(report.status.name)),
                              DataCell(Text(report.createdAt.toLocal().toString())),
                              DataCell(
                                TextButton(
                                  onPressed: () => _openReport(report),
                                  child: const Text('Open'),
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _ReportDetailDialog extends StatefulWidget {
  const _ReportDetailDialog({
    required this.detail,
    required this.onDismiss,
    required this.onResolve,
  });

  final AdminReportDetail detail;
  final Future<void> Function() onDismiss;
  final Future<void> Function({
    required AdminAction contentAction,
    required AdminAction userAction,
    String? adminNote,
  }) onResolve;

  @override
  State<_ReportDetailDialog> createState() => _ReportDetailDialogState();
}

class _ReportDetailDialogState extends State<_ReportDetailDialog> {
  AdminAction _contentAction = AdminAction.none;
  AdminAction _userAction = AdminAction.none;
  final _note = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action, String message) async {
    setState(() => _busy = true);
    try {
      await action();
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final detail = widget.detail;
    final canModerate = detail.status == ReportStatus.pending;

    return AlertDialog(
      title: Text('Report #${detail.id}'),
      content: SizedBox(
        width: 640,
        child: _busy
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Status: ${detail.status.name}'),
                    Text('Target: ${detail.targetType.name} #${detail.targetId}'),
                    if (detail.targetContent != null) Text('Content: ${detail.targetContent}'),
                    Text('Reporter: ${detail.reporterUsername}'),
                    Text('Reported user: ${detail.reportedUsername}'),
                    Text('Reason: ${detail.reason.name}'),
                    if (detail.description != null) Text('Description: ${detail.description}'),
                    if (detail.adminNote != null) Text('Admin note: ${detail.adminNote}'),
                    if (detail.resolvedByAdminUsername != null)
                      Text('Resolved by: ${detail.resolvedByAdminUsername}'),
                    if (canModerate) ...[
                      const SizedBox(height: 16),
                      DropdownButtonFormField<AdminAction>(
                        key: ValueKey(_contentAction),
                        initialValue: _contentAction,
                        decoration: const InputDecoration(
                          labelText: 'Content action',
                          border: OutlineInputBorder(),
                        ),
                        items: AdminAction.values
                            .map(
                              (action) => DropdownMenuItem(
                                value: action,
                                child: Text(action.name),
                              ),
                            )
                            .toList(),
                        onChanged: (value) => setState(() => _contentAction = value ?? AdminAction.none),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<AdminAction>(
                        key: ValueKey(_userAction),
                        initialValue: _userAction,
                        decoration: const InputDecoration(
                          labelText: 'User action',
                          border: OutlineInputBorder(),
                        ),
                        items: AdminAction.values
                            .map(
                              (action) => DropdownMenuItem(
                                value: action,
                                child: Text(action.name),
                              ),
                            )
                            .toList(),
                        onChanged: (value) => setState(() => _userAction = value ?? AdminAction.none),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _note,
                        decoration: const InputDecoration(
                          labelText: 'Admin note',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                      ),
                    ],
                  ],
                ),
              ),
      ),
      actions: [
        TextButton(onPressed: _busy ? null : () => Navigator.pop(context), child: const Text('Close')),
        if (canModerate)
          TextButton(
            onPressed: _busy
                ? null
                : () => _run(widget.onDismiss, 'Report dismissed.'),
            child: const Text('Dismiss'),
          ),
        if (canModerate)
          FilledButton(
            onPressed: _busy
                ? null
                : () => _run(
                      () => widget.onResolve(
                        contentAction: _contentAction,
                        userAction: _userAction,
                        adminNote: _note.text,
                      ),
                      'Report resolved.',
                    ),
            child: const Text('Resolve'),
          ),
      ],
    );
  }
}
