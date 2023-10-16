import 'dart:convert';
import 'config.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'main.dart';
import 'models.dart';
import 'package:flutter/services.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isLoading = false;
  final storage = FlutterSecureStorage();

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

  Future<void> login(BuildContext context) async {
    final username = usernameController.text;
    final password = passwordController.text;

    // Đặt isLoading thành true để hiển thị nút xoay tròn
    setState(() {
      isLoading = true;
    });

    final response = await http.post(
      Uri.parse('$endpoint/api/Users/authenticate'),
      body: jsonEncode({'phone': username, 'password': password}),
      headers: {'Content-Type': 'application/json'},
    );

    // Sau khi hoàn thành yêu cầu, đặt isLoading lại thành false
    setState(() {
      isLoading = false;
    });

    if (response.statusCode == 200) {
      final userData = jsonDecode(response.body);
      final token = jsonDecode(response.body)['token'];
      await storage.write(key: 'token', value: token);
      final user = User(
        id: userData['id'],
        name: userData['name'],
        email: userData['mail'],
        phone: userData['phone'],
        role: userData['role'],
      );
      final authStatus = AuthStatus(true, user);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => HomeScreen(authStatus: authStatus),
        ),
      );
      _showSnackBar("Đăng nhập thành công");
    } else {
      print('Đăng nhập thất bại');
      _showSnackBar("Đăng nhập thất bại");
    }
  }

  // @override
  // Widget build(BuildContext context) {
  //   return Scaffold(
  //     appBar: AppBar(
  //       title: Text('Đăng nhập'),
  //       backgroundColor: Color.fromARGB(255, 253, 145, 145),
  //     ),
  //     body: Center(
  //       child: Column(
  //         mainAxisAlignment: MainAxisAlignment.center,
  //         children: <Widget>[
  //           TextField(
  //             controller: usernameController,
  //             decoration: InputDecoration(labelText: 'Số điện thoại'),
  //           ),
  //           TextField(
  //             controller: passwordController,
  //             decoration: InputDecoration(labelText: 'Mật khẩu'),
  //             obscureText: true,
  //           ),
  //           ElevatedButton(
  //             style: ElevatedButton.styleFrom(
  //               primary: Colors.red, // Đặt màu nền của nút là màu đỏ
  //               onPrimary: Colors.white, // Đặt màu chữ trên nút là màu trắng
  //             ),
  //             onPressed: isLoading
  //                 ? null
  //                 : () {
  //                     login(context);
  //                   },
  //             child: Text('Đăng nhập'),
  //           ),
  //           // Hiển thị vòng xoay loading khi isLoading là true
  //           if (isLoading) CircularProgressIndicator(),
  //         ],
  //       ),
  //     ),
  //   );
  // }

//   @override
// Widget build(BuildContext context) {
//   return Scaffold(
//     appBar: AppBar(
//       title: Text('Đăng nhập'),
//       backgroundColor: Colors.transparent, // Đặt màu nền trong suốt cho Appbar
//     ),
//     extendBodyBehindAppBar: true, // Mở rộng màu nền trong suốt đến Appbar
//     body: Stack(
//       children: <Widget>[
//         Image.network(
//           'https://images.pexels.com/photos/1707215/pexels-photo-1707215.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1', // Đặt đường dẫn đến hình ảnh từ internet
//           fit: BoxFit.cover,
//           width: double.infinity,
//           height: double.infinity,
//         ),
//         Center(
//           child: Container(
//             margin: EdgeInsets.all(20),
//             padding: EdgeInsets.all(20),
//             color: Colors.black.withOpacity(0.6), // Đặt màu nền trong suốt cho form đăng nhập
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: <Widget>[
//                 TextField(
//                   controller: usernameController,
//                   decoration: InputDecoration(
//                     labelText: 'Số điện thoại',
//                     filled: true,
//                     fillColor: Colors.white, // Đặt màu nền cho ô input
//                   ),
//                 ),
//                 SizedBox(height: 16.0),
//                 TextField(
//                   controller: passwordController,
//                   decoration: InputDecoration(
//                     labelText: 'Mật khẩu',
//                     filled: true,
//                     fillColor: Colors.white, // Đặt màu nền cho ô input
//                   ),
//                   obscureText: true,
//                 ),
//                 SizedBox(height: 16.0),
//                 ElevatedButton(
//                   style: ElevatedButton.styleFrom(
//                     primary: Colors.red,
//                     onPrimary: Colors.white,
//                   ),
//                   onPressed: isLoading ? null : () {
//                     login(context);
//                   },
//                   child: Text('Đăng nhập'),
//                 ),
//                 if (isLoading) SizedBox(height: 16.0),
//                 if (isLoading) CircularProgressIndicator(),
//               ],
//             ),
//           ),
//         ),
//       ],
//     ),
//   );
// }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Đăng nhập'),
        backgroundColor: Colors.transparent,
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: <Widget>[
          Image.network(
            'https://images.pexels.com/photos/1707215/pexels-photo-1707215.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1',
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),
          Center(
            child: Container(
              margin: EdgeInsets.all(20),
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(10.0), // Đặt góc tròn
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  // TextField(
                  //   controller: usernameController,
                  //   decoration: InputDecoration(
                  //     labelText: 'Số điện thoại',
                  //     filled: true,
                  //     fillColor: Colors.white,
                  //     border: OutlineInputBorder(
                  //       borderRadius: BorderRadius.circular(10.0), // Đặt góc tròn
                  //     ),
                  //   ),
                  // ),
                  TextField(
  controller: usernameController,
  decoration: InputDecoration(
    labelText: 'Số điện thoại',
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10.0),
    ),
  ),
  inputFormatters: [
    FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
  ],
  keyboardType: TextInputType.phone, // Đặt loại bàn phím thành số điện thoại
),


                  SizedBox(height: 16.0),
                  TextField(
                    controller: passwordController,
                    decoration: InputDecoration(
                      labelText: 'Mật khẩu',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(10.0), // Đặt góc tròn
                      ),
                      suffixIcon:
                          Icon(Icons.lock), // Thêm icon ở cuối TextField
                    ),
                    obscureText: true,
                  ),
                  SizedBox(height: 16.0),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      primary: Colors.red,
                      onPrimary: Colors.white,
                    ),
                    onPressed: isLoading
                        ? null
                        : () {
                            login(context);
                          },
                    child: Text('Đăng nhập'),
                  ),
                  if (isLoading) SizedBox(height: 16.0),
                  if (isLoading) CircularProgressIndicator(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
