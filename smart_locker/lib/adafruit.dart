import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:typed_data/typed_data.dart' show Uint8Buffer;
import 'package:flutter_config/flutter_config.dart';
import 'package:flutter/widgets.dart';

import 'package:intl/intl.dart';


class AdafruitIoClient {
  final MqttServerClient client;

  AdafruitIoClient(String username, String apiKey)
      : client = MqttServerClient('io.adafruit.com', username) {
    client.port = 1883;
    client.logging(on: true);
  }

  Future<void> connect(String username) async {
    // WidgetsFlutterBinding.ensureInitialized();
    // await FlutterConfig.loadEnvVariables();
    // final apiKey = FlutterConfig.get('YOUR_API_KEY');
    final MqttClientConnectionStatus? connectionStatus =
        await client.connect(username, 'aio_Skzh53SB6VTRhD6Yk32adYL8eG2a');

    if (connectionStatus != null) {
      print('Connected: ${connectionStatus.state}');
    } else {
      print('Failed to connect');
    }
  }

  void subscribe(String feedName) {
    client.subscribe('nghiavahau/feeds/$feedName', MqttQos.exactlyOnce);
  }

  void publish(String feedName, String message) {
    // Chuyển đổi chuỗi thành Uint8List (Uint8Buffer)
    final messageBytes = Uint8List.fromList(utf8.encode(message));

    // Tạo Uint8Buffer từ Uint8List
    final messageBuffer = Uint8Buffer()..addAll(messageBytes);

    client.publishMessage(
        'nghiavahau/feeds/$feedName', MqttQos.exactlyOnce, messageBuffer);
  }

  Stream<List<MqttReceivedMessage<MqttMessage>>> getUpdates() {
    return client.updates!;
  }

  void disconnect() {
    client.disconnect();
  }
}

// void main() {
//   // Lấy thời gian hiện tại
//   final now = DateTime.now();

//   // Định dạng thời gian thành chuỗi
//   final formattedTime = DateFormat('yyyy-MM-dd HH:mm:ss').format(now);

//   // In ra thời gian đã định dạng
//   print('Thời gian hiện tại là: $formattedTime');
// }