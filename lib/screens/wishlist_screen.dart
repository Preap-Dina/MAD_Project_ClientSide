import 'package:flutter/material.dart';
import '../models/food.dart';
import '../services/api_service.dart';
import '../widgets/food_card.dart';
import 'food_detail_screen.dart';
import '../widgets/bottom_nav.dart';

class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key});

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  final ApiService api = ApiService();
  List<Food> items = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    try {
      final list = await api.getWishlist();
      setState(() => items = list);
    } catch (e) {
      // ignore
    } finally {
      setState(() => loading = false);
    }
  }

  Future<void> _remove(Food f) async {
    try {
      await api.removeFromWishlist(f.id);
      await _load();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to remove')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Wishlist')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(12.0),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.8,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: items.length,
                itemBuilder: (c, i) {
                  final f = items[i];
                  return FoodCard(
                    food: f,
                    isFavorite: true,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => FoodDetailScreen(foodId: f.id),
                      ),
                    ),
                    onFavoriteToggle: () => _remove(f),
                  );
                },
              ),
            ),
      bottomNavigationBar: const AppBottomNav(index: 2),
    );
  }
}
