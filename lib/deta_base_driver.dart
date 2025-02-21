import 'dart:convert';

import 'package:http/http.dart' as http;

@Deprecated("This class is only for backwards compatibility as we move away from Deta")
class DetaBase {
  String collectionId;
  String baseName;
  String apiKey;

  late String baseURL;
  late Map<String, String> defHeaders;

  DetaBase(this.collectionId, this.baseName, this.apiKey) {
    baseURL = "https://database.deta.sh/v1/$collectionId/$baseName";
    defHeaders = {"Content-Type": "application/json", "X-Api-Key": apiKey};
  }

  void _validateStatusCode(int statusCode, {String? body}) {
    if ((statusCode / 100).floor() != 2) {
      throw Exception(
          "Status code returned is not 2xx (status code $statusCode)${(body != null) ? ", errors are : ${jsonDecode(body)["errors"]}" : ""}");
    }
  }

  Future<Map<String, dynamic>> put(List<Object> items) async {
    http.Response res = await http.put(Uri.parse("$baseURL/items"),
        headers: defHeaders, body: jsonEncode({"items": items}));
    _validateStatusCode(res.statusCode, body: res.body);

    return jsonDecode(res.body);
  }

  Future<Map<String, dynamic>> get(String key) async {
    // See https://deta.space/docs/en/build/reference/http-api/base for more detail
    http.Response res = await http.get(
        Uri.parse(Uri.encodeFull("$baseURL/items/$key")),
        headers: defHeaders);
    _validateStatusCode(res.statusCode, body: res.body);

    return jsonDecode(res.body)
      ..removeWhere((k, v) =>
          k ==
          "key"); // Exclude the "key" key that's always the same as the key we queried
  }

  Future delete(String key) async {
    // See https://deta.space/docs/en/build/reference/http-api/base for more detail
    http.Response res = await http.delete(
        Uri.parse(Uri.encodeFull("$baseURL/items/$key")),
        headers: defHeaders);
    _validateStatusCode(res.statusCode,
        body: res
            .body); // Even though the docs says that it will always return 200, even if the key doesn't exist, it stll returns 400 if the key is empty
  }

  Future<Map<String, dynamic>> insert(Object item) async {
    http.Response res = await http.post(Uri.parse("$baseURL/items"),
        headers: defHeaders, body: jsonEncode({"item": item}));
    _validateStatusCode(res.statusCode, body: res.body);
    return jsonDecode(res.body);
  }

  // TODO: add more of the actual arguments: https://deta.space/docs/en/build/reference/http-api/base
  // FIXME: maybe the Object parameter should be abstracted more like in the official SDKs
  Future<Map<String, dynamic>> update(String key, Object rawQuery) async {
    http.Response res = await http.patch(
        Uri.parse(Uri.encodeFull("$baseURL/items/$key")),
        headers: defHeaders,
        body: jsonEncode(rawQuery));
    _validateStatusCode(res.statusCode, body: res.body);
    return jsonDecode(res.body)
      ..removeWhere((k, v) =>
          k ==
          "key"); // Exclude the "key" key that's always the same as the key we queried
  }

  // TODO: add the actual arguments: https://deta.space/docs/en/build/reference/http-api/base
  Future<Map<String, dynamic>> query() async {
    // FIXME: this doesn't support pagination! See the docs!
    http.Response res =
        await http.post(Uri.parse("$baseURL/query"), headers: defHeaders);
    _validateStatusCode(res.statusCode, body: res.body);
    return jsonDecode(res.body);
  }
}
