// import 'package:flutter/material.dart';
// import 'models.dart';

// class AccountScreen extends StatelessWidget {
//   final User user; // Đối tượng User để hiển thị thông tin tài khoản
//   final Function onLogout; // Callback để xử lý đăng xuất

//   AccountScreen({required this.user, required this.onLogout});

//   void handleLogout() {
//     // Gọi callback để thông báo về việc đăng xuất
//     onLogout();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Tài khoản'),
//         backgroundColor: Color.fromARGB(255, 253, 145, 145),
//       ),
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Text('Xin chào, ${user.name}'), // Hiển thị tên người dùng
//             // Hiển thị các thông tin tài khoản khác ở đây
//             ElevatedButton(
//               style: ElevatedButton.styleFrom(
//                             primary:
//                                 Colors.red, // Đặt màu nền của nút là màu đỏ
//                             onPrimary: Colors
//                                 .white, // Đặt màu chữ trên nút là màu trắng
//                           ),
//               onPressed: () {
//                 // Xử lý đăng xuất khi nút Đăng xuất được bấm
//                 handleLogout();
//               },
//               child: Text('Đăng xuất'),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'models.dart';
import 'EditProfileScreen.dart';

class AccountScreen extends StatelessWidget {
  final AuthStatus authStatus; // Đối tượng User để hiển thị thông tin tài khoản
  final Function onLogout; // Callback để xử lý đăng xuất

  AccountScreen({required this.authStatus, required this.onLogout});

  void handleLogout() {
    // Gọi callback để thông báo về việc đăng xuất
    onLogout();
  }

  void navigateToEditProfile(BuildContext context) {
    // Chuyển đến trang chỉnh sửa thông tin cá nhân
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EditProfileScreen(authStatus: authStatus),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tài khoản'),
        backgroundColor: Color.fromARGB(255, 253, 145, 145),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Xin chào, ${authStatus.user.name}',
              style: TextStyle(
                fontSize: 18.0, 
                fontWeight: FontWeight.bold, 
              ),
            ),
            // Hiển thị các thông tin tài khoản khác ở đây
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                primary: Colors.red,
                onPrimary: Colors.white, 
              ),
              onPressed: () {
                // Xử lý đăng xuất khi nút Đăng xuất được bấm
                handleLogout();
              },
              child: Text('Đăng xuất'),
            ),
            SizedBox(
                height: 20), // Khoảng cách giữa nút Đăng xuất và nút Chỉnh sửa
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                primary: Colors.red, // Đặt màu nền của nút là màu xanh
                onPrimary: Colors.white, // Đặt màu chữ trên nút là màu trắng
              ),
              onPressed: () {
                // Xử lý khi nút Chỉnh sửa được bấm
                navigateToEditProfile(context);
              },
              child: Text('Chỉnh sửa thông tin cá nhân'),
            ),
          ],
        ),
      ),
    );
  }
}
