import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/todo_model.dart';
import '../providers/active_todo_count.dart';
import '../providers/filtered_todos.dart';
import '../providers/todo_filter.dart';
import '../providers/todo_list.dart';
import '../providers/todo_search.dart';
import '../utils/debounce.dart';

class TodosPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _TodosPage();
}

class _TodosPage extends State<TodosPage> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 20.0,
              vertical: 40.0,
            ),
            child: Column(children: [
              TodoHeader(),
              CreateTodo(),
              SizedBox(height: 20.0),
              SearchAndFilterTodo(),
              ShowTodos(),
            ]),
          ),
        ),
      ),
    );
  }
}

class SearchAndFilterTodo extends StatelessWidget {
  final debounce = Debounce(milliseconds: 1000);
  Widget filterButton(BuildContext context, Filter filter) {
    return TextButton(
      onPressed: () {
        context.read<TodoFilter>().changeFilter(filter);
      },
      child: Text(
        filter == Filter.all
            ? 'All'
            : filter == Filter.active
                ? 'Active'
                : 'Completed',
        style: TextStyle(fontSize: 18.0, color: textColor(context, filter)),
      ),
    );
  }

  Color textColor(BuildContext context, Filter filter) {
    final currentFilter = context.watch<TodoFilter>().state.filter;
    return currentFilter == filter ? Colors.blue : Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
            decoration: InputDecoration(
              labelText: 'Search Todos',
              border: InputBorder.none,
              filled: true,
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (String? newSearchTerm) {
              if (newSearchTerm != null) {
                debounce.run(() {
                  context.read<TodoSearch>().setSearchTerm(newSearchTerm);
                });
              }
            }),
        SizedBox(
          height: 10.0,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            filterButton(context, Filter.all),
            filterButton(context, Filter.active),
            filterButton(context, Filter.completed)
          ],
        )
      ],
    );
  }
}

class CreateTodo extends StatefulWidget {
  const CreateTodo({super.key});

  @override
  State<CreateTodo> createState() => _CreateTodoState();
}

class _CreateTodoState extends State<CreateTodo> {
  final newTodoController = TextEditingController();

  @override
  void dispose() {
    newTodoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: newTodoController,
      decoration: InputDecoration(labelText: 'What to do?'),
      onSubmitted: (String? todoDesc) {
        if (todoDesc != null && todoDesc.trim().isNotEmpty) {
          context.read<TodoList>().addTodo(todoDesc);
          newTodoController.clear();
        }
      },
    );
  }
}

class TodoHeader extends StatelessWidget {
  const TodoHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('TODO', style: TextStyle(fontSize: 40.0)),
        Text(
            '${context.watch<ActiveTodoCount>().state.activeTodoCount} items left',
            style: TextStyle(fontSize: 20.0, color: Colors.redAccent))
      ],
    );
  }
}

class ShowTodos extends StatelessWidget {
  const ShowTodos({super.key});

  @override
  Widget build(BuildContext context) {
    final todos = context.watch<FilteredTodos>().state.filteredTodos;

    Widget showBackground(int direction) {
      return Container(
        margin: const EdgeInsets.all(4.0),
        padding: const EdgeInsets.symmetric(horizontal: 10.0),
        color: Colors.red,
        alignment:
            direction == 0 ? Alignment.centerLeft : Alignment.centerRight,
        child: Icon(
          Icons.delete,
          size: 30.0,
          color: Colors.white,
        ),
      );
    }

    return ListView.separated(
      primary: false,
      shrinkWrap: true,
      itemBuilder: (BuildContext context, int index) {
        return Dismissible(
          key: ValueKey(todos[index].id),
          background: showBackground(0),
          secondaryBackground: showBackground(1),
          child: TodoItem(
            todo: todos[index],
          ),
          onDismissed: (_) {
            context.read<TodoList>().removeTodo(todos[index]);
          },
          confirmDismiss: (_) {
            return showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) {
                  return AlertDialog(
                      title: Text('Are you sure?'),
                      content: Text('Do you really want to delete?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: Text('NO'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: Text('YES'),
                        )
                      ]);
                });
          },
        );
      },
      separatorBuilder: (BuildContext context, int index) {
        return Divider(color: Colors.grey);
      },
      itemCount: todos.length,
    );
  }
}

class TodoItem extends StatefulWidget {
  final Todo todo;
  const TodoItem({super.key, required this.todo});

  @override
  State<TodoItem> createState() => _TodoItemState();
}

class _TodoItemState extends State<TodoItem> {
  late final TextEditingController textController;

  @override
  void initState() {
    super.initState();
    textController = TextEditingController();
  }

  @override
  void dispose() {
    super.dispose();
    textController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
        onTap: () {
          showDialog(
              context: context,
              builder: (context) {
                bool _error = false;
                textController.text = widget.todo.desc;

                return StatefulBuilder(
                  builder: (BuildContext context, StateSetter setState) {
                    return AlertDialog(
                      title: Text('Edit Todo'),
                      content: TextField(
                        controller: textController,
                        autofocus: true,
                        decoration: InputDecoration(
                          errorText: _error ? 'Value cannot be empty' : null,
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text('CANCEL'),
                        ),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _error =
                                  textController.text.isEmpty ? true : false;

                              if (!_error) {
                                context.read<TodoList>().editTodo(
                                      widget.todo.id,
                                      textController.text,
                                    );
                                Navigator.pop(context);
                              }
                            });
                          },
                          child: Text('EDIT'),
                        )
                      ],
                    );
                  },
                );
              });
        },
        leading: Checkbox(
          value: widget.todo.completed,
          onChanged: (bool? checked) {
            context.read<TodoList>().toggleTodo(widget.todo.id);
          },
        ),
        title: Text(widget.todo.desc));
  }
}
