// I don't have dependency management in this example project.
// Just pretend that these variables are coming from some DI library.

import 'package:bloc_interop/blocs/counter_bloc.dart';

class Injector {
  CounterBloc counterBloc;
  Injector._() : counterBloc = CounterBloc();
  static Injector? _instance;
  static Injector instance() => _instance ??= Injector._();
}
