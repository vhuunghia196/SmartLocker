class AuthStatus {
  bool isLoggedIn;
  User user;

  AuthStatus(this.isLoggedIn, this.user);
  void updateUser(User updatedUser) {
    user = updatedUser;
  }

  // Thêm phương thức logout
  void logout() {
    isLoggedIn = false;
    user = User.defaultUser();
  }
}

class User {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String role;
  User.defaultUser()
      : id = "defaultId",
        name = "defaultName",
        email = "defaultEmail",
        phone = "defaultPhone",
        role = "defaultRole";
  User({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
  });

  User copyWith({String? name, String? email}) {
    return User(
      id: this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: this.phone,
      role: this.role,
    );
  }
}

class Otp {
  final String otpId;
  final String otpCode;
  final String exe;
  final String userId;
  final String lockerId;
  Otp(this.otpId, this.otpCode, this.exe, this.userId, this.lockerId);
}

class History {
  final String historyId;
  final String userSend;
  final String lockerId;
  final String startTime;
  final String endTime;
  final String shipper;
  final String receiver;

  History({
    required this.historyId,
    required this.userSend,
    required this.lockerId,
    required this.startTime,
    required this.endTime,
    required this.shipper,
    required this.receiver,
  });
}

enum LockerStatus {
  on,
  off,
}

class Locker {
  final String lockerId;
  final String location;
  final LockerStatus status;

  Locker({
    required this.lockerId,
    required this.location,
    required this.status,
  });
}
