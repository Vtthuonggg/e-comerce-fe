import 'package:collection/collection.dart';
import 'package:currency_text_input_formatter/currency_text_input_formatter.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app/app/models/Ingredient.dart';
import 'package:flutter_app/app/models/category.dart';
import 'package:flutter_app/app/models/product.dart';
import 'package:flutter_app/app/utils/formatters.dart';
import 'package:flutter_app/bootstrap/helpers.dart';
import 'package:flutter_app/resources/pages/custom_toast.dart';
import 'package:flutter_app/resources/widgets/single_tap_detector.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:form_builder_validators/form_builder_validators.dart';

enum CostType {
  retail,
  wholesale,
  base,
  another,
}

extension CostTypeExtension on CostType {
  static num getCost(Ingredient item, CostType costType) {
    switch (costType) {
      case CostType.retail:
        return item.retailCost ?? 0;
      case CostType.base:
        return item.baseCost ?? 0;
      case CostType.another:
        return 1;
      default:
        return 0;
    }
  }
}

class OrderIngredientItem extends StatelessWidget {
  final Ingredient item;
  final int index;
  int? currentPolicy;
  final CostType costType;
  final Function() updatePaid;
  final Function(String?)? updateQuantity;
  final Function(Ingredient) removeItem;
  final Function() onMinusQuantity;
  final Function() getPrice;
  final Function(String?) onChangeQuantity;
  final Function() onIncreaseQuantity;
  final Function(String?) onChangePrice;
  final Function(String?) onChangeDiscount;
  final Function(DiscountType?) onChangeDiscountType;
  void Function(String)? onVATChange = null;
  List<CategoryModel>? categories = [];
  Map<String, bool> featuresConfig = {};
  OrderIngredientItem({
    super.key,
    required this.item,
    required this.index,
    required this.removeItem,
    required this.updatePaid,
    required this.costType,
    required this.onMinusQuantity,
    required this.getPrice,
    required this.onChangeQuantity,
    required this.onIncreaseQuantity,
    required this.onChangePrice,
    required this.onChangeDiscount,
    required this.onChangeDiscountType,
    this.onVATChange,
    this.categories,
    this.featuresConfig = const {},
    this.updateQuantity,
    this.currentPolicy,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  "${index + 1}. ${item.name ?? ''} ",
                  maxLines: 2,
                  // overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontWeight: FontWeight.bold, overflow: TextOverflow.fade),
                ),
              ),
              InkWell(
                onTap: () {
                  removeItem(item);
                },
                child: Icon(Icons.delete_outline,
                    size: 25, color: ThemeColor.get(context).primaryAccent),
              ),
            ],
          ),
          6.verticalSpace,
          Row(
            children: [
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
                        onTap: () {
                          onMinusQuantity();
                        },
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
                          child: FormBuilderTextField(
                            onTapOutside: (value) {
                              FocusScope.of(context).unfocus();
                            },
                            key: item.quantityKey,
                            name: '${item.id}.quantity',
                            initialValue: roundQuantity(item.quantity ?? 0),
                            onChanged: (value) {
                              onChangeQuantity(value);
                            },
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: ThemeColor.get(context).primaryAccent,
                            ),
                            keyboardType: TextInputType.numberWithOptions(
                                signed: true, decimal: true),
                            validator: FormBuilderValidators.compose([]),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'^\d+\.?\d{0,3}'),
                              ),
                            ],
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              contentPadding:
                                  EdgeInsets.symmetric(vertical: 10),
                              floatingLabelBehavior:
                                  FloatingLabelBehavior.never,
                              hintText: '0',
                              hintStyle: TextStyle(color: Colors.grey[400]),
                            ),
                          ),
                        ),
                      ),

                      // Plus button
                      InkWell(
                        onTap: () {
                          onIncreaseQuantity();
                        },
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
              Expanded(
                child: Container(
                  height: 40,
                  // height: 36,
                  child: FormBuilderTextField(
                    onTapOutside: (value) {
                      FocusScope.of(context).unfocus();
                    },
                    readOnly: costType == CostType.base,
                    key: item.priceKey,
                    name: '${item.id}.price',
                    controller: item.txtPrice,
                    onChanged: (value) {
                      onChangePrice(value);
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
                      disabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      floatingLabelBehavior: FloatingLabelBehavior.never,
                      suffixText: 'đ',
                      hintText: '0',
                    ),
                  ),
                ),
              ),
              8.horizontalSpace,
              if (costType == CostType.base ||
                  featuresConfig['product_discount'] == true)
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Expanded(
                          child: SizedBox(
                        height: 40,
                        child: FormBuilderTextField(
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          onTapOutside: (value) {
                            FocusScope.of(context).unfocus();
                          },
                          key: item.discountKey,
                          textAlign: TextAlign.right,
                          initialValue: (item.discount ?? 0) != 0
                              ? (item.discountType == DiscountType.percent
                                  ? roundQuantity(item.discount ?? 0)
                                  : vnd.format(
                                      (item.discount ?? 0) / item.quantity))
                              : '',
                          name: '${item.id}.discount',
                          onChanged: (value) {
                            onChangeDiscount(value);
                          },
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.bold),
                          keyboardType: TextInputType.number,
                          inputFormatters:
                              item.discountType == DiscountType.percent
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
                                onChangeDiscountType(value);
                              },
                              children: {
                                DiscountType.percent: Container(
                                  child: Text('%',
                                      style: TextStyle(
                                          // color: Colors.white
                                          fontWeight: FontWeight.bold,
                                          color: item.discountType ==
                                                  DiscountType.percent
                                              ? Colors.white
                                              : Colors.black)),
                                ),
                                DiscountType.price: Container(
                                  child: Text('đ',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          // color: Colors.white
                                          color: item.discountType ==
                                                  DiscountType.price
                                              ? Colors.white
                                              : Colors.black)),
                                )
                              },
                              groupValue: item.discountType,
                            ),
                            // icon: Icon(Icons.contact_page),
                            floatingLabelBehavior: FloatingLabelBehavior.never,
                            hintText: '0',
                            suffixText:
                                item.discountType == DiscountType.percent
                                    ? ''
                                    : '',
                          ),
                        ),
                      )),
                    ],
                  ),
                ),
              // Spacer(),
            ],
          ),
          4.verticalSpace,
          Row(
            children: [if (costType == CostType.base) buildVAT(context)],
          ),
          if (featuresConfig['select_category'] == true ||
              featuresConfig['input_size'] == true ||
              featuresConfig['vat'] == true) ...[
            8.verticalSpace,
            SizedBox(
              height: 40,
              width: double.infinity,
              child: Row(
                children: [
                  if (featuresConfig['vat'] == true) buildVAT(context),
                ],
              ),
            ),
            8.verticalSpace,
          ],
          if (featuresConfig['order_form'] == true) buildNoteProduct(context),
          8.verticalSpace,
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
                          text: costType == CostType.base
                              ? '${vndCurrency.format(getPrice())}'
                              : vndCurrency.format(getPrice()),
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

  Widget buildNoteProduct(context) {
    return FormBuilderTextField(
      name: '${item.id}.note',
      initialValue: item.productNote,
      cursorColor: ThemeColor.get(context).primaryAccent,
      onChanged: (value) {
        item.productNote = value ?? '';
      },
      keyboardType: TextInputType.streetAddress,
      decoration: InputDecoration(
        labelText: 'Nhập ghi chú',
        labelStyle: TextStyle(color: Colors.grey[700]),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: ThemeColor.get(context).primaryAccent,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  Widget buildVAT(BuildContext context) {
    return Expanded(
      child: FormBuilderTextField(
        name: '${item.id}.vat',
        controller: item.txtVAT,
        onTapOutside: (value) {
          FocusScope.of(context).unfocus();
        },
        enabled: false,
        key: item.vatKey,
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.allow(
            RegExp(r'^\d+\.?\d{0,2}'),
          ),
        ],
        textAlign: TextAlign.right,
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        onChanged: (value) {
          if (value != null) {
            double? parsedValue = double.tryParse(value);
            if (parsedValue != null && parsedValue > 100) {
              CustomToast.showToastError(context,
                  description: "Thuế VAT không được lớn hơn 100%");

              Future.delayed(Duration(milliseconds: 100), () {
                item.txtVAT.text = '100';
                item.txtVAT.selection = TextSelection.fromPosition(
                    TextPosition(offset: item.txtVAT.text.length));
              });
              return;
            }
            onVATChange!(value);
          }
        },
        decoration: InputDecoration(
          suffixText: '%',
          labelText: 'VAT',
          labelStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget buildCateContainer(ctx, popupWidget) {
    return Container(
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20), topRight: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.09),
                  offset: const Offset(0, -13),
                  blurRadius: 31)
            ]),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Stack(
              children: [
                Align(
                    alignment: Alignment.center,
                    child: Container(
                      margin: EdgeInsets.all(16),
                      child: Text(
                        'Chọn danh mục',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                    )),
                Positioned(
                  right: 0,
                  child: IconButton(
                    icon: Icon(
                      Icons.close,
                      size: 30,
                    ),
                    onPressed: () {
                      Navigator.of(ctx).pop();
                    },
                  ),
                )
              ],
            ),
            Flexible(
              child: Container(
                child: popupWidget,
              ),
            ),
            SizedBox(
              height: 16,
            )
          ],
        ));
  }

  Widget buildPopupCategory(
      BuildContext context, CategoryModel cate, bool isSelected) {
    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 0),
      leading: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Icon(
            FontAwesomeIcons.shapes,
            size: 30,
            color: ThemeColor.get(context).primaryAccent,
          ),
        ],
      ),
      title: Text("${cate.name}"),
    );
  }

  CategoryModel? getSelectedCategory() {
    if (categories == null) {
      return null;
    }

    final found = categories!
        .firstWhereOrNull((element) => element.id == item.categoryId);

    return found;
  }
}
