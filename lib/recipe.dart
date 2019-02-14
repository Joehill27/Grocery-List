import 'package:firebase_database/firebase_database.dart';

class Recipe {
  String key;
  String subject;
  String url;
  String ingredients;
  bool completed;
  String userId;
  var image;

  Recipe(this.subject, this.url, this.ingredients, this.userId,  this.image, this.completed);

  Recipe.fromSnapshot(DataSnapshot snapshot) :
        key = snapshot.key,
        subject = snapshot.value["subject"],
        url = snapshot.value["url"],
        ingredients = snapshot.value["ingredients"],
        userId = snapshot.value["userId"],
        image = snapshot.value["image"],
        completed = snapshot.value["completed"];

  toJson() {
    return {
      "subject": subject,
      "url": url,
      "ingredients": ingredients,
      "userId": userId,
      "image": image,
      "completed": completed,
    };
  }
}