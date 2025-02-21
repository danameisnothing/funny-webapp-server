import 'dart:io';

import 'package:funny_webapp_server/app_utils.dart' as app_utils;
import 'package:funny_webapp_server/deta_base_driver.dart';

const liveStreamID = "vnerJ3LLqL8";
/*const steamCotLSoundtrackURL =
    "https://store.steampowered.com/app/2015890/Cult_of_the_Lamb_Soundtrack/";
const cotlCacheTime = Duration(days: 7);*/
const defJSONHeader = {"Content-Type": "application/json; charset=utf-8"};
const defPlainTextHeader = {"Content-Type": "text/plain"};
const coreHandlerCtxDBKeyName = "db_instance";

// API / DB names (usually DB key names, or API key parameter names)
const dbCotLCacheMainKeyName = "music_durations";
const apiMusicDurationsKeyName = "music_durations";

const dbCurrPlayingMusicKeyName = "music";
const dbLastUpdatedKeyName = "last_updated";
const apiCurrPlayingMusicKeyName = "curr_playing";
const apiOffsetSKeyName = "offs_s";
const apiBatchInfoMusicNameKey = "music_name";
const apiBatchInfoMusicTimeRemainingKey = "time_remaining";

final devMongoDBPassword = app_utils.getDBEnvPass();

// (Deprecated) DetaBase variables
@Deprecated("This variable is only for backwards compatibility as we move away from Deta")
final steamCotLCacheDB = DetaBase(
    Platform.environment["DETA_PROJECT_KEY"]!.split("_")[0],
    "steam_cotl_soundtrack_cache",
    Platform.environment["DETA_PROJECT_KEY"]!);
@Deprecated("This variable is only for backwards compatibility as we move away from Deta")
final latestRadioDB = DetaBase(
    Platform.environment["DETA_PROJECT_KEY"]!.split("_")[0],
    "latest_cotl_radio_music",
    Platform.environment["DETA_PROJECT_KEY"]!);