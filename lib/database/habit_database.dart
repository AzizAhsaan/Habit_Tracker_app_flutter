import 'package:flutter/material.dart';
import 'package:habit_tracker_app/modules/app_settings.dart';
import 'package:habit_tracker_app/modules/habit.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart'; // Import the package

class HabitDatabase extends ChangeNotifier {
  static late Isar isar;

  /* 

  S E T U P 


  */

  // initilize database

  static Future<void> initialize() async {
    final dir = await getApplicationDocumentsDirectory();
    isar = await Isar.open(
      [HabitSchema, AppSettingsSchema],
      directory: dir.path,
    );
  }

  //save first date of app statup (for heatmap)

  Future<void> saveFirstLaunchDate() async {
    final existingSettings = await isar.appSettings.where().findFirst();
    if (existingSettings == null) {
      final settings = AppSettings()..firstLaunchDate = DateTime.now();
      await isar.writeTxn(() => isar.appSettings.put(settings));
    }
  }
  // get first date of app statup(for heatmap)

  Future<DateTime?> getFirstLaunchDate() async {
    final settings = await isar.appSettings.where().findFirst();
    return settings?.firstLaunchDate;
  }

  /* 

  CRUD OPERATIONS

  */

  // List of habits

  final List<Habit> currentHabits = [];

  // CREATE - add a new habit

  Future<void> addHabit(String habitName) async {
    final newHabit = Habit()..name = habitName;

    await isar.writeTxn(() => isar.habits.put(newHabit));
    readHabits();
  }

  // READ - read saved habits from db

  Future<void> readHabits() async {
    // fetch all habits from db

    List<Habit> fetchedHabits = await isar.habits.where().findAll();
    currentHabits.clear();
    currentHabits.addAll(fetchedHabits);
    notifyListeners();
  }

  // UPDATE - check habit on and off

  Future<void> updateHabitCompletion(int id, bool isCompleted) async {
    // find habit by id

    final habit = await isar.habits.get(id);

    // update habit

    if (habit != null) {
      await isar.writeTxn(() async {
        //if habit is completed => add the current date to the completedDays list

        if (isCompleted && !habit.completedDays.contains(DateTime.now())) {
          //today

          final today = DateTime.now();

          habit.completedDays.add(
            DateTime(today.year, today.month, today.day),
          );

          // add the current date if its not already in the list
        }
        //if habit is not completed => remove the current date from the completedDays list

        else {
          habit.completedDays.removeWhere((date) =>
              date.year == DateTime.now().year &&
              date.month == DateTime.now().month &&
              date.day == DateTime.now().day);
        }
        // save the updated habits back to the db
        await isar.habits.put(habit);
      });
    }
    readHabits();
  }

  // UPDATE - edit habit name

  Future<void> updateHabitName(int id, String newName) async {
    // find habit by id
    final habit = await isar.habits.get(id);

    // update habit name
    if (habit != null) {
      await isar.writeTxn(() async {
        habit.name = newName;
        await isar.habits.put(habit);
      });
    }
    readHabits();
  }

  // DELETE - delete habit

  Future<void> deleteHabit(int id) async {
    // perform delete operation
    await isar.writeTxn(() async {
      await isar.habits.delete(id);
    });
    readHabits();
  }
}
