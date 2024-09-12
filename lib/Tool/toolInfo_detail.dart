import 'dart:convert';
import 'dart:typed_data';

import 'package:data_table_2/data_table_2.dart';
import 'package:dual_screen/dual_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_toastr/flutter_toastr.dart';
import 'package:intl/intl.dart';
import 'package:pinch_zoom/pinch_zoom.dart';
import 'package:seoyoneh_equipment/Font/font.dart';
import 'package:seoyoneh_equipment/Model/ReturnObject.dart';
import 'package:seoyoneh_equipment/Util/net.dart';
import 'package:seoyoneh_equipment/Util/util.dart';

// ignore: must_be_immutable
class ToolDetailInfo extends StatefulWidget {
  final Map<String, dynamic> toolInfo;
  const ToolDetailInfo({required this.toolInfo, super.key});

  @override
  State<ToolDetailInfo> createState() => _ToolDetailInfoState();
}

class _ToolDetailInfoState extends State<ToolDetailInfo> {
  late ScrollController mainController; // 공구 점검 시트 스크롤 Controller
  late ScrollController toolInfoScrollController; // 공구상세정보 스크롤 Controller
  // Map<String, dynamic> selectedTool = {};
  Map<String, dynamic> toolInfo = {}; // 공구 데이터
  Map<String, dynamic> checkInfo = {}; // 점검 데이터
  bool isSavedResult = false; // 점검 여부
  late TextEditingController firstController; // 첫번째 측정값 Controller
  late TextEditingController secondController; // 두번째 측정값 Controller
  late TextEditingController thirdController; // 세번째 측정값 Controller
  late TextEditingController finalController; // 최종 측정값 Controller
  late TextEditingController noteController; // 특이사항 입력 Controller

  late Uint8List toolBlobImg;

  bool isLoading = false;

  String checkDate = DateFormat('yyyy-MM').format(DateTime.now());

  @override
  void initState() {
    super.initState();
    mainController = ScrollController();
    firstController = TextEditingController();
    secondController = TextEditingController();
    thirdController = TextEditingController();
    finalController = TextEditingController();
    noteController = TextEditingController();
    toolInfoScrollController = ScrollController();
    loadToolDetailInfo();
    print(widget.toolInfo['TOOLCD']);
  }

  void showLoadingBar(bool flag) {
    setState(() {
      isLoading = flag;
    });
  }

  // 공구 상세정보 데이터 조회
  void loadToolDetailInfo() async {
    showLoadingBar(true);
    var response = await Net.post('/tm/service.do', {
      'SPNAME': 'APG_MOBILE_TM21310.INQUERY_DETAIL',
      'IN_TOOLCD': widget.toolInfo['TOOLCD']
    });

    ReturnObject resultItem =
        ReturnObject.fromJsonMap(jsonDecode(response.body));
    if (resultItem.result == 'SUCCESS' && resultItem.data != null) {
      if (resultItem.data[0]['MODEL_PHOTO'] != null) {
        List<int> intList =
            resultItem.data[0]['MODEL_PHOTO'].cast<int>().toList();
        toolBlobImg = Uint8List.fromList(intList);
      }
      toolInfo = resultItem.data[0];
    }
    showLoadingBar(false);
    loadCheckInfo();
  }

  // 공구 점검 시트 조회
  Future<void> loadCheckInfo() async {
    showLoadingBar(true);
    var response = await Net.post('/tm/service', {
      'SPNAME': 'APG_MOBILE_TM21070.INQUERY_TOOL',
      'IN_TOOLCD': widget.toolInfo['TOOLCD'],
      'IN_CORCD': Util.USER_INFO['CORCD'],
      'IN_BIZCD': Util.USER_INFO['BIZCD'],
      'IN_CHECK_DATE': checkDate,
      'IN_LANG_SET': Util.USER_INFO['IN_LANG_SET'],
    });
    ReturnObject resultItem = ReturnObject.fromJsonMap(jsonDecode(response.body));
    if (resultItem.result == 'SUCCESS' && resultItem.data != null && resultItem.data.length > 0) {
      print(resultItem.data);
      checkInfo = resultItem.data[0];
      firstController.text = checkInfo['CHKVAL1'] ?? '';
      secondController.text = checkInfo['CHKVAL2'] ?? '';
      thirdController.text = checkInfo['CHKVAL3'] ?? '';
      finalController.text = checkInfo['RSLTVAL'] ?? '';
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

  // text input form 위젯
  Widget inputFormField(String text, TextEditingController controller) {
    return TextFormField(
        controller: controller,
        keyboardType: TextInputType.number,
        style: TextStyle(
          fontFamily: MyFontStyle.nanumGothic,
          fontSize: 15,
        ),
        textAlignVertical: TextAlignVertical.center,
        textAlign: TextAlign.center,
        cursorColor: Color.fromRGBO(110, 110, 110, 1.0),
        readOnly: text == '최종값' ? true : false,
        onChanged: (value) {
          int firstValue = firstController.text == '' ? 0 : int.parse(firstController.text);
          int secondValue = secondController.text == '' ? 0 : int.parse(secondController.text);
          int thirdValue = thirdController.text == '' ? 0 : int.parse(thirdController.text);
          int sumValue = firstValue + secondValue + thirdValue;
          int det = 0;
          if(firstValue != 0) {
            det++;
          }
          if(secondValue != 0) {
            det++;
          }
          if(thirdValue != 0) {
            det++;
          }
          String finalValue = (sumValue / det).toString();
          finalValue = finalValue.split('.').last == '0' ? finalValue.split('.').first : finalValue.split('.').first + '.' + finalValue.split('.').last.substring(0, 1);
          finalController.text = finalValue;
        },
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

  // text form 위젯(readOnly = true)
  Widget textFormField(String text) {
    return TextFormField(
        style:
            const TextStyle(fontFamily: MyFontStyle.nanumGothic, fontSize: 17),
        textAlignVertical: TextAlignVertical.center,
        readOnly: true,
        decoration: InputDecoration(
          hintText: text,
          hintStyle: const TextStyle(
              color: Colors.black,
              fontFamily: MyFontStyle.nanumGothic,
              fontSize: 18,
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

  // 특이사항 란 입력 input form 위젯
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

  // 공구 점검 시트 화면
  Widget showToolCheckList() {
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
                    child: Text('라인',
                        style: TextStyle(
                            fontSize: 15,
                            color: Colors.white,
                            fontFamily: MyFontStyle.nanumGothicBold)))),
            DataColumn2(label: verticalDivider, fixedWidth: 10),
            const DataColumn2(
                label: Center(
                    child: Text('모델번호',
                        style: TextStyle(
                            fontSize: 15,
                            color: Colors.white,
                            fontFamily: MyFontStyle.nanumGothicBold)))),
            DataColumn2(label: verticalDivider, fixedWidth: 10),
            const DataColumn2(
                label: Center(
                    child: Text('기준값',
                        style: TextStyle(
                            fontSize: 15,
                            color: Colors.white,
                            fontFamily: MyFontStyle.nanumGothicBold))),
                fixedWidth: 90),
            DataColumn2(label: verticalDivider, fixedWidth: 10),
            const DataColumn2(
                label: Center(
                    child: Text('1회',
                        style: TextStyle(
                            fontSize: 15,
                            color: Colors.white,
                            fontFamily: MyFontStyle.nanumGothicBold))),
                fixedWidth: 100),
            DataColumn2(label: verticalDivider, fixedWidth: 10),
            const DataColumn2(
                label: Center(
                    child: Text('2회',
                        style: TextStyle(
                            fontSize: 15,
                            color: Colors.white,
                            fontFamily: MyFontStyle.nanumGothicBold))),
                fixedWidth: 100),
            DataColumn2(label: verticalDivider, fixedWidth: 10),
            const DataColumn2(
                label: Center(
                    child: Text('3회',
                        style: TextStyle(
                            fontSize: 15,
                            color: Colors.white,
                            fontFamily: MyFontStyle.nanumGothicBold))),
                fixedWidth: 100),
            DataColumn2(label: verticalDivider, fixedWidth: 10),
            const DataColumn2(
                label: Center(
                    child: Text(
                  '최종\n(수정값)',
                  style: TextStyle(
                      fontSize: 15,
                      color: Colors.white,
                      fontFamily: MyFontStyle.nanumGothicBold),
                  textAlign: TextAlign.center,
                )),
                fixedWidth: 100),
            DataColumn2(label: verticalDivider, fixedWidth: 10),
            const DataColumn2(
                label: Center(
                    child: Text('공구번호',
                        style: TextStyle(
                            fontSize: 15,
                            color: Colors.white,
                            fontFamily: MyFontStyle.nanumGothicBold))),
                fixedWidth: 100),
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
                  child: Text(widget.toolInfo['LINECDNM'],
                      style: TextStyle(
                          fontSize: 15, fontFamily: MyFontStyle.nanumGothic)))),
              DataCell(verticalDivider),
              DataCell(Center(
                  child: Text(widget.toolInfo['MODELNO'],
                      style: TextStyle(
                          fontSize: 15, fontFamily: MyFontStyle.nanumGothic)))),
              DataCell(verticalDivider),
              DataCell(Center(
                  child: Text(widget.toolInfo['MGRT_STD'],
                      style: const TextStyle(
                          fontSize: 15, fontFamily: MyFontStyle.nanumGothic)))),
              DataCell(verticalDivider),
              DataCell(Center(
                  child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 5),
                      child: inputFormField('1회', firstController)))),
              DataCell(verticalDivider),
              DataCell(Center(
                  child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 5),
                      child: inputFormField('2회', secondController)))),
              DataCell(verticalDivider),
              DataCell(Center(
                  child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 5),
                      child: inputFormField('3회', thirdController)))),
              DataCell(verticalDivider),
              DataCell(Center(
                  child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 5),
                      child: inputFormField('최종값', finalController)))),
              DataCell(verticalDivider),
              DataCell(Center(
                  child: Text(widget.toolInfo['TOOLNO'],
                      style: const TextStyle(
                          fontSize: 15, fontFamily: MyFontStyle.nanumGothic)))),
            ]);
          }),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(children: <Widget>[
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
                                    child: Text(toolInfo['LINECDNM'] ?? '라인명 없음',
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
                      Container(
                        width: 120.0,
                        margin: EdgeInsets.only(right: 10.0),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Color.fromRGBO(0, 80, 155, 1)),
                          onPressed: () async {
                            showToolDetailInfo();
                          },
                          child: Text(
                            '공구정보',
                            style: TextStyle(
                                color: Colors.white,
                                fontFamily: MyFontStyle.nanumGothic,
                                fontSize: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(
                    height: 120,
                    child: showToolCheckList(),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Container(
                          margin: EdgeInsets.only(left: 15.0),
                          child: Text(
                            '특이사항',
                            style: TextStyle(fontSize: 18, fontFamily: MyFontStyle.nanumGothicBold, color: Color.fromRGBO(110, 110, 110, 1)),
                            
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
                            if (firstController.text != '' &&
                                secondController.text != '' &&
                                thirdController.text != '' &&
                                finalController.text != '') {
                              // showDialog(
                              //   context: context,
                              //   barrierDismissible: false,
                              //   builder: (BuildContext context) {
                              //     return Util.ShowConfirmPopup(context, '점검 결과를 저장하시겠습니까?', () async {
                                    print(widget.toolInfo);
                                    var response = await Net.post('/tm/service', {
                                      'SPNAME': 'APG_MOBILE_TM21070.SAVE_TOOL',
                                      'IN_TOOLCD': widget.toolInfo['TOOLCD'],
                                      'IN_CORCD': Util.USER_INFO['CORCD'],
                                      'IN_BIZCD': Util.USER_INFO['BIZCD'],
                                      'IN_CHECK_DATE': checkDate,
                                      'IN_CHKVAL1': firstController.text,
                                      'IN_CHKVAL2': secondController.text,
                                      'IN_CHKVAL3': thirdController.text,
                                      'IN_RSLTVAL': finalController.text,
                                      'IN_CONTENT': noteController.text,
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
                            } else {
                              showDialog(
                                  context: context,
                                  barrierDismissible: false,
                                  builder: (BuildContext context) {
                                    return Util.ShowMessagePopup(
                                        context, '측정값 또는 최종값을 모두 입력해주세요.');
                                  });
                            }
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
    ]);
  }

  // 공구 상세 정보 팝업
  Future<dynamic> showToolDetailInfo() {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
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
                  controller: toolInfoScrollController,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
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
                                  child: Text(
                                    '공구코드',
                                    style: TextStyle(
                                        fontSize: 18,
                                        fontFamily: MyFontStyle.nanumGothic),
                                  ),
                                ),
                                Container(
                                    margin: EdgeInsets.only(
                                        top: 5, right: 5, bottom: 10),
                                    height: 38,
                                    child:
                                        textFormField(toolInfo['TOOLCD'] ?? ''))
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
                                    '공구번호',
                                    style: TextStyle(
                                        fontSize: 18,
                                        fontFamily: MyFontStyle.nanumGothic),
                                  ),
                                ),
                                Container(
                                    margin: EdgeInsets.only(
                                        top: 5, left: 5, bottom: 10),
                                    height: 38,
                                    child:
                                        textFormField(toolInfo['TOOLNO'] ?? ''))
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
                                    '법인',
                                    style: TextStyle(
                                        fontSize: 18,
                                        fontFamily: MyFontStyle.nanumGothic),
                                  ),
                                ),
                                Container(
                                    margin: EdgeInsets.only(
                                        top: 5, right: 5, bottom: 10),
                                    height: 38,
                                    child:
                                        textFormField(toolInfo['CORNM'] ?? ''))
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
                                    style: TextStyle(
                                        fontSize: 18,
                                        fontFamily: MyFontStyle.nanumGothic),
                                  ),
                                ),
                                Container(
                                    margin: EdgeInsets.only(
                                        top: 5, left: 5, bottom: 10),
                                    height: 38,
                                    child:
                                        textFormField(toolInfo['BIZNM'] ?? ''))
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
                                    '라인',
                                    style: TextStyle(
                                        fontSize: 18,
                                        fontFamily: MyFontStyle.nanumGothic),
                                  ),
                                ),
                                Container(
                                    margin: EdgeInsets.only(
                                        top: 5, right: 5, bottom: 10),
                                    height: 38,
                                    child: textFormField(
                                        toolInfo['LINECDNM'] ?? ''))
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
                                    '공장구분',
                                    style: TextStyle(
                                        fontSize: 18,
                                        fontFamily: MyFontStyle.nanumGothic),
                                  ),
                                ),
                                Container(
                                    margin: EdgeInsets.only(
                                        top: 5, left: 5, bottom: 10),
                                    height: 38,
                                    child: textFormField(
                                        toolInfo['PLANT_DIV_NM'] ?? ''))
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
                                    '모델명',
                                    style: TextStyle(
                                        fontSize: 18,
                                        fontFamily: MyFontStyle.nanumGothic),
                                  ),
                                ),
                                Container(
                                    margin: EdgeInsets.only(
                                        top: 5, right: 5, bottom: 10),
                                    height: 38,
                                    child: textFormField(
                                        toolInfo['MODELNAME'] ?? ''))
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
                                    '모델번호',
                                    style: TextStyle(
                                        fontSize: 18,
                                        fontFamily: MyFontStyle.nanumGothic),
                                  ),
                                ),
                                Container(
                                    margin: EdgeInsets.only(
                                        top: 5, left: 5, bottom: 10),
                                    height: 38,
                                    child:
                                        textFormField(toolInfo['MODELNO'] ?? ''))
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
                                    '속도(rpm)',
                                    style: TextStyle(
                                        fontSize: 18,
                                        fontFamily: MyFontStyle.nanumGothic),
                                  ),
                                ),
                                Container(
                                    margin: EdgeInsets.only(
                                        top: 5, bottom: 10, right: 5),
                                    height: 38,
                                    child: textFormField(
                                        toolInfo['SPEEDNM'].toString()))
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
                                    '기준값',
                                    style: TextStyle(
                                        fontSize: 18,
                                        fontFamily: MyFontStyle.nanumGothic),
                                  ),
                                ),
                                Container(
                                    margin: EdgeInsets.only(
                                        top: 5, left: 5, bottom: 10),
                                    height: 38,
                                    child: textFormField(
                                        toolInfo['MGRT_STD'].toString()))
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
                                    '관리부서',
                                    style: TextStyle(
                                        fontSize: 18,
                                        fontFamily: MyFontStyle.nanumGothic),
                                  ),
                                ),
                                Container(
                                    margin: EdgeInsets.only(
                                        top: 5, bottom: 10, right: 5),
                                    height: 38,
                                    child: textFormField(
                                        toolInfo['MGRT_DEPT_NM'].toString()))
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
                                    '도입부서',
                                    style: TextStyle(
                                        fontSize: 18,
                                        fontFamily: MyFontStyle.nanumGothic),
                                  ),
                                ),
                                Container(
                                    margin: EdgeInsets.only(
                                        top: 5, left: 5, bottom: 10),
                                    height: 38,
                                    child: textFormField(
                                        toolInfo['PURC_DEPT_NM'].toString()))
                              ],
                            ),
                          )
                        ],
                      ),
                      Container(
                        margin: EdgeInsets.only(left: 5),
                        child: Text(
                          '용도',
                          style: TextStyle(
                              fontSize: 18,
                              fontFamily: MyFontStyle.nanumGothic),
                        ),
                      ),
                      Container(
                          margin: EdgeInsets.only(top: 5, bottom: 10),
                          height: 38,
                          child:
                              textFormField(toolInfo['TOOL_NOTE'].toString())),
                      Container(
                        margin: EdgeInsets.only(left: 5),
                        child: Text(
                          '특기사항',
                          style: TextStyle(
                              fontSize: 18,
                              fontFamily: MyFontStyle.nanumGothic),
                        ),
                      ),
                      Container(
                          margin: EdgeInsets.only(top: 5, bottom: 10),
                          height: 38,
                          child: textFormField(toolInfo['NOTE'] ?? '')),
                    ],
                  ),
                ),
              ),
              endPane: Container(
                  margin: EdgeInsets.only(left: 20, right: 20, bottom: 100),
                  child: Center(
                    child: Padding(
                        padding: EdgeInsets.all(10),
                        child: toolInfo['MODEL_PHOTO'] == null
                            ? Image.asset('images/SEOYONEH_CI.png')
                            : Image.memory(toolBlobImg)),
                  ))),
          actions: <Widget>[
            Container(
              width: 100,
              padding: EdgeInsets.all(10),
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                    backgroundColor: Color.fromRGBO(0, 80, 155, 1)),
                onPressed: () async {
                  // launchUrl(Uri.parse(''));
                  Navigator.pop(context);
                },
                child: Text(
                  '확인',
                  style: TextStyle(
                      color: Colors.white,
                      fontFamily: MyFontStyle.nanumGothic,
                      fontSize: 16),
                ),
              ),
            )
          ],
        );
      },
    );
  }
}
