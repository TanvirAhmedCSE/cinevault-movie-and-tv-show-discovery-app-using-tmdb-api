import 'package:flutter/material.dart';
import '/model/movie_model.dart';
import '/service/api_service.dart';
import 'components/movie_list_item.dart';

class MoviesCategory extends StatefulWidget {
  final MovieType movieType;
  final int movieID;

  const MoviesCategory({super.key, required this.movieType, this.movieID = 0});

  @override
  State<MoviesCategory> createState() => _MoviesCategoryState();
}

class _MoviesCategoryState extends State<MoviesCategory> {
  final ApiService apiService = ApiService();
  late Future<List<MovieModel>> _movieFuture;

  @override
  void initState() {
    super.initState();
    // Cache future in initState — prevents re-firing on every rebuild
    _movieFuture = apiService.getMovieData(
      widget.movieType,
      movieID: widget.movieID,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _movieFuture,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final List<MovieModel> movies = snapshot.data ?? [];
          return ListView.builder(
            padding: const EdgeInsets.only(right: 16),
            itemBuilder: (context, index) =>
                MovieListItem(movieModel: movies[index]),
            itemCount: movies.length,
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
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
            color: Color(0xFFE50914),
            strokeWidth: 2,
          ),
        );
      },
    );
  }
}
