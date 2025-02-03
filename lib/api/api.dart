import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:just_apartment_live/models/configuration.dart';

class CallApi {
  final String _url = Configuration.API_URL;

  postData(data, apiUrl) async {
    var fullUrl = _url + apiUrl;


    print("FULLURL   " + fullUrl);
    print("DATA----<<<<<>>>>>" + fullUrl);

    return await http.post(Uri.parse(fullUrl),
        body: jsonEncode(data), headers: _setHeaders());
  }

  getData(apiUrl) async {
    var fullUrl = _url + apiUrl;
    return await http.get(Uri.parse(fullUrl), headers: _setHeaders());
  }

  _setHeaders() => {
        'Content-type': 'application/json',
        'Accept': 'application/json',
      };
}
