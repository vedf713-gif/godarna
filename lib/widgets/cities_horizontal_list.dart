import 'package:flutter/material.dart';
import 'package:godarna/constants/app_strings.dart';
import 'package:godarna/models/property_model.dart';

class CitiesHorizontalList extends StatelessWidget {
  final List<PropertyModel> properties;
  final Function(String city)? onCityTap;

  const CitiesHorizontalList({
    super.key,
    required this.properties,
    this.onCityTap,
  });

  Map<String, List<PropertyModel>> _groupPropertiesByCity() {
    final Map<String, List<PropertyModel>> cityMap = {};

    for (final property in properties) {
      final city = property.city.isNotEmpty ? property.city : 'Unknown';
      if (!cityMap.containsKey(city)) {
        cityMap[city] = [];
      }
      cityMap[city]!.add(property);
    }

    return cityMap;
  }

  @override
  Widget build(BuildContext context) {
    final cityMap = _groupPropertiesByCity();
    final cities = cityMap.entries.toList();

    if (cities.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            AppStrings.getString('exploreCities', context),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        SizedBox(
          height: 200,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            scrollDirection: Axis.horizontal,
            itemCount: cities.length,
            itemBuilder: (context, index) {
              final city = cities[index];
              final cityName = city.key;
              final cityProperties = city.value;

              return GestureDetector(
                onTap: () => onCityTap?.call(cityName),
                child: Container(
                  width: 160,
                  margin:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // City Card with Image
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              // City Image (using first property's image as city image)
                              if (cityProperties.isNotEmpty &&
                                  cityProperties.first.mainPhoto != null)
                                Image.network(
                                  cityProperties.first.mainPhoto!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      _buildPlaceholderIcon(),
                                )
                              else
                                _buildPlaceholderIcon(),
                              // Gradient Overlay
                              Container(
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.transparent,
                                      Color(0x99000000), // 60% opacity black
                                    ],
                                  ),
                                ),
                              ),
                              // City Name
                              Positioned(
                                left: 12,
                                right: 12,
                                bottom: 12,
                                child: Text(
                                  cityName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              // Property Count
                              Positioned(
                                top: 8,
                                right: 8,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.black54,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '${cityProperties.length} ${AppStrings.getString('properties', context)}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceholderIcon() {
    return Container(
      color: Colors.grey[200],
      child: const Icon(Icons.location_city, size: 40, color: Colors.grey),
    );
  }
}
