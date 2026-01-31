import 'package:mason/mason.dart';
import 'package:mockito/annotations.dart';

@GenerateNiceMocks([
  MockSpec<HookContext>(),
  MockSpec<Logger>(),
])
import 'mocks.mocks.dart';
