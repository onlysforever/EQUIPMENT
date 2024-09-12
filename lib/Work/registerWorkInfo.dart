import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:dual_screen/dual_screen.dart';
import 'package:flutter/material.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:pinch_zoom/pinch_zoom.dart';
import 'package:seoyoneh_equipment/Font/font.dart';
import 'package:seoyoneh_equipment/Model/ReturnObject.dart';
import 'package:seoyoneh_equipment/Util/net.dart';
import 'package:seoyoneh_equipment/Util/util.dart';
import 'package:seoyoneh_equipment/Work/partInfo.dart';

import '../QRScanner/qrScanner.dart';

// ignore: must_be_immutable
class RegisterWorkInfo extends StatefulWidget {
  RegisterWorkInfo(this.args, {super.key});
  Map<String, dynamic> args = {};

  @override
  State<RegisterWorkInfo> createState() => _RegisterWorkInfoState(args);
}

class _RegisterWorkInfoState extends State<RegisterWorkInfo> {
  Map<String, dynamic> args = {};
  _RegisterWorkInfoState(this.args);

  late ScrollController spScrollController; // startPane 스크롤 Controller(화면 기준 왼쪽)
  late ScrollController epScrollController; // endPand 스크롤 Controller(화면 기준 오른쪽)
  late TextEditingController workNoController; // 작업문서번호
  late TextEditingController equipCodeController; // 설비코드
  late TextEditingController equipNameController; // 설비명
  late TextEditingController bizNameController; // 사업장
  late TextEditingController corNameController; // 공장구분
  late TextEditingController typeTextController; // 현상
  late TextEditingController reasonTextController; // 원인
  late TextEditingController noteTextController; // 내용
  late TextEditingController issueController; // 특이사항

  List<WorkCode> workCodes = <WorkCode>[]; // 작업구분 combobox
  List<PartCode> partCodes = <PartCode>[]; // 이상부위 combobox
  List<TypeCode> typeCodes = <TypeCode>[]; // 현상 combobox
  List<ReasonCode> reasonCodes = <ReasonCode>[]; // 원인 combobox
  List<NoteCode> noteCodes = <NoteCode>[]; // 내용 combobox
  List<FactoryCode> factoryCodes = <FactoryCode>[]; // 설비코드조회 팝업 공장구분 combobox
  List<LineCode> lineCodes = <LineCode>[]; // 설비코드조회 팝업 대표라인 combobox
  List<SubLineCode> subLineCodes = <SubLineCode>[]; // 설비코드조회 팝업 라인 combobox
  List<CharCode> charCodes = <CharCode>[]; // 특이사항 특수문자 combobox
  List<dynamic> result = [];
  List<dynamic> part = [];
  List<dynamic> workerList = [];
  List<dynamic> checkedList = [];
  List<dynamic> defaultCheckedList = [];

  Map<String, dynamic> workMap = {};
  Map<String, dynamic> partMap = {};
  Map<String, dynamic> typeMap = {};
  Map<String, dynamic> reasonMap = {};
  Map<String, dynamic> noteMap = {};
  Map<String, dynamic> factoryMap = {};
  Map<String, dynamic> lineMap = {};
  Map<String, dynamic> subLineMap = {};
  Map<String, dynamic> bizMap = {};
  Map<String, dynamic> imageMap = {};
  Map<String, dynamic> charMap = {};

  String workCode = 'DEFAULT';
  String partCode = 'DEFAULT';
  String typeCode = 'DEFAULT';
  String reasonCode = 'DEFAULT';
  String noteCode = 'DEFAULT';
  String factoryCode = 'DEFAULT';
  String lineCode = 'DEFAULT';
  String subLineCode = 'DEFAULT';
  String charCode = 'DEFAULT';
  String workName = '';
  String partName = '';
  String typeName = '';
  String reasonName = '';
  String noteName = '';
  String factoryName = '';
  String lineName = '';
  String subLineName = '';
  String charName = '';
  String startTime = '';
  String endTime = '';
  String workNo = '';
  DateTime now = DateTime.now();
  late DateTime startDate;
  late DateTime startFullDate;
  late String workDate;
  late DateTime endDate;
  late DateTime endFullDate;
  TimeOfDay startTimeOfDay = TimeOfDay.now();
  TimeOfDay endTimeOfDay = TimeOfDay.now();
  late File prob1File;
  late File prob2File;
  late File solv1File;
  late File solv2File;
  late DTS dts;

  bool isProb1Empty = true;
  bool isProb2Empty = true;
  bool isSolv1Empty = true;
  bool isSolv2Empty = true;
  bool isResultEmpty = true;
  bool isPartEmpty = true;
  bool isLoading = false;


  @override
  void initState() {
    print(args);
    startDate = now;
    endDate = now;
    workDate = DateFormat('yyyyMMddHHmm').format(startDate);
    startTime = '${startTimeOfDay.hour < 10 ? '0${startTimeOfDay.hour}' : startTimeOfDay.hour}:${startTimeOfDay.minute < 10 ? '0${startTimeOfDay.minute}' : startTimeOfDay.minute}';
    endTime = '${endTimeOfDay.hour < 10 ? '0${endTimeOfDay.hour}' : endTimeOfDay.hour}:${endTimeOfDay.minute < 10 ? '0${endTimeOfDay.minute}' : endTimeOfDay.minute}';
    startFullDate = DateTime(startDate.year, startDate.month, startDate.day, startTimeOfDay.hour, startTimeOfDay.minute);
    endFullDate = DateTime(endDate.year, endDate.month, endDate.day, endTimeOfDay.hour, endTimeOfDay.minute);
    spScrollController = ScrollController();
    epScrollController = ScrollController();
    workNoController = TextEditingController();
    equipNameController = TextEditingController();
    issueController = TextEditingController();
    typeTextController = TextEditingController();
    reasonTextController = TextEditingController();
    noteTextController = TextEditingController();
    loadWorkInfo();
    // loadWorkCodes();
    // loadPartCodes();
    loadTypeCodes();
    loadReasonCodes();
    loadNoteCodes();
    loadfactoryCodes();
    loadCharCodes();
    workNo = 'D${now.year}${DateFormat('MM').format(now)}${DateFormat('dd').format(now)}-${DateFormat('HH').format(now)}${DateFormat('mm').format(now)}${DateFormat('ss').format(now)}-${DateFormat('SSS').format(now)}';
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

  // 보전작업 데이터 조회
  void loadWorkInfo() async {
    showLoadingBar(true);
    var response = await Net.post('/tm/service', {
      'SPNAME': 'APG_MOBILE_TM21020.INQUERY_HEADER',
      'IN_WORKNO': args['WORKNO'] ?? '',
      'IN_LANG_SET': Util.USER_INFO['IN_LANG_SET']
    });
    ReturnObject resultItem =
        ReturnObject.fromJsonMap(jsonDecode(response.body));
    if (resultItem.result == 'SUCCESS' &&
        resultItem.data != null &&
        resultItem.data.length > 0) {
      // setState(() {        
        
      // });
      args = resultItem.data[0];
      if(args['PROB_PHOTO_1'] != null) {
        print(args['PROB_PHOTO_1']);
        List<int> prob1IntList = args['PROB_PHOTO_1'].cast<int>().toList();
        // List<dynamic> 인거 List<int>로 변환해서 imageMap['PROB_PHOTO_1'] 에 넣음
        Uint8List prob1ByteImg = Uint8List.fromList(prob1IntList);
        args['PROB_PHOTO_1_INT'] = prob1ByteImg;
        imageMap['PROB_PHOTO_1'] = prob1IntList;
      }
      if(args['PROB_PHOTO_2'] != null) {
        print(args['PROB_PHOTO_2']);
        List<int> prob2IntList = args['PROB_PHOTO_2'].cast<int>().toList();
        // List<dynamic> 인거 List<int>로 변환해서 imageMap['PROB_PHOTO_2'] 에 넣음
        Uint8List prob2ByteImg = Uint8List.fromList(prob2IntList);
        args['PROB_PHOTO_2_INT'] = prob2ByteImg;
        imageMap['PROB_PHOTO_2'] = prob2IntList;
      }
      if(args['SOLV_PHOTO_1'] != null) {
        List<int> solv1IntList = args['SOLV_PHOTO_1'].cast<int>().toList();
        Uint8List solv1ByteImg = Uint8List.fromList(solv1IntList);
        args['SOLV_PHOTO_1_INT'] = solv1ByteImg;
        imageMap['SOLV_PHOTO_1'] = solv1IntList;
      }
      if(args['SOLV_PHOTO_2'] != null) {
        List<int> solv2IntList = args['SOLV_PHOTO_2'].cast<int>().toList();
        Uint8List solv2ByteImg = Uint8List.fromList(solv2IntList);
        args['SOLV_PHOTO_2_INT'] = solv2ByteImg;
        imageMap['SOLV_PHOTO_2'] = solv2IntList;
      }
      typeTextController.text = args['ODD_TYPE'] ?? '';
      reasonTextController.text = args['ODD_REASON'] ?? '';
      noteTextController.text = args['NOTE'] ?? '';
      issueController.text = args['ISSUE'] ?? '';
      startDate = DateFormat('yyyy-MM-dd hh:mm').parse(args['START_DATE']);
      endDate = DateFormat('yyyy-MM-dd hh:mm').parse(args['END_DATE']);
      
      startFullDate = DateTime(startDate.year, startDate.month, startDate.day, startDate.hour, startDate.minute);
      endFullDate = DateTime(endDate.year, endDate.month, endDate.day, endDate.hour, endDate.minute);
    }
    loadWorkCodes();
  }

  // 작업구분 combobox 데이터 조회
  Future<void> loadWorkCodes() async {
    var response = await Net.post('/tm/service.do', {
      'SPNAME': 'APG_MOBILE_TM21020.INQUERY_WORKCD',
      'IN_GROUPCD': 'TQ013'
    });

    ReturnObject resultItem =
        ReturnObject.fromJsonMap(jsonDecode(response.body));
    if (resultItem.result == 'SUCCESS' &&
        resultItem.data != null &&
        resultItem.data.length > 0) {
      workCodes.add(WorkCode('DEFAULT', ''));
      workMap['DEFAULT'] = '';

      for(int index = 0; index < resultItem.data.length; index++) {
        workCodes.add(WorkCode(resultItem.data[index]['CD'], resultItem.data[index]['CDNM']));
        workMap[resultItem.data[index]['CD']] = resultItem.data[index]['CDNM'];
      }
      workCode = args['WORK_DIV'] ?? 'DEFAULT';
      workName = workMap[workCode];
    } else {
      workCodes.add(WorkCode('DEFAULT', ''));
      workMap['DEFAULT'] = '';
      workCode = args['WORK_DIV'] ?? 'DEFAULT';
      workName = workMap[workCode];
    }
    loadPartCodes();
  }

  // 이상부위 combobox 데이터 조회
  Future<void> loadPartCodes() async {
    var response = await Net.post('/tm/service.do', {
      'SPNAME': 'APG_MOBILE_TM21020.INQUERY_ODDCD',
      'IN_MAPPINGCD': workCode == 'DEFAULT' ? '' : workCode.toString()
    });

    ReturnObject resultItem =
        ReturnObject.fromJsonMap(jsonDecode(response.body));
    if (resultItem.result == 'SUCCESS' &&
        resultItem.data != null &&
        resultItem.data.length > 0) {
          print(resultItem.data);
      partCodes.add(PartCode('DEFAULT', ''));
      partMap['DEFAULT'] = '';

      for(int index = 0; index < resultItem.data.length; index++) {
        partCodes.add(PartCode(resultItem.data[index]['CD'], resultItem.data[index]['CDNM']));
        partMap[resultItem.data[index]['CD']] = resultItem.data[index]['CDNM'];
      }
      setState(() {
        partCode = args['ODDCD'] ?? 'DEFAULT';
        partName = partMap[partCode];
      });
    } else {
      partCodes.add(PartCode('DEFAULT', ''));
      partMap['DEFAULT'] = '';
      setState(() {
        partCode = args['ODDCD'] ?? 'DEFAULT';
        partName = partMap[partCode];
      });
    }
    showLoadingBar(false);
  }

  // 선택된 작업 구분에 따른 이상 부위 조회
  Future<void> changePartCodes() async {
    showLoadingBar(true);
    partCodes.clear();
    partMap.clear();
    var response = await Net.post('/tm/service.do', {
      'SPNAME': 'APG_MOBILE_TM21020.INQUERY_ODDCD',
      'IN_MAPPINGCD': workCode == 'DEFAULT' ? '' : workCode.toString()
    });

    ReturnObject resultItem =
        ReturnObject.fromJsonMap(jsonDecode(response.body));
    if (resultItem.result == 'SUCCESS' &&
        resultItem.data != null &&
        resultItem.data.length > 0) {
          print(resultItem.data);
      partCodes.add(PartCode('DEFAULT', ''));
      partMap['DEFAULT'] = '';

      for(int index = 0; index < resultItem.data.length; index++) {
        partCodes.add(PartCode(resultItem.data[index]['CD'], resultItem.data[index]['CDNM']));
        partMap[resultItem.data[index]['CD']] = resultItem.data[index]['CDNM'];
      }
      setState(() {
        partCode = 'DEFAULT';
        partName = partMap[partCode];
      });
    } else {
      partCodes.add(PartCode('DEFAULT', ''));
      partMap['DEFAULT'] = '';
      setState(() {
        partCode = 'DEFAULT';
        partName = partMap[partCode];
      });
    }
    showLoadingBar(false);
  }

  // 현상 combobox 데이터 조회
  Future<void> loadTypeCodes() async {
    // var response = await http.post(Uri.parse('${Util.SERVICE_HOST}/getFactoryCode.do'), headers: {'Content-Type': 'application/json', 'AuthKey': Util.encodeAuthData}, body: jsonEncode(userInfo));
    // var response = await Net.post('/getFactoryCode.do', {});
    // var responseBody = jsonDecode(response.body);
    // var result = responseBody['data'];
    // print(result);

    typeCodes.add(TypeCode('0', ''));
    typeMap['0'] = '';
    // for(int index = 0; index < result.length; index++) {
    //   workCodes.add(WorkCode(result[index]['BIZCD'], result[index]['BIZCDNM']));
    //   workMap[result[index]['BIZCD']] = result[index]['BIZCDNM'];
    // }

    for(int index = 0; index < 5; index++) {
      typeCodes.add(TypeCode((index+1).toString(), '테스트현상'));
      typeMap[(index+1).toString()] = '테스트현상';
    }
    setState(() {
      typeCode = '0';
      typeName = '';
    });
  }

  // 원인 combobox 데이터 조회
  Future<void> loadReasonCodes() async {
    // var response = await http.post(Uri.parse('${Util.SERVICE_HOST}/getFactoryCode.do'), headers: {'Content-Type': 'application/json', 'AuthKey': Util.encodeAuthData}, body: jsonEncode(userInfo));
    // var response = await Net.post('/getFactoryCode.do', {});
    // var responseBody = jsonDecode(response.body);
    // var result = responseBody['data'];
    // print(result);

    reasonCodes.add(ReasonCode('0', ''));
    reasonMap['0'] = '';
    // for(int index = 0; index < result.length; index++) {
    //   workCodes.add(WorkCode(result[index]['BIZCD'], result[index]['BIZCDNM']));
    //   workMap[result[index]['BIZCD']] = result[index]['BIZCDNM'];
    // }

    for(int index = 0; index < 5; index++) {
      reasonCodes.add(ReasonCode((index+1).toString(), '테스트원인'));
      reasonMap[(index+1).toString()] = '테스트원인';
    }
    setState(() {
      reasonCode = '0';
      reasonName = '';
    });
  }

  // 내용 combobox 데이터 조회
  Future<void> loadNoteCodes() async {
    // var response = await http.post(Uri.parse('${Util.SERVICE_HOST}/getFactoryCode.do'), headers: {'Content-Type': 'application/json', 'AuthKey': Util.encodeAuthData}, body: jsonEncode(userInfo));
    // var response = await Net.post('/getFactoryCode.do', {});
    // var responseBody = jsonDecode(response.body);
    // var result = responseBody['data'];
    // print(result);

    noteCodes.add(NoteCode('0', ''));
    noteMap['0'] = '';
    // for(int index = 0; index < result.length; index++) {
    //   workCodes.add(WorkCode(result[index]['BIZCD'], result[index]['BIZCDNM']));
    //   workMap[result[index]['BIZCD']] = result[index]['BIZCDNM'];
    // }

    for(int index = 0; index < 5; index++) {
      noteCodes.add(NoteCode((index+1).toString(), '테스트내용'));
      noteMap[(index+1).toString()] = '테스트내용';
    }
    setState(() {
      noteCode = '0';
      noteName = '';
    });
  }

  // 설비코드조회 팝업 공장구분 combobox 데이터 조회
  Future<void> loadfactoryCodes() async {
    // showLoadingBar(true);
    var response = await Net.post('/tm/service.do', {
      'SPNAME': 'APG_MOBILE_SUPPORT.INQUERY_BIZ_LIST',
      'IN_LANG_SET': Util.USER_INFO['IN_LANG_SET'],
    });
    ReturnObject resultItem =
        ReturnObject.fromJsonMap(jsonDecode(response.body));
    factoryCodes.add(FactoryCode('DEFAULT', ''));
    factoryMap['DEFAULT'] = '';
    if (resultItem.result == 'SUCCESS' &&
        resultItem.data != null &&
        resultItem.data.length > 0) {
      for (int index = 0; index < resultItem.data.length; index++) {
        factoryCodes.add(FactoryCode(resultItem.data[index]['OBJECT_ID'],
            resultItem.data[index]['OBJECT_NM']));
        factoryMap[resultItem.data[index]['OBJECT_ID']] =
            resultItem.data[index]['OBJECT_NM'];
        bizMap[resultItem.data[index]['OBJECT_ID']] =
            resultItem.data[index]['GROUPCD'];
      }
    }
    // showLoadingBar(false);
    loadLineCodes();
  }

  // 설비코드조회 팝업 대표라인코드 데이터 조회
  Future<void> loadLineCodes() async {
    var response = await Net.post('/tm/service.do', {
      'SPNAME': 'APG_MOBILE_TM21010.INQUERY_PROC_REP_LINE',
      'IN_BIZCD': factoryCode == 'DEFAULT'
        ? Util.USER_INFO['BIZCD']
        : bizMap[factoryCode],
      'IN_CORCD': Util.USER_INFO['CORCD'],
      'IN_PLANT_DIV': factoryCode == 'DEFAULT' ? '' : factoryCode,
      'IN_LANG_SET': Util.USER_INFO['IN_LANG_SET'],
    });
    ReturnObject resultItem =
        ReturnObject.fromJsonMap(jsonDecode(response.body));
    lineCodes.add(LineCode('DEFAULT', ''));
    lineMap['DEFAULT'] = '';
    if (resultItem.result == 'SUCCESS' &&
        resultItem.data != null &&
        resultItem.data.length > 0) {
      for (int index = 0; index < resultItem.data.length; index++) {
        lineCodes.add(LineCode(resultItem.data[index]['PROC_REP_LINE'],
            resultItem.data[index]['LINENM']));
        lineMap[resultItem.data[index]['PROC_REP_LINE']] =
            resultItem.data[index]['LINENM'];
      }
    }
    loadSubLineCodes();
  }

  // 설비코드조회 팝업 선택된 공장구분에 따른 대표라인 데이터 조회
  Future<void> loadAlertLineCodes(setState) async {
    var response = await Net.post('/tm/service.do', {
      'SPNAME': 'APG_MOBILE_TM21010.INQUERY_PROC_REP_LINE',
      'IN_BIZCD': factoryCode == 'DEFAULT'
        ? Util.USER_INFO['BIZCD']
        : bizMap[factoryCode],
      'IN_CORCD': Util.USER_INFO['CORCD'],
      'IN_PLANT_DIV': factoryCode == 'DEFAULT' ? '' : factoryCode,
      'IN_LANG_SET': Util.USER_INFO['IN_LANG_SET'],
    });
    ReturnObject resultItem =
        ReturnObject.fromJsonMap(jsonDecode(response.body));
    lineCodes.add(LineCode('DEFAULT', ''));
    lineMap['DEFAULT'] = '';
    if (resultItem.result == 'SUCCESS' &&
        resultItem.data != null &&
        resultItem.data.length > 0) {
      for (int index = 0; index < resultItem.data.length; index++) {
        lineCodes.add(LineCode(resultItem.data[index]['PROC_REP_LINE'],
            resultItem.data[index]['LINENM']));
        lineMap[resultItem.data[index]['PROC_REP_LINE']] =
            resultItem.data[index]['LINENM'];
      }
    }
    setState(() {
      lineCode = 'DEFAULT';
      lineName = '';
    });
  }

  // 설비코드조회 팝업 라인코드 데이터 조회
  Future<void> loadSubLineCodes() async {
    var response = await Net.post('/tm/service', {
      'SPNAME': 'APG_MOBILE_TM21010.INQUERY_LINE',
      'IN_BIZCD': factoryCode == 'DEFAULT'
        ? Util.USER_INFO['BIZCD']
        : bizMap[factoryCode],
      'IN_CORCD': Util.USER_INFO['CORCD'],
      'IN_PROC_REP_LINE': lineCode != 'DEFAULT' ? lineCode : '',
      'IN_PLANT_DIV': factoryCode == 'DEFAULT' ? '' : factoryCode,
      'IN_LANG_SET': Util.USER_INFO['IN_LANG_SET'],
    });
    ReturnObject resultItem = ReturnObject.fromJsonMap(jsonDecode(response.body));
    subLineCodes.add(SubLineCode('DEFAULT', ''));
    subLineMap['DEFAULT'] = '';
    if (resultItem.result == 'SUCCESS' && resultItem.data != null && resultItem.data.length > 0) {
      print('LOAD SUB LINE CODE SUCCESS');
      print(resultItem.data.length);
      for (int index = 0; index < resultItem.data.length; index++) {
        subLineCodes.add(SubLineCode(resultItem.data[index]['LINECD'],
            resultItem.data[index]['LINENM']));
        subLineMap[resultItem.data[index]['LINECD']] =
            resultItem.data[index]['LINENM'];
      }
    }
  }

  // 설비코드조회 팝업 선택된 대표라인에 따른 라인 데이터 조회
  Future<void> loadAlertSubLineCodes(setState) async {
    var response = await Net.post('/tm/service', {
      'SPNAME': 'APG_MOBILE_TM21010.INQUERY_LINE',
      'IN_BIZCD': factoryCode == 'DEFAULT'
        ? Util.USER_INFO['BIZCD']
        : bizMap[factoryCode],
      'IN_CORCD': Util.USER_INFO['CORCD'],
      'IN_PROC_REP_LINE': lineCode != 'DEFAULT' ? lineCode : '',
      'IN_PLANT_DIV': factoryCode == 'DEFAULT' ? '' : factoryCode,
      'IN_LANG_SET': Util.USER_INFO['IN_LANG_SET'],
    });
    ReturnObject resultItem = ReturnObject.fromJsonMap(jsonDecode(response.body));
    subLineCodes.add(SubLineCode('DEFAULT', ''));
    subLineMap['DEFAULT'] = '';
    if (resultItem.result == 'SUCCESS' && resultItem.data != null && resultItem.data.length > 0) {
      print('LOAD SUB LINE CODE SUCCESS');
      print(resultItem.data.length);
      for (int index = 0; index < resultItem.data.length; index++) {
        subLineCodes.add(SubLineCode(resultItem.data[index]['LINECD'],
            resultItem.data[index]['LINENM']));
        subLineMap[resultItem.data[index]['LINECD']] =
            resultItem.data[index]['LINENM'];
      }
    }
    setState(() {
      subLineCode = 'DEFAULT';
      subLineName = '';
    });
  }

  // 특이사항 입력 란 특수문자 combobox 위젯
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

  // 설비코드조회 팝업 설비 리스트 조회
  void loadEquipmentList(setState) async {
    var response = await Net.post('/tm/service.do', {
      'SPNAME': 'APG_MOBILE_TM21010.INQUERY_LIST',
      'IN_BIZCD': factoryCode == 'DEFAULT'
          ? Util.USER_INFO['BIZCD']
          : bizMap[factoryCode],
      'IN_CORCD': Util.USER_INFO['CORCD'],
      'IN_EQUIPCD': '',
      'IN_EQUIPNM': equipNameController.text.toUpperCase(),
      'IN_LINECD': subLineCode != 'DEFAULT' ? subLineCode : '',
      'IN_PROC_REP_LINE': lineCode != 'DEFAULT' ? lineCode : '',
      'IN_DIR_LINE_YN': 'N',
      'IN_PLANT_DIV': factoryCode != 'DEFAULT' ? factoryCode : '',
      'IN_LANG_SET': Util.USER_INFO['IN_LANG_SET'],
      'IN_CHK_TYPE': 'CM'
    });
    ReturnObject resultItem =
        ReturnObject.fromJsonMap(jsonDecode(response.body));
    if (resultItem.result == 'SUCCESS' &&
        resultItem.data != null &&
        resultItem.data.length > 0) {
      setState(() {
        result = resultItem.data;
        isResultEmpty = false;
        dts = DTS(resultItem.data.length, resultItem.data, context);
      });
    } else {
      setState(() {
        result = resultItem.data;
        isResultEmpty = false;
        dts = DTS(resultItem.data.length, resultItem.data, context);
      });
    }
  }

  // 자재출고내역 데이터 조회
  void loadPartList(setState) async {
    var response = await Net.post('/tm/service.do', {
      'SPNAME': 'APG_MOBILE_TM21020.INQUERY_DETAIL',
      'IN_WORKNO': args['WORKNO'] ?? workNo
    });
    ReturnObject resultItem = ReturnObject.fromJsonMap(jsonDecode(response.body));
    if (resultItem.result == 'SUCCESS' &&
        resultItem.data != null &&
        resultItem.data.length > 0) {
      setState(() {
        part = resultItem.data;
        isPartEmpty = false;
      });
    } else {
      setState(() {
        isPartEmpty = false;
      });
    }
  }

  // 작업구분 combobox 위젯
  Widget workCodeWidget() {
    return InputDecorator(
      decoration: const InputDecoration(
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.only(right: 10.0)),
      child: DropdownButton2(
        underline: const SizedBox.shrink(),
        isExpanded: true,
        icon: Icon(Icons.arrow_drop_down, color: Color.fromRGBO(0, 80, 155, 1), size: 30,),
        items: workCodes.map((workCode) {
          return DropdownMenuItem(
            value: workCode.code,
            child: Text(
              workCode.name,
              style: const TextStyle(color: Colors.black, fontSize: 18.0, fontFamily: MyFontStyle.nanumGothic),
            ),
          );
        }).toList(),
        onChanged: (value) async {
          setState(() {
            workCode = value!;
            workName = workMap[workCode];
            partCode = 'DEFAULT';
            partName = '';
          });
          changePartCodes();
        },
        barrierColor: Colors.transparent,
        focusColor: Colors.transparent,
        selectedItemHighlightColor: Colors.transparent,
        value: workCode,
        dropdownMaxHeight: 250,
        dropdownDecoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
        ),
        style: const TextStyle(fontSize: 17.0),
      ),
    );
  }

  // 이상부위 combobox 위젯
  Widget partCodeWidget() {
    return InputDecorator(
      decoration: const InputDecoration(
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.only(right: 10.0)),
      child: DropdownButton2(
        underline: const SizedBox.shrink(),
        isExpanded: true,
        icon: Icon(Icons.arrow_drop_down, color: Color.fromRGBO(0, 80, 155, 1), size: 30,),
        items: partCodes.map((partCode) {
          return DropdownMenuItem(
            value: partCode.code,
            child: Text(
              partCode.name,
              style: const TextStyle(color: Colors.black, fontSize: 18.0, fontFamily: MyFontStyle.nanumGothic),
            ),
          );
        }).toList(),
        onChanged: (value) async {
          setState(() {
            partCode = value!;
            partName = partMap[partCode];
          });
        },
        barrierColor: Colors.transparent,
        focusColor: Colors.transparent,
        selectedItemHighlightColor: Colors.transparent,
        value: partCode,
        dropdownMaxHeight: 250,
        dropdownDecoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
        ),
        style: const TextStyle(fontSize: 17.0),
      ),
    );
  }

  // 현상 combobox 위젯
  Widget typeCodeWidget() {
    return InputDecorator(
      decoration: const InputDecoration(
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.only(right: 10.0)),
      child: DropdownButton2(
        underline: const SizedBox.shrink(),
        isExpanded: true,
        icon: Icon(Icons.arrow_drop_down, color: Color.fromRGBO(0, 80, 155, 1), size: 30,),
        items: typeCodes.map((typeCode) {
          return DropdownMenuItem(
            value: typeCode.code,
            child: Text(
              typeCode.name,
              style: const TextStyle(color: Colors.black, fontSize: 18.0, fontFamily: MyFontStyle.nanumGothic),
            ),
          );
        }).toList(),
        onChanged: (value) async {
          setState(() {
            typeCode = value!;
            typeName = typeMap[typeCode];
          });
        },
        barrierColor: Colors.transparent,
        focusColor: Colors.transparent,
        selectedItemHighlightColor: Colors.transparent,
        value: typeCode,
        dropdownMaxHeight: 250,
        dropdownDecoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
        ),
        style: const TextStyle(fontSize: 17.0),
      ),
    );
  }

  // 원인 combobox 위젯
  Widget reasonCodeWidget() {
    return InputDecorator(
      decoration: const InputDecoration(
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.only(right: 10.0)),
      child: DropdownButton2(
        underline: const SizedBox.shrink(),
        isExpanded: true,
        icon: Icon(Icons.arrow_drop_down, color: Color.fromRGBO(0, 80, 155, 1), size: 30,),
        items: reasonCodes.map((reasonCode) {
          return DropdownMenuItem(
            value: reasonCode.code,
            child: Text(
              reasonCode.name,
              style: const TextStyle(color: Colors.black, fontSize: 18.0, fontFamily: MyFontStyle.nanumGothic),
            ),
          );
        }).toList(),
        onChanged: (value) async {
          setState(() {
            reasonCode = value!;
            reasonName = reasonMap[reasonCode];
          });
        },
        barrierColor: Colors.transparent,
        focusColor: Colors.transparent,
        selectedItemHighlightColor: Colors.transparent,
        value: reasonCode,
        dropdownMaxHeight: 250,
        dropdownDecoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
        ),
        style: const TextStyle(fontSize: 17.0),
      ),
    );
  }

  // 내용 combobox 위젯
  Widget noteCodeWidget() {
    return InputDecorator(
      decoration: const InputDecoration(
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.only(right: 10.0)),
      child: DropdownButton2(
        underline: const SizedBox.shrink(),
        isExpanded: true,
        icon: Icon(Icons.arrow_drop_down, color: Color.fromRGBO(0, 80, 155, 1), size: 30,),
        items: noteCodes.map((noteCode) {
          return DropdownMenuItem(
            value: noteCode.code,
            child: Text(
              noteCode.name,
              style: const TextStyle(color: Colors.black, fontSize: 18.0, fontFamily: MyFontStyle.nanumGothic),
            ),
          );
        }).toList(),
        onChanged: (value) async {
          setState(() {
            noteCode = value!;
            noteName = noteMap[noteCode];
          });
        },
        barrierColor: Colors.transparent,
        focusColor: Colors.transparent,
        selectedItemHighlightColor: Colors.transparent,
        value: noteCode,
        dropdownMaxHeight: 250,
        dropdownDecoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
        ),
        style: const TextStyle(fontSize: 17.0),
      ),
    );
  }

  // 설비코드조회 팝업 공장구분 combobox 위젯
  Widget factoryCodeWidget(setState) {
    return InputDecorator(
      decoration: const InputDecoration(
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
        items: factoryCodes.map((factoryCode) {
          return DropdownMenuItem(
            value: factoryCode.code,
            child: Text(
              factoryCode.name,
              style: const TextStyle(
                  color: Colors.black,
                  fontSize: 15.0,
                  fontFamily: MyFontStyle.nanumGothic),
            ),
          );
        }).toList(),
        onChanged: (value) async {
          setState(() {
            factoryCode = value!;
            factoryName = factoryMap[factoryCode];
            lineCodes.clear();
            lineMap.clear();
            subLineCodes.clear();
            subLineMap.clear();
            lineCode = 'DEFAULT';
            lineName = '';
            subLineCode = 'DEFAULT';
            subLineName = '';
          });
          loadAlertLineCodes(setState);
          loadAlertSubLineCodes(setState);
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
      ),
    );
  }

  // 설비코드조회 팝업 대표라인 combobox 위젯
  Widget lineCodeWidget(setState) {
    return InputDecorator(
      decoration: const InputDecoration(
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
        items: lineCodes.map((lineCode) {
          return DropdownMenuItem(
            value: lineCode.code,
            child: Text(
              lineCode.name,
              style: const TextStyle(
                  color: Colors.black,
                  fontSize: 15.0,
                  fontFamily: MyFontStyle.nanumGothic),
            ),
          );
        }).toList(),
        onChanged: (value) async {
          setState(() {
            lineCode = value!;
            lineName = lineMap[lineCode];
            subLineCodes.clear();
            subLineMap.clear();
            subLineCode = 'DEFAULT';
            subLineName = '';
          });
          loadAlertSubLineCodes(setState);
        },
        barrierColor: Colors.transparent,
        focusColor: Colors.transparent,
        selectedItemHighlightColor: Colors.transparent,
        value: lineCode,
        dropdownMaxHeight: 250,
        dropdownDecoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
        ),
        style: const TextStyle(fontSize: 17.0),
      ),
    );
  }

  // 설비코드조회 팝업 라인 combobox 위젯
  Widget subLineCodeWidget(setState) {
    return InputDecorator(
      decoration: const InputDecoration(
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
        items: subLineCodes.map((subLineCode) {
          return DropdownMenuItem(
            value: subLineCode.code,
            child: Text(
              subLineCode.name,
              style: const TextStyle(
                  color: Colors.black,
                  fontSize: 15.0,
                  fontFamily: MyFontStyle.nanumGothic),
            ),
          );
        }).toList(),
        onChanged: (value) async {
          setState(() {
            subLineCode = value!;
            subLineName = subLineMap[subLineCode];
          });
        },
        barrierColor: Colors.transparent,
        focusColor: Colors.transparent,
        selectedItemHighlightColor: Colors.transparent,
        value: subLineCode,
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
          setState(() {
            issueController.text = issueController.text + charMap[value];
          });
          print(value);
          print(issueController.text);
          print(charMap[value]);
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

  // 자재출고내역 팝업 자재 수량 입력 input form 위젯
  Widget inputFormField(String text, TextEditingController controller) {
    return TextFormField(
        controller: controller,
        keyboardType: TextInputType.number,
        style: TextStyle(
          fontFamily: MyFontStyle.nanumGothicBold,
          fontSize: 13,
        ),
        textAlignVertical: TextAlignVertical.center,
        textAlign: TextAlign.center,
        cursorColor: Color.fromRGBO(110, 110, 110, 1.0),
        decoration: InputDecoration(
          hintText: text,
          hintStyle: const TextStyle(color: Color.fromRGBO(190, 190, 190, 1), fontFamily: MyFontStyle.nanumGothic, fontSize: 15, overflow: TextOverflow.ellipsis),
          contentPadding: const EdgeInsets.only(top:5),
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

  Widget verticalDivider = const VerticalDivider(
      color: Colors.black,
      thickness: 0.1,
  );

  void showSelectDialog() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
          title: SizedBox(
            width: 150,
            height: 30,
            child: Image.asset('images/SEOYONEH_CI.png')
          ),
          content: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              SizedBox(
                width: 170,
                height: 170,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(backgroundColor: Colors.white, side: BorderSide(color: Color.fromRGBO(0, 80, 155, 1), width: 2.5)),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Image.asset('images/tool_menu.png', width: 80, height: 110,),
                      Text('검색', style: TextStyle(fontSize: 23, color: Color.fromRGBO(0, 80, 155, 1), fontFamily: MyFontStyle.nanumGothicBold),),
                    ]
                  ),
                  onPressed: () async {
                    // 설비 검색
                    Navigator.pop(context);
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (BuildContext context) {
                        return StatefulBuilder(builder: (context, StateSetter setState) {
                          if(result.isEmpty && isResultEmpty) {
                            print('LOAD FACTORY AND EQUIPMENT LIST');
                            loadEquipmentList(setState);
                            // Net.post('/tm/equipmentMaster.do', {
                            //   'SPNAME': 'APG_MOBILE_TM21010.INQUERY_LIST',
                            //   'IN_BIZCD': Util.USER_INFO['BIZCD'],
                            //   'IN_CORCD': Util.USER_INFO['CORCD'],
                            //   'IN_EQUIPCD': '',
                            //   'IN_EQUIPNM': '',
                            //   'IN_LINECD': '',
                            //   'IN_PROC_REP_LINE': '',
                            //   'IN_DIR_LINE_YN': 'N',
                            //   'IN_PLANT_DIV': '',
                            //   'IN_LANG_SET': Util.USER_INFO['IN_LANG_SET'],
                            // }).then((response) {
                            //   var responseBody = jsonDecode(response.body);
                            //   setState(() {
                            //     result = responseBody['data'];
                            //     isResultEmpty = false;
                            //     int length = result.length;
                            //     dts = DTS(length, result, context);
                            //   });
                            //   print(result);
                            // });
                          }
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
                                  )
                                )
                              ],
                            ),
                            content: Container(
                              padding: EdgeInsets.only(bottom: 10),
                              width: MediaQuery.of(context).size.width * 0.9,
                              height: MediaQuery.of(context).size.height * 0.8,
                              child: Column(
                                children: <Widget>[
                                  Row(
                                    children: <Widget>[
                                      Expanded(
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.start,
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: <Widget>[
                                            Container(
                                              margin: EdgeInsets.only(left: 5),
                                              child: Text('공장구분', style: TextStyle(fontSize: 18, fontFamily: MyFontStyle.nanumGothic),),
                                            ),
                                            Container(
                                              margin: EdgeInsets.only(top: 5, bottom: 10),
                                              height: 38,
                                              child: factoryCodeWidget(setState)
                                            )
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
                                              child: Text('대표라인', style: TextStyle(fontSize: 18, fontFamily: MyFontStyle.nanumGothic),),
                                            ),
                                            Container(
                                              margin: EdgeInsets.only(top: 5, left: 5, bottom: 10),
                                              height: 38,
                                              child: lineCodeWidget(setState)
                                            )
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
                                              child: Text('라인', style: TextStyle(fontSize: 18, fontFamily: MyFontStyle.nanumGothic),),
                                            ),
                                            Container(
                                              margin: EdgeInsets.only(top: 5, left: 5, bottom: 10),
                                              height: 38,
                                              child: subLineCodeWidget(setState)
                                            )
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
                                              child: Text('설비명', style: TextStyle(fontSize: 18, fontFamily: MyFontStyle.nanumGothic),),
                                            ),
                                            Container(
                                              margin: EdgeInsets.only(top: 5, left: 5, bottom: 10),
                                              height: 38,
                                              child: TextFormField(
                                                cursorColor: Color.fromRGBO(110, 110, 110, 1.0),
                                                style: TextStyle(
                                                    fontFamily: MyFontStyle.nanumGothic,
                                                    fontSize: 17),
                                                textAlignVertical: TextAlignVertical.center,
                                                controller: equipNameController,
                                                decoration: InputDecoration(
                                                  contentPadding:
                                                      const EdgeInsets.all(10),
                                                  focusedBorder:
                                                      const OutlineInputBorder(
                                                          borderRadius: BorderRadius.horizontal(
                                                            left: Radius.circular(5),
                                                            right: Radius.circular(5),
                                                          ),
                                                          borderSide: BorderSide(color: Colors.grey)),
                                                  enabledBorder:
                                                      const OutlineInputBorder(
                                                          borderRadius:
                                                              BorderRadius.horizontal(
                                                            left: Radius.circular(5),
                                                            right: Radius.circular(5),
                                                          ),
                                                          borderSide: BorderSide(
                                                              color: Colors.grey)),
                                                ))
                                            )
                                          ],
                                        ),
                                      ),
                                      Container(
                                        margin: EdgeInsets.only(bottom:5, left: 10, top: 20),
                                        width: 100,
                                        height: 40,
                                        child: OutlinedButton(
                                          style: OutlinedButton.styleFrom(backgroundColor: Color.fromRGBO(0, 80, 155, 1)),
                                          onPressed: () async {
                                            setState(() {
                                              isResultEmpty = true;
                                            });
                                            loadEquipmentList(setState);
                                          }, 
                                          child: Text('조회', style: TextStyle(color: Colors.white, fontFamily: MyFontStyle.nanumGothic, fontSize: 16),)
                                        ),
                                      ),
                                    ],
                                  ),
                                  isResultEmpty
                                    ? Expanded(
                                        child: Center(
                                          child: CircularProgressIndicator(
                                            color: Color.fromRGBO(110, 110, 110, 1.0),
                                            strokeWidth: 5.0,
                                          )
                                        )
                                      )
                                    : Expanded(
                                        child: Stack(
                                          children: <Widget>[
                                            Theme(
                                              data: Theme.of(context).copyWith(
                                                  dividerColor: Color.fromRGBO(190, 190, 190, 1.0)),
                                              child: PaginatedDataTable2(
                                                minWidth: MediaQuery.of(context).size.width,
                                                columns: [
                                                  const DataColumn2(label: Center(child: Text('공장코드', style: TextStyle(fontSize: 15, fontFamily: MyFontStyle.nanumGothic))), fixedWidth: 100),
                                                  DataColumn2(label: verticalDivider, fixedWidth: 10),
                                                  const DataColumn2(label: Center(child: Text('대표라인', style: TextStyle(fontSize: 15, fontFamily: MyFontStyle.nanumGothic)))),
                                                  DataColumn2(label: verticalDivider, fixedWidth: 10),
                                                  const DataColumn2(label: Center(child: Text('설비명', style: TextStyle(fontSize: 15, fontFamily: MyFontStyle.nanumGothic)))),
                                                  DataColumn2(label: verticalDivider, fixedWidth: 10),
                                                  const DataColumn2(label: Center(child: Text('규격', style: TextStyle(fontSize: 15, fontFamily: MyFontStyle.nanumGothic))), fixedWidth: 150),
                                                  DataColumn2(label: verticalDivider, fixedWidth: 10),
                                                  const DataColumn2(label: Center(child: Text('중량', style: TextStyle(fontSize: 15, fontFamily: MyFontStyle.nanumGothic))), fixedWidth: 50),
                                                  DataColumn2(label: verticalDivider, fixedWidth: 10),
                                                  const DataColumn2(label: Center(child: Text('제작사', style: TextStyle(fontSize: 15, fontFamily: MyFontStyle.nanumGothic))), fixedWidth: 150),
                                                  DataColumn2(label: verticalDivider, fixedWidth: 10),
                                                  const DataColumn2(label: Center(child: Text('관리담당자', style: TextStyle(fontSize: 15, fontFamily: MyFontStyle.nanumGothic))), fixedWidth: 80),
                                                  DataColumn2(label: verticalDivider, fixedWidth: 10),
                                                  const DataColumn2(label: Center(child: Text('설비코드', style: TextStyle(fontSize: 15, fontFamily: MyFontStyle.nanumGothic))), ),
                                                ],
                                                showFirstLastButtons: true,
                                                dataRowHeight: 40,
                                                rowsPerPage: 25,
                                                columnSpacing: 0,
                                                horizontalMargin: 0,
                                                renderEmptyRowsInTheEnd: false,
                                                source: dts
                                              )
                                            ),
                                          ],
                                        )
                                      )
                                ],
                              )
                            ),
                          );
                        });
                      });
                    // Navigator.push(context, MaterialPageRoute(builder: (context) => ToolInfo(userInfo)));
                  },
                )
              ),
              Padding(padding: EdgeInsets.symmetric(horizontal: 10),),
              SizedBox(
                width: 170,
                height: 170,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(backgroundColor: Colors.white, side: BorderSide(color: Color.fromRGBO(0, 80, 155, 1), width: 2.5)),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Image.asset('images/camera.png', width: 80, height: 110,),
                      Text('QR', style: TextStyle(fontSize: 23, color: Color.fromRGBO(0, 80, 155, 1), fontFamily: MyFontStyle.nanumGothicBold),),
                    ]
                  ),
                  onPressed: () async {
                    // QR리딩 실행
                    Navigator.pop(context);
                    var result = await Util.pushNavigator(context, QRScanner(type: 'equipment', subType: ''));
                    print(result);
                    setState(() {
                      args['EQUIPCD'] = result['EQUIPCD'];
                      args['EQUIPNM'] = result['EQUIPNM'];
                    });
                    // Navigator.push(context, MaterialPageRoute(builder: (context) => ToolInfo(userInfo)));
                  },
                )
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              style: TextButton.styleFrom(
                textStyle: const TextStyle(
                    color: Colors.white, 
                    fontFamily: MyFontStyle.nanumGothic),
                foregroundColor: Colors.white,
                backgroundColor: Color.fromRGBO(0, 80, 155, 1),
                shape: RoundedRectangleBorder(
                  side: const BorderSide(
                    color: Colors.transparent,
                    width: 1,
                    style: BorderStyle.solid
                  ),
                  borderRadius: BorderRadius.circular(30)
                )
              ),
              autofocus: true,
              child: Container(
                padding: EdgeInsets.all(5),
                child: Text("닫기", style: TextStyle(fontSize: 16, fontFamily: MyFontStyle.nanumGothic)),
              ),
              onPressed: () {
                Navigator.pop(context);
              },
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
            child: TwoPane(
              paneProportion: 0.7,
              startPane: Flex(
                direction: Axis.vertical,
                children: [
                  Flexible(
                    flex: 90,
                    child: Container(
                    padding: EdgeInsets.only(top: 35, left: 10, right: 10),
                    child: SingleChildScrollView(
                      child: Column(
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Container(
                                    margin: EdgeInsets.only(left: 5, top: 15),
                                    child: Text('작업문서번호', style: TextStyle(fontSize: 18, fontFamily: MyFontStyle.nanumGothic),),
                                  ),
                                  Container(
                                    margin: EdgeInsets.only(top: 10),
                                    width: (MediaQuery.of(context).size.width * 0.7) / 3,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: Colors.black12,
                                      border: Border.all(width: 0.2),
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                    child: Center(
                                      child: Text(args['WORKNO'] ?? workNo, style: TextStyle(fontFamily: MyFontStyle.nanumGothic, fontSize: 18),)
                                    )
                                  )
                                ],
                              ),
                              Padding(padding: EdgeInsets.symmetric(horizontal: 5),),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Container(
                                      margin: EdgeInsets.only(left: 5, top: 15),
                                      child: Text('설비코드', style: TextStyle(fontSize: 18, fontFamily: MyFontStyle.nanumGothic),),
                                    ),
                                    Row(
                                      children: <Widget>[
                                        InkWell(
                                          onTap: () {
                                            showSelectDialog();
                                          },
                                          child: Container(
                                            margin: EdgeInsets.only(top: 10),
                                            width: (MediaQuery.of(context).size.width * 0.7) / 4,
                                            height: 40,
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              border: Border.all(width: 0.2),
                                              borderRadius: BorderRadius.circular(5),
                                            ),
                                            child: Center(
                                              child: Text(args['EQUIPCD'] ?? '', style: TextStyle(fontFamily: MyFontStyle.nanumGothic, fontSize: 18),)
                                            )
                                          )
                                        ),
                                        Expanded(
                                          child: InkWell(
                                            onTap: () {
                                              // QR or 설비 목록 검색할 수 있는 dialog
                                              showSelectDialog();
                                            },
                                            child: Container(
                                              margin: EdgeInsets.only(top: 10, left: 5),
                                              padding: EdgeInsets.symmetric(horizontal: 10),
                                              height: 40,
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                border: Border.all(width: 0.2),
                                                borderRadius: BorderRadius.circular(5),
                                              ),
                                              child: Center(
                                                child: Text(args['EQUIPNM'] ?? '', style: TextStyle(fontFamily: MyFontStyle.nanumGothic, fontSize: 18), overflow: TextOverflow.ellipsis, maxLines: 1)
                                              ),
                                            )
                                          ),
                                        )
                                        
                                      ],
                                    )
                                  ],
                                )
                              )
                            ],
                          ),
                          Row(
                            children: <Widget>[
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Container(
                                      margin: EdgeInsets.only(left: 5, top: 15),
                                      child: Text('대표라인', style: TextStyle(fontSize: 18, fontFamily: MyFontStyle.nanumGothic),),
                                    ),
                                    Container(
                                      margin: EdgeInsets.only(top: 10),
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        border: Border.all(width: 0.2),
                                        borderRadius: BorderRadius.circular(5),
                                      ),
                                      child: Center(
                                        child: Text(args['PROC_REP_LINE_NM'] ?? '', style: TextStyle(fontFamily: MyFontStyle.nanumGothic, fontSize: 18),)
                                      )
                                    )
                                  ],
                                ),
                              ),
                              Padding(padding: EdgeInsets.symmetric(horizontal: 5),),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Container(
                                      margin: EdgeInsets.only(left: 5, top: 15),
                                      child: Text('라인', style: TextStyle(fontSize: 18, fontFamily: MyFontStyle.nanumGothic),),
                                    ),
                                    Container(
                                      margin: EdgeInsets.only(top: 10),
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        border: Border.all(width: 0.2),
                                        borderRadius: BorderRadius.circular(5),
                                      ),
                                      child: Center(
                                        child: Text(args['LINENM'] ?? '', style: TextStyle(fontFamily: MyFontStyle.nanumGothic, fontSize: 18),)
                                      )
                                    )
                                  ],
                                )
                              )
                            ],
                          ),
                          Row(
                            children: <Widget>[
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Container(
                                      margin: EdgeInsets.only(left: 5, top: 15),
                                      child: Text('작업시작시간', style: TextStyle(fontSize: 18, fontFamily: MyFontStyle.nanumGothic),),
                                    ),
                                    Container(
                                      margin: EdgeInsets.only(top: 10),
                                      width: 230,
                                      height: 40,
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
                                          if(selectedDate != null) {
                                            final time = await showTimePicker(
                                              context: context,
                                              initialTime: startTimeOfDay,
                                              initialEntryMode: TimePickerEntryMode.inputOnly,
                                              helpText: '',
                                              hourLabelText: '시',
                                              minuteLabelText: '분',
                                              confirmText: '확인',
                                              cancelText: '취소',
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
                                            if (time != null) {
                                              setState(() {
                                                startDate = selectedDate;
                                                startTime = '${time.hour < 10 ? '0${time.hour}' : time.hour}:${time.minute < 10 ? '0${time.minute}' : time.minute}';
                                                args['START_DATE'] = '${startDate.year.toString()}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')} $startTime';
                                                startFullDate = DateTime(startDate.year, startDate.month, startDate.day, time.hour, time.minute);
                                              });
                                            }
                                          }
                                        }, 
                                        child: Text(
                                          args['START_DATE'] ??
                                          '${startDate.year.toString()}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')} $startTime',
                                          style: TextStyle(fontFamily: MyFontStyle.nanumGothic, fontSize: 17, color: Colors.black),
                                        )
                                      ),
                                    )
                                  ],
                                ),
                              ),
                              Padding(padding: EdgeInsets.symmetric(horizontal: 5),),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Container(
                                      margin: EdgeInsets.only(left: 5, top: 15),
                                      child: Text('작업종료시간', style: TextStyle(fontSize: 18, fontFamily: MyFontStyle.nanumGothic),),
                                    ),
                                    Container(
                                      margin: EdgeInsets.only(top: 10),
                                      width: 230,
                                      height: 40,
                                      child: OutlinedButton(
                                        onPressed: () async {
                                          final selectedDate = await showDatePicker(
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
                                          if(selectedDate != null) {
                                            final time = await showTimePicker(
                                              context: context,
                                              initialTime: endTimeOfDay,
                                              initialEntryMode: TimePickerEntryMode.inputOnly,
                                              helpText: '',
                                              hourLabelText: '시',
                                              minuteLabelText: '분',
                                              confirmText: '확인',
                                              cancelText: '취소',
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
                                            if (time != null) {
                                              setState(() {
                                                endDate = selectedDate;
                                                endTime = '${time.hour < 10 ? '0${time.hour}' : time.hour}:${time.minute < 10 ? '0${time.minute}' : time.minute}';
                                                args['END_DATE'] = '${endDate.year.toString()}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')} $endTime';
                                                endFullDate = DateTime(endDate.year, endDate.month, endDate.day, time.hour, time.minute);
                                              });
                                            }
                                          }
                                        }, 
                                        child: Text(
                                          args['END_DATE'] ??
                                          '${endDate.year.toString()}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')} $endTime',
                                          style: TextStyle(fontFamily: MyFontStyle.nanumGothic, fontSize: 17, color: Colors.black),
                                        )
                                      ),
                                    )
                                  ],
                                ),
                              ),
                              Padding(padding: EdgeInsets.symmetric(horizontal: 5),),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Container(
                                    margin: EdgeInsets.only(left: 5, top: 15),
                                    child: Text('사업장', style: TextStyle(fontSize: 18, fontFamily: MyFontStyle.nanumGothic),),
                                  ),
                                  Container(
                                    margin: EdgeInsets.only(top: 10),
                                    width: (MediaQuery.of(context).size.width * 0.7) / 5,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: Colors.black12,
                                      border: Border.all(width: 0.2),
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                    child: Center(
                                      child: Text(args['BIZNM'] ?? '', style: TextStyle(fontFamily: MyFontStyle.nanumGothic, fontSize: 18),)
                                    )
                                  )
                                ],
                              ),
                              Padding(padding: EdgeInsets.symmetric(horizontal: 5),),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Container(
                                    margin: EdgeInsets.only(left: 5, top: 15),
                                    child: Text('공장구분', style: TextStyle(fontSize: 18, fontFamily: MyFontStyle.nanumGothic),),
                                  ),
                                  Container(
                                    margin: EdgeInsets.only(top: 10),
                                    width: (MediaQuery.of(context).size.width * 0.7) / 5,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: Colors.black12,
                                      border: Border.all(width: 0.2),
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                    child: Center(
                                      child: Text(args['PLANT_DIV_NM'] ?? '', style: TextStyle(fontFamily: MyFontStyle.nanumGothic, fontSize: 18),)
                                    )
                                  )
                                ],
                              )
                            ],
                          ),
                          Row(
                            children: <Widget>[
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Container(
                                    margin: EdgeInsets.only(left: 5, top: 15),
                                    child: Text('투입공수(M/H)', style: TextStyle(fontSize: 18, fontFamily: MyFontStyle.nanumGothic),),
                                  ),
                                  Container(
                                    margin: EdgeInsets.only(top: 10),
                                    width: 120,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: Colors.black12,
                                      border: Border.all(width: 0.2),
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                    child: Center(
                                      child: Text(args['WORK_MH']?.toString() ?? '', style: TextStyle(fontFamily: MyFontStyle.nanumGothic, fontSize: 18),)
                                    )
                                  )
                                ],
                              ),
                              Padding(padding: EdgeInsets.symmetric(horizontal: 5),),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Container(
                                    margin: EdgeInsets.only(left: 5, top: 15),
                                    child: Text('투입인원', style: TextStyle(fontSize: 18, fontFamily: MyFontStyle.nanumGothic),),
                                  ),
                                  Container(
                                    margin: EdgeInsets.only(top: 10),
                                    width: 75,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: Colors.black12,
                                      border: Border.all(width: 0.2),
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                    child: Center(
                                      child: Text(args['WORKNUM']?.toString() ?? '', style: TextStyle(fontFamily: MyFontStyle.nanumGothic, fontSize: 18),)
                                    )
                                  )
                                ],
                              ),
                              Padding(padding: EdgeInsets.symmetric(horizontal: 5),),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Container(
                                    margin: EdgeInsets.only(left: 5, top: 15),
                                    child: Text('작업시간(분)', style: TextStyle(fontSize: 18, fontFamily: MyFontStyle.nanumGothic),),
                                  ),
                                  Container(
                                    margin: EdgeInsets.only(top: 10),
                                    width: 100,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: Colors.black12,
                                      border: Border.all(width: 0.2),
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                    child: Center(
                                      child: Text(args['WORK_TIME']?.toString() ?? '', style: TextStyle(fontFamily: MyFontStyle.nanumGothic, fontSize: 18),)
                                    )
                                  )
                                ],
                              ),
                              Padding(padding: EdgeInsets.symmetric(horizontal: 5),),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Container(
                                      margin: EdgeInsets.only(left: 5, top: 15),
                                      child: Text('작업구분', style: TextStyle(fontSize: 18, fontFamily: MyFontStyle.nanumGothic),),
                                    ),
                                    Container(
                                      margin: EdgeInsets.only(top: 10),
                                      height: 40,
                                      child: workCodeWidget()
                                    )
                                  ],
                                ),
                              ),
                              Padding(padding: EdgeInsets.symmetric(horizontal: 5),),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Container(
                                      margin: EdgeInsets.only(left: 5, top: 15),
                                      child: Text('이상부위', style: TextStyle(fontSize: 18, fontFamily: MyFontStyle.nanumGothic),),
                                    ),
                                    Container(
                                      margin: EdgeInsets.only(top: 10),
                                      height: 40,
                                      child: partCodeWidget()
                                    )
                                  ],
                                )
                              )
                            ],
                          ),
                          Row(
                            children: <Widget>[
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Container(
                                      margin: EdgeInsets.only(left: 5, top: 15),
                                      child: Text('현상', style: TextStyle(fontSize: 18, fontFamily: MyFontStyle.nanumGothic),),
                                    ),
                                    Container(
                                      margin: EdgeInsets.only(top: 10),
                                      height: 40,
                                      child: typeCodeWidget()
                                    )
                                  ],
                                ),
                              ),
                              Padding(padding: EdgeInsets.symmetric(horizontal: 5),),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Container(
                                      margin: EdgeInsets.only(left: 5, top: 15),
                                      child: Text('원인', style: TextStyle(fontSize: 18, fontFamily: MyFontStyle.nanumGothic),),
                                    ),
                                    Container(
                                      margin: EdgeInsets.only(top: 10),
                                      height: 40,
                                      child: reasonCodeWidget()
                                    )
                                  ],
                                ),
                              ),
                              Padding(padding: EdgeInsets.symmetric(horizontal: 5),),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Container(
                                      margin: EdgeInsets.only(left: 5, top: 15),
                                      child: Text('내용', style: TextStyle(fontSize: 18, fontFamily: MyFontStyle.nanumGothic),),
                                    ),
                                    Container(
                                      margin: EdgeInsets.only(top: 10),
                                      height: 40,
                                      child: noteCodeWidget()
                                    )
                                  ],
                                ),
                              )
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Container(
                                margin: EdgeInsets.only(left: 5, top: 15),
                                child: Text('현상', style: TextStyle(fontSize: 18, fontFamily: MyFontStyle.nanumGothicBold, color: Color.fromRGBO(110, 110, 110, 1)),),
                              ),
                              Container(
                                  margin: EdgeInsets.only(top: 10),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    border: Border.all(width: 0.2),
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  child: TextFormField(
                                    maxLines: 2,
                                    style: TextStyle(fontFamily: MyFontStyle.nanumGothic, fontSize: 18),
                                    textAlignVertical: TextAlignVertical.center,
                                    controller: typeTextController,
                                    decoration: InputDecoration(
                                      border: InputBorder.none,
                                      contentPadding: const EdgeInsets.all(10),
                                      // focusedBorder: const OutlineInputBorder(
                                      //   borderRadius: BorderRadius.horizontal(left: Radius.circular(5), right: Radius.circular(5),), 
                                      //   borderSide: BorderSide(color: Colors.grey)
                                      // ),
                                      // enabledBorder: const OutlineInputBorder(
                                      //   borderRadius: BorderRadius.horizontal(left: Radius.circular(5), right: Radius.circular(5),), 
                                      //   borderSide: BorderSide(color: Colors.grey)
                                      // ),
                                    )
                                  )
                                )
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Container(
                                margin: EdgeInsets.only(left: 5, top: 15),
                                child: Text('원인', style: TextStyle(fontSize: 18, fontFamily: MyFontStyle.nanumGothicBold, color: Color.fromRGBO(110, 110, 110, 1)),),
                              ),
                              Container(
                                  margin: EdgeInsets.only(top: 10),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    border: Border.all(width: 0.2),
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  child: TextFormField(
                                    maxLines: 2,
                                    style: TextStyle(fontFamily: MyFontStyle.nanumGothic, fontSize: 18),
                                    textAlignVertical: TextAlignVertical.center,
                                    controller: reasonTextController,
                                    decoration: InputDecoration(
                                      border: InputBorder.none,
                                      contentPadding: const EdgeInsets.all(10),
                                      // focusedBorder: const OutlineInputBorder(
                                      //   borderRadius: BorderRadius.horizontal(left: Radius.circular(5), right: Radius.circular(5),), 
                                      //   borderSide: BorderSide(color: Colors.grey)
                                      // ),
                                      // enabledBorder: const OutlineInputBorder(
                                      //   borderRadius: BorderRadius.horizontal(left: Radius.circular(5), right: Radius.circular(5),), 
                                      //   borderSide: BorderSide(color: Colors.grey)
                                      // ),
                                    )
                                  )
                                )
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Container(
                                margin: EdgeInsets.only(left: 5, top: 15),
                                child: Text('내용', style: TextStyle(fontSize: 18, fontFamily: MyFontStyle.nanumGothicBold, color: Color.fromRGBO(110, 110, 110, 1)),),
                              ),
                              Container(
                                  margin: EdgeInsets.only(top: 10),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    border: Border.all(width: 0.2),
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  child: TextFormField(
                                    maxLines: 2,
                                    style: TextStyle(fontFamily: MyFontStyle.nanumGothic, fontSize: 18),
                                    textAlignVertical: TextAlignVertical.center,
                                    controller: noteTextController,
                                    decoration: InputDecoration(
                                      border: InputBorder.none,
                                      contentPadding: const EdgeInsets.all(10),
                                      // focusedBorder: const OutlineInputBorder(
                                      //   borderRadius: BorderRadius.horizontal(left: Radius.circular(5), right: Radius.circular(5),), 
                                      //   borderSide: BorderSide(color: Colors.grey)
                                      // ),
                                      // enabledBorder: const OutlineInputBorder(
                                      //   borderRadius: BorderRadius.horizontal(left: Radius.circular(5), right: Radius.circular(5),), 
                                      //   borderSide: BorderSide(color: Colors.grey)
                                      // ),
                                    )
                                  )
                                )
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Container(
                                margin: EdgeInsets.only(left: 5, top: 10),
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
                              Container(
                                  margin: EdgeInsets.only(top: 10),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    border: Border.all(width: 0.2),
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  child: TextFormField(
                                    maxLines: 8,
                                    style: TextStyle(fontFamily: MyFontStyle.nanumGothic, fontSize: 18),
                                    textAlignVertical: TextAlignVertical.center,
                                    controller: issueController,
                                    decoration: InputDecoration(
                                      border: InputBorder.none,
                                      contentPadding: const EdgeInsets.all(10),
                                      // focusedBorder: const OutlineInputBorder(
                                      //   borderRadius: BorderRadius.horizontal(left: Radius.circular(5), right: Radius.circular(5),), 
                                      //   borderSide: BorderSide(color: Colors.grey)
                                      // ),
                                      // enabledBorder: const OutlineInputBorder(
                                      //   borderRadius: BorderRadius.horizontal(left: Radius.circular(5), right: Radius.circular(5),), 
                                      //   borderSide: BorderSide(color: Colors.grey)
                                      // ),
                                    )
                                  )
                                )
                            ],
                          ),
                        ],
                      )
                    )
                  )
                  ),
                  Flexible(
                    flex: 10,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: <Widget>[
                        Container(
                          width: MediaQuery.of(context).size.width * 0.1,
                          margin: EdgeInsets.only(left: 5, right: 10, bottom: 10, top: 10),
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(backgroundColor: Color.fromRGBO(0, 80, 155, 1)),
                            onPressed: () async {
                              if(workerList.isEmpty) {
                                showLoadingBar(true);
                                var response1 = await Net.post('/tm/service', {
                                  'SPNAME': 'APG_MOBILE_TM21020.INQUERY_WORKER_LIST',
                                  'IN_CORCD': Util.USER_INFO['CORCD'],
                                  'IN_BIZCD': Util.USER_INFO['BIZCD'],
                                });
                                ReturnObject resultItem1 = ReturnObject.fromJsonMap(jsonDecode(response1.body));
                                print(resultItem1.data);
                                workerList = resultItem1.data;
                                
                                List<dynamic> workEmpnoList = [];
                                var response2 = await Net.post('/tm/service', {
                                  'SPNAME': 'APG_MOBILE_TM21020.INQUERY_WORKER',
                                  'IN_WORKNO': args['WORKNO'] ?? workNo
                                });
                                ReturnObject resultItem2 = ReturnObject.fromJsonMap(jsonDecode(response2.body));
                                workEmpnoList = resultItem2.data;

                                if(workEmpnoList.isNotEmpty) {
                                  for(int checkIndex = 0; checkIndex < workEmpnoList.length; checkIndex++) {
                                    for(int workerIndex = 0; workerIndex < workerList.length; workerIndex++) {
                                      if(workerList[workerIndex]['WORK_EMPNO'] == workEmpnoList[checkIndex]['WORK_EMPNO']) {
                                        workerList[workerIndex]['CHECK'] = true;
                                        checkedList.add(workerIndex);
                                        defaultCheckedList.add(workerIndex);
                                        break;
                                      }
                                    }
                                  }
                                }
                                showLoadingBar(false);
                              }

                              showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder: (BuildContext context) {
                                  return PinchZoom(
                                    child: Util.ShowWorkerPopup(context, workerList, checkedList, (callbackWorkerList, callbackCheckedList) {
                                      setState(() {
                                        workerList = callbackWorkerList;
                                        checkedList = callbackCheckedList;
                                      });
                                      Navigator.pop(context);
                                    })
                                  );
                                }
                              );
                              // Navigator.pop(context);
                            }, 
                            child: Text('작업자 정보', style: TextStyle(color: Colors.white, fontFamily: MyFontStyle.nanumGothic, fontSize: 16),)
                          ),
                        ),
                        Container(
                          width: MediaQuery.of(context).size.width * 0.11,
                          margin: EdgeInsets.only(left: 5, right: 10, bottom: 10, top: 10),
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(backgroundColor: Color.fromRGBO(0, 80, 155, 1)),
                            onPressed: () async {
                              showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder: (BuildContext context) {
                                  return PinchZoom(
                                    child: StatefulBuilder(builder: ((context, setState) {
                                      if(part.isEmpty && isPartEmpty) {
                                        loadPartList(setState);
                                      }
                                    
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
                                                var response = await Util.pushNavigator(context, PartInfo(args));
                                                if(response != null) {
                                                  setState(() {
                                                    part.add(response);
                                                  });
                                                }
                                              }, 
                                              child: Text('추가', style: TextStyle(color: Colors.white, fontFamily: MyFontStyle.nanumGothic, fontSize: 16),)
                                            )
                                          ],
                                        ),
                                        content: isPartEmpty
                                          ? Expanded(
                                              child: Center(
                                                child: CircularProgressIndicator(
                                                  color: Color.fromRGBO(110, 110, 110, 1.0),
                                                  strokeWidth: 5.0,
                                                )
                                              )
                                            )
                                          : Container(
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
                                                    const DataColumn2(label: Center(child: Text('일련번호', style: TextStyle(fontSize: 15, color: Colors.white, fontFamily: MyFontStyle.nanumGothicBold))), fixedWidth: 60),
                                                    DataColumn2(label: verticalDivider, fixedWidth: 10),
                                                    const DataColumn2(label: Center(child: Text('자재번호', style: TextStyle(fontSize: 15, color: Colors.white, fontFamily: MyFontStyle.nanumGothicBold))), fixedWidth: 120),
                                                    DataColumn2(label: verticalDivider, fixedWidth: 10),
                                                    const DataColumn2(label: Center(child: Text('자재명', style: TextStyle(fontSize: 15, color: Colors.white, fontFamily: MyFontStyle.nanumGothicBold)))),
                                                    DataColumn2(label: verticalDivider, fixedWidth: 10),
                                                    const DataColumn2(label: Center(child: Text('규격', style: TextStyle(fontSize: 15, color: Colors.white, fontFamily: MyFontStyle.nanumGothicBold)))),
                                                    DataColumn2(label: verticalDivider, fixedWidth: 10),
                                                    const DataColumn2(label: Center(child: Text('현재고', style: TextStyle(fontSize: 15, color: Colors.white, fontFamily: MyFontStyle.nanumGothicBold))), fixedWidth: 50),
                                                    DataColumn2(label: verticalDivider, fixedWidth: 10),
                                                    const DataColumn2(label: Center(child: Text('수량', style: TextStyle(fontSize: 15, color: Colors.white, fontFamily: MyFontStyle.nanumGothicBold))), fixedWidth: 50),
                                                    DataColumn2(label: verticalDivider, fixedWidth: 10),
                                                    const DataColumn2(label: Center(child: Text('금액', style: TextStyle(fontSize: 15, color: Colors.white, fontFamily: MyFontStyle.nanumGothicBold))), fixedWidth: 100),
                                                  ],
                                                  dataRowHeight: 40,
                                                  columnSpacing: 0,
                                                  showBottomBorder: true,
                                                  horizontalMargin: 0,
                                                  rows: List.generate(
                                                    part.length, (index) {
                                                      if(part[index]['INPUT_CONTROLLER'] == null) {
                                                        part[index]['INPUT_CONTROLLER'] = TextEditingController();
                                                        if(part[index]['QTY'] == null) {
                                                          part[index]['INPUT_CONTROLLER'].text = '1';
                                                        } else {
                                                          part[index]['INPUT_CONTROLLER'].text = part[index]['QTY'].toString();
                                                        }
                                                      }
                                                      
                                                      return DataRow(cells: [
                                                        DataCell(Center(child: Text('${index+1}', style: TextStyle(fontSize: 15, fontFamily: MyFontStyle.nanumGothic)))),
                                                        DataCell(verticalDivider),
                                                        DataCell(Center(child: Text(part[index]['PARTNO'] ?? '', style: TextStyle(fontSize: 15, fontFamily: MyFontStyle.nanumGothic)))),
                                                        DataCell(verticalDivider),
                                                        DataCell(Center(child: Text(part[index]['PARTNM'] ?? '', style: TextStyle(fontSize: 15, fontFamily: MyFontStyle.nanumGothic)))),
                                                        DataCell(verticalDivider),
                                                        DataCell(Center(child: Text(part[index]['MSIZE'] ?? '', style: TextStyle(fontSize: 15, fontFamily: MyFontStyle.nanumGothic)))),
                                                        DataCell(verticalDivider),
                                                        DataCell(Center(child: Text(part[index]['CUR_INV_QTY'].toString(), style: TextStyle(fontSize: 15, fontFamily: MyFontStyle.nanumGothic)))),
                                                        DataCell(verticalDivider),
                                                        DataCell(Center(child: Padding(padding: EdgeInsets.symmetric(vertical: 5), child: inputFormField(part[index]['INPUT_CONTROLLER'].text, part[index]['INPUT_CONTROLLER'])))),
                                                        DataCell(verticalDivider),
                                                        DataCell(Center(child: Text(part[index]['UCOST'].toString(), style: TextStyle(fontSize: 15, fontFamily: MyFontStyle.nanumGothic)))),
                                                      ]);
                                                    }
                                                  ),
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
                                            onPressed: () => Navigator.pop(context),
                                          )
                                        ],
                                      );
                                    }))
                                  );
                                }
                              );
                            }, 
                            child: Text('자재출고 내역', style: TextStyle(color: Colors.white, fontFamily: MyFontStyle.nanumGothic, fontSize: 16),)
                          ),
                        ),
                      ],
                    )
                  )
                ],
              ),
              endPane: SingleChildScrollView(
                controller: epScrollController,
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.3,
                  height: MediaQuery.of(context).size.height,
                  child: Column(
                    children: <Widget>[
                      Container(
                        margin: EdgeInsets.only(top: 35, left: 10, right: 10, bottom: 10),
                        height: MediaQuery.of(context).size.height * 0.85,
                        child: Column(
                          children: <Widget>[
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Container(
                                    margin: EdgeInsets.only(left: 5, top: 15),
                                    child: Text('현상', style: TextStyle(fontSize: 18, fontFamily: MyFontStyle.nanumGothic),),
                                  ),
                                  Row(
                                    children: <Widget>[
                                      Expanded(
                                        child: Column(
                                          children: <Widget>[
                                            InkWell(
                                              child: Container(
                                                height: (MediaQuery.of(context).size.height / 4),
                                                margin: EdgeInsets.only(top: 10, right: 5),
                                                padding: EdgeInsets.all(10),
                                                decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  border: Border.all(width: 0.2),
                                                  borderRadius: BorderRadius.circular(10),
                                                ),
                                                child: Center(
                                                  child: args['PROB_PHOTO_1'] != null
                                                    ? Image.memory(args['PROB_PHOTO_1_INT'])
                                                    : isProb1Empty
                                                      ? Text('첨부된 사진 없음')
                                                      : Image.file(prob1File)
                                                )
                                              ),
                                              onTap: () async {
                                                // 첨부된 이미지가 있을 경우 해당 이미지 확대 표시
                                                if(args['PROB_PHOTO_1'] != null || !isProb1Empty) {
                                                  showDialog(
                                                    context: context,
                                                    barrierDismissible: false,
                                                    builder: (BuildContext context) {
                                                      return AlertDialog(
                                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
                                                        title: SizedBox(
                                                          width: 150,
                                                          height: 30,
                                                          child: Image.asset('images/SEOYONEH_CI.png')
                                                        ),
                                                        content: Container(
                                                          width: MediaQuery.of(context).size.width * 0.7,
                                                          height: MediaQuery.of(context).size.height * 0.7,
                                                          child: isProb1Empty 
                                                            ? Image.memory(args['PROB_PHOTO_1_INT'])
                                                            : Image.file(prob1File),
                                                        ),
                                                        actions: <Widget>[
                                                          TextButton(
                                                            style: TextButton.styleFrom(
                                                              textStyle: const TextStyle(
                                                                  color: Colors.white, 
                                                                  fontFamily: MyFontStyle.nanumGothic),
                                                              foregroundColor: Colors.white,
                                                              backgroundColor: Color.fromRGBO(0, 80, 155, 1),
                                                              shape: RoundedRectangleBorder(
                                                                side: const BorderSide(
                                                                  color: Colors.transparent,
                                                                  width: 1,
                                                                  style: BorderStyle.solid
                                                                ),
                                                                borderRadius: BorderRadius.circular(30)
                                                              )
                                                            ),
                                                            autofocus: true,
                                                            child: Container(
                                                              padding: EdgeInsets.all(5),
                                                              child: Text("닫기", style: TextStyle(fontSize: 16, fontFamily: MyFontStyle.nanumGothicBold)),
                                                            ),
                                                            onPressed: () {
                                                              Navigator.pop(context);
                                                            },
                                                          )
                                                        ],
                                                      );
                                                    }
                                                  );
                                                }
                                              },
                                            ),
                                            Container(
                                              width: MediaQuery.of(context).size.width * 0.1,
                                              margin: EdgeInsets.only(left: 10, right: 10),
                                              padding: EdgeInsets.only(top: 5),
                                              child: OutlinedButton(
                                                style: OutlinedButton.styleFrom(backgroundColor: Colors.black12),
                                                onPressed: () async {
                                                  showDialog(
                                                    context: context,
                                                    barrierDismissible: false,
                                                    builder: (BuildContext context) {
                                                      return AlertDialog(
                                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
                                                        title: SizedBox(
                                                          width: 150,
                                                          height: 30,
                                                          child: Image.asset('images/SEOYONEH_CI.png')
                                                        ),
                                                        content: Row(
                                                          mainAxisAlignment: MainAxisAlignment.center,
                                                          children: <Widget>[
                                                            SizedBox(
                                                              width: 170,
                                                              height: 170,
                                                              child: OutlinedButton(
                                                                style: OutlinedButton.styleFrom(backgroundColor: Colors.white, side: BorderSide(color: Color.fromRGBO(0, 80, 155, 1), width: 2.5)),
                                                                child: Column(
                                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                                  crossAxisAlignment: CrossAxisAlignment.center,
                                                                  children: [
                                                                    Image.asset('images/camera.png', width: 80, height: 110,),
                                                                    Text('카메라', style: TextStyle(fontSize: 23, color: Color.fromRGBO(0, 80, 155, 1), fontFamily: MyFontStyle.nanumGothicBold),),
                                                                  ]
                                                                ),
                                                                onPressed: () {
                                                                  // 카메라 실행
                                                                  Navigator.pop(context);
                                                                  ImagePicker().pickImage(source: ImageSource.camera).then((image) {
                                                                    if(image != null) {
                                                                      GallerySaver.saveImage(image.path).then((value) {
                                                                        print(image.path);
                                                                        print(value);
                                                                        setState(() {
                                                                          isProb1Empty = false;
                                                                          prob1File = File(image.path);  
                                                                          imageMap['PROB1_IMG_PATH'] = prob1File.path;
                                                                          imageMap['PROB1_IMG_NM'] = image.name;
                                                                        });
                                                                      });
                                                                    }
                                                                  });
                                                                  // Navigator.push(context, MaterialPageRoute(builder: (context) => ToolInfo(userInfo)));
                                                                },
                                                              )
                                                            ),
                                                            Padding(padding: EdgeInsets.symmetric(horizontal: 10),),
                                                            SizedBox(
                                                              width: 170,
                                                              height: 170,
                                                              child: OutlinedButton(
                                                                style: OutlinedButton.styleFrom(backgroundColor: Colors.white, side: BorderSide(color: Color.fromRGBO(0, 80, 155, 1), width: 2.0)),
                                                                child: Column(
                                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                                  crossAxisAlignment: CrossAxisAlignment.center,
                                                                  children: [
                                                                    Image.asset('images/gallery.png', width: 80, height: 110,),
                                                                    Text('앨범', style: TextStyle(fontSize: 23, color: Color.fromRGBO(0, 80, 155, 1), fontFamily: MyFontStyle.nanumGothicBold),),
                                                                  ]
                                                                ),
                                                                onPressed: () async {
                                                                  // 앨범에서 사진 선택
                                                                  Navigator.pop(context);
                                                                  ImagePicker picker = ImagePicker();
                                                                  XFile? prob1Image = await picker.pickImage(source: ImageSource.gallery);
                                                                  if(prob1Image != null) {
                                                                    setState(() {
                                                                      isProb1Empty = false;
                                                                      prob1File = File(prob1Image.path);  
                                                                      imageMap['PROB1_IMG_PATH'] = prob1File.path;
                                                                      imageMap['PROB1_IMG_NM'] = prob1Image.name;
                                                                    });
                                                                  }
                                                                  // Navigator.push(context, MaterialPageRoute(builder: (context) => ToolInfo(userInfo)));
                                                                },
                                                              )
                                                            ),
                                                          ],
                                                        ),
                                                        actions: <Widget>[
                                                          TextButton(
                                                            style: TextButton.styleFrom(
                                                              textStyle: const TextStyle(
                                                                  color: Colors.white, 
                                                                  fontFamily: MyFontStyle.nanumGothic),
                                                              foregroundColor: Colors.white,
                                                              backgroundColor: Color.fromRGBO(0, 80, 155, 1),
                                                              shape: RoundedRectangleBorder(
                                                                side: const BorderSide(
                                                                  color: Colors.transparent,
                                                                  width: 1,
                                                                  style: BorderStyle.solid
                                                                ),
                                                                borderRadius: BorderRadius.circular(30)
                                                              )
                                                            ),
                                                            autofocus: true,
                                                            child: Container(
                                                              padding: EdgeInsets.all(5),
                                                              child: Text("닫기", style: TextStyle(fontSize: 16, fontFamily: MyFontStyle.nanumGothicBold)),
                                                            ),
                                                            onPressed: () {
                                                              Navigator.pop(context);
                                                            },
                                                          )
                                                        ],
                                                      );
                                                    });
                                                },
                                                child: Text(
                                                  '사진 첨부',
                                                  style: TextStyle(color: Colors.black, fontFamily: MyFontStyle.nanumGothic, fontSize: 16),
                                                )
                                              ),
                                            )
                                          ],
                                        )
                                      ),
                                      Expanded(
                                        child: Column(
                                          children: <Widget>[
                                            InkWell(
                                              child: Container(
                                                height: (MediaQuery.of(context).size.height / 4),
                                                margin: EdgeInsets.only(top: 10, left: 5),
                                                padding: EdgeInsets.all(10),
                                                decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  border: Border.all(width: 0.2),
                                                  borderRadius: BorderRadius.circular(10),
                                                ),
                                                child: Center(
                                                  child: args['PROB_PHOTO_2'] != null
                                                    ? Image.memory(args['PROB_PHOTO_2_INT'])
                                                    : isProb2Empty
                                                      ? Text('첨부된 사진 없음')
                                                      : Image.file(prob2File)
                                                )
                                              ),
                                              onTap: () async {
                                                if(args['PROB_PHOTO_2'] != null || !isProb2Empty) {
                                                  showDialog(
                                                    context: context,
                                                    barrierDismissible: false,
                                                    builder: (BuildContext context) {
                                                      return AlertDialog(
                                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
                                                        title: SizedBox(
                                                          width: 150,
                                                          height: 30,
                                                          child: Image.asset('images/SEOYONEH_CI.png')
                                                        ),
                                                        content: Container(
                                                          width: MediaQuery.of(context).size.width * 0.7,
                                                          height: MediaQuery.of(context).size.height * 0.7,
                                                          child: isProb1Empty 
                                                            ? Image.memory(args['PROB_PHOTO_2_INT'])
                                                            : Image.file(prob2File),
                                                        ),
                                                        actions: <Widget>[
                                                          TextButton(
                                                            style: TextButton.styleFrom(
                                                              textStyle: const TextStyle(
                                                                  color: Colors.white, 
                                                                  fontFamily: MyFontStyle.nanumGothic),
                                                              foregroundColor: Colors.white,
                                                              backgroundColor: Color.fromRGBO(0, 80, 155, 1),
                                                              shape: RoundedRectangleBorder(
                                                                side: const BorderSide(
                                                                  color: Colors.transparent,
                                                                  width: 1,
                                                                  style: BorderStyle.solid
                                                                ),
                                                                borderRadius: BorderRadius.circular(30)
                                                              )
                                                            ),
                                                            autofocus: true,
                                                            child: Container(
                                                              padding: EdgeInsets.all(5),
                                                              child: Text("닫기", style: TextStyle(fontSize: 16, fontFamily: MyFontStyle.nanumGothicBold)),
                                                            ),
                                                            onPressed: () {
                                                              Navigator.pop(context);
                                                            },
                                                          )
                                                        ],
                                                      );
                                                    }
                                                  );
                                                }
                                              },
                                            ),
                                            Container(
                                              width: MediaQuery.of(context).size.width * 0.1,
                                              margin: EdgeInsets.only(left: 10, right: 10),
                                              padding: EdgeInsets.only(top: 5),
                                              child: OutlinedButton(
                                                style: OutlinedButton.styleFrom(backgroundColor: Colors.black12),
                                                onPressed: () async {
                                                  showDialog(
                                                    context: context,
                                                    barrierDismissible: false,
                                                    builder: (BuildContext context) {
                                                      return AlertDialog(
                                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
                                                        title: SizedBox(
                                                          width: 150,
                                                          height: 30,
                                                          child: Image.asset('images/SEOYONEH_CI.png')
                                                        ),
                                                        content: Row(
                                                          mainAxisAlignment: MainAxisAlignment.center,
                                                          children: <Widget>[
                                                            SizedBox(
                                                              width: 170,
                                                              height: 170,
                                                              child: OutlinedButton(
                                                                style: OutlinedButton.styleFrom(backgroundColor: Colors.white, side: BorderSide(color: Color.fromRGBO(0, 80, 155, 1), width: 2.5)),
                                                                child: Column(
                                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                                  crossAxisAlignment: CrossAxisAlignment.center,
                                                                  children: [
                                                                    Image.asset('images/camera.png', width: 80, height: 110,),
                                                                    Text('카메라', style: TextStyle(fontSize: 23, color: Color.fromRGBO(0, 80, 155, 1), fontFamily: MyFontStyle.nanumGothicBold),),
                                                                  ]
                                                                ),
                                                                onPressed: () {
                                                                  // 카메라 실행
                                                                  Navigator.pop(context);
                                                                  ImagePicker().pickImage(source: ImageSource.camera).then((image) {
                                                                    if(image != null) {
                                                                      GallerySaver.saveImage(image.path).then((value) {
                                                                        print(image.path);
                                                                        print(value);
                                                                        setState(() {
                                                                          isProb2Empty = false;
                                                                          prob2File = File(image.path);  
                                                                          imageMap['PROB2_IMG_PATH'] = prob2File.path;
                                                                          imageMap['PROB2_IMG_NM'] = image.name;
                                                                        });
                                                                      });
                                                                    }
                                                                  });
                                                                  // Navigator.push(context, MaterialPageRoute(builder: (context) => ToolInfo(userInfo)));
                                                                },
                                                              )
                                                            ),
                                                            Padding(padding: EdgeInsets.symmetric(horizontal: 10),),
                                                            SizedBox(
                                                              width: 170,
                                                              height: 170,
                                                              child: OutlinedButton(
                                                                style: OutlinedButton.styleFrom(backgroundColor: Colors.white, side: BorderSide(color: Color.fromRGBO(0, 80, 155, 1), width: 2.0)),
                                                                child: Column(
                                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                                  crossAxisAlignment: CrossAxisAlignment.center,
                                                                  children: [
                                                                    Image.asset('images/gallery.png', width: 80, height: 110,),
                                                                    Text('앨범', style: TextStyle(fontSize: 23, color: Color.fromRGBO(0, 80, 155, 1), fontFamily: MyFontStyle.nanumGothicBold),),
                                                                  ]
                                                                ),
                                                                onPressed: () async {
                                                                  // 앨범에서 사진 선택
                                                                  Navigator.pop(context);
                                                                  ImagePicker picker = ImagePicker();
                                                                  XFile? prob2Image = await picker.pickImage(source: ImageSource.gallery);
                                                                  if(prob2Image != null) {
                                                                    setState(() {
                                                                      isProb2Empty = false;
                                                                      prob2File = File(prob2Image.path);  
                                                                      imageMap['PROB2_IMG_PATH'] = prob2File.path;
                                                                      imageMap['PROB2_IMG_NM'] = prob2Image.name;
                                                                    });
                                                                  }
                                                                  // Navigator.push(context, MaterialPageRoute(builder: (context) => ToolInfo(userInfo)));
                                                                },
                                                              )
                                                            ),
                                                          ],
                                                        ),
                                                        actions: <Widget>[
                                                          TextButton(
                                                            style: TextButton.styleFrom(
                                                              textStyle: const TextStyle(
                                                                  color: Colors.white, 
                                                                  fontFamily: MyFontStyle.nanumGothic),
                                                              foregroundColor: Colors.white,
                                                              backgroundColor: Color.fromRGBO(0, 80, 155, 1),
                                                              shape: RoundedRectangleBorder(
                                                                side: const BorderSide(
                                                                  color: Colors.transparent,
                                                                  width: 1,
                                                                  style: BorderStyle.solid
                                                                ),
                                                                borderRadius: BorderRadius.circular(30)
                                                              )
                                                            ),
                                                            autofocus: true,
                                                            child: Container(
                                                              padding: EdgeInsets.all(5),
                                                              child: Text("닫기", style: TextStyle(fontSize: 16, fontFamily: MyFontStyle.nanumGothicBold)),
                                                            ),
                                                            onPressed: () {
                                                              Navigator.pop(context);
                                                            },
                                                          )
                                                        ],
                                                      );
                                                    }
                                                  );
                                                },
                                                child: Text(
                                                  '사진 첨부',
                                                  style: TextStyle(color: Colors.black, fontFamily: MyFontStyle.nanumGothic, fontSize: 16),
                                                )
                                              ),
                                            )
                                          ],
                                        )
                                      )
                                    ],
                                  )
                                ],
                              ),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Container(
                                    margin: EdgeInsets.only(left: 5, top: 10),
                                    child: Text('조치', style: TextStyle(fontSize: 18, fontFamily: MyFontStyle.nanumGothic),),
                                  ),
                                  Row(
                                    children: <Widget>[
                                      Expanded(
                                        child: Column(
                                          children: <Widget>[
                                            InkWell(
                                              child: Container(
                                                height: (MediaQuery.of(context).size.height / 4),
                                                margin: EdgeInsets.only(top: 10, right: 5),
                                                padding: EdgeInsets.all(10),
                                                decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  border: Border.all(width: 0.2),
                                                  borderRadius: BorderRadius.circular(10),
                                                ),
                                                child: Center(
                                                  child: args['SOLV_PHOTO_1'] != null
                                                  ? Image.memory(args['SOLV_PHOTO_1_INT'])
                                                  : isSolv1Empty 
                                                    ? Text('첨부된 사진 없음')
                                                    : Image.file(solv1File)
                                                )
                                              ),
                                              onTap: () {
                                                if(args['SOLV_PHOTO_1'] != null || !isSolv1Empty) {
                                                  showDialog(
                                                    context: context,
                                                    barrierDismissible: false,
                                                    builder: (BuildContext context) {
                                                      return AlertDialog(
                                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
                                                        title: SizedBox(
                                                          width: 150,
                                                          height: 30,
                                                          child: Image.asset('images/SEOYONEH_CI.png')
                                                        ),
                                                        content: Container(
                                                          width: MediaQuery.of(context).size.width * 0.7,
                                                          height: MediaQuery.of(context).size.height * 0.7,
                                                          child: isSolv1Empty 
                                                            ? Image.memory(args['SOLV_PHOTO_1_INT'])
                                                            : Image.file(solv1File),
                                                        ),
                                                        actions: <Widget>[
                                                          TextButton(
                                                            style: TextButton.styleFrom(
                                                              textStyle: const TextStyle(
                                                                  color: Colors.white, 
                                                                  fontFamily: MyFontStyle.nanumGothic),
                                                              foregroundColor: Colors.white,
                                                              backgroundColor: Color.fromRGBO(0, 80, 155, 1),
                                                              shape: RoundedRectangleBorder(
                                                                side: const BorderSide(
                                                                  color: Colors.transparent,
                                                                  width: 1,
                                                                  style: BorderStyle.solid
                                                                ),
                                                                borderRadius: BorderRadius.circular(30)
                                                              )
                                                            ),
                                                            autofocus: true,
                                                            child: Container(
                                                              padding: EdgeInsets.all(5),
                                                              child: Text("닫기", style: TextStyle(fontSize: 16, fontFamily: MyFontStyle.nanumGothicBold)),
                                                            ),
                                                            onPressed: () {
                                                              Navigator.pop(context);
                                                            },
                                                          )
                                                        ],
                                                      );
                                                    }
                                                  );
                                                }
                                              },
                                            ),
                                            Container(
                                              width: MediaQuery.of(context).size.width * 0.1,
                                              margin: EdgeInsets.only(left: 10, right: 10),
                                              padding: EdgeInsets.only(top: 5),
                                              child: OutlinedButton(
                                                style: OutlinedButton.styleFrom(backgroundColor: Colors.black12),
                                                onPressed: () async {
                                                  showDialog(
                                                  context: context,
                                                  barrierDismissible: false,
                                                  builder: (BuildContext context) {
                                                    return AlertDialog(
                                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
                                                      title: SizedBox(
                                                        width: 150,
                                                        height: 30,
                                                        child: Image.asset('images/SEOYONEH_CI.png')
                                                      ),
                                                      content: Row(
                                                        mainAxisAlignment: MainAxisAlignment.center,
                                                        children: <Widget>[
                                                          SizedBox(
                                                            width: 170,
                                                            height: 170,
                                                            child: OutlinedButton(
                                                              style: OutlinedButton.styleFrom(backgroundColor: Colors.white, side: BorderSide(color: Color.fromRGBO(0, 80, 155, 1), width: 2.0)),
                                                              child: Column(
                                                                mainAxisAlignment: MainAxisAlignment.start,
                                                                crossAxisAlignment: CrossAxisAlignment.center,
                                                                children: [
                                                                  Image.asset('images/camera.png', width: 100, height: 120,),
                                                                  Text('카메라', style: TextStyle(fontSize: 23, color: Color.fromRGBO(0, 80, 155, 1), fontFamily: MyFontStyle.nanumGothicBold),),
                                                                ]
                                                              ),
                                                              onPressed: () {
                                                                // 카메라 실행
                                                                Navigator.pop(context);
                                                                ImagePicker().pickImage(source: ImageSource.camera).then((image) {
                                                                  if(image != null) {
                                                                    GallerySaver.saveImage(image.path).then((value) {
                                                                      print(image.path);
                                                                      print(value);
                                                                      setState(() {
                                                                        isSolv1Empty = false;
                                                                        solv1File = File(image.path);  
                                                                        imageMap['SOLV1_IMG_PATH'] = solv1File.path;
                                                                        imageMap['SOLV1_IMG_NM'] = image.name;
                                                                      });
                                                                    });
                                                                  }
                                                                });
                                                                // Navigator.push(context, MaterialPageRoute(builder: (context) => ToolInfo(userInfo)));
                                                              },
                                                            )
                                                          ),
                                                          Padding(padding: EdgeInsets.symmetric(horizontal: 10),),
                                                          SizedBox(
                                                            width: 170,
                                                            height: 170,
                                                            child: OutlinedButton(
                                                              style: OutlinedButton.styleFrom(backgroundColor: Colors.white, side: BorderSide(color: Color.fromRGBO(0, 80, 155, 1), width: 2.5)),
                                                              child: Column(
                                                                mainAxisAlignment: MainAxisAlignment.start,
                                                                crossAxisAlignment: CrossAxisAlignment.center,
                                                                children: [
                                                                  Image.asset('images/gallery.png', width: 100, height: 120,),
                                                                  Text('앨범', style: TextStyle(fontSize: 23, color: Color.fromRGBO(0, 80, 155, 1), fontFamily: MyFontStyle.nanumGothicBold),),
                                                                ]
                                                              ),
                                                              onPressed: () async {
                                                                // 앨범에서 사진 선택
                                                                Navigator.pop(context);
                                                                ImagePicker picker = ImagePicker();
                                                                XFile? solv1Image = await picker.pickImage(source: ImageSource.gallery);
                                                                if(solv1Image != null) {
                                                                  setState(() {
                                                                    isSolv1Empty = false;
                                                                    solv1File = File(solv1Image.path);  
                                                                    imageMap['SOLV1_IMG_PATH'] = solv1File.path;
                                                                    imageMap['SOLV1_IMG_NM'] = solv1Image.name;
                                                                  });
                                                                }
                                                                // Navigator.push(context, MaterialPageRoute(builder: (context) => ToolInfo(userInfo)));
                                                              },
                                                            )
                                                          ),
                                                        ],
                                                      ),
                                                      actions: <Widget>[
                                                        TextButton(
                                                          style: TextButton.styleFrom(
                                                            textStyle: const TextStyle(
                                                                color: Colors.white, 
                                                                fontFamily: MyFontStyle.nanumGothic),
                                                            foregroundColor: Colors.white,
                                                            backgroundColor: Color.fromRGBO(0, 80, 155, 1),
                                                            shape: RoundedRectangleBorder(
                                                              side: const BorderSide(
                                                                color: Colors.transparent,
                                                                width: 1,
                                                                style: BorderStyle.solid
                                                              ),
                                                              borderRadius: BorderRadius.circular(30)
                                                            )
                                                          ),
                                                          autofocus: true,
                                                          child: Container(
                                                            padding: EdgeInsets.all(5),
                                                            child: Text("닫기", style: TextStyle(fontSize: 16, fontFamily: MyFontStyle.nanumGothicBold)),
                                                          ),
                                                          onPressed: () {
                                                            Navigator.pop(context);
                                                          },
                                                        )
                                                      ],
                                                    );
                                                  });
                                                },
                                                child: Text(
                                                  '사진 첨부',
                                                  style: TextStyle(color: Colors.black, fontFamily: MyFontStyle.nanumGothic, fontSize: 16),
                                                )
                                              ),
                                            )
                                          ],
                                        )
                                      ),
                                      Expanded(
                                        child: Column(
                                          children: <Widget>[
                                            InkWell(
                                              child: Container(
                                                height: (MediaQuery.of(context).size.height / 4),
                                                margin: EdgeInsets.only(top: 10, left: 5),
                                                padding: EdgeInsets.all(10),
                                                decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  border: Border.all(width: 0.2),
                                                  borderRadius: BorderRadius.circular(10),
                                                ),
                                                child: Center(
                                                  child: args['SOLV_PHOTO_2'] != null
                                                  ? Image.memory(args['SOLV_PHOTO_2_INT'])
                                                  : isSolv2Empty 
                                                    ? Text('첨부된 사진 없음')
                                                    : Image.file(solv2File)
                                                )
                                              ),
                                              onTap: () {
                                                if(args['SOLV_PHOTO_2'] != null || !isSolv1Empty) {
                                                  showDialog(
                                                    context: context,
                                                    barrierDismissible: false,
                                                    builder: (BuildContext context) {
                                                      return AlertDialog(
                                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
                                                        title: SizedBox(
                                                          width: 150,
                                                          height: 30,
                                                          child: Image.asset('images/SEOYONEH_CI.png')
                                                        ),
                                                        content: Container(
                                                          width: MediaQuery.of(context).size.width * 0.7,
                                                          height: MediaQuery.of(context).size.height * 0.7,
                                                          child: isSolv2Empty 
                                                            ? Image.memory(args['SOLV_PHOTO_2_INT'])
                                                            : Image.file(solv2File),
                                                        ),
                                                        actions: <Widget>[
                                                          TextButton(
                                                            style: TextButton.styleFrom(
                                                              textStyle: const TextStyle(
                                                                  color: Colors.white, 
                                                                  fontFamily: MyFontStyle.nanumGothic),
                                                              foregroundColor: Colors.white,
                                                              backgroundColor: Color.fromRGBO(0, 80, 155, 1),
                                                              shape: RoundedRectangleBorder(
                                                                side: const BorderSide(
                                                                  color: Colors.transparent,
                                                                  width: 1,
                                                                  style: BorderStyle.solid
                                                                ),
                                                                borderRadius: BorderRadius.circular(30)
                                                              )
                                                            ),
                                                            autofocus: true,
                                                            child: Container(
                                                              padding: EdgeInsets.all(5),
                                                              child: Text("닫기", style: TextStyle(fontSize: 16, fontFamily: MyFontStyle.nanumGothicBold)),
                                                            ),
                                                            onPressed: () {
                                                              Navigator.pop(context);
                                                            },
                                                          )
                                                        ],
                                                      );
                                                    }
                                                  );
                                                }
                                              },
                                            ),
                                            Container(
                                              width: MediaQuery.of(context).size.width * 0.1,
                                              margin: EdgeInsets.only(left: 10, right: 10),
                                              padding: EdgeInsets.only(top: 5),
                                              child: OutlinedButton(
                                                style: OutlinedButton.styleFrom(backgroundColor: Colors.black12),
                                                onPressed: () async {
                                                  showDialog(
                                                  context: context,
                                                  barrierDismissible: false,
                                                  builder: (BuildContext context) {
                                                    return AlertDialog(
                                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
                                                      title: SizedBox(
                                                        width: 150,
                                                        height: 30,
                                                        child: Image.asset('images/SEOYONEH_CI.png')
                                                      ),
                                                      content: Row(
                                                        mainAxisAlignment: MainAxisAlignment.center,
                                                        children: <Widget>[
                                                          SizedBox(
                                                            width: 170,
                                                            height: 170,
                                                            child: OutlinedButton(
                                                              style: OutlinedButton.styleFrom(backgroundColor: Colors.white, side: BorderSide(color: Color.fromRGBO(0, 80, 155, 1), width: 2.0)),
                                                              child: Column(
                                                                mainAxisAlignment: MainAxisAlignment.start,
                                                                crossAxisAlignment: CrossAxisAlignment.center,
                                                                children: [
                                                                  Image.asset('images/camera.png', width: 100, height: 120,),
                                                                  Text('카메라', style: TextStyle(fontSize: 23, color: Color.fromRGBO(0, 80, 155, 1), fontFamily: MyFontStyle.nanumGothicBold),),
                                                                ]
                                                              ),
                                                              onPressed: () {
                                                                // 카메라 실행
                                                                Navigator.pop(context);
                                                                ImagePicker().pickImage(source: ImageSource.camera).then((image) {
                                                                  if(image != null) {
                                                                    GallerySaver.saveImage(image.path).then((value) {
                                                                      print(image.path);
                                                                      print(value);
                                                                      setState(() {
                                                                        isSolv2Empty = false;
                                                                        solv2File = File(image.path);  
                                                                        imageMap['SOLV2_IMG_PATH'] = solv2File.path;
                                                                        imageMap['SOLV2_IMG_NM'] = image.name;
                                                                      });
                                                                    });
                                                                  }
                                                                });
                                                                // Navigator.push(context, MaterialPageRoute(builder: (context) => ToolInfo(userInfo)));
                                                              },
                                                            )
                                                          ),
                                                          Padding(padding: EdgeInsets.symmetric(horizontal: 10),),
                                                          SizedBox(
                                                            width: 170,
                                                            height: 170,
                                                            child: OutlinedButton(
                                                              style: OutlinedButton.styleFrom(backgroundColor: Colors.white, side: BorderSide(color: Color.fromRGBO(0, 80, 155, 1), width: 2.5)),
                                                              child: Column(
                                                                mainAxisAlignment: MainAxisAlignment.start,
                                                                crossAxisAlignment: CrossAxisAlignment.center,
                                                                children: [
                                                                  Image.asset('images/gallery.png', width: 100, height: 120,),
                                                                  Text('앨범', style: TextStyle(fontSize: 23, color: Color.fromRGBO(0, 80, 155, 1), fontFamily: MyFontStyle.nanumGothicBold),),
                                                                ]
                                                              ),
                                                              onPressed: () async {
                                                                // 앨범에서 사진 선택
                                                                Navigator.pop(context);
                                                                ImagePicker picker = ImagePicker();
                                                                XFile? solv2Image = await picker.pickImage(source: ImageSource.gallery);
                                                                if(solv2Image != null) {
                                                                  setState(() {
                                                                    isSolv2Empty = false;
                                                                    solv2File = File(solv2Image.path);  
                                                                    imageMap['SOLV2_IMG_PATH'] = solv2File.path;
                                                                    imageMap['SOLV2_IMG_NM'] = solv2Image.name;
                                                                  });
                                                                }
                                                                // Navigator.push(context, MaterialPageRoute(builder: (context) => ToolInfo(userInfo)));
                                                              },
                                                            )
                                                          ),
                                                        ],
                                                      ),
                                                      actions: <Widget>[
                                                        TextButton(
                                                          style: TextButton.styleFrom(
                                                            textStyle: const TextStyle(
                                                                color: Colors.white, 
                                                                fontFamily: MyFontStyle.nanumGothic),
                                                            foregroundColor: Colors.white,
                                                            backgroundColor: Color.fromRGBO(0, 80, 155, 1),
                                                            shape: RoundedRectangleBorder(
                                                              side: const BorderSide(
                                                                color: Colors.transparent,
                                                                width: 1,
                                                                style: BorderStyle.solid
                                                              ),
                                                              borderRadius: BorderRadius.circular(30)
                                                            )
                                                          ),
                                                          autofocus: true,
                                                          child: Container(
                                                            padding: EdgeInsets.all(5),
                                                            child: Text("닫기", style: TextStyle(fontSize: 16, fontFamily: MyFontStyle.nanumGothicBold)),
                                                          ),
                                                          onPressed: () {
                                                            Navigator.pop(context);
                                                          },
                                                        )
                                                      ],
                                                    );
                                                  });
                                                },
                                                child: Text(
                                                  '사진 첨부',
                                                  style: TextStyle(color: Colors.black, fontFamily: MyFontStyle.nanumGothic, fontSize: 16),
                                                )
                                              ),
                                            )
                                          ],
                                        )
                                      )
                                    ],
                                  )
                                ],
                              ),
                            )
                          ],
                        ),
                      ),
                      Expanded(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisAlignment: MainAxisAlignment.end,
                            children: <Widget>[
                              Container(
                                width: MediaQuery.of(context).size.width * 0.1,
                                margin: EdgeInsets.only(left: 5, right: 10, bottom: 10),
                                child: OutlinedButton(
                                  style: OutlinedButton.styleFrom(backgroundColor: Color.fromRGBO(0, 80, 155, 1)),
                                  onPressed: () async {
                                    Navigator.pop(context);
                                  }, 
                                  child: Text('취소', style: TextStyle(color: Colors.white, fontFamily: MyFontStyle.nanumGothic, fontSize: 16),)
                                ),
                              ),
                              Container(
                                width: MediaQuery.of(context).size.width * 0.1,
                                margin: EdgeInsets.only(left: 5, right: 10, bottom: 10),
                                child: OutlinedButton(
                                  style: OutlinedButton.styleFrom(backgroundColor: Color.fromRGBO(0, 80, 155, 1)),
                                  onPressed: () async {
                                    // launchUrl(Uri.parse(''));
                                    showDialog(
                                      context: context,
                                      barrierDismissible: false,
                                      builder: (BuildContext dialogContext) {
                                        return AlertDialog(
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10.0)),
                                          title: SizedBox(
                                            width: 400,
                                            height: 30,
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.start,
                                              children: <Widget>[
                                                Image.asset('images/SEOYONEH_CI.png')
                                              ],
                                            ),
                                          ),
                                          content: Container(
                                            padding:
                                                EdgeInsets.only(top: 10, bottom: 20),
                                            child: Text(
                                              '보전 작업을 등록하시겠습니까?',
                                              style: TextStyle(
                                                  fontSize: 20,
                                                  color: Colors.black,
                                                  fontFamily:
                                                      MyFontStyle.nanumGothic),
                                            ),
                                          ),
                                          actions: <Widget>[
                                            TextButton(
                                              style: TextButton.styleFrom(
                                                  textStyle: const TextStyle(
                                                      color: Colors.white,
                                                      fontFamily:
                                                          MyFontStyle.nanumGothic),
                                                  foregroundColor: Colors.white,
                                                  backgroundColor:
                                                      Color.fromRGBO(0, 80, 155, 1),
                                                  shape: RoundedRectangleBorder(
                                                      side: const BorderSide(
                                                          color: Colors.transparent,
                                                          width: 1,
                                                          style: BorderStyle.solid),
                                                      borderRadius:
                                                          BorderRadius.circular(30))),
                                              autofocus: true,
                                              child: Container(
                                                padding: EdgeInsets.all(5),
                                                child: Text("취소",
                                                    style: TextStyle(
                                                        fontSize: 16,
                                                        fontFamily:
                                                            MyFontStyle.nanumGothic)),
                                              ),
                                              onPressed: () {
                                                Navigator.pop(dialogContext);
                                              },
                                            ),
                                            TextButton(
                                              style: TextButton.styleFrom(
                                                  textStyle: const TextStyle(
                                                      color: Colors.white,
                                                      fontFamily:
                                                          MyFontStyle.nanumGothic),
                                                  foregroundColor: Colors.white,
                                                  backgroundColor:
                                                      Color.fromRGBO(0, 80, 155, 1),
                                                  shape: RoundedRectangleBorder(
                                                      side: const BorderSide(
                                                          color: Colors.transparent,
                                                          width: 1,
                                                          style: BorderStyle.solid),
                                                      borderRadius:
                                                          BorderRadius.circular(30))),
                                              autofocus: true,
                                              child: Container(
                                                padding: EdgeInsets.all(5),
                                                child: Text("확인",
                                                    style: TextStyle(
                                                        fontSize: 16,
                                                        fontFamily:
                                                            MyFontStyle.nanumGothic)),
                                              ),
                                              onPressed: () async {
                                                // print(startFullDate);
                                                // print(endFullDate);
                                                // print(DateTimeRange(start: startFullDate, end: endFullDate).duration.inMinutes.toString());
                                                Navigator.pop(dialogContext);
                                                showLoadingBar(true);
                                                // 보전 작업 저장
                                                await Net.multipartRequest('/tm/uploadService.do', imageMap, {
                                                  'SPNAME': 'APG_MOBILE_TM21020.SAVE',
                                                  'IN_WORKNO': args['WORKNO'] ?? workNo,
                                                  'IN_EQUIPCD': args['EQUIPCD'] ?? '',
                                                  'IN_CORCD': Util.USER_INFO['CORCD'],
                                                  'IN_BIZCD': Util.USER_INFO['BIZCD'],
                                                  'IN_PLANT_DIV': args['PLANT_DIV'],
                                                  'IN_START_DATE': DateFormat('yyyyMMddHHmm').format(startFullDate),
                                                  'IN_END_DATE': DateFormat('yyyyMMddHHmm').format(endFullDate),
                                                  'IN_WORK_TIME': DateTimeRange(start: startFullDate, end: endFullDate).duration.inMinutes.toString(),
                                                  'IN_WORK_DIV': workCode,
                                                  'IN_ODDCD': partCode,
                                                  'IN_WORKCD': '',
                                                  'IN_ODD_GRADE': '',
                                                  'IN_ODD_TYPE': typeTextController.text,
                                                  'IN_ODD_REASON': reasonTextController.text,
                                                  'IN_NOTE': noteTextController.text,
                                                  'IN_AMT': '',
                                                  'IN_REG_EMPNO': Util.USER_INFO['EMPNO'],
                                                  'IN_NON_OPRNO': '',
                                                  // 'IN_REPORT_TEXT': '',
                                                  'IN_PROB_PHOTO_1': '',
                                                  'IN_PROB_PHOTO_2': '',
                                                  'IN_REPORT_FILEID': '',
                                                  'IN_SOLV_PHOTO_1': '',
                                                  'IN_SOLV_PHOTO_2': '',
                                                  'IN_ODD_TYPECD': '', // typeCode
                                                  'IN_ODD_REASONCD': '',
                                                  'IN_NOTECD': '',
                                                  'IS_POSITION': '',
                                                  'IN_ISSUE': issueController.text,
                                                });

                                                // 보전 작업자 저장
                                                List<dynamic> items = [];
                                                // 기존 저장된 작업자 목록과 수정된 작업자 목록 비교 후 추가 및 삭제 처리
                                                if(defaultCheckedList.isNotEmpty) {
                                                  for(int index = 0; index < defaultCheckedList.length; index++) {
                                                    items.add({
                                                      'SPNAME': 'APG_MOBILE_TM21020.REMOVE_WORKER', 
                                                      'IN_WORKNO': args['WORKNO'] ?? workNo,
                                                      'IN_WORK_EMPNO': workerList[defaultCheckedList[index]]['WORK_EMPNO'] 
                                                    });
                                                  }
                                                  for(int index = 0; index < checkedList.length; index++) {
                                                    items.add({
                                                      'SPNAME': 'APG_MOBILE_TM21020.SAVE_WORKER', 
                                                      'IN_WORKNO': args['WORKNO'] ?? workNo,
                                                      'IN_WORK_EMPNO': workerList[checkedList[index]]['WORK_EMPNO'], 
                                                      'IN_WORK_NOTE': '', 
                                                      'IN_WORK_MH':  '', 
                                                      'IN_REG_EMPNO': Util.USER_INFO['EMPNO']
                                                    });
                                                  }
                                                  await Net.post('/tm/service.do', {'LIST': items});
                                                } else {
                                                  for(int index = 0; index < checkedList.length; index++) {
                                                    items.add({
                                                      'SPNAME': 'APG_MOBILE_TM21020.SAVE_WORKER', 
                                                      'IN_WORKNO': args['WORKNO'] ?? workNo,
                                                      'IN_WORK_EMPNO': workerList[checkedList[index]]['WORK_EMPNO'], 
                                                      'IN_WORK_NOTE': '', 
                                                      'IN_WORK_MH':  '', 
                                                      'IN_REG_EMPNO': Util.USER_INFO['EMPNO']
                                                    });
                                                  }
                                                  await Net.post('/tm/service.do', {'LIST': items});
                                                }

                                                //보전 자재 출고 내역 저장
                                                for(int index = 0; index < part.length; index++) {
                                                  items.add({
                                                    'SPNAME': 'APG_MOBILE_TM21020.SAVE_DETAIL', 
                                                    'IN_WORKNO': args['WORKNO'] ?? workNo,
                                                    'IN_SEQNO': '0000${index+1}',
                                                    'IN_WORK_DATE': workDate,
                                                    'IN_PARTNO': part[index]['PARTNO'],
                                                    'IN_QTY': part[index]['INPUT_CONTROLLER'].text,
                                                    'IN_AMT': (part[index]['UCOST'] ?? int.parse(part[index]['INPUT_CONTROLLER'].text) * 2).toString(),
                                                    'IN_NOTE': '',
                                                    'IN_REG_EMPNO': Util.USER_INFO['EMPNO']
                                                  });
                                                }
                                                await Net.post('/tm/service.do', {'LIST': items});

                                                //수불 정보 저장
                                                await Net.post('/tm/service', {
                                                  'SPNAME': 'APG_MOBILE_TM21020.SAVE_EXPORT',
                                                    'IN_WORKNO': args['WORKNO'] ?? workNo
                                                });
                                                showLoadingBar(false);
                                                Util.showToastMessage(context, '보전 작업이 저장되었습니다.');
                                              },
                                            ),
                                          ]
                                        );
                                      }
                                    );
                                    // Navigator.pop(context);
                                  }, 
                                  child: Text('저장', style: TextStyle(color: Colors.white, fontFamily: MyFontStyle.nanumGothic, fontSize: 16),)
                                ),
                              ),
                            ],
                        )
                      )
                      
                    ],
                  )
                )
              )
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

class WorkCode {
  const WorkCode(this.code, this.name);

  final String code;
  final String name;

  @override
  String toString() {
    return '$code: $name';
  }
}

class PartCode {
  const PartCode(this.code, this.name);

  final String code;
  final String name;

  @override
  String toString() {
    return '$code: $name';
  }
}

class TypeCode {
  const TypeCode(this.code, this.name);

  final String code;
  final String name;

  @override
  String toString() {
    return '$code: $name';
  }
}

class ReasonCode {
  const ReasonCode(this.code, this.name);

  final String code;
  final String name;

  @override
  String toString() {
    return '$code: $name';
  }
}

class NoteCode {
  const NoteCode(this.code, this.name);

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

class DTS extends DataTableSource {
  int length = 0;
  List<dynamic> result = [];
  BuildContext context;
  var f = NumberFormat('###,###,###,###');

  DTS(equipLength, equipList, this.context) {
    length = equipLength;
    result.addAll(equipList);
  }

  Widget verticalDivider = const VerticalDivider(
      color: Colors.black,
      thickness: 0.1,
  );

  void tapOnDataCell(context, Map<String, dynamic> selectedEquipment) async {
    print(selectedEquipment);
    // 주기 선택 다이얼로그
    Navigator.pop(context);
    Util.replacePushNavigator(context, RegisterWorkInfo(selectedEquipment));
    // Navigator.pop(context);
  }

  @override
  DataRow getRow(int index) {
    return DataRow2.byIndex(
      onTap: () {
        tapOnDataCell(context, result[index]);
      },
      index: index,
      cells: [
        DataCell(Align(alignment: Alignment.center, child: Text(result[index]['PLANT_DIV_NM'] ?? '', style: const TextStyle(fontSize: 15, fontFamily: MyFontStyle.nanumGothic)))),
        DataCell(verticalDivider),
        DataCell(Text(result[index]['PROC_REP_LINE_NM'] ?? '', style: TextStyle(fontSize: 15, fontFamily: MyFontStyle.nanumGothic))),
        DataCell(verticalDivider),
        DataCell(Text(result[index]['EQUIPNM'] ?? '', style: const TextStyle(fontSize: 15, fontFamily: MyFontStyle.nanumGothic))),
        DataCell(verticalDivider),
        DataCell(Text(result[index]['STD'] ?? '', style: const TextStyle(fontSize: 15, fontFamily: MyFontStyle.nanumGothic))),
        DataCell(verticalDivider),
        DataCell(Align(alignment: Alignment.centerRight, child: Text(result[index]['WEIGHT'].toString() == 'null' ? '' : result[index]['WEIGHT'].toString(), style: const TextStyle(fontSize: 15, fontFamily: MyFontStyle.nanumGothic)))),
        DataCell(verticalDivider),
        DataCell(Text(result[index]['MAKE_VEND'] ?? '', style: const TextStyle(fontSize: 15, fontFamily: MyFontStyle.nanumGothic))),
        DataCell(verticalDivider),
        DataCell(Center(child: Text(result[index]['MGRT_EMPNO'] ?? '', style: const TextStyle(fontSize: 15, fontFamily: MyFontStyle.nanumGothic)))),
        DataCell(verticalDivider),
        DataCell(Text(result[index]['EQUIPCD'] ?? '', style: const TextStyle(fontSize: 15, fontFamily: MyFontStyle.nanumGothic))),
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

class LineCode {
  const LineCode(this.code, this.name);

  final String code;
  final String name;

  @override
  String toString() {
    return '$code: $name';
  }
}

class SubLineCode {
  const SubLineCode(this.code, this.name);

  final String code;
  final String name;

  @override
  String toString() {
    return '$code: $name';
  }
}
