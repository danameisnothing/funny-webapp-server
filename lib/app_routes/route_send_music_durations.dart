import 'dart:convert';

import 'package:shelf/shelf.dart' as shelf;
import 'package:mongo_dart/mongo_dart.dart';

import 'package:funny_webapp_server/app_utils.dart' as app_utils;
import 'package:funny_webapp_server/app_constants.dart' as app_consts;

List<Map<String, double>>? _isValidClientResponse(String reqStr) {
  late Map<String, dynamic> reqBody;
  try {
    reqBody = jsonDecode(reqStr);
  } catch (_) {
    return null;
  }

  if (!reqBody.containsKey(app_consts.apiMusicDurationsKeyName)) {
    return null;
  } else if (reqBody[app_consts.apiMusicDurationsKeyName] is! List<dynamic>) {
    return null;
  }

  final List<Map<String, double>> musicData = [];

  // Test if a valid format of app_consts.apiCotLCacheMainKeyName is sent by the client
  try {
    reqBody[app_consts.apiMusicDurationsKeyName].forEach((obj) {
      if (obj is! Map<String, dynamic>) {
        throw Exception("Wrong ${app_consts.apiMusicDurationsKeyName} format");
      }

      obj.forEach((k, v) {
        if (v is! int && v is! double) {
          throw Exception("Wrong ${app_consts.apiMusicDurationsKeyName} format");
        }

        musicData.add({k: double.parse(v.toString())}); // Because we can accept int, but internally, we store it as a double
      });
    });
  } catch (_) {
    return null;
  }

  return musicData;
}

Future<shelf.Response> sendMusicDurationsRoute(shelf.Request req) async {
  final List<Map<String, double>>? newMusicData = _isValidClientResponse(await req.readAsString());
  if (newMusicData == null) {
    return app_utils.badRequestMsg();
  }

  final db = req.context[app_consts.coreHandlerCtxDBKeyName] as app_utils.DBPassThru;

  // Put data in DB
  if (await db.cotLSoundtrackDurationsColl.count() == 0) {
    db.cotLSoundtrackDurationsColl.insertOne({app_consts.dbCotLCacheMainKeyName: newMusicData});
  }  else {
    db.cotLSoundtrackDurationsColl.updateOne(where.exists(app_consts.dbCotLCacheMainKeyName), modify.set(app_consts.dbCotLCacheMainKeyName, newMusicData));
  }

  return app_utils.genericOKMsg();
}
