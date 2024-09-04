import 'package:flutter/material.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:firebase_core/firebase_core.dart';

import 'expense_list_model.dart';
import 'expense.dart';
import 'database.dart';

void main() async {
  final expenses = ExpenseListModel();

  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  runApp(ScopedModel<ExpenseListModel>(
    model: expenses,
    child: const MyApp(),
  ));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  //this widget is the root of the application

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Expense Ledger',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      home: const MyHomePage(title: 'Expense Ledger'),
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: ScopedModelDescendant<ExpenseListModel>(
        builder: (context, child, expenses) {
          return ListView.separated(
              itemCount: expenses.items.length + 1,
              itemBuilder: (context, index) {
                if (index == 0 ){
                  return ListTile(
                    title: Text("Total expenses: " + expenses.totalExpense.toString(), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),));
                } else {
                  index = index - 1;
                  return Dismissible(
                      key: Key(expenses.items[index].id.toString()),
                      onDismissed: (direction){
                        expenses.delete(expenses.items[index]);

                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text("Item with id, " + expenses.items[index].id.toString() + "is dismissed"),
                          duration: (const Duration(seconds: 1)),
                        ));
                      },
                      child: ListTile(
                          onTap: () {
                            Navigator.push(
                              context, MaterialPageRoute(
                                builder: (context) => FormPage(
                                  id: expenses.items[index].id,
                                  expenses: expenses,
                                )
                              )
                            );
                          },
                          leading: const Icon(Icons.monetization_on),
                          trailing: const Icon(Icons.keyboard_arrow_right),
                          title: Text(expenses.items[index].category + ": " +
                                expenses.items[index].formattedDate,
                                style: const TextStyle(fontSize: 18, fontStyle: FontStyle.italic),
                                  )
                        ));}
                    },
                    separatorBuilder: (context, index) {
                  return const Divider();
                    },
                  );
                },
            ),
            floatingActionButton: ScopedModelDescendant<ExpenseListModel>(
                builder: (context, child, expenses) {
                  return FloatingActionButton(
                    onPressed: (){
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => ScopedModelDescendant<ExpenseListModel>(
                                  builder: (context, child, expenses) {
                                    return FormPage(
                                      id: 0,
                                      expenses: expenses,
                                    );
                                  }
                              )
                          )
                      );
                    },
                tooltip: 'Increment',
                child: const Icon(Icons.add),
                  );
                }));
  }
}

class FormPage extends StatefulWidget {
  const FormPage({super.key,  required this.id, required this.expenses});

  final int id;
  final ExpenseListModel expenses;

  @override
  FormPageState createState() => FormPageState(id: id, expenses: expenses);
}

class FormPageState extends State<FormPage> {
  FormPageState({required this.id, required this.expenses,});

  int id;
  ExpenseListModel expenses;

  var scaffoldKey = GlobalKey<ScaffoldMessengerState>();
  var formKey = GlobalKey<FormState>();

  double _amount = 0;
  DateTime _date = DateTime.now();
  String _category = '';

  void _submit() {

    final form = formKey.currentState!;

    if (form.validate()) {
      form.save();

      if (id == 0)
       {  expenses.add(Expense(0, _amount, _date, _category));  } 
      else
       {  expenses.update(Expense(id, _amount, _date, _category));  } 

      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      appBar: AppBar(
        title: const Text('Enter expense details'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: formKey,
          child: Column(
            children: [
              TextFormField(
                style: const TextStyle(fontSize: 22),
                decoration: const InputDecoration(
                  icon: Icon(Icons.monetization_on),
                  labelText: 'Amount', labelStyle: TextStyle(fontSize: 18)
                ),
                validator: (val ) {
                  Pattern pattern = r'^[1-9]\d*(\.\d+)?$';
                  RegExp regex = RegExp(pattern as String);
                  if (!regex.hasMatch(val!))
                    { return 'Enter a valid number.'; }
                  else
                    { return null;  }
                },
                initialValue: id == 0 ? '' : expenses.byId(id)?.amount.toString(),
                onSaved: (val) => _amount = double.parse(val!),
                keyboardType: TextInputType.datetime,
              ),
              TextFormField(
                style: const TextStyle(fontSize: 22),
                decoration: const InputDecoration(
                  icon: Icon(Icons.calendar_today),
                  hintText: 'Enter date of purchase',
                  labelText: 'Date', 
                  labelStyle: TextStyle(  fontSize: 18  ),
                ),
                validator: (val) {  
                  Pattern pattern = r'^((?"19|20)\d\d)[- /.](0[1-9]|1[012])[- /.](0[1-9]|[12][0-9]|3[3[01])$';  
                  RegExp regex = RegExp(pattern as String);
                  if (!regex.hasMatch(val!)) { return 'Enter a valid date'; }
                  else {  return null;  }
                },
                onSaved: (val) => _date = DateTime.parse(val!),
                initialValue: id == 0 ? '' : expenses.byId(id)?.formattedDate,
                keyboardType: TextInputType.datetime,
              ),
              TextFormField(
                style: const TextStyle( fontSize: 22  ),
                decoration: const InputDecoration(
                  icon: Icon(Icons.category),
                  labelText: 'Category',
                  labelStyle: TextStyle( fontSize: 18 )
                ),
                onSaved: (val) => _category = val!,
                initialValue: id == 0 ? '' : expenses.byId(id)?.category.toString(),
              ),
              ElevatedButton(
                onPressed: _submit,
                child: const Text('Submit'),
              )
            ]
          )
        )
      )
    );
  }
}