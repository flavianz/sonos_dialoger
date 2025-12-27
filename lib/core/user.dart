import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { admin, coach, dialog }

class SonosUser {
  String id;
  String first;
  String last;
  bool linked;
  UserRole? role;

  SonosUser(this.id, this.first, this.last, this.linked, this.role);

  factory SonosUser.fromDoc(DocumentSnapshot doc) {
    final map = doc.data() as Map<String, dynamic>;
    String id = doc.id;
    String first = map["first"] as String;
    String last = map["last"] as String;
    bool linked = map["linked"] as bool;

    UserRole? userRole = switch (map["role"]) {
      "admin" => UserRole.admin,
      "coach" => UserRole.coach,
      "dialog" => UserRole.dialog,
      _ => null,
    };

    return SonosUser(id, first, last, linked, userRole);
  }

  Map<String, dynamic> toMap() {
    return {
      "first": first,
      "last": last,
      "linked": linked,
      "role": switch (role) {
        UserRole.admin => "admin",
        UserRole.coach => "coach",
        UserRole.dialog => "dialog",
        _ => null,
      },
    };
  }
}
