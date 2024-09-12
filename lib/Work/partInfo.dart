import 'dart:convert';

import 'package:data_table_2/data_table_2.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pinch_zoom/pinch_zoom.dart';
import 'package:seoyoneh_equipment/Font/font.dart';
import 'package:seoyoneh_equipment/Model/ReturnObject.dart';
import 'package:seoyoneh_equipment/Util/net.dart';
import 'package:seoyoneh_equipment/Util/util.dart';
import 'package:seoyoneh_equipment/Work/registerWorkInfo.dart';

// ignore: must_be_immutable
class PartInfo extends StatefulWidget {
  PartInfo(this.partInfo, {super.key});
  Map<String, dynamic> partInfo = {};

  @override
  State<PartInfo> createState() => _PartInfoState(partInfo);
}

class _PartInfoState extends State<PartInfo> {
  _PartInfoState(this.partInfo);

  Map<String, dynamic> partInfo = {};
  List<DropDownCode> firstCodes = <DropDownCode>[]; // 첫번째 자재 분류 조건
  List<DropDownCode> secondCodes = <DropDownCode>[]; // 두번째 자재 분류 조건
  List<DropDownCode> thirdCodes = <DropDownCode>[]; // 세번째 자재 분류 조건
  List<dynamic> result = [];

  DropDownCode selectedFirstCode = DropDownCode('', '', ''); // 선택된 첫번째 자재 분류 코드
  DropDownCode selectedSecondCode = DropDownCode('', '', ''); // 선택된 두번쨰 자재 분류 코드
  DropDownCode selectedThirdCode = DropDownCode('', '', ''); // 선택된 세번째 자재 분류 코드

  late ScrollController scrollController;
  late TextEditingController partNameController;
  late DTS dts;
  
  bool isSearching = false;
  bool isLoading = false;


  @override
  void initState() {
    loadFirstCodes();
    partNameController = TextEditingController();
    dts = DTS(0, [], context);
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
  
  // 첫번째 자재 분류 데이터 조회
  Future<void> loadFirstCodes() async {
    showLoadingBar(true);
    firstCodes.clear();
    secondCodes.clear();
    thirdCodes.clear();
    var response = await Net.post('/tm/service.do', {
      'SPNAME': 'APG_TM21130.INQUERY_FIRST',
    });
    ReturnObject resultItem = ReturnObject.fromJsonMap(jsonDecode(response.body));
    if (resultItem.result == 'SUCCESS' && resultItem.data != null && resultItem.data.length > 0) {
      firstCodes.add(DropDownCode('', '', ''));
      secondCodes.add(DropDownCode('', '', ''));
      thirdCodes.add(DropDownCode('', '', ''));
      // thirdCodes.add(DropDownCode('', '', ''));
      for (int index = 0; index < resultItem.data.length; index++) {
        firstCodes.add(DropDownCode(resultItem.data[index]['CD'], resultItem.data[index]['MAPPINGCD'], resultItem.data[index]['CDNM']));
      }
      selectedFirstCode = firstCodes.first;
      selectedSecondCode = secondCodes.first;
      selectedThirdCode = thirdCodes.first;
    }
    showLoadingBar(false);
  }

  // 두번째 자재 분류 데이터 조회
  Future<void> loadSecondCodes() async {
    showLoadingBar(true);
    secondCodes.clear();
    thirdCodes.clear();
    var response = await Net.post('/tm/service.do', {
      'SPNAME': 'APG_TM21130.INQUERY_SECOND',
      'IN_CD': selectedFirstCode.code
    });
    ReturnObject resultItem = ReturnObject.fromJsonMap(jsonDecode(response.body));
    if (resultItem.result == 'SUCCESS' && resultItem.data != null && resultItem.data.length > 0) {
      secondCodes.add(DropDownCode('', '', ''));
      thirdCodes.add(DropDownCode('', '', ''));
      for (int index = 0; index < resultItem.data.length; index++) {
        secondCodes.add(DropDownCode(resultItem.data[index]['CD'], resultItem.data[index]['MAPPINGCD'], resultItem.data[index]['CDNM']));
      }
      selectedSecondCode = secondCodes.first;
      selectedThirdCode = thirdCodes.first;
    } else {
      secondCodes.add(DropDownCode('', '', ''));
      thirdCodes.add(DropDownCode('', '', ''));
      selectedSecondCode = secondCodes.first;
      selectedThirdCode = thirdCodes.first;
    }
    showLoadingBar(false);
  }

  // 세번째 자재 분류 데이터 조회
  Future<void> loadThirdCodes() async {
    showLoadingBar(true);
    thirdCodes.clear();
    var response = await Net.post('/tm/service.do', {
      'SPNAME': 'APG_TM21130.INQUERY_THIRD',
      'IN_CD': '${selectedFirstCode.code}${selectedSecondCode.code}'
    });
    ReturnObject resultItem = ReturnObject.fromJsonMap(jsonDecode(response.body));
    if (resultItem.result == 'SUCCESS' && resultItem.data != null && resultItem.data.length > 0) {
      thirdCodes.add(DropDownCode('', '', ''));
      for (int index = 0; index < resultItem.data.length; index++) {
        thirdCodes.add(DropDownCode(resultItem.data[index]['CD'], resultItem.data[index]['MAPPINGCD'], resultItem.data[index]['CDNM']));
      }
      selectedThirdCode = thirdCodes.first;
    } else {
      thirdCodes.add(DropDownCode('', '', ''));
      selectedThirdCode = thirdCodes.first;
    }
    showLoadingBar(false);
  }

  // 자재 리스트 조회
  void loadPartList() async {
    showLoadingBar(true);
    var response = await Net.post('/tm/service.do', {
      'SPNAME': 'APG_TM31110.INQUERY',
      'IN_CORCD': Util.USER_INFO['CORCD'],
      'IN_BIZCD': Util.USER_INFO['BIZCD'],
      'IN_PLANT_DIV': '',
      'IN_PARTNO': '${selectedFirstCode.code}${selectedFirstCode.code}${selectedSecondCode.code}${selectedFirstCode.code}${selectedSecondCode.code}${selectedThirdCode.code}',
      'IN_PARTNM': partNameController.text,
      'IN_POSNO': '',
      'IN_INPT': ''
    });
    print('${selectedFirstCode.code}${selectedSecondCode.code}${selectedThirdCode.code}');
    
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

  Widget verticalDivider = const VerticalDivider(
      color: Color.fromRGBO(190, 190, 190, 1.0),
      thickness: 0.5,
  );

  // 첫번쨰 자재 분류 combobox 위젯
  Widget firstCodeWidget() {
    return InputDecorator(
      decoration: const InputDecoration(
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.only(right: 10.0)),
      child: DropdownButton2<DropDownCode>(
        underline: const SizedBox.shrink(),
        isExpanded: true,
        icon: Icon(Icons.arrow_drop_down, color: Color.fromRGBO(0, 80, 155, 1), size: 30,),
        items: firstCodes.map((DropDownCode code) {
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
            selectedFirstCode = value!;
            loadSecondCodes();
          });
        },
        barrierColor: Colors.transparent,
        focusColor: Colors.transparent,
        selectedItemHighlightColor: Colors.transparent,
        value: selectedFirstCode,
        dropdownMaxHeight: 250,
        dropdownDecoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
        ),
        style: const TextStyle(fontSize: 17.0),
        // hint: const Text('공장구분을 선택하세요.', style: TextStyle(fontFamily: MyFontStyle.nanumGothic),),
      ),
    );
  }

  // 두번쨰 자재 분류 combobox 위젯
  Widget secondCodeWidget() {
    return InputDecorator(
      decoration: const InputDecoration(
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.only(right: 10.0)),
      child: DropdownButton2<DropDownCode>(
        underline: const SizedBox.shrink(),
        isExpanded: true,
        icon: Icon(Icons.arrow_drop_down, color: Color.fromRGBO(0, 80, 155, 1), size: 30,),
        items: secondCodes.map((DropDownCode code) {
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
            selectedSecondCode = value!;
            loadThirdCodes();
          });
        },
        barrierColor: Colors.transparent,
        focusColor: Colors.transparent,
        selectedItemHighlightColor: Colors.transparent,
        value: selectedSecondCode,
        dropdownMaxHeight: 250,
        dropdownDecoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
        ),
        style: const TextStyle(fontSize: 17.0),
        // hint: const Text('공장구분을 선택하세요.', style: TextStyle(fontFamily: MyFontStyle.nanumGothic),),
      ),
    );
  }

  // 세번째 자재 분류 combobox 위젯
  Widget thirdCodeWidget() {
    return InputDecorator(
      decoration: const InputDecoration(
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.only(right: 10.0)),
      child: DropdownButton2<DropDownCode>(
        underline: const SizedBox.shrink(),
        isExpanded: true,
        icon: Icon(Icons.arrow_drop_down, color: Color.fromRGBO(0, 80, 155, 1), size: 30,),
        items: thirdCodes.map((DropDownCode code) {
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
            selectedThirdCode = value!;
          });
        },
        barrierColor: Colors.transparent,
        focusColor: Colors.transparent,
        selectedItemHighlightColor: Colors.transparent,
        value: selectedThirdCode,
        dropdownMaxHeight: 250,
        dropdownDecoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
        ),
        style: const TextStyle(fontSize: 17.0),
        // hint: const Text('공장구분을 선택하세요.', style: TextStyle(fontFamily: MyFontStyle.nanumGothic),),
      ),
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
                // 상단 조회 조건 및 버튼 위젯
                Container(
                  margin: EdgeInsets.all(5),
                  width: MediaQuery.of(context).size.width,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(width: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Padding(padding: EdgeInsets.only(left: 10),),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Container(
                                margin: EdgeInsets.only(left: 5, top: 15),
                                child: Text('자재분류', style: TextStyle(fontSize: 18, fontFamily: MyFontStyle.nanumGothic),),
                              ),
                              Container(
                                margin: EdgeInsets.only(top: 10),
                                height: 40,
                                width: (MediaQuery.of(context).size.width - 160) / 4,
                                child: firstCodeWidget(),
                              )
                            ],
                          ),
                          Padding(padding: EdgeInsets.only(left: 5),),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Container(
                                margin: EdgeInsets.only(left: 5, top: 15),
                                child: Text('', style: TextStyle(fontSize: 18, fontFamily: MyFontStyle.nanumGothic),),
                              ),
                              Container(
                                margin: EdgeInsets.only(top: 10),
                                height: 40,
                                width: (MediaQuery.of(context).size.width - 160) / 4,
                                child: secondCodeWidget(),
                              )
                            ],
                          ),
                          Padding(padding: EdgeInsets.only(left: 5),),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Container(
                                margin: EdgeInsets.only(left: 5, top: 15),
                                child: Text('', style: TextStyle(fontSize: 18, fontFamily: MyFontStyle.nanumGothic),),
                              ),
                              Container(
                                margin: EdgeInsets.only(top: 10),
                                height: 40,
                                width: (MediaQuery.of(context).size.width - 160) / 4,
                                child: thirdCodeWidget(),
                              )
                            ],
                          ),
                          Padding(padding: EdgeInsets.only(left: 5),),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Container(
                                margin: EdgeInsets.only(left: 5, top: 15),
                                child: Text('자재명', style: TextStyle(fontSize: 18, fontFamily: MyFontStyle.nanumGothic),),
                              ),
                              Container(
                                margin: EdgeInsets.only(top: 10),
                                height: 40,
                                width: (MediaQuery.of(context).size.width - 160) / 4,
                                child: TextFormField(
                                  style: TextStyle(fontFamily: MyFontStyle.nanumGothic, fontSize: 17),
                                  textAlignVertical: TextAlignVertical.center,
                                  controller: partNameController,
                                  decoration: InputDecoration(
                                    contentPadding: const EdgeInsets.all(10),
                                    focusedBorder: const OutlineInputBorder(
                                      borderRadius: BorderRadius.horizontal(left: Radius.circular(5), right: Radius.circular(5),), 
                                      borderSide: BorderSide(color: Colors.grey)
                                    ),
                                    enabledBorder: const OutlineInputBorder(
                                      borderRadius: BorderRadius.horizontal(left: Radius.circular(5), right: Radius.circular(5),), 
                                      borderSide: BorderSide(color: Colors.grey)
                                    ),
                                  )
                                )
                              )
                            ],
                          )
                        ]
                      ),
                      Column(
                        children: <Widget>[ 
                          Container(
                            margin: EdgeInsets.only(top: 5, bottom: 5, right: 5),
                            width: 100,
                            height: 40,
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(backgroundColor: Color.fromRGBO(0, 80, 155, 1)),
                              onPressed: () async {
                                // await Navigator.push(context, MaterialPageRoute(builder: (context) => RegisterWorkInfo({})));
                              }, 
                              child: Text('초기화', style: TextStyle(color: Colors.white, fontFamily: MyFontStyle.nanumGothic, fontSize: 16),)
                            ),
                          ),
                          Container(
                            margin: EdgeInsets.only(bottom:5, right: 5),
                            width: 100,
                            height: 40,
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(backgroundColor: Color.fromRGBO(0, 80, 155, 1)),
                              onPressed: () async {
                                // 조회 조건에 맞는 보전작업 조회
                                loadPartList();
                              }, 
                              child: Text('조회', style: TextStyle(color: Colors.white, fontFamily: MyFontStyle.nanumGothic, fontSize: 16),)
                            ),
                          )
                        ]
                      )
                    ],
                  )
                ),
                // 하단 데이터 테이블 위젯, 데이터 테이블 column 데이터
                Expanded(
                  child: Theme(
                    data: Theme.of(context).copyWith(
                        dividerColor: Color.fromRGBO(190, 190, 190, 1.0)),
                    child: PaginatedDataTable2(
                      headingRowColor: MaterialStateColor.resolveWith(
                            (states) => Color.fromRGBO(0, 80, 155, 1.0)),
                      // minWidth: MediaQuery.of(context).size.width * 1.5,
                      fixedLeftColumns: 10,
                      columns: [
                        const DataColumn2(
                          label: Center(
                            child: Text('No.', 
                              style: TextStyle(
                                fontSize: 15, 
                                fontFamily: MyFontStyle.nanumGothicBold,
                                color: Colors.white))), 
                          fixedWidth: 50),
                        DataColumn2(label: verticalDivider, fixedWidth: 10),
                        const DataColumn2(
                          label: Center(
                            child: Text('자재번호', 
                              style: TextStyle(
                                fontSize: 15, 
                                fontFamily: MyFontStyle.nanumGothicBold,
                                color: Colors.white))),
                          fixedWidth: 100),
                        DataColumn2(label: verticalDivider, fixedWidth: 10),
                        const DataColumn2(
                          label: Center(
                            child: Text('자재명', 
                              style: TextStyle(
                                fontSize: 15, 
                                fontFamily: MyFontStyle.nanumGothicBold,
                                color: Colors.white)))),
                        DataColumn2(label: verticalDivider, fixedWidth: 10),
                        const DataColumn2(
                          label: Center(
                            child: Text('규격', 
                              style: TextStyle(
                                fontSize: 15, 
                                fontFamily: MyFontStyle.nanumGothicBold,
                                color: Colors.white)))),
                        DataColumn2(label: verticalDivider, fixedWidth: 10),
                        const DataColumn2(
                          label: Center(
                            child: Text('단위', 
                              style: TextStyle(
                                fontSize: 15, 
                                fontFamily: MyFontStyle.nanumGothicBold,
                                color: Colors.white))),  
                          fixedWidth: 50),
                        DataColumn2(label: verticalDivider, fixedWidth: 10),
                        const DataColumn2(
                          label: Center(
                            child: Text('재고위치', 
                              style: TextStyle(
                                fontSize: 15, 
                                fontFamily: MyFontStyle.nanumGothicBold,
                                color: Colors.white))), 
                          fixedWidth: 100),
                        DataColumn2(label: verticalDivider, fixedWidth: 10),
                        const DataColumn2(
                          label: Center(
                            child: Text('제작사', 
                              style: TextStyle(
                                fontSize: 15, 
                                fontFamily: MyFontStyle.nanumGothicBold,
                                color: Colors.white))), 
                          fixedWidth: 150),
                        DataColumn2(label: verticalDivider, fixedWidth: 10),
                        const DataColumn2(
                          label: Center(
                            child: Text('안전재고', 
                              style: TextStyle(
                                fontSize: 15, 
                                fontFamily: MyFontStyle.nanumGothicBold,
                                color: Colors.white))),  fixedWidth: 50),
                        DataColumn2(label: verticalDivider, fixedWidth: 10),
                        const DataColumn2(
                          label: Center(
                            child: Text('현재고', 
                              style: TextStyle(
                                fontSize: 15, 
                                fontFamily: MyFontStyle.nanumGothicBold,
                                color: Colors.white))),  fixedWidth: 50),
                      ],
                      showFirstLastButtons: true,
                      dataRowHeight: 40,
                      rowsPerPage: 25,
                      columnSpacing: 0,
                      horizontalMargin: 0,
                      renderEmptyRowsInTheEnd: false,
                      source: dts
                    )
                  )
                )
              ]
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
}

class DTS extends DataTableSource {
  int length = 0;
  List<dynamic> result = [];
  BuildContext context;

  DTS(workLength, workList, this.context) {
    length = workLength;
    result.addAll(workList);
  }

  Widget verticalDivider = const VerticalDivider(
      color: Colors.black,
      thickness: 0.1,
  );

  void tapOnDataCell(context, Map<String, dynamic> selectedPart) async {
    // 보전작업 조회 화면
    // await Util.pushNavigator(context, RegisterWorkInfo(selectedWork));
    Navigator.pop(context, selectedPart);
  }

  @override
  DataRow getRow(int index) {
    return DataRow2.byIndex(
      onTap: () {
        tapOnDataCell(context, result[index]);
      },
      index: index,
      cells: [
        DataCell(Align(alignment: Alignment.centerRight, child: Text((index+1).toString(), style: const TextStyle(fontSize: 15, fontFamily: MyFontStyle.nanumGothic)))),
        DataCell(verticalDivider),
        DataCell(Align(alignment: Alignment.center, child: Text(result[index]['PARTNO'], style: const TextStyle(fontSize: 15, fontFamily: MyFontStyle.nanumGothic)))),
        DataCell(verticalDivider),
        DataCell(Align(alignment: Alignment.center, child: Text(result[index]['PARTNM'], style: const TextStyle(fontSize: 15, fontFamily: MyFontStyle.nanumGothic)))),
        DataCell(verticalDivider),
        DataCell(Align(alignment: Alignment.center, child: Text(result[index]['MSIZE'].toString(), style: const TextStyle(fontSize: 15, fontFamily: MyFontStyle.nanumGothic)))),
        DataCell(verticalDivider),
        DataCell(Align(alignment: Alignment.center, child: Text(result[index]['UNIT'].toString(), style: const TextStyle(fontSize: 15, fontFamily: MyFontStyle.nanumGothic)))),
        DataCell(verticalDivider),
        DataCell(Align(alignment: Alignment.center, child: Text(result[index]['POSNO'], style: const TextStyle(fontSize: 15, fontFamily: MyFontStyle.nanumGothic)))),
        DataCell(verticalDivider),
        DataCell(Align(alignment: Alignment.center, child: Text(result[index]['MAKE_VEND'] ?? '', style: const TextStyle(fontSize: 15, fontFamily: MyFontStyle.nanumGothic)))),
        DataCell(verticalDivider),
        DataCell(Align(alignment: Alignment.center, child: Text(result[index]['SAF_INV_QTY'].toString(), style: const TextStyle(fontSize: 15, fontFamily: MyFontStyle.nanumGothic)))),
        DataCell(verticalDivider),
        DataCell(Align(alignment: Alignment.center, child: Text(result[index]['CUR_INV_QTY'].toString(), style: const TextStyle(fontSize: 15, fontFamily: MyFontStyle.nanumGothic)))),
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

class FactoryCode {
  const FactoryCode(this.code, this.name);

  final String code;
  final String name;

  @override
  String toString() {
    return '$code: $name';
  }
}