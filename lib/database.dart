
import 'dart:async';
import 'dart:io';
import 'package:path/path.dart';

import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import 'expense.dart';

class SQLiteDbProvider {
  SQLiteDbProvider._();

  static final SQLiteDbProvider db = SQLiteDbProvider._();

  static Database? _database;

  Future<Database?> get database async {
    if (_database != null) { return _database; }

    _database = await initDB();
    return _database;
  }

  initDB() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, "ExpenseDB2.db");
    return await openDatabase(
        path,
        version: 1,
        onOpen: (db) {},
        onCreate: (Database db, int version) async {
          await db.execute("CREATE TABLE Expense ("
              "id INTEGER PRIMARY KEY,"
              "amount REAL,"
              "date TEXT, "
              "category TEXT"
              ")");

          await db.execute(
              "INSERT INTO Expense ('id', 'amount', 'date', 'category') values (?, ?, ?, ?)",
              [1, 1000, '2024-08-14 10:00:00', "FOOD"]
          );
        }
    );
  }

  Future<List<Expense>> getAllExpenses() async {
    final db = await database;

    List<Map> results = await db!.query( "Expense", columns: Expense.columns, orderBy: "date DESC" );

    List<Expense> expenses = [];
    for (var result in results) {
      Expense expense = Expense.fromMap(result);
      expenses.add(expense);
    }

    return expenses;
  }

  Future<Object> getExpenseById(int id) async {
    final db = await database;

    var result = await db?.query("Expense", where: "id = ", whereArgs: [id]);

    return result!;
  }

  Future<dynamic> getTotalExpense() async {
    final db = await database;

    List<Map> list = await db!.rawQuery(
        "Select SUM(amount) as amount from expense");

    return list;
  }

  Future<Expense> insert(Expense expense) async {
    final db = await database;

    var maxIdResult = await db?.rawQuery(
        "SELECT MAX(id)+1 as last_inserted_id FROM Expense");

    var id = maxIdResult!.first["last_inserted_id"];

    var result = await db?.rawInsert(
        "INSERT Into Expense (id, amount, date, category)" " VALUES (?, ?, ?, ?)", [id, expense.amount, expense.date.toString(), expense.category]
        );

    return Expense(id as int, expense.amount, expense.date, expense.category);
  }

  Future<int?> update(Expense item) async {
    final db = await database;

    var result = await db?.update(
        "Expense", item.toMap(), where: "id = ?", whereArgs: [item.id]);

    return result;
  }

  delete(int id) async {
    final db = await database;
    db?.delete("Expense", where: "id = ?", whereArgs: [id]);
  }
}

// import 'package:firebase_database/firebase_database.dart';
// import 'expense.dart';


// class ExpenseDatabase {
//   final DatabaseReference _databaseRef = FirebaseDatabase.instance.ref();

//   // Add a new expense
//   Future<void> addExpense(Expense expense) async {
//     final newExpenseRef = _databaseRef.child('expenses').push();
//     await newExpenseRef.set(expense.toMap());
//   }

//   // Get all expenses
//   Future<List<Expense>> getAllExpenses() async {
//     final snapshot = await _databaseRef.child('expenses').get();
//     if (snapshot.exists) {
//       final List<Expense> expenses = [];

//       for (var _ in snapshot.children){
//         (childSnapshot) {
//         final expenseData = childSnapshot.value as Map<dynamic, dynamic>;
//         expenses.add(Expense.fromMap(expenseData));
//       };
//       }
//       /*snapshot.children.forEach((childSnapshot) {
//         final expenseData = childSnapshot.value as Map<dynamic, dynamic>;
//         expenses.add(Expense.fromMap(expenseData));
//       });*/
//       return expenses;
//     }
//     return [];
//   }

//   // Update an existing expense (assuming you have the expense ID)
//   Future<void> updateExpense(Expense expense) async {
//     await _databaseRef.child('expenses/${expense.id}').update(expense.toMap());
//   }

//   // Delete an expense (assuming you have the expense ID)
//   Future<void> deleteExpense(int expenseId) async {
//     await _databaseRef.child('expenses/$expenseId').remove();
//   }
// }

