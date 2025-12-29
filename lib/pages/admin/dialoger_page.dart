import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/user.dart';
import '../../providers/firestore_providers/user_providers.dart';

class DialogerPage extends ConsumerWidget {
  const DialogerPage({super.key});

  @override
  Widget build(BuildContext context, ref) {
    final dialoguers = ref.watch(nonAdminUsersProvider);

    if (dialoguers.isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (dialoguers.hasError) {
      print(dialoguers.error);
      return Center(child: Text("Ups, hier hat etwas nicht geklappt"));
    }

    return Scaffold(
      appBar: AppBar(
        forceMaterialTransparency: true,
        title: Text("Dialoger"),
        actions: [
          FilledButton.icon(
            onPressed: () {
              context.push("/admin/dialoger/new");
            },
            label: Text("Neu"),
            icon: Icon(Icons.add),
          ),
        ],
      ),
      body: Column(
        children: [
          Divider(color: Theme.of(context).primaryColor),
          Expanded(
            child: ListView(
              children:
                  dialoguers.value!.map((dialoguer) {
                    return Column(
                      children: [
                        GestureDetector(
                          onTap: () {
                            context.push("/admin/dialog/${dialoguer.id}");
                          },
                          child: MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    "${dialoguer.first} ${dialoguer.last}",
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    dialoguer.role == UserRole.coach
                                        ? "Coach"
                                        : "DialogerIn",
                                  ),
                                ),
                                IconButton(
                                  onPressed: () {
                                    context.push(
                                      "/admin/dialog/${dialoguer.id}/edit",
                                    );
                                  },
                                  icon: Icon(Icons.edit),
                                  tooltip: "Bearbeiten",
                                ),
                                IconButton(
                                  onPressed: () {},
                                  icon: Icon(Icons.delete),
                                  tooltip: "Löschen",
                                ),
                              ],
                            ),
                          ),
                        ),
                        Divider(),
                      ],
                    );
                  }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
