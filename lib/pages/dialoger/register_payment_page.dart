import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sonos_dialoger/app.dart';
import 'package:sonos_dialoger/providers/firestore_providers/user_providers.dart';

import '../../components/misc.dart';
import '../../core/payment.dart';
import '../../core/user.dart';
import '../../providers/firestore_providers.dart';

class RegisterPaymentPage extends ConsumerStatefulWidget {
  final bool editing;
  final String? id;

  const RegisterPaymentPage({super.key, this.id, this.editing = false});

  @override
  ConsumerState<RegisterPaymentPage> createState() =>
      _RegisterPaymentPageState();
}

class _RegisterPaymentPageState extends ConsumerState<RegisterPaymentPage> {
  String? type;
  String? interval = "yearly";
  bool hasFirstPayment = false;
  String? paymentMethod;
  String? myLocationId;

  bool isLoading = false;
  bool isInit = false;

  final amountController = TextEditingController();
  final firstController = TextEditingController();
  final lastController = TextEditingController();
  final hourController = TextEditingController(
    text: DateTime.now().hour.toString().padLeft(2, "0"),
  );
  final minuteController = TextEditingController(
    text: DateTime.now().minute.toString().padLeft(2, "0"),
  );

  Payment? editPayment;

  Timer? timer;

  @override
  void initState() {
    super.initState();
    scheduleMinuteUpdates();
  }

  void scheduleMinuteUpdates() {
    final now = DateTime.now();

    final nextMinute = DateTime(
      now.year,
      now.month,
      now.day,
      now.hour,
      now.minute + 1,
    );

    final delay = nextMinute.difference(now);

    Future.delayed(delay, () {
      updateTimeText();

      timer = Timer.periodic(const Duration(minutes: 1), (_) {
        updateTimeText();
      });
    });
  }

  void updateTimeText() {
    final now = DateTime.now();
    if (minuteController.text == (now.minute - 1).toString() ||
        (now.minute == 0 &&
            minuteController.text == "59" &&
            hourController.text == (now.hour - 1).toString())) {
      hourController.text = now.hour.toString().padLeft(2, "0");
      minuteController.text = now.minute.toString().padLeft(2, "0");
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    amountController.dispose();
    firstController.dispose();
    lastController.dispose();
    hourController.dispose();
    minuteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.editing && !isInit) {
      if (widget.id == null) {
        throw ErrorDescription("No id provided for payment edit page");
      }
      final paymentDoc = ref.watch(paymentProvider(widget.id!));
      if (paymentDoc.isLoading) {
        return Center(child: CircularProgressIndicator());
      }
      if (paymentDoc.hasError) {
        return Center(child: Text("Ups, hier hat etwas nicht geklappt"));
      }
      final data = paymentDoc.value!.data() ?? {};
      editPayment = Payment.fromDoc(paymentDoc.value!);
      if (ref.watch(userDataProvider).value?.role != UserRole.admin &&
          !editPayment!.canDialogerStillEdit()) {
        return Center(
          child: Text("Du kannst diese Leistung nicht mehr bearbeiten"),
        );
      }
      final date =
          ((data["timestamp"] as Timestamp?) ?? Timestamp.now()).toDate();
      type = data["type"];
      amountController.text = data["amount"].toString();
      firstController.text = data["first"] ?? "";
      lastController.text = data["last"] ?? "";
      hourController.text = date.hour.toString();
      minuteController.text = date.minute.toString();
      if (type == "once") {
        paymentMethod = data["method"];
      } else if (type == "twintabo") {
        interval = data["interval"];
      } else {
        interval = data["interval"];
        hasFirstPayment = data["has_first_payment"];
        if (hasFirstPayment) {
          paymentMethod = data["method"];
        }
      }

      isInit = true;
    }
    final scheduleDocs = ref.watch(todayScheduleProvider);

    if (!widget.editing) {
      if (scheduleDocs.isLoading) {
        return Center(child: CircularProgressIndicator());
      }
      if (scheduleDocs.hasError) {
        print(scheduleDocs.error);
        return Center(child: Text("Ups, hier hat etwas nicht geklappt"));
      }
      if (scheduleDocs.value!.docs.isEmpty) {
        return Center(child: Text("Heute bist du nicht eingeteilt"));
      }
      final scheduleData = scheduleDocs.value!.docs[0].data();
      final uid = ref.watch(userProvider).value?.uid;
      if (scheduleData["personnel_assigned"] != true) {
        return Center(child: Text("Heute bist du nicht eingeteilt"));
      }
      final assignments =
          (scheduleData["personnel"] as Map<String, dynamic>? ?? {}).entries
              .where(
                (assignment) => (assignment.value as List? ?? []).contains(uid),
              )
              .toList();
      if (assignments.isEmpty) {
        return Center(child: Text("Heute bist du nicht eingeteilt"));
      }
      final myAssignment = assignments[0];
      myLocationId = myAssignment.key;
    }
    final isTimeComplete =
        int.tryParse(hourController.text) != null &&
        int.tryParse(hourController.text)! >= 0 &&
        int.tryParse(hourController.text)! <= 23 &&
        int.tryParse(minuteController.text) != null &&
        int.tryParse(minuteController.text)! >= 0 &&
        int.tryParse(minuteController.text)! <= 59;
    late final bool isInfoComplete;
    if (type == "once") {
      isInfoComplete = isTimeComplete && amountController.text.isNotEmpty;
    } else if (type == "repeating") {
      isInfoComplete =
          isTimeComplete &&
          firstController.text.isNotEmpty &&
          lastController.text.isNotEmpty &&
          interval != null &&
          (!hasFirstPayment || paymentMethod != null);
    } else {
      isInfoComplete =
          isTimeComplete &&
          firstController.text.isNotEmpty &&
          lastController.text.isNotEmpty &&
          interval != null;
    }
    void resetInputs() {
      setState(() {
        type = null;
        interval = "yearly";
        amountController.text = "";
        firstController.text = "";
        lastController.text = "";
        hourController.text = DateTime.now().hour.toString().padLeft(2, "0");
        minuteController.text = DateTime.now().minute.toString().padLeft(
          2,
          "0",
        );
        hasFirstPayment = false;
        paymentMethod = null;
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("Leistung ${widget.editing ? "bearbeiten" : "erfassen"}"),
        actions: [
          IconButton(
            onPressed: () {
              context.push("/dialog/qr");
            },
            icon: Icon(Icons.qr_code_2),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 5),
              child: Center(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    Row(
                      spacing: 15,
                      children: [
                        Expanded(
                          child: TextFormField(
                            onChanged: (_) => setState(() {}),
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 19),
                            controller: hourController,
                            decoration: InputDecoration(
                              hintText: "Stunde",
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                            ),
                          ),
                        ),
                        Text(
                          ":",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Expanded(
                          child: TextFormField(
                            onChanged: (_) => setState(() {}),
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 19),
                            controller: minuteController,
                            decoration: InputDecoration(
                              hintText: "Minute",
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 15),
                    Row(
                      spacing: 15,
                      children:
                          type == "repeating" || type == "twintabo"
                              ? [
                                Expanded(
                                  child: DropdownButtonFormField(
                                    isDense: false,
                                    dropdownColor:
                                        Theme.of(context).secondaryHeaderColor,
                                    value: type,
                                    decoration: InputDecoration(
                                      hintText: "Zahlungs",
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(24),
                                      ),
                                    ),
                                    items: [
                                      DropdownMenuItem(
                                        value: "once",
                                        child: Text("Einmalig"),
                                      ),
                                      DropdownMenuItem(
                                        value: "repeating",
                                        child: Text("LSV"),
                                      ),
                                      DropdownMenuItem(
                                        value: "twintabo",
                                        child: Text("Twint-Abo"),
                                      ),
                                    ],
                                    onChanged: (value) {
                                      setState(() {
                                        type = value;
                                      });
                                    },
                                  ),
                                ),
                                Expanded(
                                  child: DropdownButtonFormField(
                                    isDense: false,
                                    dropdownColor:
                                        Theme.of(context).secondaryHeaderColor,
                                    value: interval,
                                    decoration: InputDecoration(
                                      hintText: "Zahlungsrhytmus",
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(24),
                                      ),
                                    ),
                                    items: [
                                      DropdownMenuItem(
                                        value: "monthly",
                                        child: Text("Monatlich"),
                                      ),
                                      DropdownMenuItem(
                                        value: "quarterly",
                                        child: Text("Vierteljährlich"),
                                      ),
                                      DropdownMenuItem(
                                        value: "semester",
                                        child: Text("Halbjährlich"),
                                      ),
                                      DropdownMenuItem(
                                        value: "yearly",
                                        child: Text("Jährlich"),
                                      ),
                                    ],
                                    onChanged: (value) {
                                      setState(() {
                                        interval = value;
                                      });
                                    },
                                  ),
                                ),
                              ]
                              : [
                                Expanded(
                                  child: DropdownButtonFormField(
                                    isDense: false,
                                    dropdownColor:
                                        Theme.of(context).secondaryHeaderColor,
                                    value: type,
                                    decoration: InputDecoration(
                                      hintText: "Wähle die Art",
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(24),
                                      ),
                                    ),
                                    items: [
                                      DropdownMenuItem(
                                        value: "once",
                                        child: Text("Einmalig"),
                                      ),
                                      DropdownMenuItem(
                                        value: "repeating",
                                        child: Text("LSV"),
                                      ),
                                      DropdownMenuItem(
                                        value: "twintabo",
                                        child: Text("Twint-Abo"),
                                      ),
                                    ],
                                    onChanged: (value) {
                                      setState(() {
                                        type = value;
                                      });
                                    },
                                  ),
                                ),
                              ],
                    ),
                    SizedBox(height: 15),
                    TextFormField(
                      onChanged: (_) => setState(() {}),
                      controller: amountController,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 25,
                      ),
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        suffix: SizedBox(width: 70, child: Text("CHF")),
                        prefix: SizedBox(width: 70),
                        hintText: "Betrag",
                        hintStyle: TextStyle(fontWeight: FontWeight.normal),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      inputFormatters: <TextInputFormatter>[
                        FilteringTextInputFormatter.allow(
                          RegExp(r'^\d+\.?\d{0,2}'),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    Row(
                      spacing: 15,
                      children: [
                        Expanded(
                          child: TextFormField(
                            onChanged: (_) => setState(() {}),
                            style: TextStyle(fontSize: 19),
                            controller: firstController,
                            decoration: InputDecoration(
                              hintText:
                                  type == "repeating" || type == "twintabo"
                                      ? "Vorname"
                                      : "Vorname (optional)",
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: TextFormField(
                            onChanged: (_) => setState(() {}),
                            style: TextStyle(fontSize: 19),
                            controller: lastController,
                            decoration: InputDecoration(
                              hintText:
                                  type == "repeating" || type == "twintabo"
                                      ? "Nachname"
                                      : "Nachname (optional)",
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 40),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Hat Erstzahlung"),
                        Switch(
                          value: type == "once" || hasFirstPayment,
                          onChanged:
                              type == "repeating"
                                  ? (value) =>
                                      setState(() => hasFirstPayment = value)
                                  : null,
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    DropdownButtonFormField(
                      isDense: false,
                      dropdownColor: Theme.of(context).secondaryHeaderColor,
                      value: paymentMethod,
                      decoration: InputDecoration(
                        hintText: "Zahlungsmittel",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      items: [
                        DropdownMenuItem(value: "sumup", child: Text("SumUp")),
                        DropdownMenuItem(value: "twint", child: Text("Twint")),
                      ],
                      onChanged:
                          ((hasFirstPayment && type == "repeating") ||
                                  type == "once")
                              ? ((value) => setState(
                                () => paymentMethod = value as String?,
                              ))
                              : null,
                    ),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(height: 15),
          Row(
            spacing: 10,
            children: [
              SizedBox(
                height: 100,
                child: OutlinedButton(
                  onPressed: () {
                    if (widget.editing) {
                      context.pop();
                    } else {
                      resetInputs();
                    }
                  },
                  child: Text(widget.editing ? "Abbrechen" : "Zurücksetzen"),
                ),
              ),
              Expanded(
                child: SizedBox(
                  height: 100,
                  child: FilledButton(
                    onPressed:
                        isInfoComplete
                            ? () async {
                              setState(() {
                                isLoading = true;
                              });
                              final commonData = {
                                "type": type,
                                "amount": num.parse(amountController.text),
                                "first": firstController.text,
                                "last": lastController.text,
                                "timestamp": Timestamp.fromDate(
                                  DateTime(
                                    DateTime.now().year,
                                    DateTime.now().month,
                                    DateTime.now().day,
                                    int.tryParse(hourController.text) ??
                                        DateTime.now().hour,
                                    int.tryParse(minuteController.text) ??
                                        DateTime.now().minute,
                                  ),
                                ),
                              };
                              if (!widget.editing) {
                                commonData["location"] = myLocationId;
                                commonData["dialoger"] =
                                    ref.watch(userProvider).value!.uid;
                                commonData["creation_timestamp"] =
                                    Timestamp.now();
                              }

                              final isCoach =
                                  ref.watch(userDataProvider).value?.role ==
                                  UserRole.coach;
                              if (type == "once") {
                                final data = {
                                  ...commonData,
                                  "method": paymentMethod,
                                  "dialoger_share": isCoach ? 0.35 : 0.3333,
                                };
                                if (widget.editing) {
                                  await FirebaseFirestore.instance
                                      .collection("payments")
                                      .doc(widget.id!)
                                      .update(data);
                                } else {
                                  await FirebaseFirestore.instance
                                      .collection("payments")
                                      .add(data);
                                }
                              } else if (type == "twintabo") {
                                final data = {
                                  ...commonData,
                                  "interval": interval,
                                  "dialoger_share": isCoach ? 0.5 : 0.45,
                                  "payment_status": "paid",
                                };
                                if (widget.editing) {
                                  await FirebaseFirestore.instance
                                      .collection("payments")
                                      .doc(widget.id!)
                                      .update(data);
                                } else {
                                  await FirebaseFirestore.instance
                                      .collection("payments")
                                      .add(data);
                                }
                              } else {
                                final data = {
                                  ...commonData,
                                  "has_first_payment": hasFirstPayment,
                                  "interval": interval,
                                  "dialoger_share": isCoach ? 0.6 : 0.5,
                                };
                                if (hasFirstPayment && paymentMethod != null) {
                                  data["method"] = paymentMethod!;
                                  data["payment_status"] = "paid";
                                } else {
                                  data["payment_status"] = "pending";
                                }
                                if (widget.editing) {
                                  await FirebaseFirestore.instance
                                      .collection("payments")
                                      .doc(widget.id!)
                                      .update(data);
                                } else {
                                  await FirebaseFirestore.instance
                                      .collection("payments")
                                      .add(data);
                                }
                              }
                              setState(() {
                                isLoading = false;
                              });
                              if (context.mounted) {
                                showSnackBar(
                                  context,
                                  widget.editing
                                      ? "Änderungen gespeichert!"
                                      : "Leistung erfasst!",
                                );
                                if (widget.editing) {
                                  context.pop();
                                }
                              }
                              if (!widget.editing) {
                                resetInputs();
                              }
                            }
                            : null,
                    child:
                        isLoading
                            ? CircularProgressIndicator(color: Colors.white)
                            : Text(widget.editing ? "Speichern" : "Erfassen"),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
