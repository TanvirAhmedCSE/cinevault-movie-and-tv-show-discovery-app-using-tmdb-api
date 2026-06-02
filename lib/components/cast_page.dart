import 'package:flutter/material.dart';
import '../model/cast_model.dart';
import '../service/api_service.dart';
import 'cast_list_item.dart';

class CastPage extends StatefulWidget {
  final int id;
  final ProgramType type;
  final Color accentColor;

  const CastPage({
    super.key,
    required this.id,
    required this.type,
    this.accentColor = const Color(0xFFE50914),
  });

  @override
  State<CastPage> createState() => _CastPageState();
}

class _CastPageState extends State<CastPage> {
  final ApiService _apiService = ApiService();
  late Future<List<CastModel>> _castFuture;

  @override
  void initState() {
    super.initState();
    _castFuture = _apiService.getCastlist(widget.id, widget.type);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<CastModel>>(
      future: _castFuture,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final List<CastModel> castList = snapshot.data ?? [];
          if (castList.isEmpty) {
            return Center(
              child: Text(
                'No cast available',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.only(left: 0, right: 6),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: castList.length,
            itemBuilder: (context, index) => CastListItem(
              castModel: castList[index],
              accentColor: widget.accentColor,
            ),
          );
        }
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Failed to load cast',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
            ),
          );
        }
        return Center(
          child: CircularProgressIndicator(
            color: widget.accentColor,
            strokeWidth: 2,
          ),
        );
      },
    );
  }
}
