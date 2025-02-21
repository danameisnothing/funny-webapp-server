import 'dart:convert';

import 'package:shelf/shelf.dart' as shelf;
import 'package:mongo_dart/mongo_dart.dart';

import 'package:funny_webapp_server/app_utils.dart' as app_utils;
import 'package:funny_webapp_server/app_constants.dart' as app_consts;

Map<String, dynamic>? _isValidClientResponse(String reqStr) {
  late Map<String, dynamic> reqBody;
  try {
    reqBody = jsonDecode(reqStr);
  } catch (_) {
    return null;
  }

  if (!reqBody.containsKey(app_consts.apiCurrPlayingMusicKeyName) ||
      reqBody[app_consts.apiCurrPlayingMusicKeyName] is! String ||
      !reqBody.containsKey(app_consts.apiOffsetSKeyName) ||
      (reqBody[app_consts.apiOffsetSKeyName] is! int && reqBody[app_consts.apiOffsetSKeyName] is! double) ||
      reqBody[app_consts.apiOffsetSKeyName] < 0.0 || reqBody[app_consts.apiOffsetSKeyName] * 1e3 > DateTime.now().millisecondsSinceEpoch) {
    return null;
  }

  return reqBody;
}

Future<shelf.Response> sendCurrPlayingMusicRoute(shelf.Request req) async {
  final reqBody = _isValidClientResponse(await req.readAsString());
  if (reqBody == null) {
    return app_utils.badRequestMsg();
  }

  final db = req.context[app_consts.coreHandlerCtxDBKeyName] as app_utils.DBPassThru;

  final chosenTime = DateTime.now().subtract(Duration(
      microseconds: (reqBody[app_consts.apiOffsetSKeyName] * 1e6)
          .floor())); // Scared of imprecision breaking everything
  
  final musicDurations = await app_utils.getMusicDurations(db);
  if (musicDurations == null) {
    return shelf.Response.notFound(
        jsonEncode({"msg": "Data for music durations not available yet. Submit the music durations data first."}),
        headers: app_consts.defJSONHeader);
  }

  // Get smallest levenshtein distance (the most likely)
  int tmpLowestScore = double.maxFinite.toInt();
  String mostLikelyMusic = "";

  musicDurations.forEach((music, _) {
    final score = app_utils.levenshtein(reqBody[app_consts.apiCurrPlayingMusicKeyName], music);
    // We can't use min() :(
    if (score <= tmpLowestScore) {
      tmpLowestScore = score;
      mostLikelyMusic = music;
    }
  });

  // Put data in DB
  if (await db.latestMusicUpdateColl.count() == 0) {
    db.latestMusicUpdateColl.insertOne({
      app_consts.dbCurrPlayingMusicKeyName: mostLikelyMusic,
      app_consts.dbLastUpdatedKeyName: (chosenTime.millisecondsSinceEpoch / 1000)
    });
  } else {
    db.latestMusicUpdateColl.updateMany(where.exists(app_consts.dbCurrPlayingMusicKeyName).and(where.exists(app_consts.dbLastUpdatedKeyName)), modify.set(app_consts.dbCurrPlayingMusicKeyName, mostLikelyMusic).set(app_consts.dbLastUpdatedKeyName, (chosenTime.millisecondsSinceEpoch / 1000)));
  }

  return app_utils.genericOKMsg();
}
