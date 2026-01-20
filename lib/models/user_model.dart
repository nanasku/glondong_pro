class User {
  final int? id;
  final String username;
  final String email;
  final String password;
  final String companyName;
  final String? alamat;
  final String? profileImage;
  final String? createdAt;
  final String? updatedAt;

  User({
    this.id,
    required this.username,
    required this.email,
    required this.password,
    required this.companyName,
    this.alamat,
    this.profileImage,
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'password': password,
      'company_name': companyName,
      'alamat': alamat,
      'profile_image': profileImage,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      username: map['username'],
      email: map['email'],
      password: map['password'],
      companyName: map['company_name'],
      alamat: map['alamat'],
      profileImage: map['profile_image'],
      createdAt: map['created_at'],
      updatedAt: map['updated_at'],
    );
  }
}
