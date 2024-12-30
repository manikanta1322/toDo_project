import 'package:cloud_firestore/cloud_firestore.dart';

class DatabaseMethods {
  Future addTodayWork(Map<String, dynamic> userTodayMap, String id) async {
    return await FirebaseFirestore.instance
        .collection("Today")
        .doc(id)
        .set(userTodayMap);
  }

  Future addTomarrowWork(Map<String, dynamic> userTodayMap, String id) async {
    return await FirebaseFirestore.instance
        .collection("Tomarrow")
        .doc(id)
        .set(userTodayMap);
  }

  Future addNextWeekWork(Map<String, dynamic> userTodayMap, String id) async {
    return await FirebaseFirestore.instance
        .collection("NextWeek")
        .doc(id)
        .set(userTodayMap);
  }

  Future<Stream<QuerySnapshot>> getAllTheWork(String category) async {
    try {
      print("Fetching data for category: $category");
      return FirebaseFirestore.instance.collection(category).snapshots();
    } catch (e) {
      print("Error in getAllTheWork: $e");
      rethrow;
    }
  }


  

  updateifTicked(String id, String day) async {
    return await FirebaseFirestore.instance
        .collection(day)
        .doc(id)
        .update({"Yes": true});
  }
}
