import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:godarna/mixins/realtime_mixin.dart';
import 'package:godarna/providers/property_provider.dart';
import 'package:godarna/providers/auth_provider.dart';
import 'package:godarna/constants/app_strings.dart';
import 'package:godarna/widgets/property_card.dart' show PropertyCardCompact;
import 'package:godarna/screens/property/add_property_screen.dart';
import 'package:godarna/screens/property/edit_property_screen.dart';
import 'package:godarna/widgets/common/app_app_bar.dart';

class MyPropertiesScreen extends StatefulWidget {
  const MyPropertiesScreen({super.key});

  @override
  State<MyPropertiesScreen> createState() => _MyPropertiesScreenState();
}

class _MyPropertiesScreenState extends State<MyPropertiesScreen> with RealtimeMixin {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final hostId = auth.currentUser?.id;
      if (hostId != null) {
        Provider.of<PropertyProvider>(context, listen: false)
            .fetchMyProperties(hostId);
        _setupRealtimeSubscriptions();
      }
    });
  }

  void _setupRealtimeSubscriptions() {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final hostId = auth.currentUser?.id;
    
    if (hostId == null) return;
    
    // اشتراك في تحديثات العقارات الخاصة بالمضيف
    subscribeToTable(
      table: 'properties',
      filter: 'host_id',
      filterValue: hostId,
      onInsert: (payload) {
        if (mounted) {
          final propertyProvider = Provider.of<PropertyProvider>(context, listen: false);
          propertyProvider.fetchMyProperties(hostId);
        }
      },
      onUpdate: (payload) {
        if (mounted) {
          final propertyProvider = Provider.of<PropertyProvider>(context, listen: false);
          propertyProvider.fetchMyProperties(hostId);
        }
      },
      onDelete: (payload) {
        if (mounted) {
          final propertyProvider = Provider.of<PropertyProvider>(context, listen: false);
          propertyProvider.fetchMyProperties(hostId);
        }
      },
    );
  }

  @override
  void dispose() {
    unsubscribeAll();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFFFF3A44); // Airbnb Red

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppAppBar(title: AppStrings.getString('myProperties', context)),
      body: Consumer<PropertyProvider>(
        builder: (context, propertyProvider, child) {
          if (propertyProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (propertyProvider.myProperties.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.home_outlined, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 20),
                  Text(
                    AppStrings.getString('noPropertiesYet', context),
                    style: const TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AddPropertyScreen(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('أضف أول عقار',
                        style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: propertyProvider.myProperties.length,
            itemBuilder: (context, index) {
              final property = propertyProvider.myProperties[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Stack(
                  children: [
                    // Property Card
                    PropertyCardCompact(
                      property: property,
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          '/property-details',
                          arguments: property,
                        );
                      },
                    ),

                    // More Options Button
                    Positioned(
                      top: 8,
                      right: 8,
                      child: PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'edit') {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    EditPropertyScreen(property: property),
                              ),
                            );
                          } else if (value == 'delete') {
                            _showDeleteDialog(
                                context, propertyProvider, property.id);
                          }
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                const Icon(Icons.edit,
                                    size: 18, color: Colors.black),
                                const SizedBox(width: 8),
                                Text('تعديل',
                                    style:
                                        Theme.of(context).textTheme.bodyMedium),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, size: 18, color: Colors.red),
                                SizedBox(width: 8),
                                Text('حذف',
                                    style: TextStyle(color: Colors.red)),
                              ],
                            ),
                          ),
                        ],
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color:
                                    Colors.black.withAlpha((0.1 * 255).round()),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.more_vert,
                              size: 20, color: Colors.grey),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const AddPropertyScreen(),
            ),
          );
        },
        backgroundColor: primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context,
      PropertyProvider propertyProvider, String propertyId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف العقار'),
        content: const Text('هل أنت متأكد أنك تريد حذف هذا العقار؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await propertyProvider.deleteProperty(propertyId);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('تم حذف العقار بنجاح'),
                      backgroundColor: Color(0xFF00D1B2),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('حدث خطأ: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('حذف', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
