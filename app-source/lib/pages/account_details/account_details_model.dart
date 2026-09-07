import '/backend/api_requests/api_calls.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/form_field_controller.dart';
import '/index.dart';
import 'account_details_widget.dart' show AccountDetailsWidget;
import 'package:flutter/material.dart';

class AccountDetailsModel extends FlutterFlowModel<AccountDetailsWidget> {
  ///  State fields for stateful widgets in this page.

  // State field(s) for accNumber widget.
  FocusNode? accNumberFocusNode;
  TextEditingController? accNumberTextController;
  String? Function(BuildContext, String?)? accNumberTextControllerValidator;
  // State field(s) for BankName widget.
  String? bankNameValue;
  FormFieldController<String>? bankNameValueController;
  // Stores action output result for [Backend Call - API (BankName Check)] action in BankName widget.
  ApiCallResponse? bankName;
  // State field(s) for AccountName widget.
  FocusNode? accountNameFocusNode;
  TextEditingController? accountNameTextController;
  String? Function(BuildContext, String?)? accountNameTextControllerValidator;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    accNumberFocusNode?.dispose();
    accNumberTextController?.dispose();

    accountNameFocusNode?.dispose();
    accountNameTextController?.dispose();
  }
}
