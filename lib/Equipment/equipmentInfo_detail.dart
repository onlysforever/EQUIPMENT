import 'dart:convert';

import 'package:data_table_2/data_table_2.dart';
import 'package:dio/dio.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:dual_screen/dual_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pinch_zoom/pinch_zoom.dart';
import 'package:seoyoneh_equipment/Font/font.dart';
import 'package:seoyoneh_equipment/Model/ReturnObject.dart';
import 'package:seoyoneh_equipment/Util/net.dart';
import 'package:seoyoneh_equipment/Util/util.dart';
import 'package:seoyoneh_equipment/Work/registerWorkInfo.dart';

import '../QRScanner/qrScanner.dart';

// ignore: must_be_immutable
class EquipmentDetailInfo extends StatefulWidget {
  final Map<String, dynamic> equipment;
  final String term;
  EquipmentDetailInfo({required this.equipment, required this.term, super.key});

  @override
  State<EquipmentDetailInfo> createState() => _EquipmentDetailInfoState();
}

class _EquipmentDetailInfoState extends State<EquipmentDetailInfo> {
  late ScrollController scrollController;
  late ScrollController equipInfoScrollController;

  Map<String, dynamic> equipmentInfo = {}; // 설비 상세정보
  Map<String, dynamic> qcitemInfo = {}; // 점검항목
  Map<String, dynamic> remarkInfo = {}; // 특이사항
  Map<String, dynamic> charMap = {};
  Map<String, dynamic> isFailedMap = {};
  Map<String, dynamic> failedListMap = {};

  // List<dynamic> qcTypeList = []; // 구분값 리스트
  List<dynamic> equipmentCheckList = []; // 점검항목 리스트
  List<dynamic> failedList = []; // 점검항목 중 '이상' 체크 된 항목 리스트
  List<CharCode> charCodes = <CharCode>[];

  late DropDownCode selectedTermCode; //DropDownCode(widget.term, '', '매일'); //Util.checkTermCodes.first;

  bool isSavedResult = false; // 점검 항목 데이터 저장 여부
  bool isSavedDay = false; // 주간 구분값 데이터 저장 여부
  bool isSavedNight = false; // 야간 구분값 데이터 저장 여부
  bool isFailed = false; // 점검값 중 '이상' 체크 여부
  // bool isTermChange = false; // 점검 주기 변경flag
  bool isLoading = false;
  bool didDownloadPDF = false; // PDF 파일 다운로드 성공 여부

  DateTime now = DateTime.now();

  String charCode = 'DEFAULT';
  String charName = '';

  double progress = 0;
  

  late var equipBlobImg;

  @override
  void initState() {
    super.initState();
    scrollController = ScrollController();
    equipInfoScrollController = ScrollController();

    selectedTermCode = widget.term == 'D' ? DropDownCode('D', '', '') : Util.checkTermCodes.first;
    loadQctype();
    loadCharCodes();
  }

  @override
  void dispose() {
    scrollController.dispose();
    equipInfoScrollController.dispose();
    super.dispose();
  }

  void showLoadingBar(bool flag) {
    setState(() {
      isLoading = flag;
    });
  }

  void onReceiveProgress(done, total) {
    progress = done / total;
    setState(() {
      if (progress >= 1) {
        didDownloadPDF = true;
      } else {
        print(progress);
      }
    });
  }

  void loadQctype() async {
    showLoadingBar(true);
    //점검 항목 구분값 조회
    var response = await Net.post('/tm/service', {'SPNAME': 'APG_MOBILE_TM21010.INQUERY_QCTY', 'IN_EQUIPCD': widget.equipment['EQUIPCD'], 'IN_QCTERM': selectedTermCode.code});

    ReturnObject resultItem = ReturnObject.fromJsonMap(jsonDecode(response.body));
    var items = [];
    if (resultItem.result == 'SUCCESS' && resultItem.data != null && resultItem.data.length > 0) {
      items = resultItem.data;
    }
    print(items);
    showLoadingBar(false);
    loadCheckList(items);
  }

  Future<void> loadCharCodes() async {
    charMap = {
      'DEFAULT': '',
      '1': 'Ø',
      '2': '℃',
      '3': 'ℓ',
      '4': '㎟',
      '5': 'V',
      '6': 'A',
      '7': '㎾'
    };
    charCodes = [
      CharCode('DEFAULT', ''),
      CharCode('1', 'Ø'),
      CharCode('2', '℃'),
      CharCode('3', 'ℓ'),
      CharCode('4', '㎟'),
      CharCode('5', 'V'),
      CharCode('6', 'A'),
      CharCode('7', '㎾'),
    ];
    setState(() {
      charCode = 'DEFAULT';
      charName = '';
    });
  }

  void loadCheckList(typeList) async {
    showLoadingBar(true);
    //점검 항목 마스터
    var response = await Net.post('/tm/service', {
      'SPNAME': 'APG_MOBILE_TM21070.INQUERY_LIST', 
      'IN_EQUIPCD': widget.equipment['EQUIPCD'], 
      'IN_QCTERM': selectedTermCode.code, 
      'IN_CHECK_DATE': Util.dateFormat(now, 'yyyyMMdd'), 
      'IN_LANG_SET': Util.USER_INFO['IN_LANG_SET']
    });
    ReturnObject resultItem = ReturnObject.fromJsonMap(jsonDecode(response.body));
    if (resultItem.result == 'SUCCESS' && resultItem.data != null && resultItem.data.length > 0) {
      if (typeList.isNotEmpty) {
        for (int i = 0; i < typeList.length; i++) {
          List<dynamic> items = [];
          for (int j = 0; j < resultItem.data.length; j++) {
            if (typeList[i]['QCTY'] == resultItem.data[j]['QCTY']) {
              items.add(resultItem.data[j]);
            }
          }
          qcitemInfo[typeList[i]['QCTY']] = {'QCTYNM': typeList[i]['QCTYNM'], 'QCLIST': items};
        }
      }
      // 점검항목 구분값이 없을 때 'RESULT' key로 점검항목 정렬
      else {
        Map map = {};
        map['QCTYNM'] = 'RESULT';
        map['QCLIST'] = resultItem.data;
        qcitemInfo['RESULT'] = {'QCTYNM': 'RESULT', 'QCLIST': resultItem.data};
      }
      //이미 저장된 점검결과 인 경우
      for(int index = 0; index < resultItem.data.length; index++) {
        print(resultItem.data[index]['RSLTVAL']);
        if(typeList.isEmpty) {
          // 구분값없는 점검항목인 경우
          if (resultItem.data[index]['RSLTVAL'] != null) {
            isSavedResult = true;
            break;
          }
        } else {
          // 구분값이 있는 점검항목인 경우
          if (resultItem.data[index]['RSLTVAL'] != null) {
            if(resultItem.data[index]['QCTY'] == '33DY' && !isSavedDay) {
              isSavedDay = true;
            }
            if(resultItem.data[index]['QCTY'] == '33NG' && !isSavedNight) {
              isSavedNight = true;
            }
            if(isSavedDay && isSavedNight) {
              break;
            }
          }
        }
      }
      
    } else {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return Util.ShowMessagePopup(context, '등록된 점검 항목이 없습니다.\n점검항목 등록후 사용해 주세요.');
        },
      );
    }
    showLoadingBar(false);
    loadEquipDetail();
  }

  void loadEquipDetail() async {
    showLoadingBar(true);
    //설비 상세 정보 조회
    var response = await Net.post('/tm/service', {
      'SPNAME': 'APG_MOBILE_TM21010.INQUERY_HEADER',
      'IN_EQUIPCD': widget.equipment['EQUIPCD'],
    });
    ReturnObject resultItem = ReturnObject.fromJsonMap(jsonDecode(response.body));

    if (resultItem.result == 'SUCCESS' && resultItem.data != null && resultItem.data.length > 0) {
      //설비 BLOB 이미지 바인딩
      if (resultItem.data[0]['EQUIP_PHOTO'] != null) {
        List<int> intList = resultItem.data[0]['EQUIP_PHOTO'].cast<int>().toList();
        equipBlobImg = Uint8List.fromList(intList);
      }
      equipmentInfo = resultItem.data[0];
    }
    showLoadingBar(false);
  }

  Widget verticalDivider = const VerticalDivider(
    color: Color.fromRGBO(190, 190, 190, 1.0),
    thickness: 0.5,
  );

  Widget textFormField(String text) {
    return TextFormField(
        style: const TextStyle(fontFamily: MyFontStyle.nanumGothic, fontSize: 17),
        textAlignVertical: TextAlignVertical.center,
        readOnly: true,
        decoration: InputDecoration(
          hintText: text,
          hintStyle: const TextStyle(color: Colors.black, fontFamily: MyFontStyle.nanumGothic, fontSize: 18, overflow: TextOverflow.ellipsis),
          contentPadding: const EdgeInsets.all(10),
          focusedBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.horizontal(
                left: Radius.circular(5),
                right: Radius.circular(5),
              ),
              borderSide: BorderSide(color: Colors.grey)),
          enabledBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.horizontal(
                left: Radius.circular(5),
                right: Radius.circular(5),
              ),
              borderSide: BorderSide(color: Colors.grey)),
        ));
  }

  Widget inputFormField(TextEditingController controller) {
    return TextFormField(
      maxLines: 7,
      controller: controller,
      style: TextStyle(fontFamily: MyFontStyle.nanumGothic, fontSize: 15, color: Colors.black, overflow: TextOverflow.ellipsis),
      textAlignVertical: TextAlignVertical.center,
      textAlign: TextAlign.left,
      cursorColor: Colors.black,
      decoration: InputDecoration(
        fillColor: Colors.white,
        hintText: '특이사항을 입력해주세요.',
        hintStyle: const TextStyle(color: Color.fromRGBO(190, 190, 190, 1), fontFamily: MyFontStyle.nanumGothic, fontSize: 15, overflow: TextOverflow.ellipsis),
        contentPadding: const EdgeInsets.all(10),
        focusedBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.horizontal(
              left: Radius.circular(5),
              right: Radius.circular(5),
            ),
            borderSide: BorderSide(color: Colors.grey)),
        enabledBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.horizontal(
              left: Radius.circular(5),
              right: Radius.circular(5),
            ),
            borderSide: BorderSide(color: Colors.grey)),
      ),
    );
  }

  // 점검주기 콤보박스
  Widget termCodeWidget() {
    return InputDecorator(
      decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(width: 1, color: Colors.black)), contentPadding: EdgeInsets.only(right: 10.0)),
      child: DropdownButton2(
        underline: const SizedBox.shrink(),
        isExpanded: true,
        icon: Icon(
          Icons.arrow_drop_down,
          color: Color.fromRGBO(0, 80, 155, 1),
          size: 30,
        ),
        items: Util.checkTermCodes.map((DropDownCode code) {
          return DropdownMenuItem<DropDownCode>(
            value: code,
            child: Text(
              code.name,
              style: const TextStyle(color: Colors.black, fontSize: 18.0, fontFamily: MyFontStyle.nanumGothic),
            ),
          );
        }).toList(),
        onChanged: (value) async {
          if (selectedTermCode != value) {
            selectedTermCode = value!;
            setState(() {
              isSavedDay = false;
              isSavedNight = false;
              isSavedResult = false;
              isFailed = false;
              isFailedMap.clear();
              failedList.clear();
              qcitemInfo.clear();
            });
            loadQctype();
          }
        },
        barrierColor: Colors.transparent,
        focusColor: Colors.transparent,
        selectedItemHighlightColor: Colors.transparent,
        value: selectedTermCode,
        dropdownMaxHeight: 250,
        dropdownDecoration: BoxDecoration(
          borderRadius: BorderRadius.circular(5),
        ),
        style: const TextStyle(fontSize: 18.0),
        hint: const Text(
          '',
          style: TextStyle(fontFamily: MyFontStyle.nanumGothic),
        ),
      ),
    );
  }

  Widget charCodeWidget() {
    return InputDecorator(
      decoration: const InputDecoration(
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.only(right: 10.0)),
      child: DropdownButton2(
        underline: const SizedBox.shrink(),
        isExpanded: true,
        icon: Icon(Icons.arrow_drop_down, color: Color.fromRGBO(0, 80, 155, 1), size: 30,),
        items: charCodes.map((charCode) {
          return DropdownMenuItem(
            value: charCode.code,
            child: Text(
              charCode.name,
              style: const TextStyle(color: Colors.black, fontSize: 18.0, fontFamily: MyFontStyle.nanumGothic),
            ),
          );
        }).toList(),
        onChanged: (value) async {
          // setState(() {
          //   noteController.text = issueController.text + charMap[value];
          // });
          // print(value);
          // print(issueController.text);
          // print(charMap[value]);
        },
        barrierColor: Colors.transparent,
        focusColor: Colors.transparent,
        selectedItemHighlightColor: Colors.transparent,
        value: charCode,
        dropdownMaxHeight: 250,
        dropdownDecoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
        ),
        style: const TextStyle(fontSize: 17.0),
      ),
    );
  }

  Widget showEquipCheckList(int index) {
    String qcty = qcitemInfo.keys.elementAt(index);
    print('@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@' + qcty + '@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@');
    if (qcitemInfo[qcty] == null) {
      return SizedBox.shrink();
    } else {
      if (qcitemInfo[qcty]['REMARK'] == null) {
        print(index);
        print(qcty);
        print(qcitemInfo[qcty]['QCLIST']);
        qcitemInfo[qcty]['REMARK'] = TextEditingController();
        if(qcitemInfo[qcty]['QCLIST'].isNotEmpty) {
          qcitemInfo[qcty]['REMARK'].text = qcitemInfo[qcty]['QCLIST'][0]['REMARK'] == null ? '' : qcitemInfo[qcty]['QCLIST'][0]['REMARK'];
        }
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // qcitemInfo.keys.length > 1
          //     ? Container(
          //         decoration: BoxDecoration(
          //           color: Color.fromRGBO(0, 80, 155, 1),
          //           border: Border.symmetric(horizontal: BorderSide(width: 0.5, color: Color.fromRGBO(190, 190, 190, 1.0)), vertical: BorderSide.none),
          //         ),
          //         height: 40,
          //         child: Center(
          //           child: Text(
          //             qcitemInfo[qcty]['QCTYNM'],
          //             style: TextStyle(color: Colors.white, fontFamily: MyFontStyle.nanumGothicBold, fontSize: 16),
          //           ),
          //         ),
          //       )
          //     : SizedBox.shrink(),
          Container(
            decoration: BoxDecoration(
              color: Color.fromRGBO(0, 80, 155, 1),
              border: Border.symmetric(horizontal: BorderSide(width: 0.5, color: Color.fromRGBO(190, 190, 190, 1.0)), vertical: BorderSide.none),
            ),
            height: 40,
            child: Center(
              child: Text(
                qcitemInfo[qcty]['QCTYNM'],
                style: TextStyle(color: Colors.white, fontFamily: MyFontStyle.nanumGothicBold, fontSize: 16),
              ),
            ),
          ),
          SizedBox(
              height: (qcitemInfo[qcty]['QCLIST'].length * 50.0) + 70.0,
              child: Theme(
                data: Theme.of(context).copyWith(dividerColor: Color.fromRGBO(190, 190, 190, 1.0)),
                child: DataTable2(
                  headingRowColor: MaterialStateColor.resolveWith((states) => Color.fromRGBO(0, 80, 155, 1.0)),
                  columns: [
                    const DataColumn2(label: Center(child: Text('No.', style: TextStyle(fontSize: 15, fontFamily: MyFontStyle.nanumGothicBold, color: Colors.white))), fixedWidth: 30),
                    DataColumn2(label: verticalDivider, fixedWidth: 10),
                    const DataColumn2(label: Center(child: Text('점검항목', style: TextStyle(fontSize: 15, fontFamily: MyFontStyle.nanumGothicBold, color: Colors.white)))),
                    DataColumn2(label: verticalDivider, fixedWidth: 10),
                    const DataColumn2(label: Center(child: Text('점검방법', style: TextStyle(fontSize: 15, fontFamily: MyFontStyle.nanumGothicBold, color: Colors.white))), fixedWidth: 60),
                    DataColumn2(label: verticalDivider, fixedWidth: 10),
                    const DataColumn2(label: Center(child: Text('영향', style: TextStyle(fontSize: 15, fontFamily: MyFontStyle.nanumGothicBold, color: Colors.white))), fixedWidth: 90),
                    DataColumn2(label: verticalDivider, fixedWidth: 10),
                    const DataColumn2(label: Center(child: Text('판단기준', style: TextStyle(fontSize: 15, fontFamily: MyFontStyle.nanumGothicBold, color: Colors.white))), fixedWidth: 150),
                    DataColumn2(label: verticalDivider, fixedWidth: 10),
                    const DataColumn2(label: Center(child: Text('주기', style: TextStyle(fontSize: 15, fontFamily: MyFontStyle.nanumGothicBold, color: Colors.white))), fixedWidth: 50),
                    DataColumn2(label: verticalDivider, fixedWidth: 10),
                    const DataColumn2(label: Center(child: Text('점검값', style: TextStyle(fontSize: 15, fontFamily: MyFontStyle.nanumGothicBold, color: Colors.white))), fixedWidth: 150),
                  ],
                  dataRowHeight: 50,
                  columnSpacing: 0,
                  showBottomBorder: true,
                  border: TableBorder(top: qcitemInfo.keys.isEmpty ? BorderSide(color: Colors.black, width: 0.1) : BorderSide.none, bottom: BorderSide(color: Colors.black, width: 0.1)),
                  horizontalMargin: 0,
                  rows: List<DataRow>.generate(qcitemInfo[qcty]['QCLIST'].length, (index) {
                    // NUM_USEYN 값으로 RESULT_WIDGET 분기처리
                    if(qcitemInfo[qcty]['QCLIST'][index]['NUM_USEYN'] == 'Y') {
                      if(qcitemInfo[qcty]['QCLIST'][index]['CONTROLLER'] == null) {
                        qcitemInfo[qcty]['QCLIST'][index]['CONTROLLER'] = TextEditingController();
                        if(qcitemInfo[qcty]['QCLIST'][index]['RSLTVAL'] != null) {
                          qcitemInfo[qcty]['QCLIST'][index]['CONTROLLER'].text = qcitemInfo[qcty]['QCLIST'][index]['RSLTVAL'];
                        }
                      }
                      if (qcitemInfo[qcty]['QCLIST'][index]['RESULT_WIDGET'] == null) {
                        qcitemInfo[qcty]['QCLIST'][index]['RESULT_CODE'] = qcitemInfo[qcty]['QCLIST'][index]['RSLTVAL'] == null ? '' : qcitemInfo[qcty]['QCLIST'][index]['CONTROLLER'].text;
                      }
                      qcitemInfo[qcty]['QCLIST'][index]['RESULT_WIDGET'] = TextFormField(
                          controller: qcitemInfo[qcty]['QCLIST'][index]['CONTROLLER'],
                          decoration: InputDecoration(
                            fillColor: Color.fromRGBO(190, 190, 190, 0.5),
                            filled: qcty == '33DY'
                                ? isSavedDay
                                : qcty == '33NG'
                                    ? isSavedNight
                                    : isSavedResult,
                            contentPadding: const EdgeInsets.all(10),
                            focusedBorder: const OutlineInputBorder(
                                borderRadius: BorderRadius.horizontal(
                                  left: Radius.circular(5),
                                  right: Radius.circular(5),
                                ),
                                borderSide: BorderSide(color: Colors.black54)),
                            enabledBorder: const OutlineInputBorder(
                                borderRadius: BorderRadius.horizontal(
                                  left: Radius.circular(5),
                                  right: Radius.circular(5),
                                ),
                                borderSide: BorderSide(color: Colors.black54))
                          ),
                          style: TextStyle(
                            fontFamily: MyFontStyle.nanumGothic,
                            fontSize: 15,
                          ),
                          textAlignVertical: TextAlignVertical.center,
                          textAlign: TextAlign.center,
                          cursorColor: Color.fromRGBO(110, 110, 110, 1.0),
                          onChanged: (value) {
                            qcitemInfo[qcty]['QCLIST'][index]['RESULT_CODE'] = value;
                            // setState(() {
                                
                            // });
                          },
                        );
                    } else {
                      if (qcitemInfo[qcty]['QCLIST'][index]['RESULT_WIDGET'] == null) {
                        qcitemInfo[qcty]['QCLIST'][index]['RESULT_CODE'] = qcitemInfo[qcty]['QCLIST'][index]['RSLTVAL'] == null ? Util.checkResultCodes.first.code : qcitemInfo[qcty]['QCLIST'][index]['RSLTVAL'];
                      }
                      qcitemInfo[qcty]['QCLIST'][index]['RESULT_WIDGET'] = InputDecorator(
                        decoration: InputDecoration(
                            fillColor: Color.fromRGBO(190, 190, 190, 0.5),
                            filled: qcty == '33DY'
                                ? isSavedDay
                                : qcty == '33NG'
                                    ? isSavedNight
                                    : isSavedResult,
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.only(right: 10.0)),
                        child: DropdownButton2(
                          underline: const SizedBox.shrink(),
                          isExpanded: true,
                          icon: Icon(
                            Icons.arrow_drop_down,
                            color: Color.fromRGBO(0, 80, 155, 1),
                            size: 30,
                          ),
                          items: Util.checkResultCodes.map((DropDownCode code) {
                            return DropdownMenuItem<DropDownCode>(
                              value: code,
                              child: Text(
                                code.name,
                                style: const TextStyle(color: Colors.black, fontSize: 15.0, fontFamily: MyFontStyle.nanumGothic),
                              ),
                            );
                          }).toList(),
                          onChanged: (value) async {
                            if (value!.code == 'FAIL') {
                              isFailedMap[qcty] = true;
                              isFailed = true;
                              if (qcitemInfo[qcty]['QCLIST'][index]['RESULT_CODE'] == Util.checkResultCodes.first.code) {
                                List tempList = failedListMap[qcty] == null ? [] : failedListMap[qcty];
                                tempList.add(qcitemInfo[qcty]['QCLIST'][index]);
                                failedListMap[qcty] = tempList;
                                // failedList.add(qcitemInfo[qcty]['QCLIST'][index]);
                              }
                            } else {
                              if(failedListMap[qcty] != null) {
                                if (failedListMap[qcty].length == 1) {
                                  isFailedMap[qcty] = false;
                                  isFailed = false;
                                }
                                List tempList = failedListMap[qcty];
                                tempList.remove(qcitemInfo[qcty]['QCLIST'][index]);
                                failedListMap[qcty] = tempList;
                              }
                              // failedList.remove(qcitemInfo[qcty]['QCLIST'][index]);
                            }
                            setState(() {
                              qcitemInfo[qcty]['QCLIST'][index]['RESULT_CODE'] = value.code;
                            });
                            print(isFailed);
                            print(failedListMap[qcty].length);
                          },
                          barrierColor: Colors.transparent,
                          focusColor: Colors.transparent,
                          selectedItemHighlightColor: Colors.transparent,
                          value: Util.GetCodeItem(Util.checkResultCodes, qcitemInfo[qcty]['QCLIST'][index]['RESULT_CODE']),
                          dropdownMaxHeight: 250,
                          dropdownDecoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          style: const TextStyle(fontSize: 17.0, color: Colors.black),
                          hint: const Text(
                            '',
                            style: TextStyle(fontFamily: MyFontStyle.nanumGothic),
                          ),
                        ),
                      );
                    }
                    
                    return DataRow(cells: [
                      DataCell(Align(alignment: Alignment.centerRight, child: Text((index + 1).toString(), style: const TextStyle(fontSize: 15, fontFamily: MyFontStyle.nanumGothic)))),
                      DataCell(verticalDivider),
                      DataCell(Text(qcitemInfo[qcty]['QCLIST'][index]['QCITEMNM'] ?? '', style: TextStyle(fontSize: 15, fontFamily: MyFontStyle.nanumGothic))),
                      DataCell(verticalDivider),
                      DataCell(Center(child: Text(qcitemInfo[qcty]['QCLIST'][index]['QCMTHNM'] ?? '', style: TextStyle(fontSize: 15, fontFamily: MyFontStyle.nanumGothic)))),
                      DataCell(verticalDivider),
                      DataCell(Center(child: Text(qcitemInfo[qcty]['QCLIST'][index]['QCEFFECTNM'] ?? '', style: const TextStyle(fontSize: 15, fontFamily: MyFontStyle.nanumGothic)))),
                      DataCell(verticalDivider),
                      DataCell(Center(child: Text((qcitemInfo[qcty]['QCLIST'][index]['VALUE'] != 0 && qcitemInfo[qcty]['QCLIST'][index]['UNIT'] != null) ? ('${qcitemInfo[qcty]['QCLIST'][index]['VALUE']}${qcitemInfo[qcty]['QCLIST'][index]['UNITNM']}') : qcitemInfo[qcty]['QCLIST'][index]['QCJUDGENM'] ?? '', style: const TextStyle(fontSize: 15, fontFamily: MyFontStyle.nanumGothic)))),
                      DataCell(verticalDivider),
                      DataCell(Center(child: Text(qcitemInfo[qcty]['QCLIST'][index]['QCTERM${selectedTermCode.code}NM'] ?? '', style: const TextStyle(fontSize: 15, fontFamily: MyFontStyle.nanumGothic)))),
                      DataCell(verticalDivider),
                      DataCell(Padding(padding: EdgeInsets.only(bottom: 5, top: 5, right: 5), child: qcitemInfo[qcty]['QCLIST'][index]['RESULT_WIDGET'])),
                    ]);
                  }),
                ),
              )),
          qcitemInfo['33DY'] != null || qcitemInfo['33NG'] != null
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Expanded(
                        child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Container(
                          margin: EdgeInsets.only(left: 10),
                          child: Row(
                            children: <Widget>[
                              Container(
                                margin: EdgeInsets.only(left: 5, top: 15, right: 5),
                                child: Text('특이사항', style: TextStyle(fontSize: 18, fontFamily: MyFontStyle.nanumGothicBold, color: Color.fromRGBO(110, 110, 110, 1)),),
                              ),
                              Container(
                                width: 80,
                                height: 40,
                                margin: EdgeInsets.only(left: 5, top: 5),
                                child: charCodeWidget(),
                              ),
                            ],
                          ),
                        ),
                        Container(margin: EdgeInsets.only(left: 10.0, top: 5.0, right: 10.0), height: 200, child: inputFormField(qcitemInfo[qcty]['REMARK'])),
                      ],
                    )),
                    // 구분값이 있을 때 구분값별 저장 버튼
                    Container(
                      width: MediaQuery.of(context).size.width * 0.1,
                      margin: EdgeInsets.only(left: 10, right: 10),
                      padding: EdgeInsets.only(bottom: 5, top: 100),
                      child: OutlinedButton(
                          style: OutlinedButton.styleFrom(backgroundColor: Color.fromRGBO(0, 80, 155, 1)),
                          onPressed: () async {
                            if (qcitemInfo.isNotEmpty && qcitemInfo.keys.length > 0) {
                              bool resultFlag = true;
                              for(int index = 0; index < qcitemInfo[qcty]['QCLIST'].length; index++) {
                                if(qcitemInfo[qcty]['QCLIST'][index]['NUM_USEYN'] == 'Y') {
                                  if(qcitemInfo[qcty]['QCLIST'][index]['RESULT_CODE'] == '' || qcitemInfo[qcty]['QCLIST'][index]['RESULT_CODE'] == null) {
                                    resultFlag = false;
                                    break;
                                  }
                                }
                              }
                              if(resultFlag) {
                                // showDialog(
                                //   context: context,
                                //   barrierDismissible: false,
                                //   builder: (BuildContext context) {
                                //     return Util.ShowConfirmPopup(context, '점검 결과를 저장하시겠습니까?', () async {
                                      var response = await Net.post('/tm/service', {
                                        'SPNAME': 'APG_MOBILE_TM21070.SAVE_MASTER',
                                        'IN_EQUIPCD': equipmentInfo['EQUIPCD'] ?? '',
                                        'IN_BIZCD': equipmentInfo['BIZCD'],
                                        'IN_CORCD': equipmentInfo['CORCD'],
                                        'IN_CHECK_DATE': Util.dateFormat(now, 'yyyyMMdd'),
                                        'IN_QCTERM': selectedTermCode.code,
                                        'IN_QCTY': qcty,
                                        'IN_CHECK_WEEK': Util.weekOfMonth(now),
                                        'IN_CHECK_MONTH': Util.month(now),
                                        'IN_CHECK_QUARTER': Util.quarter(now),
                                        'IN_CHECK_HALF': Util.half(now),
                                        'IN_CHECK_YEAR': Util.year(now),
                                        'IN_CHECK_EMPNO': Util.USER_INFO['USERID'],
                                        'IN_REMARK': qcitemInfo[qcty]['REMARK'].text,
                                        'IN_REG_EMPNO': Util.USER_INFO['USERID']
                                      });
                                      ReturnObject resultItem = ReturnObject.fromJsonMap(jsonDecode(response.body));
                                      if (resultItem.result == 'SUCCESS') {
                                        List<dynamic> items = [];
                                        for (int index = 0; index < qcitemInfo[qcty]['QCLIST'].length; index++) {
                                          items.add({
                                            'SPNAME': 'APG_MOBILE_TM21070.SAVE_DETAIL',
                                            'IN_EQUIPCD': equipmentInfo['EQUIPCD'] ?? '',
                                            'IN_QCITEMCD': qcitemInfo[qcty]['QCLIST'][index]['QCITEMCD'],
                                            'IN_CHECK_DATE': Util.dateFormat(now, 'yyyyMMdd'),
                                            'IN_QCTERM': selectedTermCode.code,
                                            'IN_QCTY': qcty,
                                            'IN_RSLTVAL': qcitemInfo[qcty]['QCLIST'][index]['RESULT_CODE'],
                                            'IN_REG_EMPNO': Util.USER_INFO['USERID'],
                                          });
                                        }
                                        response = await Net.post('/tm/service', {'LIST': items});
                                        resultItem = ReturnObject.fromJsonMap(jsonDecode(response.body));
                                        if (resultItem.result == 'SUCCESS') {
                                          setState(() {
                                            qcty == '33DY' 
                                              ? isSavedDay = true 
                                              : isSavedNight = true;
                                          });
                                          if (isFailedMap[qcty] == null ? false : isFailedMap[qcty]) {
                                            Navigator.pop(context);
                                            showDialog(
                                                context: context,
                                                barrierDismissible: false,
                                                builder: (BuildContext context) {
                                                  return Util.ShowConfirmPopup(context, '점검 결과가 저장되었습니다.\n이상 내용에 대한 보전작업을 등록하시겠습니까?', () {
                                                    Navigator.pop(context);
                                                    Map<String, dynamic> args = {
                                                      'EQUIPCD': widget.equipment['EQUIPCD'],
                                                      'EQUIPNM': widget.equipment['EQUIPNM'],
                                                      'BIZNM': widget.equipment['BIZNM'],
                                                      'PLANT_DIV': equipmentInfo['PLANT_DIV'],
                                                      'PLANT_DIV_NM': widget.equipment['PLANT_DIV_NM']
                                                    };
                                                    Util.pushNavigator(context, RegisterWorkInfo(args));
                                                  });
                                                });
                                          } else {
                                            Navigator.pop(context);
                                            Util.showToastMessage(context, '점검 결과가 저장되었습니다.');
                                          }
                                        } else {
                                          //점검결과 저장 실패
                                          Navigator.pop(context);
                                          showDialog(
                                            context: context,
                                            barrierDismissible: false,
                                            builder: (BuildContext context) {
                                              return Util.ShowMessagePopup(context, '점검 결과가 저장실패하였습니다.\n관리자에게 문의하세요.');
                                            },
                                          );
                                        }
                                      } else {
                                        //점검결과 저장 실패
                                        showDialog(
                                          context: context,
                                          barrierDismissible: false,
                                          builder: (BuildContext context) {
                                            return Util.ShowMessagePopup(context, '점검 결과가 저장실패하였습니다.\n관리자에게 문의하세요.');
                                          },
                                        );
                                      }
                                  //   });
                                  // });
                              } else {
                                showDialog(
                                  context: context,
                                  barrierDismissible: false,
                                  builder: (BuildContext context) {
                                    return Util.ShowMessagePopup(context, '입력하지 않은 점검 항목이 있습니다.\n점검 결과를 모두 입력해주세요.');
                                  },
                                );
                              }
                            } else {
                              showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder: (BuildContext context) {
                                  return Util.ShowMessagePopup(context, '등록된 점검 항목이 없습니다.\n점검항목 등록후 사용해 주세요.');
                                },
                              );
                            }
                          },
                          child: Text(
                            '저장',
                            style: TextStyle(color: Colors.white, fontFamily: MyFontStyle.nanumGothic, fontSize: 16),
                          )),
                    ),
                  ],
                )
              : Row(children: <Widget>[
                  Expanded(
                      child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Container(
                        margin: EdgeInsets.only(left: 5),
                        child: Row(
                          children: <Widget>[
                            Container(
                              margin: EdgeInsets.only(left: 5, top: 15, right: 5),
                              child: Text('특이사항', style: TextStyle(fontSize: 18, fontFamily: MyFontStyle.nanumGothicBold, color: Color.fromRGBO(110, 110, 110, 1)),),
                            ),
                            Container(
                              width: 80,
                              height: 40,
                              margin: EdgeInsets.only(left: 5, top: 5),
                              child: charCodeWidget(),
                            ),
                          ],
                        ),
                      ),
                      Container(margin: EdgeInsets.only(left: 10.0, top: 5.0, right: 10.0), height: 180, child: inputFormField(qcitemInfo[qcty]['REMARK'])),
                    ],
                  ))
                ]),
        ],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.transparent,
        statusBarBrightness: Brightness.dark,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );
    return Stack(
      children: <Widget>[
        Scaffold(
          appBar: null,
          body: PinchZoom(
            maxScale: 2,
            resetDuration: Duration(milliseconds: 200),
            zoomEnabled: true,
            child: Column(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.only(top: 20, left: 15.0, right: 15.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      SizedBox(
                        width: 180.0,
                        height: 50.0,
                        child: Image.asset('images/SEOYONEH_CI.png'),
                      ),
                      IconButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        icon: const Icon(
                          Icons.chevron_left_rounded,
                          color: Color.fromRGBO(110, 110, 110, 1.0),
                          size: 35.0,
                        ),
                        style: IconButton.styleFrom(
                          minimumSize: Size.zero,
                          padding: EdgeInsets.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          splashFactory: NoSplash.splashFactory,
                          highlightColor: Colors.transparent,
                        ),
                        hoverColor: Colors.transparent,
                        highlightColor: Colors.transparent,
                        splashColor: Colors.transparent,
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Expanded(
                        child: Row(
                      children: <Widget>[
                        Container(
                          margin: EdgeInsets.only(left: 10.0, right: 10.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Container(
                                child: Text(widget.equipment['PROC_REP_LINE_NM'] ?? '대표라인 없음',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontFamily: MyFontStyle.nanumGothic,
                                    ),
                                    overflow: TextOverflow.ellipsis),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          margin: EdgeInsets.only(left: 10.0, right: 10.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Container(
                                child: Text(widget.equipment['EQUIPNM'] ?? '설비명 없음',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontFamily: MyFontStyle.nanumGothic,
                                    ),
                                    overflow: TextOverflow.ellipsis),
                              ),
                            ],
                          ),
                        ),
                      ],
                    )),
                    Row(
                      children: <Widget>[
                        widget.term == Term.W.name
                            ? Container(
                                margin: EdgeInsets.zero,
                                height: 40,
                                width: MediaQuery.of(context).size.width * 0.14,
                                child: termCodeWidget(),
                              )
                            : SizedBox.shrink(),
                        Container(
                          margin: EdgeInsets.only(left: 5.0),
                          child: OutlinedButton(
                              style: OutlinedButton.styleFrom(backgroundColor: Color.fromRGBO(0, 80, 155, 1)),
                              onPressed: () async {
                                showEquipDetailInfo();
                              },
                              child: Text(
                                '설비정보',
                                style: TextStyle(color: Colors.white, fontFamily: MyFontStyle.nanumGothic, fontSize: 16),
                              )),
                        ),
                        Container(
                          margin: EdgeInsets.only(left: 5.0),
                          child: OutlinedButton(
                              style: OutlinedButton.styleFrom(backgroundColor: Color.fromRGBO(0, 80, 155, 1)),
                              onPressed: () async {
                                // launchUrl(Uri.parse(''));
                                if(equipmentInfo['CHK_SAFETY'] != null && equipmentInfo['CHK_SAFETY_FILENAME'] != null) {
                                  String FILEID = '${equipmentInfo['CHK_SAFETY']}';
                                  String FILENM = '${equipmentInfo['CHK_SAFETY_FILENAME']}';
                                  var tempDir = await getTemporaryDirectory();
                                  Util.DownloadFile(
                                          Dio(),
                                          '${Util.FILE_DOWNLOAD_HOST}$FILEID',
                                          '${tempDir.path}/$FILENM',
                                          context,
                                          onReceiveProgress)
                                      .then((value) {
                                        showLoadingBar(false);
                                    if (didDownloadPDF) {
                                      OpenFilex.open('${tempDir.path}/$FILENM');
                                      // Pspdfkit.present('${tempDir.path}/$FILENM');
                                    } else {
                                      Util.ShowMessagePopup(
                                          context,
                                          '다운로드 실패 하였습니다\n관리자에게 문의해주세요.');
                                    }
                                  });
                                } else {
                                  // 저장된 pdf 파일이 없습니다.
                                  showDialog(
                                    context: context,
                                    barrierDismissible: false,
                                    builder: (BuildContext context) {
                                      return Util.ShowMessagePopup(context, '안전주의사항 파일을 찾을 수 없습니다.\n안전주의사항 파일을 등록후 사용해 주세요.');
                                    },
                                  );
                                }
                              },
                              child: Text(
                                '안전주의사항',
                                style: TextStyle(color: Colors.white, fontFamily: MyFontStyle.nanumGothic, fontSize: 16),
                              )),
                        ),
                        Container(
                          margin: EdgeInsets.only(left: 5.0),
                          child: OutlinedButton(
                              style: OutlinedButton.styleFrom(backgroundColor: Color.fromRGBO(0, 80, 155, 1)),
                              onPressed: () async {
                                // launchUrl(Uri.parse(''));
                                if(equipmentInfo['CHK_EQUIP_STD'] != null && equipmentInfo['CHK_EQUIP_STD_FILENAME'] != null) {
                                  String fileName = '${equipmentInfo['CHK_EQUIP_STD']}${equipmentInfo['CHK_EQUIP_STD_FILENAME']}';
                                  print(fileName);
                                  String FILEID = '${equipmentInfo['CHK_EQUIP_STD']}';
                                  String FILENM = '${equipmentInfo['CHK_EQUIP_STD_FILENAME']}';
                                  var tempDir = await getTemporaryDirectory();
                                  Util.DownloadFile(
                                          Dio(),
                                          '${Util.FILE_DOWNLOAD_HOST}$FILEID',
                                          '${tempDir.path}/$FILENM',
                                          context,
                                          onReceiveProgress)
                                      .then((value) {
                                        showLoadingBar(false);
                                    if (didDownloadPDF) {
                                      OpenFilex.open('${tempDir.path}/$FILENM');
                                      // Pspdfkit.present('${tempDir.path}/$FILENM');
                                    } else {
                                      Util.ShowMessagePopup(
                                          context,
                                          '다운로드 실패 하였습니다\n관리자에게 문의해주세요.');
                                    }
                                  });
                                } else {
                                  // 저장된 pdf 파일이 없습니다.
                                  showDialog(
                                    context: context,
                                    barrierDismissible: false,
                                    builder: (BuildContext context) {
                                      return Util.ShowMessagePopup(context, '설비기준표 파일을 찾을 수 없습니다.\n설비기준표 파일을 등록후 사용해 주세요.');
                                    },
                                  );
                                }
                              },
                              child: Text(
                                '설비기준표',
                                style: TextStyle(color: Colors.white, fontFamily: MyFontStyle.nanumGothic, fontSize: 16),
                              )),
                        ),
                        Container(
                          margin: EdgeInsets.only(left: 5.0),
                          child: OutlinedButton(
                              style: OutlinedButton.styleFrom(backgroundColor: Color.fromRGBO(0, 80, 155, 1)),
                              onPressed: () async {
                                if (isSavedResult || isSavedDay || isSavedNight) {
                                  Map<String, dynamic> args = {
                                    'EQUIPCD': widget.equipment['EQUIPCD'],
                                    'EQUIPNM': widget.equipment['EQUIPNM'],
                                  };
                                  Util.pushNavigator(context, RegisterWorkInfo(args));
                                } else {
                                  // 저장 하지 않고 보전작업등록 버튼 클릭 시
                                  showDialog(
                                      context: context,
                                      barrierDismissible: false,
                                      builder: (BuildContext context) {
                                        return Util.ShowMessagePopup(context, '점검 결과 저장 후 보전작업 등록하세요.');
                                      });
                                }
                              },
                              child: Text(
                                '보전작업등록',
                                style: TextStyle(color: Colors.white, fontFamily: MyFontStyle.nanumGothic, fontSize: 16),
                              )),
                        ),
                        Container(
                          margin: EdgeInsets.only(left: 5, right: 10),
                          width: 100,
                          child: OutlinedButton(
                              style: OutlinedButton.styleFrom(backgroundColor: Color.fromRGBO(0, 80, 155, 1)),
                              onPressed: () async {
                                // 선택하여 설비점검 가능하게끔 수정 
                                await Util.pushNavigator(
                                    context,
                                    QRScanner(
                                      type: 'equipment',
                                      subType: 'CM',
                                    ));
                              },
                              child: Text(
                                'QR',
                                style: TextStyle(color: Colors.white, fontFamily: MyFontStyle.nanumGothic, fontSize: 16),
                              )),
                        )
                      ],
                    )
                  ],
                ),
                Expanded(
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    physics: BouncingScrollPhysics(),
                    controller: scrollController,
                    itemCount: qcitemInfo.keys.length,
                    itemBuilder: (context, index) {
                      return showEquipCheckList(index);
                    },
                  ),
                ),
                qcitemInfo['33DY'] != null || qcitemInfo['33NG'] != null
                    ? /* Row(
                        mainAxisAlignment: MainAxisAlignment.end, children: <Widget>[
                          Container(
                            width: MediaQuery.of(context).size.width * 0.1,
                            margin: EdgeInsets.only(left: 5, right: 10),
                            padding: EdgeInsets.symmetric(vertical: 5),
                            child: OutlinedButton(
                                style: OutlinedButton.styleFrom(backgroundColor: Color.fromRGBO(0, 80, 155, 1)),
                                onPressed: () async {
                                  Navigator.pop(context);
                                },
                                child: Text(
                                  '닫기',
                                  style: TextStyle(color: Colors.white, fontFamily: MyFontStyle.nanumGothic, fontSize: 16),
                                )),
                          ),
                        ]
                      ) */SizedBox.shrink()
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: <Widget>[
                          Container(
                            width: MediaQuery.of(context).size.width * 0.1,
                            margin: EdgeInsets.only(left: 5, right: 10),
                            padding: EdgeInsets.symmetric(vertical: 5),
                            child: OutlinedButton(
                                style: OutlinedButton.styleFrom(backgroundColor: Color.fromRGBO(0, 80, 155, 1)),
                                onPressed: () async {
                                  Navigator.pop(context);
                                },
                                child: Text(
                                  '취소',
                                  style: TextStyle(color: Colors.white, fontFamily: MyFontStyle.nanumGothic, fontSize: 16),
                                )),
                          ),
                          // 구분값이 없을 때 통합 저장 버튼
                          Container(
                            width: MediaQuery.of(context).size.width * 0.1,
                            margin: EdgeInsets.only(left: 5, right: 10),
                            padding: EdgeInsets.symmetric(vertical: 5),
                            child: OutlinedButton(
                                style: OutlinedButton.styleFrom(backgroundColor: Color.fromRGBO(0, 80, 155, 1)),
                                onPressed: () async {
                                  if (qcitemInfo.isNotEmpty && qcitemInfo.keys.length > 0) {
                                    // showDialog(
                                    //     context: context,
                                    //     barrierDismissible: false,
                                    //     builder: (BuildContext context) {
                                    //       return Util.ShowConfirmPopup(context, '점검 결과를 저장하시겠습니까?', () async {
                                            var response = await Net.post('/tm/service', {
                                              'SPNAME': 'APG_MOBILE_TM21070.SAVE_MASTER',
                                              'IN_EQUIPCD': equipmentInfo['EQUIPCD'] ?? '',
                                              'IN_BIZCD': equipmentInfo['BIZCD'],
                                              'IN_CORCD': equipmentInfo['CORCD'],
                                              'IN_CHECK_DATE': Util.dateFormat(now, 'yyyyMMdd'),
                                              'IN_QCTERM': selectedTermCode.code,
                                              'IN_QCTY': 'COMMON',
                                              'IN_CHECK_WEEK': Util.weekOfMonth(now),
                                              'IN_CHECK_MONTH': Util.month(now),
                                              'IN_CHECK_QUARTER': Util.quarter(now),
                                              'IN_CHECK_HALF': Util.half(now),
                                              'IN_CHECK_YEAR': Util.year(now),
                                              'IN_CHECK_EMPNO': Util.USER_INFO['USERID'],
                                              'IN_REMARK': qcitemInfo['RESULT']['REMARK'].text,
                                              'IN_REG_EMPNO': Util.USER_INFO['USERID']
                                            });
                                            ReturnObject resultItem = ReturnObject.fromJsonMap(jsonDecode(response.body));
                                            if (resultItem.result == 'SUCCESS') {
                                              List<dynamic> items = [];
                                              for (int index = 0; index < qcitemInfo['RESULT']['QCLIST'].length; index++) {
                                                items.add({
                                                  'SPNAME': 'APG_MOBILE_TM21070.SAVE_DETAIL',
                                                  'IN_EQUIPCD': equipmentInfo['EQUIPCD'] ?? '',
                                                  'IN_QCITEMCD': qcitemInfo['RESULT']['QCLIST'][index]['QCITEMCD'],
                                                  'IN_CHECK_DATE': Util.dateFormat(now, 'yyyyMMdd'),
                                                  'IN_QCTERM': selectedTermCode.code,
                                                  'IN_QCTY': 'COMMON',
                                                  'IN_RSLTVAL': qcitemInfo['RESULT']['QCLIST'][index]['RESULT_CODE'],
                                                  'IN_REG_EMPNO': Util.USER_INFO['USERID'],
                                                });
                                              }
                                              response = await Net.post('/tm/service', {'LIST': items});
                                              resultItem = ReturnObject.fromJsonMap(jsonDecode(response.body));
                                              if (resultItem.result == 'SUCCESS') {
                                                setState(() {
                                                  isSavedResult = true;
                                                });
                                                if (isFailed) {
                                                  Navigator.pop(context);
                                                  showDialog(
                                                      context: context,
                                                      barrierDismissible: false,
                                                      builder: (BuildContext context) {
                                                        return Util.ShowConfirmPopup(context, '점검 결과가 저장되었습니다.\n이상 내용에 대한 보전작업을 등록하시겠습니까?', () {
                                                          Navigator.pop(context);
                                                          Map<String, dynamic> args = {
                                                            'EQUIPCD': widget.equipment['EQUIPCD'],
                                                            'EQUIPNM': widget.equipment['EQUIPNM'],
                                                            'BIZNM': widget.equipment['BIZNM'],
                                                            'PLANT_DIV_NM': widget.equipment['PLANT_DIV_NM']
                                                          };
                                                          Util.pushNavigator(context, RegisterWorkInfo(args));
                                                        });
                                                      });
                                                } else {
                                                  Navigator.pop(context);
                                                  Util.showToastMessage(context, '점검 결과가 저장되었습니다.');
                                                }
                                              }
                                            } else {
                                              //점검결과 저장 실패
                                              Navigator.pop(context);
                                              showDialog(
                                                context: context,
                                                barrierDismissible: false,
                                                builder: (BuildContext context) {
                                                  return Util.ShowMessagePopup(context, '점검 결과가 저장실패하였습니다.\n관리자에게 문의하세요.');
                                                },
                                              );
                                            }
                                        //   });
                                        // });
                                  } else {
                                    showDialog(
                                      context: context,
                                      barrierDismissible: false,
                                      builder: (BuildContext context) {
                                        return Util.ShowMessagePopup(context, '등록된 점검 항목이 없습니다.\n점검항목 등록후 사용해 주세요.');
                                      },
                                    );
                                  }
                                },
                                child: Text(
                                  '저장',
                                  style: TextStyle(color: Colors.white, fontFamily: MyFontStyle.nanumGothic, fontSize: 16),
                                )),
                          ),
                        ],
                      )
              ],
            )
          )
        ),
        Visibility(
          visible: isLoading,
          child: Container(
            color: Colors.transparent,
            alignment: Alignment.center,
            child: const Padding(
              padding: EdgeInsets.all(10.0),
              child: CircularProgressIndicator(
                color: Color.fromRGBO(110, 110, 110, 1.0),
                strokeWidth: 5.0,
              ),
            ),
          ),
        )
      ],
    );
  }

  // 설비 상세 정보 화면
  Future<dynamic> showEquipDetailInfo() {
    return showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                SizedBox(
                  width: 200,
                  height: 40,
                  child: Image.asset('images/SEOYONEH_CI.png'),
                ),
                Padding(
                    padding: EdgeInsets.zero,
                    child: IconButton(
                      icon: Icon(Icons.close, color: Colors.black, size: 30),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ))
              ],
            ),
            content: TwoPane(
              paneProportion: 0.6,
              startPane: Container(
                width: MediaQuery.of(context).size.width * 0.4,
                height: MediaQuery.of(context).size.height * 0.5,
                child: SingleChildScrollView(
                  physics: BouncingScrollPhysics(),
                  controller: equipInfoScrollController,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Container(
                            margin: EdgeInsets.only(left: 5, top: 10),
                            child: Text(
                              '설비명',
                              style: TextStyle(fontSize: 18, fontFamily: MyFontStyle.nanumGothic),
                            ),
                          ),
                        ],
                      ),
                      Container(margin: EdgeInsets.only(top: 5, bottom: 10), height: 38, child: textFormField(equipmentInfo['EQUIPNM'] ?? '')),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Container(
                                  margin: EdgeInsets.only(left: 5),
                                  child: Text(
                                    '설비코드',
                                    style: TextStyle(fontSize: 18, fontFamily: MyFontStyle.nanumGothic),
                                  ),
                                ),
                                Container(margin: EdgeInsets.only(top: 5, right: 5, bottom: 10), height: 38, child: textFormField(equipmentInfo['EQUIPCD'] ?? ''))
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Container(
                                  margin: EdgeInsets.only(left: 10),
                                  child: Text(
                                    '사업장',
                                    style: TextStyle(fontSize: 18, fontFamily: MyFontStyle.nanumGothic),
                                  ),
                                ),
                                Container(margin: EdgeInsets.only(top: 5, left: 5, bottom: 10), height: 38, child: textFormField(equipmentInfo['BIZNM'] ?? ''))
                              ],
                            ),
                          )
                        ],
                      ),
                      Container(
                        margin: EdgeInsets.only(left: 5),
                        child: Text(
                          '설비규격',
                          style: TextStyle(fontSize: 18, fontFamily: MyFontStyle.nanumGothic),
                        ),
                      ),
                      Container(margin: EdgeInsets.only(top: 5, bottom: 10), height: 38, child: textFormField(equipmentInfo['STD'] ?? '')),
                      Container(
                        margin: EdgeInsets.only(left: 5),
                        child: Text(
                          '설비용도',
                          style: TextStyle(fontSize: 18, fontFamily: MyFontStyle.nanumGothic),
                        ),
                      ),
                      Container(margin: EdgeInsets.only(top: 5, bottom: 10), height: 38, child: textFormField(equipmentInfo['USE_DIV'] ?? '')),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Container(
                                  margin: EdgeInsets.only(left: 5),
                                  child: Text(
                                    '중량(톤)',
                                    style: TextStyle(fontSize: 18, fontFamily: MyFontStyle.nanumGothic),
                                  ),
                                ),
                                Container(margin: EdgeInsets.only(top: 5, bottom: 10, right: 5), height: 38, child: textFormField(equipmentInfo['WEIGHT'] == null ? '' : Util.doubleNumberFormat(equipmentInfo['WEIGHT'])))
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Container(
                                  margin: EdgeInsets.only(left: 10),
                                  child: Text(
                                    '전력(KW)',
                                    style: TextStyle(fontSize: 18, fontFamily: MyFontStyle.nanumGothic),
                                  ),
                                ),
                                Container(
                                  margin: EdgeInsets.only(top: 5, left: 5, bottom: 10),
                                  height: 38,
                                  child: textFormField(
                                    equipmentInfo['EP_CONS'] == null ? '' : Util.doubleNumberFormat(equipmentInfo['EP_CONS']),
                                  ),
                                ),
                              ],
                            ),
                          )
                        ],
                      ),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Container(
                                  margin: EdgeInsets.only(left: 5),
                                  child: Text(
                                    '설비등급',
                                    style: TextStyle(fontSize: 18, fontFamily: MyFontStyle.nanumGothic),
                                  ),
                                ),
                                Container(margin: EdgeInsets.only(top: 5, bottom: 10, right: 5), height: 38, child: textFormField(equipmentInfo['GRADE'] ?? ''))
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Container(
                                  margin: EdgeInsets.only(left: 10),
                                  child: Text(
                                    '취득금액',
                                    style: TextStyle(fontSize: 18, fontFamily: MyFontStyle.nanumGothic),
                                  ),
                                ),
                                Container(margin: EdgeInsets.only(top: 5, left: 5, bottom: 10), height: 38, child: textFormField(Util.thousandNumberFormat(equipmentInfo['AMT'])))
                              ],
                            ),
                          )
                        ],
                      ),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Container(
                                  margin: EdgeInsets.only(left: 5),
                                  child: Text(
                                    '제작일자',
                                    style: TextStyle(fontSize: 18, fontFamily: MyFontStyle.nanumGothic),
                                  ),
                                ),
                                Container(margin: EdgeInsets.only(top: 5, bottom: 10, right: 5), height: 38, child: textFormField(equipmentInfo['MAKE_DATE'] ?? ''))
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Container(
                                  margin: EdgeInsets.only(left: 10),
                                  child: Text(
                                    '설치일자',
                                    style: TextStyle(fontSize: 18, fontFamily: MyFontStyle.nanumGothic),
                                  ),
                                ),
                                Container(margin: EdgeInsets.only(top: 5, left: 5, bottom: 10), height: 38, child: textFormField(equipmentInfo['INS_DATE'] ?? ''))
                              ],
                            ),
                          )
                        ],
                      ),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Container(
                                  margin: EdgeInsets.only(left: 5),
                                  child: Text(
                                    '제작처',
                                    style: TextStyle(fontSize: 18, fontFamily: MyFontStyle.nanumGothic),
                                  ),
                                ),
                                Container(margin: EdgeInsets.only(top: 5, bottom: 10, right: 5), height: 38, child: textFormField(equipmentInfo['MAKE_VEND'] ?? ''))
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Container(
                                  margin: EdgeInsets.only(left: 10),
                                  child: Text(
                                    '설치회사',
                                    style: TextStyle(fontSize: 18, fontFamily: MyFontStyle.nanumGothic),
                                  ),
                                ),
                                Container(margin: EdgeInsets.only(top: 5, left: 5, bottom: 10), height: 38, child: textFormField(equipmentInfo['INS_VEND'] ?? ''))
                              ],
                            ),
                          )
                        ],
                      ),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Container(
                                  margin: EdgeInsets.only(left: 5),
                                  child: Text(
                                    '도입부서',
                                    style: TextStyle(fontSize: 18, fontFamily: MyFontStyle.nanumGothic),
                                  ),
                                ),
                                Container(margin: EdgeInsets.only(top: 5, bottom: 10, right: 5), height: 38, child: textFormField(equipmentInfo['PURC_DEPT_NM'] ?? ''))
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Container(
                                  margin: EdgeInsets.only(left: 10),
                                  child: Text(
                                    '관리부서',
                                    style: TextStyle(fontSize: 18, fontFamily: MyFontStyle.nanumGothic),
                                  ),
                                ),
                                Container(margin: EdgeInsets.only(top: 5, left: 5, bottom: 10), height: 38, child: textFormField(equipmentInfo['MGRT_DEPT_NM'] ?? ''))
                              ],
                            ),
                          )
                        ],
                      ),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Container(
                                  margin: EdgeInsets.only(left: 5),
                                  child: Text(
                                    '공장구분',
                                    style: TextStyle(fontSize: 18, fontFamily: MyFontStyle.nanumGothic),
                                  ),
                                ),
                                Container(margin: EdgeInsets.only(top: 5, bottom: 10, right: 5), height: 38, child: textFormField(widget.equipment['PLANT_DIV_NM']))
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Container(
                                  margin: EdgeInsets.only(left: 10),
                                  child: Text(
                                    '예열관리',
                                    style: TextStyle(fontSize: 18, fontFamily: MyFontStyle.nanumGothic),
                                  ),
                                ),
                                Container(margin: EdgeInsets.only(top: 5, left: 5, bottom: 10), height: 38, child: textFormField(equipmentInfo['PREHEAT_DIV'] ?? ''))
                              ],
                            ),
                          )
                        ],
                      ),
                      Container(
                        margin: EdgeInsets.only(left: 5),
                        child: Text(
                          '비고',
                          style: TextStyle(fontSize: 18, fontFamily: MyFontStyle.nanumGothic),
                        ),
                      ),
                      Container(margin: EdgeInsets.only(top: 5, bottom: 10), height: 38, child: textFormField('')),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Container(
                                  margin: EdgeInsets.only(left: 5),
                                  child: Text(
                                    '담당자',
                                    style: TextStyle(fontSize: 18, fontFamily: MyFontStyle.nanumGothic),
                                  ),
                                ),
                                Container(margin: EdgeInsets.only(top: 5, bottom: 10, right: 5), height: 38, child: textFormField(equipmentInfo['PURC_EMPNO'] ?? ''))
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Container(
                                  margin: EdgeInsets.only(left: 10),
                                  child: Text(
                                    '관리자',
                                    style: TextStyle(fontSize: 18, fontFamily: MyFontStyle.nanumGothic),
                                  ),
                                ),
                                Container(margin: EdgeInsets.only(top: 5, left: 5, bottom: 10), height: 38, child: textFormField(equipmentInfo['MGRT_EMPNO_NM'] ?? ''))
                              ],
                            ),
                          )
                        ],
                      ),
                      Container(
                        margin: EdgeInsets.only(left: 5),
                        child: Text(
                          '특기사항',
                          style: TextStyle(fontSize: 18, fontFamily: MyFontStyle.nanumGothic),
                        ),
                      ),
                      Container(margin: EdgeInsets.only(top: 5, bottom: 10), height: 38, child: textFormField(equipmentInfo['NOTE'] ?? '')),
                    ],
                  ),
                ),
              ),
              endPane: Container(
                margin: EdgeInsets.only(left: 20, right: 20, bottom: 100),
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(10),
                    child: equipmentInfo['EQUIP_PHOTO'] == null ? Image.asset('images/SEOYONEH_CI.png') : Image.memory(equipBlobImg),
                  ),
                ),
              ),
            ),
            actions: <Widget>[
              Container(
                width: 100,
                padding: EdgeInsets.all(10),
                child: OutlinedButton(
                    style: OutlinedButton.styleFrom(backgroundColor: Color.fromRGBO(0, 80, 155, 1)),
                    onPressed: () async {
                      // launchUrl(Uri.parse(''));
                      Navigator.pop(context);
                    },
                    child: Text(
                      '확인',
                      style: TextStyle(color: Colors.white, fontFamily: MyFontStyle.nanumGothic, fontSize: 16),
                    )),
              )
            ],
          );
        });
  }
}

class CharCode {
  const CharCode(this.code, this.name);

  final String code;
  final String name;

  @override
  String toString() {
    return '$code: $name';
  }
}
