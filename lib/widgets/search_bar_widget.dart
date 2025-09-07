import 'package:flutter/material.dart';
import 'package:godarna/constants/app_strings.dart';
import 'package:godarna/constants/app_icons.dart';
import 'package:godarna/constants/app_tokens.dart';

class SearchBarWidget extends StatefulWidget {
  final Function(String) onSearch;
  final VoidCallback onFilterTap;
  final String? initialQuery;

  const SearchBarWidget({
    super.key,
    required this.onSearch,
    required this.onFilterTap,
    this.initialQuery,
  });

  @override
  State<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.initialQuery != null) {
      _searchController.text = widget.initialQuery!;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: AppTokens.r16,
        border: Border.all(color: cs.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withAlpha(15),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: AppStrings.getString('searchHint', context),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppTokens.s16, vertical: AppTokens.s16),
                prefixIcon: Icon(
                  AppIcons.search,
                  color: cs.onSurfaceVariant,
                ),
              ),
              onChanged: (value) {
                widget.onSearch(value);
              },
            ),
          ),
          Container(
            height: 40,
            width: 1,
            color: cs.outlineVariant,
          ),
          IconButton(
            onPressed: widget.onFilterTap,
            icon: Icon(AppIcons.filter, color: cs.primary),
          ),
        ],
      ),
    );
  }
}
