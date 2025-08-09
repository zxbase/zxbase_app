import 'package:flutter/material.dart';

// Zero trust text form field,
// preventing OS from reading the content.
class ZTTextFormField extends TextFormField {
  ZTTextFormField({
    super.key,
    super.autocorrect = false,
    super.enableSuggestions = false,
    autofillHints = false,
    super.inputFormatters,
    super.onChanged,
    super.validator,
    super.obscureText,
    super.keyboardType,
    super.decoration,
    super.controller,
    super.textAlign,
    super.maxLines,
    super.readOnly,
    super.focusNode,
    super.onSaved,
    super.initialValue,
    super.enabled,
  }) : super();
}
