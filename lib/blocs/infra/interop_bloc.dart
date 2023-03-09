import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Our own bloc that knows how to interact with the native side through
/// events and state updates.
abstract class InteropBloc<E, S> extends Bloc<E, S> {
  late MethodChannel platform;

  final List<String> _nativeSubscriptions;

  InteropBloc(super.initialState)
      : _nativeSubscriptions = List.empty(growable: true) {
    // Receive events from the native side.
    platform = MethodChannel(
        "br.com.rtakahashi.playground.bloc_interop/${getBlocName()}",
        const JSONMethodCodec());
    platform.setMethodCallHandler(_handler);

    // If we always send messages to a fixed method, then we'd be wasting calls
    // when the other side isn't listening.
    // Also, this way a certain bloc adapter on the native side can receive
    // messages in multiple methods if it wants.
    // Just make sure to never subscribe to the same method twice.
    stream.listen((event) {
      print("SENDING UPDATE to $_nativeSubscriptions");
      for (var subscription in _nativeSubscriptions) {
        platform.invokeMethod(subscription, stateToMessage(event));
      }
    });
  }

  Future<dynamic> _handler(MethodCall methodCall) async {
    print("RECEIVING EVENT");
    print(methodCall.method);
    print(methodCall.arguments);
    switch (methodCall.method) {
      case 'sendEvent':
        return receiveMessage(methodCall.arguments);
      case 'registerCallback':
        return registerCallback(methodCall.arguments as String);
      case 'unregisterCallback':
        return unregisterCallback(methodCall.arguments as String);
      case 'getCurrentState':
        return stateToMessage(state);
      default:
        throw MissingPluginException("notImplemented");
    }
  }

  /// Must be overridden to produce an event that this bloc understands from
  /// a message received from the native side.
  E messageToEvent(dynamic message);

  /// Must be overridden to produce a message that the native side will
  /// undestand, containing the state.
  dynamic stateToMessage(S state);

  String getBlocName();

  void registerCallback(String callback) {
    print("REGISTERING CALLBACK $callback");
    _nativeSubscriptions.add(callback);
  }

  void unregisterCallback(String callback) {
    _nativeSubscriptions.remove(callback);
  }

  void receiveMessage(dynamic message) {
    // The message parameter is something that came from the other side of the
    // channel. We turn it into an event and add it to this bloc.
    E event = messageToEvent(message);
    add(event);
  }
}
