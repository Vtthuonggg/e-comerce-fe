import 'package:currency_text_input_formatter/currency_text_input_formatter.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app/app/models/product.dart';
import 'package:flutter_app/app/utils/formatters.dart';
import 'package:flutter_app/bootstrap/helpers.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_app/resources/widgets/select_topping.dart';

class OrderProductItem extends StatefulWidget {
  final Product item;
  final int index;
  final VoidCallback updatePaid;
  final Function(Product) removeItem;
  final VoidCallback onMinusQuantity;
  final Function(String) onChangeQuantity;
  final VoidCallback onIncreaseQuantity;
  final Function(String) onChangePrice;
  final Function(String) onChangeDiscount;
  final Function(DiscountType) onChangeDiscountType;
  final num Function() getPrice;
  OrderProductItem({
    Key? key,
    required this.item,
    required this.index,
    required this.updatePaid,
    required this.removeItem,
    required this.onMinusQuantity,
    required this.onChangeQuantity,
    required this.onIncreaseQuantity,
    required this.onChangePrice,
    required this.onChangeDiscount,
    required this.onChangeDiscountType,
    required this.getPrice,
  }) : super(key: key);

  @override
  State<OrderProductItem> createState() => _OrderProductItemState();
}

class _OrderProductItemState extends State<OrderProductItem> {
  List<Product> get selectedToppings =>
      (widget.item.toppings ?? []).cast<Product>();
  final _selectToppingMultiKey = GlobalKey<DropdownSearchState<Product>>();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with name and delete button
          Row(
            children: [
              Expanded(
                child: Text(
                  "${widget.index + 1}. ${widget.item.name ?? ''} ",
                  maxLines: 2,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    overflow: TextOverflow.fade,
                  ),
                ),
              ),
              InkWell(
                onTap: () {
                  widget.removeItem(widget.item);
                },
                child: Icon(
                  Icons.delete_outline,
                  size: 25,
                  color: ThemeColor.get(context).primaryAccent,
                ),
              ),
            ],
          ),
          6.verticalSpace,

          // Quantity, Price, Discount row
          Row(
            children: [
              // Quantity control
              Expanded(
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: ThemeColor.get(context)
                          .primaryAccent
                          .withOpacity(0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      // Minus button
                      InkWell(
                        onTap: widget.onMinusQuantity,
                        borderRadius:
                            BorderRadius.horizontal(left: Radius.circular(9)),
                        child: Container(
                          width: 36,
                          height: 40,
                          decoration: BoxDecoration(
                            color: ThemeColor.get(context)
                                .primaryAccent
                                .withOpacity(0.1),
                            borderRadius: BorderRadius.horizontal(
                                left: Radius.circular(9)),
                          ),
                          child: Icon(
                            Icons.remove,
                            size: 18,
                            color: ThemeColor.get(context).primaryAccent,
                          ),
                        ),
                      ),

                      // Quantity input
                      Expanded(
                        child: Container(
                          color: Colors.white,
                          child: TextField(
                            controller: widget.item.txtQuantity,
                            onTapOutside: (value) {
                              FocusScope.of(context).unfocus();
                            },
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: ThemeColor.get(context).primaryAccent,
                            ),
                            keyboardType: TextInputType.numberWithOptions(
                                signed: true, decimal: true),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'^\d+\.?\d{0,3}'),
                              ),
                            ],
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              contentPadding:
                                  EdgeInsets.symmetric(vertical: 10),
                              hintText: '0',
                              hintStyle: TextStyle(color: Colors.grey[400]),
                            ),
                            onChanged: widget.onChangeQuantity,
                          ),
                        ),
                      ),

                      // Plus button
                      InkWell(
                        onTap: widget.onIncreaseQuantity,
                        borderRadius:
                            BorderRadius.horizontal(right: Radius.circular(9)),
                        child: Container(
                          width: 36,
                          height: 40,
                          decoration: BoxDecoration(
                            color: ThemeColor.get(context)
                                .primaryAccent
                                .withOpacity(0.1),
                            borderRadius: BorderRadius.horizontal(
                                right: Radius.circular(9)),
                          ),
                          child: Icon(
                            Icons.add,
                            size: 18,
                            color: ThemeColor.get(context).primaryAccent,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              8.horizontalSpace,

              // Price input
              Expanded(
                child: Container(
                  height: 40,
                  child: TextField(
                    controller: widget.item.txtPrice,
                    onTapOutside: (value) {
                      FocusScope.of(context).unfocus();
                    },
                    textAlign: TextAlign.right,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      CurrencyTextInputFormatter(
                        locale: 'vi',
                        symbol: '',
                      )
                    ],
                    decoration: InputDecoration(
                      floatingLabelBehavior: FloatingLabelBehavior.never,
                      suffixText: 'đ',
                      hintText: '0',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    onChanged: widget.onChangePrice,
                  ),
                ),
              ),
              8.horizontalSpace,

              // Discount input with type selector
              Expanded(
                child: Container(
                  height: 40,
                  child: TextField(
                    controller: widget.item.txtDiscount,
                    onTapOutside: (value) {
                      FocusScope.of(context).unfocus();
                    },
                    textAlign: TextAlign.right,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    keyboardType: TextInputType.number,
                    inputFormatters:
                        widget.item.discountType == DiscountType.percent
                            ? [
                                FilteringTextInputFormatter.allow(
                                  RegExp(r'^\d+\.?\d{0,2}'),
                                ),
                              ]
                            : [
                                CurrencyTextInputFormatter(
                                  locale: 'vi',
                                  symbol: '',
                                )
                              ],
                    decoration: InputDecoration(
                      suffixIcon:
                          CupertinoSlidingSegmentedControl<DiscountType>(
                        thumbColor: ThemeColor.get(context).primaryAccent,
                        onValueChanged: (DiscountType? value) {
                          if (value != null) {
                            widget.onChangeDiscountType(value);
                          }
                        },
                        children: {
                          DiscountType.percent: Container(
                            child: Text(
                              '%',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: widget.item.discountType ==
                                        DiscountType.percent
                                    ? Colors.white
                                    : Colors.black,
                              ),
                            ),
                          ),
                          DiscountType.price: Container(
                            child: Text(
                              'đ',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: widget.item.discountType ==
                                        DiscountType.price
                                    ? Colors.white
                                    : Colors.black,
                              ),
                            ),
                          )
                        },
                        groupValue: widget.item.discountType,
                      ),
                      floatingLabelBehavior: FloatingLabelBehavior.never,
                      hintText: '0',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    onChanged: widget.onChangeDiscount,
                  ),
                ),
              ),
            ],
          ),
          4.verticalSpace,

          // Note input
          Container(
            height: 40,
            child: TextField(
              controller: widget.item.txtNote,
              onTapOutside: (value) {
                FocusScope.of(context).unfocus();
              },
              style: TextStyle(fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Ghi chú...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                isDense: true,
              ),
              onChanged: (val) {
                widget.item.note = val;
              },
            ),
          ),
          8.verticalSpace,

          ToppingMultiSelect(
            multiKey: _selectToppingMultiKey,
            selectedToppings: selectedToppings,
            onSelect: (toppings) {
              setState(() {
                widget.item.toppings = toppings ?? [];
              });
              widget.updatePaid();
            },
          ),

          if (selectedToppings.isNotEmpty) ...[
            8.verticalSpace,
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: ThemeColor.get(context).primaryAccent.withOpacity(0.05),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: ThemeColor.get(context).primaryAccent.withOpacity(0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.restaurant_menu,
                        size: 14,
                        color: ThemeColor.get(context).primaryAccent,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Topping đã chọn:',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: ThemeColor.get(context).primaryAccent,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  ...selectedToppings.map((topping) => Padding(
                        padding: EdgeInsets.only(bottom: 6),
                        child: Row(
                          children: [
                            Container(
                              width: 4,
                              height: 4,
                              decoration: BoxDecoration(
                                color: ThemeColor.get(context).primaryAccent,
                                shape: BoxShape.circle,
                              ),
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                topping.name ?? '',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[800],
                                ),
                              ),
                            ),
                            // Quantity controls
                            Container(
                              height: 24,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: ThemeColor.get(context)
                                      .primaryAccent
                                      .withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  InkWell(
                                    onTap: () {
                                      if (topping.quantity > 1) {
                                        setState(() {
                                          topping.quantity--;
                                          topping.txtQuantity.text =
                                              roundQuantity(topping.quantity);
                                        });
                                        widget.updatePaid();
                                      }
                                    },
                                    borderRadius: BorderRadius.horizontal(
                                        left: Radius.circular(5)),
                                    child: Container(
                                      width: 24,
                                      height: 24,
                                      decoration: BoxDecoration(
                                        color: ThemeColor.get(context)
                                            .primaryAccent
                                            .withOpacity(0.1),
                                        borderRadius: BorderRadius.horizontal(
                                            left: Radius.circular(5)),
                                      ),
                                      child: Icon(
                                        Icons.remove,
                                        size: 12,
                                        color: ThemeColor.get(context)
                                            .primaryAccent,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    constraints: BoxConstraints(minWidth: 28),
                                    alignment: Alignment.center,
                                    padding:
                                        EdgeInsets.symmetric(horizontal: 4),
                                    child: Text(
                                      roundQuantity(topping.quantity),
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: ThemeColor.get(context)
                                            .primaryAccent,
                                      ),
                                    ),
                                  ),
                                  InkWell(
                                    onTap: () {
                                      setState(() {
                                        topping.quantity++;
                                        topping.txtQuantity.text =
                                            roundQuantity(topping.quantity);
                                      });
                                      widget.updatePaid();
                                    },
                                    borderRadius: BorderRadius.horizontal(
                                        right: Radius.circular(5)),
                                    child: Container(
                                      width: 24,
                                      height: 24,
                                      decoration: BoxDecoration(
                                        color: ThemeColor.get(context)
                                            .primaryAccent
                                            .withOpacity(0.1),
                                        borderRadius: BorderRadius.horizontal(
                                            right: Radius.circular(5)),
                                      ),
                                      child: Icon(
                                        Icons.add,
                                        size: 12,
                                        color: ThemeColor.get(context)
                                            .primaryAccent,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(width: 8),
                            Text(
                              vnd.format(topping.retailCost ?? 0) + ' đ',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[700],
                              ),
                            ),
                            SizedBox(width: 12),
                            InkWell(
                              onTap: () {
                                setState(() {
                                  widget.item.toppings!.removeWhere(
                                      (element) => element.id == topping.id);
                                });
                                widget.updatePaid();
                              },
                              child: Icon(
                                Icons.close,
                                size: 14,
                                color: Colors.redAccent,
                              ),
                            )
                          ],
                        ),
                      )),
                ],
              ),
            ),
          ],
          8.verticalSpace,

          // Total price display
          Row(
            children: [
              Spacer(),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(vertical: 3, horizontal: 8),
                    decoration: BoxDecoration(
                      color: ThemeColor.get(context)
                          .primaryAccent
                          .withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      Icons.payments,
                      color: ThemeColor.get(context).primaryAccent,
                      size: 16,
                    ),
                  ),
                  SizedBox(width: 8),
                  Text.rich(
                    TextSpan(
                      text: 'Tổng tiền: ',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                      children: <TextSpan>[
                        TextSpan(
                          text: vndCurrency.format(widget.getPrice()),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: ThemeColor.get(context).primaryAccent,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          4.verticalSpace,
          Divider(),
          4.verticalSpace,
        ],
      ),
    );
  }
}
