import 'package:flutter/material.dart';
import 'models.dart';
import 'login_screen.dart';
import 'account.dart';
import 'order-locker.dart';
import 'order.dart';

void main() => runApp(MyApp(authStatus: null));

class MyApp extends StatelessWidget {
  final AuthStatus? authStatus; // Sử dụng '?' để cho phép giá trị null

  MyApp({this.authStatus});

  @override
  Widget build(BuildContext context) {
    final effectiveAuthStatus = authStatus ??
        AuthStatus(
            false,
            User.defaultUser());

    return MaterialApp(
      home: HomeScreen(authStatus: effectiveAuthStatus),
    );
  }
}

class HomeScreen extends StatefulWidget {
  final AuthStatus authStatus; // Thêm tham số authStatus

  HomeScreen(
      {required this.authStatus}); // Sử dụng {} để đặt tham số là optional

  @override
  _HomeScreenState createState() => _HomeScreenState(authStatus: authStatus);
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0; // Sử dụng để theo dõi mục đang được chọn trong menu
  bool _showBackButton = false; // Để ẩn/hiện nút quay về
  final AuthStatus authStatus; // Thêm tham số authStatus
  final List<Widget> _children;
  bool isReserveButtonEnabled = true;

  _HomeScreenState({required this.authStatus})
      : _children = [
          Home(), // Trang chủ
          Reserve(
              authStatus:
                  authStatus), // Đặt tủ và truyền authStatus vào đây nếu roleId khác 3
          Order(authStatus: authStatus),
          Login(), // Đăng nhập
        ];

  void onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
      _showBackButton = false; // Ẩn nút quay về khi chuyển tab
    });
  }

  void onLoginSuccess() {
    // Xử lý khi đăng nhập thành công
    setState(() {
      _showBackButton =
          true; // Hiển thị nút quay về sau khi đăng nhập thành công
    });
  }

  void onLogout() {
    // Xử lý khi đăng xuất
    widget.authStatus.logout(); // Đăng xuất người dùng
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => MyApp(authStatus: widget.authStatus),
      ),
    );
    setState(() {
      _showBackButton = false; // Ẩn nút quay về sau khi đăng xuất
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tủ để đồ thông minh'),
        backgroundColor: Color.fromARGB(255, 253, 145, 145),
        automaticallyImplyLeading: _showBackButton, // Ẩn/hiện nút quay về
      ),
      body: _children[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        onTap: (index) {
          if (index == 3 && widget.authStatus.isLoggedIn) {
            // Chuyển đến trang giao diện tài khoản và truyền đối tượng User
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AccountScreen(
                  authStatus: widget.authStatus,
                  onLogout: onLogout, // Truyền hàm callback onLogout
                ),
              ),
            ).then((_) {});
          } else {
            setState(() {
              _currentIndex = index;
            });
          }
        },
        currentIndex: _currentIndex,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Trang chủ',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: 'Đặt tủ',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_bag),
            label: 'Đơn hàng',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: widget.authStatus.isLoggedIn ? 'Tài khoản' : 'Đăng nhập',
          )
        ],
        selectedFontSize: 14.0, // Kích thước chữ cho tab đã chọn
        unselectedFontSize: 14.0, // Kích thước chữ cho tab chưa chọn
        selectedItemColor:
            Color.fromARGB(255, 230, 7, 7), // Màu cho tab đã chọn
        unselectedItemColor:
            const Color.fromARGB(255, 0, 0, 0), // Màu cho tab chưa chọn
      ),
    );
  }
}

class Home extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text('Trang chủ'),
    );
  }
}

class Reserve extends StatelessWidget {
  final AuthStatus authStatus; // Thêm tham số authStatus

  Reserve({required this.authStatus}); // Sử dụng {} để đặt tham số là optional

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              primary: Colors.red, // Đặt màu nền của nút là màu đỏ
              onPrimary: Colors.white, // Đặt màu chữ trên nút là màu trắng
            ),
            onPressed: authStatus.user.role != "3"
                ? () {
                    // Xử lý khi người dùng bấm nút (điều này chỉ xảy ra khi role không phải là 3)
                    if (authStatus.isLoggedIn) {
                      // Đã đăng nhập, chuyển đến OrderLocker
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              OrderLocker(authStatus: authStatus),
                        ),
                      );
                    } else {
                      // Chưa đăng nhập, chuyển đến LoginScreen
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => LoginScreen(),
                        ),
                      );
                    }
                  }
                : null, // Đặt onPressed thành null khi role là 3
            child: Text('Bắt đầu đăng ký tủ'),
          )
        ],
      ),
    );
  }
}

class Login extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              primary: Colors.red, // Đặt màu nền của nút là màu đỏ
              onPrimary: Colors.white, // Đặt màu chữ trên nút là màu trắng
            ),
            onPressed: () {
              // Điều hướng đến màn hình đăng nhập khi nút được nhấn
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => LoginScreen(),
                ),
              );
            },
            child: Text('Bắt đầu đăng nhập'),
          ),
        ],
      ),
    );
  }
}

class Order extends StatelessWidget {
  final AuthStatus authStatus;
  Order({required this.authStatus});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              primary: Colors.red, // Đặt màu nền của nút là màu đỏ
              onPrimary: Colors.white, // Đặt màu chữ trên nút là màu trắng
            ),
            onPressed: () {
              if (authStatus.isLoggedIn) {
                // Đã đăng nhập, chuyển đến OrderLocker
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => OrderList(authStatus: authStatus),
                  ),
                );
              } else {
                // Chưa đăng nhập, chuyển đến LoginScreen
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => LoginScreen(),
                  ),
                );
              }
            },
            child: Text('Xác nhận đơn hàng'),
          ),
        ],
      ),
    );
  }
}
