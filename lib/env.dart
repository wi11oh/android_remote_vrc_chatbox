import 'package:envied/envied.dart';

part 'env.g.dart';

@Envied(path: '.env')
abstract class Env {
  @EnviedField(varName: 'GCP_TRANSLATION', obfuscate: true)
  static String gcptl = _Env.gcptl;
  // @EnviedField(varName: 'MINHONAPIKEY', obfuscate: true)
  // static String mhk = _Env.mhk;
  // @EnviedField(varName: 'MINHONAPIKEYS', obfuscate: true)
  // static String mhks = _Env.mhks;
  // @EnviedField(varName: 'MINHONNAME', obfuscate: true)
  // static String mhn = _Env.mhn;
}

