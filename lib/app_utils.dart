import 'dart:math';
import 'dart:io';

import 'package:shelf/shelf.dart' as shelf;
import 'package:mongo_dart/mongo_dart.dart';

import 'package:funny_webapp_server/app_constants.dart';

class DBPassThru {
  final Db _db;
  final DbCollection cotLSoundtrackDurationsColl;
  final DbCollection latestMusicUpdateColl;

  DBPassThru(this._db, this.cotLSoundtrackDurationsColl, this.latestMusicUpdateColl);

  static Future<DBPassThru> getDBConn() async {
    final db = await Db.create("mongodb+srv://testnow720:$devMongoDBPassword@funny-webapp-data.ew7zr.mongodb.net:27017/funny_webapp_db");
    await db.open();
    return DBPassThru(db, db.collection("cotl_soundtrack_durations"), db.collection("cotl_latest_music_update"));    
  }

  Future destroyDBConn() async {
    await _db.close();
  }
}

String getDBEnvPass() {
  /*if (Platform.environment["MONGO_PASS"] == null) {
    throw Exception("Not present");
  }*/
  return (Platform.environment["MONGO_PASS"] != null) ? Platform.environment["MONGO_PASS"]! : throw Exception("Not present");
}

Map<String, double> parseMusicDuration(List<dynamic> dbData) {
  final rebuiltData = <String, double>{};
  for (final obj in dbData) {
    obj.forEach((k, v) {
      rebuiltData[k] = double.parse(v.toString());
    });
  }

  return rebuiltData;
}

Future<Map<String, double>?> getMusicDurations(DBPassThru db) async {
  if (await db.cotLSoundtrackDurationsColl.count() == 0) {
    return null;
  }

  return parseMusicDuration((await db.cotLSoundtrackDurationsColl.find(where.exists(dbCotLCacheMainKeyName)).toList()).first[dbCotLCacheMainKeyName]);
}

Future<Map<String, dynamic>?> getLastMusicUpdate(DBPassThru db) async {
  if (await db.latestMusicUpdateColl.count() == 0) {
    return null;
  }

  return (await db.latestMusicUpdateColl.find(where.exists(dbCurrPlayingMusicKeyName).and(where.exists(dbLastUpdatedKeyName))).toList()).first;
}

Future<Map<String, double>?> getTimeRemainingForAllMusic(DBPassThru db) async {
  final musicDurations = await getMusicDurations(db);
  if (musicDurations == null) return null;

  final musicLastUpdated = await getLastMusicUpdate(db);
  if (musicLastUpdated == null) return null;

  // The lazy way
  final longestOngoingMusic = <String, double>{};
  musicDurations.forEach((k, v) {
    longestOngoingMusic[k] = getTimeLeftToSong(
        musicDurations,
        musicLastUpdated[dbCurrPlayingMusicKeyName],
        DateTime.fromMillisecondsSinceEpoch(
            (musicLastUpdated[dbLastUpdatedKeyName] * 1000).toInt(),
            isUtc: true),
        k,
        DateTime.now());
  });

  return longestOngoingMusic;
}

String getPredictedCurrentMusicStr(Map<String, double> timeRemainingMusics) {
  double tmpLongestSongToBeCurrent = -double.maxFinite;
  timeRemainingMusics.forEach((k, v) {
    if (v >= tmpLongestSongToBeCurrent) {
      tmpLongestSongToBeCurrent = v;
    }
  });

  return timeRemainingMusics.keys.firstWhere(
    (music) => timeRemainingMusics[music] == tmpLongestSongToBeCurrent);
}

// Really bad code AAAAAAAAAAAAAAAAA
double getTimeLeftToSong(Map<String, double> songs, String firstSong,
    DateTime firstSongTimeFound, String targetSong, DateTime currTime) {
  String ptrCurrSong = firstSong;
  double totalSecondsToTarget = 0;

  while (true) {
    bool isBreaking = false;
    final keyList = songs.keys.toList();

    final idxKeys = keyList.asMap(); // Just for the index
    final currSongIdx = keyList.indexOf(ptrCurrSong);
    // We start at the first song's POV
    for (int i = currSongIdx; i < idxKeys.length; i++) {
      if (idxKeys[i] == targetSong &&
          totalSecondsToTarget > 0 &&
          (currTime.difference(firstSongTimeFound).inMilliseconds / 1000) <=
              totalSecondsToTarget) {
        isBreaking = true;
        break;
      }
      totalSecondsToTarget += songs[idxKeys[i]]!;
    }
    if (isBreaking) break;
    ptrCurrSong = idxKeys[0]!;
  }

  return totalSecondsToTarget -
      (currTime.difference(firstSongTimeFound).inMilliseconds / 1000);
  //return Duration(seconds: totalSecondsToTarget - currTime.difference(firstSongTimeFound).inSeconds);
}

// https://github.com/brinkler/levenshtein-dart/blob/master/lib/levenshtein.dart
// Adjusted for Dart 3
int levenshtein(String s, String t, {final caseSensitive = false}) {
  if (!caseSensitive) {
    s = s.toLowerCase();
    t = t.toLowerCase();
  }
  if (s == t) return 0;
  if (s.isEmpty) return t.length;
  if (t.isEmpty) return s.length;

  final v0 = List<int>.filled(t.length + 1, 0);
  final v1 = List<int>.filled(t.length + 1, 0);

  for (int i = 0; i < t.length + 1; i < i++) {
    v0[i] = i;
  }

  for (int i = 0; i < s.length; i++) {
    v1[0] = i + 1;

    for (int j = 0; j < t.length; j++) {
      final cost = (s[i] == t[j]) ? 0 : 1;
      v1[j + 1] = min(v1[j] + 1, min(v0[j + 1] + 1, v0[j] + cost));
    }

    for (int j = 0; j < t.length + 1; j++) {
      v0[j] = v1[j];
    }
  }

  return v1[t.length];
}

/*@Deprecated("Use the mongo_dart API calls instead")
Future<Map<String, double>?> getMusicInfo() async {
  // basically gets the first part of the full key (the collection id)
  final Map<String, dynamic> cotlCache = await steamCotLCacheDB.query();
  // Because it's guaranteed to be 0 or 1
  // This returns the keys in alphabetical order, but screw it. Why not?
  if (cotlCache["paging"]["size"] == 1) {
    return jsonDecode(cotlCache["items"][0]["music_cache_json_str"])
        .cast<String, double>();
  }

  return null;
}

@Deprecated("Use the mongo_dart API calls instead")
Future<Map<String, dynamic>?> getMusicInCache() async {
  final Map<String, dynamic> cache = await latestRadioDB.query();
  // Because it's guaranteed to be 0 or 1
  if (cache["paging"]["size"] == 1) {
    return cache["items"][0];
  }

  return null;
}

@Deprecated("Use the mongo_dart API calls instead")
Future<Map<String, double>?> getTimeRemainingAllMusic() async {
  final Map<String, double>? musicInfo = await getMusicInfo();
  if (musicInfo == null) return null;

  final Map<String, dynamic>? musicInCache = await getMusicInCache();
  if (musicInCache == null) return null;

  // The lazy way
  final Map<String, double> longestOngoingMusic = <String, double>{};
  musicInfo.forEach((k, v) {
    longestOngoingMusic[k] = getTimeLeftToSong(
        musicInfo,
        musicInCache["base_music"],
        DateTime.fromMillisecondsSinceEpoch(
            (double.parse(musicInCache["time"]) * 1000).toInt(),
            isUtc: true),
        k,
        DateTime.now());
  });

  return longestOngoingMusic;
}*/

shelf.Response badRequestMsg() =>
    shelf.Response.badRequest(body: "Bad Request");
shelf.Response notFoundMsg() => shelf.Response.notFound("Not Found");
shelf.Response methodNotAllowedMsg() =>
    shelf.Response(405, body: "Method Not Allowed");
shelf.Response goneMsg() => shelf.Response(410, body: "Gone");
shelf.Response genericOKMsg() => shelf.Response.ok("OK");
