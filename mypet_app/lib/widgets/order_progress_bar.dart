import 'package:flutter/material.dart';
import '../core/colors.dart';
import '../core/order_status.dart';

class OrderProgressBar extends StatelessWidget {
  final String status;
  final bool pickup;
  const OrderProgressBar({super.key, required this.status, this.pickup = false});

  @override
  Widget build(BuildContext context) {
    final steps = OrderTracking.flow;
    final labels = OrderTracking.stepLabels(pickup: pickup);
    final currentIdx = OrderTracking.indexOf(status);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(steps.length, (i) {
        final done = i <= currentIdx;
        final color = done ? OrderTracking.color(steps[i]) : AppColors.greyLight;
        return Expanded(
          child: Column(children: [
            Row(children: [
              if (i > 0)
                Expanded(child: Container(height: 2, color: i <= currentIdx ? AppColors.primary : AppColors.greyLight)),
              Container(width: 12, height: 12,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
              if (i < steps.length - 1)
                Expanded(child: Container(height: 2, color: i < currentIdx ? AppColors.primary : AppColors.greyLight)),
            ]),
            const SizedBox(height: 4),
            Text(labels[i],
                style: TextStyle(
                  fontSize: 9,
                  color: done ? color : AppColors.greyLight,
                  fontWeight: i == currentIdx ? FontWeight.bold : FontWeight.normal,
                ),
                textAlign: TextAlign.center),
          ]),
        );
      }),
    );
  }
}
