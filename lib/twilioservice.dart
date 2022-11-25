import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:twiliovideo/config.dart';

class TwilioFunctionsService {
  // TwilioFunctionsService._();
  // static final instance = TwilioFunctionsService._();
  TwilioFunctionsService();
  final http.Client client = http.Client();
  final accessTokenUrl = AppConfig.accessTokenUrl;

  createToken(String identity) async {
    try {
      Map<String, String> header = {
        'Content-Type': 'application/json',
      };
      var url = Uri.parse('$accessTokenUrl?user=$identity');
      print(url);
      final response = await client.get(url, headers: header);
      Map<String, dynamic> responseMap = jsonDecode(response.body);
      print(responseMap);
      return responseMap['accessToken'];
    } catch (error) {
      throw Exception([error.toString()]);
    }
  }
}
