class Food {
  final int id;
  final String name;
  final String? category;
  final String? ingredients;
  final String? steps;
  final String? image;

  Food({
    required this.id,
    required this.name,
    this.category,
    this.ingredients,
    this.steps,
    this.image,
  });

  factory Food.fromJson(Map<String, dynamic> json) {
    return Food(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      category: json['category'],
      ingredients: json['ingredients'],
      steps: json['steps'],
      image: json['image'],
    );
  }
}
