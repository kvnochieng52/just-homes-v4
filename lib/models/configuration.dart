//import 'package:flutter/material.dart';

class Configuration {
  static const appName = 'JUST APARTMENT';
  static const imagesPath = './images';
  static const appLogo = "$imagesPath/logo.png";

  static const API_URL = 'https://justhomes.co.ke/api/';
  static const WEB_URL = 'https://justhomes.co.ke/';

  // static const API_URL = 'http://10.0.2.2:8000/api/';
  // static const WEB_URL = 'http://10.0.2.2:8000/';

  // static validateEmail(String email) {
  //   return RegExp(r'^.+@[a-zA-Z]+\.{1}[a-zA-Z]+(\.{0,1}[a-zA-Z]+)$')
  //       .hasMatch(email);
  // }

  static validateEmail(String email) async {
    // bool emailValid = RegExp(
    //         r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+")
    //     .hasMatch(email);
    // return emailValid;

    return "name";
  }
}
