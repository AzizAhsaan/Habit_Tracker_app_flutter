import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:habit_tracker_app/components/my_drawer.dart';
import 'package:habit_tracker_app/components/my_habit_tile.dart';
import 'package:habit_tracker_app/components/my_heat_map.dart';
import 'package:habit_tracker_app/database/habit_database.dart';
import 'package:habit_tracker_app/modules/habit.dart';
import 'package:habit_tracker_app/theme/theme_provider.dart';
import 'package:habit_tracker_app/util/habit_util.dart';
import 'package:provider/provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    // TODO: implement initState
    //read existing habits on app startup
    Provider.of<HabitDatabase>(context, listen: false).readHabits();
    super.initState();
  }

  //text controller
  final TextEditingController _habitConroller = TextEditingController();
  // create new habit

  void createNewHabit() {
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
              content: TextField(
                controller: _habitConroller,
                decoration: const InputDecoration(
                  hintText: "Create new habit",
                ),
              ),
              actions: [
                //save button
                MaterialButton(
                    child: Text("Add"),
                    onPressed: () {
                      // get the new habit name
                      String newHabitName = _habitConroller.text;

                      // save to db
                      context.read<HabitDatabase>().addHabit(newHabitName);
                      //pop box

                      Navigator.pop(context);

                      //clear controller
                      _habitConroller.clear();
                    }),
                // cancel button
                MaterialButton(
                  onPressed: () =>
                      {Navigator.pop(context), _habitConroller.clear()},
                  child: Text("Cancel"),
                )
              ],
            ));
  }

  // check habit on & off
  void checkHabitOnOff(bool? value, Habit habit) {
    // update habit completion status

    if (value != null) {
      context.read<HabitDatabase>().updateHabitCompletion(habit.id, value);
    }
  }

  // edit habit box

  void editHabitBox(Habit habit) {
    // set the controller's text to the habit's current name
    _habitConroller.text = habit.name;

    showDialog(
        context: context,
        builder: (context) => AlertDialog(
              content: TextField(
                controller: _habitConroller,
              ),
              actions: [
                //save button
                MaterialButton(
                    child: Text("Add"),
                    onPressed: () {
                      // get the new habit name
                      String newHabitName = _habitConroller.text;

                      // save to db
                      context
                          .read<HabitDatabase>()
                          .updateHabitName(habit.id, newHabitName);
                      //pop box

                      Navigator.pop(context);

                      //clear controller
                      _habitConroller.clear();
                    }),
                // cancel button
                MaterialButton(
                  onPressed: () =>
                      {Navigator.pop(context), _habitConroller.clear()},
                  child: Text("Cancel"),
                )
              ],
            ));
  }

  // delete habit box
  void deleteHabitBox(Habit habit) {
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
              title: const Text("Are you sure you want to delete?"),
              actions: [
                //delete button
                MaterialButton(
                    child: Text("Delete"),
                    onPressed: () {
                      // save to db
                      context.read<HabitDatabase>().deleteHabit(habit.id);
                      //pop box

                      Navigator.pop(context);
                    }),
                // cancel button
                MaterialButton(
                  onPressed: () => {Navigator.pop(context)},
                  child: Text("Cancel"),
                )
              ],
            ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      drawer: const MyDrawer(),
      backgroundColor: Theme.of(context).colorScheme.surface,
      floatingActionButton: FloatingActionButton(
        onPressed: createNewHabit,
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.tertiary,
        child: Icon(Icons.add),
      ),
      body: ListView(
        children: [
          //Heat map
          _buildHeatMap(),

          //list
          _buildHabitList()
        ],
      ),
    );
  }

  // build heat map
  Widget _buildHeatMap() {
    final habitDatabase = context.watch<HabitDatabase>();
    List<Habit> currentHabits = habitDatabase.currentHabits;

    // return heat map UI
    return FutureBuilder<DateTime?>(
        future: habitDatabase.getFirstLaunchDate(),
        builder: (context, snapshot) {
          // once the data is available => build heatmap

          if (snapshot.hasData) {
            return MyHeatMap(
                datasets: prepareHeatMapDataset(currentHabits),
                startDate: snapshot.data!);
          }

          // handle case where no data is returned
          else {
            return Container();
          }
        });
  }

  Widget _buildHabitList() {
    // habit db
    final habitDataBase = context.watch<HabitDatabase>();

    // current habits

    List<Habit> currentHabits = habitDataBase.currentHabits;

    //return list ob havbits UI

    return ListView.builder(
        itemCount: currentHabits.length,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemBuilder: (context, index) {
          // get each individual habit

          final habit = currentHabits[index];

          // check if the habit is completed today
          bool isCompletedToday = isHabitCompletedToday(habit.completedDays);

          // return habit tile UI
          return MyHabitTile(
            isCompleted: isCompletedToday,
            text: habit.name,
            onChanged: (value) => checkHabitOnOff(value, habit),
            editHabit: (context) => editHabitBox(habit),
            deleteHabit: (context) => deleteHabitBox(habit),
          );
        });
  }
}
