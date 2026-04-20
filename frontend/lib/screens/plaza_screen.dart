import 'package:flutter/material.dart';

class PlazaScreen extends StatefulWidget {
  const PlazaScreen({super.key});

  @override
  State<PlazaScreen> createState() => _PlazaScreenState();
}

class _PlazaScreenState extends State<PlazaScreen> {
  static const List<String> _categories = <String>[
    '推荐',
    '同城',
    '运动',
    '学习',
    '约饭',
    '拼车',
    '悬赏',
  ];
  int _selectedCategory = 0;

  List<_PlazaPost> get _posts => List<_PlazaPost>.generate(14, (int i) {
        return _PlazaPost(
          title: '${_categories[_selectedCategory]}动态 ${i + 1}',
          content: '这是来自${_categories[_selectedCategory]}频道的内容，帮助你快速发现有趣的同城活动与搭子。',
          tag: i % 2 == 0 ? '同城' : '热门',
        );
      });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: <Color>[Color(0xFFF8FAFC), Color(0xFFEEF2FF)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        children: <Widget>[
          const Padding(
            padding: EdgeInsets.fromLTRB(12, 10, 12, 0),
            child: _PlazaBanner(),
          ),
          Container(
            width: double.infinity,
            color: const Color(0xFFF7F8FF),
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List<Widget>.generate(_categories.length, (int i) {
                  final bool selected = _selectedCategory == i;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      selected: selected,
                      label: Text(_categories[i]),
                      onSelected: (_) => setState(() => _selectedCategory = i),
                    ),
                  );
                }),
              ),
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 90),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 0.8,
              ),
              itemCount: _posts.length,
              itemBuilder: (BuildContext context, int index) {
                return _PlazaWaterfallCard(post: _posts[index]);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PlazaBanner extends StatelessWidget {
  const _PlazaBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: const LinearGradient(
          colors: <Color>[Color(0xFF6D5EF9), Color(0xFF8B80FF)],
        ),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            '趣同行广场',
            style: TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 4),
          Text(
            '瀑布流展示、分类吸顶，快速发现你感兴趣的内容',
            style: TextStyle(color: Color(0xFFEDE9FE), fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _PlazaPost {
  _PlazaPost({
    required this.title,
    required this.content,
    required this.tag,
  });

  final String title;
  final String content;
  final String tag;
}

class _PlazaWaterfallCard extends StatelessWidget {
  const _PlazaWaterfallCard({required this.post});

  final _PlazaPost post;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              post.tag,
              style: const TextStyle(
                color: Color(0xFF6D5EF9),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              post.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Expanded(
              child: Text(
                post.content,
                maxLines: 6,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12.5),
              ),
            ),
            const SizedBox(height: 6),
            const Row(
              children: <Widget>[
                Icon(Icons.favorite_border, size: 16),
                SizedBox(width: 4),
                Text('赞', style: TextStyle(fontSize: 11)),
                SizedBox(width: 10),
                Icon(Icons.chat_bubble_outline, size: 16),
                SizedBox(width: 4),
                Text('评论', style: TextStyle(fontSize: 11)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
