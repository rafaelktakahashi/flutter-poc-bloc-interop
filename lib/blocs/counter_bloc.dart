import 'package:bloc_interop/blocs/infra/interop_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class CounterEvent {}

class CounterEventIncrement extends CounterEvent {
  int step;

  CounterEventIncrement.by(this.step);
}

class CounterEventMultiply extends CounterEvent {
  int factor;

  CounterEventMultiply.by(this.factor);
}

class CounterEventReset extends CounterEvent {}

abstract class CounterState {}

class CounterStateNumber extends CounterState {
  int value;

  CounterStateNumber(this.value);

  CounterStateNumber add(int offset) {
    return CounterStateNumber(value + offset);
  }

  CounterStateNumber multiply(int factor) {
    return CounterStateNumber(value * factor);
  }
}

class CounterStateError extends CounterState {
  String errorMessage;

  CounterStateError(this.errorMessage);
}

/// Our counter bloc that extends from our InteropBloc.
/// The InteropBloc provides extra functionality for automatically making this
/// bloc usable from the native side, but requires us to implement a few
/// extra methods.
class CounterBloc extends InteropBloc<CounterEvent, CounterState> {
  CounterBloc() : super(CounterStateNumber(0)) {
    // Register event handlers
    on<CounterEventIncrement>((event, emit) {
      var currentState = state;
      emit(currentState is CounterStateNumber
          ? currentState.add(event.step)
          : CounterStateNumber(0));
    });
    on<CounterEventMultiply>((event, emit) {
      var currentState = state;
      emit(currentState is CounterStateNumber
          ? currentState.multiply(event.factor)
          : CounterStateNumber(0));
    });
    on<CounterEventReset>((_, emit) => emit(CounterStateNumber(0)));
  }
}
