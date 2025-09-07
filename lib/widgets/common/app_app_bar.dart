import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:godarna/theme/app_dimensions.dart';
import 'package:godarna/constants/app_colors.dart';

/// AppBar موحد للتطبيق بتصميم Airbnb حديث - جميع الشاشات يجب أن تستخدم هذا المكون
class AppAppBar extends StatelessWidget implements PreferredSizeWidget {
  const AppAppBar({
    super.key,
    this.title,
    this.subtitle,
    this.leading,
    this.actions,
    this.centerTitle = true,
    this.backgroundColor,
    this.elevation = 0,
    this.showBackButton = true,
    this.onBackPressed,
    this.bottom,
    this.isTransparent = false,
    this.showShadow = true,
    this.titleColor,
    this.iconColor,
  });

  final String? title;
  final String? subtitle;
  final Widget? leading;
  final List<Widget>? actions;
  final bool centerTitle;
  final Color? backgroundColor;
  final double elevation;
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  final PreferredSizeWidget? bottom;
  final bool isTransparent;
  final bool showShadow;
  final Color? titleColor;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveBackgroundColor = isTransparent
        ? Colors.transparent
        : backgroundColor ??
            (isDark ? AppColors.backgroundPrimaryDark : Colors.white);
    final effectiveTitleColor = titleColor ??
        (isDark ? AppColors.textPrimaryDark : AppColors.textPrimary);
    final effectiveIconColor = iconColor ??
        (isDark ? AppColors.textPrimaryDark : AppColors.textPrimary);

    return Container(
      decoration: showShadow && !isTransparent
          ? BoxDecoration(
              color: effectiveBackgroundColor,
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withAlpha((0.3 * 255).toInt())
                      : AppColors.shadowLight,
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            )
          : null,
      child: AppBar(
        title: _buildTitle(context, effectiveTitleColor, isDark),
        leading: _buildLeading(context, effectiveIconColor),
        actions: _buildActions(context, effectiveIconColor),
        centerTitle: centerTitle,
        backgroundColor: effectiveBackgroundColor,
        foregroundColor: effectiveIconColor,
        elevation: elevation,
        scrolledUnderElevation: 0,
        toolbarHeight: AppDimensions.appBarHeight,
        bottom: bottom,
        surfaceTintColor: effectiveBackgroundColor,
        systemOverlayStyle:
            isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      ),
    );
  }

  Widget? _buildTitle(BuildContext context, Color titleColor, bool isDark) {
    if (title == null && subtitle == null) return null;

    if (subtitle != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (title != null)
            Text(
              title!,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: titleColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'Cairo',
              ),
            ),
          Text(
            subtitle!,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
              fontFamily: 'Cairo',
            ),
          ),
        ],
      );
    }

    return Text(
      title!,
      textAlign: TextAlign.center,
      style: TextStyle(
        color: titleColor,
        fontSize: 20,
        fontWeight: FontWeight.bold,
        fontFamily: 'Cairo',
      ),
    );
  }

  Widget? _buildLeading(BuildContext context, Color iconColor) {
    if (leading != null) return leading;

    if (showBackButton && Navigator.of(context).canPop()) {
      return Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isTransparent
              ? Colors.white.withAlpha((0.9 * 255).toInt())
              : Colors.transparent,
          shape: BoxShape.circle,
          boxShadow: isTransparent
              ? [
                  BoxShadow(
                    color: Colors.black.withAlpha((0.1 * 255).toInt()),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: IconButton(
          onPressed: () {
            HapticFeedback.lightImpact();
            if (onBackPressed != null) {
              onBackPressed!();
            } else {
              Navigator.of(context).pop();
            }
          },
          icon: Icon(
            Icons.arrow_back_ios_rounded,
            size: AppDimensions.iconLarge,
            color: isTransparent ? AppColors.textPrimary : iconColor,
          ),
          splashRadius: 20,
        ),
      );
    }

    return null;
  }

  List<Widget>? _buildActions(BuildContext context, Color iconColor) {
    if (actions == null) return null;

    return actions!.map((action) {
      if (action is IconButton) {
        return Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isTransparent
                ? Colors.white.withAlpha((0.9 * 255).toInt())
                : Colors.transparent,
            shape: BoxShape.circle,
            boxShadow: isTransparent
                ? [
                    BoxShadow(
                      color: Colors.black.withAlpha((0.1 * 255).toInt()),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: IconButton(
            onPressed: action.onPressed,
            icon: action.icon,
            splashRadius: 20,
          ),
        );
      }
      return action;
    }).toList();
  }

  @override
  Size get preferredSize => const Size.fromHeight(AppDimensions.appBarHeight);
}

/// AppBar خاص بالشاشة الرئيسية بتصميم Airbnb
class HomeAppBar extends StatelessWidget implements PreferredSizeWidget {
  const HomeAppBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.showLogo = false,
  });

  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool showLogo;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppAppBar(
      title: showLogo ? null : title,
      showBackButton: false,
      leading: showLogo ? _buildLogo(isDark) : leading,
      actions: _buildEnhancedActions(context, actions, isDark),
      backgroundColor: isDark ? AppColors.backgroundPrimaryDark : Colors.white,
      showShadow: true,
    );
  }

  Widget _buildLogo(bool isDark) {
    return Container(
      margin: const EdgeInsets.all(8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primaryRed, AppColors.primaryRedLight],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.villa_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'GoDarna',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
              fontFamily: 'Cairo',
            ),
          ),
        ],
      ),
    );
  }

  List<Widget>? _buildEnhancedActions(
      BuildContext context, List<Widget>? originalActions, bool isDark) {
    if (originalActions == null) return null;

    return originalActions.map((action) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: isDark ? AppColors.backgroundCardDark : AppColors.grey50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? AppColors.borderMediumDark : AppColors.borderLight,
          ),
        ),
        child: action,
      );
    }).toList();
  }

  @override
  Size get preferredSize => const Size.fromHeight(AppDimensions.appBarHeight);
}

/// AppBar مع شريط بحث بتصميم Airbnb
class SearchAppBar extends StatelessWidget implements PreferredSizeWidget {
  const SearchAppBar({
    super.key,
    required this.onSearchChanged,
    this.hintText,
    this.actions,
    this.showBackButton = true,
    this.onFilterTap,
    this.filterCount = 0,
  });

  final ValueChanged<String> onSearchChanged;
  final String? hintText;
  final List<Widget>? actions;
  final bool showBackButton;
  final VoidCallback? onFilterTap;
  final int filterCount;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.backgroundPrimaryDark : Colors.white,
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withAlpha((0.3 * 255).toInt())
                : AppColors.shadowLight,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: showBackButton,
        toolbarHeight: AppDimensions.appBarHeight,
        title: _buildSearchBar(context, isDark),
        actions: _buildFilterActions(context, isDark),
        systemOverlayStyle:
            isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context, bool isDark) {
    return Container(
      height: 48,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.backgroundCardDark : AppColors.grey50,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? AppColors.borderMediumDark : AppColors.borderLight,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withAlpha((0.2 * 255).toInt())
                : AppColors.shadowLight,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        onChanged: onSearchChanged,
        decoration: InputDecoration(
          hintText: hintText ?? 'ابحث عن مدينة أو عنوان',
          hintStyle: TextStyle(
            color:
                isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
            fontFamily: 'Cairo',
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            color:
                isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
          ),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          isDense: true,
        ),
        style: TextStyle(
          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
          fontFamily: 'Cairo',
        ),
      ),
    );
  }

  List<Widget>? _buildFilterActions(BuildContext context, bool isDark) {
    List<Widget> filterActions = [];

    // إضافة زر الفلتر
    if (onFilterTap != null) {
      filterActions.add(
        Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: filterCount > 0
                ? AppColors.primaryRed
                : (isDark ? AppColors.backgroundCardDark : AppColors.grey50),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: filterCount > 0
                  ? AppColors.primaryRed
                  : (isDark
                      ? AppColors.borderMediumDark
                      : AppColors.borderLight),
            ),
          ),
          child: Stack(
            children: [
              IconButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  onFilterTap!();
                },
                icon: Icon(
                  Icons.tune_rounded,
                  color: filterCount > 0
                      ? Colors.white
                      : (isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimary),
                ),
                splashRadius: 20,
              ),
              if (filterCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      filterCount.toString(),
                      style: const TextStyle(
                        color: AppColors.primaryRed,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    }

    // إضافة الإجراءات الإضافية
    if (actions != null) {
      filterActions.addAll(actions!);
    }

    return filterActions.isNotEmpty ? filterActions : null;
  }

  @override
  Size get preferredSize => const Size.fromHeight(AppDimensions.appBarHeight);
}
