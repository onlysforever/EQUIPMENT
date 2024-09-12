import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:seoyoneh_equipment/Util/util.dart';

class Net {
  static Future<http.Response> post(String service, dynamic param) {
    return http.post(Uri.parse('${Util.SERVICE_HOST}$service'),
        headers: {
          'Content-Type': 'application/json',
          'AuthKey': Util.encodeAuthData
        },
        body: jsonEncode(param));
  }

  static Future<http.Response> multipartRequest(String service, Map<String, dynamic> imageMap, Map<String, String> param) async {
    var request = await http.MultipartRequest('POST', Uri.parse('${Util.SERVICE_HOST}$service'));
    if(imageMap['PROB1_IMG_PATH'] != null) {
      request.files.add(await http.MultipartFile.fromPath('prob1Image', imageMap['PROB1_IMG_PATH'], filename: imageMap['PROB1_IMG_NM']));
    } else if(imageMap['PROB_PHOTO_1'] != null) {
      request.files.add(await http.MultipartFile.fromBytes('prob1Image', imageMap['PROB_PHOTO_1'], filename: ''));
    }
    if(imageMap['PROB2_IMG_PATH'] != null) {
      request.files.add(await http.MultipartFile.fromPath('prob2Image', imageMap['PROB2_IMG_PATH'], filename: imageMap['PROB2_IMG_NM']));
    } else if(imageMap['PROB_PHOTO_2'] != null) {
      request.files.add(await http.MultipartFile.fromBytes('prob2Image', imageMap['PROB_PHOTO_2'], filename: ''));
    }
    if(imageMap['SOLV1_IMG_PATH'] != null) {
      request.files.add(await http.MultipartFile.fromPath('solv1Image', imageMap['SOLV1_IMG_PATH'], filename: imageMap['SOLV1_IMG_NM']));
      print(imageMap['SOLV1_IMG_NM']);
    } else if(imageMap['SOLV_PHOTO_1'] != null) {
      request.files.add(await http.MultipartFile.fromBytes('solv1Image', imageMap['SOLV_PHOTO_1'], filename: ''));
    }
    if(imageMap['SOLV2_IMG_PATH'] != null) {
      request.files.add(await http.MultipartFile.fromPath('solv2Image', imageMap['SOLV2_IMG_PATH'], filename: imageMap['SOLV2_IMG_NM']));
      print(imageMap['SOLV2_IMG_NM']);
    } else if(imageMap['SOLV_PHOTO_2'] != null) {
      request.files.add(await http.MultipartFile.fromBytes('solv2Image', imageMap['SOLV_PHOTO_2'], filename: ''));
    }
    
    request.headers.addAll({
      'AuthKey': Util.encodeAuthData
    });
    request.fields.addAll(param);
    return http.Response.fromStream(await request.send());
  }
}