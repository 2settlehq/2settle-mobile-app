import '/flutter_flow/flutter_flow_util.dart';
import 'set_app_passcode_widget.dart' show SetAppPasscodeWidget;
import 'package:flutter/material.dart';

class SetAppPasscodeModel extends FlutterFlowModel<SetAppPasscodeWidget> {
  TextEditingController? pinCodeController;
  FocusNode? pinCodeFocusNode;
  String? Function(BuildContext, String?)? pinCodeControllerValidator;

  @override
  void initState(BuildContext context) {
    pinCodeController = TextEditingController();
  }

  @override
  void dispose() {
    pinCodeFocusNode?.dispose();
    pinCodeController?.dispose();
  }
}
