import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:kphoto/objectbox.g.dart'; // Generated file

class ObjectBoxManager {
  late final Store store;

  ObjectBoxManager._create(this.store);

  static Future<ObjectBoxManager> create() async {
    final docsDir = await getApplicationDocumentsDirectory();
    final store = await openStore(directory: p.join(docsDir.path, "objectbox"));
    return ObjectBoxManager._create(store);
  }
}
