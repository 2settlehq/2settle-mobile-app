import '/pages/receive_account_setup/receive_account_setup_widget.dart';
import 'package:flutter/material.dart';

class ReceiveDollarAccountWidget extends StatelessWidget {
  const ReceiveDollarAccountWidget({super.key});

  static String routeName = 'ReceiveDollarAccount';
  static String routePath = 'receiveDollarAccount';

  @override
  Widget build(BuildContext context) {
    return const ReceiveAccountSetupScaffold(
      title: 'Dollar Account',
      arrayKey: 'dollarAccounts',
      network: 'USD',
      liveValidate: false,
    );
  }
}
