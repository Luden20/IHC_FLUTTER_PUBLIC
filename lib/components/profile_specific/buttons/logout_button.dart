
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../service/pocketbase.service.dart';
import '../../general/shinny_button.dart';

class LogoutButton extends StatelessWidget {
  const LogoutButton({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ShinnyButton(
      alternative: true,
      onPressed: () async {
        await PBService.logout();
      },
      text: 'Cerrar sesión',
      icons: Icons.logout,
      width: 220,
      height: 48,
    );
  }
}