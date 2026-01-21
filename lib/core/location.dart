import 'package:cloud_firestore/cloud_firestore.dart';

class Location {
  String id;
  String name;
  String? space;

  String? town;
  String? postalCode;
  String? street;
  String? houseNumber;

  String? email;
  String? phone;
  String? link;

  num? price;
  String? notes;

  String? areaOverview;
  String? usageRights;
  String? contract;

  Location(
    this.id,
    this.name,
    this.space,
    this.town,
    this.postalCode,
    this.street,
    this.houseNumber,
    this.email,
    this.phone,
    this.link,
    this.price,
    this.notes,
    this.areaOverview,
    this.usageRights,
    this.contract,
  );

  factory Location.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Location(
      doc.id,
      data["name"] as String,
      data["space"] as String?,
      data["address"]?["town"] as String?,
      data["address"]?["postal_code"] as String?,
      data["address"]?["street"] as String?,
      data["address"]?["house_number"] as String?,
      data["email"] as String?,
      data["phone"] as String?,
      data["link"] as String?,
      data["price"] as num?,
      data["notes"] as String?,
      data["area_overview"] as String?,
      data["usage_rights"] as String?,
      data["contract"] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      "name": name,
      "space": space,
      "address": {
        "town": town,
        "postal_code": postalCode,
        "street": street,
        "house_number": houseNumber,
      },
      "email": email,
      "phone": phone,
      "link": link,
      "price": price,
      "notes": notes,
      "area_overview": areaOverview,
      "usage_rights": usageRights,
      "contract": contract,
    };
  }

  String getName() {
    return "$name${space != null ? (", Fläche $space") : ""}, ${town ?? "-"}";
  }
}
