
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:install_plugin/install_plugin.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:seoyoneh_equipment/Login/login.dart';
import 'package:seoyoneh_equipment/Model/ReturnObject.dart';
import 'package:seoyoneh_equipment/Util/net.dart';
import 'package:seoyoneh_equipment/Util/util.dart';
import 'package:yaml/yaml.dart';

void main() {
  runApp(const Main());
}

class Main extends StatelessWidget {
  const Main({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Intro(),
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        appBarTheme: AppBarTheme(
          systemOverlayStyle: SystemUiOverlayStyle.dark,
        )
      ),
    );
  }
}

class Intro extends StatefulWidget {
  const Intro({super.key});

  @override
  State<Intro> createState() => _IntroState();
}

class _IntroState extends State<Intro> with TickerProviderStateMixin{
  late AnimationController loadingController;

  //최초 실행
  @override
  void initState() {
    super.initState();
    loadingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..addListener(() {
      setState(() {});
    });
    loadingController.repeat(reverse: false);

    //향후 앱 버전 비교 후 로그인 화면 전환으로 수정 필요
    Net.post('/tm/service.do', {
      'SPNAME': 'APG_MOBILE_SUPPORT.INQUERY_GET_VERSION',
      'IN_APP': 'EQUIPMENT',
      'IN_LANG_SET': Util.USER_INFO['IN_LANG_SET'],
    }).then((response) async {
      ReturnObject resultItem = ReturnObject.fromJsonMap(jsonDecode(response.body));
      await rootBundle.loadString("pubspec.yaml").then((value) {
        var yaml = loadYaml(value);
        Util.appVersion = yaml['version'];
      });
      if(Platform.isAndroid) {
        int latestVersion = int.parse(resultItem.data[0]['ANDROID_VERSION'].toString().replaceAll('.', ''));
        int nowVersion = int.parse(Util.appVersion.replaceAll('.', ''));
        if(nowVersion < latestVersion) {
          // showDialog(
          //   context: context,
          //   barrierDismissible: false,
          //   builder: (BuildContext context) {
          //     return Util.ShowMessagePopup(context, '최신 버전을 다운로드 중입니다.\n다운로드 후 자동으로 설치가 시작됩니다.');
          //   },
          // );
          var permissionStorage = await Permission.manageExternalStorage.request();
          
          var permissionInstall = await Permission.requestInstallPackages.request();
          
          var downloadDir = '/storage/emulated/0/Download'; // 다운로드 폴더 경로
          File olderFile = File('$downloadDir/equipment_${Util.appVersion}.apk');
          if(olderFile.existsSync()) {
            olderFile.deleteSync();
          }
          String url = 'http://jwebapi.seoyoneh.com:4877/deploy/'; // 서버주소
          String fileName = 'equipment_${resultItem.data[0]['ANDROID_VERSION']}.apk'; // 서버에 등록된 최신 버전 apk파일
          var resultPath = '$downloadDir/$fileName'; // 앱 패키지 디렉토리에 최신버전 apk파일 이름
          await downloadFile(url, fileName, downloadDir);
          if (permissionStorage.isGranted && permissionInstall.isGranted) {
            InstallPlugin.installApk(resultPath).then((value) {
              // 최신버전 apk파일로 업데이트
              print('install apk $value');
            }).catchError((error) {
              print('install apk error: $error');
            });
          }
        } else {
          Util.replacePushNavigator(context, Login());
        }
        print(Util.appVersion);
      } else if(Platform.isIOS) {
        if(resultItem.data['IOS_VERSION'] != Util.appVersion) {
          
        } else {
          Util.replacePushNavigator(context, Login());
        }
      }
    });

    // Future.delayed(
    //   const Duration(seconds: 2), 
    //   () => Util.replacePushNavigator(context, Login()));
  }

  Future<String> downloadFile(String url, String fileName, String dir) async {
    HttpClient httpClient = HttpClient();
    File file;
    String filePath = '';
    String serviceUrl = '';

    try {
      serviceUrl = '$url/$fileName';
      var request = await httpClient.getUrl(Uri.parse(serviceUrl));
      var response = await request.close();

      if (response.statusCode == 200) {
        var bytes = await consolidateHttpClientResponseBytes(response);
        print(bytes.lengthInBytes);
        filePath = '$dir/$fileName';
        file = File(filePath);
        await file.writeAsBytes(bytes);
      } else {
        filePath = 'Error Code : ${response.statusCode}';
      }
    } catch (exception) {
      filePath = 'not url';
    }
    return filePath;
  }

  //화면 종료 이벤트
  @override
  void dispose() {
    loadingController.dispose();
    super.dispose();
    
  }

  //앱 메인 화면
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
    return Scaffold(
      //상단 appbar
      appBar: null,
      // 화면 body
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            SizedBox(
              width: 800,
              height: 200,
              child: Image.asset('images/SEOYONEH_CI.png'),
            ),
            const Padding(
              padding: EdgeInsets.only(
                  top: 20.0, bottom: 20.0, left: 0.0, right: 0.0),
            ),
            CircularProgressIndicator(
              value: loadingController.value,
              color: const Color.fromRGBO(110, 110, 100, 1.0),
              strokeWidth: 5.0,
            )
          ],
        )
      )
    );
  }
}
