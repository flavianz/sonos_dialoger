import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../components/misc.dart';

enum PaymentInterval { monthly, quarterly, semester, yearly }

enum PaymentMethod { twint, sumup }

extension PaymentMethodName on PaymentMethod {
  String paymentMethodName() {
    return switch (this) {
      PaymentMethod.twint => "Twint",
      PaymentMethod.sumup => "Sumup",
    };
  }
}

enum PaymentStatus { paid, pending, cancelled }

extension PaymentStatusName on PaymentStatus {
  Widget widget(BuildContext context) {
    if (this == PaymentStatus.paid) {
      return getPill("Bezahlt", Theme.of(context).primaryColor, true);
    }
    if (this == PaymentStatus.pending) {
      return getPill("Ausstehend", Theme.of(context).primaryColorLight, false);
    }
    return getPill("Zurückgenommen", Theme.of(context).cardColor, false);
  }
}

class Payment {
  final String id;
  final num amount;
  final String dialoger;
  final num dialogerShare;
  final String location;
  final DateTime timestamp;
  final DateTime creationTimestamp;

  PaymentStatus getPaymentStatus() {
    if (this is OncePayment) {
      return (this as OncePayment).paymentStatus ?? PaymentStatus.paid;
    } else {
      if (this is RepeatingPaymentWithFirstPayment) {
        return (this as RepeatingPaymentWithFirstPayment).paymentStatus ??
            PaymentStatus.paid;
      } else if (this is RepeatingTwintPayment) {
        return (this as RepeatingTwintPayment).paymentStatus ??
            PaymentStatus.paid;
      } else {
        return (this as RepeatingPaymentWithoutFirstPayment).paymentStatus;
      }
    }
  }

  PaymentMethod? getPaymentMethod() {
    if (this is OncePayment) {
      return (this as OncePayment).paymentMethod;
    } else {
      if (this is RepeatingPaymentWithFirstPayment) {
        return (this as RepeatingPaymentWithFirstPayment).paymentMethod;
      } else {
        return null;
      }
    }
  }

  factory Payment.fromDoc(DocumentSnapshot doc) {
    final map = doc.data() as Map<String, dynamic>;
    String id = doc.id;
    num amount = map["amount"] as num;
    String dialoger = map["dialoger"] as String;
    num dialogerShare = map["dialoger_share"] as num;
    String location = map["location"] as String;
    DateTime timestamp = (map["timestamp"] as Timestamp).toDate();
    String? first = map["first"] as String?;
    String? last = map["last"] as String?;
    String type = map["type"] as String;
    PaymentStatus? paymentStatus = switch (map["payment_status"]) {
      "paid" => PaymentStatus.paid,
      "pending" => PaymentStatus.pending,
      "cancelled" => PaymentStatus.cancelled,
      _ => null,
    };
    late DateTime creationTimestamp;
    if (map["creation_timestamp"] != null) {
      creationTimestamp = (map["creation_timestamp"] as Timestamp).toDate();
    } else {
      creationTimestamp = timestamp;
    }

    if (type == "once") {
      PaymentMethod paymentMethod = switch (map["method"]) {
        "twint" => PaymentMethod.twint,
        "sumup" => PaymentMethod.sumup,
        _ => throw Exception("Invalid payment method ${map["method"]}"),
      };
      return OncePayment(
        id,
        amount,
        dialoger,
        dialogerShare,
        location,
        timestamp,
        creationTimestamp,
        first,
        last,
        paymentMethod,
        paymentStatus,
      );
    } else if (type == "twintabo") {
      PaymentInterval interval = switch (map["interval"]) {
        "monthly" => PaymentInterval.monthly,
        "quarterly" => PaymentInterval.quarterly,
        "semester" => PaymentInterval.semester,
        "yearly" => PaymentInterval.yearly,
        _ => throw Exception("Invalid payment interval ${map["interval"]}"),
      };
      first = map["first"] as String;
      last = map["last"] as String;
      return RepeatingTwintPayment(
        id,
        amount,
        dialoger,
        dialogerShare,
        location,
        timestamp,
        creationTimestamp,
        interval,
        first,
        last,
        paymentStatus,
      );
    } else {
      bool hasFirstPayment = map["has_first_payment"] as bool;
      PaymentInterval interval = switch (map["interval"]) {
        "monthly" => PaymentInterval.monthly,
        "quarterly" => PaymentInterval.quarterly,
        "semester" => PaymentInterval.semester,
        "yearly" => PaymentInterval.yearly,
        _ => throw Exception("Invalid payment interval ${map["interval"]}"),
      };
      first = map["first"] as String;
      last = map["last"] as String;
      if (hasFirstPayment == true) {
        PaymentMethod paymentMethod = switch (map["method"]) {
          "twint" => PaymentMethod.twint,
          "sumup" => PaymentMethod.sumup,
          _ => throw Exception("Invalid payment method ${map["method"]}"),
        };
        return RepeatingPaymentWithFirstPayment(
          id,
          amount,
          dialoger,
          dialogerShare,
          location,
          timestamp,
          creationTimestamp,
          interval,
          first,
          last,
          paymentMethod,
          paymentStatus,
        );
      } else {
        if (paymentStatus == null) {
          throw Exception("Invalid payment status ${map["payment_status"]}");
        }
        return RepeatingPaymentWithoutFirstPayment(
          id,
          amount,
          dialoger,
          dialogerShare,
          location,
          timestamp,
          creationTimestamp,
          interval,
          first,
          last,
          paymentStatus,
        );
      }
    }
  }

  Payment(
    this.id,
    this.amount,
    this.dialoger,
    this.dialogerShare,
    this.location,
    this.timestamp,
    this.creationTimestamp,
  );

  bool isRepeatingPayment() {
    return this is RepeatingPayment;
  }

  bool isOncePayment() {
    return this is OncePayment;
  }

  bool canDialogerStillEdit() {
    return timestamp.isSameDate(DateTime.now()) ||
        (timestamp.isSameDate(DateTime.now().addDays(1)) &&
            DateTime.now().hour < 11);
  }
}

class OncePayment extends Payment {
  final String? first;
  final String? last;
  final PaymentMethod paymentMethod;
  final PaymentStatus? paymentStatus;

  OncePayment(
    super.id,
    super.amount,
    super.dialoger,
    super.dialogerShare,
    super.location,
    super.timestamp,
    super.creationTimestamp,
    this.first,
    this.last,
    this.paymentMethod,
    this.paymentStatus,
  );
}

class RepeatingPayment extends Payment {
  final PaymentInterval paymentInterval;
  final String first;
  final String last;

  RepeatingPayment(
    super.id,
    super.amount,
    super.dialoger,
    super.dialogerShare,
    super.location,
    super.timestamp,
    super.creationTimestamp,
    this.paymentInterval,
    this.first,
    this.last,
  );
}

class RepeatingTwintPayment extends RepeatingPayment {
  final PaymentStatus? paymentStatus;

  RepeatingTwintPayment(
    super.id,
    super.amount,
    super.dialoger,
    super.dialogerShare,
    super.location,
    super.timestamp,
    super.creationTimestamp,
    super.paymentInterval,
    super.first,
    super.last,
    this.paymentStatus,
  );
}

class RepeatingPaymentWithFirstPayment extends RepeatingPayment {
  final PaymentMethod paymentMethod;
  final PaymentStatus? paymentStatus;

  RepeatingPaymentWithFirstPayment(
    super.id,
    super.amount,
    super.dialoger,
    super.dialogerShare,
    super.location,
    super.timestamp,
    super.creationTimestamp,
    super.paymentInterval,
    super.first,
    super.last,
    this.paymentMethod,
    this.paymentStatus,
  );
}

class RepeatingPaymentWithoutFirstPayment extends RepeatingPayment {
  final PaymentStatus paymentStatus;

  RepeatingPaymentWithoutFirstPayment(
    super.id,
    super.amount,
    super.dialoger,
    super.dialogerShare,
    super.location,
    super.timestamp,
    super.creationTimestamp,
    super.paymentInterval,
    super.first,
    super.last,
    this.paymentStatus,
  );
}

extension PaymentsSum on Iterable<Payment> {
  num get sum {
    num sum = 0;
    for (var element in this) {
      if (element.getPaymentStatus() == PaymentStatus.cancelled) {
        continue;
      }

      sum += element.amount;
    }
    return sum;
  }

  num get sumWithoutDialogerShare {
    num sum = 0;
    for (var element in this) {
      if (element is RepeatingPaymentWithoutFirstPayment) {
        if (element.paymentStatus == PaymentStatus.cancelled) {
          continue;
        }
      }
      sum += element.amount * (1 - element.dialogerShare);
    }
    return sum;
  }

  num get dialogerShareSum {
    num sum = 0;
    for (var element in this) {
      if (element is RepeatingPaymentWithoutFirstPayment) {
        if (element.paymentStatus == PaymentStatus.cancelled) {
          continue;
        }
      }
      sum += element.amount * element.dialogerShare;
    }
    return sum;
  }
}
