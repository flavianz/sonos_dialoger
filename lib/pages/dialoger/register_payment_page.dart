import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sonos_dialoger/app.dart';
import 'package:sonos_dialoger/providers/firestore_providers/user_providers.dart';

import '../../components/misc.dart';
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

  @override
  void dispose() {
    amountController.dispose();
    firstController.dispose();
    lastController.dispose();
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
      type = data["type"];
      amountController.text = data["amount"].toString();
      firstController.text = data["first"] ?? "";
      lastController.text = data["last"] ?? "";
      if (type == "once") {
        paymentMethod = data["method"];
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
    final isInfoComplete =
        amountController.text.isNotEmpty &&
        (type == "once"
            ? paymentMethod != null
            : firstController.text.isNotEmpty &&
                lastController.text.isNotEmpty &&
                interval != null &&
                (!hasFirstPayment || paymentMethod != null));
    void resetInputs() {
      setState(() {
        type = null;
        interval = "yearly";
        amountController.text = "";
        firstController.text = "";
        lastController.text = "";
        hasFirstPayment = false;
        paymentMethod = null;
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("Leistung erfassen"),
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
                      children:
                          type == "repeating"
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
                                        child: Text("Wiederholend"),
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
                                        child: Text("Wiederholend"),
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
                                  type == "repeating"
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
                                  type == "repeating"
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
                          (hasFirstPayment || type == "once")
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
                                "dialoger":
                                    ref.watch(userProvider).value?.uid ?? "",
                                "timestamp": Timestamp.fromDate(DateTime.now()),
                              };
                              if (myLocationId != null) {
                                commonData["location"] = myLocationId!;
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
                                      .set(data);
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
                                      .set(data);
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
