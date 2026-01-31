import 'package:mason/mason.dart';

class MockLogger implements Logger {
  final List<String> infos = [];
  final List<String> errs = [];
  final List<String> details = [];

  @override
  Level level = Level.info;

  @override
  void info(String? message, {LogStyle? style}) => infos.add(message ?? '');

  @override
  void err(String? message, {LogStyle? style}) => errs.add(message ?? '');

  @override
  void detail(String? message, {LogStyle? style}) => details.add(message ?? '');

  @override
  void warn(String? message, {String tag = 'WARN', LogStyle? style}) => infos.add('$tag: $message');

  @override
  void success(String? message, {LogStyle? style}) => infos.add('SUCCESS: $message');

  @override
  void alert(String? message, {LogStyle? style}) => infos.add('ALERT: $message');
  
  @override
  String prompt(String? message, {Object? defaultValue, bool hidden = false}) => '';

  @override
  bool confirm(String? message, {bool defaultValue = false}) => defaultValue;

  @override
  Progress progress(String message, {ProgressOptions? options}) => _MockProgress();

  // Correct Generic Implementation
  @override
  List<T> chooseAny<T extends Object?>(String? message, {required List<T> choices, List<T>? defaultValues, String Function(T choice)? display}) {
    return [];
  }

  @override
  T chooseOne<T extends Object?>(String? message, {required List<T> choices, T? defaultValue, String Function(T choice)? display}) {
    if (defaultValue != null) return defaultValue;
    return choices.first;
  }
  
  @override
  void write(String? message) => infos.add(message ?? '');
  
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MockProgress implements Progress {
  @override
  void cancel() {}

  @override
  void complete([String? update]) {}

  @override
  void fail([String? update]) {}

  @override
  void update(String update) {}
}

class MockContext implements HookContext {
  @override
  Map<String, dynamic> vars = {};

  @override
  final Logger logger;

  MockContext({Logger? logger}) : logger = logger ?? MockLogger();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
