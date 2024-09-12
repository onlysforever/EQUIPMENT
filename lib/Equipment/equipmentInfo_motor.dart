import 'dart:convert';

import 'package:data_table_2/data_table_2.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:dual_screen/dual_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_toastr/flutter_toastr.dart';
import 'package:intl/intl.dart';
import 'package:pinch_zoom/pinch_zoom.dart';
import 'package:seoyoneh_equipment/Font/font.dart';
import 'package:seoyoneh_equipment/Model/ReturnObject.dart';
import 'package:seoyoneh_equipment/QRScanner/qrScanner.dart';
import 'package:seoyoneh_equipment/Util/net.dart';
import 'package:seoyoneh_equipment/Util/util.dart';

class EquipmentMotorInfo extends StatefulWidget {
  final Map<String, dynamic> selectedEquipment;
  EquipmentMotorInfo({required this.selectedEquipment, super.key});

  @override
  State<EquipmentMotorInfo> createState() => _EquipmentMotorInfoState();
}

class _EquipmentMotorInfoState extends State<EquipmentMotorInfo> {
  bool isSavedResult = false; // 점검 결과 저장 이력 체크
  bool isLoading = false; // 로딩 위젯 flag
  bool isFailed = false; // 점검값 중 '이상' 체크 여부

  Map<String, dynamic> equipmentInfo = {};
  Map<String, dynamic> charMap = {};
  

  late TextEditingController hrztController; // 수평값 Controller
  late TextEditingController vrtcController; // 수직값 Controller
  late TextEditingController gradeController; // 평가등급 Controller
  late TextEditingController noteController; // 특이사항 Controller
  late ScrollController equipInfoScrollController; // 설비상세정보 스크롤 Controller
  late ScrollController mainController; // 점검시트 화면 스크롤 Controller
  List<dynamic> motorList = []; // 측정 설비 모터 리스트
  List<dynamic> checkList = []; // 측정 설비 점검 리스트
  List<CharCode> charCodes = <CharCode>[];
  List<DropDownCode> gradeCodes = Util.gradeCodes;
  List<DropDownCode> standardCodes = Util.moterStandardCodes;
  DropDownCode selectedStandardCode = Util.moterStandardCodes.first;
  DropDownCode selectedGradeCode = Util.gradeCodes.first;


  late var equipBlobImg;
  String checkDate = DateFormat('yyyy-MM').format(DateTime.now());
  String charCode = 'DEFAULT';
  String charName = '';

  @override
  void initState() {
    hrztController = TextEditingController();
    vrtcController = TextEditingController();
    gradeController = TextEditingController();
    noteController = TextEditingController();
    equipInfoScrollController = ScrollController();
    mainController = ScrollController();
    loadDetailInfo();
    loadCharCodes();
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void showLoadingBar(bool flag) {
    setState(() {
      isLoading = flag;
    });
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

  Future<void> loadDetailInfo() async {
    showLoadingBar(true);
    //설비 상세 정보 조회
    var response = await Net.post('/tm/service', {
      'SPNAME': 'APG_MOBILE_TM21010.INQUERY_HEADER',
      'IN_EQUIPCD': widget.selectedEquipment['EQUIPCD'],
    });
    ReturnObject resultItem = ReturnObject.fromJsonMap(jsonDecode(response.body));

    if (resultItem.result == 'SUCCESS' && resultItem.data != null && resultItem.data.length > 0) {
      //설비 BLOB 이미지 바인딩
      if (resultItem.data[0]['EQUIP_PHOTO'] != null) {
        List<int> intList = resultItem.data[0]['EQUIP_PHOTO'].cast<int>().toList();
        equipBlobImg = Uint8List.fromList(intList);
      }
      equipmentInfo = resultItem.data[0];
      if (equipmentInfo['MOTOR_CNT'] != null && equipmentInfo['MOTOR_CNT'] > 0) {
        for (int index = 0; index < equipmentInfo['MOTOR_CNT']; index++) {
          motorList.add({
            'EQUIPCD': equipmentInfo['EQUIPCD'],
            'EQUIPNM': equipmentInfo['EQUIPNM'],
            'MOTORNM': '#${index + 1}',
          });
        }
      } else {
        Util.ShowMessagePopup(context, '등록된 모터정보가 없습니다.\n모터 정보 등록후 진행 해 주세요.');
      }
    }
    showLoadingBar(false);
    loadCheckInfo();
  }

  // 설비 점검시트 조회
  Future<void> loadCheckInfo() async {
    showLoadingBar(true);
    var response = await Net.post('/tm/service', {
      'SPNAME': 'APG_MOBILE_TM21070.INQUERY_MOTOR',
      'IN_EQUIPCD': widget.selectedEquipment['EQUIPCD'],
      'IN_CORCD': Util.USER_INFO['CORCD'],
      'IN_BIZCD': Util.USER_INFO['BIZCD'],
      'IN_CHECK_DATE': checkDate,
      'IN_LANG_SET': Util.USER_INFO['IN_LANG_SET'],
    });
    ReturnObject resultItem = ReturnObject.fromJsonMap(jsonDecode(response.body));
    if (resultItem.result == 'SUCCESS' && resultItem.data != null && resultItem.data.length > 0) {
      print(resultItem.data);
      checkList = resultItem.data;
      for(int index = 0; index < motorList.length; index++) {
        motorList[index]['MOTOR_STANDARD'] = checkList[index]['POWER'];
        motorList[index]['VRTC_CONTROLLER'].text = checkList[index]['VRTCL_VALUE'] ?? '';
        motorList[index]['HRZT_CONTROLLER'].text = checkList[index]['HRZNT_VALUE'] ?? '';
        // motorList[index]['GRADE_CONTROLLER'].text = checkList[index]['GRADE'] ?? '';
        motorList[index]['GRADE_CONTROLLER'].text = checkList[index]['GRADE'] ?? '';
      }
      noteController.text = checkList[0]['REMARK'] ?? '';
      setState(() {
        isSavedResult = true;  
      });
    }
    showLoadingBar(false);
  }

  // 평가등급 위젯
  Widget standardCodeWidget(index) {
    return InputDecorator(
      decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.only(right: 10.0)),
      child: DropdownButton2<DropDownCode>(
        underline: const SizedBox.shrink(),
        isExpanded: true,
        icon: Icon(
          Icons.arrow_drop_down,
          color: Color.fromRGBO(0, 80, 155, 1),
          size: 30,
        ),
        items: standardCodes.map((DropDownCode code) {
          return DropdownMenuItem<DropDownCode>(
            value: code,
            child: Text(
              code.name,
              style: const TextStyle(color: Colors.black, fontSize: 15.0, fontFamily: MyFontStyle.nanumGothic),
            ),
          );
        }).toList(),
        onChanged: (value) async {
          setState(() {
            motorList[index]['MOTOR_STANDARD'] = value!.code;
          });
        },
        value: Util.GetCodeItem(Util.moterStandardCodes, motorList[index]['MOTOR_STANDARD']),
        barrierColor: Colors.transparent,
        focusColor: Colors.transparent,
        selectedItemHighlightColor: Colors.transparent,
        dropdownMaxHeight: 250,
        dropdownDecoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
        ),
        style: const TextStyle(fontSize: 17.0),
      ),
    );
  }

  // Widget gradeCodeWidget(index) {
  //   return InputDecorator(
  //     decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.only(right: 10.0)),
  //     child: DropdownButton2<DropDownCode>(
  //       underline: const SizedBox.shrink(),
  //       isExpanded: true,
  //       icon: Icon(
  //         Icons.arrow_drop_down,
  //         color: Color.fromRGBO(0, 80, 155, 1),
  //         size: 30,
  //       ),
  //       items: gradeCodes.map((DropDownCode code) {
  //         return DropdownMenuItem<DropDownCode>(
  //           value: code,
  //           child: Text(
  //             code.name,
  //             style: const TextStyle(color: Colors.black, fontSize: 15.0, fontFamily: MyFontStyle.nanumGothic),
  //           ),
  //         );
  //       }).toList(),
  //       onChanged: (value) async {
  //         setState(() {
  //           motorList[index]['GRADE'] = value!.code;
  //         });
  //       },
  //       value: Util.GetCodeItem(Util.gradeCodes, motorList[index]['GRADE']),
  //       barrierColor: Colors.transparent,
  //       focusColor: Colors.transparent,
  //       selectedItemHighlightColor: Colors.transparent,
  //       dropdownMaxHeight: 250,
  //       dropdownDecoration: BoxDecoration(
  //         borderRadius: BorderRadius.circular(8),
  //       ),
  //       style: const TextStyle(fontSize: 17.0),
  //     ),
  //   );
  // }

  // 특이사항 란 입력 특수문자 combobox
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
          //   issueController.text = issueController.text + charMap[value];
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

  Widget verticalDivider = const VerticalDivider(
    color: Color.fromRGBO(190, 190, 190, 1.0),
    thickness: 0.5,
  );

  // 모터진동측정 점검시트 화면
  Widget showMotorCheckList() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 5.0),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Color.fromRGBO(190, 190, 190, 1.0)),
        child: DataTable2(
          headingRowColor: MaterialStateColor.resolveWith((states) => Color.fromRGBO(0, 80, 155, 1.0)),
          columns: [
            const DataColumn2(label: Center(child: Text('설비명', style: TextStyle(fontSize: 15, color: Colors.white, fontFamily: MyFontStyle.nanumGothicBold))), size: ColumnSize.M),
            DataColumn2(label: verticalDivider, fixedWidth: 10),
            const DataColumn2(label: Center(child: Text('모터명', style: TextStyle(fontSize: 15, color: Colors.white, fontFamily: MyFontStyle.nanumGothicBold))), fixedWidth: 100),
            DataColumn2(label: verticalDivider, fixedWidth: 10),
            const DataColumn2(label: Center(child: Text('규격', style: TextStyle(fontSize: 15, color: Colors.white, fontFamily: MyFontStyle.nanumGothicBold))), fixedWidth: 150),
            DataColumn2(label: verticalDivider, fixedWidth: 10),
            const DataColumn2(label: Center(child: Text('수직값', style: TextStyle(fontSize: 15, color: Colors.white, fontFamily: MyFontStyle.nanumGothicBold))), fixedWidth: 120),
            DataColumn2(label: verticalDivider, fixedWidth: 10),
            const DataColumn2(label: Center(child: Text('수평값', style: TextStyle(fontSize: 15, color: Colors.white, fontFamily: MyFontStyle.nanumGothicBold))), fixedWidth: 120),
            DataColumn2(label: verticalDivider, fixedWidth: 10),
            const DataColumn2(label: Center(child: Text('평가등급', style: TextStyle(fontSize: 15, color: Colors.white, fontFamily: MyFontStyle.nanumGothicBold))), fixedWidth: 120),
          ],
          dataRowHeight: 50,
          columnSpacing: 0,
          showBottomBorder: true,
          horizontalMargin: 0,
          rows: List.generate(motorList.length, (index) {
            if (motorList[index]['HRZT_CONTROLLER'] == null) {
              motorList[index]['HRZT_CONTROLLER'] = TextEditingController();
            }
            if (motorList[index]['VRTC_CONTROLLER'] == null) {
              motorList[index]['VRTC_CONTROLLER'] = TextEditingController();
            }
            if (motorList[index]['STANDARD_WIDGET'] == null) {
              motorList[index]['MOTOR_STANDARD'] = Util.moterStandardCodes.first.code;
            }
            if (motorList[index]['GRADE_CONTROLLER'] == null) {
              motorList[index]['GRADE_CONTROLLER'] = TextEditingController();
            }
            motorList[index]['STANDARD_WIDGET'] = standardCodeWidget(index);
            // motorList[index]['GRADE_WIDGET'] = gradeCodeWidget(index);
            return DataRow(cells: [
              DataCell(Center(child: Text(motorList[index]['EQUIPNM'], style: TextStyle(fontSize: 15, fontFamily: MyFontStyle.nanumGothic)))),
              DataCell(verticalDivider),
              DataCell(Center(child: Text(motorList[index]['MOTORNM'], style: TextStyle(fontSize: 15, fontFamily: MyFontStyle.nanumGothic)))),
              DataCell(verticalDivider),
              DataCell(Center(child: Padding(padding: EdgeInsets.symmetric(vertical: 5), child: motorList[index]['STANDARD_WIDGET']))),
              DataCell(verticalDivider),
              DataCell(Center(child: Padding(padding: EdgeInsets.symmetric(vertical: 5), child: inputFormField('수직값', index, motorList[index]['VRTC_CONTROLLER'])))),
              DataCell(verticalDivider),
              DataCell(Center(child: Padding(padding: EdgeInsets.symmetric(vertical: 5), child: inputFormField('수평값', index, motorList[index]['HRZT_CONTROLLER'])))),
              DataCell(verticalDivider),
              DataCell(Center(child: Padding(padding: EdgeInsets.only(top: 5, bottom: 5, right: 5), child: inputFormField('평가등급', index, motorList[index]['GRADE_CONTROLLER'])))),
            ]);
          }),
        ),
      ),
    );
  }

  // 설비상세정보 text form 위젯(readOnly = true)
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

  // text input form 위젯
  Widget inputFormField(String text, int index, TextEditingController controller) {
    return TextFormField(
        controller: controller,
        keyboardType: TextInputType.number,
        style: TextStyle(
          fontFamily: MyFontStyle.nanumGothic,
          fontSize: 15,
        ),
        textAlignVertical: TextAlignVertical.center,
        textAlign: TextAlign.center,
        readOnly: text == '평가등급' ? true : false,
        cursorColor: Color.fromRGBO(110, 110, 110, 1.0),
        decoration: InputDecoration(
          fillColor: Color.fromRGBO(190, 190, 190, 0.5),
          filled: isSavedResult,
          hintText: text,
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
        onChanged: (value) {
          double resultVal = 0;
          if(motorList[index]['VRTC_CONTROLLER'].text != '' && motorList[index]['HRZT_CONTROLLER'].text != '') {
            print('둘다 입력');
            // 수직, 수평값 모두 입력된 경우
            if(double.parse(motorList[index]['VRTC_CONTROLLER'].text) > double.parse(motorList[index]['HRZT_CONTROLLER'].text)) {
              resultVal = double.parse(motorList[index]['VRTC_CONTROLLER'].text);
            } else {
              resultVal = double.parse(motorList[index]['HRZT_CONTROLLER'].text);
            }
          } else if(motorList[index]['VRTC_CONTROLLER'].text == '' && motorList[index]['HRZT_CONTROLLER'].text != '') {
            print('수평값만 입력');
            // 수평값만 입력된 경우
            resultVal = double.parse(motorList[index]['HRZT_CONTROLLER'].text);
          } else if(motorList[index]['HRZT_CONTROLLER'].text == '' && motorList[index]['VRTC_CONTROLLER'].text != '') {
            print('수직값만 입력');
            // 수직값만 입력된 경우
            resultVal = double.parse(motorList[index]['VRTC_CONTROLLER'].text);
          } else {
            print('둘다 입력 안됨');
            // 둘다 null 인경우
            setState(() {
              //평가등급 '' 처리
              motorList[index]['GRADE_CONTROLLER'].text = '';
            });
          }
          if(resultVal <= 1.12 && resultVal > 0) {
              setState(() {
                // 평가등급 A
                motorList[index]['GRADE_CONTROLLER'].text = 'A';
              });
            } else if(resultVal > 1.12 && resultVal <= 2.8) {
              setState(() {
                // 평가등급 B
                motorList[index]['GRADE_CONTROLLER'].text = 'B';
              });
            } else if(resultVal > 2.8 && resultVal < 11.2) {
              setState(() {
                // 평가등급 C
                motorList[index]['GRADE_CONTROLLER'].text = 'C';
              });
            } else if(resultVal >= 11.2) {
              setState(() {
                // 평가등급 D
                motorList[index]['GRADE_CONTROLLER'].text = 'D';
              });
            } else {
              // 잘못된 입력값
            }
        },
      );
  }

  // 특이사항 input form 위젯
  Widget noteFormField(TextEditingController controller) {
    return TextFormField(
      maxLines: 8,
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
                                Container(margin: EdgeInsets.only(top: 5, bottom: 10, right: 5), height: 38, child: textFormField(widget.selectedEquipment['PLANT_DIV_NM']))
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
          child: SingleChildScrollView(
            controller: mainController,
            child: Container(
              height: MediaQuery.of(context).size.height,
              padding: const EdgeInsets.only(top: 20.0, left: 0.0, right: 0.0, bottom: 0.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.only(left: 15.0, right: 15.0),
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
                                    margin: EdgeInsets.only(right: 10),
                                    child: Text(widget.selectedEquipment['EQUIPNM'] ?? '설비명 없음',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontFamily: MyFontStyle.nanumGothic,
                                        ),
                                        overflow: TextOverflow.ellipsis),
                                  )
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: <Widget>[
                          Container(
                            width: 120.0,
                            margin: EdgeInsets.only(right: 10.0),
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: Color.fromRGBO(0, 80, 155, 1)),
                              onPressed: () async {
                                showEquipDetailInfo();
                              },
                              child: Text(
                                '설비정보',
                                style: TextStyle(color: Colors.white, fontFamily: MyFontStyle.nanumGothic, fontSize: 16),
                              ),
                            ),
                          ),
                          Container(
                            margin: EdgeInsets.only(right: 10.0),
                            child: OutlinedButton(
                                style: OutlinedButton.styleFrom(backgroundColor: Color.fromRGBO(0, 80, 155, 1)),
                                onPressed: () async {
                                  // launchUrl(Uri.parse(''));
                                  // if(equipmentInfo['CHK_SAFETY'] != null && equipmentInfo['CHK_SAFETY_FILENAME'] != null) {
                                  //   String FILEID = '${equipmentInfo['CHK_SAFETY']}';
                                  //   String FILENM = '${equipmentInfo['CHK_SAFETY_FILENAME']}';
                                  //   var tempDir = await getTemporaryDirectory();
                                  //   Util.DownloadFile(
                                  //           Dio(),
                                  //           '${Util.FILE_DOWNLOAD_HOST}$FILEID',
                                  //           '${tempDir.path}/$FILENM',
                                  //           context,
                                  //           onReceiveProgress)
                                  //       .then((value) {
                                  //         showLoadingBar(false);
                                  //     if (didDownloadPDF) {
                                  //       OpenFilex.open('${tempDir.path}/$FILENM');
                                  //       // Pspdfkit.present('${tempDir.path}/$FILENM');
                                  //     } else {
                                  //       Util.ShowMessagePopup(
                                  //           context,
                                  //           '다운로드 실패 하였습니다\n관리자에게 문의해주세요.');
                                  //     }
                                  //   });
                                  // } else {
                                  //   // 저장된 pdf 파일이 없습니다.
                                  //   showDialog(
                                  //     context: context,
                                  //     barrierDismissible: false,
                                  //     builder: (BuildContext context) {
                                  //       return Util.ShowMessagePopup(context, '안전주의사항 파일을 찾을 수 없습니다.\n안전주의사항 파일을 등록후 사용해 주세요.');
                                  //     },
                                  //   );
                                  // }
                                },
                                child: Text(
                                  '설비기준표',
                                  style: TextStyle(color: Colors.white, fontFamily: MyFontStyle.nanumGothic, fontSize: 16),
                                )),
                          ),
                          Container(
                            margin: EdgeInsets.only(right: 10),
                            width: 100,
                            child: OutlinedButton(
                                style: OutlinedButton.styleFrom(backgroundColor: Color.fromRGBO(0, 80, 155, 1)),
                                onPressed: () async {
                                  // 선택하여 설비점검 가능하게끔 수정 
                                  await Util.pushNavigator(
                                      context,
                                      QRScanner(
                                        type: 'equipment',
                                        subType: 'MT',
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
                  SizedBox(
                    height: 70.0 + 50 * (equipmentInfo['MOTOR_CNT'] ?? 0),
                    child: showMotorCheckList(),
                  ),
                  Expanded(
                      child: equipmentInfo['MOTOR_CNT'] == null 
                        ? SizedBox.shrink()
                        : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Container(
                        margin: EdgeInsets.only(left: 5),
                        child: Row(
                          children: <Widget>[
                            Container(
                              margin: EdgeInsets.only(left: 10, top: 15, right: 5),
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
                      Container(margin: EdgeInsets.only(left: 10.0, top: 5.0, right: 10.0), height: 200, child: noteFormField(noteController)),
                    ],
                  )),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: <Widget>[
                      Container(
                        width: 100.0,
                        margin: EdgeInsets.only(left: 5, right: 10.0),
                        padding: EdgeInsets.symmetric(vertical: 5.0),
                        child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color.fromRGBO(0, 80, 155, 1),
                            ),
                            onPressed: () async {
                              Navigator.pop(context);
                            },
                            child: Text(
                              '취소',
                              style: TextStyle(color: Colors.white, fontFamily: MyFontStyle.nanumGothic, fontSize: 16),
                            )),
                      ),
                      Container(
                        width: 100.0,
                        margin: EdgeInsets.only(left: 5, right: 10),
                        padding: EdgeInsets.symmetric(vertical: 5),
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(backgroundColor: Color.fromRGBO(0, 80, 155, 1)),
                          onPressed: () async {
                            bool flag = false;
                            for(int index = 0; index < motorList.length; index++) {
                              if(
                              motorList[index]['VRTC_CONTROLLER'].text == '' ||
                              motorList[index]['HRZT_CONTROLLER'].text == '' ||
                              motorList[index]['GRADE_CONTROLLER'].text == '') {
                                flag = true;
                                break;
                              }
                            }
                            if (!flag) {
                              // showDialog(
                              //   context: context,
                              //   barrierDismissible: false,
                              //   builder: (BuildContext context) {
                              //     return Util.ShowConfirmPopup(context, '점검 결과를 저장하시겠습니까?', () async {
                                    print(Util.USER_INFO);
                                    List<dynamic> items = [];
                                    for (int index = 0; index < motorList.length; index++) {
                                      items.add({
                                        'SPNAME': 'APG_MOBILE_TM21070.SAVE_MOTOR', 
                                        'IN_EQUIPCD': widget.selectedEquipment['EQUIPCD'],
                                        'IN_CHECK_DATE': checkDate, 
                                        'IN_MOTOR_NM': '${index + 1}',
                                        'IN_CORCD': Util.USER_INFO['CORCD'],
                                        'IN_BIZCD': Util.USER_INFO['BIZCD'],
                                        'IN_POWER':  motorList[index]['MOTOR_STANDARD'], 
                                        'IN_VRTCL_VALUE': motorList[index]['VRTC_CONTROLLER'].text, 
                                        'IN_HRZNT_VALUE': motorList[index]['HRZT_CONTROLLER'].text, 
                                        'IN_GRADE': motorList[index]['GRADE_CONTROLLER'].text,
                                        'IN_REMARK': noteController.text, 
                                        'IN_REG_EMPNO': Util.USER_INFO['EMPNO'],
                                        'IN_REG_DATE': DateFormat('yyyy-MM-dd').format(DateTime.now())
                                      });
                                    }
                                    var response = await Net.post('/tm/service', {'LIST': items});
                                    ReturnObject resultItem = ReturnObject.fromJsonMap(jsonDecode(response.body));
                                    if (resultItem.result == 'SUCCESS') {
                                      setState(() {
                                        isSavedResult = true;
                                      });
                                      // if (isFailed) {
                                      //   Navigator.pop(context);
                                      //   showDialog(
                                      //       context: context,
                                      //       barrierDismissible: false,
                                      //       builder: (BuildContext context) {
                                      //         return Util.ShowConfirmPopup(context, '점검 결과가 저장되었습니다.\n이상 내용에 대한 보전작업을 등록하시겠습니까?', () {
                                      //           Navigator.pop(context);
                                      //         });
                                      //       });
                                      // } else {
                                        Navigator.pop(context);
                                        Util.showToastMessage(context, '점검 결과가 저장되었습니다.');
                                      // }
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
                                    return Util.ShowMessagePopup(context, '수직값, 수평값, 평가등급을 모두 입력해주세요.');
                                  });
                            }
                          },
                          child: Text(
                            '저장',
                            style: TextStyle(color: Colors.white, fontFamily: MyFontStyle.nanumGothic, fontSize: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              )
            ),
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
      ),
    ]);
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
