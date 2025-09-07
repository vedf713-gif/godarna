import 'package:flutter/material.dart';

class AdminDataTable extends StatelessWidget {
  final List<DataColumn> columns;
  final List<DataRow> rows;
  final EdgeInsetsGeometry margin;

  const AdminDataTable({
    super.key,
    required this.columns,
    required this.rows,
    this.margin = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((0.1 * 255).toInt()),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: WidgetStatePropertyAll(
              Theme.of(context)
                  .colorScheme
                  .primary
                  .withAlpha((0.6 * 255).toInt()),
            ),
            columns: columns,
            rows: rows,
            dataRowMinHeight: 48,
            dataRowMaxHeight: 64,
            headingRowHeight: 56,
            dividerThickness: 0.4,
            headingTextStyle: TextStyle(
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}
