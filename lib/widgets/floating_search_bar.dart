import 'package:flutter/material.dart';
import 'package:godarna/constants/app_strings.dart';

class FloatingSearchBar extends StatefulWidget {
  final VoidCallback onFilterPressed;
  final VoidCallback onCategoryPressed;
  final TextEditingController? searchController;
  final ValueChanged<String>? onSearchChanged;

  const FloatingSearchBar({
    super.key,
    required this.onFilterPressed,
    required this.onCategoryPressed,
    this.searchController,
    this.onSearchChanged,
  });

  @override
  State<FloatingSearchBar> createState() => _FloatingSearchBarState();
}

class _FloatingSearchBarState extends State<FloatingSearchBar> {
  bool _isVisible = true;
  final ScrollController _scrollController = ScrollController();
  double _lastScrollOffset = 0.0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;

    final currentScroll = _scrollController.offset;
    final isScrollingDown = currentScroll > _lastScrollOffset;
    final isAtEdge = !_scrollController.position.outOfRange;

    if (isScrollingDown && isAtEdge && _isVisible) {
      setState(() => _isVisible = false);
    } else if (!isScrollingDown && !_isVisible) {
      setState(() => _isVisible = true);
    }

    _lastScrollOffset = currentScroll;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      top: _isVisible ? 0 : -100,
      left: 0,
      right: 0,
      child: Material(
        elevation: 4,
        color: Colors.white,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 45,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    controller: widget.searchController,
                    onChanged: widget.onSearchChanged,
                    decoration: InputDecoration(
                      hintText:
                          AppStrings.getString('search_properties', context),
                      hintStyle: TextStyle(color: Colors.grey[600]),
                      prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Filter Button
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .primaryColor
                      .withAlpha(25), // ~10% opacity
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: Icon(
                    Icons.filter_list_rounded,
                    color: Theme.of(context).colorScheme.primary,
                    size: 24,
                  ),
                  onPressed: widget.onFilterPressed,
                ),
              ),
              // Category Button
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .primaryColor
                      .withAlpha(25), // ~10% opacity
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: Icon(
                    Icons.category_outlined,
                    color: Theme.of(context).colorScheme.primary,
                    size: 24,
                  ),
                  onPressed: widget.onCategoryPressed,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
