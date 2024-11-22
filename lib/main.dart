import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'expense_list_model.dart';
import 'expense.dart';


void main() async {

  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp( options: DefaultFirebaseOptions.currentPlatform, );

  final expenses = ExpenseListModel();

  runApp(ScopedModel<ExpenseListModel>(
    model: expenses,
    child: const  MyApp(),
  ));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  //this widget is the root of the application

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LedgeEx',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      home: const MyHomePage(title: 'Expense tracker'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;



  @override
  // ignore: library_private_types_in_public_api, no_logic_in_create_state
  _MyHomePageState createState() => _MyHomePageState(title: title,);
  
}

class _MyHomePageState extends State<MyHomePage> {
  _MyHomePageState({required this.title});

  final String title;


  // void _confirmDelete(BuildContext context, ExpenseListModel expenses, Expense expense) {
  //   showDialog(
  //     context: context,
  //     builder: (BuildContext context) {
  //       return AlertDialog(
  //         title: const Text("Delete Entry"),
  //         content: const Text("Are you sure you want to delete this expense entry?"),
  //         actions: <Widget>[
  //           TextButton(
  //             onPressed: () => Navigator.of(context).pop() ,
  //             child: const Text("Cancel")
  //           ),
  //           TextButton(
  //             onPressed: (){
  //               // ScopedModel.of<ExpenseListModel>(context).delete(expense) ;
  //               setState(() => expenses.delete(expense));
  //               Navigator.of(context).pop();
  //             },
  //             child: const Text("Delete"),
  //           )
  //         ],
  //       );
  //     },
  //   );
  // }

  Future<bool?> _confirmDelete(BuildContext context, ExpenseListModel expenses, Expense expense ) async {
    bool confirm = await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Confirm'),
          content: Text('Are you sure you want to delete this expense entry?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('Delete'),
            ),
          ],
        )
    );
    if (confirm){
      setState(() => expenses.delete(expense));
    }
    return confirm;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar( title: Text(title), ),
      body: ScopedModelDescendant<ExpenseListModel>(
        builder: (context, child, expenses) {
          return ListView.separated(
              itemCount: expenses.items.length + 1,
              itemBuilder: (context, index) {
                if (index == 0 ){
                  return ListTile(
                    title: Text("Total expenses: ${expenses.totalExpense}",
                    style: const TextStyle(fontSize: 18,fontWeight: FontWeight.bold),),
                  );
                    
                }
                else {
                  index = index - 1;
                  return GestureDetector(
                    child: Dismissible(
                      key: Key(expenses.items[index].id.toString()),
                      // onDismissed: (direction) =>  _deleteConfirmed( context, expenses, expenses.items[index] ),
                      confirmDismiss:  (direction) async => await _confirmDelete( context, expenses, expenses.items[index]) ,
                      child: ListTile(
                             onLongPress: () {
                             showModalBottomSheet(
                               context: context,
                               builder: (BuildContext context) {
                                 return Wrap(
                                  children: <Widget>[
                                    ListTile(
                                      leading: const Icon(Icons.delete),
                                      title: const Text('Delete'),
                                      onTap: () async {
                                        Navigator.pop(context);
                                        await _confirmDelete(context, expenses, expenses.items[index]); 
                                      },
                                    )
                                  ],
                                );}
                              );
                            },
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
                          title: Text("${expenses.items[index].category}: ${expenses.items[index].formattedDate}",
                                style: const TextStyle(fontSize: 18, fontStyle: FontStyle.italic),
                                  )
                        ))
                  );}
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
                tooltip: 'Add expense entry',
                child: const Icon(Icons.add),
                  );
                }
              ));
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
 

 FormPageState({required this.id, required this.expenses,}) : _date = DateTime.now();

  int id;
  ExpenseListModel expenses;

  var scaffoldKey = GlobalKey<ScaffoldMessengerState>();
  var formKey = GlobalKey<FormState>();

  double _amount = 0;
  DateTime _date;
  String _category = '';

  String? formattedDate;

  void _submit() {

    final form = formKey.currentState!;

    // try {
    //   form.validate();
    // } catch (e) {
    //   print(e);
    // } finally {
    //   Navigator.pop(context);
    // }

    form.save();

      if (id == 0) {  expenses.add(Expense(0, _amount, _date, _category));  } 
      else {  expenses.update(Expense(id, _amount, _date, _category));  } 

    Navigator.pop(context);
  }

  Future<void> _setDate (BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(context: context, firstDate: DateTime(1999), lastDate: DateTime(2101));

      if (pickedDate != null) {
          setState( () {  _date = DateTime(pickedDate.year, pickedDate.month, pickedDate.day); 
          formattedDate = DateFormat('MMM d, yyyy').format(_date); }
        );
      }
  }

  @override
  Widget build(BuildContext context) {
    // TextEditingController textController = TextEditingController(text: _date.toString());
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
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              TextFormField(
                
                style: const TextStyle(fontSize: 22),
                controller: TextEditingController(text: formattedDate),
                decoration: const InputDecoration(
                  icon: Icon(Icons.calendar_today),
                  hintText: 'Enter date of purchase',
                  labelText: 'Date',
                  labelStyle: TextStyle(  fontSize: 18  ),
                ),
                // validator: (val) {
                //   Pattern pattern = r'^((?"19|20)\d\d)[- /.](0[1-9]|1[012])[- /.](0[1-9]|[12][0-9]|3[3[01])$';
                //   RegExp regex = RegExp(pattern as String);
                //   if (!regex.hasMatch(val!)) { return 'Enter a valid date'; }
                //   else {  return null;  }
                // },
                onTap: () => _setDate(context),
                // initialValue: id == 0 ? '' : expenses.byId(id)?.date.toString(),
                
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

