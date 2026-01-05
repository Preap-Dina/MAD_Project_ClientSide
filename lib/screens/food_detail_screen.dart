import 'package:flutter/material.dart';
import '../models/food.dart';
import '../services/api_service.dart';
import '../widgets/bottom_nav.dart';
import '../utils/constants.dart';

class FoodDetailScreen extends StatefulWidget {
  final int foodId;
  const FoodDetailScreen({super.key, required this.foodId});

  @override
  State<FoodDetailScreen> createState() => _FoodDetailScreenState();
}

class _FoodDetailScreenState extends State<FoodDetailScreen> {
  final ApiService api = ApiService();
  Food? food;
  List<Food> related = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    try {
      final f = await api.getFood(widget.foodId);
      final rel = await api.getFoods(category: f.category);
      setState(() {
        food = f;
        related = rel.where((e) => e.id != f.id).toList();
      });
    } catch (e) {
      // ignore
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Consts.primaryColor,
        title: const Text('Detail', style: TextStyle(color: Colors.white)),
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
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (food?.image != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          food!.image!,
                          errorBuilder: (c, e, s) => Container(
                            color: Colors.grey[200],
                            height: 180,
                            child: const Center(
                              child: Icon(Icons.broken_image),
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 12),
                    Text(
                      food?.name ?? '',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Consts.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Ingredients',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    _buildMultilineText(food?.ingredients),
                    const SizedBox(height: 8),
                    Text(
                      'Steps',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    _buildMultilineText(food?.steps),
                    const SizedBox(height: 16),
                    if (related.isNotEmpty) ...[
                      const Text(
                        'Related',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 160,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemBuilder: (c, i) {
                            final r = related[i];
                            return GestureDetector(
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      FoodDetailScreen(foodId: r.id),
                                ),
                              ),
                              child: SizedBox(
                                width: 140,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: r.image != null
                                            ? Image.network(
                                                r.image!,
                                                fit: BoxFit.cover,
                                                width: 140,
                                                errorBuilder: (c, e, s) =>
                                                    Container(
                                                      color: Colors.grey[200],
                                                      child: const Center(
                                                        child: Icon(
                                                          Icons.broken_image,
                                                        ),
                                                      ),
                                                    ),
                                              )
                                            : Container(
                                                color: Colors.grey[200],
                                              ),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      r.name,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemCount: related.length,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
      bottomNavigationBar: const AppBottomNav(index: 0),
    );
  }
}

Widget _buildMultilineText(String? raw) {
  if (raw == null || raw.trim().isEmpty) return const Text('-');
  final normalized = raw.replaceAll(r'\r\n', '\n').replaceAll('\r\n', '\n');
  return Text(normalized, style: TextStyle(color: Consts.descriptionColor));
}
