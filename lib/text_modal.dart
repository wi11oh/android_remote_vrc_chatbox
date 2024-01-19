import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';

import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:remote_vrc_chatbox/env.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'package:fluttertoast/fluttertoast.dart';






void showTextModal(BuildContext context, TextEditingController txc) async {
  final context_ = context;

  showModalBottomSheet<void>(
    context: context_,
    builder: (BuildContext context) {
      return SizedBox(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
            ListTile(
              leading: const FaIcon(FontAwesomeIcons.clone,
                size: 20,
              ),
              title: const Text('コピー',
                style: TextStyle(
                  fontFamily: "NotoJP"
                ),
              ),
              subtitle: const Text("入力欄の文字列をコピーします",
                style: TextStyle(
                  fontFamily: "NotoJP"
                ),
              ),
              onTap: () {
                if(txc.text != ""){
                  Clipboard.setData(ClipboardData(text: txc.text));
                }
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const FaIcon(FontAwesomeIcons.deleteLeft,
                size: 20,
              ),
              title: const Text("削除",
                style: TextStyle(
                  fontFamily: "NotoJP"
                ),
              ),
              subtitle: const Text("入力欄の入力を消します",
                style: TextStyle(
                  fontFamily: "NotoJP"
                ),
              ),
              onTap: () {
                txc.text = "";
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const FaIcon(FontAwesomeIcons.globe,
                size: 20,
              ),
              title: const Text("開く",
                style: TextStyle(
                  fontFamily: "NotoJP"
                ),
              ),
              subtitle: const Text("入力欄の文字列がURLなら移動、文字列なら検索します",
                style: TextStyle(
                  fontFamily: "NotoJP"
                ),
              ),
              onTap: () {
                bool isURL(String input) {
                  RegExp urlRegex = RegExp(
                    r'^(https?|mailto):\/\/'
                    r'(?:(?:[A-Z0-9](?:[A-Z0-9-]{0,61}[A-Z0-9])?\.)+(?:[A-Z]{2,6}\.?|[A-Z0-9-]{2,}\.?)|'
                    r'localhost|'
                    r'\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})'
                    r'(?::\d+)?'
                    r'(?:\/\S*)?$',
                    caseSensitive: false,
                  );
                  return urlRegex.hasMatch(input);
                }

                if (isURL(txc.text)) {
                  launchUrl(
                    Uri.parse(txc.text),
                    mode: LaunchMode.externalApplication
                  );
                } else {
                  launchUrl(
                    Uri.parse("https://www.google.com/search?q=${txc.text}"),
                    mode: LaunchMode.externalApplication
                  );
                }

                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const FaIcon(FontAwesomeIcons.language,
                size: 20,
              ),
              title: const Text('翻訳',
                style: TextStyle(
                  fontFamily: "NotoJP"
                ),
              ),
              subtitle: const Text("Google で翻訳",
                style: TextStyle(
                  fontFamily: "NotoJP"
                ),
              ),
              onTap: () async {
                if (txc.text != "") {
                  String textToTranslate = txc.text;

                  txc.text = "翻訳中…";

                  String apiKey = Env.gcptl;
                  String targetLanguage = 'en';
                  String apiUrl = 'https://translation.googleapis.com/language/translate/v2';
                  String translatedText = "";

                  final response = await http.post(Uri.parse('$apiUrl?key=$apiKey&q=$textToTranslate&target=$targetLanguage'));

                  if (response.statusCode == 200) {
                    Map<String, dynamic> jsonResponse = json.decode(response.body);
                    translatedText = jsonResponse['data']['translations'][0]['translatedText'];
                    translatedText = translatedText.replaceAll("&#39;", "'");

                    showTranslateModal(context: context_, translatedText: translatedText, txc: txc);
                  } else {
                    Fluttertoast.showToast(
                      msg: "エラー status:${response.statusCode}",
                      gravity: ToastGravity.BOTTOM,
                      toastLength: Toast.LENGTH_LONG,
                      backgroundColor: const Color.fromARGB(255, 19, 19, 19),
                      textColor: Colors.white,
                      fontSize: 20
                    );
                    txc.text = "";
                  }
                  // Navigator.pop(context);
                }

              },
            ),
          ],
        )),
      );
    },
  );
}

void showTranslateModal({
  required BuildContext context,
  required String translatedText,
  required TextEditingController txc,
}) {
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text("翻訳",
              style: TextStyle(
                fontFamily: "NotoJP"
              ),
            ),
            Image.asset("assets/images/color-short.png"),
          ],
        ),
        content: SelectableText(translatedText),
        actions: [
          TextButton.icon(
            icon: const FaIcon(
              FontAwesomeIcons.turnDown,
              size: 20,
            ),
            label: const Text("翻訳結果を入力欄にペースト"),
            onPressed: () {
              txc.text = translatedText;
              Navigator.popUntil(context, (route) => route.isFirst);
            },
          ),
        ],
      );
    },
  );
}