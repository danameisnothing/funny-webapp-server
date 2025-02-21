import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shelf/shelf.dart' as shelf;

import 'package:funny_webapp_server/youtube_utils.dart';

import 'package:funny_webapp_server/app_constants.dart' as app_consts;

Future<shelf.Response> m3u8Route(shelf.Request req) async {
  /*final String ytHTML =
      await getLiveStreamMobileYouTubeHTML(app_consts.liveStreamID);
  final String hlsURL = getLiveStreamHLSManifestURLSync(ytHTML);

  final http.Response m3u8Resp = await http.get(Uri.parse(hlsURL));
  if ((m3u8Resp.statusCode / 100).floor() != 2) {
    throw Exception("Target resource returned a non-2xx status code");
  }

  return shelf.Response.ok(jsonEncode({"res": m3u8Resp.body}),
      headers: app_consts.defJSONHeader);*/
  
  late String ytHTML;
  try {
    ytHTML = await getLiveStreamMobileYouTubeHTML(app_consts.liveStreamID);
  } catch (e) {
    return shelf.Response.ok(jsonEncode({"debug": "error at fetching HTML", "error": e.toString(), "ytHTML": ytHTML}), headers: app_consts.defJSONHeader);
  }

  late String hlsURL;
  try {
    hlsURL = getLiveStreamHLSManifestURLSync(/*await File("C:/Users/testn/Desktop/RTC Launcher/e.txt").readAsString()*/ytHTML);
  } catch (e) {
    return shelf.Response.ok(jsonEncode({"debug": "error at finding manifest", "error": e.toString(), "ytHTML": ytHTML}), headers: app_consts.defJSONHeader);
  }

  final http.Response m3u8Resp = await http.get(Uri.parse(hlsURL));
  if ((m3u8Resp.statusCode / 100).floor() != 2) {
    throw Exception("Target resource returned a non-2xx status code");
  }

  return shelf.Response.ok(jsonEncode({"res": m3u8Resp.body}),
      headers: app_consts.defJSONHeader);
}
