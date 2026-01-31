abstract class AllTypes {
  // Primitives
  Future<String> getString();
  Future<int> getInt();
  Future<double> getDouble();
  Future<bool> getBool();
  Future<void> voidMethod();

  // Collections
  Future<List<String>> getList();
  Future<Map<String, dynamic>> getMap();

  // Streams
  Stream<String> onString();
  Stream<int> onInt();
  Stream<Map<String, dynamic>> onMap();
}
