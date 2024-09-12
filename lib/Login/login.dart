import 'dart:convert';

import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:pinch_zoom/pinch_zoom.dart';
import 'package:seoyoneh_equipment/Font/font.dart';
import 'package:seoyoneh_equipment/Util/net.dart';
import 'package:seoyoneh_equipment/Util/util.dart';
import 'package:seoyoneh_equipment/home.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../Model/ReturnObject.dart';

class Login extends StatefulWidget {
  Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  late SharedPreferences pref; // preference 객체
  late FocusNode idFocusNode; // id 입력란 포커스 객체
  late FocusNode pwFocusNode; // pw 입력란 포커스 객체
  late ScrollController scrollController; // 메인 스크롤 controller
  late TextEditingController idController; // id 입력 controller
  late TextEditingController pwController; // pw 입력 controller
  List<LangCode> langCodes = <LangCode>[]; // 언어 combobox
  // List<CompCode> compCodes = <CompCode>[];
  List<DropDownCode> compCodes = <DropDownCode>[]; // 회사 combobox
  DropDownCode selectedCompCode = DropDownCode('', '', ''); 
  String langCode = '';
  String compCode = '';
  bool saveIdChecked = false; // id 저장 여부
  bool savePwChecked = false; // pw 저장 여부
  bool isLoading = false;

  //최초 실행
  @override
  void initState() {
    super.initState();
    idFocusNode = FocusNode();
    pwFocusNode = FocusNode();
    idController = TextEditingController();
    pwController = TextEditingController();
    scrollController = ScrollController();
    loadCompCodes();
    loadLangCodes();
  }

  @override
  void dispose() {
    idFocusNode.dispose();
    pwFocusNode.dispose();
    idController.dispose();
    pwController.dispose();
    scrollController.dispose();
    super.dispose();
  }

  void showLoadingBar(bool flag) {
    setState(() {
      isLoading = flag;
    });
  }

  void executeLogin() async {
    if (idController.text.trim() == '' || pwController.text.trim() == '') {
      var message = '';
      if (idController.text.trim() == '') {
        message = '사번을 입력해 주세요';
      } else if (pwController.text.trim() == '') {
        message = '비밀번호를 입력해 주세요';
      }
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return Util.ShowMessagePopup(context, message);
        },
      ).then((value) {
        if (message == '사번을 입력해 주세요') {
          idFocusNode.requestFocus();
        } else if (message == '비밀번호를 입력해 주세요') {
          idFocusNode.requestFocus();
        }
      });
    } else {
      final encryptPw =
          Util.encrypter.encrypt(pwController.text, iv: Util.iv).base64;
      showLoadingBar(true);
      var response = await Net.post('/tm/service', {
        'SPNAME': 'APG_MOBILE_LOGIN.EXECUTE_LOGIN',
        'IN_USER_ID': idController.text,
        'IN_PASSWORD': encryptPw,
        'IN_LANG_SET': langCode,
      });
      ReturnObject resultItem =
          ReturnObject.fromJsonMap(jsonDecode(response.body));
      if (resultItem.result == 'SUCCESS' &&
          resultItem.data != null &&
          resultItem.data.length > 0) {
        Map<String, dynamic> data = resultItem.data[0];
        if (data['VALID_PASSWD'] == 'Y') {
          if (saveIdChecked) {
            pref.setBool('IS_SAVE_ID', saveIdChecked);
            pref.setString('SAVE_ID', idController.text);
          } else {
            pref.setBool('IS_SAVE_ID', saveIdChecked);
            pref.remove('SAVE_ID');
          }
          if (savePwChecked) {
            pref.setBool('IS_SAVE_PW', savePwChecked);
            pref.setString('SAVE_PW', pwController.text);
          } else {
            pref.setBool('IS_SAVE_PW', savePwChecked);
            pref.remove('SAVE_PW');
          }
          Util.USER_INFO = data;
          showLoadingBar(false);
          Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (context) => Home()));
        } else {
          showLoadingBar(false);
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return Util.ShowMessagePopup(
                  context, '로그인에 실패하였습니다.\n사번, 비밀번호 확인 후 재 로그인해 주세요.');
            },
          );
        }
      } else {
        showLoadingBar(false);
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return Util.ShowMessagePopup(
                context, '로그인에 실패하였습니다.\n사번, 비밀번호 확인 후 재 로그인해 주세요.');
          },
        );
      }
    }
  }

  Future<void> loadCompCodes() async {
    compCodes.add(DropDownCode('1100', 'KO', '[SYEH] Korea'));
    compCodes.add(DropDownCode('7400', 'ME', '[SYEH] Mexico'));
    selectedCompCode = compCodes.first;
  }

  Future<void> loadLangCodes() async {
    //preference에 ID, PW 저장 값 호출위해 pref 객체 생성
    pref = await SharedPreferences.getInstance();
    print(pref.getBool('IS_SAVE_ID'));

    bool idFlag = false;
    bool pwFlag = false;

    if (pref.get('IS_SAVE_ID') != null) {
      idFlag = pref.getBool('IS_SAVE_ID')!;
    }
    if (pref.get('IS_SAVE_PW') != null) {
      pwFlag = pref.getBool('IS_SAVE_PW')!;
    }

    if (idFlag) {
      saveIdChecked = true;
      idController.text = pref.getString('SAVE_ID')!;
      // 저장된 ID가 있으므로 PW 입력칸에 포커스 설정
      pwFocusNode.requestFocus();
    }
    if (pwFlag) {
      savePwChecked = true;
      pwController.text = pref.getString('SAVE_PW')!;
    }

    setState(() {
      langCodes.add(LangCode('KO', 'Korean'));
      langCodes.add(LangCode('EN', 'English'));
      langCode = 'KO';
    });
  }

  Widget compCodeWidget() {
    return InputDecorator(
      decoration: const InputDecoration(
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.only(right: 10.0)),
      child: DropdownButton2<DropDownCode>(
        underline: const SizedBox.shrink(),
        isExpanded: true,
        icon: Icon(
          Icons.arrow_drop_down,
          color: Color.fromRGBO(0, 80, 155, 1),
          size: 30,
        ),
        items: compCodes.map((DropDownCode code) {
          return DropdownMenuItem(
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
            selectedCompCode = value!;
          });
        },
        barrierColor: Colors.transparent,
        focusColor: Colors.transparent,
        selectedItemHighlightColor: Colors.transparent,
        value: selectedCompCode,
        dropdownMaxHeight: 150,
        dropdownDecoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
        ),
        style: const TextStyle(
            fontSize: 17.0, fontFamily: MyFontStyle.nanumGothic),
        hint: const Text(
          'COMPANY',
          style: TextStyle(fontFamily: MyFontStyle.nanumGothic),
        ),
      ),
    );
  }

  Widget _idWidget() {
    return TextFormField(
      keyboardType: TextInputType.number,
      focusNode: idFocusNode,
      style: const TextStyle(fontSize: 17.0),
      decoration: const InputDecoration(
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: Color.fromRGBO(0, 80, 155, 1.0),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: Color.fromRGBO(190, 190, 190, 1.0),
          ),
        ),
        labelText: 'ID',
        labelStyle: TextStyle(
            fontFamily: MyFontStyle.nanumGothicBold,
            color: Color.fromRGBO(110, 110, 110, 1.0)),
        floatingLabelStyle:
            TextStyle(color: Color.fromRGBO(110, 110, 110, 1.0)),
        hintText: '사원번호 6자리를 입력하세요.',
        hintStyle: TextStyle(
            fontFamily: MyFontStyle.nanumGothicBold,
            color: Color.fromRGBO(190, 190, 190, 1.0)),
      ),
      controller: idController,
      autofocus: true,
    );
  }

  Widget _pwWidget() {
    return TextFormField(
      focusNode: pwFocusNode,
      style: const TextStyle(fontSize: 17),
      obscureText: true,
      decoration: const InputDecoration(
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: Color.fromRGBO(0, 80, 155, 1.0),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: Color.fromRGBO(190, 190, 190, 1.0),
          ),
        ),
        labelText: 'PASSWORD',
        labelStyle: TextStyle(
            fontFamily: MyFontStyle.nanumGothicBold,
            color: Color.fromRGBO(110, 110, 110, 1.0)),
        floatingLabelStyle:
            TextStyle(color: Color.fromRGBO(110, 110, 110, 1.0)),
        hintText: '비밀번호를 입력하세요.',
        hintStyle: TextStyle(
            fontFamily: MyFontStyle.nanumGothicBold,
            color: Color.fromRGBO(190, 190, 190, 1.0)),
      ),
      controller: pwController,
      textInputAction: TextInputAction.go,
      onFieldSubmitted: (value) async {
        executeLogin();
      },
    );
  }

  Widget langCodeWidget() {
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
        items: langCodes.map((langCode) {
          return DropdownMenuItem(
            value: langCode.code,
            child: Text(
              langCode.name,
              style: const TextStyle(
                  color: Colors.black,
                  fontSize: 15.0,
                  fontFamily: MyFontStyle.nanumGothic),
            ),
          );
        }).toList(),
        onChanged: (value) async {
          setState(() {
            langCode = value!;
          });
        },
        barrierColor: Colors.transparent,
        focusColor: Colors.transparent,
        selectedItemHighlightColor: Colors.transparent,
        value: langCode,
        dropdownMaxHeight: 150,
        dropdownDecoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
        ),
        style: const TextStyle(
            fontSize: 17.0, fontFamily: MyFontStyle.nanumGothic),
        hint: const Text(
          'LANGUAGE',
          style: TextStyle(fontFamily: MyFontStyle.nanumGothic),
        ),
      ),
    );
  }

  Widget saveIdButton() {
    return SizedBox(
      width: 150.0,
      height: 75.0,
      child: LabeledCheckbox(
        label: '아이디 저장',
        padding: const EdgeInsets.symmetric(horizontal: 0.0),
        value: saveIdChecked,
        onChanged: (bool newValue) {
          setState(() {
            saveIdChecked = newValue;
          });
        },
      ),
    );
  }

  Widget savePwButton() {
    return SizedBox(
      width: 150.0,
      height: 75.0,
      child: LabeledCheckbox(
        label: '비밀번호 저장',
        padding: const EdgeInsets.symmetric(horizontal: 0.0),
        value: savePwChecked,
        onChanged: (bool newValue) {
          setState(() {
            savePwChecked = newValue;
          });
        },
      ),
    );
  }

  Widget _loginButtonWidget() {
    return ElevatedButton(
        style: ElevatedButton.styleFrom(
            splashFactory: NoSplash.splashFactory,
            backgroundColor: Color.fromRGBO(0, 80, 155, 1),
            textStyle: const TextStyle(fontSize: 20.0),
            fixedSize: const Size(400.0, 60.0)),
        onPressed: () async {
          executeLogin();
        },
        child: const Text('Login',
            style: TextStyle(fontFamily: MyFontStyle.nanumGothic)));
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      child: Stack(children: <Widget>[
        Scaffold(
          appBar: null,
          body: PinchZoom(
            maxScale: 2,
            resetDuration: Duration(milliseconds: 200),
            zoomEnabled: true,
            child: /* SingleChildScrollView(
              controller: scrollController,
              child:  */Center(
                child: SizedBox(
                  height: 600.0,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 400.0,
                        height: 100.0,
                        child: Image.asset('images/SEOYONEH_CI.png'),
                      ),
                      // SizedBox(width: 400.0, height: 60.0, child: compCodeWidget()),
                      SizedBox(width: 400.0, height: 70.0, child: _idWidget()),
                      SizedBox(width: 400.0, height: 70.0, child: _pwWidget()),
                      SizedBox(width: 400.0, height: 50.0, child: langCodeWidget()),
                      SizedBox(
                          width: 400.0,
                          height: 40.0,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: <Widget>[saveIdButton(), savePwButton()],
                          )),
                      SizedBox(
                          width: 400.0, height: 60.0, child: _loginButtonWidget()),
                    ],
                  ),
                ),
              ),
            // )
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
      ]),
      onWillPop: () async {
        await Util.onExitApp(context);
        return false;
      },
    );
  }
}

class LangCode {
  const LangCode(this.code, this.name);

  final String code;
  final String name;

  @override
  String toString() {
    return '$code: $name';
  }
}

class CompCode {
  const CompCode(this.code, this.name);

  final String code;
  final String name;

  @override
  String toString() {
    return '$code: $name';
  }
}

class LabeledCheckbox extends StatelessWidget {
  const LabeledCheckbox({
    super.key,
    required this.label,
    required this.padding,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final EdgeInsets padding;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        onChanged(!value);
      },
      hoverColor: Colors.transparent,
      splashColor: Colors.transparent,
      focusColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: Padding(
        padding: padding,
        child: Row(
          children: <Widget>[
            SizedBox(
              height: 24.0,
              width: 24.0,
              child: Transform.scale(
                scale: 1.5,
                child: Checkbox(
                  value: value,
                  onChanged: (bool? newValue) {
                    onChanged(newValue!);
                  },
                  checkColor: const Color.fromRGBO(250, 175, 25, 1.0),
                  fillColor: MaterialStateColor.resolveWith(
                      (states) => Colors.transparent),
                  side: MaterialStateBorderSide.resolveWith((states) =>
                      const BorderSide(
                          color: Color.fromRGBO(0, 80, 155, 1.0), width: 2.0)),
                ),
              ),
            ),
            const SizedBox(
              height: 32.0,
              width: 10.0,
            ),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontFamily: MyFontStyle.nanumGothic,
                  fontSize: 18.0,
                  color: Color.fromRGBO(110, 110, 110, 1.0),
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
