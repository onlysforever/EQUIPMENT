import 'dart:convert';

import 'package:seoyoneh_equipment/Equipment/equipmentInfo_detail.dart';
import 'package:seoyoneh_equipment/Equipment/equipmentInfo_generator.dart';
import 'package:seoyoneh_equipment/Equipment/equipmentInfo_motor.dart';
import 'package:seoyoneh_equipment/Equipment/equipmentInfo_safety.dart';
import 'package:seoyoneh_equipment/Font/font.dart';
import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:seoyoneh_equipment/Illuminance/illuminance_detail.dart';
import 'package:seoyoneh_equipment/Model/ReturnObject.dart';
import 'package:seoyoneh_equipment/Tool/toolInfo_detail.dart';
import 'package:seoyoneh_equipment/Util/net.dart';
import 'package:seoyoneh_equipment/Util/util.dart';

// ignore: must_be_immutable
class QRScanner extends StatefulWidget {
  final String type;
  final String subType;
  QRScanner({required this.type, required this.subType, super.key});

  @override
  State<QRScanner> createState() => QRScannerState();
}

class QRScannerState extends State<QRScanner> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  Barcode? result;
  QRViewController? controller;

  // In order to get hot reload to work we need to pause the camera if the platform
  // is android, or resume the camera if the platform is iOS.

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    controller?.stopCamera();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var scanArea = (MediaQuery.of(context).size.width < 300 || MediaQuery.of(context).size.height < 300) ? 200.0 : 300.0;
    return Scaffold(
      body: Column(
        children: <Widget>[
          Expanded(
            flex: 5,
            child: QRView(
              key: qrKey,
              onQRViewCreated: _onQRViewCreated,
              overlay: QrScannerOverlayShape(borderColor: Colors.red, borderRadius: 10, borderLength: 30, borderWidth: 10, cutOutSize: scanArea),
            ),
          ),
          Expanded(
            flex: 1,
            child: Center(
              child: Text('QR코드를 스캔해주세요', style: TextStyle(fontSize: 20, fontFamily: MyFontStyle.nanumGothic)),
            ),
          )
        ],
      ),
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) async {
      controller.stopCamera();
      print(scanData.code);
      if (widget.type == 'equipment') {
        print(scanData.code);
        print(widget.subType);
        var response = await Net.post('/tm/service', {
          'SPNAME': 'APG_MOBILE_TM21010.INQUERY_LIST',
          'IN_BIZCD': Util.USER_INFO['BIZCD'],
          'IN_CORCD': Util.USER_INFO['CORCD'],
          'IN_EQUIPCD': scanData.code,
          'IN_EQUIPNM': '',
          'IN_LINECD': '',
          'IN_PROC_REP_LINE': '',
          'IN_DIR_LINE_YN': 'N',
          'IN_PLANT_DIV': '',
          'IN_LANG_SET': Util.USER_INFO['IN_LANG_SET'],
          'IN_CHK_TYPE': widget.subType
        });
        var responseBody = jsonDecode(response.body);
        print(responseBody);
        var resultEquipmentInfo = responseBody['data'][0];
        print(resultEquipmentInfo);
        if(widget.subType == 'CM') {
          Navigator.pop(context);
          showTermDialog(context, resultEquipmentInfo);
        } else if(widget.subType == 'MT') {
          Util.replacePushNavigator(context,
                  EquipmentMotorInfo(selectedEquipment: resultEquipmentInfo));
        } else if(widget.subType == 'BA') {
          Util.replacePushNavigator(context,
                  EquipmentSafetyInfo(selectedEquipment: resultEquipmentInfo));
        } else if(widget.subType == 'GN') {
          Util.replacePushNavigator(context,
                  EquipmentGeneratorInfo(selectedEquipment: resultEquipmentInfo));
        } else if(widget.subType == '') {
          Navigator.pop(context, resultEquipmentInfo);
        }
      } else if (widget.type == 'tool') {
        var response = await Net.post('/tm/service', {
          'SPNAME': 'APG_TM21310.INQUERY',
          'IN_CORCD': Util.USER_INFO['CORCD'],
          'IN_BIZCD': Util.USER_INFO['BIZCD'], //Util.USER_INFO['BIZCD'],
          'IN_LINECD': '',
          'IN_TOOLCD': scanData.code,
          'IN_TOOLNO': '',
          'IN_MODELNAME': ''
        });
        var responseBody = jsonDecode(response.body);
        var resultToolInfo = responseBody['data'][0];
        await Util.replacePushNavigator(
            context,
            ToolDetailInfo(
              toolInfo: resultToolInfo,
            ));
        // await Navigator.push(context, MaterialPageRoute(builder: (context) => ToolDetailInfo(resultToolInfo)));
      } else if(widget.type == 'illuminance') {
        var response = await Net.post('/tm/service', {
          'SPNAME': 'APG_MOBILE_BM20020.INQUERY_MASTER',
          'IN_CORCD': Util.USER_INFO['CORCD'],
          'IN_BIZCD': Util.USER_INFO['BIZCD'],
          'IN_VINCD': '',
          'IN_LINECD': scanData.code,
          'IN_PLANT_DIV': '',
          'IN_LANG_SET': Util.USER_INFO['IN_LANG_SET']
        });
        var responseBody = jsonDecode(response.body);
        var resultLineInfo = responseBody['data'][0];
        Util.replacePushNavigator(context, IlluminanceDetailInfo(selectedLine: resultLineInfo));
      }  /* else if (widget.type == 'work') {
        print(Util.USER_INFO);
        var response = await Net.post('/tm/equipmentMaster.do', {
          'SPNAME': 'APG_MOBILE_TM21010.INQUERY_LIST',
          'IN_BIZCD': Util.USER_INFO['BIZCD'],
          'IN_CORCD': Util.USER_INFO['CORCD'],
          'IN_EQUIPCD': scanData.code,
          'IN_EQUIPNM': '',
          'IN_LINECD': '',
          'IN_PROC_REP_LINE': '',
          'IN_DIR_LINE_YN': 'N',
          'IN_PLANT_DIV': '',
          'IN_LANG_SET': Util.USER_INFO['IN_LANG_SET'],
        });
        var responseBody = jsonDecode(response.body);
        var resultEquipmentInfo = responseBody['data'];
        print(resultEquipmentInfo);
        Navigator.pop(context, resultEquipmentInfo);
      } */
    });
  }

  void showTermDialog(context, equipment) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Util.ShowTermPopup(context, Term.D, (value) {
          Util.replacePushNavigator(context, EquipmentDetailInfo(equipment: equipment, term: value));
        });
      },
    );
  }
}
