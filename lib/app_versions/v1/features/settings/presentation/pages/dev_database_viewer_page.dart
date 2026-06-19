import 'package:flutter/material.dart';
import 'package:nano_app/core/storage/localdb/database_service.dart';
import 'package:nano_app/core/theme/theme.dart';

class DevDatabaseViewerPage extends StatefulWidget {
  const DevDatabaseViewerPage({super.key});

  @override
  State<DevDatabaseViewerPage> createState() => _DevDatabaseViewerPageState();
}

class _DevDatabaseViewerPageState extends State<DevDatabaseViewerPage> {
  final TextEditingController _searchController = TextEditingController();

  Future<_DatabaseSnapshot>? _snapshotFuture;
  String? _selectedTableName;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _snapshotFuture = _loadDatabaseSnapshot();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    final future = _loadDatabaseSnapshot();
    setState(() {
      _snapshotFuture = future;
    });
    await future;
  }

  Future<_DatabaseSnapshot> _loadDatabaseSnapshot() async {
    final db = await DatabaseService.database;

    final versionResult = await db.rawQuery('PRAGMA user_version');
    final version = _asInt(versionResult.first['user_version']);

    final tableRows = await db.rawQuery("""
      SELECT name
      FROM sqlite_master
      WHERE type = 'table'
        AND name NOT LIKE 'sqlite_%'
      ORDER BY name ASC
      """);

    final tables = <_DatabaseTableSnapshot>[];

    for (final row in tableRows) {
      final tableName = row['name']?.toString();
      if (tableName == null || tableName.trim().isEmpty) continue;

      final quotedTableName = _quoteIdentifier(tableName);

      final columnRows = await db.rawQuery(
        'PRAGMA table_info($quotedTableName)',
      );

      final countRows = await db.rawQuery(
        'SELECT COUNT(*) AS total FROM $quotedTableName',
      );

      final dataRows = await db.rawQuery('SELECT * FROM $quotedTableName');

      tables.add(
        _DatabaseTableSnapshot(
          name: tableName,
          totalRows: _asInt(countRows.first['total']),
          columns: columnRows.map(_DatabaseColumnSnapshot.fromMap).toList(),
          rows: dataRows,
        ),
      );
    }

    tables.sort((a, b) => a.name.compareTo(b.name));

    if (_selectedTableName == null ||
        !tables.any((table) => table.name == _selectedTableName)) {
      _selectedTableName = tables.isEmpty ? null : tables.first.name;
    }

    return _DatabaseSnapshot(
      version: version,
      tables: tables,
      loadedAt: DateTime.now(),
    );
  }

  static String _quoteIdentifier(String value) {
    return '"${value.replaceAll('"', '""')}"';
  }

  static int _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        title: const Text('Dev / Database'),
        actions: [
          IconButton(
            tooltip: 'Tải lại database',
            onPressed: _refresh,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: FutureBuilder<_DatabaseSnapshot>(
          future: _snapshotFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const _DatabaseLoadingState();
            }

            if (snapshot.hasError) {
              return _DatabaseErrorState(
                message:
                    'Không thể mở công cụ kiểm tra dữ liệu lúc này. Hãy tải lại hoặc kiểm tra log dev.',
                onRetry: _refresh,
              );
            }

            final data = snapshot.data;
            if (data == null || data.tables.isEmpty) {
              return _DatabaseEmptyState(onRetry: _refresh);
            }

            final selectedTable = _selectedTable(data);

            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: const EdgeInsets.all(AppSpacing.pagePadding),
                children: [
                  _DatabaseSummaryCard(snapshot: data),
                  const SizedBox(height: AppSpacing.lg),
                  _SearchField(
                    controller: _searchController,
                    onChanged: (value) {
                      setState(() => _searchQuery = value.trim());
                    },
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _TableSelector(
                    tables: data.filteredTables(_searchQuery),
                    selectedTableName: selectedTable?.name,
                    onSelected: (tableName) {
                      setState(() => _selectedTableName = tableName);
                    },
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  if (selectedTable != null)
                    _TableDetailSection(table: selectedTable)
                  else
                    _NoTableSelectedCard(hasSearch: _searchQuery.isNotEmpty),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  _DatabaseTableSnapshot? _selectedTable(_DatabaseSnapshot snapshot) {
    if (snapshot.tables.isEmpty) return null;

    final filteredTables = snapshot.filteredTables(_searchQuery);
    if (filteredTables.isEmpty) return null;

    final selectedName = _selectedTableName;
    if (selectedName != null) {
      for (final table in filteredTables) {
        if (table.name == selectedName) return table;
      }
    }

    return filteredTables.first;
  }
}

class _DatabaseSnapshot {
  const _DatabaseSnapshot({
    required this.version,
    required this.tables,
    required this.loadedAt,
  });

  final int version;
  final List<_DatabaseTableSnapshot> tables;
  final DateTime loadedAt;

  int get totalRows =>
      tables.fold<int>(0, (sum, table) => sum + table.totalRows);

  List<_DatabaseTableSnapshot> filteredTables(String query) {
    final normalizedQuery = query.trim().toLowerCase();
    if (normalizedQuery.isEmpty) return tables;

    return tables.where((table) {
      return table.name.toLowerCase().contains(normalizedQuery);
    }).toList();
  }
}

class _DatabaseTableSnapshot {
  const _DatabaseTableSnapshot({
    required this.name,
    required this.totalRows,
    required this.columns,
    required this.rows,
  });

  final String name;
  final int totalRows;
  final List<_DatabaseColumnSnapshot> columns;
  final List<Map<String, Object?>> rows;
}

class _DatabaseColumnSnapshot {
  const _DatabaseColumnSnapshot({
    required this.name,
    required this.type,
    required this.notNull,
    required this.primaryKey,
    this.defaultValue,
  });

  final String name;
  final String type;
  final bool notNull;
  final bool primaryKey;
  final Object? defaultValue;

  factory _DatabaseColumnSnapshot.fromMap(Map<String, Object?> map) {
    return _DatabaseColumnSnapshot(
      name: map['name']?.toString() ?? '',
      type: map['type']?.toString() ?? 'UNKNOWN',
      notNull: _asBool(map['notnull']),
      primaryKey: _asBool(map['pk']),
      defaultValue: map['dflt_value'],
    );
  }

  static bool _asBool(Object? value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    return value?.toString() == '1';
  }
}

class _DatabaseSummaryCard extends StatelessWidget {
  const _DatabaseSummaryCard({required this.snapshot});

  final _DatabaseSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: AppDecoration.gradient(
        colors: const [Color(0xFF0F172A), Color(0xFF2563EB)],
        radius: AppRadius.xxl,
        shadows: AppShadows.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 52,
                width: 52,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(.14),
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                child: const Icon(
                  Icons.storage_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SQLite Inspector',
                      style: AppTextStyles.heading3.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Theo dõi toàn bộ database local của ứng dụng.',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: Colors.white.withOpacity(.82),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              _SummaryPill(
                icon: Icons.table_chart_rounded,
                label: '${snapshot.tables.length} bảng',
              ),
              _SummaryPill(
                icon: Icons.format_list_numbered_rounded,
                label: '${snapshot.totalRows} dòng',
              ),
              _SummaryPill(
                icon: Icons.memory_rounded,
                label: 'Version ${snapshot.version}',
              ),
              _SummaryPill(
                icon: Icons.schedule_rounded,
                label: _formatTime(snapshot.loadedAt),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _formatTime(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    final second = date.second.toString().padLeft(2, '0');
    return '$hour:$minute:$second';
  }
}

class _SummaryPill extends StatelessWidget {
  const _SummaryPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.14),
        borderRadius: BorderRadius.circular(AppRadius.circular),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: AppTextStyles.labelMedium.copyWith(color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: 'Tìm bảng, ví dụ: users, meal_plans, notifications...',
        prefixIcon: const Icon(Icons.search_rounded),
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.4),
        ),
      ),
    );
  }
}

class _TableSelector extends StatelessWidget {
  const _TableSelector({
    required this.tables,
    required this.selectedTableName,
    required this.onSelected,
  });

  final List<_DatabaseTableSnapshot> tables;
  final String? selectedTableName;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    if (tables.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      decoration: AppDecoration.card(
        radius: AppRadius.xxl,
        shadows: AppShadows.soft,
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Danh sách bảng',
            style: AppTextStyles.heading4.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Chọn một bảng để xem cấu trúc cột và toàn bộ dữ liệu đang lưu.',
            style: AppTextStyles.bodySmall,
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: tables.map((table) {
              final selected = table.name == selectedTableName;
              return ChoiceChip(
                selected: selected,
                label: Text('${table.name} (${table.totalRows})'),
                onSelected: (_) => onSelected(table.name),
                selectedColor: AppColors.primarySoft,
                backgroundColor: AppColors.inputBackground,
                labelStyle: AppTextStyles.labelMedium.copyWith(
                  color: selected ? AppColors.primaryDark : AppColors.textMuted,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                ),
                side: BorderSide(
                  color: selected ? AppColors.primary : AppColors.border,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _TableDetailSection extends StatelessWidget {
  const _TableDetailSection({required this.table});

  final _DatabaseTableSnapshot table;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _TableHeaderCard(table: table),
        const SizedBox(height: AppSpacing.md),
        _ColumnsCard(columns: table.columns),
        const SizedBox(height: AppSpacing.md),
        _RowsCard(table: table),
      ],
    );
  }
}

class _TableHeaderCard extends StatelessWidget {
  const _TableHeaderCard({required this.table});

  final _DatabaseTableSnapshot table;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: AppDecoration.card(
        radius: AppRadius.xxl,
        shadows: AppShadows.soft,
      ),
      child: Row(
        children: [
          Container(
            height: 50,
            width: 50,
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: const Icon(
              Icons.view_column_rounded,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  table.name,
                  style: AppTextStyles.heading3.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '${table.columns.length} cột • ${table.totalRows} dòng dữ liệu',
                  style: AppTextStyles.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ColumnsCard extends StatelessWidget {
  const _ColumnsCard({required this.columns});

  final List<_DatabaseColumnSnapshot> columns;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppDecoration.card(
        radius: AppRadius.xxl,
        shadows: AppShadows.soft,
      ),
      child: ExpansionTile(
        initiallyExpanded: true,
        tilePadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        childrenPadding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        title: Text(
          'Cấu trúc cột',
          style: AppTextStyles.heading4.copyWith(fontWeight: FontWeight.w800),
        ),
        subtitle: Text(
          'Tên cột, kiểu dữ liệu, khóa chính và giá trị mặc định.',
          style: AppTextStyles.bodySmall,
        ),
        children: [
          if (columns.isEmpty)
            const _MutedInfoBox(message: 'Bảng này chưa có metadata cột.')
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingTextStyle: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
                dataTextStyle: AppTextStyles.bodySmall,
                columns: const [
                  DataColumn(label: Text('Cột')),
                  DataColumn(label: Text('Kiểu')),
                  DataColumn(label: Text('PK')),
                  DataColumn(label: Text('NOT NULL')),
                  DataColumn(label: Text('Default')),
                ],
                rows: columns.map((column) {
                  return DataRow(
                    cells: [
                      DataCell(Text(column.name)),
                      DataCell(Text(column.type.isEmpty ? '-' : column.type)),
                      DataCell(Text(column.primaryKey ? 'Có' : '-')),
                      DataCell(Text(column.notNull ? 'Có' : '-')),
                      DataCell(Text(column.defaultValue?.toString() ?? '-')),
                    ],
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}

class _RowsCard extends StatelessWidget {
  const _RowsCard({required this.table});

  final _DatabaseTableSnapshot table;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppDecoration.card(
        radius: AppRadius.xxl,
        shadows: AppShadows.soft,
      ),
      child: ExpansionTile(
        initiallyExpanded: true,
        tilePadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        childrenPadding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        title: Text(
          'Dữ liệu trong bảng',
          style: AppTextStyles.heading4.copyWith(fontWeight: FontWeight.w800),
        ),
        subtitle: Text(
          '${table.rows.length} dòng đang được hiển thị trực tiếp từ SQLite.',
          style: AppTextStyles.bodySmall,
        ),
        children: [
          if (table.rows.isEmpty)
            const _MutedInfoBox(message: 'Bảng này hiện chưa có dữ liệu.')
          else
            _RowsDataTable(table: table),
        ],
      ),
    );
  }
}

class _RowsDataTable extends StatelessWidget {
  const _RowsDataTable({required this.table});

  final _DatabaseTableSnapshot table;

  @override
  Widget build(BuildContext context) {
    final columnNames = table.columns.isNotEmpty
        ? table.columns.map((column) => column.name).toList()
        : table.rows.first.keys.map((key) => key.toString()).toList();

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.borderLight),
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columnSpacing: AppSpacing.lg,
            headingRowColor: WidgetStateProperty.all(AppColors.inputBackground),
            headingTextStyle: AppTextStyles.labelMedium.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
            dataTextStyle: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
            columns: columnNames.map((name) {
              return DataColumn(label: Text(name));
            }).toList(),
            rows: table.rows.map((row) {
              return DataRow(
                cells: columnNames.map((columnName) {
                  return DataCell(
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 220),
                      child: SelectableText(
                        _formatCellValue(row[columnName]),
                        maxLines: 4,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  static String _formatCellValue(Object? value) {
    if (value == null) return 'NULL';
    if (value is bool) return value ? 'true' : 'false';
    return value.toString();
  }
}

class _NoTableSelectedCard extends StatelessWidget {
  const _NoTableSelectedCard({required this.hasSearch});

  final bool hasSearch;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: AppDecoration.card(
        radius: AppRadius.xxl,
        shadows: AppShadows.soft,
      ),
      child: Column(
        children: [
          const Icon(
            Icons.search_off_rounded,
            color: AppColors.textHint,
            size: 42,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            hasSearch ? 'Không tìm thấy bảng phù hợp' : 'Chưa chọn bảng',
            style: AppTextStyles.heading4,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            hasSearch
                ? 'Thử nhập tên bảng khác hoặc xóa bộ lọc tìm kiếm.'
                : 'Chọn một bảng phía trên để xem chi tiết.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _MutedInfoBox extends StatelessWidget {
  const _MutedInfoBox({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.inputBackground,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Text(message, style: AppTextStyles.bodySmall),
    );
  }
}

class _DatabaseLoadingState extends StatelessWidget {
  const _DatabaseLoadingState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: AppSpacing.md),
          Text('Đang đọc SQLite...', style: AppTextStyles.bodyMedium),
        ],
      ),
    );
  }
}

class _DatabaseErrorState extends StatelessWidget {
  const _DatabaseErrorState({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: AppDecoration.card(
            radius: AppRadius.xxl,
            shadows: AppShadows.soft,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: AppColors.error,
                size: 48,
              ),
              const SizedBox(height: AppSpacing.md),
              Text('Không đọc được database', style: AppTextStyles.heading4),
              const SizedBox(height: AppSpacing.sm),
              SelectableText(
                message,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodySmall,
              ),
              const SizedBox(height: AppSpacing.lg),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DatabaseEmptyState extends StatelessWidget {
  const _DatabaseEmptyState({required this.onRetry});

  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.storage_rounded,
              color: AppColors.textHint,
              size: 48,
            ),
            const SizedBox(height: AppSpacing.md),
            Text('Chưa tìm thấy bảng SQLite', style: AppTextStyles.heading4),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Database có thể chưa được khởi tạo. Hãy thử tải lại sau khi app tạo dữ liệu.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Tải lại'),
            ),
          ],
        ),
      ),
    );
  }
}
