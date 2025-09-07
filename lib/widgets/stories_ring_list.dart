import 'package:flutter/material.dart';
import 'package:godarna/widgets/bouncy_tap.dart';

class StoryItem {
  final String title;
  final String image;
  final VoidCallback? onTap;

  const StoryItem({required this.title, required this.image, this.onTap});
}

class StoriesRingList extends StatelessWidget {
  final List<StoryItem> items;
  final EdgeInsetsGeometry padding;

  const StoriesRingList({
    super.key,
    required this.items,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 110,
      child: ListView.separated(
        padding: padding,
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          final it = items[index];
          return _StoryRing(item: it);
        },
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemCount: items.length,
      ),
    );
  }
}

class _StoryRing extends StatelessWidget {
  final StoryItem item;
  const _StoryRing({required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final ringColors = isDark
        ? [theme.colorScheme.secondary, theme.colorScheme.onSurfaceVariant, theme.colorScheme.tertiary]
        : [theme.colorScheme.primary, theme.colorScheme.surface, theme.colorScheme.secondary];

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        BouncyTap(
          scale: 0.9,
          onTap: item.onTap,
          child: Container(
            width: 70,
            height: 70,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: ringColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                if (isDark)
                  BoxShadow(
                    color: theme.colorScheme.primary.withAlpha(77),
                    blurRadius: 18,
                    spreadRadius: 1,
                  ),
              ],
            ),
            child: Container(
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
              padding: const EdgeInsets.all(3),
              child: ClipOval(
                child: Image.asset(
                  item.image,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stack) {
                    final theme = Theme.of(context);
                    final isDark = theme.brightness == Brightness.dark;
                    return Container(
                      color: isDark ? theme.colorScheme.surface : Colors.white,
                      child: Icon(
                        Icons.bolt,
                        color: isDark ? Theme.of(context).colorScheme.onSurfaceVariant : theme.colorScheme.primary,
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: 76,
          child: Text(
            item.title,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700),
          ),
        )
      ],
    );
  }
}
