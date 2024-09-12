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

class EquipmentSafetyInfo extends StatefulWidget {
  final Map<String, dynamic> selectedEquipment;
  EquipmentSafetyInfo({required this.selectedEquipment, super.key});

  @override
  State<EquipmentSafetyInfo> createState() => _EquipmentSafetyInfoState();
}

class _EquipmentSafetyInfoState extends State<EquipmentSafetyInfo> {
  bool isSavedResult = false;
  bool isLoading = false;

  Map<String, dynamic> equipmentInfo = {};
  Map<String, dynamic> checkInfo = {};
  Map<String, dynamic> charMap = {};

  late TextEditingController checkController; // 생산확인 Controller
  late TextEditingController noteController; // 특이사항 Controller
  late ScrollController equipInfoScrollController; // 설비상세정보 스크롤 Controller
  late ScrollController mainController; // 설비점검시트 스크롤 Controller

  List<StateCode> stateCodes = <StateCode>[]; // 동작상태 combobox
  List<LocateCode> locateCodes = <LocateCode>[]; // 감지위치 combobox
  List<DirtyCode> dirtyCodes = <DirtyCode>[]; // 이물질(오염) combobox
  List<CharCode> charCodes = <CharCode>[]; // 특이사항 란 입력 특수문자 combobox

  StateCode selectedStateCode = StateCode('', ''); // 선택된 동작상태 code
  LocateCode selectedLocateCode = LocateCode('', ''); // 선택된 감지위치 code
  DirtyCode selectedDirtyCode = DirtyCode('', ''); // 선택된 이물질(오염) code

  late var equipBlobImg;
  String checkDate = DateFormat('yyyy-MM').format(DateTime.now());
  String charCode = 'DEFAULT';
  String charName = '';

  @override
  void initState() {
    checkController = TextEditingController();
    noteController = TextEditingController();
    equipInfoScrollController = ScrollController();
    mainController = ScrollController();
    loadStateCodes();
    loadLocateCodes();
    loadDirtyCodes();
    loadCharCodes();
    loadDetailInfo();

    
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

  Future<void> loadStateCodes() async {
    stateCodes.add(StateCode('SUCCESS', '양호'));
    stateCodes.add(StateCode('FAIL', '불량'));
    selectedStateCode = stateCodes.first;
  }

  Future<void> loadLocateCodes() async {
    locateCodes.add(LocateCode('SUCCESS', '양호'));
    locateCodes.add(LocateCode('FAIL', '불량'));
    selectedLocateCode = locateCodes.first;
  }

  Future<void> loadDirtyCodes() async {
    dirtyCodes.add(DirtyCode('SUCCESS', '양호'));
    dirtyCodes.add(DirtyCode('FAIL', '불량'));
    selectedDirtyCode = dirtyCodes.first;
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

  // 동작상태 combobox 위젯
  Widget stateCodeWidget() {
    return InputDecorator(
      decoration: InputDecoration(
        fillColor: Color.fromRGBO(190, 190, 190, 0.5),
        filled: isSavedResult,
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.only(right: 10.0)),
      child: DropdownButton2<StateCode>(
        underline: const SizedBox.shrink(),
        isExpanded: true,
        icon: Icon(
          Icons.arrow_drop_down,
          color: Color.fromRGBO(0, 80, 155, 1),
          size: 30,
        ),
        items: stateCodes.map((StateCode code) {
          return DropdownMenuItem<StateCode>(
            value: code,
            child: Text(
              code.name,
              style: const TextStyle(
                  color: Colors.black,
                  fontSize: 15.0,
                  fontFamily: MyFontStyle.nanumGothic),
            ),
          );
        }).toList(),
        onChanged: (value) async {
          setState(() {
            selectedStateCode = value!;
          });
        },
        value: selectedStateCode,
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

  // 감지위치 combobox 위젯
  Widget locateCodeWidget() {
    return InputDecorator(
      decoration: InputDecoration(
        fillColor: Color.fromRGBO(190, 190, 190, 0.5),
        filled: isSavedResult,
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.only(right: 10.0)),
      child: DropdownButton2<LocateCode>(
        underline: const SizedBox.shrink(),
        isExpanded: true,
        icon: Icon(
          Icons.arrow_drop_down,
          color: Color.fromRGBO(0, 80, 155, 1),
          size: 30,
        ),
        items: locateCodes.map((LocateCode code) {
          return DropdownMenuItem<LocateCode>(
            value: code,
            child: Text(
              code.name,
              style: const TextStyle(
                  color: Colors.black,
                  fontSize: 15.0,
                  fontFamily: MyFontStyle.nanumGothic),
            ),
          );
        }).toList(),
        onChanged: (value) async {
          setState(() {
            selectedLocateCode = value!;
          });
        },
        value: selectedLocateCode,
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

  // 이물질(오염) combobox 위젯
  Widget dirtyCodeWidget() {
    return InputDecorator(
      decoration: InputDecoration(
        fillColor: Color.fromRGBO(190, 190, 190, 0.5),
        filled: isSavedResult,
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.only(right: 10.0)),
      child: DropdownButton2<DirtyCode>(
        underline: const SizedBox.shrink(),
        isExpanded: true,
        icon: Icon(
          Icons.arrow_drop_down,
          color: Color.fromRGBO(0, 80, 155, 1),
          size: 30,
        ),
        items: dirtyCodes.map((DirtyCode code) {
          return DropdownMenuItem<DirtyCode>(
            value: code,
            child: Text(
              code.name,
              style: const TextStyle(
                  color: Colors.black,
                  fontSize: 15.0,
                  fontFamily: MyFontStyle.nanumGothic),
            ),
          );
        }).toList(),
        onChanged: (value) async {
          setState(() {
            selectedDirtyCode = value!;
          });
        },
        value: selectedDirtyCode,
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
    }
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
    loadCheckInfo();
  }

  // 안전기 점검 데이터 조회
  Future<void> loadCheckInfo() async {
    showLoadingBar(true);
    var response = await Net.post('/tm/service', {
      'SPNAME': 'APG_MOBILE_TM21070.INQUERY_SAFETY',
      'IN_EQUIPCD': widget.selectedEquipment['EQUIPCD'],
      'IN_CORCD': Util.USER_INFO['CORCD'],
      'IN_BIZCD': Util.USER_INFO['BIZCD'],
      'IN_CHECK_DATE': checkDate,
      'IN_LANG_SET': Util.USER_INFO['IN_LANG_SET'],
    });
    ReturnObject resultItem = ReturnObject.fromJsonMap(jsonDecode(response.body));
    if (resultItem.result == 'SUCCESS' && resultItem.data != null && resultItem.data.length > 0) {
      print(resultItem.data);
      checkInfo = resultItem.data[0];
      
      selectedStateCode = checkInfo['WORK_STATUS'] == stateCodes[0].code ? stateCodes[0] : stateCodes[1];
      selectedLocateCode = checkInfo['DETECT_LOC'] == locateCodes[0].code ? locateCodes[0] : locateCodes[1];
      selectedDirtyCode = checkInfo['POLLUTION'] == dirtyCodes[0].code ? dirtyCodes[0] : dirtyCodes[1];
      checkController.text = checkInfo['CHK_MANAGER'] ?? '';
      noteController.text = checkInfo['REMARK'] ?? '';
      setState(() {
        isSavedResult = true;  
      });
    }
    showLoadingBar(false);
  }

  Widget verticalDivider = const VerticalDivider(
    color: Color.fromRGBO(190, 190, 190, 1.0),
    thickness: 0.5,
  );

  // 안전기 점검시트 화면
  Widget showSafetyCheckList() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 5.0),
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
                    child: Text('대표라인명',
                        style: TextStyle(
                            fontSize: 15,
                            color: Colors.white,
                            fontFamily: MyFontStyle.nanumGothicBold))),
                size: ColumnSize.M),
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
                    child: Text('설비명',
                        style: TextStyle(
                            fontSize: 15,
                            color: Colors.white,
                            fontFamily: MyFontStyle.nanumGothicBold))),
                size: ColumnSize.M),
            DataColumn2(label: verticalDivider, fixedWidth: 10),
            const DataColumn2(
                label: Center(
                    child: Text('동작상태',
                        style: TextStyle(
                            fontSize: 15,
                            color: Colors.white,
                            fontFamily: MyFontStyle.nanumGothicBold))),
                fixedWidth: 110),
            DataColumn2(label: verticalDivider, fixedWidth: 10),
            const DataColumn2(
                label: Center(
                    child: Text('감지위치',
                        style: TextStyle(
                            fontSize: 15,
                            color: Colors.white,
                            fontFamily: MyFontStyle.nanumGothicBold))),
                fixedWidth: 110),
            DataColumn2(label: verticalDivider, fixedWidth: 10),
            const DataColumn2(
                label: Center(
                    child: Text('이물질(오염)',
                        style: TextStyle(
                            fontSize: 15,
                            color: Colors.white,
                            fontFamily: MyFontStyle.nanumGothicBold))),
                fixedWidth: 110),
            DataColumn2(label: verticalDivider, fixedWidth: 10),
            const DataColumn2(
                label: Center(
                    child: Text('생산 확인',
                        style: TextStyle(
                            fontSize: 15,
                            color: Colors.white,
                            fontFamily: MyFontStyle.nanumGothicBold))),
                fixedWidth: 110),
          ],
          dataRowHeight: 50,
          columnSpacing: 0,
          showBottomBorder: true,
          // border: TableBorder(
          //     top: BorderSide(color: Colors.black, width: 0.1),
          //     bottom: BorderSide(color: Colors.black, width: 0.1)),
          horizontalMargin: 0,
          rows: List.generate(1, (index) {
            return DataRow(cells: [
              DataCell(Align(
                  alignment: Alignment.centerRight,
                  child: Text((index + 1).toString(),
                      style: const TextStyle(
                          fontSize: 15, fontFamily: MyFontStyle.nanumGothic)))),
              DataCell(verticalDivider),
              DataCell(Center(
                  child: Text(equipmentInfo['PROC_REP_LINE_NM'] ?? '',
                      style: TextStyle(
                          fontSize: 15, fontFamily: MyFontStyle.nanumGothic)))),
              DataCell(verticalDivider),
              DataCell(Center(
                  child: Text(equipmentInfo['LINENM'] ?? '',
                      style: TextStyle(
                          fontSize: 15, fontFamily: MyFontStyle.nanumGothic)))),
              DataCell(verticalDivider),
              DataCell(Center(
                  child: Text(equipmentInfo['EQUIPNM'] ?? '',
                      style: TextStyle(
                          fontSize: 15, fontFamily: MyFontStyle.nanumGothic)))),
              DataCell(verticalDivider),
              DataCell(Center(
                  child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 5),
                      child: stateCodeWidget()))),
              DataCell(verticalDivider),
              DataCell(Center(
                  child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 5),
                      child: locateCodeWidget()))),
              DataCell(verticalDivider),
              DataCell(Center(
                  child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 5),
                      child: dirtyCodeWidget()))),
              DataCell(verticalDivider),
              DataCell(Center(
                  child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 5),
                      child: inputFormField('생산 확인', checkController)))),
            ]);
          }),
        ),
      ),
    );
  }

  // 설비상세정보 text form 위젯
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
  Widget inputFormField(String text, TextEditingController controller) {
    return TextFormField(
        controller: controller,
        keyboardType: TextInputType.text,
        style: TextStyle(
          fontFamily: MyFontStyle.nanumGothic,
          fontSize: 15,
        ),
        textAlignVertical: TextAlignVertical.center,
        textAlign: TextAlign.center,
        cursorColor: Color.fromRGBO(110, 110, 110, 1.0),
        decoration: InputDecoration(
          fillColor: Color.fromRGBO(190, 190, 190, 0.5),
          filled: isSavedResult,
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
        hintText: '조치내용을 입력해주세요.',
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
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: Color.fromRGBO(0, 80, 155, 1)),
                                onPressed: () async {
                                  showEquipDetailInfo();
                                },
                                child: Text(
                                  '설비정보',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontFamily: MyFontStyle.nanumGothic,
                                      fontSize: 16),
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
                                        subType: 'BA',
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
                      height: 120,
                      child: showSafetyCheckList(),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Container(
                            margin: EdgeInsets.only(left: 10),
                            child: Row(
                              children: <Widget>[
                                Container(
                                  margin: EdgeInsets.only(left: 10, top: 15, right: 5),
                                  child: Text('조치내용', style: TextStyle(fontSize: 18, fontFamily: MyFontStyle.nanumGothicBold, color: Color.fromRGBO(110, 110, 110, 1)),),
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
                      )
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
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
                                style: TextStyle(
                                    color: Colors.white,
                                    fontFamily: MyFontStyle.nanumGothic,
                                    fontSize: 16),
                              )),
                        ),
                        Container(
                          width: 100.0,
                          margin: EdgeInsets.only(left: 5, right: 10),
                          padding: EdgeInsets.symmetric(vertical: 5),
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                                backgroundColor: Color.fromRGBO(0, 80, 155, 1)),
                            onPressed: () async {
                              // showDialog(
                              //   context: context,
                              //   barrierDismissible: false,
                              //   builder: (BuildContext context) {
                              //     return Util.ShowConfirmPopup(context, '점검 결과를 저장하시겠습니까?', () async {
                                    var response = await Net.post('/tm/service', {
                                      'SPNAME': 'APG_MOBILE_TM21070.SAVE_SAFETY',
                                        'IN_EQUIPCD': widget.selectedEquipment['EQUIPCD'],
                                        'IN_CHECK_DATE': checkDate,
                                        'IN_CORCD': Util.USER_INFO['CORCD'],
                                        'IN_BIZCD': Util.USER_INFO['BIZCD'],
                                        'IN_WORK_STATUS': selectedStateCode.code,
                                        'IN_DETECT_LOC': selectedLocateCode.code,
                                        'IN_POLLUTION': selectedDirtyCode.code,
                                        'IN_REMARK': noteController.text,
                                        'IN_CHK_MANAGER': checkController.text,
                                        'IN_REG_EMPNO': Util.USER_INFO['EMPNO']
                                    });
                                    ReturnObject resultItem = ReturnObject.fromJsonMap(jsonDecode(response.body));
                                    if (resultItem.result == 'SUCCESS') {
                                      setState(() {
                                        isSavedResult = true;
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
                        ),
                      ],
                    ),
                  ],
                ),
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

class StateCode {
  const StateCode(this.code, this.name);

  final String code;
  final String name;

  @override
  String toString() {
    return '$code: $name';
  }
}

class LocateCode {
  const LocateCode(this.code, this.name);

  final String code;
  final String name;

  @override
  String toString() {
    return '$code: $name';
  }
}

class DirtyCode {
  const DirtyCode(this.code, this.name);

  final String code;
  final String name;

  @override
  String toString() {
    return '$code: $name';
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
