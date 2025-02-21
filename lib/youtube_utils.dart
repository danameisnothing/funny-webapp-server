export 'youtube_utils.dart';

import 'dart:convert';

import 'package:http/http.dart' as http;

Future<String> getLiveStreamMobileYouTubeHTML(String videoID) async {
  final http.Response ytInitialPRReq = await http
      .get(Uri.parse("https://m.youtube.com/watch?v=$videoID"), headers: {
    "User-Agent":
        "Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0.6478.110 Mobile Safari/537.36",
    "Accept-Language": "en-US,en;q=0.5"
  });
  if (ytInitialPRReq.statusCode != 200) {
    throw Exception("A non-200 status code encountered");
  }
  return ytInitialPRReq.body;
}

dynamic getLiveStreamHLSManifestURLSync(String html) {
  // Regex from yt-dlp
  var ytInitialPRMatches =
      RegExp(r"ytInitialPlayerResponse\s*=").allMatches(html);
  if (ytInitialPRMatches.isEmpty) {
    throw Exception("Cannot found ytInitialPlayerResponse on response string");
  }

  late String ytInitialPRJSONStr;

  for (var match in ytInitialPRMatches) {
    String chunked = html.substring(match.end + 1, html.length);

    // Check if it's the beginning of a JSON string
    if (chunked[0] != "{") {
      continue;
    }

    // a jank regex I made in my own
    RegExpMatch? endJSONMatch =
        RegExp(r'adBreakHeartbeatParams\":\".{8}\"}').firstMatch(chunked);

    if (endJSONMatch == null) {
      throw Exception("Cannot find end of JSON string");
    }

    ytInitialPRJSONStr = chunked.substring(0, endJSONMatch.end);
  }

  return jsonDecode(ytInitialPRJSONStr)["streamingData"]["hlsManifestUrl"];
}
