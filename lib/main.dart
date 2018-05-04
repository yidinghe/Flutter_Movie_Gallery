import 'package:flutter/material.dart';
import 'package:flutter_movie_gallery/database/database.dart';
import 'package:flutter_movie_gallery/model/model.dart';
import 'package:flutter_movie_gallery/screens/movieView.dart';

import 'package:rxdart/rxdart.dart';
import 'package:http/http.dart' as http;

import 'dart:convert';

const key = '3332ce65712d0011fa1d3bd54ba65b6f';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Movie Searcher",
      theme: ThemeData.dark(),
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  HomeState createState() => HomeState();
}

class HomeState extends State<HomePage> {
  List<Movie> movies = List();
  bool hasLoaded = true;
  MovieDatabase db;

  final PublishSubject subject = PublishSubject<String>();

  @override
  void dispose() {
    subject.close();
    db.closeDb();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    db = MovieDatabase();
    db.initDB();
    subject.stream.debounce(Duration(milliseconds: 400)).listen(searchMovies);
  }

  void searchMovies(query) {
    resetMovies();
    if (query.isEmpty) {
      setState(() {
        hasLoaded = true;
      });
      return;
    }
    setState(() => hasLoaded = false);
    http
        .get(
            'https://api.themoviedb.org/3/search/movie?api_key=$key&query=$query')
        .then((res) => (res.body))
        .then(json.decode)
        .then((map) => map["results"])
        .then((movies) => movies.forEach(addMovie))
        .catchError(onError)
        .then((e) {
      setState(() {
        hasLoaded = true;
      });
    });
  }

  void onError(dynamic d) {
    setState(() {
      hasLoaded = true;
    });
  }

  void addMovie(item) {
    setState(() {
      movies.add(Movie.fromJson(item));
    });
    print('${movies.map((m) => m.title)}');
  }

  void resetMovies() {
    setState(() => movies.clear());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Movie Searcher'),
      ),
      body: Container(
        padding: EdgeInsets.all(10.0),
        child: Column(
          children: <Widget>[
            TextField(
              onChanged: (String string) => (subject.add(string)),
            ),
            hasLoaded ? Container() : CircularProgressIndicator(),
            Expanded(
                child: ListView.builder(
              padding: EdgeInsets.all(10.0),
              itemCount: movies.length,
              itemBuilder: (BuildContext context, int index) {
                return new MovieView(movies[index], db);
              },
            ))
          ],
        ),
      ),
    );
  }
}
