import 'package:flutter/material.dart';
import 'package:godarna/widgets/common/app_app_bar.dart';

class AdminScaffold extends StatelessWidget {
  final String title;
  final List<Widget>? actions;
  final Widget body;
  final Widget? bottom;

  const AdminScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions,
    this.bottom,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppAppBar(
        title: title,
        actions: actions,
        // الشاشات الإدارية غالبًا هي جذور تنقل، لا نعرض زر رجوع افتراضيًا
        showBackButton: false,
      ),
      body: Container(
        color: Theme.of(context).colorScheme.surface,
        child: body,
      ),
      bottomNavigationBar: bottom == null
          ? null
          : SafeArea(child: Padding(padding: const EdgeInsets.all(12), child: bottom!)),
    );
  }
}
