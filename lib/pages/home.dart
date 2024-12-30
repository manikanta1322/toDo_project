import 'dart:ffi';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:random_string/random_string.dart';
import 'package:to_do_project/services/database.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  bool today = true, tomorrow = false, nextWeek = false;
  bool suggest = false;
  Stream? todoStream;

  getOnTheLoad() async {
    Stream<QuerySnapshot> stream = await DatabaseMethods().getAllTheWork(
        today ? "Today" : tomorrow ? "Tomarrow" : "NextWeek"
    );
    setState(() {
        todoStream = stream;
    });
}

  @override
  void initState() {
    getOnTheLoad();
    super.initState();
  }

 Widget allWork() {
  return Expanded(
    child: StreamBuilder(
        stream: todoStream,
        builder: (context, AsyncSnapshot snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasData && snapshot.data.docs.isNotEmpty) {
            return ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: snapshot.data.docs.length,
              itemBuilder: (context, index) {
                DocumentSnapshot ds = snapshot.data.docs[index];
                return CheckboxListTile(
                  title: Text(
                    ds["Work"],
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold),
                  ),
                  value: ds["Yes"],
                  onChanged: (value) async {
                    await DatabaseMethods().updateifTicked(ds.id,
                        today ? "Today" : tomorrow ? "Tomarrow" : "NextWeek");
                    setState(() {
                    
                    });
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                  activeColor: Color(0xff279cfb),
                );
              },
            );
          } else {
            return Center(
              child: Text(
                "No data available.",
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            );
          }
        }),
  );
}


  TextEditingController toDoController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          openBox();
        },
        // backgroundColor: Color(0xff279cfb),
        child: Icon(
          Icons.add,
          color: Color(0xff249fff),
          size: 30,
        ),
      ),
      body: Container(
        padding: EdgeInsets.only(top: 90, left: 30),
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xff232FDA2),
              Color(0xff13D8CA),
              Color(0xff09adfe),
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Hello World",
              style: TextStyle(
                color: Colors.white,
                fontSize: 30,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(
              height: 10,
            ),
            Text(
              "Good Morning",
              style: TextStyle(
                color: Colors.white,
                fontSize: 30,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(
              height: 10,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                today
                    ? Material(
                        elevation: 5,
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                          decoration: BoxDecoration(
                            color: Color(0xff3dffe3),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            "Today",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      )
                    : GestureDetector(
                        onTap: () async {
                          today = true;
                          tomorrow = false;
                          nextWeek = false;
                          await getOnTheLoad();
                          setState(() {});
                        },
                        child: Text(
                          "Today",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                tomorrow
                    ? Material(
                        elevation: 5,
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                          decoration: BoxDecoration(
                            color: Color(0xff3dffe3),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            "Tomorrow",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      )
                    : GestureDetector(
                        onTap: () async {
                          today = false;
                          tomorrow = true;
                          nextWeek = false;
                          await getOnTheLoad();
                          setState(() {});
                        },
                        child: Text(
                          "Tomorrow",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                nextWeek
                    ? Material(
                        elevation: 5,
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                          decoration: BoxDecoration(
                            color: Color(0xff3dffe3),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            "Next Week",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      )
                    : GestureDetector(
                        onTap: () async {
                          today = false;
                          tomorrow = false;
                          nextWeek = true;
                          await getOnTheLoad();
                          setState(() {});
                        },
                        child: Text(
                          "Next Week",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
              ],
            ),
            SizedBox(
              height: 20,
            ),
            allWork(),
          ],
        ),
      ),
    );
  }

  Future openBox() => showDialog(
      context: context,
      builder: (context) => AlertDialog(
            content: SingleChildScrollView(
                child: Container(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      GestureDetector(
                          onTap: () {
                            Navigator.pop(context);
                          },
                          child: Icon(Icons.cancel)),
                      SizedBox(
                        width: 60,
                      ),
                      Text(
                        "Add the Work TODO",
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  SizedBox(
                    height: 10,
                  ),
                  Text("Add Text"),
                  SizedBox(
                    height: 10,
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.black38, width: 2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: TextField(
                      controller: toDoController,
                      decoration: InputDecoration(
                        hintText: "Enter text",
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 10,
                  ),
                  GestureDetector(
                    onTap: () {
                      String id = randomAlphaNumeric(10);
                      Map<String, dynamic> userToDo = {
                        "id": id,
                        "Work": toDoController.text,
                        "Yes": false,
                      };
                      today
                          ? DatabaseMethods().addTodayWork(userToDo, id)
                          : tomorrow
                              ? DatabaseMethods().addTomarrowWork(userToDo, id)
                              : DatabaseMethods().addNextWeekWork(userToDo, id);
                      Navigator.pop(context);
                    },
                    child: Center(
                      child: Container(
                        width: 100,
                        padding: EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: Color(0xff008080),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          "Add",
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  )
                ],
              ),
            )),
            // actions: [TextButton(onPressed: () {}, child: Text("Submit"))],
          ));
}
