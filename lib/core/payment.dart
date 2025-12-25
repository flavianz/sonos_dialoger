import 'package:cloud_firestore/cloud_firestore.dart';

enum PaymentInterval { monthly, quarterly, semester, yearly }

enum PaymentMethod { twint, sumup }

enum PaymentStatus { paid, pending, cancelled }

class Payment {
  final String id;
  final num amount;
  final String dialoger;
  final num dialogerShare;
  final String location;
  final DateTime timestamp;

  PaymentStatus getPaymentStatus() {
    if (this is OncePayment) {
      return PaymentStatus.paid;
    } else {
      if (this is RepeatingPaymentWithFirstPayment) {
        return PaymentStatus.paid;
      } else {
        return (this as RepeatingPaymentWithoutFirstPayment).paymentStatus;
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
        first,
        last,
        paymentMethod,
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
          interval,
          first,
          last,
          paymentMethod,
        );
      } else {
        PaymentStatus paymentStatus = switch (map["payment_status"]) {
          "paid" => PaymentStatus.paid,
          "pending" => PaymentStatus.pending,
          "cancelled" => PaymentStatus.cancelled,
          _ =>
            throw Exception("Invalid payment status ${map["payment_status"]}"),
        };
        return RepeatingPaymentWithoutFirstPayment(
          id,
          amount,
          dialoger,
          dialogerShare,
          location,
          timestamp,
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
  );

  bool isRepeatingPayment() {
    return this is RepeatingPayment;
  }

  bool isOncePayment() {
    return this is OncePayment;
  }
}

class OncePayment extends Payment {
  final String? first;
  final String? last;
  final PaymentMethod paymentMethod;

  OncePayment(
    super.id,
    super.amount,
    super.dialoger,
    super.dialogerShare,
    super.location,
    super.timestamp,
    this.first,
    this.last,
    this.paymentMethod,
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
    this.paymentInterval,
    this.first,
    this.last,
  );
}

class RepeatingPaymentWithFirstPayment extends RepeatingPayment {
  final PaymentMethod paymentMethod;

  RepeatingPaymentWithFirstPayment(
    super.id,
    super.amount,
    super.dialoger,
    super.dialogerShare,
    super.location,
    super.timestamp,
    super.paymentInterval,
    super.first,
    super.last,
    this.paymentMethod,
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
      if (element is RepeatingPaymentWithoutFirstPayment) {
        if (element.paymentStatus == PaymentStatus.cancelled) {
          continue;
        }
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
