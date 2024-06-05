import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TodoPage extends StatefulWidget {
  const TodoPage({super.key});

  @override
  State<TodoPage> createState() => _TodoPageState();
}

class _TodoPageState extends State<TodoPage> {
  final User? user = FirebaseAuth.instance.currentUser;
  final TextEditingController _taskController = TextEditingController();
  final CollectionReference tasksCollection =
      FirebaseFirestore.instance.collection('tasks');

  Future<void> _addTask() async {
    if (_taskController.text.isNotEmpty) {
      await tasksCollection.add({
        'userId': user?.uid,
        'title': _taskController.text,
        'isCompleted': false,
      });
      _taskController.clear();
    }
  }

  Future<void> _toggleTaskCompletion(DocumentSnapshot doc) async {
    await tasksCollection.doc(doc.id).update({
      'isCompleted': !doc['isCompleted'],
    });
  }

  Future<void> _deleteTask(DocumentSnapshot doc) async {
    await tasksCollection.doc(doc.id).delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My ToDo List'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _taskController,
              decoration: InputDecoration(
                labelText: 'Add a new task',
                suffixIcon: IconButton(
                  onPressed: _addTask,
                  icon: const Icon(Icons.add),
                ),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: tasksCollection
                  .where('userId', isEqualTo: user?.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                var tasks = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    var task = tasks[index];

                    return ListTile(
                      title: Text(
                        task['title'],
                        style: TextStyle(
                          decoration: task['isCompleted']
                              ? TextDecoration.lineThrough
                              : TextDecoration.none,
                        ),
                      ),
                      leading: Checkbox(
                        value: task['isCompleted'],
                        onChanged: (value) => _toggleTaskCompletion(task),
                      ),
                      trailing: IconButton(
                        onPressed: () => _deleteTask(task),
                        icon: const Icon(Icons.delete),
                      ),
                    );
                  },
                );
              },
            ),
          )
        ],
      ),
    );
  }
}
