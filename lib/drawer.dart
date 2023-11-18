import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:remote_vrc_chatbox/thirdparty_nts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:async';
import 'dart:io';
import 'package:fluttertoast/fluttertoast.dart';






class InDrawerWidget extends StatefulWidget {
  final VoidCallback reconnectWebsocketCallback;
  final VoidCallback releadConnSetting;
  final VoidCallback disconnectWebsocket;

  const InDrawerWidget({Key? key,
    required this.reconnectWebsocketCallback,
    required this.releadConnSetting,
    required this.disconnectWebsocket,
  }) : super(key: key);

  @override
  InDrawerWidgetState createState() => InDrawerWidgetState();
}






class InDrawerWidgetState extends State<InDrawerWidget> {
  late bool _isWebsocket = false;




  @override
  void initState() {
    super.initState();
    readConnSet();
  }




  Future<void> _showDialog(BuildContext context) async {
    String value = " -ERROR!- ";

    Future<File> getFilePath() async {
      final directory = await getTemporaryDirectory();
      return File("${directory.path}/rvc_setting.txt");
    }

    Future<String> load() async {
      final file = await getFilePath();
      return file.readAsString();
    }

    Future<void> getIPfromtxt() async {
      value = await load();
    }

    await getIPfromtxt();

    final outerContext = context;
    return showDialog(
      context: outerContext,
      barrierDismissible: false,
      barrierColor: Colors.black87,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("アプリを終了します"),
          content: Text("IPを$valueに設定しました\n再起動をしてください"),
          actions: [
            TextButton(
              child: const Text(
                '再起動',
                style: TextStyle(color: Colors.red),
              ),
              onPressed: () {
                Navigator.pop(context);
                exit(0);
              },
            ),
          ],
        );
      },
    );
  }






  Future<void> wSwitch(String tf, String name) async {

    Future<File> getFilePath() async {
      final directory = await getTemporaryDirectory();
      return File("${directory.path}/$name");
    }

    void write() async {
      getFilePath().then((File file) {
        file.writeAsString(tf);
      });
    }

    write();

  }






  Future<void> readConnSet() async {

    Future<File> getFilePath(name) async {
      final directory = await getTemporaryDirectory();
      return File("${directory.path}/$name");
    }

    Future<String> load(name) async {
      final file = await getFilePath(name);
      return file.readAsString();
    }

    String value = "false";
    try {
      value = await load("conn_setting.txt");
    } catch (e) {
      debugPrint("$e");
    }

    bool b = value.toLowerCase() == 'true';
    setState(() {
      _isWebsocket = b;
    });
  }






  Future<void> _showSettingDialog(BuildContext context) async {
    TextEditingController iptxconn = TextEditingController();
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return  SimpleDialog(
          title: const Text(
            "IP設定",
            style: TextStyle(
              fontFamily: "NotoJP"
            ),
            ),
          children:[
            Container(
              padding: const EdgeInsets.all(15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    keyboardType: const TextInputType.numberWithOptions(
                      signed: false,
                      decimal: true
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'[0-9.]')
                      )
                    ],
                    controller: iptxconn,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 20
                      ),
                      hintText: '例 192.168.0.10',
                      suffixIcon: IconButton(
                        color: const Color.fromARGB(255, 19, 19, 19),
                        onPressed:() {

                          final ipv4Regex = RegExp(
                            r'^(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})$',
                            multiLine: false,
                            caseSensitive: true,
                          );


                          bool isValidIPv4(String input) {
                            if (!ipv4Regex.hasMatch(input)) {
                              return false;
                            }

                            List<int> segments = input.split('.').map((s) => int.parse(s)).toList();
                            for (int segment in segments) {
                              if (segment < 0 || segment > 255) {
                                return false;
                              }
                            }

                            return true;
                          }

                          if (isValidIPv4(iptxconn.text)) {
                            debugPrint("allow=============================================");

                            try {
                              wSwitch(iptxconn.text, "rvc_setting.txt");
                            } catch (e) {
                              debugPrint("$e");
                            }

                            Navigator.pop(context);
                            _showDialog(context);
                          } else {
                            debugPrint("disallow=============================================");
                            Navigator.pop(context);
                            Fluttertoast.showToast(
                              msg: "有効なIPv4アドレスではありません",
                              gravity: ToastGravity.BOTTOM,
                              toastLength: Toast.LENGTH_LONG,
                              backgroundColor: const Color.fromARGB(255, 19, 19, 19),
                              textColor: Colors.white,
                              fontSize: 20
                            );
                          }
                        },
                        icon: const FaIcon(FontAwesomeIcons.rotateLeft)
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(100),
                        borderSide: const BorderSide(
                          color: Color.fromARGB(255, 19, 19, 19),
                          width: 2
                        )
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(100),
                        borderSide: const BorderSide(
                          color: Color.fromARGB(255, 19, 19, 19),
                          width: 2
                        )
                      )
                    ),
                    onFieldSubmitted: (value) {
                      final ipv4Regex = RegExp(
                        r'^(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})$',
                        multiLine: false,
                        caseSensitive: true,
                      );


                      bool isValidIPv4(String input) {
                        if (!ipv4Regex.hasMatch(input)) {
                          return false;
                        }

                        List<int> segments = input.split('.').map((s) => int.parse(s)).toList();
                        for (int segment in segments) {
                          if (segment < 0 || segment > 255) {
                            return false;
                          }
                        }

                        return true;
                      }

                      if (isValidIPv4(iptxconn.text)) {
                        debugPrint("allow=============================================");

                        try {
                          wSwitch(iptxconn.text, "rvc_setting.txt");
                        } catch (e) {
                          debugPrint("$e");
                        }

                        Navigator.pop(context);
                        _showDialog(context);
                      } else {
                        debugPrint("disallow=============================================");
                        Navigator.pop(context);
                        Fluttertoast.showToast(
                          msg: "有効なIPv4アドレスではありません",
                          gravity: ToastGravity.BOTTOM,
                          toastLength: Toast.LENGTH_LONG,
                          backgroundColor: const Color.fromARGB(255, 19, 19, 19),
                          textColor: Colors.white,
                          fontSize: 20
                        );
                      }
                    },
                  ),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(10, 20, 10, 0),
                      child: RichText(
                        text: TextSpan(
                          text: "設定した後はアプリを再起動してください",
                          style: const TextStyle(color: Color.fromARGB(255, 19, 19, 19), fontFamily: "NotoJP"),
                          children: <TextSpan>[
                            const TextSpan(
                              text: "\n\nローカルIPの調べ方は ",
                              style: TextStyle(color: Color.fromARGB(255, 19, 19, 19), fontFamily: "NotoJP")
                            ),
                            TextSpan(
                              text: "ここ",
                              style: const TextStyle(color: Colors.blue, decoration: TextDecoration.underline, fontWeight: FontWeight.bold),
                              recognizer: TapGestureRecognizer() ..onTap = () {
                                launchUrl(
                                  Uri.parse("http://wi11oh.com/other/remote_vrc_chatbox_tips/"),
                                  mode: LaunchMode.externalApplication
                                );
                              },
                            ),
                            const TextSpan(
                                text: " を参照",
                                style: TextStyle(color: Color.fromARGB(255, 19, 19, 19), fontFamily: "NotoJP")
                            ),
                          ]
                        )
                      )
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }






  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Color.fromARGB(255, 19, 19, 19),
                  width: 2
                )
              )
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "remote vrc-chatbox",
                  style: TextStyle(
                    fontFamily: "Din",
                    fontSize: 40
                  ),
                ),
                Text(
                  "made by うぃろー / willoh",
                  style: TextStyle(
                    fontFamily: "Din",
                    fontSize: 10,
                    color: Color.fromARGB(255, 128, 128, 128)
                  )
                ),
              ],
            ),
          ),
          ListTile(
            title: const Text(
              "IP設定",
              style: TextStyle(
                fontFamily: "NotoJP",
                fontSize: 15,
                color: Color.fromARGB(255, 19, 19, 19),
              ),
            ),
            subtitle: const Text("VRChatが起動しているPCのLocal-IP"),
            onTap: () {
              _showSettingDialog(context);
            },
          ),
          SwitchListTile(
            title: const Text(
              "通信方式",
              style: TextStyle(
                fontFamily: "NotoJP",
                fontSize: 15,
                color: Color.fromARGB(255, 19, 19, 19),
              ),
            ),
            subtitle: const Text("OSC <--> Websocket"),
            trackColor: MaterialStateColor.resolveWith(
              (Set<MaterialState> states) {
                if (states.contains(MaterialState.selected)) {
                  // Selected state color
                  return const Color.fromARGB(255, 19, 19, 19);
                }
                if (states.contains(MaterialState.disabled)) {
                  // Disabled state color
                  return const Color.fromARGB(255, 19, 19, 19);
                }
                // Default color
                return const Color.fromARGB(255, 19, 19, 19);
              },
            ),
            activeColor: const Color.fromARGB(255, 160, 160, 160),
            value: _isWebsocket,
            onChanged: (bool value) {
              setState(() {

                _isWebsocket = value;

                try {
                  wSwitch("$value", "conn_setting.txt");
                } catch (e) {
                  debugPrint("$e");
                }

                widget.releadConnSetting();

                if (! _isWebsocket) {
                  widget.disconnectWebsocket();
                }

              });
            },
          ),
          ListTile(
            title: Text(
              "再接続",
              style: TextStyle(
                fontFamily: "NotoJP",
                fontSize: 15,
                color: _isWebsocket ? const Color.fromARGB(255, 19, 19, 19) : const Color.fromARGB(255, 199, 199, 199),
              ),
            ),
            subtitle: const Text("Websocketモードのみ"),
            onTap: (!(_isWebsocket)) ? null : () {
              Navigator.pop(context);
              widget.reconnectWebsocketCallback();
              Fluttertoast.showToast(
                msg: "再接続中… 5秒以上要します🍵",
                gravity: ToastGravity.BOTTOM,
                toastLength: Toast.LENGTH_LONG,
                backgroundColor: const Color.fromARGB(255, 19, 19, 19),
                textColor: Colors.white,
                fontSize: 20
              );
            },
          ),
          ListTile(
            title: const Text(
              "作者のリンク集",
              style: TextStyle(
                fontFamily: "NotoJP",
                fontSize: 15,
                color: Color.fromARGB(255, 19, 19, 19),
              ),
            ),
            onTap: () {
              launchUrl(
                Uri.parse("https://wi11oh.com/links/"),
                mode: LaunchMode.externalApplication
              );
            },
            trailing: const FaIcon(FontAwesomeIcons.upRightFromSquare,
              size: 17,
              color: Color.fromARGB(255, 19, 19, 19)
            ),
          ),
          ListTile(
            title: const Text(
              "法的表示",
              style: TextStyle(
                fontFamily: "NotoJP",
                fontSize: 15,
                color: Color.fromARGB(255, 19, 19, 19),
              ),
            ),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const LicenceView())
              );
            },
          ),
        ],
      ),
    );
  }
}