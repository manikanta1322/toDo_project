// ignore_for_file: use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:random_string/random_string.dart';
import 'package:to_do_project/services/database.dart';
import 'package:to_do_project/services/notifications.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  bool today = true, tomorrow = false, nextWeek = false;
  Stream? todoStream;
  String greeting = "";

  TextEditingController toDoController = TextEditingController();
  TimeOfDay? selectedTime;

  getOnTheLoad() async {
    try {
      Stream<QuerySnapshot> stream = await DatabaseMethods().getAllTheWork(
        today
            ? "Today"
            : tomorrow
                ? "Tomorrow"
                : "NextWeek",
      );
      setState(() {
        todoStream = stream;
      });
    } catch (e) {
      print("Error fetching data: $e");
    }
  }

  @override
  void initState() {
    super.initState();
    updateGreeting();
    getOnTheLoad();
  }

  void updateGreeting() {
    final hour = DateTime.now().hour;
    setState(() {
      if (hour >= 5 && hour < 12) {
        greeting = "Good Morning";
      } else if (hour >= 12 && hour < 17) {
        greeting = "Good Afternoon";
      } else if (hour >= 17 && hour < 21) {
        greeting = "Good Evening";
      } else {
        greeting = "Good Night";
      }
    });
  }

  Future<void> deleteTask(String taskId) async {
    String category = today
        ? "Today"
        : tomorrow
            ? "Tomorrow"
            : "NextWeek";
    await FirebaseFirestore.instance.collection(category).doc(taskId).delete();
  }

  Widget allWork() {
    return StreamBuilder(
      stream: todoStream,
      builder: (context, AsyncSnapshot snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(
            child: Text(
              "Error loading data: ${snapshot.error}",
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          );
        } else if (snapshot.hasData && snapshot.data.docs.isNotEmpty) {
          return ListView.builder(
            padding: EdgeInsets.zero,
            itemCount: snapshot.data.docs.length,
            itemBuilder: (context, index) {
              DocumentSnapshot ds = snapshot.data.docs[index];
              return Container(
                margin: EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 5,
                      offset: Offset(2, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Checkbox(
                      value: ds["Yes"],
                      onChanged: (value) async {
                        await DatabaseMethods().updateifTicked(
                          ds.id,
                          today
                              ? "Today"
                              : tomorrow
                                  ? "Tomorrow"
                                  : "NextWeek",
                        );
                        setState(() {});
                      },
                      activeColor: Color(0xff279cfb),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ds["Work"],
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 5),
                          Text(
                            ds["Time"] ?? "No time set",
                            style: TextStyle(color: Colors.grey, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 10),
                    IconButton(
                      icon: Icon(Icons.edit, color: Colors.blue),
                      onPressed: () {
                        editTaskDialog(ds.id, ds["Work"], ds["Time"]);
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: () async {
                        await deleteTask(ds.id);
                      },
                    ),
                  ],
                ),
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
      },
    );
  }

  Future<void> pickTime(BuildContext context) async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time != null) {
      setState(() {
        selectedTime = time;
      });
    }
  }

  Future openBox() => showDialog(
        context: context,
        builder: (context) {
          return StatefulBuilder(
            builder: (BuildContext context, StateSetter setDialogState) {
              return AlertDialog(
                content: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              Navigator.pop(context);
                            },
                            child: Icon(Icons.cancel),
                          ),
                          SizedBox(width: 60),
                          Text(
                            "Add the Work TODO",
                            style: TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      SizedBox(height: 10),
                      Text("Add Text"),
                      SizedBox(height: 10),
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
                      SizedBox(height: 10),
                      Row(
                        children: [
                          Text("Time:"),
                          SizedBox(width: 10),
                          GestureDetector(
                            onTap: () async {
                              final now = TimeOfDay.now();
                              final time = await showTimePicker(
                                context: context,
                                initialTime: today
                                    ? now
                                    : selectedTime ?? TimeOfDay.now(),
                                helpText: today
                                    ? 'Select a time from now onwards'
                                    : 'Select a time',
                              );
                              if (time != null) {
                                // Ensure selected time is from now onwards for today
                                if (today &&
                                    (time.hour < now.hour ||
                                        (time.hour == now.hour &&
                                            time.minute < now.minute))) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                          "Please select a time from now onwards."),
                                    ),
                                  );
                                } else {
                                  setDialogState(() {
                                    selectedTime = time;
                                  });
                                }
                              }
                            },
                            child: Text(
                              selectedTime != null
                                  ? selectedTime!.format(context)
                                  : "Select Time",
                              style: TextStyle(
                                color: Colors.blue,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 10),
                      GestureDetector(
                        onTap: () async {
                          if (toDoController.text.isNotEmpty) {
                            String id = randomAlphaNumeric(10);
                            Map<String, dynamic> userToDo = {
                              "id": id,
                              "Work": toDoController.text,
                              "Yes": false,
                              "Time": selectedTime != null
                                  ? selectedTime!.format(context)
                                  : "No time set",
                            };

                            // Add the task to the database based on the selected day
                            today
                                ? DatabaseMethods().addTodayWork(userToDo, id)
                                : tomorrow
                                    ? DatabaseMethods()
                                        .addTomarrowWork(userToDo, id)
                                    : DatabaseMethods()
                                        .addNextWeekWork(userToDo, id);

                            // Show a notification when a task is added and the time is set
                            if (selectedTime != null) {
                              await NotificationService.showNotification(
                                'Task Reminder',
                                'It\'s time to do: ${toDoController.text}',
                              );
                            }

                            // Close the dialog after adding the task
                            Navigator.pop(context);
                          }
                        },
                        child: Center(
                          child: Container(
                            width: 100,
                            padding: EdgeInsets.symmetric(horizontal: 10),
                            decoration: BoxDecoration(
                              color: Color(0xff008080),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            alignment: Alignment.center,
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
                ),
              );
            },
          );
        },
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          toDoController.clear();
          selectedTime = null;
          openBox();
        },
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
              "Hello Manikanta",
              style: TextStyle(
                color: Colors.white,
                fontSize: 30,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10),
            Text(
              greeting,
              style: TextStyle(
                color: Colors.white,
                fontSize: 30,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10),
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
            SizedBox(height: 20),
            Expanded(
              child: allWork(),
            ),
          ],
        ),
      ),
    );
  }

  void editTaskDialog(String taskId, String currentWork, String? currentTime) {
    TextEditingController editController =
        TextEditingController(text: currentWork);
    TimeOfDay? selectedEditTime = currentTime != null
        ? TimeOfDay(
            hour: int.parse(currentTime.split(":")[0]),
            minute: int.parse(currentTime.split(":")[1].split(" ")[0]),
          )
        : null;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setDialogState) {
            return AlertDialog(
              title: Text("Edit Task"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: editController,
                    decoration: InputDecoration(labelText: "Edit Work"),
                  ),
                  SizedBox(height: 10),
                  Row(
                    children: [
                      Text("Time:"),
                      SizedBox(width: 10),
                      GestureDetector(
                        onTap: () async {
                          final time = await showTimePicker(
                            context: context,
                            initialTime: selectedEditTime ?? TimeOfDay.now(),
                          );
                          if (time != null) {
                            setDialogState(() {
                              selectedEditTime = time;
                            });
                          }
                        },
                        child: Text(
                          selectedEditTime != null
                              ? selectedEditTime!.format(context)
                              : "Select Time",
                          style: TextStyle(
                            color: Colors.blue,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text("Cancel"),
                ),
                TextButton(
                  onPressed: () async {
                    if (editController.text.isNotEmpty) {
                      String category = today
                          ? "Today"
                          : tomorrow
                              ? "Tomorrow"
                              : "NextWeek";
                      await FirebaseFirestore.instance
                          .collection(category)
                          .doc(taskId)
                          .update({
                        "Work": editController.text,
                        "Time": selectedEditTime != null
                            ? selectedEditTime!.format(context)
                            : currentTime,
                      });
                      Navigator.pop(context);
                    }
                  },
                  child: Text("Save"),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
