import 'package:flutter/material.dart';
import 'package:godarna/constants/app_tokens.dart';
import 'package:godarna/widgets/common/app_button.dart';

/// مكونات تحميل مغربية مع تأثير شيمر
class MoroccanSkeletonLoader extends StatefulWidget {
  final Widget child;
  final bool isLoading;

  const MoroccanSkeletonLoader({
    super.key,
    required this.child,
    this.isLoading = true,
  });

  @override
  State<MoroccanSkeletonLoader> createState() => _MoroccanSkeletonLoaderState();
}

class _MoroccanSkeletonLoaderState extends State<MoroccanSkeletonLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    if (widget.isLoading) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(MoroccanSkeletonLoader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isLoading != oldWidget.isLoading) {
      if (widget.isLoading) {
        _controller.repeat();
      } else {
        _controller.stop();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isLoading) {
      return widget.child;
    }

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final cs = Theme.of(context).colorScheme;
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                Colors.transparent,
                cs.onSurface.withAlpha(77),
                Colors.transparent,
              ],
              stops: [
                _animation.value - 0.3,
                _animation.value,
                _animation.value + 0.3,
              ].map((stop) => stop.clamp(0.0, 1.0)).toList(),
            ).createShader(bounds);
          },
          child: widget.child,
        );
      },
    );
  }
}

/// بطاقة عقار skeleton مغربية
class MoroccanPropertyCardSkeleton extends StatelessWidget {
  const MoroccanPropertyCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return MoroccanSkeletonLoader(
      child: Container(
        margin: const EdgeInsets.all(AppTokens.s8),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(AppTokens.s16),
          boxShadow: [
            BoxShadow(
              color: cs.shadow.withAlpha(26),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // صورة العقار
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: cs.surfaceContainerHigh,
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppTokens.s16)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppTokens.s16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // عنوان العقار
                  Container(
                    height: 20,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(AppTokens.s4),
                    ),
                  ),
                  const SizedBox(height: AppTokens.s8),
                  // الموقع
                  Container(
                    height: 16,
                    width: 150,
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(AppTokens.s4),
                    ),
                  ),
                  const SizedBox(height: AppTokens.s12),
                  // السعر والتقييم
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        height: 18,
                        width: 80,
                        decoration: BoxDecoration(
                          color: cs.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(AppTokens.s4),
                        ),
                      ),
                      Container(
                        height: 18,
                        width: 60,
                        decoration: BoxDecoration(
                          color: cs.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(AppTokens.s4),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// قائمة skeleton للعقارات
class MoroccanPropertyListSkeleton extends StatelessWidget {
  final int itemCount;

  const MoroccanPropertyListSkeleton({
    super.key,
    this.itemCount = 6,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: itemCount,
      itemBuilder: (context, index) => const MoroccanPropertyCardSkeleton(),
    );
  }
}

/// skeleton للملف الشخصي
class MoroccanProfileSkeleton extends StatelessWidget {
  const MoroccanProfileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return MoroccanSkeletonLoader(
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.s20),
        child: Column(
          children: [
            // صورة المستخدم
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: cs.surfaceContainerHigh,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(height: AppTokens.s16),
            // اسم المستخدم
            Container(
              height: 24,
              width: 200,
              decoration: BoxDecoration(
                color: cs.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(AppTokens.s4),
              ),
            ),
            const SizedBox(height: AppTokens.s8),
            // البريد الإلكتروني
            Container(
              height: 16,
              width: 250,
              decoration: BoxDecoration(
                color: cs.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(AppTokens.s4),
              ),
            ),
            const SizedBox(height: AppTokens.s24),
            // خيارات الملف الشخصي
            ...List.generate(
                4,
                (index) => Padding(
                      padding: const EdgeInsets.only(bottom: AppTokens.s16),
                      child: Container(
                        height: 50,
                        decoration: BoxDecoration(
                          color: cs.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(AppTokens.s8),
                        ),
                      ),
                    )),
          ],
        ),
      ),
    );
  }
}

/// حالة فارغة مغربية
class MoroccanEmptyState extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final VoidCallback? onAction;
  final String? actionText;

  const MoroccanEmptyState({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    this.onAction,
    this.actionText,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.s32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    cs.primary.withAlpha(26),
                    cs.secondary.withAlpha(26),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 60,
                color: cs.primary,
              ),
            ),
            const SizedBox(height: AppTokens.s24),
            Text(
              title,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: cs.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTokens.s12),
            Text(
              description,
              style: TextStyle(
                fontSize: 16,
                color: cs.onSurfaceVariant,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            if (onAction != null && actionText != null) ...[
              const SizedBox(height: AppTokens.s32),
              AppButton(
                onPressed: onAction,
                text: actionText!,
                type: AppButtonType.primary,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
