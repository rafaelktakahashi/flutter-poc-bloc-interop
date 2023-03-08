import 'package:flutter_bloc/flutter_bloc.dart';

/// Our own bloc that knows how to interact with the native side through
/// events and state updates.
abstract class InteropBloc<E, S> extends Bloc<E, S> {
  InteropBloc(super.initialState);
  // TODO: All this implementation through the method channel.
}
