import 'dart:convert';

import 'package:data_table_2/data_table_2.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:pinch_zoom/pinch_zoom.dart';
import 'package:seoyoneh_equipment/Font/font.dart';
import 'package:seoyoneh_equipment/Model/ReturnObject.dart';
import 'package:seoyoneh_equipment/QRScanner/qrScanner.dart';
import 'package:seoyoneh_equipment/Tool/toolInfo_detail.dart';
import 'package:seoyoneh_equipment/Util/net.dart';
import 'package:seoyoneh_equipment/Util/util.dart';

// ignore: must_be_immutable
class ToolInfo extends StatefulWidget {
  ToolInfo({super.key});

  @override
  State<ToolInfo> createState() => _ToolInfoState();
}

class _ToolInfoState extends State<ToolInfo> {
  List<DropDownCode> factoryCodes = <DropDownCode>[]; // 공장구분 combobox
  List<DropDownCode> lineCodes = <DropDownCode>[]; // 공장구분 combobox

  DropDownCode selectedFactoryCode = DropDownCode('', '', ''); // 선택된 공장구분 code
  DropDownCode selectedLineCode = DropDownCode('', '', ''); // 선택된 공장구분 code

  late TextEditingController toolCodeController; // 공구코드
  late TextEditingController toolNoController; // 공구번호
  late TextEditingController toolNameController; // 공구명
  late PaginatorController pageController; // grid padge Controller

  late DTS dts;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    toolCodeController = TextEditingController();
    toolNoController = TextEditingController();
    toolNameController = TextEditingController();
    pageController = PaginatorController();
    dts = DTS(0, [], context);

    loadFactoryCodes();
  }

  void showLoadingBar(bool flag) {
    setState(() {
      isLoading = flag;
    });
  }

  // 공장 구분 콤보박스 데이터 조회
  Future<void> loadFactoryCodes() async {
    showLoadingBar(true);
    factoryCodes.clear();
    var response = await Net.post('/tm/service', {
      'SPNAME': 'APG_MOBILE_SUPPORT.INQUERY_BIZ_LIST',
      'IN_LANG_SET': Util.USER_INFO['IN_LANG_SET'],
    });
    ReturnObject resultItem = ReturnObject.fromJsonMap(jsonDecode(response.body));
    if (resultItem.result == 'SUCCESS' && resultItem.data != null && resultItem.data.length > 0) {
      factoryCodes.add(DropDownCode('', '', ''));
      for (int index = 0; index < resultItem.data.length; index++) {
        factoryCodes.add(DropDownCode(resultItem.data[index]['OBJECT_ID'], resultItem.data[index]['GROUPCD'], resultItem.data[index]['OBJECT_NM']));
      }
      selectedFactoryCode = factoryCodes.first;
    }
    showLoadingBar(false);
    loadLineCodes();
  }

  // 라인 combobox 데이터 조회
  Future<void> loadLineCodes() async {
    showLoadingBar(true);
    var response = await Net.post('/tm/service.do', {
      'SPNAME': 'APG_MOBILE_TM21010.INQUERY_PROC_REP_LINE',
      // 공장구분 선택에 따른 BIZCD 수정 필요
      'IN_BIZCD': selectedFactoryCode.code.isEmpty ? Util.USER_INFO['BIZCD'] : selectedFactoryCode.group,
      'IN_CORCD': Util.USER_INFO['CORCD'],
      'IN_PLANT_DIV': '',
      'IN_LANG_SET': Util.USER_INFO['IN_LANG_SET'],
    });
    ReturnObject resultItem = ReturnObject.fromJsonMap(jsonDecode(response.body));
    if (resultItem.result == 'SUCCESS' && resultItem.data != null && resultItem.data.length > 0) {
      lineCodes.add(DropDownCode('', '', ''));
      for (int index = 0; index < resultItem.data.length; index++) {
        lineCodes.add(DropDownCode(resultItem.data[index]['PROC_REP_LINE'], '', resultItem.data[index]['LINENM']));
      }
      selectedLineCode = lineCodes.first;
    }
    
    showLoadingBar(false);
    loadToolList();
  }

  // 공구 현황 데이터 조회
  void loadToolList() async {
    showLoadingBar(true);
    var response = await Net.post('/tm/service.do', {
      'SPNAME': 'APG_MOBILE_TM21310.INQUERY',
      'IN_CORCD': Util.USER_INFO['CORCD'],
      'IN_BIZCD': selectedFactoryCode.code.isEmpty ? Util.USER_INFO['BIZCD'] : selectedFactoryCode.group,
      'IN_LINECD': selectedLineCode.code.isEmpty ? '' : selectedLineCode.code,
      'IN_TOOLCD': toolCodeController.text,
      'IN_TOOLNO': toolNoController.text,
      'IN_MODELNAME': toolNameController.text
    });
    ReturnObject resultItem =
        ReturnObject.fromJsonMap(jsonDecode(response.body));
    if (resultItem.result == 'SUCCESS' &&
        resultItem.data != null &&
        resultItem.data.length > 0) {
      setState(() {
        dts = DTS(resultItem.data.length, resultItem.data, context);
      });
    } else {
      setState(() {
        dts = DTS(resultItem.data.length, resultItem.data, context);
      });
    }
    showLoadingBar(false);
  }

  Widget factoryCodeWidget() {
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
        items: factoryCodes.map((DropDownCode code) {
          return DropdownMenuItem<DropDownCode>(
            value: code,
            child: Text(
              code.name,
              style: const TextStyle(color: Colors.black, fontSize: 15.0, fontFamily: MyFontStyle.nanumGothic),
            ),
          );
        }).toList(),
        onChanged: (value) async {
          pageController.goToFirstPage();
          setState(() {
            print(value);
            lineCodes.clear();
            selectedFactoryCode = value!;
            loadLineCodes();
          });
        },
        value: selectedFactoryCode,
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

  // 라인코드 combobox 위젯
  Widget lineCodeWidget() {
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
        items: lineCodes.map((DropDownCode code) {
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
            print(value);
            selectedLineCode = value!;
          });
        },
        value: selectedLineCode,
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

  Widget verticalDivider = const VerticalDivider(
    color: Color.fromRGBO(190, 190, 190, 1.0),
    thickness: 0.5,
  );

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
            child: Padding(
              padding: const EdgeInsets.only(
                  top: 20.0, left: 0.0, right: 0.0, bottom: 0.0),
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
                  Column(
                    children: <Widget>[
                      Container(
                        margin: EdgeInsets.all(5),
                        width: MediaQuery.of(context).size.width,
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          border: Border.all(width: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            Row(
                              children: <Widget>[
                                Padding(
                                  padding: EdgeInsets.only(left: 10),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Container(
                                      margin: EdgeInsets.only(left: 5, top: 15),
                                      child: Text(
                                        '공장구분',
                                        style: TextStyle(
                                            fontSize: 18,
                                            fontFamily: MyFontStyle.nanumGothic),
                                      ),
                                    ),
                                    Container(
                                      margin: EdgeInsets.only(top: 10),
                                      height: 40,
                                      width: (MediaQuery.of(context).size.width -
                                              160) /
                                          4,
                                      child: factoryCodeWidget(),
                                    )
                                  ],
                                ),
                                Padding(
                                  padding: EdgeInsets.only(left: 5),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Container(
                                      margin: EdgeInsets.only(left: 5, top: 15),
                                      child: Text(
                                        '대표라인',
                                        style: TextStyle(
                                            fontSize: 18,
                                            fontFamily: MyFontStyle.nanumGothic),
                                      ),
                                    ),
                                    Container(
                                      margin: EdgeInsets.only(top: 10),
                                      height: 40,
                                      width: (MediaQuery.of(context).size.width -
                                              160) /
                                          4,
                                      child: lineCodeWidget(),
                                    )
                                  ],
                                ),
                                
                                Padding(
                                  padding: EdgeInsets.only(left: 5),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Container(
                                      margin: EdgeInsets.only(left: 5, top: 15),
                                      child: Text(
                                        '공구번호',
                                        style: TextStyle(
                                            fontSize: 18,
                                            fontFamily: MyFontStyle.nanumGothic),
                                      ),
                                    ),
                                    Container(
                                      margin: EdgeInsets.only(top: 10),
                                      height: 40,
                                      width: (MediaQuery.of(context).size.width -
                                              160) /
                                          4,
                                      child: TextFormField(
                                        cursorColor:
                                            Color.fromRGBO(110, 110, 110, 1.0),
                                        style: TextStyle(
                                            fontFamily: MyFontStyle.nanumGothic,
                                            fontSize: 17),
                                        textAlignVertical:
                                            TextAlignVertical.center,
                                        controller: toolNoController,
                                        decoration: InputDecoration(
                                          contentPadding:
                                              const EdgeInsets.all(10),
                                          focusedBorder: const OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.horizontal(
                                                left: Radius.circular(5),
                                                right: Radius.circular(5),
                                              ),
                                              borderSide:
                                                  BorderSide(color: Colors.grey)),
                                          enabledBorder: const OutlineInputBorder(
                                            borderRadius: BorderRadius.horizontal(
                                              left: Radius.circular(5),
                                              right: Radius.circular(5),
                                            ),
                                            borderSide:
                                                BorderSide(color: Colors.grey),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                Padding(
                                  padding: EdgeInsets.only(left: 5),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Container(
                                      margin: EdgeInsets.only(left: 5, top: 15),
                                      child: Text(
                                        '모델명',
                                        style: TextStyle(
                                            fontSize: 18,
                                            fontFamily: MyFontStyle.nanumGothic),
                                      ),
                                    ),
                                    Container(
                                      margin: EdgeInsets.only(top: 10),
                                      height: 40,
                                      width: (MediaQuery.of(context).size.width -
                                              160) /
                                          4,
                                      child: TextFormField(
                                        cursorColor:
                                            Color.fromRGBO(110, 110, 110, 1.0),
                                        style: TextStyle(
                                            fontFamily: MyFontStyle.nanumGothic,
                                            fontSize: 17),
                                        textAlignVertical:
                                            TextAlignVertical.center,
                                        controller: toolNameController,
                                        decoration: InputDecoration(
                                          contentPadding:
                                              const EdgeInsets.all(10),
                                          focusedBorder: const OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.horizontal(
                                                left: Radius.circular(5),
                                                right: Radius.circular(5),
                                              ),
                                              borderSide:
                                                  BorderSide(color: Colors.grey)),
                                          enabledBorder: const OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.horizontal(
                                                left: Radius.circular(5),
                                                right: Radius.circular(5),
                                              ),
                                              borderSide:
                                                  BorderSide(color: Colors.grey)),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            Column(
                              children: <Widget>[
                                // Container(
                                //   margin: EdgeInsets.only(
                                //       top: 5, bottom: 5, right: 5),
                                //   width: 100,
                                //   height: 40,
                                //   child: OutlinedButton(
                                //       style: OutlinedButton.styleFrom(
                                //           backgroundColor:
                                //               Color.fromRGBO(0, 80, 155, 1)),
                                //       onPressed: () async {
                                //         // String responseCode = await FlutterBarcodeScanner.scanBarcode('#ff6666', '취소', true, ScanMode.BARCODE);
                                //         // print(responseCode);
                                //         // var response = await Net.post('/tm/service', {
                                //         //   'SPNAME': 'APG_TM21310.INQUERY',
                                //         //   'IN_CORCD': Util.USER_INFO['CORCD'],
                                //         //   'IN_BIZCD': Util.USER_INFO['BIZCD'], //Util.USER_INFO['BIZCD'],
                                //         //   'IN_LINECD': '',
                                //         //   'IN_TOOLCD': responseCode,
                                //         //   'IN_TOOLNO': '',
                                //         //   'IN_MODELNAME': ''
                                //         // });
                                //         // var responseBody = jsonDecode(response.body);
                                //         // var resultToolInfo = responseBody['data'][0];
                                //         // await Util.pushNavigator(
                                //         //     context,
                                //         //     ToolDetailInfo(
                                //         //       toolInfo: resultToolInfo,
                                //         //     ));
                                //         await Util.pushNavigator(
                                //             context,
                                //             QRScanner(
                                //               type: 'tool',
                                //               subType: '',
                                //             ));
                                //       },
                                //       child: Text(
                                //         'QR',
                                //         style: TextStyle(
                                //             color: Colors.white,
                                //             fontFamily: MyFontStyle.nanumGothic,
                                //             fontSize: 16),
                                //       )),
                                // ),
                                Container(
                                  margin: EdgeInsets.only(bottom: 5, right: 5, top: 50),
                                  width: 100,
                                  height: 40,
                                  child: OutlinedButton(
                                    style: OutlinedButton.styleFrom(
                                        backgroundColor:
                                            Color.fromRGBO(0, 80, 155, 1)),
                                    onPressed: () async {
                                      pageController.goToFirstPage();
                                      loadToolList();
                                    },
                                    child: Text(
                                      '조회',
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
                    ],
                  ),
                  Expanded(
                    child: Theme(
                      data: Theme.of(context).copyWith(
                          dividerColor: Color.fromRGBO(190, 190, 190, 1.0)),
                      child: PaginatedDataTable2(
                          headingRowColor: MaterialStateColor.resolveWith(
                              (states) => Color.fromRGBO(0, 80, 155, 1.0)),
                          minWidth: MediaQuery.of(context).size.width * 1.05,
                          fixedLeftColumns: 10,
                          columns: [
                            const DataColumn2(
                                label: Center(
                                    child: Text('No.',
                                        style: TextStyle(
                                            fontSize: 15,
                                            color: Colors.white,
                                            fontFamily:
                                                MyFontStyle.nanumGothicBold))),
                                fixedWidth: 40),
                            DataColumn2(label: verticalDivider, fixedWidth: 10),
                            const DataColumn2(
                                label: Center(
                                    child: Text('공구번호',
                                        style: TextStyle(
                                            fontSize: 15,
                                            color: Colors.white,
                                            fontFamily:
                                                MyFontStyle.nanumGothicBold))),
                                fixedWidth: 150),
                            DataColumn2(label: verticalDivider, fixedWidth: 10),
                            const DataColumn2(
                                label: Center(
                                    child: Text('대표라인',
                                        style: TextStyle(
                                            fontSize: 15,
                                            color: Colors.white,
                                            fontFamily:
                                                MyFontStyle.nanumGothicBold)))),
                            DataColumn2(label: verticalDivider, fixedWidth: 10),
                            const DataColumn2(
                                label: Center(
                                    child: Text('모델명',
                                        style: TextStyle(
                                            fontSize: 15,
                                            color: Colors.white,
                                            fontFamily:
                                                MyFontStyle.nanumGothicBold)))),
                            DataColumn2(label: verticalDivider, fixedWidth: 10),
                            const DataColumn2(
                                label: Center(
                                    child: Text('모델번호',
                                        style: TextStyle(
                                            fontSize: 15,
                                            color: Colors.white,
                                            fontFamily:
                                                MyFontStyle.nanumGothicBold))),
                                fixedWidth: 150),
                            DataColumn2(label: verticalDivider, fixedWidth: 10),
                            const DataColumn2(
                                label: Center(
                                    child: Text('메이커',
                                        style: TextStyle(
                                            fontSize: 15,
                                            color: Colors.white,
                                            fontFamily:
                                                MyFontStyle.nanumGothicBold))),
                                fixedWidth: 120),
                            DataColumn2(label: verticalDivider, fixedWidth: 10),
                            const DataColumn2(
                                label: Center(
                                    child: Text('관리기준',
                                        style: TextStyle(
                                            fontSize: 15,
                                            color: Colors.white,
                                            fontFamily:
                                                MyFontStyle.nanumGothicBold))),
                                fixedWidth: 70),
                            DataColumn2(label: verticalDivider, fixedWidth: 10),
                            const DataColumn2(
                                label: Center(
                                    child: Text('속도(rpm)',
                                        style: TextStyle(
                                            fontSize: 15,
                                            color: Colors.white,
                                            fontFamily:
                                                MyFontStyle.nanumGothicBold))),
                                fixedWidth: 70),
                            DataColumn2(label: verticalDivider, fixedWidth: 10),
                            const DataColumn2(
                                label: Center(
                                    child: Text('S/S',
                                        style: TextStyle(
                                            fontSize: 15,
                                            color: Colors.white,
                                            fontFamily:
                                                MyFontStyle.nanumGothicBold))),
                                fixedWidth: 90),
                            DataColumn2(label: verticalDivider, fixedWidth: 10),
                            const DataColumn2(
                                label: Center(
                                    child: Text('중량(kg)',
                                        style: TextStyle(
                                            fontSize: 15,
                                            color: Colors.white,
                                            fontFamily:
                                                MyFontStyle.nanumGothicBold))),
                                fixedWidth: 60),
                          ],
                          showFirstLastButtons: true,
                          dataRowHeight: 40,
                          rowsPerPage: 25,
                          columnSpacing: 0,
                          horizontalMargin: 0,
                          renderEmptyRowsInTheEnd: false,
                          controller: pageController,
                          source: dts),
                    ),
                  ),
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
        )
      ],
    );
  }
}

class DTS extends DataTableSource {
  int length = 0;
  List<dynamic> result = [];
  BuildContext context;

  DTS(equipLength, equipList, this.context) {
    length = equipLength;
    result.addAll(equipList);
  }

  Widget verticalDivider = const VerticalDivider(
    color: Color.fromRGBO(190, 190, 190, 1.0),
    thickness: 0.5,
  );

  void tapOnDataCell(context, Map<String, dynamic> selectedTool) async {
    await Util.pushNavigator(context, ToolDetailInfo(toolInfo: selectedTool));
  }

  @override
  DataRow getRow(int index) {
    return DataRow2.byIndex(
      onTap: () {
        tapOnDataCell(context, result[index]);
      },
      index: index,
      cells: [
        DataCell(Align(
            alignment: Alignment.centerRight,
            child: Text((index + 1).toString(),
                style: const TextStyle(
                    fontSize: 15, fontFamily: MyFontStyle.nanumGothic)))),
        DataCell(verticalDivider),
        DataCell(Align(
            alignment: Alignment.center,
            child: Text(result[index]['TOOLNO'] ?? '',
                style: const TextStyle(
                    fontSize: 15, fontFamily: MyFontStyle.nanumGothic)))),
        DataCell(verticalDivider),
        DataCell(Text(result[index]['LINECDNM'] ?? '',
            style:
                TextStyle(fontSize: 15, fontFamily: MyFontStyle.nanumGothic))),
        DataCell(verticalDivider),
        DataCell(Text(result[index]['MODELNAME'] ?? '',
            style: const TextStyle(
                fontSize: 15, fontFamily: MyFontStyle.nanumGothic))),
        DataCell(verticalDivider),
        DataCell(Text(result[index]['MODELNO'] ?? '',
            style: const TextStyle(
                fontSize: 15, fontFamily: MyFontStyle.nanumGothic))),
        DataCell(verticalDivider),
        DataCell(Text(result[index]['MAKERNM'] ?? '',
            style: const TextStyle(
                fontSize: 15, fontFamily: MyFontStyle.nanumGothic))),
        DataCell(verticalDivider),
        DataCell(Text(result[index]['MGRT_STD'] ?? '',
            style: const TextStyle(
                fontSize: 15, fontFamily: MyFontStyle.nanumGothic))),
        DataCell(verticalDivider),
        DataCell(Text(result[index]['SPEEDNM'] ?? '',
            style: const TextStyle(
                fontSize: 15, fontFamily: MyFontStyle.nanumGothic))),
        DataCell(verticalDivider),
        DataCell(Text(result[index]['SCREW_SIZE'] ?? '',
            style: const TextStyle(
                fontSize: 15, fontFamily: MyFontStyle.nanumGothic))),
        DataCell(verticalDivider),
        DataCell(
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              result[index] == null
                  ? ''
                  : Util.doubleNumberFormat(result[index]['WEIGHT']),
              style: const TextStyle(
                  fontSize: 15, fontFamily: MyFontStyle.nanumGothic),
            ),
          ),
        ),
      ],
    );
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => length;

  @override
  int get selectedRowCount => 0;
}

class LineCode {
  const LineCode(this.code, this.name);

  final String code;
  final String name;

  @override
  String toString() {
    return '$code: $name';
  }
}
