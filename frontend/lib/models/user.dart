class UserModel {
  final String id;
  final String name;
  final String email;
  final String role; // 'admin' or 'employee'
  final String? designation;
  final String? location;
  final String? upiId;
  final double baseSalary;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.designation,
    this.location,
    this.upiId,
    this.baseSalary = 15000,
  });

  bool get isAdmin => role == 'admin';
  bool get isSubAdmin => role == 'subadmin';

  factory UserModel.fromJson(Map<String, dynamic> j) => UserModel(
    id: j['id'],
    name: j['name'],
    email: j['email'],
    role: j['role'],
    designation: j['designation'],
    location: j['location'],
    upiId: j['upi_id'],
    baseSalary: (j['base_salary'] ?? 15000).toDouble(),
  );
}
