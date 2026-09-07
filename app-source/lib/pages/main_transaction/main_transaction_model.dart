import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/form_field_controller.dart';
import '/index.dart';
import 'main_transaction_widget.dart' show MainTransactionWidget;
import 'package:flutter/material.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

class MainTransactionModel extends FlutterFlowModel<MainTransactionWidget> {
  ///  State fields for stateful widgets in this page.

  final formKey = GlobalKey<FormState>();
  // State field(s) for budget widget.
  String? budgetValue;
  FormFieldController<String>? budgetValueController;
  // State field(s) for Amount widget.
  FocusNode? amountFocusNode;
  TextEditingController? amountTextController;
  late MaskTextInputFormatter amountMask;
  String? Function(BuildContext, String?)? amountTextControllerValidator;
  // State field(s) for Crypto widget.
  String? cryptoValue;
  FormFieldController<String>? cryptoValueController;
  // State field(s) for CryptoNetwork widget.
  String? cryptoNetworkValue;
  FormFieldController<String>? cryptoNetworkValueController;
  // State field(s) for AccNo widget.
  FocusNode? accNoFocusNode;
  TextEditingController? accNoTextController;
  String? Function(BuildContext, String?)? accNoTextControllerValidator;
  // State field(s) for BankName widget.
  String? bankNameValue;
  FormFieldController<String>? bankNameValueController;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    amountFocusNode?.dispose();
    amountTextController?.dispose();

    accNoFocusNode?.dispose();
    accNoTextController?.dispose();
  }
}
