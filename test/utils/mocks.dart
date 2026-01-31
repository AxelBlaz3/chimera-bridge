import 'package:mason/mason.dart';
import 'package:mockito/annotations.dart';

@GenerateNiceMocks([
  MockSpec<HookContext>(),
  MockSpec<Logger>(),
])
// ignore: unused_import
import 'mocks.mocks.dart';
