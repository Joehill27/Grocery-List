import 'package:firebase_database/firebase_database.dart';
import 'authentication.dart';
import 'recipe.dart';
import 'package:flutter/material.dart';
import 'home_page.dart';
import 'favorites.dart';

class RecipePage extends StatefulWidget {
  RecipePage({Key key, this.auth, this.userId, this.onSignedOut})
      : super(key: key);

  final BaseAuth auth;
  final VoidCallback onSignedOut;
  final String userId;

  @override
  State<StatefulWidget> createState() => new _RecipePageState();
}

class _RecipePageState extends State<RecipePage> {
  List<Recipe> _recipeList;
  int _currentIndex = 1;
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  final _textEditingController = TextEditingController();

  Query _todoQuery;

    _signOut() async {
      try {
        await widget.auth.signOut();
        widget.onSignedOut();
      } catch (e) {
        print(e);
      }
    }

    void onTabTapped(int index) {
      setState(() {
        switch (index) {
          case 0:
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => HomePage()),
            );
            break;
          case 1:
            break;
          case 2:
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => FavoritePage()),
          );
            break;
        }
      });
    }

    @override
    Widget build(BuildContext context) {
      return new Scaffold(
        appBar: new AppBar(
          centerTitle: true,
          title: new Center(child: new Text('Recipe List', textAlign: TextAlign.center)),
          actions: <Widget>[
            new FlatButton(
                child: new Text('Logout',
                    style: new TextStyle(fontSize: 17.0, color: Colors.white)),
                onPressed: _signOut)
          ],
        ),
        body: null,
        floatingActionButton: FloatingActionButton(
          onPressed: () {
          },
          tooltip: 'Increment',
          child: Icon(Icons.add),
        ),
        bottomNavigationBar: BottomNavigationBar(
            onTap: onTabTapped,
            currentIndex: _currentIndex,
            fixedColor: Colors.indigoAccent,
            items: [
              BottomNavigationBarItem(
                icon: new Icon(Icons.local_grocery_store),
                title: new Text('Shopping List', style: TextStyle(
                    fontWeight: FontWeight.bold),
                ),
              ),
              BottomNavigationBarItem(
                icon: new Icon(Icons.library_books),
                title: new Text('Recipes',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              BottomNavigationBarItem(
                icon: new Icon(Icons.favorite),
                title: new Text('Fav Recipes', style: TextStyle(
                    fontWeight: FontWeight.bold),
                ),
              ),
            ]
        ),
      );
    }
  }