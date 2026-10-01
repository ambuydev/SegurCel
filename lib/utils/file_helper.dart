import 'file_helper_stub.dart' if (dart.library.html) 'file_helper_web.dart';

abstract class FileHelper {
  static Future<String?> pickFileContent() => FileHelperImpl.pickFileContent();
  static Future<void> saveFile(String content, String fileName) => FileHelperImpl.saveFile(content, fileName);
  static Future<void> openUrl(String url) => FileHelperImpl.openUrl(url);
}
