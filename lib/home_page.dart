import 'package:flutter/material.dart';
import 'authentication.dart';
import 'package:firebase_database/firebase_database.dart';
import 'item.dart';
import 'dart:async';

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

  _updateItem(Item todo){
    //Toggle completed
    todo.completed = !todo.completed;
    if (todo != null) {
      _database.reference().child("todo").child(todo.key).set(todo.toJson());
    }
  }

  _deleteItem(String todoId, int index) {
    _database.reference().child("todo").child(todoId).remove().then((_) {
      print("Delete $todoId successful");
      setState(() {
        _itemList.removeAt(index);
      });
    });
  }

  _showDialog(BuildContext context) async {
    _textEditingController.clear();
    await showDialog<String>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            content: new Row(
              children: <Widget>[
                new Expanded(child: new TextField(
                  controller: _textEditingController,
                  autofocus: true,
                  decoration: new InputDecoration(
                    labelText: 'Add new Item',
                  ),
                ))
              ],
            ),
            actions: <Widget>[
              new FlatButton(
                  child: const Text('Cancel'),
                  onPressed: () {
                    Navigator.pop(context);
                  }),
              new FlatButton(
                  child: const Text('Save'),
                  onPressed: () {
                    _addNewItem(_textEditingController.text.toString());
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
      return Center(child: Text("Welcome. Your shopping list is empty",
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 30.0),));
    }
  }

  void onTabTapped(int index) {
    setState(() {
      switch (index) {
        case 0:
          break;
        case 1:
          /*Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => RecipeList()),
          );*/
          break;
        case 2:
          /*Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => Favorite()),
          );*/
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
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
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            _showDialog(context);
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