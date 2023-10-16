import 'dart:convert';

import 'package:flutter/material.dart';
import 'models.dart';
import 'config.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class EditProfileScreen extends StatefulWidget {
  AuthStatus
      authStatus; // Đối tượng User để hiển thị và chỉnh sửa thông tin cá nhân

  EditProfileScreen({required this.authStatus});

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  TextEditingController _nameController = TextEditingController();
  TextEditingController _emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Khởi tạo giá trị ban đầu cho các trường thông tin cá nhân
    _nameController.text = widget.authStatus.user.name;
    _emailController.text = widget.authStatus.user.email;
  }

  void _saveChanges() async {
    final userId = widget.authStatus.user.id;
    final storage = FlutterSecureStorage();
    final token = await storage.read(key: 'token');
    // Lưu các thay đổi vào thông tin cá nhân của người dùng
    final newName = _nameController.text;
    final newEmail = _emailController.text;
    if (!newEmail.contains('@gmail.com')) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Email phải có định dạng @gmail.com'),
      ));
      return; // Không thực hiện lưu nếu email không hợp lệ
    }
    // Thực hiện lưu dữ liệu vào cơ sở dữ liệu hoặc hệ thống lưu trữ tùy thuộc vào ứng dụng của bạn
    final updateUser = await http.put(
      Uri.parse('$endpoint/api/Users/$userId'),
      body: jsonEncode(
          {"userId": userId, "userName": newName, "userEmail": newEmail}),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    // Hiển thị thông báo hoặc thông báo thành công
    if (updateUser.statusCode == 204) {
      final updatedUser =
          widget.authStatus.user.copyWith(name: newName, email: newEmail);

      widget.authStatus.updateUser(updatedUser);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Thông tin cá nhân đã được cập nhật.'),
      ));
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Lỗi'),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chỉnh sửa thông tin cá nhân'),
        backgroundColor:
            Color.fromARGB(255, 253, 145, 145), // Màu nền cho appbar
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tên người dùng'),
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: 'Nhập tên của bạn',
              ),
            ),
            SizedBox(height: 20),
            Text('Email'),
            TextFormField(
              controller: _emailController,
              decoration: InputDecoration(
                hintText: 'Nhập email của bạn',
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                primary: Colors.red, // Đặt màu nền của nút là màu đỏ
                onPrimary: Colors.white, // Đặt màu chữ trên nút là màu trắng
              ),
              onPressed: () {
                // Xử lý lưu thay đổi khi nút Lưu được bấm
                _saveChanges();
              },
              child: Text('Lưu'),
            ),
          ],
        ),
      ),
    );
  }
}
