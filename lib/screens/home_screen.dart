import 'package:flutter/material.dart';
import '../models/food.dart';
import '../services/api_service.dart';
import '../widgets/food_card.dart';
import '../widgets/bottom_nav.dart';
import '../utils/constants.dart';
import 'food_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService api = ApiService();
  List<Food> foods = [];
  Set<int> favourites = {};
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadFoods();
    _loadWishlist();
  }

  Future<void> _loadWishlist() async {
    try {
      final list = await api.getWishlist();
      setState(() {
        favourites = list.map((f) => f.id).toSet();
      });
    } catch (e) {
      // ignore - user may not be logged in
    }
  }

  Future<void> _loadFoods() async {
    setState(() => loading = true);
    try {
      final list = await api.getFoods();
      setState(() {
        foods = list;
      });
    } catch (e) {
      // ignore
    } finally {
      setState(() => loading = false);
    }
  }

  void _toggleFav(Food f) async {
    try {
      if (favourites.contains(f.id)) {
        final success = await api.removeFromWishlist(f.id);
        if (success) {
          setState(() => favourites.remove(f.id));
        }
      } else {
        final success = await api.addToWishlist(f.id);
        if (success) {
          setState(() => favourites.add(f.id));
        }
      }
    } catch (e) {
      // show login required or error
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Action failed: ${e.toString()}')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Consts.primaryColor,
        title: const Text(
          'ទំព័រដើម',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
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
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadFoods,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (foods.isNotEmpty)
                        SizedBox(
                          height: 180,
                          child: PageView(
                            controller: PageController(viewportFraction: 0.92),
                            children: foods
                                .take(5)
                                .map(
                                  (f) => Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6.0,
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: f.image != null
                                          ? Image.network(
                                              f.image!,
                                              fit: BoxFit.cover,
                                              width: double.infinity,
                                            )
                                          : Container(
                                              color: Colors.grey[200],
                                              height: 180,
                                            ),
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                      const SizedBox(height: 16),
                      const Text(
                        'Recipes',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.8,
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8,
                            ),
                        itemCount: foods.length,
                        itemBuilder: (context, idx) {
                          final f = foods[idx];
                          return FoodCard(
                            food: f,
                            isFavorite: favourites.contains(f.id),
                            onTap: () async {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      FoodDetailScreen(foodId: f.id),
                                ),
                              );
                            },
                            onFavoriteToggle: () => _toggleFav(f),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
      bottomNavigationBar: const AppBottomNav(index: 0),
    );
  }
}
