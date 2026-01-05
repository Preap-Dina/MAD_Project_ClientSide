import 'package:flutter/material.dart';
import '../models/food.dart';
import '../services/api_service.dart';
import '../widgets/food_card.dart';
import '../widgets/bottom_nav.dart';
import '../utils/constants.dart';
import 'food_detail_screen.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final ApiService api = ApiService();
  List<Food> foods = [];
  Set<int> favourites = {};
  bool loading = true;
  String query = '';
  String category = '';

  final TextEditingController _ctrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
    _loadWishlist();
    _ctrl.addListener(() {
      setState(() => query = _ctrl.text);
      _search();
    });
  }

  Future<void> _load() async {
    setState(() => loading = true);
    try {
      final list = await api.getFoods();
      setState(() {
        allFoods = list;
        foods = list;
      });
    } catch (e) {
      // ignore
    } finally {
      setState(() => loading = false);
    }
  }

  Future<void> _loadWishlist() async {
    try {
      final list = await api.getWishlist();
      setState(() => favourites = list.map((f) => f.id).toSet());
    } catch (e) {
      // ignore - not logged in
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

  List<Food> allFoods = [];

  @override
  Widget build(BuildContext context) {
    final categories = allFoods
        .map((e) => e.category ?? '')
        .toSet()
        .where((c) => c.isNotEmpty)
        .toList();
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Consts.primaryColor,
        title: const Text('Explore', style: TextStyle(color: Colors.white)),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12.0),
            child: Center(
              child: Text(
                'TosTver - តោះធ្វើ',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _ctrl,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: 'Search recipes',
                filled: true,
                fillColor: Colors.grey[100],
                suffixIcon: query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _ctrl.clear();
                          setState(() => query = '');
                          _search();
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 0,
                  horizontal: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          if (categories.isNotEmpty)
            SizedBox(
              height: 48,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                scrollDirection: Axis.horizontal,
                itemBuilder: (c, i) {
                  final cat = categories[i];
                  final selected = cat == category;
                  return ChoiceChip(
                    label: Text(
                      cat,
                      style: TextStyle(
                        color: selected ? Colors.white : Colors.black,
                      ),
                    ),
                    selected: selected,
                    onSelected: (v) {
                      setState(() => category = v ? cat : '');
                      _search();
                    },
                    selectedColor: Consts.primaryColor,
                    backgroundColor: Colors.grey[200],
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  );
                },
                separatorBuilder: (_, __) => const SizedBox(width: 8),
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
                          isFavorite: favourites.contains(f.id),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => FoodDetailScreen(foodId: f.id),
                            ),
                          ),
                          onFavoriteToggle: () async {
                            try {
                              if (favourites.contains(f.id)) {
                                final ok = await api.removeFromWishlist(f.id);
                                if (ok) setState(() => favourites.remove(f.id));
                              } else {
                                final ok = await api.addToWishlist(f.id);
                                if (ok) setState(() => favourites.add(f.id));
                              }
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Action failed: ${e.toString()}',
                                  ),
                                ),
                              );
                            }
                          },
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
