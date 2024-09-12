import 'package:flutter/material.dart';
import 'package:pinch_zoom/pinch_zoom.dart';
import 'package:seoyoneh_equipment/Equipment/equipmentInfo.dart';
import 'package:seoyoneh_equipment/Font/font.dart';
import 'package:seoyoneh_equipment/Illuminance/illuminance.dart';
import 'package:seoyoneh_equipment/Login/login.dart';
import 'package:seoyoneh_equipment/QRScanner/qrScanner.dart';
import 'package:seoyoneh_equipment/Tool/toolInfo.dart';
import 'package:seoyoneh_equipment/Util/util.dart';

import 'Work/workInfo.dart';

// ignore: must_be_immutable
class Home extends StatefulWidget {
  Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  Widget menuButton(image, text, newPage) {
    return SizedBox(
        width: 200,
        height: 200,
        child: OutlinedButton(
          style: OutlinedButton.styleFrom(
              backgroundColor: Color.fromRGBO(0, 80, 155, 1)),
          child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Image.asset(
                  image,
                  width: 150,
                  height: 150,
                ),
                Text(
                  text,
                  style: TextStyle(
                      fontSize: 23,
                      color: Colors.white,
                      fontFamily: MyFontStyle.nanumGothicBold),
                ),
              ]),
          onPressed: () {
            // 설비 정보 화면으로 전환
            if(text == '설비 점검') {
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (BuildContext context) {
                  return Util.ShowCheckTypePopup(context, CheckType.QR, '설비점검 조회', (value) {
                    print(value);
                    if(value == CheckType.QR.name) {
                      Util.replacePushNavigator(context, QRScanner(
                          type: 'equipment',
                          subType: 'CM',
                        )
                      );
                    } else {
                      Util.replacePushNavigator(context, EquipmentInfo(
                          checkType: 'CM',
                        )
                      );
                    }
                  });
                },
              );
            } else if(text == '안전기 점검') {
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (BuildContext context) {
                  return Util.ShowCheckTypePopup(context, CheckType.QR, '안전기점검 조회', (value) {
                    print(value);
                    if(value == CheckType.QR.name) {
                      Util.replacePushNavigator(context, QRScanner(
                          type: 'equipment',
                          subType: 'BA',
                        )
                      );
                    } else {
                      Util.replacePushNavigator(context, EquipmentInfo(
                          checkType: 'BA',
                        )
                      );
                    }
                  });
                },
              );
            } else if(text == '비상발전기 점검') {
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (BuildContext context) {
                  return Util.ShowCheckTypePopup(context, CheckType.QR, '비상 발전기점검 조회', (value) {
                    print(value);
                    if(value == CheckType.QR.name) {
                      Util.replacePushNavigator(context, QRScanner(
                          type: 'equipment',
                          subType: 'GN',
                        )
                      );
                    } else {
                      Util.replacePushNavigator(context, EquipmentInfo(
                          checkType: 'GN',
                        )
                      );
                    }
                  });
                },
              );
            } else if(text == '모터진동 측정') {
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (BuildContext context) {
                  return Util.ShowCheckTypePopup(context, CheckType.QR, '모터측정 점검조회', (value) {
                    print(value);
                    if(value == CheckType.QR.name) {
                      Util.replacePushNavigator(context, QRScanner(
                          type: 'equipment',
                          subType: 'MT',
                        )
                      );
                    } else {
                      Util.replacePushNavigator(context, EquipmentInfo(
                          checkType: 'MT',
                        )
                      );
                    }
                  });
                },
              );
            } else {
              Util.pushNavigator(context, newPage);
            }
            
          },
        ));
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: null,
        body: PinchZoom(
          maxScale: 3,
          resetDuration: Duration(milliseconds: 200),
          zoomEnabled: true,
          child: Column(
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // setting 아이콘 버튼, 임시 숨김 조치
                  // Container(
                  //   padding: EdgeInsets.only(top: 50, right: 10),
                  //   child: InkWell(
                  //     hoverColor: Colors.transparent,
                  //     onTap: () {

                  //     },
                  //     child: Row(
                  //       children: [
                  //         SvgPicture.asset(
                  //           'images/footer_setting.svg',
                  //           width: 25,
                  //           height: 25,
                  //           color: Color.fromRGBO(0, 80, 155, 1)
                  //         ),
                  //         Padding(padding: EdgeInsets.symmetric(horizontal: 5),),
                  //         Text('Setting', style: TextStyle(fontFamily: MyFontStyle.nanumGothic, fontSize: 20, color: Color.fromRGBO(0, 80, 155, 1)),)
                  //       ],
                  //     )
                  //   )
                  // ),
                  // 로그아웃 버튼
                  Container(
                    padding: EdgeInsets.only(top: 50, left: 20, right: 30),
                    child: InkWell(
                      splashColor: Colors.transparent,
                      highlightColor: Colors.transparent,
                      onTap: () {
                        showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (BuildContext context) {
                              return Util.ShowConfirmPopup(
                                context,
                                '로그아웃 하시겠습니까?',
                                () {
                                  Util.replacePushNavigator(context, Login());
                                },
                              );
                            });
                      },
                      child: Row(
                        children: [
                          Icon(Icons.exit_to_app_rounded,
                              color: Color.fromRGBO(0, 80, 155, 1), size: 30),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 5),
                          ),
                          Text(
                            'Logout',
                            style: TextStyle(
                                fontFamily: MyFontStyle.nanumGothic,
                                fontSize: 20,
                                color: Color.fromRGBO(0, 80, 155, 1)),
                          )
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              // 로고 이미지
              Container(
                  width: 400,
                  height: 100,
                  padding: EdgeInsets.only(bottom: 20),
                  margin: EdgeInsets.only(bottom: 20),
                  child: Image.asset('images/SEOYONEH_CI.png')),
              // 화면 중앙 3개의 버튼 Row 위젯
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    // 설비점검 버튼
                    menuButton(
                        'images/equipment_menu.png',
                        '설비 점검',
                        EquipmentInfo(
                          checkType: 'CM',
                        )),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                    ),
                    // 공구점검 버튼
                    menuButton('images/tool_menu.png', '토크 측정', ToolInfo()),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                    ),
                    // 보전 작업 버튼
                    menuButton('images/work_menu.png', '보전 작업', WorkInfo()),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
              ),
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    // 안전기 점검 버튼
                    menuButton('images/safety_menu.png', '안전기 점검', EquipmentInfo(checkType: 'BA')),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                    ),
                    // 비상발전기 점검 버튼
                    // menuButton('images/generator_menu.png', '비상발전기 점검', EquipmentInfo(checkType: 'GN',),),
                    // Padding(
                    //   padding: EdgeInsets.symmetric(horizontal: 20),
                    // ),
                    // 모터진동 측정 버튼
                    menuButton('images/motor_menu.png', '모터진동 측정', EquipmentInfo(checkType: 'MT',),),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                    ),
                    // 조도체크 버튼
                    menuButton('images/tool_menu.png', '조도 체크', IlluminanceInfo()),
                  ],
                ),
              ),
            ],
          ),
        ), 
      ), 
      onWillPop:  () async {
        await Util.onExitApp(context);
        return false;
      }
    );
  }
}
