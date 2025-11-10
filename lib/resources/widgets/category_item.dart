import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_app/app/models/category.dart';
import 'package:flutter_app/bootstrap/helpers.dart';

typedef CategoryItemBuilder = Widget Function(
    CategoryModel cate, bool isSelected, BuildContext context);

class CategoryHeader extends StatelessWidget {
  final List<CategoryModel> categories;
  final int? selectedId;
  final ValueChanged<CategoryModel>? onTap;
  final EdgeInsetsGeometry margin;
  final CategoryItemBuilder? itemBuilder;

  const CategoryHeader({
    Key? key,
    required this.categories,
    this.selectedId,
    this.onTap,
    this.margin = const EdgeInsets.only(right: 16, left: 16, top: 6, bottom: 6),
    this.itemBuilder,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    ScreenUtil.init(context);
    return Container(
      width: 1.sw,
      clipBehavior: Clip.none,
      margin: margin,
      child: SingleChildScrollView(
        clipBehavior: Clip.none,
        scrollDirection: Axis.horizontal,
        child: Row(
          children: categories
              .map((e) {
                final isSelected = e.id == selectedId;
                final child = itemBuilder != null
                    ? itemBuilder!(e, isSelected, context)
                    : _defaultItem(e, isSelected, context);
                return GestureDetector(
                  onTap: () => onTap?.call(e),
                  child: child,
                );
              })
              .toList()
              .cast<Widget>(),
        ),
      ),
    );
  }

  Widget _defaultItem(
      CategoryModel cate, bool isSelected, BuildContext context) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 220),
      curve: Curves.easeOut,
      margin: EdgeInsets.symmetric(horizontal: 3),
      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: isSelected
            ? ThemeColor.get(context).primaryAccent.withOpacity(0.1)
            : Colors.grey[100],
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color:
                      ThemeColor.get(context).primaryAccent.withOpacity(0.18),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                  spreadRadius: 2,
                ),
              ]
            : [],
      ),
      transform: Matrix4.identity()..scale(isSelected ? 1.08 : 1.0),
      child: Center(
        child: Text(
          cate.name ?? '',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? ThemeColor.get(context).primaryAccent
                    : Colors.grey[700],
              ),
        ),
      ),
    );
  }
}
