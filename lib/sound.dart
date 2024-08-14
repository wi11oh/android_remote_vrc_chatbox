import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:soundpool/soundpool.dart';
import 'dart:io';

enum SeSoundIds { send }

class SeSound {
  String os = Platform.operatingSystem;
  bool isIOS = Platform.isIOS;
  late Soundpool _soundPool;

  final Map<SeSoundIds, int> _seContainer = {};
  final Map<int, int> _streamContainer = {};

  SeSound() {
    _soundPool = Soundpool.fromOptions(options: const SoundpoolOptions(
      streamType: StreamType.music,
      maxStreams: 5,
    ));
    () async {
      var send = await rootBundle.load("assets/se/send.mp3").then((value) => _soundPool.load(value));
      _seContainer[SeSoundIds.send] = send;
      _streamContainer[send] = 0;
    }();
  }

  void playSe(SeSoundIds ids) async {
    var seId = _seContainer[ids];
    if (seId != null) {
      var streamId = _streamContainer[seId] ?? 0;
      if (streamId > 0 && isIOS) {
        await _soundPool.stop(streamId);
      }
      _streamContainer[seId] = await _soundPool.play(seId);
    } else {
      debugPrint("error se");
    }
  }

  Future<void> dispose() async {
    await _soundPool.release();
    _soundPool.dispose();
  }
}
