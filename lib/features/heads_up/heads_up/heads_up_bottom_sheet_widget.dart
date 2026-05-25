// lib/features/heads_up/views/heads_up_bottom_sheet.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:seizure_app/core/constants/dimensions.dart';
import 'package:seizure_app/features/heads_up/view_models/heads_up_view_model.dart';

class HeadsUpBottomSheet extends StatelessWidget {
  const HeadsUpBottomSheet({super.key});

  static void show() {
    Get.bottomSheet(
      const HeadsUpBottomSheet(),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      isScrollControlled: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = HeadsUpViewModel.instance();

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          Dimensions.twentyFour,
          Dimensions.twenty,
          Dimensions.twentyFour,
          Dimensions.thirtyTwo,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: Dimensions.twentyFour,
          children: [
            /// Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            /// Header
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: Dimensions.eight,
              children: [
                Text('Heads Up', style: Theme.of(context).textTheme.titleLarge),
                Text(
                  'Let your circle know you\'re feeling off. If you don\'t check in, they\'ll be notified to reach out.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.black54),
                ),
              ],
            ),

            /// Check-in window
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: Dimensions.twelve,
              children: [
                Text('Notify if no check-in within', style: Theme.of(context).textTheme.bodyMedium),
                Obx(() => Row(
                  spacing: Dimensions.eight,
                  children: HeadsUpViewModel.windowOptions.map((minutes) {
                    final isSelected = vm.selectedMinutes.value == minutes;
                    final label = minutes == 60 ? '1 hr' : minutes == 120 ? '2 hrs' : '30 min';
                    return GestureDetector(
                      onTap: () => vm.selectedMinutes.value = minutes,
                      child: AnimatedContainer(
                        duration: Duration(milliseconds: 150),
                        padding: EdgeInsets.symmetric(horizontal: Dimensions.sixteen, vertical: Dimensions.twelve),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.black : Colors.transparent,
                          border: Border.all(color: isSelected ? Colors.black : Colors.black26),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          label,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.black,
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                )),
              ],
            ),

            /// Optional note
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: Dimensions.twelve,
              children: [
                Text('Add a note (optional)', style: Theme.of(context).textTheme.bodyMedium),
                TextField(
                  controller: vm.noteController,
                  maxLines: 3,
                  maxLength: 120,
                  decoration: InputDecoration(
                    hintText: 'e.g. Feeling an aura, heading home...',
                    hintStyle: TextStyle(color: Colors.black38, fontSize: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.black12),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.black12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.black, width: 1.5),
                    ),
                    contentPadding: EdgeInsets.all(Dimensions.sixteen),
                  ),
                ),
              ],
            ),

            /// What happens next
            Container(
              padding: EdgeInsets.all(Dimensions.sixteen),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.04),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: Dimensions.eight,
                children: [
                  Text('What happens next', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  _Step(number: '1', text: 'Your circle is notified you\'re feeling off'),
                  _Step(number: '2', text: 'A countdown starts on your home screen'),
                  _Step(number: '3', text: 'Check in anytime to cancel the alert'),
                  _Step(number: '4', text: 'If time runs out, your circle is told to reach out'),
                ],
              ),
            ),

            /// Send button
            Obx(() => SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: vm.isLoading.value ? null : vm.startHeadsUp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: Dimensions.sixteen),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: vm.isLoading.value
                    ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text('Send Heads Up', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            )),
          ],
        ),
      ),
    );
  }
}

class _Step extends StatelessWidget {
  final String number;
  final String text;

  const _Step({required this.number, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 10,
      children: [
        Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.black),
          child: Center(child: Text(number, style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))),
        ),
        Expanded(child: Text(text, style: TextStyle(fontSize: 13, color: Colors.black54))),
      ],
    );
  }
}