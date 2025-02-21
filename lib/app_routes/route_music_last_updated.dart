import 'dart:convert';

import 'package:shelf/shelf.dart' as shelf;

import 'package:funny_webapp_server/app_constants.dart' as app_consts;
import 'package:funny_webapp_server/app_utils.dart' as app_utils;

Future<shelf.Response> musicLastUpdatedRoute(shelf.Request req) async {
  final db = req.context[app_consts.coreHandlerCtxDBKeyName] as app_utils.DBPassThru;

  final musicLastUpdated = await app_utils.getLastMusicUpdate(db);
  if (musicLastUpdated == null) {
    return shelf.Response.notFound(
        jsonEncode({"msg": "Data not available yet. Check back later."}),
        headers: app_consts.defJSONHeader);
  }

  final data = musicLastUpdated..removeWhere((k, v) => k == "_id");
  return shelf.Response.ok(jsonEncode({"res": data}), headers: app_consts.defJSONHeader);
}