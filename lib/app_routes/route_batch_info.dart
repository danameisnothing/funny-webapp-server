import 'dart:convert';

import 'package:shelf/shelf.dart' as shelf;

import 'package:funny_webapp_server/app_constants.dart' as app_consts;
import 'package:funny_webapp_server/app_utils.dart' as app_utils;

Future<shelf.Response> batchInfoRoute(shelf.Request req) async {
  final db = req.context[app_consts.coreHandlerCtxDBKeyName] as app_utils.DBPassThru;

  final Map<String, double>? timeRemainingForAllMusic = await app_utils.getTimeRemainingForAllMusic(db);
  if (timeRemainingForAllMusic == null) {
    return shelf.Response.notFound(
        jsonEncode({"msg": "Data not available yet. Check back later."}),
        headers: app_consts.defJSONHeader);
  }

  final musicLastUpdated = await app_utils.getLastMusicUpdate(db);
  if (musicLastUpdated == null) {
    return shelf.Response.notFound(
        jsonEncode({"msg": "Data not available yet. Check back later."}),
        headers: app_consts.defJSONHeader);
  }
  final filteredMusicLastUpdated = musicLastUpdated..removeWhere((k, v) => k == "_id");

  final Map<String, double> orderedMusic = Map.fromEntries(timeRemainingForAllMusic
      .entries
      .toList()
    ..sort((k, v) => k.value.compareTo(v
        .value))); // Re-orders the map from the smallest to the biggest remaining time

  final List<Object> timeRemainings = [];
  orderedMusic.forEach((k, v) {
    timeRemainings.add({app_consts.apiBatchInfoMusicNameKey: k, app_consts.apiBatchInfoMusicTimeRemainingKey: v});
  });

  return shelf.Response.ok(
      jsonEncode({
        "curr_playing_music": app_utils.getPredictedCurrentMusicStr(timeRemainingForAllMusic),
        "time_remaining_all": timeRemainings,
        "advanced_stats": filteredMusicLastUpdated,
      }),
      headers: app_consts.defJSONHeader);
}
