class MapLocation {
  final int id;
  final int categoryId;
  final String name;
  final String slug;
  final String country;
  final String state;
  final double latitude;
  final double longitude;
  final String shortDescription;
  final String importantFacts;
  final String examRelevance;
  final int pyqCount;
  final String categoryName;
  final String categoryIcon;
  final List<String> facts;

  const MapLocation({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.slug,
    this.country = 'India',
    this.state = '',
    required this.latitude,
    required this.longitude,
    this.shortDescription = '',
    this.importantFacts = '',
    this.examRelevance = 'High',
    this.pyqCount = 10,
    this.categoryName = 'Geography',
    this.categoryIcon = 'place',
    this.facts = const [],
  });

  factory MapLocation.fromJson(Map<String, dynamic> json) {
    List<String> parsedFacts = [];
    if (json['facts'] is List) {
      parsedFacts = (json['facts'] as List).map((e) => e.toString()).toList();
    } else if (json['important_facts'] != null && json['important_facts'].toString().isNotEmpty) {
      parsedFacts = json['important_facts'].toString().split('.').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    }

    return MapLocation(
      id: json['id'] ?? 0,
      categoryId: json['category_id'] ?? 0,
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      country: json['country'] ?? 'India',
      state: json['state'] ?? '',
      latitude: double.tryParse(json['latitude'].toString()) ?? 21.1243,
      longitude: double.tryParse(json['longitude'].toString()) ?? 70.8242,
      shortDescription: json['short_description'] ?? '',
      importantFacts: json['important_facts'] ?? '',
      examRelevance: json['exam_relevance'] ?? 'High',
      pyqCount: json['pyq_count'] ?? 10,
      categoryName: json['category_name'] ?? 'Geography',
      categoryIcon: json['category_icon'] ?? 'place',
      facts: parsedFacts,
    );
  }
}

class MapCategory {
  final int id;
  final String name;
  final String slug;
  final String icon;

  const MapCategory({
    required this.id,
    required this.name,
    required this.slug,
    this.icon = 'place',
  });

  factory MapCategory.fromJson(Map<String, dynamic> json) {
    return MapCategory(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      icon: json['icon'] ?? 'place',
    );
  }
}
