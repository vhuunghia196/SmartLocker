import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:smart_locker/comfirm_order.dart';
import 'package:smart_locker/models.dart';
import 'config.dart';

class OrderLocker extends StatefulWidget {
  final AuthStatus authStatus;
  OrderLocker({required this.authStatus});

  @override
  _OrderLockerState createState() => _OrderLockerState();
}

class _OrderLockerState extends State<OrderLocker> {
  String selectedRecipient = "Người nhận số 0";
  String selectedHour = '';
  String selectedLocation1 = "Location1"; // Điểm gửi mặc định
  String selectedLocation2 = "Location2"; // Điểm đến mặc định
  List<String> availableHours = [];
  String selectedUserId =
      'U000'; // Thêm biến này để lưu trữ userId người được chọn
  // List<Map<String, dynamic>> users = [];
  List<dynamic> users = [];
  TextEditingController txtOtp = TextEditingController();
  String historyId = "";
  bool isLoading = false;
  final storage = FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _loadUsers();
    _generateAvailableHours();
    _setInitialHour();
  }

  Future<void> _loadUsers() async {
    final userIdLoggin = widget.authStatus.user.id;
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

        // Lọc danh sách người dùng và loại bỏ người dùng đã đăng nhập và có roleId là 3
        final filteredUsers = userList.where((user) {
          final String userId = user['userId'];
          final String roleIdStr = user['roleId'];

          // Kiểm tra xem roleId có thể được chuyển thành số nguyên hay không
          final int? roleId = int.tryParse(roleIdStr);

          // Kiểm tra nếu roleId không null và không bằng 3
          return userId != userIdLoggin && roleId != null && roleId != 3;
        }).toList();

        setState(() {
          users = filteredUsers;
          selectedRecipient = users.isNotEmpty ? users[0]['name'] : '';
          selectedUserId = users.isNotEmpty ? users[0]['userId'] : '';
        });
      } else {
        print('Dữ liệu JSON không có cấu trúc phù hợp.');
      }
    } else if (response.statusCode == 401) {
      print('Chưa đăng nhập');
    } else {
      print("Lỗi Server");
    }
  }

  void _generateAvailableHours() {
    final DateTime now = DateTime.now();
    final int currentHour = now.hour;

    availableHours = []; // Xóa danh sách cũ
    for (int hour = 6; hour < 18; hour++) {
      if (currentHour <= hour) {
        final String endHour = (hour == 17) ? '18' : (hour + 1).toString();
        final String hourRange = '$hour:00 - $endHour:00';
        availableHours.add(hourRange);
      }
    }
  }

  void _setInitialHour() {
    final DateTime now = DateTime.now();
    final int currentHour = now.hour;

    for (int hour = 6; hour < 18; hour++) {
      if (currentHour <= hour) {
        final String hourRange = '$hour:00 - ${(hour + 1) % 24}:00';

        setState(() {
          selectedHour = hourRange;
        });
        break;
      }
    }
  }

  List<DropdownMenuItem<String>> _buildRecipientItems() {
    return users.map((user) {
      final String name = user['name'] ?? '';
      final String phone = user['phone'] ?? '';
      final String userId = user['userId'] ?? '';

      return DropdownMenuItem<String>(
        value: userId,
        child: Text('$name - $phone'),
      );
    }).toList();
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

  String formatHourRange(String hour) {
    final List<String> parts =
        hour.split('-'); // Tách thành 2 phần: "6h" và "7h"
    final String startHour = parts[0].trim();
    final String endHour = parts[1].trim();

    final formattedStartHour =
        startHour.padLeft(2, '0'); // Đảm bảo có 2 chữ số cho giờ
    final formattedEndHour =
        endHour.padLeft(2, '0'); // Đảm bảo có 2 chữ số cho giờ kết thúc

    return '$formattedStartHour - $formattedEndHour';
  }

  String getStartTime(String hourRange) {
    final List<String> parts = hourRange.split('-');
    if (parts.length == 2) {
      final String startTime = parts[0].trim();
      return startTime;
    }
    // Trả về một giá trị mặc định nếu định dạng không hợp lệ.
    return '';
  }

  Future<void> sendOTPRequest() async {
    final token = await storage.read(key: 'token');
    final userId = widget.authStatus.user.id;
    final userName = widget.authStatus.user.name;
    if (selectedHour.isEmpty) {
      setState(() {
        isLoading = false;
      });
      _showSnackBar('Vui lòng chọn giờ đặt tủ.');
      return;
    }

    // Chuyển đổi selectedHour thành định dạng "6h-7h"
    final formattedHour = formatHourRange(selectedHour);

    // lấy được startTime
    final startTime = getStartTime(formattedHour);
    setState(() {
      isLoading = true;
    });
    final response = await http.post(
      Uri.parse('$endpoint/api/Otps/generatedotp'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        "userIdSend": userId,
        "userIdReceive": null,
        "startTime": startTime,
        "locationSend": selectedLocation1,
        "locationReceive": selectedLocation2
      }),
    );

    if (response.statusCode == 200) {
      final otp = jsonDecode(response.body)['otp'];
      final otpData = Otp(otp['otpId'], otp['otpCode'], otp['expirationTime'],
          otp['userId'], otp['lockerId']);
      final otpCode = otpData.otpCode;

      historyId = jsonDecode(response.body)['historyId'];
      String messageMail =
          "Hi $userName,\n\nYour OTP is $otpCode.\n\nUsing this for unlocked Smartlocker\n\nContact us: 0987654321";

      final response2 = await http.post(
        Uri.parse('$endpoint/api/Otps/sendmail'),
        body: jsonEncode({
          'userId': userId,
          'mailContent': messageMail
        }), // Sử dụng selectedUserId ở đây
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (response2.statusCode == 200) {
        _showSnackBar('Đã gửi mã OTP qua gmail. Hãy kiểm tra email của bạn.');
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ConfirmOrderScreen(
                authStatus: widget.authStatus,
                userReceive:
                    selectedUserId,
                    nameUserReceive: selectedRecipient, // Truyền người nhận vào ConfirmOrderScreen
                startTime: startTime,
                locationSend: selectedLocation1,
                locationReceive: selectedLocation2,
                historyId: historyId,
                otpSend: otpData),
          ),
        );
      }
    } else if (response.statusCode == 400) {
      _showSnackBar('Hết tủ');
    } else if (response.statusCode == 401) {
      _showSnackBar('Chưa đăng nhập');
    } else {
      _showSnackBar('Lỗi server');
    }
    setState(() {
      isLoading = false;
    });
  }

  void _showHourSelector() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return ListView(
          children: availableHours.map((String hourRange) {
            return ListTile(
              title: Text(hourRange),
              onTap: () {
                setState(() {
                  selectedHour = hourRange;
                });
                Navigator.of(context).pop();
              },
            );
          }).toList(),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Đặt tủ'),
        backgroundColor: Color.fromARGB(255, 253, 145, 145),
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: NetworkImage(
              'https://images.pexels.com/photos/3314876/pexels-photo-3314876.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1', // Thay thế bằng URL hình ảnh từ mạng
            ),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: Container(
            margin: EdgeInsets.only(
              left: 30.0,
              right: 30.0,
              top: 30.0,
              bottom: 100.0, // Thêm padding phía dưới
            ),
            padding: EdgeInsets.only(
              left: 30.0,
              right: 30.0,
              top: 30.0,
              bottom: 30.0, // Thêm padding phía dưới
            ),

            decoration: BoxDecoration(
              color: Color.fromARGB(255, 255, 255, 255).withOpacity(0.3),
              borderRadius: BorderRadius.circular(10.0),
              border: Border.all(
                color: Colors.transparent, // Đặt màu viền là màu trong suốt
                width: 0.0, // Đặt độ rộng viền là 0.0
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 5.0,
                  spreadRadius: 2.0,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Icon(
                        Icons
                            .person, // Thay thế bằng biểu tượng người dùng tượng trưng
                        size: 32,
                        color: Colors.blue,
                      ),
                      SizedBox(width: 8.0),
                      DropdownButton<String>(
                        value: selectedUserId,
                        onChanged: (String? newValue) {
                          final selectedUser = users
                              .firstWhere((user) => user['userId'] == newValue);
                          setState(() {
                            selectedRecipient = selectedUser['name'] ?? '';
                            selectedUserId = newValue!;
                          });
                        },
                        items: _buildRecipientItems(),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Icon(
                        Icons
                            .location_on, // Thay thế bằng biểu tượng địa điểm tượng trưng
                        size: 32,
                        color: Colors.green,
                      ),
                      SizedBox(width: 8.0),
                      DropdownButton<String>(
                        value: selectedLocation1,
                        onChanged: (String? newValue) {
                          setState(() {
                            selectedLocation1 = newValue!;
                            if (selectedLocation1 == selectedLocation2) {
                              selectedLocation2 =
                                  (selectedLocation1 == "Location1")
                                      ? "Location2"
                                      : "Location1";
                            }
                          });
                        },
                        items: [
                          DropdownMenuItem<String>(
                            value: "Location1",
                            child: Text("Điểm gửi: Location1"),
                          ),
                          DropdownMenuItem<String>(
                            value: "Location2",
                            child: Text("Điểm gửi: Location2"),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Icon(
                        Icons
                            .location_on, // Thay thế bằng biểu tượng địa điểm tượng trưng
                        size: 32,
                        color: Colors.orange,
                      ),
                      SizedBox(width: 8.0),
                      DropdownButton<String>(
                        value: selectedLocation2,
                        onChanged: (String? newValue) {
                          setState(() {
                            selectedLocation2 = newValue!;
                            if (selectedLocation1 == selectedLocation2) {
                              selectedLocation1 =
                                  (selectedLocation2 == "Location1")
                                      ? "Location2"
                                      : "Location1";
                            }
                          });
                        },
                        items: [
                          DropdownMenuItem<String>(
                            value: "Location1",
                            child: Text("Điểm đến: Location1"),
                          ),
                          DropdownMenuItem<String>(
                            value: "Location2",
                            child: Text("Điểm đến: Location2"),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.access_time,
                          size: 32, // Đặt kích thước của biểu tượng
                          color: Color.fromARGB(
                              255, 223, 24, 114), // Đặt màu sắc của biểu tượng
                        ),
                        onPressed: () {
                          _showHourSelector();
                        },
                      ),
                      SizedBox(width: 8.0),
                      Text(
                        'Giờ đã chọn: $selectedHour',
                        style: TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
                AnimatedSwitcher(
                  duration: Duration(milliseconds: 300),
                  child: isLoading
                      ? Center(
                          child: CircularProgressIndicator(),
                        )
                      : ElevatedButton(
                          onPressed: () {
                            if (mounted) {
                              // Thực hiện một số hoạt động ở đây nếu widget vẫn hoạt động
                              sendOTPRequest();
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            primary:
                                Colors.red, // Đặt màu nền của nút là màu đỏ
                            onPrimary: Colors
                                .white, // Đặt màu chữ trên nút là màu trắng
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Text(
                              'Xác nhận đặt tủ',
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
