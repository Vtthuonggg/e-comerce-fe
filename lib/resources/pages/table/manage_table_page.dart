import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_app/app/controllers/controller.dart';
import 'package:flutter_app/app/networking/room_api_service.dart';
import 'package:flutter_app/app/utils/message.dart';
import 'package:flutter_app/bootstrap/helpers.dart';
import 'package:flutter_app/resources/pages/table/table_item.dart';
import 'package:flutter_app/resources/widgets/app_loading.dart';
import 'package:flutter_app/resources/widgets/gradient_appbar.dart';
import 'package:flutter_app/resources/widgets/manage_table/add_table_bulk.dart';
import 'package:flutter_app/resources/widgets/manage_table/edit_areas.dart';
import 'package:flutter_app/resources/widgets/manage_table/edit_table.dart';
import 'package:flutter_app/resources/widgets/manage_table/table_area.dart';
import 'package:nylo_framework/nylo_framework.dart';

class ManageTablePage extends NyStatefulWidget {
  final Controller controller = Controller();

  static const path = '/manage-table';
  ManageTablePage({super.key});

  @override
  NyState<ManageTablePage> createState() => _ManageTablePageState();
}

class Area {
  final String name;
  final int id;
  final List<dynamic> rooms;

  Area({
    required this.name,
    required this.id,
    required this.rooms,
  });
}

class _ManageTablePageState extends NyState<ManageTablePage> {
  late Future<List<Area>> _areasFuture = _fetchAreas();
  String? filterRoomType;
  int? _selectedArea = -1;

  Future<List<Area>> _fetchAreas({String? search}) async {
    try {
      final areaRes =
          await api<RoomApiService>((request) => request.fetchAreas());
      final roomRes = await api<RoomApiService>(
          (request) => request.fetchRooms(search: search));
      log(roomRes.toString());
      return _mapResponseToArea(areaRes, roomRes);
    } catch (e) {
      log(e.toString());
      rethrow;
    }
  }

  List<Area> _mapResponseToArea(
    dynamic areaRes,
    dynamic roomRes,
  ) {
    List<Area> areas = [];
    List<dynamic> rooms = roomRes['data'];

    areaRes['data'].forEach((area) {
      var filteredRooms =
          rooms.where((room) => room['area']?['id'] == area['id']).toList();
      filteredRooms.sort((a, b) => a['id'].compareTo(b['id']));
      areas.add(Area(
        id: area['id'],
        name: area['name'],
        rooms: filteredRooms,
      ));
    });

    areas.sort((a, b) => a.id.compareTo(b.id));
    return areas;
  }

  Future _reloadAreas() async {
    setState(() {
      _areasFuture = _fetchAreas();
    });
  }

  List<dynamic> _filterAreas(List<Area> data, {String? type}) {
    List<Area> filteredAreas = data;

    if (type != null) {
      List<String> typesToFilter = type == TableStatus.using.toValue()
          ? [TableStatus.using.toValue(), TableStatus.preOrder.toValue()]
          : [type];
      filteredAreas = filteredAreas.map((area) {
        var filteredRooms = area.rooms
            .where((room) => typesToFilter.contains(room['type']))
            .toList();
        return Area(
          id: area.id,
          name: area.name,
          rooms: filteredRooms,
        );
      }).toList();
    }

    if (_selectedArea != -1) {
      filteredAreas =
          filteredAreas.where((e) => e.id == _selectedArea).toList();
    }

    return filteredAreas;
  }

  int _countRoomType(List<dynamic> data, String type) {
    int count = 0;

    data.forEach((area) {
      area.rooms.forEach((room) {
        if (room['type'] == type) {
          count++;
        }
      });
    });

    return count;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GradientAppBar(title: Text("Quản lý bàn")),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _reloadAreas,
          color: ThemeColor.get(context).primaryAccent,
          child: FutureBuilder(
              future: _areasFuture,
              builder: (context, snapshot) {
                switch (snapshot.connectionState) {
                  case ConnectionState.none:
                  case ConnectionState.waiting:
                    return Center(child: AppLoading());
                  case ConnectionState.active:
                  case ConnectionState.done:
                    if (snapshot.hasError) {
                      return Container(
                        child: Center(
                          child: Text(getResponseError(snapshot.error)),
                        ),
                      );
                    }
                    return Container(
                      child: Column(
                        children: [
                          buildHeader(snapshot.data),
                          buildListArea(snapshot.data ?? []),
                          SizedBox(
                            height: 5,
                          ),
                          Expanded(
                            child: SingleChildScrollView(
                              child: Column(
                                children: _filterAreas(snapshot.data ?? [],
                                        type: filterRoomType)
                                    .asMap()
                                    .entries
                                    .map<Widget>((entry) => TableArea(
                                          key: ValueKey(entry.value.id),
                                          area: entry.value,
                                          refresh: _reloadAreas,
                                          onTapEditTable: (table) {
                                            showEditTableDialog(
                                                snapshot.data ?? [], table);
                                          },
                                          onTapAddTable: () {
                                            showCreateTableDialog(
                                                snapshot.data ?? [],
                                                entry.value);
                                          },
                                          cancelTable: (table) {},
                                        ))
                                    .toList(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                }
              }),
        ),
      ),
    );
  }

  void showCreateTableDialog(List<Area> areas, Area initArea) async {
    await showModalBottomSheet(
        backgroundColor: Colors.transparent,
        useSafeArea: true,
        context: context,
        isScrollControlled: true,
        builder: (context) {
          return AddTableModal(
              areas: areas, initArea: initArea, refresh: _reloadAreas);
        });
  }

  void showEditTableDialog(List<Area> areas, dynamic table) async {
    await showModalBottomSheet(
        useSafeArea: true,
        backgroundColor: Colors.transparent,
        context: context,
        isScrollControlled: true,
        builder: (context) {
          return Container(
            padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(10.0),
                  topRight: Radius.circular(10.0),
                )),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: EditTable(
                areas: areas,
                initArea: table['area']?['id'] ?? -1,
                editData: table,
                refresh: _reloadAreas,
              ),
            ),
          );
        });

    _reloadAreas();
  }

  Widget buildListArea(List<Area> data, {String? type}) {
    final options = [
      Area(name: 'Tất cả', id: -1, rooms: []),
      ...data,
    ];

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      height: 44,
      child: Row(
        children: [
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: options.length,
              itemBuilder: (context, index) {
                final area = options[index];
                final isSelected = _selectedArea == area.id;
                return Container(
                  margin: EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedArea = area.id;
                      });
                    },
                    child: Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.blue[600] : Colors.grey[100],
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? Colors.blue[600]!
                              : Colors.grey[300]!,
                          width: 1,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          area.name,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? Colors.white : Colors.grey[700],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          GestureDetector(
            onTap: () {
              showCreateAreaDialog(data);
            },
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: Colors.blue[200]!, width: 1),
              ),
              child: Icon(
                Icons.add_rounded,
                color: Colors.blue[600],
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void showCreateAreaDialog(List<Area> data) async {
    await showModalBottomSheet(
        useSafeArea: true,
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) {
          return Container(
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(10.0),
                  topRight: Radius.circular(10.0),
                )),
            padding: MediaQuery.of(context).viewInsets,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: EditAreas(areas: data, refresh: _reloadAreas),
            ),
          );
        });
  }

  Widget buildHeader(dynamic data) {
    int countEmpty = _countRoomType(data, TableStatus.free.toValue());
    int countUsing = _countRoomType(data, TableStatus.using.toValue());
    int countPreOrder = _countRoomType(data, TableStatus.preOrder.toValue());
    countUsing += countPreOrder;
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: _buildHeaderCard(
              icon: Icons.home,
              title: "Tất cả",
              count: countUsing + countEmpty,
              isSelected: filterRoomType == null,
              color: Colors.blue[600]!,
              onTap: () {
                setState(() {
                  filterRoomType = null;
                });
              },
            ),
          ),
          SizedBox(width: 4),
          Expanded(
            child: _buildHeaderCard(
              icon: Icons.check_circle,
              title: "Trống",
              count: countEmpty,
              isSelected: filterRoomType == TableStatus.free.toValue(),
              color: Colors.green[600]!,
              onTap: () {
                setState(() {
                  filterRoomType = TableStatus.free.toValue();
                });
              },
            ),
          ),
          SizedBox(width: 4),
          Expanded(
            child: _buildHeaderCard(
              icon: Icons.schedule,
              title: "Sử dụng",
              count: countUsing,
              isSelected: filterRoomType == TableStatus.using.toValue(),
              color: Colors.red[600]!,
              onTap: () {
                setState(() {
                  filterRoomType = TableStatus.using.toValue();
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCard({
    required IconData icon,
    required String title,
    required int count,
    required bool isSelected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.grey[100],
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : color,
              size: 16,
            ),
            SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 11,
                      color: isSelected ? Colors.white : Colors.grey[600],
                    ),
                  ),
                  Text(
                    count.toString(),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? Colors.white : color,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AddTableModal extends StatefulWidget {
  final Area initArea;
  final List<Area> areas;
  final VoidCallback refresh;

  AddTableModal({
    super.key,
    required this.areas,
    required this.initArea,
    required this.refresh,
  });

  @override
  State<AddTableModal> createState() => _AddTableModalState();
}

class _AddTableModalState extends State<AddTableModal> {
  String _selectedMode = 'single'; // single, bulk

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
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.add_business_outlined,
                  color: Colors.green[600],
                  size: 20,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  "Tạo bàn mới",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey[900],
                  ),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(Icons.close, color: Colors.grey[600]),
              ),
            ],
          ),
          SizedBox(height: 24),

          // Mode Selection
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
                  'Chọn phương thức tạo bàn',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
                SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedMode = 'single';
                          });
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(
                              vertical: 12, horizontal: 16),
                          decoration: BoxDecoration(
                            color: _selectedMode == 'single'
                                ? Colors.blue[600]
                                : Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _selectedMode == 'single'
                                  ? Colors.blue[600]!
                                  : Colors.grey[300]!,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.table_restaurant_outlined,
                                color: _selectedMode == 'single'
                                    ? Colors.white
                                    : Colors.grey[600],
                                size: 18,
                              ),
                              SizedBox(width: 8),
                              Text(
                                "Tạo 1 bàn",
                                style: TextStyle(
                                  color: _selectedMode == 'single'
                                      ? Colors.white
                                      : Colors.grey[700],
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedMode = 'bulk';
                          });
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(
                              vertical: 12, horizontal: 16),
                          decoration: BoxDecoration(
                            color: _selectedMode == 'bulk'
                                ? Colors.purple[600]
                                : Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _selectedMode == 'bulk'
                                  ? Colors.purple[600]!
                                  : Colors.grey[300]!,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.dashboard_outlined,
                                color: _selectedMode == 'bulk'
                                    ? Colors.white
                                    : Colors.grey[600],
                                size: 18,
                              ),
                              SizedBox(width: 8),
                              Text(
                                "Tạo hàng loạt",
                                style: TextStyle(
                                  color: _selectedMode == 'bulk'
                                      ? Colors.white
                                      : Colors.grey[700],
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 16),

          if (_selectedMode == 'single')
            EditTable(
                areas: widget.areas,
                initArea: widget.initArea.id,
                refresh: widget.refresh),
          if (_selectedMode == 'bulk')
            AddTableBulk(areas: widget.areas, refresh: widget.refresh),
        ],
      ),
    );
  }
}

class AppBarWithSearch extends StatefulWidget implements PreferredSizeWidget {
  final Text title;
  final bool isMoveTable;
  final ValueChanged<String>? onChanged;
  final List<Widget>? customIcons; // Added parameter for custom icons
  final Function cancelMoveTable;
  AppBarWithSearch(
      {required this.title,
      this.onChanged,
      required this.cancelMoveTable,
      this.isMoveTable = false,
      this.customIcons}); // Updated constructor

  @override
  _AppBarWithSearchState createState() => _AppBarWithSearchState();

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);
}

class _AppBarWithSearchState extends State<AppBarWithSearch> {
  bool isSearchBarOpened = false;
  TextEditingController _textEditingController = TextEditingController();
  FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
  }

  void _closeSearch() {
    if (widget.onChanged != null) {
      if (_textEditingController.text.isNotEmpty) widget.onChanged!('');
    }

    setState(() {
      isSearchBarOpened = false;
      _textEditingController.clear();
    });
  }

  void _openSearch() {
    setState(() {
      isSearchBarOpened = true;
    });

    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> actions = [
      IconButton(
        icon: isSearchBarOpened ? Icon(Icons.close) : Icon(Icons.search),
        onPressed: () {
          if (isSearchBarOpened) {
            _closeSearch();
          } else {
            _openSearch();
          }
        },
      ),
    ];

    if (widget.customIcons != null) {
      actions.addAll(widget.customIcons!);
    }

    return AppBar(
      title: isSearchBarOpened
          ? TextFormField(
              focusNode: _focusNode,
              onFieldSubmitted: (value) {
                if (widget.onChanged != null) {
                  widget.onChanged!(value);
                }
              },
              cursorColor: ThemeColor.get(context).primaryAccent,
              textInputAction: TextInputAction.search,
              controller: _textEditingController,
              decoration: InputDecoration(
                hintText: 'Nhập sđt và tên...',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
              ),
            )
          : widget.title,
      leading: widget.isMoveTable
          ? IconButton(
              icon: Icon(Icons.close),
              onPressed: () {
                setState(() {
                  widget.cancelMoveTable();
                });
              },
            )
          : null,
      actions: actions, // Using the modified actions list
    );
  }
}
