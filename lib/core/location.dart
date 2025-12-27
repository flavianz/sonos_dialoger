import 'package:cloud_firestore/cloud_firestore.dart';

class Location {
  String id;
  String name;

  String? town;
  String? postalCode;
  String? street;
  String? houseNumber;

  String? email;
  String? phone;
  String? link;

  num? price;
  String? notes;

  Location(
    this.id,
    this.name,
    this.town,
    this.postalCode,
    this.street,
    this.houseNumber,
    this.email,
    this.phone,
    this.link,
    this.price,
    this.notes,
  );

  factory Location.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Location(
      doc.id,
      data["name"] as String,
      data["address"]?["town"] as String?,
      data["address"]?["postal_code"] as String?,
      data["address"]?["street"] as String?,
      data["address"]?["house_number"] as String?,
      data["email"] as String?,
      data["phone"] as String?,
      data["link"] as String?,
      data["price"] as num?,
      data["notes"] as String?,
    );
  }
}
