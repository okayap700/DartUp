import 'dart:collection';
import 'package:scoped_model/scoped_model.dart';


import 'expense.dart';
import 'expense_database.dart';
// import 'database.dart';

class ExpenseListModel extends Model {

  ExpenseListModel() { load(); }

  // static final expenseDatabase = SQLiteDbProvider._();

  final List<Expense> _items = [];
  final _database = ExpenseDatabase();


  UnmodifiableListView<Expense> get items => UnmodifiableListView(_items);

 /*  Future<double> get totalExpense{
  return SQLiteDbProvider.db.getTotalExpense();
  } */

  double get totalExpense{
    double amount = 0.0;

    for(var  i = 0; i < _items.length; i++) {
      amount = amount + _items[i].amount;
    }

    return amount;
  }

  Future<void> load() async {
    try{
      final dbItems = await _database.getAllExpenses();
      // _items.clear();
      _items.addAll(dbItems);
      notifyListeners();
    } catch (e) {
      print("Error loading expenses: $e");
    }
  }

  //by Id used to get particular expense from _items variable
  Expense? byId(int id) {
    for(var i = 0; i < _items.length; i++) {
      if(_items[i].id == id ) {
        return _items[i];
      }
    }

    return null;
  }

  //add used to add a new item into the _items list & into the database and notifyListeners for UI
  Future<void> add (Expense item) async {
    try {
      await _database.addExpense(item);
      _items.add(item);
      notifyListeners();
    } catch (e) {
      print("Error adding expense: $e");
    }
  }

  //update used to update the _items variable & into the database and notifyListeners for UI
  Future<void> update (Expense item) async {
    try {
      await _database.updateExpense(item);

      final index = items.indexWhere( (element) => element.id == item.id);
      if (index != -1) {
        _items[index] = item;
        notifyListeners();
      }
    } catch (e) {
      print("Error updating expense: $e");
    }
  }

  Future<void> delete (Expense item) async {
    try {
      await _database.deleteExpense(item.id);
      _items.remove(item);
      notifyListeners();
    } catch (e) {
      print("Error deleting expense: $e");
    }
  }
}