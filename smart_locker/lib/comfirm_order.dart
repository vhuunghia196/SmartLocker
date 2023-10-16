import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:smart_locker/main.dart';
import 'package:smart_locker/models.dart';
import 'config.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'order-locker.dart';

class ConfirmOrderScreen extends StatefulWidget {
  final AuthStatus authStatus;
  final String userReceive;
  final String nameUserReceive;
  final String startTime;
  final String locationSend;
  final String locationReceive;
  final String historyId;
  final Otp otpSend;

  ConfirmOrderScreen(
      {required this.authStatus,
      required this.userReceive,
      required this.nameUserReceive,
      required this.startTime,
      required this.locationSend,
      required this.locationReceive,
      required this.historyId,
      required this.otpSend});

  @override
  _ConfirmOrderScreenState createState() => _ConfirmOrderScreenState();
}

class _ConfirmOrderScreenState extends State<ConfirmOrderScreen> {
  final storage = FlutterSecureStorage();

  String otp = '';
  String selectedUserId =
      'U000'; // Thêm biến này để lưu trữ userId người được chọn
  String selectedRecipient = "Người nhận số 0";
  List<Map<String, dynamic>> filteredUsers = [];

  String historyIdNew = "";
  bool isLoading = false;
  @override
  void initState() {
    super.initState();
    _loadUsers(); // Gọi hàm _loadUsers khi widget được khởi tạo
  }

  Future<void> _loadUsers() async {
    final token = await storage.read(key: 'token');
    final response = await http.get(
      Uri.parse('$endpoint/api/Users'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final dynamic responseData = jsonDecode(response.body);

      if (responseData is Map<String, dynamic> &&
          responseData.containsKey('\$values')) {
        final List<dynamic> userList = responseData['\$values'];

        // Lọc danh sách user có roleId là 3
        final List<dynamic> filteredUsers = userList.where((user) {
          final String roleIdStr = user['roleId'];

          // Kiểm tra xem roleId có thể được chuyển thành số nguyên hay không
          final int? roleId = int.tryParse(roleIdStr);

          return roleId == 3;
        }).toList();

        // Lấy một user ngẫu nhiên nếu danh sách không rỗng
        if (filteredUsers.isNotEmpty) {
          final random = Random();
          final randomUserIndex = random.nextInt(filteredUsers.length);
          final randomUser = filteredUsers[randomUserIndex];

          setState(() {
            selectedRecipient = randomUser['name'] ?? '';
            selectedUserId = randomUser['userId'] ?? '';
          });
        } else {
          // Xử lý trường hợp danh sách không có người dùng có roleId là 3
          print('Không có người dùng có roleId là 3.');
        }
      } else {
        print('Dữ liệu JSON không có cấu trúc phù hợp.');
      }
    } else if (response.statusCode == 401) {
      print('Chưa đăng nhập');
    } else {
      print("Lỗi Server");
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Color.fromARGB(255, 253, 145, 145),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> sendOTPRequest(
      {required String userReceive,
      required String nameUserReceive,
      required String startTime,
      required String locationSend,
      required String locationReceive,
      required String historyId,
      required Otp otpSend}) async {
    final token = await storage.read(key: 'token');
    final userId = widget.authStatus.user.id;
    setState(() {
      isLoading = true;
    });
    final response3 = await http.post(
      Uri.parse('$endpoint/api/Histories'),
      body: jsonEncode({
        "historyId": historyId,
        "userSend": userId,
        "shipper": selectedUserId,
        "receiver": userReceive
      }),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final response = await http.post(
      Uri.parse('$endpoint/api/Otps/generatedotp'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        "userIdSend": userId,
        "userIdReceive": selectedUserId,
        "startTime": startTime,
        "locationSend": locationSend,
        "locationReceive": locationReceive
      }),
    );

    if (response.statusCode == 200) {
      final otp = jsonDecode(response.body)['otp'];
      final otpData = Otp(otp['otpId'], otp['otpCode'], otp['expirationTime'],
          otp['userId'], otp['lockerId']);
      final otpCode = otpData.otpCode;
      final otpId = otpSend.otpId;
      historyIdNew = jsonDecode(response.body)['historyId'];
      String messageMail =
          "Hi $selectedRecipient,\n\nYour OTP is $otpCode.\n\nUsing this for unlocked Smartlocker to transport \n\nContact us: 0987654321";
      // Xóa otp
      final response6 = await http.delete(
        Uri.parse('$endpoint/api/Otps/$otpId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final response4 = await http.post(
        Uri.parse('$endpoint/api/Histories'),
        body: jsonEncode({
          "historyId": historyIdNew,
          "userSend": userId,
          "shipper": selectedUserId,
          "receiver": userReceive
        }),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final response5 = await http.post(
        Uri.parse('$endpoint/api/Otps'),
        body: jsonEncode({"otp": otpCode, "lockerId": otpSend.lockerId}),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final response2 = await http.post(
        Uri.parse('$endpoint/api/Otps/sendmail'),
        body:
            jsonEncode({'userId': selectedUserId, 'mailContent': messageMail}),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      String messageMail2 =
          "Hi $nameUserReceive, you have an order in progress, please pay attention and check .\n\nContact us: 0987654321";
      final response3 = await http.post(
        Uri.parse('$endpoint/api/Otps/sendmail'),
        body:
            jsonEncode({'userId': userReceive, 'mailContent': messageMail2}),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      _showSnackBar('Đã gửi mã OTP qua gmail của Shipper');
      Navigator.pop(context);
    } else if (response.statusCode == 400) {
      print('Hết tủ');
    } else if (response.statusCode == 401) {
      print('Chưa đăng nhập');
    } else {
      print("Lỗi Server");
    }
    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Xác nhận gửi hàng'),
        backgroundColor: Color.fromARGB(255, 253, 145, 145),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            SizedBox(height: 20),
            Stack(
              alignment: Alignment.center,
              children: <Widget>[
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    primary: Colors.red, // Đặt màu nền của nút là màu đỏ
                    onPrimary:
                        Colors.white, // Đặt màu chữ trên nút là màu trắng
                  ),
                  onPressed: () {
                    // Xử lý khi nút xác nhận được nhấn
                    // Đặt tủ ở đây và sử dụng authStatus nếu cần
                    sendOTPRequest(
                        userReceive: widget.userReceive,
                        nameUserReceive: widget.nameUserReceive,
                        startTime: widget.startTime,
                        locationSend: widget.locationSend,
                        locationReceive: widget.locationReceive,
                        historyId: widget.historyId,
                        otpSend: widget.otpSend);
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Text('Xác nhận gửi hàng'),
                  ),
                ),
                if (isLoading)
                  CircularProgressIndicator(), // Hiển thị loading nếu isLoading là true
              ],
            ),
            // Hiển thị thông báo
          ],
        ),
      ),
    );
  }
}
