import 'package:flutter/material.dart';
import 'authentication.dart';
import 'package:firebase_database/firebase_database.dart';
import 'item.dart';
import 'dart:async';
import 'recipePage.dart';
import 'favorites.dart';
import 'package:shimmer/shimmer.dart';
import 'login_signup_page.dart';
import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:image_picker/image_picker.dart';

class HomePage extends StatefulWidget {
  HomePage({Key key, this.auth, this.userId, this.onSignedOut})
      : super(key: key);

  final BaseAuth auth;
  final VoidCallback onSignedOut;
  final String userId;

  @override
  State<StatefulWidget> createState() => new _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Item> _itemList;
  int _currentIndex = 0;
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  final _textEditingController = TextEditingController();
  StreamSubscription<Event> _onTodoAddedSubscription;
  StreamSubscription<Event> _onTodoChangedSubscription;
  Query _todoQuery;

  final TextRecognizer textRecognizer = FirebaseVision.instance.textRecognizer();

  @override
  void initState() {
    super.initState();
    _itemList = new List();
    _todoQuery = _database
        .reference()
        .child("item")
        .orderByChild("userId")
        .equalTo(widget.userId);
    _onTodoAddedSubscription = _todoQuery.onChildAdded.listen(_onEntryAdded);
    _onTodoChangedSubscription = _todoQuery.onChildChanged.listen(_onEntryChanged);
  }

  @override
  void dispose() {
    _onTodoAddedSubscription.cancel();
    _onTodoChangedSubscription.cancel();
    super.dispose();
  }


  _onEntryChanged(Event event) {
    var oldEntry = _itemList.singleWhere((entry) {
      return entry.key == event.snapshot.key;
    });
    setState(() {
      _itemList[_itemList.indexOf(oldEntry)] = Item.fromSnapshot(event.snapshot);
    });
  }

  _onEntryAdded(Event event) {
    setState(() {
      _itemList.add(Item.fromSnapshot(event.snapshot));
    });
  }

  _signOut() async {
    try {
      await widget.auth.signOut();
      widget.onSignedOut();
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => LoginSignUpPage()),
      );
    } catch (e) {
      print(e);
    }
  }

  _addNewItem(String todoItem) {
    if (todoItem.length > 0) {
      Item todo = new Item(todoItem.toString(), widget.userId, false);
      _database.reference().child("item").push().set(todo.toJson());
    }
  }

  _updateItem(Item item){
    //Toggle completed
    item.completed = !item.completed;
    if (item != null) {
      _database.reference().child("item").child(item.key).set(item.toJson());
    }
  }

  _deleteItem(String itemId, int index) {
    _database.reference().child("item").child(itemId).remove().then((_) {
      print("Delete $itemId successful");
      setState(() {
        _itemList.removeAt(index);
      });
    });
  }

  _deleteChecked(context) {
    for(int i = _itemList.length-1; i >= 0; i--)
      if(_itemList[i].completed == true)
        _deleteItem(_itemList[i].key, i);
  }

  _showAddDialog(BuildContext context) async {
    _textEditingController.clear();
    await showDialog<String>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            content: new Row(
              children: <Widget>[
                new Expanded(child: new TextField(
                  style: TextStyle(fontSize: 18.0),
                  controller: _textEditingController,
                  autofocus: true,
                  decoration: new InputDecoration(
                    labelText: 'Add New Item',
                  ),
                ))
              ],
            ),
            actions: <Widget>[
              new RaisedButton(
                  child: const Text('Cancel',
                      style: TextStyle(color: Colors.white)),
                  color: Colors.indigo,
                  onPressed: () {
                    Navigator.pop(context);
                  }),
              new RaisedButton(
                  child: const Text('Save',
                      style: TextStyle(color: Colors.white)
                  ),
                  color: Colors.indigo,
                  onPressed: () {
                    _addNewItem(_textEditingController.text.toString());
                    Navigator.pop(context);
                  }),
               /*new IconButton(
                 icon: Icon(Icons.camera_alt),
                 onPressed: () {
                   _itemsFromPicture(context);
                   Navigator.pop(context);
                 }
                )*/
            ],
          );
        }
    );
  }

  _itemsFromPicture(BuildContext context) async{
    var picture = await ImagePicker.pickImage(
      source: ImageSource.camera,
    );

    final FirebaseVisionImage visionImage = FirebaseVisionImage.fromFile(picture);
    final VisionText visionText = await textRecognizer.processImage(visionImage);

    //String error = "Couldn't find any items in the photo! Please try again!";
    for (TextBlock block in visionText.blocks) {
      for (TextLine line in block.lines) {
          _addNewItem(line.text);
        }
      }
    }

  _showDeleteDialog(BuildContext context) async {
    _textEditingController.clear();
    await showDialog<String>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            content: new Row(
              children: <Widget>[
                new Expanded(child: new TextField(
                  style: TextStyle(fontSize: 18.0),
                  controller: _textEditingController,
                  autofocus: true,
                  decoration: new InputDecoration(
                    labelText: 'Delete Checked Items?',
                  ),
                ))
              ],
            ),
            actions: <Widget>[
              new RaisedButton(
                  child: const Text('No',
                      style: TextStyle(color: Colors.white)
                  ),
                  color: Colors.indigo,
                  onPressed: () {
                    Navigator.pop(context);
                  }),
              new RaisedButton(
                  child: const Text('Yes',
                      style: TextStyle(color: Colors.white)),
                  color: Colors.indigo,
                  onPressed: () {
                    _deleteChecked(context);
                    Navigator.pop(context);
                  })
            ],
          );
        }
    );
  }

  Widget _showItemList() {
    if (_itemList.length > 0) {
      return ListView.builder(
          shrinkWrap: true,
          itemCount: _itemList.length,
          itemBuilder: (BuildContext context, int index) {
            String itemId = _itemList[index].key;
            String subject = _itemList[index].info;
            bool completed = _itemList[index].completed;
            String userId = _itemList[index].userId;
            return Dismissible(
              key: Key(itemId),
              background: Container(color: Colors.indigoAccent),
              onDismissed: (direction) async {
                _deleteItem(itemId, index);
              },
              child: ListTile(
                title: Text(
                  subject,
                  style: TextStyle(fontSize: 20.0),
                ),
                trailing: IconButton(
                    icon: (completed)
                        ? Icon(
                      Icons.done_outline,
                      color: Colors.green,
                      size: 20.0,
                    )
                        : Icon(Icons.done, color: Colors.grey, size: 20.0),
                    onPressed: () {
                      _updateItem(_itemList[index]);
                    }),
              ),
            );
          });
    } else {
      return Center(
          child:
          Padding(
              padding: const EdgeInsets.all(16.0),
              child: Shimmer.fromColors(
                  baseColor: Colors.indigo,
                  highlightColor: Colors.lightBlueAccent,
                  child: Text("Welcome. Your shopping list is empty.",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 30.0))
              )
          )
      );
    }
  }

  void onTabTapped(int index) {
    setState(() {
      switch (index) {
        case 0:
          break;
        case 1:
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => RecipePage()),
          );
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
      drawer: Drawer(
        // Add a ListView to the drawer. This ensures the user can scroll
        // through the options in the Drawer if there isn't enough vertical
        // space to fit everything.
        child: ListView(
          // Important: Remove any padding from the ListView.
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              child: Text('Drawer Header', style: TextStyle(color: Colors.white)),
              decoration: BoxDecoration(
                color: Colors.indigo,
              ),
            ),
            ListTile(
              title: Text('Item 1', style: TextStyle(color: Colors.black)),
              onTap: () {
                // Update the state of the app
                // ...
              },
            ),
            ListTile(
              title: Text('Item 2', style: TextStyle(color: Colors.black)),
              onTap: () {
                // Update the state of the app
                // ...
              },
            ),
          ],
        ),
      ),
        appBar: new AppBar(
          centerTitle: true,
          title: new Center(child: new Text('Shopping List', textAlign: TextAlign.center)),
          actions: <Widget>[
            new FlatButton(
                child: new Text('Logout',
                    style: new TextStyle(fontSize: 17.0, color: Colors.white)),
                onPressed: _signOut)
          ],
        ),
        body: _showItemList(),
        floatingActionButton: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.end,
          children: <Widget>[
            FloatingActionButton(
              heroTag: null,
              onPressed: () {
              _showAddDialog(context);
              },
              tooltip: 'Add Item',
              child: Icon(Icons.add),
              backgroundColor: Colors.green,
         ),
            new Padding(
              padding: new EdgeInsets.symmetric(
                horizontal: 134.0,
              ),
            ),
            FloatingActionButton(
              heroTag: null,
              onPressed: () {
                _showDeleteDialog(context);
              },
              tooltip: 'Remove Checked Items',
              child: Icon(Icons.remove),
              backgroundColor: Colors.red,
            )
       ]
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