import 'dart:async';
import 'package:flutter/material.dart';
import 'package:godarna/constants/app_icons.dart';

class AdminSearchBar extends StatefulWidget {
  final String hint;
  final ValueChanged<String> onSearch;
  final Duration debounce;

  const AdminSearchBar({
    super.key,
    required this.hint,
    required this.onSearch,
    this.debounce = const Duration(milliseconds: 400),
  });

  @override
  State<AdminSearchBar> createState() => _AdminSearchBarState();
}

class _AdminSearchBarState extends State<AdminSearchBar> {
  final TextEditingController _ctrl = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _ctrl.addListener(_onChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  void _onChanged() {
    _debounce?.cancel();
    _debounce =
        Timer(widget.debounce, () => widget.onSearch(_ctrl.text.trim()));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Theme.of(context)
                  .colorScheme
                  .shadow
                  .withAlpha((0.1 * 255).toInt()),
              blurRadius: 10,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Icon(AppIcons.search,
              color: Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _ctrl,
              decoration: InputDecoration(
                hintText: widget.hint,
                border: InputBorder.none,
              ),
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => widget.onSearch(_ctrl.text.trim()),
            ),
          ),
          if (_ctrl.text.isNotEmpty)
            IconButton(
              icon: Icon(AppIcons.clear,
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
              onPressed: () {
                _ctrl.clear();
                widget.onSearch('');
              },
            ),
        ],
      ),
    );
  }
}
