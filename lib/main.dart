import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:remote_vrc_chatbox/drawer.dart';
import "package:remote_vrc_chatbox/themeProvider.dart";

import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:remote_vrc_chatbox/text_modal.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:osc/osc.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:provider/provider.dart';



int theme = 0;


void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ChangeNotifierProvider(
      create: (context) => ThemeProvider(),
      child: const MyApp(),
    )
  );
}

// class ThemeProvider with ChangeNotifier {
//   bool _isDarkTheme = false;

//   bool get isDarkTheme => _isDarkTheme;

//   void toggleTheme() {
//     _isDarkTheme = !_isDarkTheme;
//     notifyListeners(); // Notify listeners that theme has changed
//   }
// }




class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: themeProvider.isDarkTheme ? ThemeData.light() : ThemeData.dark(),
          home: const MyForm(),
    );
      },
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
  bool _isTextFieldEmpty = true;
  ScrollController scc = ScrollController();
  GlobalKey listviewKey = GlobalKey();

  List<String> items = [];
  List<String> times = [];
  List<String> modes = [];

  SpeechToText speechToText = SpeechToText();
  bool isListenning = false;






  @override
  void initState() {

    super.initState();
    readConnSet();
    connectToWebSocket();

    txc.addListener(_updateTextFieldState);

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
    txc.removeListener(_updateTextFieldState);
    super.dispose();
  }




  void _updateTextFieldState() {
    setState(() {
      _isTextFieldEmpty = txc.text.isEmpty;
    });
  }




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
    _streamSubscription = _channel.stream.listen((message) {
      String historyViewMode = "copy (PC→mobile)";

      final streamMap = jsonDecode(message) as Map<String, dynamic>;

      setState(() {
        _addItem(streamMap["clip"], historyViewMode);
        debugPrint("clip : ${streamMap["clip"]}");
        Clipboard.setData(ClipboardData(text: streamMap["clip"]));
        txc.clear();
        scc.animateTo(
          scc.position.maxScrollExtent + 87,
          duration: const Duration(seconds: 1),
          curve: Curves.fastLinearToSlowEaseIn
        );
      });
    });

  }




  Future<void> reconnectWebsocket() async {
    _channel.sink.close();
    await Future.delayed(const Duration(seconds: 5), () {});
    connectToWebSocket();
  }




  void disconnectWebsocket() async {
    _channel.sink.close();
    debugPrint("disconnect");
  }




  void websocket(text) {
    try {
      _channel.sink.add(text);
    } catch (e) {
      debugPrint("$e");
    }
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




  void _addItem(String text,String mode) {
    setState(() {
      items.add(text);
      times.add(DateFormat('yyyy/MM/dd HH:mm:ss').format(DateTime.now()));
      modes.add(mode);
    });
  }




  // bool checkListviewOverflow() {
  //   final RenderBox listviewRB = listviewKey.currentContext!.findRenderObject() as RenderBox;
  //   final lvHeight = listviewRB.size.height;
  //   final lvContentHeight = listviewRB.paintBounds.size.height;
  //   return lvContentHeight >= lvHeight;
  // }




  void addViewAndAnim(String text, String historyViewMode) {
    _addItem(text, historyViewMode);
    txc.clear();
    scc.animateTo(
      scc.position.maxScrollExtent + 87,
      duration: const Duration(seconds: 1),
      curve: Curves.fastLinearToSlowEaseIn
    );
  }




  send (Map payload) {
    final payloadjson = jsonEncode(payload);
    String historyViewMode = "unknown";
    if (payload["mode"] == "nomal" && payload["textmsg"] != "") {
      if (_isWebsocket) {
        historyViewMode = "text (advanced/WS)";
        websocket(payloadjson);
      } else {
        historyViewMode = "text (nomal/OSC)";
        final message = OSCMessage("/chatbox/input", arguments: [payload["textmsg"], true]);
        const port = 9000;
        RawDatagramSocket.bind(InternetAddress.anyIPv4, 0)
        .then((socket) => socket.send(message.toBytes(), InternetAddress(_ipAddr), port))
        .catchError((e) {
          debugPrint('Error: $e');
          return -1;
        });
      }
      addViewAndAnim(payload["textmsg"], historyViewMode);
    } else if (payload["mode"] == "paste" && payload["textmsg"] != "" && _isWebsocket) {
      historyViewMode = "paste (mobile→PC)";
      websocket(payloadjson);
      addViewAndAnim(payload["textmsg"], historyViewMode);
    } else if (payload["mode"] == "copy" && payload["textmsg"] == "" && _isWebsocket) {
      historyViewMode = "copy (PC→mobile)";
      websocket(payloadjson);
    } else {
      debugPrint("empty");
    }
  }
  void submit (Map payload) {
    send(payload);
  }
  void submit2 () {
    Map<String, String> payload = {
      "mode": "nomal",
      "textmsg": txc.text
    };
    send(payload);
  }




  void pressedit(i) {
    setState(() {
      txc.text = items[i];
    });
  }






  @override
  Widget build(BuildContext context) {


    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      systemNavigationBarColor: Colors.white
    ));





    return Scaffold(
      extendBodyBehindAppBar: true,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: 5,
              sigmaY: 5
            ),
            child: Container(),),
        ),
        iconTheme: const IconThemeData(
        ),
        centerTitle: true,
        // shape: const Border(
        //   bottom: BorderSide(
        //     color: Color.fromARGB(255, 19, 19, 19),
        //     width: 2
        //   )
        // ),
        elevation: 0.0,
        title: const Text(
          "remote vrc-chatbox",
          style: TextStyle(
            fontSize: 24,
            fontFamily: "Din"
          )
        ),
        actions: <Widget>[
          IconButton(
            onPressed: () {
              Provider.of<ThemeProvider>(context, listen: false).toggleTheme();
              setState(() {
                SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
                  systemNavigationBarColor: Theme.of(context).brightness == Brightness.light ? const Color(0xff1c1b1f) : Colors.white
                ));
              });
            },
            icon: const FaIcon(
              FontAwesomeIcons.circleHalfStroke,
              size: 20,
            ))
        ]
        ,
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
              key: listviewKey,
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
                        border: Border.all(
                          width: 2,
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
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    times[index],
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontFamily: "Din"
                                    ),
                                  ),
                                  Text(
                                    " / ${modes[index]}",
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontFamily: "Din"
                                    ),
                                  ),
                                ],
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
                                width: 2,
                                color: const Color.fromARGB(0, 0, 0, 0)
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
                                  Map<String, String> payload = {
                                    "mode": "nomal",
                                    "textmsg": txc.text
                                  };
                                  submit(payload);
                                });
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
                                decoration: BoxDecoration(
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(20),
                                    topRight: Radius.circular(20),
                                    bottomRight: Radius.circular(20)
                                  ),
                                  border: Border.all(
                                    color: Colors.black
                                  )
                                ),
                                width: 250,
                                child: const Center(
                                  child: Text(
                                    "音声認識中 …\nPTT(押してる間だけ認識)です",
                                    style: TextStyle(
                                      fontFamily: "NotoJP",
                                      fontSize: 15,
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
                            width: 2,
                            color:const Color.fromARGB(0, 0, 0, 0)
                          ),
                        ),
                        width: 40,
                        height: 40,
                        child: IconButton(
                          onPressed: (!(_isWebsocket)) ? null : () {
                            if (txc.text == "") {
                              Map<String, String> payload = {
                                "mode": "copy",
                                "textmsg": ""
                              };
                              submit(payload);
                            } else {
                              Map<String, String> payload = {
                                "mode": "paste",
                                "textmsg": txc.text
                              };
                              submit(payload);
                            }
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
                            Map<String, String> payload = {
                              "mode": "nomal",
                              "textmsg": txc.text
                            };
                            submit(payload);
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
                                width: 2
                              )
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: const BorderSide(
                                width: 2
                              )
                            ),
                            prefixIcon: IconButton(
                              onPressed: (!(_isTextFieldEmpty))
                                  ? () async {
                                      showTextModal(context, txc);
                                    }
                                  : null,
                              splashRadius: 20,
                              iconSize: 15,
                              padding: EdgeInsets.zero,
                              color: (!(_isTextFieldEmpty))
                                ? Theme.of(context).brightness == Brightness.light
                                    ? const Color.fromARGB(255, 39, 39, 39)
                                    : Colors.white
                                : Theme.of(context).brightness == Brightness.light
                                    ? const Color.fromARGB(255, 39, 39, 39)
                                    : Colors.black,
                              icon: const FaIcon(FontAwesomeIcons.ellipsis),
                            ),
                            suffixIcon: IconButton(
                              splashRadius: 20,
                              color: (!(_isTextFieldEmpty))
                                ? Theme.of(context).brightness == Brightness.light
                                    ? const Color.fromARGB(255, 39, 39, 39)
                                    : Colors.white
                                : Theme.of(context).brightness == Brightness.light
                                    ? const Color.fromARGB(255, 39, 39, 39)
                                    : Colors.black,
                              iconSize: 20,
                              padding: EdgeInsets.zero,
                              onPressed: (!(_isTextFieldEmpty)) ? submit2 : null,
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
