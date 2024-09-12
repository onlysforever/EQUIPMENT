import 'dart:convert';

import 'package:data_table_2/data_table_2.dart';
import 'package:dio/dio.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pinch_zoom/pinch_zoom.dart';
import 'package:seoyoneh_equipment/Font/font.dart';
import 'package:seoyoneh_equipment/Model/ReturnObject.dart';
import 'package:seoyoneh_equipment/Util/net.dart';
import 'package:seoyoneh_equipment/Util/util.dart';

class IlluminanceDetailInfo extends StatefulWidget {
  final Map<String, dynamic> selectedLine;
  IlluminanceDetailInfo({required this.selectedLine, super.key});

  @override
  State<IlluminanceDetailInfo> createState() => _IlluminanceDetailInfoState();
}

class _IlluminanceDetailInfoState extends State<IlluminanceDetailInfo> {
  bool isLoading = false;
  bool isSavedDay = false;
  bool isSavedNight = false;

  Map<String, dynamic> dayCheckInfo = {}; // 주간 점검 데이터
  Map<String, dynamic> nightCheckInfo = {}; // 야간 점검 데이터

  DateTime dayDate = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
  DateTime nightDate = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);

  late TextEditingController dayNoteController; // 주간 특이사항 Controller
  late TextEditingController dayWhetherController; // 주간 날씨 Controller
  late TextEditingController dayDateController; // 주간 점검일자 Controller
  late TextEditingController dayMgrController; // 주간 점검자 Controller
  late TextEditingController nightNoteController; // 야간 특이사항 Controller
  late TextEditingController nightWhetherController; // 야간 날씨 Controller
  late TextEditingController nightDateController; // 야간 점검일자 Controller
  late TextEditingController nightMgrController; // 야간 점검자 Controller
  late ScrollController mainController; // 점검시트 화면 스크롤 Controller

  List<DropDownCode> charCodes = <DropDownCode>[]; // 특이사항 란 입력 특수문자 combobox
  List<dynamic> qcTypeList = ['33DY', '33NG']; // 33DY = 주간, 33NG = 야간
  List<dynamic> qcTypeName = ['주간', '야간'];
  List<dynamic> lineInfo = [];
  List<dynamic> dayResult = [];
  List<dynamic> nightResult = [];
  List<DropDownCode> whetherCodes = Util.whetherCodes;
  DropDownCode selectedDayWhetherCode = Util.whetherCodes.first;
  DropDownCode selectedNightWhetherCode = Util.whetherCodes.first;
  List<DropDownCode> empCodes = <DropDownCode>[];
  late DropDownCode selectedDayEmpCode;
  late DropDownCode selectedNightEmpCode;

  String FILEID = '';
  String FILENM = '';

  bool didDownloadPDF = false; // PDF 파일 다운로드 성공 여부

  double progress = 0;
  

  DropDownCode selectedCharCode = DropDownCode('', '', '');

  late var equipBlobImg;
  String checkDate = DateFormat('yyyy-MM').format(DateTime.now());

  @override
  void initState() {
    dayNoteController = TextEditingController();
    dayWhetherController = TextEditingController();
    dayDateController = TextEditingController();
    dayMgrController = TextEditingController();
    nightNoteController = TextEditingController();
    nightWhetherController = TextEditingController();
    nightDateController = TextEditingController();
    nightMgrController = TextEditingController();
    mainController = ScrollController();
    dayDateController.text = '${dayDate.year}-${dayDate.month < 10 ? '0${dayDate.month}' : dayDate.month}-${dayDate.day < 10 ? '0${dayDate.day}' : dayDate.day}';
    nightDateController.text = '${nightDate.year}-${nightDate.month < 10 ? '0${nightDate.month}' : nightDate.month}-${nightDate.day < 10 ? '0${nightDate.day}' : nightDate.day}';
    loadCharCodes();
    loadDetailInfo();
    loadEmpCodes();
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
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

  // 특이사항 란 입력 특수문자 combobox 조회
  Future<void> loadCharCodes() async {
    charCodes = [
      DropDownCode('DEFAULT', '', ''),
      DropDownCode('1', '', 'Ø'),
      DropDownCode('2', '', '℃'),
      DropDownCode('3', '', 'ℓ'),
      DropDownCode('4', '', '㎟'),
      DropDownCode('5', '', 'V'),
      DropDownCode('6', '', 'A'),
      DropDownCode('7', '', '㎾'),
    ];
    setState(() {
      selectedCharCode = charCodes.first;
    });
  }

  Future<void> loadDetailInfo() async {
    showLoadingBar(true);
    //설비 상세 정보 조회
    var response = await Net.post('/tm/service', {
      'SPNAME': 'APG_MOBILE_BM20020.INQUERY_DETAIL',
      'IN_CORCD': widget.selectedLine['CORCD'],
      'IN_BIZCD': widget.selectedLine['BIZCD'],
      'IN_LINECD': widget.selectedLine['LINECD']
    });
    ReturnObject resultItem = ReturnObject.fromJsonMap(jsonDecode(response.body));
    if (resultItem.result == 'SUCCESS' && resultItem.data != null && resultItem.data.length > 0) {
      lineInfo = resultItem.data;
      dayResult = resultItem.data;
      nightResult = resultItem.data;
      print(lineInfo);
      loadIlluminanceCheckList();
    } else {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return Util.ShowMessagePopup(context, '등록된 공정이 없습니다.\n공정 등록후 사용해 주세요.');
        },
      );
    }
    //조도체크 기준 PDF 파일 정보 조회
    response = await Net.post('/tm/service', {
      'SPNAME': 'APG_MOBILE_BM20020.INQUERY_FILEINFO'
    });
    resultItem = ReturnObject.fromJsonMap(jsonDecode(response.body));
    FILEID = resultItem.data[0]['FILEID'];
    FILENM = resultItem.data[0]['FILENM'];

    // if(equipmentInfo['MOTOR_CNT'] == null) {
    //   showDialog(
    //     context: context,
    //     barrierDismissible: false,
    //     builder: (BuildContext context) {
    //       return Util.ShowMessagePopup(context, '등록된 모터가 없습니다.\n모터 등록후 사용해 주세요.');
    //     },
    //   );
    // }
    showLoadingBar(false);
    
  }

  Future<void> loadEmpCodes() async {
    showLoadingBar(true);
    //설비 상세 정보 조회
    var response = await Net.post('/tm/service', {
      'SPNAME': 'APG_MOBILE_SUPPORT.INQUERY_ILMN_EMP_LIST'
    });
    ReturnObject resultItem = ReturnObject.fromJsonMap(jsonDecode(response.body));
    if (resultItem.result == 'SUCCESS' && resultItem.data != null && resultItem.data.length > 0) {
      empCodes.add(DropDownCode('', '', ''));
      selectedDayEmpCode = empCodes.first;
      selectedNightEmpCode = empCodes.first;
      for (int index = 0; index < resultItem.data.length; index++) {
        empCodes.add(DropDownCode(resultItem.data[index]['EMPNO'], resultItem.data[index]['BIZCD'], resultItem.data[index]['EMPNM']));
      }
    } else {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return Util.ShowMessagePopup(context, '등록된 작업자가 없습니다.\n작업자 등록후 사용해 주세요.');
        },
      );
    }
    
    showLoadingBar(false);
    
  }

  // 조도체크 점검리스트 조회
  void loadIlluminanceCheckList() async {
    showLoadingBar(true);
    var response = await Net.post('/tm/service', {
      'SPNAME': 'APG_MOBILE_TM21070.INQUERY_ILLUMINANCE', 
      'IN_CORCD': Util.USER_INFO['CORCD'],
      'IN_BIZCD': Util.USER_INFO['BIZCD'],
      'IN_LINECD': widget.selectedLine['LINECD'], 
      'IN_CHECK_DATE': checkDate,
      'IN_LANG_SET': Util.USER_INFO['IN_LANG_SET']
    });
    ReturnObject resultItem = ReturnObject.fromJsonMap(jsonDecode(response.body));
    if (resultItem.result == 'SUCCESS' && resultItem.data != null && resultItem.data.length > 0) {
      //이미 저장된 점검결과 인 경우
      for(int i = 0; i < qcTypeList.length; i++) {
        int index = 0;
        for (int j = 0; j < resultItem.data.length; j++) {
          if (qcTypeList[i] == resultItem.data[j]['QCTY']) {
            if(qcTypeList[i] == '33DY') {
              dayResult[index][qcTypeList[i]] = TextEditingController();
              dayResult[index][qcTypeList[i]].text = resultItem.data[j]['ILMN_VAL'] ?? '';
            } else {
              nightResult[index][qcTypeList[i]] = TextEditingController();
              nightResult[index][qcTypeList[i]].text = resultItem.data[j]['ILMN_VAL'] ?? '';
            }
            // lineInfo[j][qcTypeList[i]] = TextEditingController();
            // lineInfo[j][qcTypeList[i]].text = resultItem.data[j]['ILMN_VAL'];
            if(resultItem.data[j]['QCTY'] == '33DY' && !isSavedDay) {
              isSavedDay = true;
              dayNoteController.text = resultItem.data[j]['REMARK'] ?? '';
              dayWhetherController.text = resultItem.data[j]['WHETHER'] ?? '';
              dayDateController.text = resultItem.data[j]['REG_DATE'];
              dayMgrController.text = resultItem.data[j]['CHK_MANAGER'] ?? '';
              selectedDayEmpCode = Util.GetCodeItem(empCodes, resultItem.data[j]['CHK_MANAGER']);
              selectedDayWhetherCode = Util.GetCodeItem(whetherCodes, resultItem.data[j]['WHETHER']);
            }
            if(resultItem.data[j]['QCTY'] == '33NG' && !isSavedNight) {
              isSavedNight = true;
              nightNoteController.text = resultItem.data[j]['REMARK'] ?? '';
              nightWhetherController.text = resultItem.data[j]['WHETHER'] ?? '';
              nightDateController.text = resultItem.data[j]['REG_DATE'];
              nightMgrController.text = resultItem.data[j]['CHK_MANAGER'] ?? '';
              selectedNightEmpCode = Util.GetCodeItem(empCodes, resultItem.data[j]['CHK_MANAGER']);
              selectedNightWhetherCode = Util.GetCodeItem(whetherCodes, resultItem.data[j]['WHETHER']);
            }
            index++;
          }
        }
      }
    }
    showLoadingBar(false);
  }

  Widget dayWhetherCodeWidget(qcty) {
    return InputDecorator(
      decoration: InputDecoration(
        fillColor: Color.fromRGBO(190, 190, 190, 0.5),
        filled: qcty == '33DY' ? isSavedDay : isSavedNight,
        border: OutlineInputBorder(), 
        contentPadding: EdgeInsets.only(right: 10.0)),
      child: DropdownButton2<DropDownCode>(
        underline: const SizedBox.shrink(),
        isExpanded: true,
        icon: Icon(
          Icons.arrow_drop_down,
          color: Color.fromRGBO(0, 80, 155, 1),
          size: 30,
        ),
        items: whetherCodes.map((DropDownCode code) {
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
            selectedDayWhetherCode = value!;
          });
        },
        value: selectedDayWhetherCode,
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

  Widget nightWhetherCodeWidget(qcty) {
    return InputDecorator(
      decoration: InputDecoration(
        fillColor: Color.fromRGBO(190, 190, 190, 0.5),
        filled: qcty == '33DY' ? isSavedDay : isSavedNight,
        border: OutlineInputBorder(), 
        contentPadding: EdgeInsets.only(right: 10.0)),
      child: DropdownButton2<DropDownCode>(
        underline: const SizedBox.shrink(),
        isExpanded: true,
        icon: Icon(
          Icons.arrow_drop_down,
          color: Color.fromRGBO(0, 80, 155, 1),
          size: 30,
        ),
        items: whetherCodes.map((DropDownCode code) {
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
            selectedNightWhetherCode = value!;
          });
        },
        value: selectedNightWhetherCode,
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

  Widget dayEmpCodeWidget(qcty) {
    return InputDecorator(
      decoration: InputDecoration(
        fillColor: Color.fromRGBO(190, 190, 190, 0.5),
        filled: qcty == '33DY' ? isSavedDay : isSavedNight,
        border: OutlineInputBorder(), 
        contentPadding: EdgeInsets.only(right: 10.0)),
      child: DropdownButton2<DropDownCode>(
        underline: const SizedBox.shrink(),
        isExpanded: true,
        icon: Icon(
          Icons.arrow_drop_down,
          color: Color.fromRGBO(0, 80, 155, 1),
          size: 30,
        ),
        items: empCodes.map((DropDownCode code) {
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
            selectedDayEmpCode = value!;
          });
        },
        value: selectedDayEmpCode,
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

  Widget nightEmpCodeWidget(qcty) {
    return InputDecorator(
      decoration: InputDecoration(
        fillColor: Color.fromRGBO(190, 190, 190, 0.5),
        filled: qcty == '33DY' ? isSavedDay : isSavedNight,
        border: OutlineInputBorder(), 
        contentPadding: EdgeInsets.only(right: 10.0)),
      child: DropdownButton2<DropDownCode>(
        underline: const SizedBox.shrink(),
        isExpanded: true,
        icon: Icon(
          Icons.arrow_drop_down,
          color: Color.fromRGBO(0, 80, 155, 1),
          size: 30,
        ),
        items: empCodes.map((DropDownCode code) {
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
            selectedNightEmpCode = value!;
          });
        },
        value: selectedNightEmpCode,
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

  // 특이사항 란 입력 특수문자 combobox 위젯
  Widget charCodeWidget(controller) {
    return InputDecorator(
      decoration: const InputDecoration(
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.only(right: 10.0)),
      child: DropdownButton2(
        underline: const SizedBox.shrink(),
        isExpanded: true,
        icon: Icon(Icons.arrow_drop_down, color: Color.fromRGBO(0, 80, 155, 1), size: 30,),
        items: charCodes.map((DropDownCode code) {
          return DropdownMenuItem(
            value: code,
            child: Text(
              code.name,
              style: const TextStyle(color: Colors.black, fontSize: 18.0, fontFamily: MyFontStyle.nanumGothic),
            ),
          );
        }).toList(),
        onChanged: (value) async {
          setState(() {
            controller.text = controller.text + value!.name;
          });
          print(value);
        },
        barrierColor: Colors.transparent,
        focusColor: Colors.transparent,
        selectedItemHighlightColor: Colors.transparent,
        value: selectedCharCode,
        dropdownMaxHeight: 250,
        dropdownDecoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
        ),
        style: const TextStyle(fontSize: 17.0),
      ),
    );
  }

  // text input form 위젯
  Widget inputFormField(String text, TextEditingController controller, String qcty) {
    return TextFormField(
        controller: controller,
        keyboardType: TextInputType.text,
        style: TextStyle(
          fontFamily: MyFontStyle.nanumGothic,
          fontSize: 18,
        ),
        textAlignVertical: TextAlignVertical.center,
        textAlign: TextAlign.center,
        cursorColor: Color.fromRGBO(110, 110, 110, 1.0),
        decoration: InputDecoration(
          fillColor: Color.fromRGBO(190, 190, 190, 0.5),
          filled: qcty == '33DY' ? isSavedDay : isSavedNight,
          hintText: text,
          hintStyle: const TextStyle(
              color: Color.fromRGBO(190, 190, 190, 1),
              fontFamily: MyFontStyle.nanumGothic,
              fontSize: 15,
              overflow: TextOverflow.ellipsis),
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

  // 특이사항 란 입력 text form 위젯
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

  Widget verticalDivider = const VerticalDivider(
    color: Color.fromRGBO(190, 190, 190, 1.0),
    thickness: 0.5,
  );

  void showLoadingBar(bool flag) {
    setState(() {
      isLoading = flag;
    });
  }

  // 조도체크 점검 시트 화면
  Widget showIlluminanceCheckList(int qcIndex, List<dynamic> result) {
    String qcty = qcTypeList[qcIndex];
    return Column(
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: <Widget>[
            Container(
              margin: EdgeInsets.only(left: 10, top: 10, right: 5, bottom: 5),
              child: Text('날씨', style: TextStyle(fontSize: 18, fontFamily: MyFontStyle.nanumGothicBold, color: Color.fromRGBO(110, 110, 110, 1)),),
            ),
            Container(
              width: 100,
              height: 40,
              margin: EdgeInsets.only(left: 5, top: 5, bottom: 5),
              child: qcty == '33DY' ? dayWhetherCodeWidget(qcty) : nightWhetherCodeWidget(qcty)
              // child: inputFormField('날씨', qcty == '33DY' ? dayWhetherController : nightWhetherController, qcty),
            ),
            Container(
              margin: EdgeInsets.only(left: 10, top: 10, right: 5, bottom: 5),
              child: Text('점검일자', style: TextStyle(fontSize: 18, fontFamily: MyFontStyle.nanumGothicBold, color: Color.fromRGBO(110, 110, 110, 1)),),
            ),
            Container(
              width: 140,
              height: 40,
              margin: EdgeInsets.only(left: 5, top: 5, bottom: 5),
              child: OutlinedButton(
                onPressed: () async {
                  final selectedDate = await showDatePicker(
                    context: context,
                    initialDate: qcty == '33DY' ? dayDate : nightDate,
                    firstDate: DateTime(1972),
                    lastDate: DateTime.now(),
                    initialEntryMode: DatePickerEntryMode.calendarOnly,
                    initialDatePickerMode: DatePickerMode.day,
                    cancelText: '취소',
                    confirmText: '선택',
                    builder: (context, child) {
                      return Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: const ColorScheme.light(
                            onPrimary: Colors.white, // selected text color
                            onSurface: Colors.black, // default text color
                            primary: Color.fromRGBO(0, 80, 155, 1), // circle color
                          ),
                          textButtonTheme: TextButtonThemeData(
                            style: TextButton.styleFrom(
                              textStyle: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontFamily: MyFontStyle.nanumGothic
                              ),
                              foregroundColor: Colors.white,
                              backgroundColor: Color.fromRGBO(0, 80, 155, 1),
                              shape: RoundedRectangleBorder(
                                side: const BorderSide(
                                    color: Colors.transparent,
                                    width: 1,
                                    style: BorderStyle.solid),
                                borderRadius: BorderRadius.circular(50)
                              )
                            )
                          )
                        ),
                        child: child!,
                      );
                    },
                  );
                  if(selectedDate != null) {
                    setState(() {
                      if(qcty == '33DY') {
                        dayDate = selectedDate;
                        dayDateController.text = '${dayDate.year}-${dayDate.month < 10 ? '0${dayDate.month}' : dayDate.month}-${dayDate.day < 10 ? '0${dayDate.day}' : dayDate.day}';
                        checkDate = DateFormat('yyyy-MM').format(dayDate);
                      } else {
                        nightDate = selectedDate;
                        nightDateController.text = '${nightDate.year}-${nightDate.month < 10 ? '0${nightDate.month}' : nightDate.month}-${nightDate.day < 10 ? '0${nightDate.day}' : nightDate.day}';
                        checkDate = DateFormat('yyyy-MM').format(nightDate);
                      }
                    });
                  }
                },
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.grey),
                  backgroundColor: qcty == '33DY' 
                    ? isSavedDay 
                      ? Color.fromRGBO(190, 190, 190, 0.5)
                      : Colors.transparent
                    : isSavedNight
                      ? Color.fromRGBO(190, 190, 190, 0.5)
                      : Colors.transparent),
                child: Text(qcty == '33DY' ? dayDateController.text : nightDateController.text, style: TextStyle(fontSize: 18, fontFamily: MyFontStyle.nanumGothic, color: Colors.black)),
              ),
            ),
            Container(
              margin: EdgeInsets.only(left: 10, top: 10, right: 5, bottom: 5),
              child: Text('점검자', style: TextStyle(fontSize: 18, fontFamily: MyFontStyle.nanumGothicBold, color: Color.fromRGBO(110, 110, 110, 1)),),
            ),
            Container(
              width: 120,
              height: 40,
              margin: EdgeInsets.only(left: 5, top: 5, bottom: 5),
              child: qcty == '33DY' ? dayEmpCodeWidget(qcty) : nightEmpCodeWidget(qcty)
            )
          ],
        ),
        Container(
          decoration: BoxDecoration(
            color: Color.fromRGBO(0, 80, 155, 1),
            border: Border.symmetric(horizontal: BorderSide(width: 0.5, color: Color.fromRGBO(190, 190, 190, 1.0)), vertical: BorderSide.none),
          ),
          height: 40,
          child: Center(
            child: Text(
              qcTypeName[qcIndex],
              style: TextStyle(color: Colors.white, fontFamily: MyFontStyle.nanumGothicBold, fontSize: 16),
            ),
          ),
        ),
        Container(
          height: (result.length * 50.0) + 70.0,
          child: Theme(
            data: Theme.of(context)
                .copyWith(dividerColor: Color.fromRGBO(190, 190, 190, 1.0)),
            child: DataTable2(
              headingRowColor: MaterialStateColor.resolveWith(
                  (states) => Color.fromRGBO(0, 80, 155, 1.0)),
              columns: [
                const DataColumn2(
                    label: Center(
                        child: Text('No.',
                            style: TextStyle(
                                fontSize: 15,
                                color: Colors.white,
                                fontFamily: MyFontStyle.nanumGothicBold))),
                    fixedWidth: 40),
                DataColumn2(label: verticalDivider, fixedWidth: 10),
                const DataColumn2(
                    label: Center(
                        child: Text('라인명',
                            style: TextStyle(
                                fontSize: 15,
                                color: Colors.white,
                                fontFamily: MyFontStyle.nanumGothicBold))),
                    size: ColumnSize.M),
                DataColumn2(label: verticalDivider, fixedWidth: 10),
                const DataColumn2(
                    label: Center(
                        child: Text('공정코드',
                            style: TextStyle(
                                fontSize: 15,
                                color: Colors.white,
                                fontFamily: MyFontStyle.nanumGothicBold))),
                    size: ColumnSize.S),
                DataColumn2(label: verticalDivider, fixedWidth: 10),
                const DataColumn2(
                    label: Center(
                        child: Text('공정명',
                            style: TextStyle(
                                fontSize: 15,
                                color: Colors.white,
                                fontFamily: MyFontStyle.nanumGothicBold))),
                    size: ColumnSize.M),
                DataColumn2(label: verticalDivider, fixedWidth: 10),
                const DataColumn2(
                    label: Center(
                        child: Text('조도(Lx)',
                            style: TextStyle(
                                fontSize: 15,
                                color: Colors.white,
                                fontFamily: MyFontStyle.nanumGothicBold))),
                    fixedWidth: 110),
              ],
              dataRowHeight: 50,
              columnSpacing: 0,
              showBottomBorder: true,
              horizontalMargin: 0,
              rows: List.generate(result.length, (index) {
                if(result[index][qcty] == null) {
                  result[index][qcty] = TextEditingController();
                }
                return DataRow(cells: [
                  DataCell(Align(
                      alignment: Alignment.centerRight,
                      child: Text((index + 1).toString(),
                          style: const TextStyle(
                              fontSize: 15, fontFamily: MyFontStyle.nanumGothic)))),
                  DataCell(verticalDivider),
                  DataCell(Center(
                      child: Text(widget.selectedLine['LINENM'] ?? '',
                          style: TextStyle(
                              fontSize: 15, fontFamily: MyFontStyle.nanumGothic)))),
                  DataCell(verticalDivider),
                  DataCell(Center(
                      child: Text(result[index]['PROCCD'] ?? '',
                          style: TextStyle(
                              fontSize: 15, fontFamily: MyFontStyle.nanumGothic)))),
                  DataCell(verticalDivider),
                  DataCell(Center(
                      child: Text(result[index]['PROCNM'] ?? '',
                          style: TextStyle(
                              fontSize: 15, fontFamily: MyFontStyle.nanumGothic)))),
                  DataCell(verticalDivider),
                  DataCell(Center(
                      child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 5),
                          child: inputFormField('조도 값', result[index][qcty], qcty)))),
                ]);
              }),
            ),
          ),
        ),
        Container(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                margin: EdgeInsets.only(left: 10),
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
                      child: charCodeWidget(qcty == '33DY' ? dayNoteController : nightNoteController),
                    ),
                  ],
                ),
              ),
              Container(margin: EdgeInsets.only(left: 10.0, top: 5.0, right: 10.0), height: 160, child: noteFormField(qcty == '33DY' ? dayNoteController : nightNoteController)),
            ],
          )
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: <Widget>[
            Container(
              width: 100.0,
              margin: EdgeInsets.only(left: 5, right: 10, bottom: 20),
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                    backgroundColor: Color.fromRGBO(0, 80, 155, 1)),
                onPressed: () async {
                  // showDialog(
                  //   context: context,
                  //   barrierDismissible: false,
                  //   builder: (BuildContext context) {
                  //     return Util.ShowConfirmPopup(context, '점검 결과를 저장하시겠습니까?', () async {
                        print(widget.selectedLine);
                        List<dynamic> items = [];
                        for (int index = 0; index < result.length; index++) {
                          items.add({
                            'SPNAME': 'APG_MOBILE_TM21070.SAVE_ILLUMINANCE',
                              'IN_CORCD': widget.selectedLine['CORCD'],
                              'IN_BIZCD': widget.selectedLine['BIZCD'],
                              'IN_LINECD': widget.selectedLine['LINECD'],
                              'IN_PROCCD': result[index]['PROCCD'],
                              'IN_REG_DATE': qcty == '33DY' ? dayDateController.text : nightDateController.text,
                              'IN_CHECK_DATE': checkDate,
                              'IN_QCTY': qcty,
                              'IN_LINENM': widget.selectedLine['LINENM'],
                              'IN_PROCNM': result[index]['PROCNM'],
                              'IN_ILMN_VAL': result[index][qcty].text,
                              'IN_REMARK': qcty == '33DY' ? dayNoteController.text : nightNoteController.text,
                              'IN_REG_EMPNO': Util.USER_INFO['EMPNO'],
                              'IN_PROC_SEQ': (index+1).toString(),
                              'IN_WHETHER': qcty == '33DY' ? selectedDayWhetherCode.code : selectedNightWhetherCode.code,
                              'IN_CHK_MANAGER': qcty =='33DY' ? selectedDayEmpCode.code : selectedNightEmpCode.code
                          });
                        }
                        var response = await Net.post('/tm/service', {'LIST': items});
                        ReturnObject resultItem = ReturnObject.fromJsonMap(jsonDecode(response.body));
                        if (resultItem.result == 'SUCCESS') {
                          setState(() {
                            qcty == '33DY' 
                              ? isSavedDay = true
                              : isSavedNight = true;
                          });
                          // if (isFailed) {
                          //   Navigator.pop(context);
                          //   showDialog(
                          //     context: context,
                          //     barrierDismissible: false,
                          //     builder: (BuildContext context) {
                          //       return Util.ShowConfirmPopup(context, '점검 결과가 저장되었습니다.\n이상 내용에 대한 보전작업을 등록하시겠습니까?', () {
                          //         Navigator.pop(context);
                          //       });
                          //     }
                          //   );
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
                  //     });
                  //   }
                  // );
                },
                child: Text(
                  '저장',
                  style: TextStyle(
                      color: Colors.white,
                      fontFamily: MyFontStyle.nanumGothic,
                      fontSize: 16),
                ),
              ),
            )
          ],
        )
      ],
    );
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
                              margin: EdgeInsets.only(left: 10.0, right: 10.0, bottom: 10),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Container(
                                    margin: EdgeInsets.only(right: 10),
                                    child: Text('${widget.selectedLine['LINENM']} - ${widget.selectedLine['LINECD']}',
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontFamily: MyFontStyle.nanumGothicBold,
                                        ),
                                        overflow: TextOverflow.ellipsis),
                                  )
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        margin: EdgeInsets.only(left: 5.0, right: 5),
                        child: OutlinedButton(
                            style: OutlinedButton.styleFrom(backgroundColor: Color.fromRGBO(0, 80, 155, 1)),
                            onPressed: () async {
                              // launchUrl(Uri.parse(''));
                              if(FILEID != '' && FILENM != '') {
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
                                    return Util.ShowMessagePopup(context, '조도체크 기준 파일을 찾을 수 없습니다.\n조도체크 기준 파일을 등록후 사용해 주세요.');
                                  },
                                );
                              }
                            },
                            child: Text(
                              '조도체크 기준',
                              style: TextStyle(color: Colors.white, fontFamily: MyFontStyle.nanumGothic, fontSize: 16),
                            )),
                      ),
                    ],
                  ),
                  Expanded(
                    child: lineInfo.isNotEmpty 
                    ? ListView.builder(
                        padding: EdgeInsets.zero,
                        physics: BouncingScrollPhysics(),
                        controller: mainController,
                        itemCount: 2,
                        itemBuilder: (context, index) {
                          return showIlluminanceCheckList(index, index == 0 ? dayResult : nightResult);
                        },
                      )
                      : SizedBox.shrink(),
                  ),
                  // Row(
                  //   mainAxisAlignment: MainAxisAlignment.end,
                  //   children: <Widget>[
                  //     Container(
                  //       width: 100.0,
                  //       margin: EdgeInsets.only(left: 5, right: 10.0),
                  //       padding: EdgeInsets.symmetric(vertical: 5.0),
                  //       child: ElevatedButton(
                  //           style: ElevatedButton.styleFrom(
                  //             backgroundColor: Color.fromRGBO(0, 80, 155, 1),
                  //           ),
                  //           onPressed: () async {
                  //             Navigator.pop(context);
                  //           },
                  //           child: Text(
                  //             '닫기',
                  //             style: TextStyle(
                  //                 color: Colors.white,
                  //                 fontFamily: MyFontStyle.nanumGothic,
                  //                 fontSize: 16),
                  //           )),
                  //     ),
                  //   ],
                  // ),
                ],
              ),
            )
          ),
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
      ]
    );
  }
}