// socket_service.dart
import 'package:socket_io_client/socket_io_client.dart' as IO;

import 'screens/onboding/api_constants.dart';

class SocketService {

  static late IO.Socket socket;

  static void connect(String userId) {
    socket = IO.io(ApiConstants.baseUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });
    print(userId);
    socket.connect();
    socket.onConnect((_) {
      print('connected');

      // Émettez un événement pour associer l'ID de l'utilisateur au socket
      socket.emit('userConnected', userId);

    });

    socket.onDisconnect((_) => print('disconnected'));
  }

  static void disconnect() {
    socket.disconnect();
    socket.dispose();
  }
  static void invitationAccepted(Function(dynamic) callback) {
    socket.on('invitationAccepted', (data) {
      callback(data);
    });
  }

  static void invitationRejected(Function(dynamic) callback) {
    socket.on('invitationRejected', (data) {
      callback(data);
    });
  }
  static void demande(Function(dynamic) callback) {
    socket.on('demande', (data) {
      callback(data);
    });
  }
  static void updateAppointment(Function(dynamic) callback) {
    socket.on('updateAppointment', (data) {
      callback(data);
    });
  }
  static void invitation(Function(dynamic) callback){
    socket.on('new invitation', (data) {
      callback(data);
    });


  }
}