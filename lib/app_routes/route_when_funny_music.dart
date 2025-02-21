import 'dart:convert';

import 'package:shelf/shelf.dart' as shelf;

import 'package:funny_webapp_server/app_constants.dart' as app_consts;
import 'package:funny_webapp_server/app_utils.dart' as app_utils;

Future<shelf.Response> whenFunnyMusicRoute(shelf.Request req) async {
  final db = req.context[app_consts.coreHandlerCtxDBKeyName] as app_utils.DBPassThru;

  final musicDurations = await app_utils.getMusicDurations(db);
  if (musicDurations == null) {
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

  // Now, it's only off by 4 seconds. Yay :)

  return shelf.Response.ok(
      jsonEncode({
        "time_left_s": app_utils.getTimeLeftToSong(
            musicDurations,
            musicLastUpdated[app_consts.dbCurrPlayingMusicKeyName],
            DateTime.fromMillisecondsSinceEpoch(
                (musicLastUpdated[app_consts.dbLastUpdatedKeyName] * 1000).toInt(),
                isUtc: true),
            "Nudism - River Boy",
            DateTime.now())
      }),
      headers: app_consts.defJSONHeader);
}
