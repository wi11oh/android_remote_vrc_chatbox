import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:remote_vrc_chatbox/drawer.dart';

import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:remote_vrc_chatbox/env.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:http/http.dart' as http;
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:osc/osc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:speech_to_text/speech_to_text.dart';






void main() => runApp(const MyApp());






class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MyForm(),
    );
  }
}






class MyForm extends StatefulWidget {
  const MyForm({Key? key}) : super(key: key);
  @override
  MyFormState createState() => MyFormState();
}






class MyFormState extends State<MyForm> {

  late StreamSubscription _intentDataStreamSubscription;
  late WebSocketChannel _channel;
  late String _ipAddr;
  late StreamSubscription<dynamic> _streamSubscription;
  late bool _isWebsocket = false;

  String? _sharedText;
  TextEditingController txc = TextEditingController();
  ScrollController scc = ScrollController();

  List<String> items = [];
  List<String> times = [];

  SpeechToText speechToText = SpeechToText();
  bool isListenning = false;






  @override
  void initState() {

    super.initState();
    readConnSet();
    connectToWebSocket();

    _intentDataStreamSubscription = ReceiveSharingIntent.getTextStream().listen((String value) {
      setState(() {
        _sharedText = value;
        debugPrint("Shared: $_sharedText");
        txc.text = value;
      });
    }, onError: (err) {
      debugPrint("getLinkStream error: $err");
    });

    ReceiveSharingIntent.getInitialText().then((String? value) {
      setState(() {
        _sharedText = value;
        debugPrint("Shared: $_sharedText");
        txc.text = _sharedText ?? "";
      });
    });

  }




  @override
  void dispose() {
    _streamSubscription.cancel();
    _intentDataStreamSubscription.cancel();
    _channel.sink.close();
    super.dispose();
  }




  // void setOSCServer() async {

  //   for (var interface in await  NetworkInterface.list()) {
  //     print('== Interface: ${interface.name} ==');
  //     for (var addr in interface.addresses) {
  //       print(
  //           '!!!!!!!!!!!!!!!!!!!!!!${addr.address} ${addr.host} ${addr.isLoopback} ${addr.rawAddress} ${addr.type.name}');
  //     }
  //   }

  //   _server = OSCSocket(serverPort: 41129);
  //   _server.listen((msg) {
  //     print("==================================================================================${msg.toString()}");
  //     txc.text = msg.toString();
  //   });
  // }




  Future<void> connectToWebSocket() async {

    String value = "192.168.0.10";

    try {
      final p = await SharedPreferences.getInstance();
      value = p.getString("ip") ?? "192.168.0.10";
    } catch (e) {
      debugPrint("$e");
    }

    _ipAddr = value;


    debugPrint("connect  $value");
    _channel = WebSocketChannel.connect(Uri.parse("ws://$value:41129"));
    _streamSubscription = _channel.stream.listen(
      (message) {
      },
    );

  }




  Future<void> reconnectWebsocket() async {
    if (_isWebsocket) {
      _channel.sink.close();
      await Future.delayed(const Duration(seconds: 5), () {});
      connectToWebSocket();
    }
  }




  void disconnectWebsocket() async {
    _channel.sink.close();
    debugPrint("disconnect");
  }




  void websocket(text) {
    _channel.sink.add(text);
  }




  Future<void> readConnSet() async {

    bool value = false;
    try {
      final p = await SharedPreferences.getInstance();
      value = p.getBool("isWebsocket") ?? false;
    } catch (e) {
      debugPrint("$e");
    }

    setState(() {
      _isWebsocket = value;
    });

  }




  void _addItem(text) {
    setState(() {
      items.add(text);
      times.add(DateFormat('yyyy/MM/dd HH:mm:ss').format(DateTime.now()));
    });
  }




  send (text) {

    if (text != "") {
      if (_isWebsocket) {
        if (text.replaceAll("[remote_vrc_chatbox_action:paste]", "") == "") {
        } else {
          websocket(text);
          debugPrint(text);
          text = text.replaceAll("[remote_vrc_chatbox_action:paste]", "");
          _addItem(text);
          txc.clear();
          debugPrint("$items");
          scc.animateTo(
          scc.position.maxScrollExtent + 90,
          duration: const Duration(seconds: 1),
          curve: Curves.fastLinearToSlowEaseIn
          );
        }
      } else {
        text = text.replaceAll("[remote_vrc_chatbox_action:paste]", "");

        final message = OSCMessage("/chatbox/input", arguments: [text, true]);
        const port = 9000;

        RawDatagramSocket.bind(InternetAddress.anyIPv4, 0)
        .then((socket) => socket.send(message.toBytes(), InternetAddress(_ipAddr), port))
        .catchError((e) {
          debugPrint('Error: $e');
          return -1;
        });
        _addItem(text);
        txc.clear();
        scc.animateTo(
        scc.position.maxScrollExtent + 90,
        duration: const Duration(seconds: 1),
        curve: Curves.fastLinearToSlowEaseIn
        );
      }
    }

  }




  submit (String text_) {
    String text = text_;
    send(text);
  }
  submit2 () {
    String text = txc.text;
    send(text);
  }




  pressedit(i) {
    txc.text = items[i];
  }






  @override
  Widget build(BuildContext context) {

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        systemNavigationBarColor: Colors.white
      )
    );



    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        iconTheme: const IconThemeData(
          color: Color.fromARGB(255, 19, 19, 19)
        ),
        centerTitle: true,
        shape: const Border(
          bottom: BorderSide(
            color: Color.fromARGB(255, 19, 19, 19),
            width: 2
          )
        ),
        backgroundColor: Colors.white,
        elevation: 0.0,
        title: const Text(
          "remote vrc-chatbox",
          style: TextStyle(
            color: Color.fromARGB(255, 19, 19, 19),
            fontSize: 24,
            fontFamily: "Din"
          )
        ),
      ),
      drawer: InDrawerWidget(
        reconnectWebsocketCallback: reconnectWebsocket,
        releadConnSetting: readConnSet,
        disconnectWebsocket: disconnectWebsocket
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: ListView.builder(
              controller: scc,
              itemCount: items.length,
              itemBuilder: (context, index) {
                return ListBody(
                  children: [
                    Container(
                      margin: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                      padding: const EdgeInsets.fromLTRB(25, 10, 25, 10),
                      height: 67,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(100),
                        color: const Color.fromARGB(0, 19, 19, 19),
                        border: Border.all(
                          color: const Color.fromARGB(255, 19, 19, 19),
                          width: 2
                        )
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                times[index],
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontFamily: "Din"
                                ),
                              ),
                              SizedBox(
                                width: MediaQuery.of(context).size.width - 122,
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Text(
                                    items[index],
                                    softWrap: false,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontFamily: "NotoJP",
                                    ),
                                  ),
                                ),
                              )
                            ],
                          ),
                          IconButton(
                            onPressed: () {
                              pressedit(index);
                            },
                            icon: const FaIcon(
                              FontAwesomeIcons.pen,
                              size: 22,
                              color: Color.fromARGB(255, 19, 19, 19),
                            ),
                          )
                        ],
                      )
                    ) ,
                  ]
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(
              color:  Color.fromARGB(255, 19, 19, 19),
            width: 2
            )
          )
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Positioned(
            //   top: -50,
            //   left: ((MediaQuery.of(context).size.width)-(MediaQuery.of(context).size.width * 0.9))/2,
            //   child: Container(
            //     width: MediaQuery.of(context).size.width * 0.9,
            //     height: 40,
            //     padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
            //     decoration: BoxDecoration(
            //       borderRadius:BorderRadius.circular(20),
            //       color: const Color.fromARGB(255, 19, 19, 19),
            //     ),
            //     child: Row(
            //       mainAxisAlignment: MainAxisAlignment.spaceAround,
            //       crossAxisAlignment: CrossAxisAlignment.center,
            //       children: [
            //         TextButton.icon(
            //           style: const ButtonStyle(
            //             padding: MaterialStatePropertyAll(EdgeInsets.fromLTRB(2, 0, 2, 0)),
            //           ),
            //           onPressed: ()  {
            //             debugPrint("clip");
            //             // final data = ClipboardData(text: txc.text);
            //             // await Clipboard.setData(data);
            //           },
            //           icon: const FaIcon(
            //             FontAwesomeIcons.solidCopy,
            //             size: 15,
            //             color: Colors.white,
            //           ),
            //           label: const Text(
            //             "コピー",
            //             style: TextStyle(
            //               fontSize: 15,
            //               color: Colors.white
            //             ),
            //           ),
            //         ),
            //         TextButton.icon(
            //           style: const ButtonStyle(
            //             padding: MaterialStatePropertyAll(EdgeInsets.fromLTRB(2, 0, 2, 0)),
            //           ),
            //           onPressed: () {},
            //           icon: const FaIcon(
            //             FontAwesomeIcons.solidClipboard,
            //             size: 15,
            //             color: Colors.white,
            //           ),
            //           label: const Text(
            //             "貼り付け",
            //             style: TextStyle(
            //               fontSize: 15,
            //               color: Colors.white
            //             ),
            //           ),
            //         ),
            //         TextButton.icon(
            //           style: const ButtonStyle(
            //             padding: MaterialStatePropertyAll(EdgeInsets.fromLTRB(2, 0, 2, 0)),
            //           ),
            //           onPressed: () {},
            //           icon: const FaIcon(
            //             FontAwesomeIcons.language,
            //             size: 15,
            //             color: Colors.white,
            //           ),
            //           label: const Text(
            //             "翻訳",
            //             style: TextStyle(
            //               fontSize: 15,
            //               color: Colors.white
            //             ),
            //           ),
            //         ),
            //       ],
            //     ),
            //   ),
            // ),
            BottomAppBar(
              padding: const EdgeInsets.fromLTRB(0, 10, 0, 10),
              elevation: 0.0,
              height: 60 + MediaQuery.of(context).viewInsets.bottom,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(100),
                              border: Border.all(
                                color: const Color.fromARGB(255, 19, 19, 19),
                                width: 2,
                              ),
                            ),
                            width: 40,
                            height: 40,
                            child: GestureDetector(
                              onTapDown: (details) async {
                                if (!isListenning) {
                                  txc.clear();
                                  var available = await speechToText.initialize();
                                  if (available) {
                                    setState(() {
                                      isListenning = true;
                                      speechToText.listen(
                                        onResult:(result) {
                                          setState(() {
                                            txc.text = result.recognizedWords;
                                          });
                                        },
                                      );
                                    });
                                  }
                                }
                              },
                              onTapUp: (detail) {
                                isListenning = false;
                                setState(() {
                                  isListenning = false;
                                });
                                speechToText.stop();
                                Future.delayed(const Duration(seconds: 1), () {
                                    submit(txc.text);
                                  }
                                );
                              },
                              child: const Icon(
                                FontAwesomeIcons.microphone,
                                size: 20,
                                ),
                            )
                          ),
                          Visibility(
                            visible: isListenning,
                            child: Positioned(
                              top: -100,
                              left: 20,
                              child: Container(
                                height: 80,
                                decoration: const BoxDecoration(
                                  color: Color.fromARGB(255, 19, 19, 19),
                                  borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(20),
                                    topRight: Radius.circular(20),
                                    bottomRight: Radius.circular(20)
                                  )
                                ),
                                width: 250,
                                child: const Center(
                                  child: Text(
                                    "音声認識中 …\nPTT(押してる間だけ認識)です",
                                    style: TextStyle(
                                      fontFamily: "NotoJP",
                                      fontSize: 15,
                                      color: Colors.white
                                    ),
                                  ),
                                )
                              )
                            ),
                          ),
                        ],
                      ),
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(100),
                          border: Border.all(
                            color: const Color.fromARGB(255, 19, 19, 19),
                            width: 2,
                          ),
                        ),
                        width: 40,
                        height: 40,
                        child: IconButton(
                          onPressed: (!(_isWebsocket)) ? null : () {
                            submit("[remote_vrc_chatbox_action:paste]${txc.text}");
                          },
                          padding: EdgeInsets.zero,
                          iconSize: 20,
                          icon: const FaIcon(FontAwesomeIcons.solidPaste),
                          splashRadius: 20,
                        ),
                      ),
                      SizedBox(
                        width: MediaQuery.of(context).size.width * 0.7,
                        height: 40,
                        child: TextFormField(
                          onEditingComplete: () {
                            submit(txc.text);
                          },
                          style: const TextStyle(
                            fontSize: 20,
                            fontFamily: "NotoJP"
                          ),
                          cursorHeight: 30,
                          scrollPadding: EdgeInsets.zero,
                          controller: txc,
                          decoration: InputDecoration(
                            contentPadding:EdgeInsets.zero,
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: const BorderSide(
                                color: Color.fromARGB(255, 19, 19, 19),
                                width: 2
                              )
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: const BorderSide(
                                color: Color.fromARGB(255, 19, 19, 19),
                                width: 2
                              )
                            ),
                            prefixIcon: IconButton(
                              onPressed: () async {
                                if (txc.text != "") {
                                  String text = txc.text;

                                  txc.text = "翻訳中…";

                                  String url    = 'https://mt-auto-minhon-mlt.ucri.jgn-x.jp';
                                  String key    = Env.mhk;
                                  String secret = Env.mhks;
                                  String name   = Env.mhn;
                                  String apiName  = 'mt';
                                  String apiParam = 'generalNT_ja_en';
                                  dynamic accessToken;

                                  callApi  () async {
                                    var params = {
                                      'access_token': accessToken,
                                      'key': key,
                                      'api_name': apiName,
                                      'api_param': apiParam,
                                      'name': name,
                                      'type': 'json',
                                      'text': text
                                    };
                                    var response = await http.post(Uri.parse('$url/api/'), body: params);
                                    if (response.statusCode != 200) {
                                      debugPrint('Request failed with status: ${response.statusCode}.');
                                      return;
                                    }
                                    debugPrint('response.body: ${response.body}');
                                    var decodeR = jsonDecode(response.body);
                                    txc.text = decodeR['resultset']['result']['text'];
                                  }

                                  var response = await http.post(Uri.parse('$url/oauth2/token.php'), body: {
                                    'grant_type': 'client_credentials',
                                    'client_id': key,
                                    'client_secret': secret,
                                    'urlAccessToken': '$url/oauth2/token.php'
                                  });

                                  if (response.statusCode != 200) {
                                    Fluttertoast.showToast(
                                      msg: "エラー status:${response.statusCode}",
                                      gravity: ToastGravity.BOTTOM,
                                      toastLength: Toast.LENGTH_LONG,
                                      backgroundColor: const Color.fromARGB(255, 19, 19, 19),
                                      textColor: Colors.white,
                                      fontSize: 20
                                    );
                                    return;
                                  }

                                  try{
                                    accessToken = jsonDecode(response.body)['access_token'];
                                  } catch (e) {
                                    debugPrint('$e');
                                    return;
                                  }

                                  if (accessToken == null) {
                                    debugPrint('response: $response');
                                    return;
                                  }

                                  callApi();
                                }
                              },
                              splashRadius: 20,
                              iconSize: 15,
                              padding: EdgeInsets.zero,
                              color: const Color.fromARGB(255, 82, 82, 82),
                              icon: const FaIcon(FontAwesomeIcons.language)),
                            suffixIcon: IconButton(
                              splashRadius: 20,
                              color: const Color.fromARGB(255, 19, 19, 19),
                              iconSize: 20,
                              padding: EdgeInsets.zero,
                              onPressed: submit2,
                              icon: const FaIcon(FontAwesomeIcons.paperPlane),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        )
      ),
    );
  }
}