import 'package:firebase_database/firebase_database.dart';

class Item {
  String key;
  String info;
  bool completed;
  String userId;

  Item(this.info, this.userId, this.completed);

  Item.fromSnapshot(DataSnapshot snapshot) :
        key = snapshot.key,
        userId = snapshot.value["userId"],
        info = snapshot.value["info"],
        completed = snapshot.value["completed"];

  toJson() {
    return {
      "userId": userId,
      "info": info,
      "completed": completed,
    };
  }
}