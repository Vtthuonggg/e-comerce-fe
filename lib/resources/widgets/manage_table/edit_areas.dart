import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_app/app/networking/room_api_service.dart';
import 'package:flutter_app/app/utils/message.dart';
import 'package:flutter_app/bootstrap/helpers.dart';
import 'package:flutter_app/resources/pages/custom_toast.dart';
import 'package:flutter_app/resources/pages/table/manage_table_page.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class EditAreas extends StatefulWidget {
  final List<Area> areas;
  final VoidCallback refresh;

  const EditAreas({
    super.key,
    required this.areas,
    required this.refresh,
  });

  @override
  State<EditAreas> createState() => _EditAreasState();
}

class _EditAreasState extends State<EditAreas> {
  final _textController = TextEditingController();

  bool _isSaving = false;

  List<Area> _areas = [];
  String searchQuery = "";
  dynamic selectedEmployee = [];
  @override
  void initState() {
    super.initState();
    _areas = widget.areas;
  }

  Future _save() async {
    if (_isSaving) {
      return;
    }

    if (_textController.text.isEmpty) {
      CustomToast.showToastError(context,
          description: 'Vui lòng nhập tên khu vực');
      return;
    }

    setState(() {
      _isSaving = true;
    });
    dynamic payload = {
      'name': _textController.text,
    };
    try {
      final created =
          await api<RoomApiService>((request) => request.createArea(payload));
      Area newArea = Area(
        name: _textController.text,
        rooms: [],
        id: created['data']['id'],
      );

      _areas.add(newArea);
      CustomToast.showToastSuccess(context, description: 'Lưu thành công');

      _textController.text = '';
      selectedEmployee = [];

      widget.refresh();
    } catch (e) {
      log(e.toString());
      CustomToast.showToastError(context, description: getResponseError(e));
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  Future _removeArea(int id) async {
    try {
      await api<RoomApiService>((request) => request.deleteArea(id: id));

      _areas.removeWhere((element) => element.id == id);

      CustomToast.showToastSuccess(context, description: 'Xóa thành công');

      setState(() {});
      widget.refresh();
    } catch (e) {
      CustomToast.showToastError(context,
          description: 'Khu vực đang có bàn hoạt động nên không được xóa.');
    }
  }

  @override
  Widget build(BuildContext context) {
    ScreenUtil.init(context);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.location_on_outlined,
                    color: Colors.blue[600],
                    size: 20,
                  ),
                ),
                SizedBox(width: 12),
                Text(
                  'Quản lý khu vực',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey[900],
                  ),
                ),
              ],
            ),
            SizedBox(height: 24),

            // Form section
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tạo khu vực mới',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                    ),
                  ),
                  SizedBox(height: 16),
                  TextFormField(
                    controller: _textController,
                    onTapOutside: (event) {
                      FocusScope.of(context).unfocus();
                    },
                    cursorColor: Colors.blue[600],
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide:
                            BorderSide(color: Colors.blue[500]!, width: 2),
                      ),
                      labelText: 'Tên khu vực',
                      labelStyle: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[700],
                      ),
                      hintText: 'Ví dụ: Tầng 1, Khu A...',
                      prefixIcon:
                          Icon(Icons.edit_outlined, color: Colors.grey[500]),
                    ),
                  ),
                  SizedBox(height: 16),
                  SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[600],
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                      onPressed: _isSaving ? null : _save,
                      child: _isSaving
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Text('Đang tạo...'),
                              ],
                            )
                          : Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.add_location_outlined, size: 18),
                                SizedBox(width: 8),
                                Text(
                                  'Tạo khu vực',
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 24),

            // Existing areas section
            if (_areas.isNotEmpty) ...[
              Text(
                'Khu vực hiện có',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
              SizedBox(height: 12),
              _buildListArea(),
            ],

            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget buildEmployee(employee, context, setState) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: employee.isSelected ? Colors.blue[50] : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: employee.isSelected ? Colors.blue[200]! : Colors.grey[200]!,
        ),
      ),
      child: ListTile(
        onTap: () {
          setState(() {
            if (selectedEmployee.contains(employee.id)) {
              selectedEmployee.remove(employee.id);
              employee.isSelected = false;
            } else {
              selectedEmployee.add(employee.id);
              employee.isSelected = true;
            }
          });
        },
        leading: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: employee.isSelected ? Colors.blue[100] : Colors.grey[100],
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(
            Icons.person,
            color: employee.isSelected ? Colors.blue[600] : Colors.grey[600],
            size: 20,
          ),
        ),
        title: Text(
          employee.name.length > 25
              ? employee.name.substring(0, 25) + '...'
              : employee.name,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: employee.isSelected ? Colors.blue[700] : Colors.grey[800],
          ),
        ),
        trailing: Container(
          padding: EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: employee.isSelected ? Colors.blue[600] : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Icon(
            employee.isSelected ? Icons.check : Icons.add,
            color: employee.isSelected ? Colors.white : Colors.grey[500],
            size: 18,
          ),
        ),
      ),
    );
  }

  Widget _areaItemChip(Area area) {
    return Container(
      margin: EdgeInsets.only(bottom: 8, right: 8),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.location_on_outlined,
              size: 16,
              color: Colors.blue[600],
            ),
            SizedBox(width: 6),
            Text(
              area.name,
              style: TextStyle(
                color: Colors.blue[700],
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
            SizedBox(width: 8),
            GestureDetector(
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    title: Row(
                      children: [
                        Icon(Icons.warning_amber, color: Colors.orange[600]),
                        SizedBox(width: 8),
                        Text(
                          'Xóa khu vực',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    content: Text(
                      'Bạn có chắc chắn muốn xóa khu vực "${area.name}" không?',
                      style: TextStyle(fontSize: 14),
                    ),
                    actions: [
                      TextButton(
                        style: TextButton.styleFrom(
                          padding:
                              EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                            side: BorderSide(color: Colors.grey[300]!),
                          ),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: Text(
                          'Hủy',
                          style: TextStyle(color: Colors.grey[700]),
                        ),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red[600],
                          foregroundColor: Colors.white,
                          padding:
                              EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                          elevation: 0,
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          _removeArea(area.id);
                        },
                        child: Text(
                          'Xóa',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                );
              },
              child: Container(
                padding: EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.red[100],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.close,
                  size: 14,
                  color: Colors.red[600],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListArea() {
    if (_areas.isEmpty) {
      return Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Column(
          children: [
            Icon(
              Icons.location_off_outlined,
              color: Colors.grey[400],
              size: 32,
            ),
            SizedBox(height: 8),
            Text(
              'Chưa có khu vực nào',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _areas.map((area) => _areaItemChip(area)).toList(),
    );
  }
}
