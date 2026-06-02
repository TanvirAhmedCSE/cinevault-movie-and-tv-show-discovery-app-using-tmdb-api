import '../model/video_model.dart';
import '../model/tv_model.dart';
import '../constants/constants.dart';
import '../model/cast_model.dart';
import '../model/movie_model.dart';
import 'dart:convert';
import 'package:http/http.dart';

enum MovieType { nowPlaying, popular, topRated, upcoming, similar }

enum TvType { popular, topRated, onTheAir, airingTody, similar }

enum ProgramType { tv, movie }

const String _kApiKey = '2d688d383e42456bd08cf38e9d73ff22';
const String _kPersonURL = 'https://api.themoviedb.org/3/person/';

class ApiService {
  Future<List<MovieModel>> getMovieData(
    MovieType type, {
    int movieID = 0,
  }) async {
    String url = '';
    if (type == MovieType.popular) {
      url = kmoviedbURL + kpopular;
    } else if (type == MovieType.topRated) {
      url = kmoviedbURL + ktop_rated;
    } else if (type == MovieType.upcoming) {
      url = kmoviedbURL + kupcoming;
    } else if (type == MovieType.nowPlaying) {
      url = kmoviedbURL + knowPlaying;
    } else if (type == MovieType.similar) {
      url = kmoviedbURL + movieID.toString() + ksimilar;
    }
    try {
      Response response = await get(
        Uri.parse(url + '?api_key=$_kApiKey&language=en-US'),
      );
      if (response.statusCode == 200) {
        Map<String, dynamic> json = jsonDecode(response.body);
        List<dynamic> body = json['results'];
        return body.map((item) => MovieModel.fromJson(item)).toList();
      } else {
        throw ('No movie found');
      }
    } catch (e) {
      throw (e.toString());
    }
  }

  Future<List<CastModel>> getCastlist(int id, ProgramType type) async {
    String url = '';
    if (type == ProgramType.movie) {
      url = kmoviedbURL + id.toString() + kcredits;
    } else {
      url = ktvdbURL + id.toString() + kcredits;
    }
    try {
      Response response = await get(
        Uri.parse(url + '?api_key=$_kApiKey&language=en-US'),
      );
      if (response.statusCode == 200) {
        Map<String, dynamic> json = jsonDecode(response.body);
        List<dynamic> body = json['cast'];
        return body.map((item) => CastModel.fromJson(item)).toList();
      } else {
        throw ('No cast found');
      }
    } catch (e) {
      throw (e.toString());
    }
  }

  Future<List<VideoModel>> getVideo(int id, ProgramType type) async {
    String url = '';
    if (type == ProgramType.movie) {
      url = kmoviedbURL + id.toString() + kvideos;
    } else {
      url = ktvdbURL + id.toString() + kvideos;
    }
    try {
      Response response = await get(
        Uri.parse(url + '?api_key=$_kApiKey&language=en-US'),
      );
      if (response.statusCode == 200) {
        Map<String, dynamic> json = jsonDecode(response.body);
        List<dynamic> body = json['results'];
        return body.map((item) => VideoModel.fromJson(item)).toList();
      } else {
        throw ('No videos found');
      }
    } catch (e) {
      throw (e.toString());
    }
  }

  Future<List<TVModel>> getTVData(TvType type, {int tvID = 0}) async {
    String url = '';
    if (type == TvType.popular) {
      url = ktvdbURL + kpopular;
    } else if (type == TvType.topRated) {
      url = ktvdbURL + ktop_rated;
    } else if (type == TvType.onTheAir) {
      url = ktvdbURL + kon_the_air;
    } else if (type == TvType.airingTody) {
      url = ktvdbURL + kairringToday;
    } else if (type == TvType.similar) {
      url = ktvdbURL + tvID.toString() + ksimilar;
    }
    try {
      Response response = await get(
        Uri.parse(url + '?api_key=$_kApiKey&language=en-US'),
      );
      if (response.statusCode == 200) {
        Map<String, dynamic> json = jsonDecode(response.body);
        List<dynamic> body = json['results'];
        return body.map((item) => TVModel.fromJson(item)).toList();
      } else {
        throw ('No tv found');
      }
    } catch (e) {
      throw (e.toString());
    }
  }

  Future<Map<String, dynamic>> getCastDetails(int personId) async {
    try {
      Response response = await get(
        Uri.parse('${_kPersonURL}$personId?api_key=$_kApiKey&language=en-US'),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw ('Person not found');
      }
    } catch (e) {
      throw (e.toString());
    }
  }

  Future<List<MovieModel>> getCastMovieCredits(int personId) async {
    try {
      Response response = await get(
        Uri.parse(
          '${_kPersonURL}$personId/movie_credits?api_key=$_kApiKey&language=en-US',
        ),
      );
      if (response.statusCode == 200) {
        Map<String, dynamic> json = jsonDecode(response.body);
        List<dynamic> cast = json['cast'] ?? [];

        List<MovieModel> movies = cast
            .map((item) => MovieModel.fromJson(item))
            .toList();
        movies.sort((a, b) => (b.popularity ?? 0).compareTo(a.popularity ?? 0));
        return movies;
      } else {
        throw ('No movie credits found');
      }
    } catch (e) {
      throw (e.toString());
    }
  }
}
