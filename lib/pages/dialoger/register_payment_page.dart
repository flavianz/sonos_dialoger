import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class RegisterPaymentPage extends StatefulWidget {
  const RegisterPaymentPage({super.key});

  @override
  State<RegisterPaymentPage> createState() => _RegisterPaymentPageState();
}

class _RegisterPaymentPageState extends State<RegisterPaymentPage> {
  String? type;
  String? interval;
  bool hasFirstPayment = false;
  String? paymentMethod;

  bool isLoading = false;

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
    return Column(
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
                    controller: amountController,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 25),
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
                      // for version 2 and greater youcan also use this
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
                        value: hasFirstPayment,
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
                      DropdownMenuItem(
                        value: "twint-fast",
                        child: Text("Twint"),
                      ),
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
                  setState(() {
                    type = null;
                    interval = null;
                    amountController.text = "";
                    firstController.text = "";
                    lastController.text = "";
                    hasFirstPayment = false;
                    paymentMethod = null;
                  });
                },
                child: Text("Zurücksetzen"),
              ),
            ),
            Expanded(
              child: SizedBox(
                height: 100,
                child: FilledButton(
                  onPressed: () {},
                  child:
                      isLoading
                          ? SizedBox(
                            height: 50,
                            width: 50,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                            ),
                          )
                          : Text("Erfassen"),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
