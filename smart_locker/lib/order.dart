import 'dart:convert';

import 'package:flutter/material.dart';
import 'models.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'config.dart';

class OrderList extends StatefulWidget {
  final AuthStatus authStatus;
  OrderList({required this.authStatus});
  @override
  _OrderListState createState() => _OrderListState();
}

class _OrderListState extends State<OrderList> {
  bool isLoading = false;
  final storage = FlutterSecureStorage();
  String locationSend = '';
  bool isLocationLoaded = false;
  bool isSendingOrder = false;
  GlobalKey<ScaffoldState> _scaffoldKey =
      GlobalKey<ScaffoldState>(); // Thêm khóa scaffold

  History? historyofReceiver;
  String locationReceive = "";
  String otpIdOfUserNow = "";
  String lockerIdOfShipperSend = "";
  History? findHistory(List<History> listHistory, String lockerIdsend) {
    for (var history in listHistory) {
      if (history.lockerId == lockerIdsend) {
        return history;
      }
    }
  }

  History? notFindHistory(List<History> listHistory, String lockerIdsend) {
    for (var history in listHistory) {
      if (history.lockerId != lockerIdsend) {
        return history;
      }
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

  Future<void> getLocation() async {
    final userId = widget.authStatus.user.id;
    final nameOfUser = widget.authStatus.user.name;
    final token = await storage.read(key: 'token');
    setState(() {
      isLoading = true;
    });
    final response = await http.get(
      Uri.parse('$endpoint/api/Otps/getbyuserid/$userId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final dynamic responseData = jsonDecode(response.body);

      if (responseData.containsKey('otp')) {
        final List<dynamic> otpList = responseData['otp']['\$values'];

        if (otpList.isNotEmpty) {
          final lockerIdsend = otpList[0]['lockerId'];
          final otpCode = otpList[0]['otpCode'];
          setState(() {
            otpIdOfUserNow = otpList[0]['otpId'];
          });
          final locationResponse = await http.get(
            Uri.parse('$endpoint/api/Lockers/$lockerIdsend'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          );

          if (locationResponse.statusCode == 200) {
            final dynamic locationData = jsonDecode(locationResponse.body);
            final String location = locationData['location'] ?? '';
            setState(() {
              locationSend = location;
            });

            final getListHistory = await http.post(
              Uri.parse('$endpoint/api/Histories/GetHistories'),
              body: jsonEncode({"userId": userId}),
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $token',
              },
            );

            if (getListHistory.statusCode == 200) {
              final dynamic responseData = jsonDecode(getListHistory.body);

              if (responseData is Map<String, dynamic> &&
                  responseData.containsKey('\$values')) {
                final List<dynamic> historyData = responseData['\$values'];

                final List<History> listHistoryFromServer =
                    historyData.map((item) {
                  return History(
                    historyId: item['historyId'],
                    userSend: item['userSend'],
                    lockerId: item['lockerId'],
                    startTime: item['startTime'],
                    endTime: item['endTime'],
                    shipper: item['shipper'],
                    receiver: item['receiver'],
                  );
                }).toList();

                final historyFind =
                    findHistory(listHistoryFromServer, lockerIdsend);
                if (historyFind != null) {
                  final historyId = historyFind.historyId;
                  final getListHistory = await http.delete(
                    Uri.parse('$endpoint/api/Histories/$historyId'),
                    headers: {
                      'Content-Type': 'application/json',
                      'Authorization': 'Bearer $token',
                    },
                  );
                }
                if (getListHistory.statusCode == 200) {
                  if (widget.authStatus.user.role == "2") {
                    final deleteOtp = await http.delete(
                      Uri.parse('$endpoint/api/Otps/$otpIdOfUserNow'),
                      headers: {
                        'Content-Type': 'application/json',
                        'Authorization': 'Bearer $token',
                      },
                    );
                    if (deleteOtp.statusCode == 204) {
                      final userSend = historyFind?.userSend;
                      // Lấy tên người gửi
                      final getNameUserSend = await http.get(
                        Uri.parse('$endpoint/api/Users/$userSend'),
                        headers: {
                          'Content-Type': 'application/json',
                          'Authorization': 'Bearer $token',
                        },
                      );
                      if (getNameUserSend.statusCode == 200) {
                        String nameUserSend = jsonDecode(getNameUserSend.body)['name'];
                        String messageMail2 =
                            "Hi $nameUserSend, $nameOfUser has taken the order.\n\nContact us: 0987654321";
                        final response3 = await http.post(
                          Uri.parse('$endpoint/api/Otps/sendmail'),
                          body: jsonEncode({
                            'userId': userSend,
                            'mailContent': messageMail2
                          }),
                          headers: {
                            'Content-Type': 'application/json',
                            'Authorization': 'Bearer $token',
                          },
                        );
                      }
                      _showSnackBar("Xác nhận lấy hàng thành công");
                      Navigator.pop(context);
                    } else {
                      _showSnackBar("Xác nhận lấy hàng không thành công");
                    }
                  }
                }
                if (widget.authStatus.user.role == "3") {
                  final historyNotFind =
                      notFindHistory(listHistoryFromServer, lockerIdsend);
                  // Gán history của người nhận vào đây

                  if (historyNotFind != null) {
                    // Gán history của người nhận vào đây
                    historyofReceiver = historyNotFind;
                    final lockerIdReceive = historyNotFind.lockerId;

                    final response5 = await http.post(
                      Uri.parse('$endpoint/api/Otps'),
                      body: jsonEncode(
                          {"otp": otpCode, "lockerId": lockerIdReceive}),
                      headers: {
                        'Content-Type': 'application/json',
                        'Authorization': 'Bearer $token',
                      },
                    );
                  }
                  setState(() {
                    isLocationLoaded = true;
                    isSendingOrder = true;
                  });

                  // Hiển thị thông báo thành công
                  _showSnackBar(
                      "Cập nhật OTP bên tủ lấy hàng thành công, bạn hãy qua tủ gửi để gửi hàng");
                }
              } else {
                _showSnackBar('Dữ liệu JSON không phải là danh sách.');
              }
            } else {
              // Xử lý lỗi HTTP ở đây
            }
          } else {
            _showSnackBar('Lỗi khi lấy thông tin vị trí.');
          }
        } else {
          _showSnackBar('Không có OTP nào được tìm thấy.');
        }
      } else {
        _showSnackBar('Không tìm thấy khóa "otp" trong dữ liệu JSON.');
      }
    } else if (response.statusCode == 401) {
      _showSnackBar('Chưa đăng nhập');
    } else {
      _showSnackBar("Lỗi Server");
    }
    setState(() {
      isLoading = false;
    });
  }

  Future<void> confirmSendPackage() async {
    final userId = widget.authStatus.user.id;
    final token = await storage.read(key: 'token');
    setState(() {
      isLoading = true;
    });
    final locationReceiveResponse = await http.get(
      Uri.parse('$endpoint/api/Otps/getbyuserid/$userId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (locationReceiveResponse.statusCode == 200) {
      final dynamic responseData = jsonDecode(locationReceiveResponse.body);

      if (responseData.containsKey('otp')) {
        final List<dynamic> otpList = responseData['otp']['\$values'];

        if (otpList.isNotEmpty) {
          final lockerIdReceive = otpList[0]['lockerId'];
          setState(() {
            lockerIdOfShipperSend = lockerIdReceive;
          });
          final locationResponse = await http.get(
            Uri.parse('$endpoint/api/Lockers/$lockerIdReceive'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          );

          if (locationResponse.statusCode == 200) {
            final dynamic locationData = jsonDecode(locationResponse.body);
            final String location = locationData['location'] ?? '';
            setState(() {
              locationReceive = location;
            });
          } else {
            _showSnackBar("Không tìm thấy Location để gửi hàng");
          }
        }
      }

      if (historyofReceiver != null) {
        final startTime = historyofReceiver?.startTime;
        final userIdReceive = historyofReceiver?.receiver;

        //Tạo otp cho người nhận
        final newOtpforReceiver = await http.post(
          Uri.parse('$endpoint/api/Otps/generatedotp'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({
            "userIdSend": userId,
            "userIdReceive": userIdReceive,
            "startTime": startTime,
            "locationSend": locationSend,
            "locationReceive": locationReceive
          }),
        );
        if (newOtpforReceiver.statusCode == 200) {
          final otp = jsonDecode(newOtpforReceiver.body)['otp'];
          final otpData = Otp(otp['otpId'], otp['otpCode'],
              otp['expirationTime'], otp['userId'], otp['lockerId']);
          final otpCode = otpData.otpCode;
          // Lấy người nhận
          final getUserReceiver = await http.get(
            Uri.parse('$endpoint/api/Users/$userIdReceive'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          );

          if (getUserReceiver.statusCode == 200) {
            // tên người nhận
            final nameOfReceiver = jsonDecode(getUserReceiver.body)['name'];
            // id người nhận
            final idOfRecerver = jsonDecode(getUserReceiver.body)['userId'];
            final String messageMail =
                "Hi $nameOfReceiver,\n\nYour OTP is $otpCode.\n\nUsing this for unlocked Smartlocker\n\nContact us: 0987654321";

            final response2 = await http.post(
              Uri.parse('$endpoint/api/Otps/sendmail'),
              body: jsonEncode({
                'userId': idOfRecerver,
                'mailContent': messageMail
              }), // Sử dụng selectedUserId ở đây
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $token',
              },
            );
            if (response2.statusCode == 200) {
              _showSnackBar('Xác nhận gửi hàng thành công.');
              //Xóa otp tủ gửi của shipper
              final deleteOtp = await http.delete(
                Uri.parse('$endpoint/api/Otps/$otpIdOfUserNow'),
                headers: {
                  'Content-Type': 'application/json',
                  'Authorization': 'Bearer $token',
                },
              );
              //Cập nhật tủ nhận cho người nhận
              final updateOtpOfReceiver = await http.post(
                Uri.parse('$endpoint/api/Otps'),
                body: jsonEncode(
                    {"otp": otpCode, "lockerId": lockerIdOfShipperSend}),
                headers: {
                  'Content-Type': 'application/json',
                  'Authorization': 'Bearer $token',
                },
              );
              if (deleteOtp.statusCode == 204 &&
                  updateOtpOfReceiver.statusCode == 201) {
                Navigator.pop(context);
              } else {
                _showSnackBar(
                    'Gửi OTP qua mail cho người nhận không thành công');
              }
            } else {
              _showSnackBar('Gửi mail không thành công');
            }
          } else {
            _showSnackBar("Không tìm thấy người nhận");
          }
        } else {
          _showSnackBar("Lỗi tạo mã OTP cho người nhận");
        }
      }
    } else {
      _showSnackBar("Lỗi không tìm thấy OTPCode");
    }
    setState(() {
      isLoading = true;
    });
  }

  // @override
  // Widget build(BuildContext context) {
  //   return Scaffold(
  //     key: _scaffoldKey, // Đặt khóa scaffold
  //     appBar: AppBar(
  //       title: Text('Thông tin đơn hàng'),
  //     ),
  //     body: Center(
  //       child: Column(
  //         mainAxisAlignment: MainAxisAlignment.center,
  //         children: [
  //           Padding(
  //             padding: const EdgeInsets.all(16.0),
  //             child: Text(
  //               'Thông tin vị trí: $locationSend',
  //               style: TextStyle(fontSize: 18.0),
  //             ),
  //           ),
  //           if (!isSendingOrder)
  //             ElevatedButton(
  //               onPressed: () {
  //                 getLocation();
  //               },
  //               child: Text('Xác nhận đơn hàng'),
  //             ),
  //           if (isSendingOrder)
  //             Column(
  //               children: [
  //                 Icon(
  //                   Icons.directions_car,
  //                   size: 48.0,
  //                   color: Colors.blue,
  //                 ),
  //                 SizedBox(height: 16.0),
  //                 ElevatedButton(
  //                   onPressed: () {
  //                     // Xử lý khi nhấn nút Xác nhận gửi hàng
  //                     confirmSendPackage();
  //                   },
  //                   child: Text('Xác nhận gửi hàng'),
  //                 ),
  //               ],
  //             ),
  //         ],
  //       ),
  //     ),
  //   );
  // }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text('Thông tin đơn hàng'),
        backgroundColor: Color.fromARGB(255, 253, 145, 145),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Thông tin vị trí: $locationSend',
                style: TextStyle(fontSize: 18.0),
              ),
            ),
            if (!isSendingOrder &&
                !isLoading) // Ẩn nút đơn hàng khi đang xử lý hoặc xác nhận gửi hàng
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  primary: Colors.red, // Đặt màu nền của nút là màu đỏ
                  onPrimary: Colors.white, // Đặt màu chữ trên nút là màu trắng
                ),
                onPressed: () {
                  getLocation();
                },
                child: Text('Xác nhận đơn hàng'),
              ),
            if (isSendingOrder &&
                !isLoading) // Hiện nút xác nhận gửi hàng khi không xử lý và đang xác nhận gửi hàng
              Column(
                children: [
                  Icon(
                    Icons.directions_car,
                    size: 48.0,
                    color: Colors.blue,
                  ),
                  SizedBox(height: 16.0),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      primary: Colors.red, // Đặt màu nền của nút là màu đỏ
                      onPrimary:
                          Colors.white, // Đặt màu chữ trên nút là màu trắng
                    ),
                    onPressed: () {
                      // Xử lý khi nhấn nút Xác nhận gửi hàng
                      confirmSendPackage();
                    },
                    child: Text('Xác nhận gửi hàng'),
                  ),
                ],
              ),
            if (isLoading) // Hiện vòng xoay loading khi đang xử lý
              CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
