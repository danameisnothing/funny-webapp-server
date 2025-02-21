import 'dart:io';

import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart' as shelf_router;
import 'package:shelf_static/shelf_static.dart' as shelf_static;

import 'package:funny_webapp_server/app_routes.dart' as app_routes;
import 'package:funny_webapp_server/app_utils.dart' as app_utils;
import 'package:funny_webapp_server/app_constants.dart' as app_consts;

// I'm using .all just for returning HTTP 405
final app = shelf_router.Router()
  // Master APIs
  ..get("/api/master/m3u8", app_routes.m3u8Route)
  ..get("/api/master/music_duration_infos", app_routes.musicDurationInfosRoute)
  ..get("/api/master/music_last_updated", app_routes.musicLastUpdatedRoute)
  ..post("/api/master/send_music_durations", app_routes.sendMusicDurationsRoute)
  ..post("/api/master/send_curr_playing_music", app_routes.sendCurrPlayingMusicRoute)
  // Public APIs
  ..get("/api/when_funny_music", app_routes.whenFunnyMusicRoute)
  ..get("/api/batch_info", app_routes.batchInfoRoute)
  // 405 handlers
  ..all("/api/master/m3u8", (shelf.Request _) => app_utils.methodNotAllowedMsg())
  ..all("/api/master/music_duration_infos", (shelf.Request _) => app_utils.methodNotAllowedMsg())
  ..all("/api/master/send_info", (shelf.Request _) => app_utils.goneMsg())
  ..all("/api/master/music_last_updated", (shelf.Request _) => app_utils.methodNotAllowedMsg())
  ..all("/api/master/send_music_durations", (shelf.Request _) => app_utils.methodNotAllowedMsg())
  ..all("/api/master/send_curr_playing_music", (shelf.Request _) => app_utils.methodNotAllowedMsg())
  ..all("/api/when_funny_music", (shelf.Request _) => app_utils.methodNotAllowedMsg())
  ..all("/api/batch_info", (shelf.Request _) => app_utils.methodNotAllowedMsg())
  // 404 handler
  ..all("/<ignored|.*>", (shelf.Request _) => app_utils.notFoundMsg());
// Deleted the Dockerfile because we don't need it
void main() async {
  // funny song with a funny name with a funny implication
  // See https://github.com/dart-lang/samples/blob/main/server/simple/bin/server.dart
  final cascade = shelf.Cascade()
      .add(shelf_static.createStaticHandler("../pages",
          defaultDocument: "index.html"))
      .add(app.call);

  final server = await shelf_io.serve(
      (shelf.Request req) async {
        // Why this function exists: I'm scared that having multiple route handlers mangling around with the same variables are bound to lead to a disaster
        req = req.change(context: <String, Object>{app_consts.coreHandlerCtxDBKeyName: await app_utils.DBPassThru.getDBConn()});
        final handlerResp = await shelf.logRequests().addHandler(cascade.handler)(req);
        await (req.context[app_consts.coreHandlerCtxDBKeyName] as app_utils.DBPassThru).destroyDBConn();

        return handlerResp;
      }
      /* shelf.logRequests().addHandler(cascade.handler) */,
      /* InternetAddress.anyIPv4 */ /*"localhost"*/ Platform.environment["IP"] ?? "localhost",
      int.parse(Platform.environment["PORT"] ?? "8080"),
      poweredByHeader: /* "Deta Space in  */"Dart with package:shelf")
    ..autoCompress = true;
  
  print("Serving at ${server.address.host}:${server.port}");
}
