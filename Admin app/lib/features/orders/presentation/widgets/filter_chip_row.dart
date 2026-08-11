import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class FilterChipRow extends StatelessWidget {
  final List<String> filters;
  final String selectedFilter;
  final Function(String) onFilterSelected;

  const FilterChipRow({
    super.key,
    required this.filters,
    required this.selectedFilter,
    required this.onFilterSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      color: AppColors.white,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: filters.map((filter) {
            final isSelected = filter == selectedFilter;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(filter),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) {
                    onFilterSelected(filter);
                  }
                },
                selectedColor: AppColors.primary.withOpacity(0.15),
                backgroundColor: AppColors.gray100,
                labelStyle: TextStyle(
                  color: isSelected ? AppColors.primary : AppColors.gray700,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  fontSize: 13,
                ),
                side: BorderSide(
                  color: isSelected ? AppColors.primary : AppColors.gray300,
                ),
                showCheckmark: false,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
