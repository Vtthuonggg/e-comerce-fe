import 'package:flutter/material.dart';
import 'package:flutter_app/app/networking/room_api_service.dart';
import 'package:flutter_app/app/utils/message.dart';
import 'package:flutter_app/bootstrap/helpers.dart';
import 'package:flutter_app/resources/pages/custom_toast.dart';
import 'package:flutter_app/resources/pages/table/manage_table_page.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';

class EditTable extends StatefulWidget {
  List<Area> areas = [];
  int? initArea;
  dynamic editData;
  final VoidCallback refresh;

  EditTable(
      {super.key,
      required this.areas,
      this.initArea,
      this.editData,
      required this.refresh});

  @override
  State<EditTable> createState() => _EditTableState();
}

class _EditTableState extends State<EditTable> {
  GlobalKey<FormBuilderState> _formState = GlobalKey<FormBuilderState>();

  bool get _isEdit => widget.editData != null;
  bool _loading = false;

  Future<void> _submit() async {
    final formState = _formState.currentState;
    if (!formState!.saveAndValidate()) {
      return;
    }

    setState(() {
      _loading = true;
    });
    try {
      if (_isEdit) {
        await api<RoomApiService>((request) =>
            request.updateRoom(widget.editData['id'], formState.value));

        Navigator.pop(context, true);
        CustomToast.showToastSuccess(context,
            description: 'Cập nhật thành công');
      } else {
        await api<RoomApiService>(
            (request) => request.createRoom(formState.value));

        Navigator.pop(context, true);
        CustomToast.showToastSuccess(context, description: 'Thêm thành công');
      }

      widget.refresh();
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
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        top: 20,
        left: 20,
        right: 20,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
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
                  color: _isEdit ? Colors.orange[50] : Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _isEdit ? Icons.edit_outlined : Icons.add_outlined,
                  color: _isEdit ? Colors.orange[600] : Colors.green[600],
                  size: 20,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  _isEdit ? 'Chỉnh sửa bàn' : 'Thêm bàn mới',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey[900],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 24),

          // Form
          FormBuilder(
            key: _formState,
            child: Container(
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
                    'Thông tin bàn',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                    ),
                  ),
                  SizedBox(height: 16),

                  // Area Dropdown
                  FormBuilderDropdown(
                    name: 'area_id',
                    initialValue: widget.initArea,
                    decoration: InputDecoration(
                      labelText: 'Khu vực',
                      labelStyle: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 14,
                      ),
                      prefixIcon: Icon(Icons.location_on_outlined,
                          color: Colors.grey[500]),
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
                    ),
                    items: widget.areas
                        .map((area) => DropdownMenuItem(
                              value: area.id,
                              child: Text(area.name),
                            ))
                        .toList(),
                  ),
                  SizedBox(height: 16),

                  // Table Name Field
                  FormBuilderTextField(
                    keyboardType: TextInputType.streetAddress,
                    name: 'name',
                    initialValue: _isEdit ? widget.editData['name'] : '',
                    cursorColor: Colors.blue[600],
                    onTapOutside: (event) {
                      FocusScope.of(context).unfocus();
                    },
                    decoration: InputDecoration(
                      labelText: 'Tên bàn',
                      labelStyle: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 14,
                      ),
                      hintText: 'Nhập tên bàn',
                      prefixIcon: Icon(Icons.table_restaurant_outlined,
                          color: Colors.grey[500]),
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
                    ),
                    validator: FormBuilderValidators.compose([
                      FormBuilderValidators.required(
                          errorText: 'Vui lòng nhập tên bàn'),
                    ]),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 24),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  icon: Icon(Icons.close, color: Colors.white, size: 18),
                  label: Text(
                    "Hủy",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[600],
                    padding: EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _loading
                      ? null
                      : () {
                          _submit();
                        },
                  icon: _loading
                      ? SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Icon(
                          _isEdit ? Icons.save_outlined : Icons.add_outlined,
                          color: Colors.white,
                          size: 18,
                        ),
                  label: Text(
                    _isEdit ? "Cập nhật" : "Thêm bàn",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        _isEdit ? Colors.orange[600] : Colors.green[600],
                    padding: EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
