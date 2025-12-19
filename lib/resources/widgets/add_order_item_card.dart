import 'package:flutter/material.dart';
import 'package:flutter_app/app/models/Ingredient.dart';
import 'package:flutter_app/app/utils/formatters.dart';
import 'package:flutter_app/bootstrap/helpers.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:form_builder_validators/form_builder_validators.dart';

class AddOrderItemCard extends StatelessWidget {
  final Ingredient ingredient;
  final int discountType;
  final Function() onRemove;
  final Function(num) onQuantityChange;
  final VoidCallback onUpdate;

  const AddOrderItemCard({
    Key? key,
    required this.ingredient,
    required this.discountType,
    required this.onRemove,
    required this.onQuantityChange,
    required this.onUpdate,
  }) : super(key: key);

  Widget _ingredientIcon({double size = 50}) {
    if (ingredient.image != null && ingredient.image!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          ingredient.image!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _fallbackIcon(size),
        ),
      );
    }
    return _fallbackIcon(size);
  }

  Widget _fallbackIcon(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: FaIcon(
          FontAwesomeIcons.leaf,
          size: size * 0.5,
          color: Colors.grey[600],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header: Image, Name, Remove button
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(10),
                topRight: Radius.circular(10),
              ),
            ),
            child: Row(
              children: [
                _ingredientIcon(),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ingredient.name ?? '',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (ingredient.unit != null &&
                          ingredient.unit!.isNotEmpty)
                        Text(
                          'Đơn vị: ${ingredient.unit}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: onRemove,
                  tooltip: 'Xóa',
                ),
              ],
            ),
          ),

          // Body: Price, Quantity, Discount, Note
          Padding(
            padding: EdgeInsets.all(12),
            child: Column(
              children: [
                // Row 1: Price
                Row(
                  children: [
                    Expanded(
                      child: FormBuilderTextField(
                        name: 'price_${ingredient.id}',
                        initialValue:
                            vnd.format(roundMoney(ingredient.baseCost ?? 0)),
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Giá nhập *',
                          hintText: '0',
                          prefixIcon: Icon(Icons.attach_money, size: 20),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 12, vertical: 12),
                          isDense: true,
                        ),
                        style: TextStyle(fontSize: 14),
                        validator: FormBuilderValidators.compose([
                          FormBuilderValidators.required(
                              errorText: 'Vui lòng nhập giá'),
                          FormBuilderValidators.numeric(
                              errorText: 'Giá phải là số'),
                          FormBuilderValidators.min(1,
                              errorText: 'Giá phải lớn hơn 0'),
                        ]),
                        onChanged: (value) => onUpdate(),
                      ),
                    ),
                    SizedBox(width: 4),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[400]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            // Minus button
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(8),
                                  bottomLeft: Radius.circular(8),
                                ),
                                onTap: () {
                                  num current = ingredient.quantity ?? 1;
                                  if (current > 1) {
                                    onQuantityChange(current - 1);
                                    onUpdate();
                                  }
                                },
                                child: Container(
                                  padding: EdgeInsets.all(12),
                                  child: Icon(Icons.remove, size: 20),
                                ),
                              ),
                            ),
                            Expanded(
                              child: Container(
                                padding: EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  border: Border(
                                    left: BorderSide(color: Colors.grey[400]!),
                                    right: BorderSide(color: Colors.grey[400]!),
                                  ),
                                ),
                                child: Text(
                                  '${roundQuantity(ingredient.quantity ?? 1)}',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            // Plus button
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.only(
                                  topRight: Radius.circular(8),
                                  bottomRight: Radius.circular(8),
                                ),
                                onTap: () {
                                  num current = ingredient.quantity ?? 1;
                                  onQuantityChange(current + 1);
                                  onUpdate();
                                },
                                child: Container(
                                  padding: EdgeInsets.all(12),
                                  child: Icon(Icons.add, size: 20),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: FormBuilderTextField(
                        name: 'discount_${ingredient.id}',
                        keyboardType:
                            TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          labelText: 'Giảm giá',
                          hintText: '0',
                          prefixIcon: Icon(Icons.discount, size: 20),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 12, vertical: 12),
                          isDense: true,
                        ),
                        style: TextStyle(fontSize: 14),
                        onChanged: (value) => onUpdate(),
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      flex: 1,
                      child: FormBuilderDropdown<int>(
                        name: 'discount_type_${ingredient.id}',
                        initialValue: discountType,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding:
                              EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                          isDense: true,
                        ),
                        style: TextStyle(fontSize: 14, color: Colors.black),
                        items: [
                          DropdownMenuItem(value: 1, child: Text('%')),
                          DropdownMenuItem(value: 2, child: Text('VND')),
                        ],
                        onChanged: (value) => onUpdate(),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),

                // Row 4: Note
                FormBuilderTextField(
                  name: 'note_${ingredient.id}',
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'Ghi chú',
                    hintText: 'Nhập ghi chú (nếu có)...',
                    prefixIcon: Icon(Icons.note, size: 20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    isDense: true,
                  ),
                  style: TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
