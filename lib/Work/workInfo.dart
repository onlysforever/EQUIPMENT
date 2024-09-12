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
class WorkInfo extends StatefulWidget {
  WorkInfo({super.key});

  @override
  State<WorkInfo> createState() => _WorkInfoState();
}

class _WorkInfoState extends State<WorkInfo> {
  Map<String, dynamic> factoryMap = {}; // 공장구분 combobox 
  Map<String, dynamic> bizMap = {}; // 공장구분 data map

  List<dynamic> workInfoList = []; // 보전작업 리스트
  List<FactoryCode> factoryCodes = <FactoryCode>[]; // 공장구분 code list
  List<dynamic> result = [];

  late ScrollController scrollController;
  late TextEditingController equipCodeController; // 설비코드
  late TextEditingController equipNameController; // 설비명
  late DTS dts;
  DateTime now = DateTime.now();
  late DateTime startDate;
  late DateTime endDate;

  String factoryCode = '';
  String factoryName = '';
  String lineCode = '';
  String lineName = '';
  
  bool isSearching = false;
  bool isLoading = false;


  @override
  void initState() {
    loadfactoryCodes();
    equipNameController = TextEditingController();
    dts = DTS(0, [], context);
    startDate = DateTime(now.year, now.month, 1);
    endDate = now;
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

  // 공장구분 combobox 데이터 조회
  Future<void> loadfactoryCodes() async {
    var response = await Net.post('/tm/service.do', {
      'SPNAME': 'APG_MOBILE_SUPPORT.INQUERY_BIZ_LIST',
      'IN_LANG_SET': Util.USER_INFO['IN_LANG_SET'],
    });
    var responseBody = jsonDecode(response.body);
    var result = responseBody['data'];

    factoryCodes.add(FactoryCode('DEFAULT', ''));
    factoryMap['DEFAULT'] = '';
    
    for(int index = 0; index < result.length; index++) {
      factoryCodes.add(FactoryCode(result[index]['OBJECT_ID'], result[index]['OBJECT_NM']));
      factoryMap[result[index]['OBJECT_ID']] = result[index]['OBJECT_NM'];
      bizMap[result[index]['OBJECT_ID']] = result[index]['GROUPCD'];
    }
    print(factoryMap);
    print(bizMap);
    setState(() {
      factoryCode = 'DEFAULT';
      factoryName = factoryMap['DEFAULT'];
    });
    loadWorkList();
  }

  // 보전작업 현황 조회
  void loadWorkList() async {
    showLoadingBar(true);
    var response = await Net.post('/tm/service.do', {
      'SPNAME': 'APG_MOBILE_TM21020.INQUERY_LIST',
      'IN_CORCD': Util.USER_INFO['CORCD'],
      'IN_BIZCD': factoryCode == 'DEFAULT'
        ? Util.USER_INFO['BIZCD']
        : bizMap[factoryCode],
      'IN_SDATE': '${startDate.year.toString()}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}',
      'IN_EDATE': '${endDate.year.toString()}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}',
      'IN_WORKNO': '',
      'IN_EQUIPNM': equipNameController.text.toUpperCase(),
      'IN_PLANT_DIV': factoryCode != 'DEFAULT' ? factoryCode : '',
      'IN_LANG_SET': Util.USER_INFO['IN_LANG_SET']
    });
    print('${startDate.year.toString()}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}');
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

  // 공장구분 combobox 위젯
  Widget factoryCodeWidget() {
    return InputDecorator(
      decoration: const InputDecoration(
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.only(right: 10.0)),
      child: DropdownButton2(
        underline: const SizedBox.shrink(),
        isExpanded: true,
        icon: Icon(Icons.arrow_drop_down, color: Color.fromRGBO(0, 80, 155, 1), size: 30,),
        items: factoryCodes.map((factoryCode) {
          return DropdownMenuItem(
            value: factoryCode.code,
            child: Text(
              factoryCode.name,
              style: const TextStyle(color: Colors.black, fontSize: 15.0, fontFamily: MyFontStyle.nanumGothic),
            ),
          );
        }).toList(),
        onChanged: (value) async {
          setState(() {
            factoryCode = value!;
            factoryName = factoryMap[factoryCode];
          });
          loadWorkList();
        },
        barrierColor: Colors.transparent,
        focusColor: Colors.transparent,
        selectedItemHighlightColor: Colors.transparent,
        value: factoryCode,
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
                                child: Text('작업일자', style: TextStyle(fontSize: 18, fontFamily: MyFontStyle.nanumGothic),),
                              ),
                              Row(
                                children: <Widget>[
                                  Container(
                                    margin: EdgeInsets.only(top: 10),
                                    height: 40,
                                    width: (MediaQuery.of(context).size.width - 160) / 8,
                                    child: OutlinedButton(
                                      onPressed: () async {
                                        final selectedDate = await showDatePicker(
                                          context: context,
                                          initialDate: startDate,
                                          firstDate: DateTime(2000),
                                          lastDate: DateTime.now(),
                                          helpText: '날짜를 선택하세요',
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
                                        if (selectedDate != null) {
                                          setState(() {
                                            startDate = selectedDate;
                                          });
                                        }
                                      }, 
                                      child: Text(
                                        '${startDate.year.toString()}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}',
                                        style: TextStyle(fontFamily: MyFontStyle.nanumGothic, fontSize: 15, color: Colors.black),
                                      )
                                    ),
                                  ),
                                  Container(
                                    margin: EdgeInsets.only(top: 10),
                                    height: 40,
                                    width: 30,
                                    child: Center(
                                      child: Text('~', style: TextStyle(fontFamily: MyFontStyle.nanumGothicBold, fontSize: 20),)
                                    )
                                  ),
                                  Container(
                                    margin: EdgeInsets.only(top: 10),
                                    height: 40,
                                    width: (MediaQuery.of(context).size.width - 160) / 8,
                                    child: OutlinedButton(
                                      onPressed: () async {
                                        final selectedDate = await showDatePicker(
                                          // locale: Locale('kr'),
                                          context: context,
                                          initialDate: endDate,
                                          firstDate: DateTime(2000),
                                          lastDate: DateTime.now(),
                                          helpText: '날짜를 선택하세요',
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
                                        if (selectedDate != null) {
                                          setState(() {
                                            endDate = selectedDate;
                                          });
                                        }
                                        // if (selectedDate != null) {
                                        //   setState(() {
                                        //     endDate = selectedDate;
                                        //   });
                                        // }
                                      }, 
                                      child: Text(
                                        '${endDate.year.toString()}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}',
                                        style: TextStyle(fontFamily: MyFontStyle.nanumGothic, fontSize: 15, color: Colors.black),
                                      )
                                    ),
                                  )
                                ],
                              )
                              
                            ],
                          ),
                          Padding(padding: EdgeInsets.only(left: 5),),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Container(
                                margin: EdgeInsets.only(left: 5, top: 15),
                                child: Text('공장구분', style: TextStyle(fontSize: 18, fontFamily: MyFontStyle.nanumGothic),),
                              ),
                              Container(
                                margin: EdgeInsets.only(top: 10),
                                height: 40,
                                width: (MediaQuery.of(context).size.width - 160) / 4,
                                child: factoryCodeWidget(),
                              )
                            ],
                          ),
                          Padding(padding: EdgeInsets.only(left: 5),),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Container(
                                margin: EdgeInsets.only(left: 5, top: 15),
                                child: Text('설비명', style: TextStyle(fontSize: 18, fontFamily: MyFontStyle.nanumGothic),),
                              ),
                              Container(
                                margin: EdgeInsets.only(top: 10),
                                height: 40,
                                width: (MediaQuery.of(context).size.width - 160) / 4,
                                child: TextFormField(
                                  style: TextStyle(fontFamily: MyFontStyle.nanumGothic, fontSize: 17),
                                  textAlignVertical: TextAlignVertical.center,
                                  controller: equipNameController,
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
                                await Util.pushNavigator(context, RegisterWorkInfo({}));
                                loadWorkList();
                                // await Navigator.push(context, MaterialPageRoute(builder: (context) => RegisterWorkInfo({})));
                              }, 
                              child: Text('신규 등록', style: TextStyle(color: Colors.white, fontFamily: MyFontStyle.nanumGothic, fontSize: 16),)
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
                                loadWorkList();
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
                            child: Text('작업문서번호', 
                              style: TextStyle(
                                fontSize: 15, 
                                fontFamily: MyFontStyle.nanumGothicBold,
                                color: Colors.white))),
                          size: ColumnSize.S),
                        DataColumn2(label: verticalDivider, fixedWidth: 10),
                        const DataColumn2(
                          label: Center(
                            child: Text('공장구분', 
                              style: TextStyle(
                                fontSize: 15, 
                                fontFamily: MyFontStyle.nanumGothicBold,
                                color: Colors.white))),  
                          fixedWidth: 100),
                        DataColumn2(label: verticalDivider, fixedWidth: 10),
                        const DataColumn2(
                          label: Center(
                            child: Text('보전코드', 
                              style: TextStyle(
                                fontSize: 15, 
                                fontFamily: MyFontStyle.nanumGothicBold,
                                color: Colors.white))),
                          fixedWidth: 150),
                        DataColumn2(label: verticalDivider, fixedWidth: 10),
                        const DataColumn2(
                          label: Center(
                            child: Text('보전설비', 
                              style: TextStyle(
                                fontSize: 15, 
                                fontFamily: MyFontStyle.nanumGothicBold,
                                color: Colors.white))),  
                          fixedWidth: 250),
                        DataColumn2(label: verticalDivider, fixedWidth: 10),
                        const DataColumn2(
                          label: Center(
                            child: Text('시작일시', 
                              style: TextStyle(
                                fontSize: 15, 
                                fontFamily: MyFontStyle.nanumGothicBold,
                                color: Colors.white))), 
                          fixedWidth: 150),
                        DataColumn2(label: verticalDivider, fixedWidth: 10),
                        const DataColumn2(
                          label: Center(
                            child: Text('종료일시', 
                              style: TextStyle(
                                fontSize: 15, 
                                fontFamily: MyFontStyle.nanumGothicBold,
                                color: Colors.white))), 
                          fixedWidth: 150),
                        DataColumn2(label: verticalDivider, fixedWidth: 10),
                        const DataColumn2(
                          label: Center(
                            child: Text('등록자', 
                              style: TextStyle(
                                fontSize: 15, 
                                fontFamily: MyFontStyle.nanumGothicBold,
                                color: Colors.white))),  fixedWidth: 100),
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

  void tapOnDataCell(context, Map<String, dynamic> selectedWork) async {
    print(selectedWork);
    // 보전작업 조회 화면
    await Util.pushNavigator(context, RegisterWorkInfo(selectedWork));
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
        DataCell(Align(alignment: Alignment.center, child: Text(result[index]['WORKNO'], style: const TextStyle(fontSize: 15, fontFamily: MyFontStyle.nanumGothic)))),
        DataCell(verticalDivider),
        DataCell(Align(alignment: Alignment.center, child: Text(result[index]['PLANT_DIV_NM'], style: const TextStyle(fontSize: 15, fontFamily: MyFontStyle.nanumGothic)))),
        DataCell(verticalDivider),
        DataCell(Align(alignment: Alignment.center, child: Text(result[index]['EQUIPCD'], style: const TextStyle(fontSize: 15, fontFamily: MyFontStyle.nanumGothic)))),
        DataCell(verticalDivider),
        DataCell(Text(result[index]['EQUIPNM'], style: const TextStyle(fontSize: 15, fontFamily: MyFontStyle.nanumGothic))),
        DataCell(verticalDivider),
        DataCell(Align(alignment: Alignment.center, child: Text(result[index]['START_DATE'], style: const TextStyle(fontSize: 15, fontFamily: MyFontStyle.nanumGothic)))),
        DataCell(verticalDivider),
        DataCell(Align(alignment: Alignment.center, child: Text(result[index]['END_DATE'], style: const TextStyle(fontSize: 15, fontFamily: MyFontStyle.nanumGothic)))),
        DataCell(verticalDivider),
        DataCell(Align(alignment: Alignment.center, child: Text(result[index]['REG_EMPNO'], style: const TextStyle(fontSize: 15, fontFamily: MyFontStyle.nanumGothic)))),
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