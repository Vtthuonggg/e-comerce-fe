import 'dart:async';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app/app/controllers/controller.dart';
import 'package:flutter_app/app/networking/category_api.dart';
import 'package:flutter_app/app/utils/formatters.dart';
import 'package:flutter_app/resources/pages/order/edit_order_page.dart';
import 'package:flutter_app/resources/widgets/app_loading.dart';
import 'package:flutter_app/resources/widgets/single_tap_detector.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_app/app/models/category.dart';
import 'package:flutter_app/app/models/product.dart';
import 'package:flutter_app/app/networking/product_api.dart';
import 'package:flutter_app/app/utils/message.dart';
import 'package:flutter_app/bootstrap/helpers.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:nylo_framework/nylo_framework.dart';

class SelectMultiProductPage extends NyStatefulWidget {
  final controller = Controller();
  static const path = '/select-multi-product';
  SelectMultiProductPage({super.key});

  @override
  NyState<SelectMultiProductPage> createState() =>
      _SelectMultiProductPageState();
}

class _SelectMultiProductPageState extends NyState<SelectMultiProductPage> {
  final PagingController<int, Product> _pagingController =
      PagingController(firstPageKey: 1);
  final GlobalKey<FormBuilderState> _formKey = GlobalKey<FormBuilderState>();
  final TextEditingController searchController = TextEditingController();

  List<CategoryModel> lstCate = [];
  CategoryModel? selectedCate;
  List<Product> selectedItems = [];
  List<Product> originalSelectedItems = [];
  List<Product> initItems = [];
  Map<int, num> initialQuantities = {};

  Timer? _debounce;
  int _pageSize = 20;
  String searchQuery = '';
  bool isSearchMode = false;
  bool _isLoading = false;
  OverlayEntry? _overlayEntry;

  String get roomName => widget.data()?['room_name'] ?? '';
  String get areaName => widget.data()?['area_name'] ?? '';
  int? get roomId => widget.data()?['room_id'];
  String? get roomType => widget.data()?['room_type'];
  bool get isEditing => widget.data()?['items'] != null;

  @override
  void initState() {
    super.initState();

    if (isEditing) {
      final tempItems = widget.data()?['items'] as List<Product>;
      List<Product> items = tempItems.map((item) {
        item.isSelected = true;
        return item;
      }).toList();
      selectedItems.addAll(items);
      originalSelectedItems = List.from(selectedItems);
      initItems = tempItems;
      initItems.forEach((item) {
        initialQuantities[item.id!] = item.quantity;
        item.txtQuantity.text = roundQuantity(item.quantity);
      });
      selectedItems.forEach((item) {
        item.txtQuantity.text = roundQuantity(item.quantity);
        _formKey.currentState?.fields['${item.id}.quantity']
            ?.didChange(roundQuantity(item.quantity));
      });
    }

    _fetchCate();
    _pagingController.addPageRequestListener((pageKey) {
      _fetchProducts(pageKey);
    });
  }

  @override
  void dispose() {
    _pagingController.dispose();
    _debounce?.cancel();
    searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchCate() async {
    try {
      var res = await api<CategoryApiService>(
          (request) => request.listCategory('', 1, 100));
      List<CategoryModel> newItems = [];
      res["data"].forEach((item) {
        newItems.add(CategoryModel.fromJson(item));
      });
      lstCate = [];
      var highlightCate = CategoryModel();
      highlightCate.name = 'Nổi bật';
      highlightCate.id = null;
      lstCate.add(highlightCate);
      lstCate.addAll(newItems);
      setState(() {});
    } catch (error) {
      showToastWarning(description: error.toString());
    }
  }

  Future<void> _fetchProducts(int pageKey) async {
    try {
      Map<String, dynamic> response =
          await api<ProductApiService>((request) => request.listProduct(
                searchQuery,
                pageKey,
                _pageSize,
                categoryId: selectedCate?.id,
              ));
      List<Product> products = [];
      response["data"].forEach((item) {
        products.add(Product.fromJson(item));
      });

      // Sync với selectedItems
      final selectedItemsMap = {for (var item in selectedItems) item.id: item};
      for (var product in products) {
        final selectedItem = selectedItemsMap[product.id];
        if (selectedItem != null) {
          product.isSelected = true;
          product.txtQuantity.text = roundQuantity(selectedItem.quantity);
          product.quantity = selectedItem.quantity;
          product.retailCost = selectedItem.retailCost;
        }
      }

      final isLastPage = products.length < _pageSize;
      if (isLastPage) {
        _pagingController.appendLastPage(products);
      } else {
        final nextPageKey = pageKey + 1;
        _pagingController.appendPage(products, nextPageKey);
      }
    } catch (error) {
      log(error.toString());
      _pagingController.error = error;
    }
  }

  void _syncSelectedItems(Product item) {
    final index = selectedItems.indexWhere((element) => element.id == item.id);
    if (index != -1) {
      selectedItems[index].quantity = item.quantity;
    } else if (item.isSelected) {
      selectedItems.add(item);
    }
  }

  void _debounceSearch() {
    if (_debounce?.isActive ?? false) {
      _debounce?.cancel();
    }
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _pagingController.refresh();
    });
  }

  void removeItem(Product item) {
    item.isSelected = false;
    item.quantity = 1;
    _formKey.currentState?.fields['${item.id}.quantity']
        ?.didChange(roundQuantity(item.quantity));
    selectedItems.removeWhere((element) => element.id == item.id);
    setState(() {});
  }

  num totalQuantity() {
    num total = 0;
    for (var item in selectedItems) {
      total += item.quantity;
    }
    return total;
  }

  void runAddToCartAnimation(GlobalKey imageKey, String? imageUrl) async {
    if (_overlayEntry != null) {
      _overlayEntry?.remove();
      _overlayEntry = null;
    }

    final renderBox = imageKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final startPosition = renderBox.localToGlobal(Offset.zero);
    final imageSize = renderBox.size;
    final screenSize = MediaQuery.of(context).size;
    final endPosition = Offset(
      screenSize.width - 60,
      screenSize.height - 70,
    );
    final overlay = Overlay.of(context);

    final animImage = Stack(
      children: [
        AnimatedAddToCartImage(
          imageUrl: imageUrl ?? '',
          startPosition: startPosition,
          endPosition: endPosition,
          size: imageSize,
          onCompleted: () {
            _overlayEntry?.remove();
            _overlayEntry = null;
          },
        ),
      ],
    );

    _overlayEntry = OverlayEntry(builder: (context) => animImage);
    overlay.insert(_overlayEntry!);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: ThemeColor.get(context).primaryAccent,
        title: isSearchMode
            ? TextFormField(
                controller: searchController,
                autofocus: true,
                onChanged: (value) {
                  searchQuery = value;
                  _debounceSearch();
                },
                cursorColor: Colors.white,
                decoration: InputDecoration(
                  contentPadding:
                      EdgeInsets.symmetric(vertical: 5, horizontal: 15),
                  hintText: 'Tìm kiếm...',
                  hintStyle: TextStyle(color: Colors.white70),
                  border: OutlineInputBorder(
                    borderSide: BorderSide.none,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  fillColor: Colors.white.withOpacity(0.2),
                  filled: true,
                  suffixIcon: searchQuery.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear, color: Colors.white),
                          onPressed: () {
                            setState(() {
                              searchController.clear();
                              searchQuery = '';
                            });
                            _debounceSearch();
                          },
                        )
                      : null,
                ),
                style: TextStyle(color: Colors.white),
              )
            : Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: areaName,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    TextSpan(
                      text: roomName.isNotEmpty ? ': $roomName' : '',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
        leading: IconButton(
          icon: Icon(isSearchMode ? Icons.arrow_back_ios_new : Icons.close,
              color: Colors.white),
          onPressed: () {
            if (isSearchMode) {
              setState(() {
                isSearchMode = false;
                searchQuery = '';
                _pagingController.refresh();
              });
            } else {
              if (isEditing) {
                selectedItems = List.from(originalSelectedItems);
                for (var item in selectedItems) {
                  if (initialQuantities.containsKey(item.id)) {
                    item.quantity = initialQuantities[item.id]!;
                    item.txtQuantity.text = roundQuantity(item.quantity);
                  }
                }
                Navigator.of(context).pop(selectedItems);
              } else {
                Navigator.of(context).pop();
              }
            }
          },
        ),
        actions: [
          if (!isSearchMode)
            IconButton(
              icon: Icon(Icons.search, color: Colors.white),
              onPressed: () {
                setState(() {
                  isSearchMode = true;
                });
              },
            ),
          if (!isSearchMode)
            Padding(
              padding: const EdgeInsets.only(right: 10.0),
              child: IconButton(
                icon: Icon(Icons.add, color: Colors.white),
                onPressed: () {
                  // TODO: Add product
                },
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: FormBuilder(
          key: _formKey,
          child: Column(
            children: [
              buildHeader(),
              SizedBox(height: 5),
              Expanded(
                child: RefreshIndicator(
                  color: ThemeColor.get(context).primaryAccent,
                  onRefresh: () =>
                      Future.sync(() => _pagingController.refresh()),
                  child: PagedListView<int, Product>(
                    pagingController: _pagingController,
                    builderDelegate: PagedChildBuilderDelegate<Product>(
                      firstPageErrorIndicatorBuilder: (context) => Center(
                          child:
                              Text(getResponseError(_pagingController.error))),
                      newPageErrorIndicatorBuilder: (context) => Center(
                          child:
                              Text(getResponseError(_pagingController.error))),
                      firstPageProgressIndicatorBuilder: (context) =>
                          Center(child: AppLoading()),
                      newPageProgressIndicatorBuilder: (context) =>
                          Center(child: AppLoading()),
                      noItemsFoundIndicatorBuilder: (_) => const Center(
                          child: Text("Không tìm thấy sản phẩm nào")),
                      itemBuilder: (context, product, index) =>
                          buildProductItem(context, product),
                    ),
                  ),
                ),
              ),
              if (selectedItems.isNotEmpty) buildBottomActions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildHeader() {
    return Container(
      width: 1.sw,
      clipBehavior: Clip.none,
      margin: EdgeInsets.only(right: 16, left: 16, top: 6, bottom: 6),
      child: SingleChildScrollView(
        clipBehavior: Clip.none,
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            ...lstCate.map((e) => buildCateItem(e, context)).toList(),
          ],
        ),
      ),
    );
  }

  Widget buildCateItem(CategoryModel cate, BuildContext context) {
    final bool isSelected = cate.id == selectedCate?.id;
    return SingleTapDetector(
      onTap: () {
        selectedCate = cate;
        _pagingController.refresh();
        setState(() {});
      },
      child: AnimatedContainer(
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
                      color: ThemeColor.get(context)
                          .primaryAccent
                          .withOpacity(0.18),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                      spreadRadius: 2),
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
      ),
    );
  }

  Widget buildProductItem(BuildContext context, Product product) {
    final GlobalKey imageKey = GlobalKey();
    return SingleTapDetector(
      onTap: () {
        if (product.isSelected != true) {
          selectedItems.add(product);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            runAddToCartAnimation(imageKey, product.image);
          });
        }
        product.isSelected = true;
        setState(() {});
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 0.09.sh,
                  height: 0.09.sh,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8.0),
                    child: product.image != null
                        ? FadeInImage(
                            key: imageKey,
                            placeholder:
                                AssetImage(getImageAsset('placeholder.png')),
                            fit: BoxFit.cover,
                            image: NetworkImage(product.image!),
                            imageErrorBuilder: (context, error, stackTrace) {
                              return Icon(Icons.image,
                                  color: Colors.grey, size: 30);
                            },
                          )
                        : Icon(Icons.image, color: Colors.grey, size: 30),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Container(
                    height: 0.09.sh,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Flexible(
                          child: Text(
                            product.name ?? '',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              vnd.format(product.retailCost ?? 0),
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.grey[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            product.isSelected
                                ? buildSelectQuantity(
                                    product, context, imageKey)
                                : SizedBox(height: 40),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Divider(color: Colors.grey[300]),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildSelectQuantity(
      Product product, BuildContext context, GlobalKey imageKey) {
    return SizedBox(
      height: 40,
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              if (product.quantity > 1) {
                product.quantity--;
                product.txtQuantity.text = roundQuantity(product.quantity);
              } else {
                removeItem(product);
              }
              _syncSelectedItems(product);
              setState(() {});
            },
            icon: Icon(Icons.remove),
          ),
          Container(
            width: 0.12.sw,
            height: 40,
            alignment: Alignment.center,
            child: FormBuilderTextField(
              key: Key('${product.id}'),
              name: '${product.id}.quantity',
              textAlign: TextAlign.center,
              controller: product.txtQuantity,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
              decoration: InputDecoration(
                hintText: '0',
                contentPadding: EdgeInsets.only(bottom: 10),
                border: InputBorder.none,
              ),
              onChanged: (value) {
                product.quantity = stringToDouble(value) ?? 0;
                _syncSelectedItems(product);
                setState(() {});
              },
              keyboardType: TextInputType.number,
              onTapOutside: (event) {
                if (product.quantity == 0) {
                  removeItem(product);
                  product.txtQuantity.text = roundQuantity(product.quantity);
                }
                FocusScope.of(context).unfocus();
              },
              onEditingComplete: () {
                if (product.quantity == 0) {
                  removeItem(product);
                  product.txtQuantity.text = roundQuantity(product.quantity);
                }
                FocusScope.of(context).unfocus();
              },
              inputFormatters: [
                FilteringTextInputFormatter.allow(
                  RegExp(r'^\d+\.?\d{0,3}'),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              product.quantity++;
              product.txtQuantity.text = roundQuantity(product.quantity);
              _syncSelectedItems(product);
              setState(() {});
            },
            icon: Icon(Icons.add),
          ),
        ],
      ),
    );
  }

  Widget buildBottomActions() {
    return Container(
      margin: EdgeInsets.only(top: 5, bottom: 10, left: 16, right: 16),
      child: Row(
        children: [
          Expanded(
            child: TextButton(
              onPressed: () {
                if (isEditing) {
                  selectedItems = List.from(originalSelectedItems);

                  final itemList = _pagingController.itemList ?? [];
                  for (var item in itemList) {
                    final isSelected = selectedItems
                        .any((selectedItem) => selectedItem.id == item.id);
                    item.isSelected = isSelected;

                    if (isSelected) {
                      final selectedItem = selectedItems.firstWhere(
                          (selectedItem) => selectedItem.id == item.id);
                      item.quantity = selectedItem.quantity;
                      item.txtQuantity.text = selectedItem.txtQuantity.text;
                    } else {
                      item.quantity = 1;
                      item.txtQuantity.text = '1';
                    }
                  }
                } else {
                  List<Product> itemsToRemove = List.from(selectedItems);
                  itemsToRemove.forEach((item) {
                    removeItem(item);
                  });
                  for (var item in _pagingController.itemList ?? []) {
                    item.isSelected = false;
                    item.quantity = 1;
                    item.txtQuantity.text = roundQuantity(item.quantity);
                  }
                }
                setState(() {});
              },
              style: TextButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                backgroundColor: Colors.grey[100],
                foregroundColor: Colors.black,
              ),
              child: Text(
                'Chọn lại',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: TextButton(
              onPressed: () {
                if (isEditing) {
                  Navigator.of(context).pop(selectedItems);
                } else {
                  routeTo(EditOrderPage.path, data: {
                    'selected_products': selectedItems,
                    'room_name': roomName,
                    'area_name': areaName,
                    'room_id': roomId,
                    'room_type': roomType,
                  }, onPop: (value) {
                    if (value != null) {
                      selectedItems = value as List<Product>;
                      for (var item in selectedItems) {
                        item.txtQuantity.text = roundQuantity(item.quantity);
                      }
                    }
                    _pagingController.refresh();
                    setState(() {});
                  });
                }
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                backgroundColor: ThemeColor.get(context).primaryAccent,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Thêm vào đơn',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Container(
                    constraints: BoxConstraints(maxWidth: 60),
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: Color.alphaBlend(Colors.black.withOpacity(0.2),
                          ThemeColor.get(context).primaryAccent),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Text(
                      roundQuantity(totalQuantity()),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AnimatedAddToCartImage extends StatefulWidget {
  final String imageUrl;
  final Offset startPosition;
  final Offset endPosition;
  final Size size;
  final VoidCallback onCompleted;

  const AnimatedAddToCartImage({
    required this.imageUrl,
    required this.startPosition,
    required this.endPosition,
    required this.size,
    required this.onCompleted,
    Key? key,
  }) : super(key: key);

  @override
  _AnimatedAddToCartImageState createState() => _AnimatedAddToCartImageState();
}

class _AnimatedAddToCartImageState extends State<AnimatedAddToCartImage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _position;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        duration: const Duration(milliseconds: 700), vsync: this);

    _position = Tween<Offset>(
      begin: widget.startPosition,
      end: widget.endPosition,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _scale = Tween<double>(begin: 1.0, end: 0.3)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    _controller.forward().whenComplete(() {
      if (mounted) {
        widget.onCompleted();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => Positioned(
        left: _position.value.dx,
        top: _position.value.dy,
        child: Transform.scale(
          scale: _scale.value,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8.0),
            child: SizedBox(
              width: widget.size.width,
              height: widget.size.height,
              child: widget.imageUrl.isNotEmpty
                  ? Image.network(
                      widget.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Image.asset(
                          getImageAsset('placeholder.png'),
                          fit: BoxFit.cover,
                        );
                      },
                    )
                  : Image.asset(
                      getImageAsset('placeholder.png'),
                      fit: BoxFit.cover,
                    ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
