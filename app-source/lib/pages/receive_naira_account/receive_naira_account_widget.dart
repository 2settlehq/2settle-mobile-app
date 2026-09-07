import '/pages/receive_account_setup/receive_account_setup_widget.dart';
import 'package:flutter/material.dart';

class ReceiveNairaAccountWidget extends StatelessWidget {
  const ReceiveNairaAccountWidget({super.key});

  static String routeName = 'ReceiveNairaAccount';
  static String routePath = 'receiveNairaAccount';

  @override
  Widget build(BuildContext context) {
    return const ReceiveAccountSetupScaffold(
      title: 'Naira Account',
      arrayKey: 'nairaAccounts',
      network: 'NGN',
      liveValidate: true,
    );
  }
}
