import 'dart:convert';

import 'package:data_table_2/data_table_2.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:pinch_zoom/pinch_zoom.dart';
import 'package:seoyoneh_equipment/Font/font.dart';
import 'package:seoyoneh_equipment/Illuminance/illuminance_detail.dart';
import 'package:seoyoneh_equipment/Model/ReturnObject.dart';
import 'package:seoyoneh_equipment/QRScanner/qrScanner.dart';
import 'package:seoyoneh_equipment/Util/net.dart';
import 'package:seoyoneh_equipment/Util/util.dart';

class IlluminanceInfo extends StatefulWidget {
  IlluminanceInfo({super.key});

  @override
  State<IlluminanceInfo> createState() => _IlluminanceInfoState();
}

class _IlluminanceInfoState extends State<IlluminanceInfo> {
  _IlluminanceInfoState();
  List<DropDownCode> factoryCodes = <DropDownCode>[]; // 공장구분 combobox
  List<DropDownCode> repLineCodes = <DropDownCode>[]; // 대표라인 combobox
  List<DropDownCode> subLineCodes = <DropDownCode>[]; // 라인 combobox

  DropDownCode selectedFactoryCode = DropDownCode('', '', ''); // 선택된 공장구분 code
  DropDownCode selectedRepLineCode = DropDownCode('', '', ''); // 선택된 대표라인 code
  DropDownCode selectedSubLineCode = DropDownCode('', '', ''); // 선택된 라인 code

  late PaginatorController pageController; // grid page Controller

  late DTS dts;

  bool isLoading = false;

  @override
  void initState() {
    pageController = PaginatorController();
    dts = DTS(0, [], context);
    loadFactoryCodes();
    loadProcList();
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

  // 공장구분 combobox 위젯
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
            selectedFactoryCode = value!;
            // loadRepLineCodes();
            loadSubLineCodes();
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

  
  // 대표라인 콤보박스 위젯
  Widget RepLineCodeWidget() {
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
        items: repLineCodes.map((DropDownCode code) {
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
            selectedRepLineCode = value!;
            loadSubLineCodes();
          });
        },
        value: selectedRepLineCode,
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

  // 라인 combobox 위젯
  Widget SubLineCodeWidget() {
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
        items: subLineCodes.map((DropDownCode lineCode) {
          return DropdownMenuItem<DropDownCode>(
            value: lineCode,
            child: Text(
              lineCode.name,
              style: const TextStyle(color: Colors.black, fontSize: 15.0, fontFamily: MyFontStyle.nanumGothic),
            ),
          );
        }).toList(),
        onChanged: (value) async {
          pageController.goToFirstPage();
          setState(() {
            selectedSubLineCode = value!;
          });
        },
        value: selectedSubLineCode,
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
        if(resultItem.data[index]['GROUPCD'] == Util.USER_INFO['BIZCD'] && resultItem.data[index]['OBJECT_NM'] != '두서공장') {
          selectedFactoryCode = factoryCodes[index+1];
        }
      }
      // selectedFactoryCode = factoryCodes.first;
    }
    showLoadingBar(false);
    // loadRepLineCodes();
    loadSubLineCodes();
  }

  // 대표라인코드 데이터 조회
  // Future<void> loadRepLineCodes() async {
  //   showLoadingBar(true);
  //   repLineCodes.clear();
  //   var response = await Net.post('/tm/service', {
  //     'SPNAME': 'APG_MOBILE_TM21010.INQUERY_PROC_REP_LINE',
  //     'IN_BIZCD': selectedFactoryCode.code.isEmpty ? Util.USER_INFO['BIZCD'] : selectedFactoryCode.group,
  //     'IN_CORCD': Util.USER_INFO['CORCD'],
  //     'IN_PLANT_DIV': selectedFactoryCode.code,
  //     'IN_LANG_SET': Util.USER_INFO['IN_LANG_SET'],
  //   });
  //   ReturnObject resultItem = ReturnObject.fromJsonMap(jsonDecode(response.body));

  //   if (resultItem.result == 'SUCCESS' && resultItem.data != null && resultItem.data.length > 0) {
  //     repLineCodes.add(DropDownCode('', '', ''));
  //     for (int index = 0; index < resultItem.data.length; index++) {
  //       repLineCodes.add(DropDownCode(resultItem.data[index]['PROC_REP_LINE'], '', resultItem.data[index]['LINENM']));
  //     }
  //     selectedRepLineCode = repLineCodes.first;
  //   }
  //   // 설비 목록 데이터 바인딩 전에 loadingBar 제거 되지 않도록 설정
  //   if(dts.length != 0) {
  //     showLoadingBar(false);
  //   }
  // }

  // 라인코드 데이터 조회
  Future<void> loadSubLineCodes() async {
    showLoadingBar(true);
    subLineCodes.clear();
    var response = await Net.post('/tm/service', {
      'SPNAME': 'APG_MOBILE_TM21010.INQUERY_ILMN_LINE',
      'IN_CORCD': Util.USER_INFO['CORCD'],
      'IN_BIZCD': selectedFactoryCode.code.isEmpty ? Util.USER_INFO['BIZCD'] : selectedFactoryCode.group
      
    });
    ReturnObject resultItem = ReturnObject.fromJsonMap(jsonDecode(response.body));
    if (resultItem.result == 'SUCCESS' && resultItem.data != null && resultItem.data.length > 0) {
      subLineCodes.add(DropDownCode('', '', ''));
      for (int index = 0; index < resultItem.data.length; index++) {
        subLineCodes.add(DropDownCode(resultItem.data[index]['LINECD'], '', resultItem.data[index]['LINENM']));
      }
      selectedSubLineCode = subLineCodes.first;
    }
    showLoadingBar(false);
  }

  void loadProcList() async {
    // 라인정보 조회
    // BM20020패키지 INQUERY_MASTER 프로시저 호출
    showLoadingBar(true);
    var response = await Net.post('/tm/service', {
      'SPNAME': 'APG_MOBILE_BM20020.INQUERY_MASTER',
      'IN_CORCD': Util.USER_INFO['CORCD'],
      'IN_BIZCD': selectedFactoryCode.code.isEmpty ? Util.USER_INFO['BIZCD'] : selectedFactoryCode.group,
      'IN_LINECD': selectedSubLineCode.code.isEmpty ? '' : selectedSubLineCode.code,
      'IN_LANG_SET': Util.USER_INFO['IN_LANG_SET']
    });
    ReturnObject resultItem = ReturnObject.fromJsonMap(jsonDecode(response.body));
    print(resultItem.data);
    print(resultItem.data.length);
    if (resultItem.result == 'SUCCESS' && resultItem.data != null && resultItem.data.length > 0) {
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

  Widget verticalDivider = const VerticalDivider(
    color: Color.fromRGBO(190, 190, 190, 1.0),
    thickness: 0.5,
  );

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        Scaffold(
          appBar: null,
          body: PinchZoom(
            maxScale: 2,
            resetDuration: Duration(milliseconds: 200),
            zoomEnabled: true,
            child: Padding(
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
                            Row(children: <Widget>[
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
                                      style: TextStyle(fontSize: 18, fontFamily: MyFontStyle.nanumGothic),
                                    ),
                                  ),
                                  Container(
                                    margin: EdgeInsets.only(top: 10),
                                    height: 40,
                                    width: (MediaQuery.of(context).size.width - 160) / 4,
                                    child: factoryCodeWidget(),
                                  )
                                ],
                              ),
                              // Padding(
                              //   padding: EdgeInsets.only(left: 5),
                              // ),
                              // Column(
                              //   crossAxisAlignment: CrossAxisAlignment.start,
                              //   children: <Widget>[
                              //     Container(
                              //       margin: EdgeInsets.only(left: 5, top: 15),
                              //       child: Text(
                              //         '대표라인',
                              //         style: TextStyle(fontSize: 18, fontFamily: MyFontStyle.nanumGothic),
                              //       ),
                              //     ),
                              //     Container(
                              //       margin: EdgeInsets.only(top: 10),
                              //       height: 40,
                              //       width: (MediaQuery.of(context).size.width - 160) / 4,
                              //       child: RepLineCodeWidget(),
                              //     )
                              //   ],
                              // ),
                              Padding(
                                padding: EdgeInsets.only(left: 5),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Container(
                                    margin: EdgeInsets.only(left: 5, top: 15),
                                    child: Text(
                                      '라인',
                                      style: TextStyle(fontSize: 18, fontFamily: MyFontStyle.nanumGothic),
                                    ),
                                  ),
                                  Container(
                                    margin: EdgeInsets.only(top: 10),
                                    height: 40,
                                    width: (MediaQuery.of(context).size.width - 160) / 4,
                                    child: SubLineCodeWidget(),
                                  ),
                                ],
                              ),
                              Padding(
                                padding: EdgeInsets.only(left: 5),
                              ),
                              // Column(
                              //   crossAxisAlignment: CrossAxisAlignment.start,
                              //   children: <Widget>[
                              //     Container(
                              //       margin: EdgeInsets.only(left: 5, top: 15),
                              //       child: Text(
                              //         '설비명',
                              //         style: TextStyle(fontSize: 18, fontFamily: MyFontStyle.nanumGothic),
                              //       ),
                              //     ),
                              //     Container(
                              //         margin: EdgeInsets.only(top: 10),
                              //         height: 40,
                              //         width: (MediaQuery.of(context).size.width - 160) / 4,
                              //         child: TextFormField(
                              //             cursorColor: Color.fromRGBO(110, 110, 110, 1.0),
                              //             style: TextStyle(fontFamily: MyFontStyle.nanumGothic, fontSize: 17),
                              //             textAlignVertical: TextAlignVertical.center,
                              //             controller: equipNameController,
                              //             decoration: InputDecoration(
                              //               contentPadding: const EdgeInsets.all(10),
                              //               focusedBorder: const OutlineInputBorder(
                              //                   borderRadius: BorderRadius.horizontal(
                              //                     left: Radius.circular(5),
                              //                     right: Radius.circular(5),
                              //                   ),
                              //                   borderSide: BorderSide(color: Colors.grey)),
                              //               enabledBorder: const OutlineInputBorder(
                              //                   borderRadius: BorderRadius.horizontal(
                              //                     left: Radius.circular(5),
                              //                     right: Radius.circular(5),
                              //                   ),
                              //                   borderSide: BorderSide(color: Colors.grey)),
                              //             )))
                              //   ],
                              // )
                            ]),
                            Column(
                              children: <Widget>[
                                Container(
                                  margin: EdgeInsets.only(top: 5, bottom: 5, right: 5),
                                  width: 100,
                                  height: 40,
                                  child: OutlinedButton(
                                      style: OutlinedButton.styleFrom(backgroundColor: Color.fromRGBO(0, 80, 155, 1)),
                                      onPressed: () async {
                                        // String responseCode = await FlutterBarcodeScanner.scanBarcode('#ff6666', '취소', true, ScanMode.BARCODE);
                                        // print(responseCode);
                                        // var response = await Net.post('/tm/service', {
                                        //   'SPNAME': 'APG_MOBILE_BM20020.INQUERY_MASTER',
                                        //   'IN_CORCD': Util.USER_INFO['CORCD'],
                                        //   'IN_BIZCD': Util.USER_INFO['BIZCD'],
                                        //   'IN_VINCD': '',
                                        //   'IN_LINECD': responseCode,
                                        //   'IN_PLANT_DIV': '',
                                        //   'IN_LANG_SET': Util.USER_INFO['IN_LANG_SET']
                                        // });
                                        // var responseBody = jsonDecode(response.body);
                                        // var resultToolInfo = responseBody['data'][0];
                                        // Util.pushNavigator(context, IlluminanceDetailInfo(selectedLine: resultToolInfo));
                                        await Util.pushNavigator(
                                            context,
                                            QRScanner(
                                              type: 'illuminance',
                                              subType: '',
                                            ));
                                      },
                                      child: Text(
                                        'QR',
                                        style: TextStyle(color: Colors.white, fontFamily: MyFontStyle.nanumGothic, fontSize: 16),
                                      )),
                                ),
                                Container(
                                  margin: EdgeInsets.only(bottom: 5, right: 5),
                                  width: 100,
                                  height: 40,
                                  child: OutlinedButton(
                                    style: OutlinedButton.styleFrom(backgroundColor: Color.fromRGBO(0, 80, 155, 1)),
                                    onPressed: () async {
                                      pageController.goToFirstPage();
                                      loadProcList();
                                    },
                                    child: Text(
                                      '조회',
                                      style: TextStyle(color: Colors.white, fontFamily: MyFontStyle.nanumGothic, fontSize: 16),
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
                          data: Theme.of(context).copyWith(dividerColor: Color.fromRGBO(190, 190, 190, 1.0)),
                          child: PaginatedDataTable2(
                              headingRowColor: MaterialStateColor.resolveWith((states) => Color.fromRGBO(0, 80, 155, 1.0)),
                              minWidth: MediaQuery.of(context).size.width,
                              columns: [
                                const DataColumn2(label: Center(child: Text('No.', style: TextStyle(fontSize: 15, color: Colors.white, fontFamily: MyFontStyle.nanumGothicBold))), fixedWidth: 50),
                                DataColumn2(label: verticalDivider, fixedWidth: 10),
                                const DataColumn2(label: Center(child: Text('공장구분', style: TextStyle(fontSize: 15, color: Colors.white, fontFamily: MyFontStyle.nanumGothicBold))), fixedWidth: 150),
                                DataColumn2(label: verticalDivider, fixedWidth: 10),
                                const DataColumn2(label: Center(child: Text('라인코드', style: TextStyle(fontSize: 15, color: Colors.white, fontFamily: MyFontStyle.nanumGothicBold))), fixedWidth: 150),
                                DataColumn2(label: verticalDivider, fixedWidth: 10),
                                const DataColumn2(label: Center(child: Text('라인명', style: TextStyle(fontSize: 15, color: Colors.white, fontFamily: MyFontStyle.nanumGothicBold)))),
                                // DataColumn2(label: verticalDivider, fixedWidth: 10),
                                // const DataColumn2(label: Center(child: Text('설비명', style: TextStyle(fontSize: 15, color: Colors.white, fontFamily: MyFontStyle.nanumGothicBold)))),
                                // DataColumn2(label: verticalDivider, fixedWidth: 10),
                                // const DataColumn2(label: Center(child: Text('규격', style: TextStyle(fontSize: 15, color: Colors.white, fontFamily: MyFontStyle.nanumGothicBold)))),
                                // DataColumn2(label: verticalDivider, fixedWidth: 10),
                                // const DataColumn2(label: Center(child: Text('중량', style: TextStyle(fontSize: 15, color: Colors.white, fontFamily: MyFontStyle.nanumGothicBold))), fixedWidth: 50),
                                // DataColumn2(label: verticalDivider, fixedWidth: 10),
                                // const DataColumn2(label: Center(child: Text('취득금액', style: TextStyle(fontSize: 15, color: Colors.white, fontFamily: MyFontStyle.nanumGothicBold))), size: ColumnSize.S),
                                // DataColumn2(label: verticalDivider, fixedWidth: 10),
                                // const DataColumn2(label: Center(child: Text('제작처', style: TextStyle(fontSize: 15, color: Colors.white, fontFamily: MyFontStyle.nanumGothicBold)))),
                                // DataColumn2(label: verticalDivider, fixedWidth: 10),
                                // const DataColumn2(label: Center(child: Text('관리담당자', style: TextStyle(fontSize: 15, color: Colors.white, fontFamily: MyFontStyle.nanumGothicBold)))),
                                // DataColumn2(label: verticalDivider, fixedWidth: 10),
                                // const DataColumn2(label: Center(child: Text('설비용도', style: TextStyle(fontSize: 15, color: Colors.white, fontFamily: MyFontStyle.nanumGothicBold))), size: ColumnSize.L),
                                // DataColumn2(label: verticalDivider, fixedWidth: 10),
                                // const DataColumn2(label: Center(child: Text('설비코드', style: TextStyle(fontSize: 15, color: Colors.white, fontFamily: MyFontStyle.nanumGothicBold)))),
                              ],
                              showFirstLastButtons: true,
                              dataRowHeight: 40,
                              rowsPerPage: 25,
                              controller: pageController,
                              columnSpacing: 0,
                              horizontalMargin: 0,
                              renderEmptyRowsInTheEnd: false,
                              source: dts)))
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

  DTS(lineLength, lineList, this.context) {
    this.length = lineLength;
    this.result.addAll(lineList);
  }

  Widget verticalDivider = const VerticalDivider(
    color: Color.fromRGBO(190, 190, 190, 1.0),
    thickness: 0.5,
  );

  void tapOnDataCell(context, Map<String, dynamic> selectedLine) async {
    print(selectedLine);
    Util.pushNavigator(context,
              IlluminanceDetailInfo(selectedLine: selectedLine));
    // showTermDialog(context, selectedEquipment);
  }

  @override
  DataRow getRow(int index) {
    return DataRow2.byIndex(
      onTap: () {
        print(result[index]);
        tapOnDataCell(context, result[index]);
      },
      index: index,
      cells: [
        DataCell(Align(alignment: Alignment.centerRight, child: Text((index + 1).toString(), style: const TextStyle(fontSize: 15, fontFamily: MyFontStyle.nanumGothic)))),
        DataCell(verticalDivider),
        DataCell(Align(alignment: Alignment.center, child: Text(result[index]['PLANT_DIV_NM'] ?? '', style: const TextStyle(fontSize: 15, fontFamily: MyFontStyle.nanumGothic)))),
        DataCell(verticalDivider),
        DataCell(Align(alignment: Alignment.center, child: Text(result[index]['LINECD'] ?? '', style: const TextStyle(fontSize: 15, fontFamily: MyFontStyle.nanumGothic)))),
        DataCell(verticalDivider),
        DataCell(Text(result[index]['LINENM'] ?? '', style: const TextStyle(fontSize: 15, fontFamily: MyFontStyle.nanumGothic))),
        // DataCell(verticalDivider),
        // DataCell(Text(result[index]['EQUIPNM'] ?? '', style: const TextStyle(fontSize: 15, fontFamily: MyFontStyle.nanumGothic))),
        // DataCell(verticalDivider),
        // DataCell(Text(result[index]['STD'] ?? '', style: const TextStyle(fontSize: 15, fontFamily: MyFontStyle.nanumGothic))),
        // DataCell(verticalDivider),
        // DataCell(Align(alignment: Alignment.centerRight, child: Text(result[index]['WEIGHT'] == null ? '' : Util.doubleNumberFormat(result[index]['WEIGHT']), style: const TextStyle(fontSize: 15, fontFamily: MyFontStyle.nanumGothic)))),
        // DataCell(verticalDivider),
        // DataCell(Align(alignment: Alignment.centerRight, child: Text(Util.thousandNumberFormat(result[index]['AMT']), style: const TextStyle(fontSize: 15, fontFamily: MyFontStyle.nanumGothic)))),
        // DataCell(verticalDivider),
        // DataCell(Text(result[index]['MAKE_VEND'] ?? '', style: const TextStyle(fontSize: 15, fontFamily: MyFontStyle.nanumGothic))),
        // DataCell(verticalDivider),
        // DataCell(Text(result[index]['MGRT_EMPNO'] ?? '', style: const TextStyle(fontSize: 15, fontFamily: MyFontStyle.nanumGothic))),
        // DataCell(verticalDivider),
        // DataCell(Text(result[index]['USE_DIV'] ?? '', style: const TextStyle(fontSize: 15, fontFamily: MyFontStyle.nanumGothic))),
        // DataCell(verticalDivider),
        // DataCell(Text(result[index]['EQUIPCD'] ?? '', style: const TextStyle(fontSize: 15, fontFamily: MyFontStyle.nanumGothic))),
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