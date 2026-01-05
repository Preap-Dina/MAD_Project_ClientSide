import 'package:flutter/material.dart';
import '../models/food.dart';
import '../services/api_service.dart';
import '../widgets/food_card.dart';
import '../widgets/bottom_nav.dart';
import 'food_detail_screen.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final ApiService api = ApiService();
  List<Food> foods = [];
  bool loading = true;
  String query = '';
  String category = '';

  final TextEditingController _ctrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
    _ctrl.addListener(() {
      setState(() => query = _ctrl.text);
      _search();
    });
  }

  Future<void> _load() async {
    setState(() => loading = true);
    try {
      final list = await api.getFoods();
      setState(() => foods = list);
    } catch (e) {
      // ignore
    } finally {
      setState(() => loading = false);
    }
  }

  Future<void> _search() async {
    setState(() => loading = true);
    try {
      final list = await api.getFoods(
        search: query,
        category: category.isEmpty ? null : category,
      );
      setState(() => foods = list);
    } catch (e) {
      // ignore
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = foods
        .map((e) => e.category ?? '')
        .toSet()
        .where((c) => c.isNotEmpty)
        .toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Explore')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _ctrl,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search recipes',
              ),
            ),
          ),
          if (categories.isNotEmpty)
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemBuilder: (c, i) {
                  final cat = categories[i];
                  final selected = cat == category;
                  return GestureDetector(
                    onTap: () {
                      setState(() => category = selected ? '' : cat);
                      _search();
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: selected ? Colors.grey[300] : Colors.grey[100],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(cat),
                    ),
                  );
                },
                separatorBuilder: (_, __) => const SizedBox(width: 4),
                itemCount: categories.length,
              ),
            ),
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.8,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                          ),
                      itemCount: foods.length,
                      itemBuilder: (c, i) {
                        final f = foods[i];
                        return FoodCard(
                          food: f,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => FoodDetailScreen(foodId: f.id),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
      bottomNavigationBar: const AppBottomNav(index: 1),
    );
  }
}
