import 'package:flutter/material.dart';
import 'package:flutter_app/app/networking/room_api_service.dart';
import 'package:flutter_app/app/utils/message.dart';
import 'package:flutter_app/bootstrap/helpers.dart';
import 'package:flutter_app/resources/pages/custom_toast.dart';
import 'package:flutter_app/resources/pages/table/manage_table_page.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';

class AddTableBulk extends StatefulWidget {
  List<Area> areas = [];
  final VoidCallback refresh;

  AddTableBulk({super.key, required this.areas, required this.refresh});

  @override
  State<AddTableBulk> createState() => _AddTableBulkState();
}

class _AddTableBulkState extends State<AddTableBulk> {
  GlobalKey<FormBuilderState> _formKey = GlobalKey<FormBuilderState>();

  final List<Widget> _rows = [];

  bool _loading = false;

  @override
  void initState() {
    super.initState();

    _rows.add(TableRow(
      areas: widget.areas,
      onTapDelete: () {},
      index: 0,
    ));

    _rows.add(TableRow(
      areas: widget.areas,
      onTapDelete: () {},
      index: 1,
    ));

    _rows.add(TableRow(
      areas: widget.areas,
      onTapDelete: () {},
      index: 2,
    ));
  }

  List<dynamic> _getListTable() {
    dynamic formValue = _formKey.currentState!.value;
    List<dynamic> listTable = [];

    _rows.forEach((element) {
      if (element is TableRow) {
        listTable.add({
          "area_id": formValue["area_${element.index}"],
          "name": formValue["name_${element.index}"] ?? "",
        });
      }
    });

    // filter all empty table name or empty area id
    return listTable
        .where((element) => element["name"] != "" && element["area_id"] != null)
        .toList();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.saveAndValidate()) return;
    final List<dynamic> listTable = _getListTable();
    if (listTable.length == 0) {
      CustomToast.showToastError(context,
          description: "Vui lòng nhập đủ thông tin!");
      return;
    }

    setState(() {
      _loading = true;
    });
    try {
      final items = await api<RoomApiService>(
          (request) => request.addTableBulk(listTable));
      CustomToast.showToastSuccess(context, description: "Thêm thành công");
      widget.refresh();
      Navigator.pop(context, items);
    } catch (e) {
      CustomToast.showToastError(context, description: getResponseError(e));
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: FormBuilder(
        key: _formKey,
        clearValueOnUnregister: true,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.table_restaurant,
                      color: Colors.green[700], size: 20),
                ),
                SizedBox(width: 12),
                Text(
                  "Thêm nhiều bàn mới",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey[900],
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),

            SizedBox(
              height: MediaQuery.of(context).size.height * 0.35,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    ..._rows.map((e) => e).toList(),
                  ],
                ),
              ),
            ),

            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                style: TextButton.styleFrom(
                  backgroundColor: Colors.blue[50],
                  foregroundColor: Colors.blue[700],
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: Icon(Icons.add, size: 18),
                label: Text(
                  "Thêm bàn",
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                onPressed: () {
                  setState(() {
                    _rows.add(TableRow(
                      areas: widget.areas,
                      onTapDelete: () {
                        setState(() {
                          _rows.removeLast();
                        });
                      },
                      index: _rows.length,
                    ));
                  });
                },
              ),
            ),
            SizedBox(height: 16),

            // Nút lưu và hủy
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red[600],
                      side: BorderSide(color: Colors.red[200]!),
                      padding: EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: Icon(Icons.close_rounded),
                    label: Text("Hủy"),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[600],
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: _loading
                        ? SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Icon(Icons.save_rounded),
                    label: Text("Lưu",
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    onPressed: _loading ? null : _submit,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class TableRow extends StatelessWidget {
  TableRow({
    super.key,
    required this.onTapDelete,
    required this.areas,
    required this.index,
  });

  final VoidCallback? onTapDelete;
  final List<Area> areas;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: FormBuilderTextField(
              keyboardType: TextInputType.name,
              name: "name_$index",
              cursorColor: Colors.grey[700],
              onTapOutside: (event) {
                FocusScope.of(context).requestFocus(FocusNode());
              },
              decoration: InputDecoration(
                prefixIcon: Icon(Icons.table_restaurant_outlined, size: 18),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: Colors.grey[600]!,
                    width: 1,
                  ),
                ),
                hintText: "Tên bàn",
                contentPadding:
                    EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              ),
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: FormBuilderDropdown(
              name: "area_$index",
              decoration: InputDecoration(
                prefixIcon: Icon(Icons.location_on_outlined, size: 18),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: Colors.grey[600]!,
                    width: 1,
                  ),
                ),
                hintText: "Khu vực",
                contentPadding:
                    EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              ),
              items: areas
                  .map((area) => DropdownMenuItem(
                        value: area.id,
                        child: Text(area.name),
                      ))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}
