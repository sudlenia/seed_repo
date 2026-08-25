import 'package:wallet_test/core/tokens/app_tokens.dart';

String formatAddressForCell(String address, double textScaleFactor) {
  bool hasPrefix = address.startsWith('0x');
  String prefix = hasPrefix ? '0x' : '';
  String body = hasPrefix ? address.substring(2) : address;
  
  if (body.length <= 12) {
    return address;
  }
  
  int startLength = textScaleFactor < 1.6 ? 6 : 4;
  
  String start = body.substring(0, startLength);
  String end = body.substring(body.length - 4);
  
  return '$prefix$start…$end';
}