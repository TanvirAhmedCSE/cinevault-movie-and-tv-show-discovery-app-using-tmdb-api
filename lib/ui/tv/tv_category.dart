import 'package:flutter/material.dart';
import '/model/tv_model.dart';
import '../../service/api_service.dart';
import 'components/tv_list_item.dart';

class TvCategory extends StatefulWidget {
  final TvType tvType;
  final int tvID;
  const TvCategory({super.key, required this.tvType, this.tvID = 0});

  @override
  State<TvCategory> createState() => _TvCategoryState();
}

class _TvCategoryState extends State<TvCategory> {
  final ApiService _apiService = ApiService();
  late Future<List<TVModel>> _tvFuture;

  @override
  void initState() {
    super.initState();
    // Cache the future — prevents re-firing on every rebuild
    _tvFuture = _apiService.getTVData(widget.tvType, tvID: widget.tvID);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<TVModel>>(
      future: _tvFuture,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final List<TVModel> tvList = snapshot.data ?? [];
          if (tvList.isEmpty) {
            return Center(
              child: Text(
                'No shows available',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.only(right: 16),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: tvList.length,
            itemBuilder: (context, index) => TvListItem(tvModel: tvList[index]),
          );
        }
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Failed to load',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
            ),
          );
        }
        return const Center(
          child: CircularProgressIndicator(
            color: Color(0xFF00D4C8),
            strokeWidth: 2,
          ),
        );
      },
    );
  }
}
