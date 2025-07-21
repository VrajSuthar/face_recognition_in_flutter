import 'package:eduwrx/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CustomDropdown<T> extends StatelessWidget {
  final String? hintText;
  final TextEditingController? controller;
  final ValueChanged<T?>? selectedValue;
  final List<DropdownMenuEntry<T>> items;
  final void Function(T) onChanged;
  final Widget? trailingIcon;
  final DropdownMenuCloseBehavior closeBehavior;
  final T? initialValue;

  const CustomDropdown({
    super.key,
    this.hintText,
    required this.selectedValue,
    required this.items,
    required this.onChanged,
    this.controller,
    this.trailingIcon,
    this.closeBehavior = DropdownMenuCloseBehavior.all,
    this.initialValue,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = Colors.white;

    return DropdownMenu<T>(
      controller: controller,

      trailingIcon: trailingIcon ?? Icon(Icons.arrow_drop_down, size: 24, color: Theme.of(context).iconTheme.color),
      textStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500, color: textColor, fontSize: 16),
      textAlign: TextAlign.end,
      menuStyle: MenuStyle(
        padding: const WidgetStatePropertyAll(EdgeInsets.zero),
        backgroundColor: WidgetStatePropertyAll(Theme.of(context).cardColor),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.r),
            side: BorderSide(color: Colors.white30, width: 1.0),
          ),
        ),
        elevation: const WidgetStatePropertyAll(2),
        shadowColor: const WidgetStatePropertyAll(Colors.black26),
      ),
      onSelected: selectedValue,
      closeBehavior: closeBehavior,
      initialSelection: initialValue,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        isCollapsed: true,
        isDense: true,
        hintStyle: TextStyle(color: textColor, fontFamily: "Muli", fontWeight: FontWeight.w500),
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        labelStyle: Theme.of(context).textTheme.bodyLarge,
        fillColor: Colors.transparent,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r), borderSide: BorderSide.none),
      ),
      hintText: hintText,
      dropdownMenuEntries: items,
    );
  }
}
