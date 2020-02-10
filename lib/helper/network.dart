import 'package:dio/dio.dart';
import 'package:html/dom.dart';
import 'package:html/parser.dart' show parse;

class Network {
  static Dio _client;

  static Future loadUrl(String url) async {
    _loadClient();

    try {
      Response response = await _client.get(url);

      Document dom = parse(response.data.toString());
      String title = dom?.head?.querySelector('title')?.text;

      if (title != null) {
        return omitTrailingTextForLongTitle(title);
      }

      return 'Website not found';
    } on DioError catch (error) {
      print(error);
      return 'Unable to fetch url';
    }
  }

  static String omitTrailingTextForLongTitle(title) {
    if (title.length > 30) {
      return title.substring(0, 30) + '...';
    }

    return title;
  }

  static void _loadClient() {
    if (_client == null) {
      _client = Dio();
    }
  }
}
