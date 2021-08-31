import 'package:filcnaplo/api/providers/user_provider.dart';
import 'package:filcnaplo/api/providers/database_provider.dart';
import 'package:filcnaplo/models/user.dart';
import 'package:filcnaplo_kreta_api/client/api.dart';
import 'package:filcnaplo_kreta_api/client/client.dart';
import 'package:filcnaplo_kreta_api/models/homework.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class HomeworkProvider with ChangeNotifier {
  late List<Homework> _homework;
  late BuildContext _context;
  List<Homework> get homework => _homework;

  HomeworkProvider({
    List<Homework> initialHomework = const [],
    required BuildContext context,
  }) {
    _homework = List.castFrom(initialHomework);
    _context = context;

    if (_homework.length == 0) restore();
  }

  Future<void> restore() async {
    String? userId = Provider.of<UserProvider>(_context, listen: false).id;

    // Load homework from the database
    if (userId != null) {
      var dbHomework = await Provider.of<DatabaseProvider>(_context, listen: false).userQuery.getHomework(userId: userId);
      _homework = dbHomework;
      notifyListeners();
    }
  }

  // Fetches Homework from the Kreta API then stores them in the database
  Future<void> fetch({DateTime? from, bool db = true}) async {
    User? user = Provider.of<UserProvider>(_context, listen: false).user;
    if (user == null) throw "Cannot fetch Homework for User null";

    String iss = user.instituteCode;
    List? homeworkJson = await Provider.of<KretaClient>(_context, listen: false).getAPI(KretaAPI.homework(iss, start: from));
    if (homeworkJson == null) throw "Cannot fetch Homework for User ${user.id}";

    List<Homework> homework = [];
    await Future.forEach(homeworkJson.cast<Map>(), (Map hw) async {
      Map? e = await Provider.of<KretaClient>(_context, listen: false).getAPI(KretaAPI.homework(iss, id: hw["Uid"]));
      if (e != null) homework.add(Homework.fromJson(e));
    });
    
    if (homework.length == 0 && _homework.length == 0) return;

    if (db) await store(homework);
    _homework = homework;
    notifyListeners();
  }

  // Stores Homework in the database
  Future<void> store(List<Homework> homework) async {
    User? user = Provider.of<UserProvider>(_context, listen: false).user;
    if (user == null) throw "Cannot store Homework for User null";
    String userId = user.id;
    await Provider.of<DatabaseProvider>(_context, listen: false).userStore.storeHomework(homework, userId: userId);
  }
}
