import 'dart:io';
import 'package:data_table_2/data_table_2.dart';
import 'package:dio/dio.dart';
import 'package:encrypt/encrypt.dart' as Encrypt;
import 'package:flutter/material.dart';
import 'package:flutter_toastr/flutter_toastr.dart';
import 'package:intl/intl.dart';
import 'package:seoyoneh_equipment/Font/font.dart';

enum Term { D, W }
enum CheckType { QR, LIST }

extension DateTimeExtension on DateTime {
  int get weekOfMonth {
    var week = 0;
    var date = this;
    while (date.month == month) {
      week++;
      date = date.subtract(const Duration(days: 7));
    }
    return week;
  }
}

class Util {
  ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  // Variable
  ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  static Map<String, dynamic> USER_INFO = {};
  // static final String SERVICE_HOST = 'http://192.168.0.131:8080/equipment';
  static String SERVICE_HOST = 'http://jwebapi.seoyoneh.com:4877/equipment';
  // static final String SERVICE_HOST_UPLOAD = 'http://192.168.0.141:8080/upload';

  // static String SERVICE_HOST = 'http://172.20.10.6:8080/equipment';
  // static String SERVICE_HOST_UPLOAD = 'http://192.168.0.141:8080/upload';

  // static String SERVICE_HOST = 'http://10.10.12.90:8080/equipment';
  // static String SERVICE_HOST_UPLOAD = 'http://192.168.0.141:8080/upload';

  // static String SERVICE_HOST = 'http://124.194.56.110:4877/sis';
  // static String SERVICE_HOST_UPLOAD = 'http://124.194.56.110:4877/upload';

  static final FILE_DOWNLOAD_HOST = 'https://scm.seoyoneh.com/Download.aspx?FileID=';
  static String appVersion = '';
  static String authData = 'SEOYONEH';
  static final encodeKey = Encrypt.Key.fromUtf8('8B55A44B49368262DF89FD0E17B1A181');
  static final iv = Encrypt.IV.fromLength(16);
  static final encrypter = Encrypt.Encrypter(Encrypt.AES(encodeKey, mode: Encrypt.AESMode.cbc));
  static final encodeAuthData = encrypter.encrypt(authData, iv: iv).base64;

  static List<DropDownCode> checkResultCodes = <DropDownCode>[DropDownCode('SUCCESS', '', '정상'), DropDownCode('FAIL', '', '이상')];
  static List<DropDownCode> checkTermCodes = <DropDownCode>[DropDownCode('W', '', '주간'), DropDownCode('M', '', '월간'), DropDownCode('Q', '', '분기'), DropDownCode('H', '', '반기'), DropDownCode('Y', '', '연간')];
  static List<DropDownCode> moterStandardCodes = <DropDownCode>[DropDownCode('45', '', '45KW'), DropDownCode('5.5', '', '5.5KW')];
  static List<DropDownCode> gradeCodes = <DropDownCode>[DropDownCode('', '', ''), DropDownCode('A', '', 'A'), DropDownCode('B', '', 'B'), DropDownCode('C', '', 'C'), DropDownCode('D', '', 'D')];
  static List<DropDownCode> whetherCodes = <DropDownCode>[DropDownCode('PURE', '', '맑음'), DropDownCode('BLUR', '', '흐림')];

  ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  // Functions
  ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  static String thousandNumberFormat(value) {
    var f = NumberFormat('###,###,###,###');
    return f.format(value);
  }

  static String doubleNumberFormat(value) {
    var f = NumberFormat('###,##0.00');
    return f.format(value);
  }

  static String dateFormat(d, format) {
    return DateFormat(format).format(d);
  }

  static String weekOfMonth(DateTime d) {
    return d.weekOfMonth.toString();
  }

  static String month(DateTime d) {
    print(d.month);
    return d.month < 10 ? '0${d.month}' : d.month.toString();
  }

  static String quarter(DateTime d) {
    return (d.month / 3.0).ceil().toString();
  }

  static String half(DateTime d) {
    return (d.month / 6.0).ceil().toString();
  }

  static String year(DateTime d) {
    return d.year.toString();
  }

  static String qcTerm(item) {
    String term = 'D';
    if (item['QCTERMD'] == 'Y') {
      term = 'D';
    } else if (item['QCTERMW'] == 'Y') {
      term = 'W';
    } else if (item['QCTERMM'] == 'Y') {
      term = 'M';
    } else if (item['QCTERMQ'] == 'Y') {
      term = 'Q';
    } else if (item['QCTERMH'] == 'Y') {
      term = 'H';
    } else if (item['QCTERMY'] == 'Y') {
      term = 'Y';
    }
    return term;
  }

  static DropDownCode GetCodeItem(items, value) {
    if (items != null && items.length > 0) {
      for (var index = 0; index < items.length; index++) {
        DropDownCode item = items[index];
        print(items[index]);
        if (item.code == value) {
          return item;
        }
      }
    }
    return DropDownCode('', '', '');
  }

  ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  // Navigator
  ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  static pushNavigator(BuildContext context, newPage) {
    return Navigator.push(context, MaterialPageRoute(builder: (context) => newPage));
  }

  static replacePushNavigator(BuildContext context, newPage) {
    return Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => newPage));
  }

  ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  // Alert
  ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  static AlertDialog ShowMessagePopup(context, message) {
    return AlertDialog(
      contentPadding: EdgeInsets.only(left: 15.0, right: 15.0, top: 10.0, bottom: 5.0),
      actionsPadding: EdgeInsets.only(left: 15.0, right: 10.0, bottom: 5.0, top: 5.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
      ),
      titlePadding: EdgeInsets.all(10.0),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Container(
            margin: EdgeInsets.zero,
            padding: EdgeInsets.zero,
            height: 25.0,
            child: Image.asset(
              'images/SEOYONEH_CI.png',
              fit: BoxFit.contain,
            ),
          ),
        ],
      ),
      content: Container(
        padding: EdgeInsets.zero,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              message,
              style: const TextStyle(
                fontSize: 20.0,
                color: Colors.black,
                fontFamily: MyFontStyle.nanumGothicBold,
                height: 1.2,
              ),
            )
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          style: TextButton.styleFrom(textStyle: const TextStyle(color: Colors.white, fontFamily: MyFontStyle.nanumGothic), foregroundColor: Colors.white, backgroundColor: Color.fromRGBO(0, 80, 155, 1), shape: RoundedRectangleBorder(side: const BorderSide(color: Colors.transparent, width: 1, style: BorderStyle.solid), borderRadius: BorderRadius.circular(30))),
          autofocus: true,
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text(
            '확인',
            style: TextStyle(
              fontFamily: MyFontStyle.nanumGothicBold,
              fontSize: 18.0,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  static AlertDialog ShowConfirmPopup(context, message, callback) {
    return AlertDialog(
      contentPadding: EdgeInsets.only(left: 15.0, right: 15.0, top: 10.0, bottom: 5.0),
      actionsPadding: EdgeInsets.only(left: 15.0, right: 10.0, bottom: 5.0, top: 5.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
      ),
      titlePadding: EdgeInsets.all(10.0),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Container(
            margin: EdgeInsets.zero,
            padding: EdgeInsets.zero,
            height: 25.0,
            child: Image.asset(
              'images/SEOYONEH_CI.png',
              fit: BoxFit.contain,
            ),
          ),
        ],
      ),
      content: Container(
        padding: EdgeInsets.zero,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              message,
              style: const TextStyle(
                fontSize: 20.0,
                color: Colors.black,
                fontFamily: MyFontStyle.nanumGothicBold,
                height: 1.2,
              ),
            )
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          style: TextButton.styleFrom(textStyle: const TextStyle(color: Colors.white, fontFamily: MyFontStyle.nanumGothic), foregroundColor: Colors.white, backgroundColor: Color.fromRGBO(0, 80, 155, 1), shape: RoundedRectangleBorder(side: const BorderSide(color: Colors.transparent, width: 1, style: BorderStyle.solid), borderRadius: BorderRadius.circular(30))),
          autofocus: true,
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text(
            '취소',
            style: TextStyle(
              fontFamily: MyFontStyle.nanumGothicBold,
              fontSize: 18.0,
              color: Colors.white,
            ),
          ),
        ),
        TextButton(
          style: TextButton.styleFrom(textStyle: const TextStyle(color: Colors.white, fontFamily: MyFontStyle.nanumGothic), foregroundColor: Colors.white, backgroundColor: Color.fromRGBO(0, 80, 155, 1), shape: RoundedRectangleBorder(side: const BorderSide(color: Colors.transparent, width: 1, style: BorderStyle.solid), borderRadius: BorderRadius.circular(30))),
          autofocus: true,
          onPressed: callback,
          child: const Text(
            '확인',
            style: TextStyle(
              fontFamily: MyFontStyle.nanumGothicBold,
              fontSize: 18.0,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  static ShowTermPopup(context, Term term, callback) {
    return StatefulBuilder(builder: ((context, setState) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
        contentPadding: EdgeInsets.only(left: 10.0, right: 10.0),
        actionsPadding: EdgeInsets.only(left: 10.0, right: 10.0, bottom: 10.0),
        titlePadding: EdgeInsets.all(10.0),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Container(
              margin: EdgeInsets.zero,
              padding: EdgeInsets.zero,
              height: 25.0,
              child: Image.asset(
                'images/SEOYONEH_CI.png',
                fit: BoxFit.contain,
              ),
            ),
          ],
        ),
        content: Container(
          padding: EdgeInsets.zero,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              RadioListTile(
                contentPadding: EdgeInsets.zero,
                activeColor: Color.fromRGBO(0, 80, 155, 1.0),
                title: Text(
                  '일상 점검',
                  style: TextStyle(fontFamily: MyFontStyle.nanumGothic, fontSize: 17),
                ),
                value: Term.D,
                groupValue: term,
                onChanged: (value) {
                  setState(() {
                    term = value!;
                  });
                },
              ),
              RadioListTile(
                contentPadding: EdgeInsets.zero,
                activeColor: Color.fromRGBO(0, 80, 155, 1.0),
                title: Text(
                  '정기 점검',
                  style: TextStyle(fontFamily: MyFontStyle.nanumGothic, fontSize: 17),
                ),
                value: Term.W,
                groupValue: term,
                onChanged: (value) {
                  setState(() {
                    term = value!;
                  });
                },
              ),
            ],
          ),
        ),
        actions: <Widget>[
          ElevatedButton(
            style: ElevatedButton.styleFrom(textStyle: const TextStyle(color: Colors.white, fontFamily: MyFontStyle.nanumGothic), foregroundColor: Colors.white, backgroundColor: Color.fromRGBO(0, 80, 155, 1), shape: RoundedRectangleBorder(side: const BorderSide(color: Colors.transparent, width: 1, style: BorderStyle.solid), borderRadius: BorderRadius.circular(30))),
            autofocus: true,
            child: Container(
              padding: EdgeInsets.all(5),
              child: Text("취소", style: TextStyle(fontSize: 16, fontFamily: MyFontStyle.nanumGothic)),
            ),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(textStyle: const TextStyle(color: Colors.white, fontFamily: MyFontStyle.nanumGothic), foregroundColor: Colors.white, backgroundColor: Color.fromRGBO(0, 80, 155, 1), shape: RoundedRectangleBorder(side: const BorderSide(color: Colors.transparent, width: 1, style: BorderStyle.solid), borderRadius: BorderRadius.circular(30))),
            autofocus: true,
            child: Container(
              padding: EdgeInsets.all(5),
              child: Text("확인", style: TextStyle(fontSize: 16, fontFamily: MyFontStyle.nanumGothic)),
            ),
            onPressed: () => callback(term.name == Term.D.name ? term.name : checkTermCodes.first.code),
          )
        ],
      );
    }));
  }

  // static ShowCheckPopup(context, String code, callback) {
  //   // CM : 일상, 정기 점검, BA : 안전기, GN : 비상발전기, MT : 모터진동측정
  //   return StatefulBuilder(builder: ((context, setState) {
  //     return AlertDialog(
  //       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
  //       contentPadding: EdgeInsets.only(left: 10.0, right: 10.0),
  //       actionsPadding: EdgeInsets.only(left: 10.0, right: 10.0, bottom: 10.0),
  //       titlePadding: EdgeInsets.all(10.0),
  //       title: Row(
  //         mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //         crossAxisAlignment: CrossAxisAlignment.center,
  //         children: <Widget>[
  //           Container(
  //             margin: EdgeInsets.zero,
  //             padding: EdgeInsets.zero,
  //             height: 25.0,
  //             child: Image.asset(
  //               'images/SEOYONEH_CI.png',
  //               fit: BoxFit.contain,
  //             ),
  //           ),
  //         ],
  //       ),
  //       content: Container(
  //         padding: EdgeInsets.zero,
  //         child: Column(
  //           mainAxisSize: MainAxisSize.min,
  //           crossAxisAlignment: CrossAxisAlignment.start,
  //           children: <Widget>[
  //             RadioListTile(
  //               contentPadding: EdgeInsets.zero,
  //               activeColor: Color.fromRGBO(0, 80, 155, 1.0),
  //               title: Text(
  //                 '설비 일상점검',
  //                 style: TextStyle(fontFamily: MyFontStyle.nanumGothic, fontSize: 17),
  //               ),
  //               value: 'CM',
  //               groupValue: code,
  //               onChanged: (value) {
  //                 setState(() {
  //                   code = value!;
  //                 });
  //               },
  //             ),
  //             RadioListTile(
  //               contentPadding: EdgeInsets.zero,
  //               activeColor: Color.fromRGBO(0, 80, 155, 1.0),
  //               title: Text(
  //                 '안전기 점검',
  //                 style: TextStyle(fontFamily: MyFontStyle.nanumGothic, fontSize: 17),
  //               ),
  //               value: 'BA',
  //               groupValue: code,
  //               onChanged: (value) {
  //                 setState(() {
  //                   code = value!;
  //                 });
  //               },
  //             ),
  //             RadioListTile(
  //               contentPadding: EdgeInsets.zero,
  //               activeColor: Color.fromRGBO(0, 80, 155, 1.0),
  //               title: Text(
  //                 '비상발전기 점검',
  //                 style: TextStyle(fontFamily: MyFontStyle.nanumGothic, fontSize: 17),
  //               ),
  //               value: 'GN',
  //               groupValue: code,
  //               onChanged: (value) {
  //                 setState(() {
  //                   code = value!;
  //                 });
  //               },
  //             ),
  //             RadioListTile(
  //               contentPadding: EdgeInsets.zero,
  //               activeColor: Color.fromRGBO(0, 80, 155, 1.0),
  //               title: Text(
  //                 '모터 진동 측정',
  //                 style: TextStyle(fontFamily: MyFontStyle.nanumGothic, fontSize: 17),
  //               ),
  //               value: 'MT',
  //               groupValue: code,
  //               onChanged: (value) {
  //                 setState(() {
  //                   code = value!;
  //                 });
  //               },
  //             ),
  //           ],
  //         ),
  //       ),
  //       actions: <Widget>[
  //         ElevatedButton(
  //           style: ElevatedButton.styleFrom(textStyle: const TextStyle(color: Colors.white, fontFamily: MyFontStyle.nanumGothic), foregroundColor: Colors.white, backgroundColor: Color.fromRGBO(0, 80, 155, 1), shape: RoundedRectangleBorder(side: const BorderSide(color: Colors.transparent, width: 1, style: BorderStyle.solid), borderRadius: BorderRadius.circular(30))),
  //           autofocus: true,
  //           child: Container(
  //             padding: EdgeInsets.all(5),
  //             child: Text("취소", style: TextStyle(fontSize: 16, fontFamily: MyFontStyle.nanumGothic)),
  //           ),
  //           onPressed: () {
  //             Navigator.pop(context);
  //           },
  //         ),
  //         ElevatedButton(
  //           style: ElevatedButton.styleFrom(textStyle: const TextStyle(color: Colors.white, fontFamily: MyFontStyle.nanumGothic), foregroundColor: Colors.white, backgroundColor: Color.fromRGBO(0, 80, 155, 1), shape: RoundedRectangleBorder(side: const BorderSide(color: Colors.transparent, width: 1, style: BorderStyle.solid), borderRadius: BorderRadius.circular(30))),
  //           autofocus: true,
  //           child: Container(
  //             padding: EdgeInsets.all(5),
  //             child: Text("확인", style: TextStyle(fontSize: 16, fontFamily: MyFontStyle.nanumGothic)),
  //           ),
  //           onPressed: () => callback(code),
  //         )
  //       ],
  //     );
  //   }));
  // }

  static ShowCheckTypePopup(context, CheckType checkType, String title, callback) {
    return StatefulBuilder(builder: ((context, setState) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
        contentPadding: EdgeInsets.only(left: 10.0, right: 10.0),
        actionsPadding: EdgeInsets.only(left: 10.0, right: 10.0, bottom: 10.0),
        titlePadding: EdgeInsets.all(10.0),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Container(
              margin: EdgeInsets.zero,
              padding: EdgeInsets.zero,
              height: 25.0,
              child: Image.asset(
                'images/SEOYONEH_CI.png',
                fit: BoxFit.contain,
              ),
            ),
          ],
        ),
        content: Container(
          padding: EdgeInsets.zero,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              RadioListTile(
                contentPadding: EdgeInsets.zero,
                activeColor: Color.fromRGBO(0, 80, 155, 1.0),
                title: Text(
                  'QR',
                  style: TextStyle(fontFamily: MyFontStyle.nanumGothic, fontSize: 17),
                ),
                value: CheckType.QR,
                groupValue: checkType,
                onChanged: (value) {
                  setState(() {
                    checkType = value!;
                  });
                },
              ),
              RadioListTile(
                contentPadding: EdgeInsets.zero,
                activeColor: Color.fromRGBO(0, 80, 155, 1.0),
                title: Text(
                  title,
                  style: TextStyle(fontFamily: MyFontStyle.nanumGothic, fontSize: 17),
                ),
                value: CheckType.LIST,
                groupValue: checkType,
                onChanged: (value) {
                  setState(() {
                    checkType = value!;
                  });
                },
              ),
            ],
          ),
        ),
        actions: <Widget>[
          ElevatedButton(
            style: ElevatedButton.styleFrom(textStyle: const TextStyle(color: Colors.white, fontFamily: MyFontStyle.nanumGothic), foregroundColor: Colors.white, backgroundColor: Color.fromRGBO(0, 80, 155, 1), shape: RoundedRectangleBorder(side: const BorderSide(color: Colors.transparent, width: 1, style: BorderStyle.solid), borderRadius: BorderRadius.circular(30))),
            autofocus: true,
            child: Container(
              padding: EdgeInsets.all(5),
              child: Text("취소", style: TextStyle(fontSize: 16, fontFamily: MyFontStyle.nanumGothic)),
            ),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(textStyle: const TextStyle(color: Colors.white, fontFamily: MyFontStyle.nanumGothic), foregroundColor: Colors.white, backgroundColor: Color.fromRGBO(0, 80, 155, 1), shape: RoundedRectangleBorder(side: const BorderSide(color: Colors.transparent, width: 1, style: BorderStyle.solid), borderRadius: BorderRadius.circular(30))),
            autofocus: true,
            child: Container(
              padding: EdgeInsets.all(5),
              child: Text("확인", style: TextStyle(fontSize: 16, fontFamily: MyFontStyle.nanumGothic)),
            ),
            onPressed: () => callback(checkType.name == CheckType.QR.name ? checkType.name : CheckType.LIST.name),
          )
        ],
      );
    }));
  }

  static ShowWorkerPopup(context, List<dynamic> workerList, List<dynamic> checkedList, callback) {
    return StatefulBuilder(builder: ((context, setState) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
        contentPadding: EdgeInsets.only(left: 10.0, right: 10.0),
        actionsPadding: EdgeInsets.only(left: 10.0, right: 10.0, bottom: 10.0),
        titlePadding: EdgeInsets.all(10.0),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Container(
              margin: EdgeInsets.zero,
              padding: EdgeInsets.zero,
              height: 25.0,
              child: Image.asset(
                'images/SEOYONEH_CI.png',
                fit: BoxFit.contain,
              ),
            ),
          ],
        ),
        content: Container(
          padding: EdgeInsets.zero,
          margin: EdgeInsets.only(bottom: 10),
          width: MediaQuery.of(context).size.height * 0.3,
          height: MediaQuery.of(context).size.height * 0.7,
          child: ListView.builder(
            itemCount: workerList.length,
            itemBuilder: (context, index) {
              if(workerList[index]['CHECK'] == null) {
                workerList[index]['CHECK'] = false;
              }
              return CheckboxListTile(
                checkColor: const Color.fromRGBO(250, 175, 25, 1.0),
                fillColor: MaterialStateColor.resolveWith(
                      (states) => Colors.transparent),
                side: MaterialStateBorderSide.resolveWith((states) =>
                      const BorderSide(
                          color: Color.fromRGBO(0, 80, 155, 1.0), width: 2.0)),
                title: Text('${workerList[index]['WORK_EMPNM']}(${workerList[index]['WORK_EMPNO']})', style: TextStyle(fontFamily: MyFontStyle.nanumGothic, fontSize: 17)),
                value: workerList[index]['CHECK'], 
                onChanged: (value) {
                  if(value == false) {
                    checkedList.remove(index);
                  } else {
                    checkedList.add(index);
                  }
                  setState(() {
                    workerList[index]['CHECK'] = value;
                  });
                }
              );
            }
          ),
        ),
        actions: <Widget>[
          ElevatedButton(
            style: ElevatedButton.styleFrom(textStyle: const TextStyle(color: Colors.white, fontFamily: MyFontStyle.nanumGothic), foregroundColor: Colors.white, backgroundColor: Color.fromRGBO(0, 80, 155, 1), shape: RoundedRectangleBorder(side: const BorderSide(color: Colors.transparent, width: 1, style: BorderStyle.solid), borderRadius: BorderRadius.circular(30))),
            autofocus: true,
            child: Container(
              padding: EdgeInsets.all(5),
              child: Text("취소", style: TextStyle(fontSize: 16, fontFamily: MyFontStyle.nanumGothic)),
            ),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(textStyle: const TextStyle(color: Colors.white, fontFamily: MyFontStyle.nanumGothic), foregroundColor: Colors.white, backgroundColor: Color.fromRGBO(0, 80, 155, 1), shape: RoundedRectangleBorder(side: const BorderSide(color: Colors.transparent, width: 1, style: BorderStyle.solid), borderRadius: BorderRadius.circular(30))),
            autofocus: true,
            child: Container(
              padding: EdgeInsets.all(5),
              child: Text("확인", style: TextStyle(fontSize: 16, fontFamily: MyFontStyle.nanumGothic)),
            ),
            onPressed: () => callback(workerList, checkedList),
          )
        ],
      );
    }));
  }

  static ShowPartPopup(context, String workNo, callback) {
    List<dynamic> result = [];
    bool isResultEmpty = true;
    return StatefulBuilder(builder: ((context, setState) {
      // loadPartList(setState);
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
        contentPadding: EdgeInsets.only(left: 10.0, right: 10.0),
        actionsPadding: EdgeInsets.only(left: 10.0, right: 10.0, bottom: 10.0),
        titlePadding: EdgeInsets.all(10.0),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Container(
              margin: EdgeInsets.zero,
              padding: EdgeInsets.zero,
              height: 25.0,
              child: Image.asset(
                'images/SEOYONEH_CI.png',
                fit: BoxFit.contain,
              ),
            ),
            OutlinedButton(
              style: OutlinedButton.styleFrom(backgroundColor: Color.fromRGBO(0, 80, 155, 1)),
              onPressed: () async {
                // Navigator.pop(context);
              }, 
              child: Text('추가', style: TextStyle(color: Colors.white, fontFamily: MyFontStyle.nanumGothic, fontSize: 16),)
            )
          ],
        ),
        content: Container(
          padding: EdgeInsets.zero,
          margin: EdgeInsets.only(bottom: 10),
          width: MediaQuery.of(context).size.width * 0.7,
          height: MediaQuery.of(context).size.height * 0.5,
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 5.0),
            child: Theme(
              data: Theme.of(context).copyWith(dividerColor: Color.fromRGBO(190, 190, 190, 1.0)),
              child: DataTable2(
                headingRowColor: MaterialStateColor.resolveWith((states) => Color.fromRGBO(0, 80, 155, 1.0)),
                columns: [
                  const DataColumn2(label: Center(child: Text('일련번호', style: TextStyle(fontSize: 13, color: Colors.white, fontFamily: MyFontStyle.nanumGothicBold))), fixedWidth: 60),
                  DataColumn2(label: verticalDivider, fixedWidth: 10),
                  const DataColumn2(label: Center(child: Text('자재번호', style: TextStyle(fontSize: 13, color: Colors.white, fontFamily: MyFontStyle.nanumGothicBold))), fixedWidth: 120),
                  DataColumn2(label: verticalDivider, fixedWidth: 10),
                  const DataColumn2(label: Center(child: Text('자재명', style: TextStyle(fontSize: 13, color: Colors.white, fontFamily: MyFontStyle.nanumGothicBold)))),
                  DataColumn2(label: verticalDivider, fixedWidth: 10),
                  const DataColumn2(label: Center(child: Text('규격', style: TextStyle(fontSize: 13, color: Colors.white, fontFamily: MyFontStyle.nanumGothicBold)))),
                  DataColumn2(label: verticalDivider, fixedWidth: 10),
                  const DataColumn2(label: Center(child: Text('현재고', style: TextStyle(fontSize: 13, color: Colors.white, fontFamily: MyFontStyle.nanumGothicBold))), fixedWidth: 50),
                  DataColumn2(label: verticalDivider, fixedWidth: 10),
                  const DataColumn2(label: Center(child: Text('수량', style: TextStyle(fontSize: 13, color: Colors.white, fontFamily: MyFontStyle.nanumGothicBold))), fixedWidth: 50),
                  DataColumn2(label: verticalDivider, fixedWidth: 10),
                  const DataColumn2(label: Center(child: Text('금액', style: TextStyle(fontSize: 13, color: Colors.white, fontFamily: MyFontStyle.nanumGothicBold))), fixedWidth: 100),
                ],
                dataRowHeight: 40,
                columnSpacing: 0,
                showBottomBorder: true,
                horizontalMargin: 0,
                rows: List.generate(7, (index) {
                  return DataRow(cells: [
                    DataCell(Center(child: Text('${index+1}', style: TextStyle(fontSize: 13, fontFamily: MyFontStyle.nanumGothic)))),
                    DataCell(verticalDivider),
                    DataCell(Center(child: Text('AABABA-001', style: TextStyle(fontSize: 13, fontFamily: MyFontStyle.nanumGothic)))),
                    DataCell(verticalDivider),
                    DataCell(Center(child: Text('에어 솔레노이드 밸브', style: TextStyle(fontSize: 13, fontFamily: MyFontStyle.nanumGothic)))),
                    DataCell(verticalDivider),
                    DataCell(Center(child: Text('AB0020-aFf-FGd', style: TextStyle(fontSize: 13, fontFamily: MyFontStyle.nanumGothic)))),
                    DataCell(verticalDivider),
                    DataCell(Center(child: Text('10', style: TextStyle(fontSize: 13, fontFamily: MyFontStyle.nanumGothic)))),
                    DataCell(verticalDivider),
                    DataCell(Center(child: Text('1', style: TextStyle(fontSize: 13, fontFamily: MyFontStyle.nanumGothic)))),
                    DataCell(verticalDivider),
                    DataCell(Center(child: Text('167,000', style: TextStyle(fontSize: 13, fontFamily: MyFontStyle.nanumGothic)))),
                  ]);
                }),
              ),
            ),
          ),
        ),
        actions: <Widget>[
          ElevatedButton(
            style: ElevatedButton.styleFrom(textStyle: const TextStyle(color: Colors.white, fontFamily: MyFontStyle.nanumGothic), foregroundColor: Colors.white, backgroundColor: Color.fromRGBO(0, 80, 155, 1), shape: RoundedRectangleBorder(side: const BorderSide(color: Colors.transparent, width: 1, style: BorderStyle.solid), borderRadius: BorderRadius.circular(30))),
            autofocus: true,
            child: Container(
              padding: EdgeInsets.all(5),
              child: Text("닫기", style: TextStyle(fontSize: 16, fontFamily: MyFontStyle.nanumGothic)),
            ),
            onPressed: () => callback(),
          )
        ],
      );
    }));
  }

  static Widget verticalDivider = const VerticalDivider(
      color: Colors.black,
      thickness: 0.1,
  );

  static void showToastMessage(context, message) {
    FlutterToastr.show(
      message,
      context,
      duration: FlutterToastr.lengthLong,
      position: FlutterToastr.bottom,
      textStyle: TextStyle(fontFamily: MyFontStyle.nanumGothic, fontSize: 18, color: Colors.white),
      backgroundColor: Color.fromRGBO(110, 110, 110, 0.5),
    );
  }

  static Future<void> onExitApp(BuildContext context) async {
    return await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          contentPadding: EdgeInsets.only(left: 15.0, right: 15.0, top: 10.0, bottom: 5.0),
          actionsPadding: EdgeInsets.only(left: 15.0, right: 10.0, bottom: 5.0, top: 5.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
          titlePadding: EdgeInsets.all(10.0),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Container(
                margin: EdgeInsets.zero,
                padding: EdgeInsets.zero,
                height: 25.0,
                child: Image.asset(
                  'images/SEOYONEH_CI.png',
                  fit: BoxFit.contain,
                ),
              ),
            ],
          ),
          content: Container(
            padding: EdgeInsets.zero,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  '앱을 종료하시겠습니까?',
                  style: const TextStyle(
                    fontSize: 20.0,
                    color: Colors.black,
                    fontFamily: MyFontStyle.nanumGothic,
                  ),
                )
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              style: TextButton.styleFrom(textStyle: const TextStyle(color: Colors.white, fontFamily: MyFontStyle.nanumGothic), foregroundColor: Colors.white, backgroundColor: Color.fromRGBO(0, 80, 155, 1), shape: RoundedRectangleBorder(side: const BorderSide(color: Colors.transparent, width: 1, style: BorderStyle.solid), borderRadius: BorderRadius.circular(30))),
              onPressed: () {
                exit(0);
              },
              child: const Text(
                '예',
                style: TextStyle(
                  fontFamily: MyFontStyle.nanumGothicBold,
                  fontSize: 18.0,
                  color: Colors.white,
                ),
              ),
            ),
            TextButton(
              style: TextButton.styleFrom(textStyle: const TextStyle(color: Colors.white, fontFamily: MyFontStyle.nanumGothic), foregroundColor: Colors.white, backgroundColor: Color.fromRGBO(0, 80, 155, 1), shape: RoundedRectangleBorder(side: const BorderSide(color: Colors.transparent, width: 1, style: BorderStyle.solid), borderRadius: BorderRadius.circular(30))),
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text(
                '아니오',
                style: TextStyle(
                  fontFamily: MyFontStyle.nanumGothicBold,
                  fontSize: 18.0,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  static Future<dynamic> DownloadFile(dio, url, path, context, onReceiveProgress) async {
    try {
      Response response = await dio.get(
        url,
        options: Options(
          responseType: ResponseType.bytes,
          followRedirects: false,
          validateStatus: (status) {
            return status! < 500;
          },
        ),
        onReceiveProgress: onReceiveProgress,
      );

      var file = File(path).openSync(mode: FileMode.write);
      file.writeFromSync(response.data);
      await file.close();
    } catch (e) {
      showDialog(
        context: context,
        builder: ((context) {
          return Util.ShowMessagePopup(context, '다운로드 실패 하였습니다\n관리자에게 문의해주세요.');
        }),
      );
    }
  }
}

class DropDownCode {
  const DropDownCode(this.code, this.group, this.name);

  final String code;
  final String name;
  final String group;

  @override
  String toString() {
    return '$code:$group:$name';
  }
}
