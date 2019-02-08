import 'package:firebase_database/firebase_database.dart';
import 'item.dart';

class Recipe {
  String key;
  String subject;
  bool completed;
  String userId;
  List<String> ingredients;

  Recipe(this.subject, this.userId, this.completed, this.ingredients);

  /*Recipe.fromSnapshot(DataSnapshot snapshot) :
        key = snapshot.key,
        userId = snapshot.value["userId"],
        subject = snapshot.value["subject"],
        completed = snapshot.value["completed"];
        List<String> ingredients = makeList(snapshot.value);

          toJson() {
            return {
              "userId": userId,
              "subject": subject,
              "completed": completed,
              "ingredients": ingredients,
            };
          }
        }*/
}