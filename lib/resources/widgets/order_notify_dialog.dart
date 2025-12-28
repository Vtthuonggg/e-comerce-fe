import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_app/app/utils/getters.dart';

class OrderNotificationDialog extends StatefulWidget {
  final String description;
  final Map<String, dynamic> orderData;
  final VoidCallback onTap;

  const OrderNotificationDialog({
    Key? key,
    required this.description,
    required this.orderData,
    required this.onTap,
  }) : super(key: key);

  @override
  _OrderNotificationDialogState createState() =>
      _OrderNotificationDialogState();
}

class _OrderNotificationDialogState extends State<OrderNotificationDialog> {
  Timer? _autoCloseTimer;

  @override
  void initState() {
    super.initState();
    _autoCloseTimer = Timer(Duration(seconds: 5), () {
      _closeDialog();
    });
  }

  @override
  void dispose() {
    _autoCloseTimer?.cancel();
    super.dispose();
  }

  void _closeDialog() {
    if (mounted && Navigator.of(context).canPop()) {
      try {
        Navigator.of(context).pop();
      } catch (e) {}
    }
  }

  void _handleTap() {
    _autoCloseTimer?.cancel();
    if (mounted) {
      Navigator.of(context).pop();
      widget.onTap();
    }
  }

  void _handleClose() {
    _autoCloseTimer?.cancel();
    _closeDialog();
  }

  @override
  Widget build(BuildContext context) {
    final roomId = widget.orderData['roomId'];
    final description = widget.description;
    final headerInfo = extractHeaderFromDescription(description);

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isTablet = screenWidth >= 600;
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    double getDialogWidth() {
      if (isTablet && isLandscape) {
        return (screenWidth * 0.4).clamp(300.0, 500.0);
      } else if (isTablet) {
        return (screenWidth * 0.6).clamp(300.0, 400.0);
      } else {
        return screenWidth * 0.67;
      }
    }

    return Align(
      alignment: Alignment.topRight,
      child: Padding(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 16,
          left: 16,
          right: 16,
        ),
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: getDialogWidth(),
            constraints: BoxConstraints(
              maxHeight: screenHeight * (isTablet ? 0.4 : 0.4),
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFD7816A),
                  Color(0xFFBD4F6C),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Color(0xFFD7816A).withOpacity(0.25),
                  blurRadius: 12,
                  spreadRadius: 0,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: InkWell(
              onTap: _handleTap,
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: EdgeInsets.all(isTablet ? 20 : 14),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(isTablet ? 12 : 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Icon(
                            Icons.restaurant_menu,
                            color: Colors.white,
                            size: isTablet ? 24 : 18,
                          ),
                        ),
                        SizedBox(width: isTablet ? 12 : 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                headerInfo['title'] ?? 'Đơn hàng mới',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize:
                                      isTablet ? 18 : 14, // Giảm font size
                                  letterSpacing: 0.3,
                                ),
                              ),
                              SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.access_time,
                                    color: Colors.white.withOpacity(0.8),
                                    size: isTablet ? 14 : 10,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    _formatTimestamp(),
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.8),
                                      fontSize:
                                          isTablet ? 14 : 10, // Giảm font size
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: InkWell(
                            onTap: _handleClose,
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: EdgeInsets.all(isTablet ? 10 : 6),
                              child: Icon(
                                Icons.close,
                                color: Colors.white.withOpacity(0.9),
                                size: isTablet ? 20 : 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: isTablet ? 16 : 12),
                    Flexible(
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(isTablet ? 18 : 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.06),
                              blurRadius: 8,
                              spreadRadius: 0,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ..._buildDescriptionContent(
                                  headerInfo['cleanContent'] ?? description),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: isTablet ? 14 : 10),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(isTablet ? 14 : 10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Icon(
                              Icons.touch_app,
                              color: Colors.white,
                              size: isTablet ? 16 : 12,
                            ),
                          ),
                          SizedBox(width: isTablet ? 10 : 6),
                          Expanded(
                            child: Text(
                              'Nhấn để xem chi tiết bàn ${headerInfo['roomNumber'] ?? roomId ?? ''}',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: isTablet ? 14 : 11,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.1,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios,
                            color: Colors.white.withOpacity(0.7),
                            size: isTablet ? 14 : 10,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem(String itemLine) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 600;

    try {
      String cleanLine = itemLine.substring(1).trim();
      List<String> parts = cleanLine.split(' - Ghi chú: ');
      String itemName = parts[0];
      String? note = parts.length > 1 ? parts[1] : null;

      return Container(
        padding: EdgeInsets.all(isTablet ? 14 : 12),
        decoration: BoxDecoration(
          color: Color(0xFFF7FAFC),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: Color(0xFFE2E8F0),
            width: 0.8,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: isTablet ? 8 : 6,
                  height: isTablet ? 8 : 6,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                    ),
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    itemName,
                    style: TextStyle(
                      color: Color(0xFF2D3748),
                      fontSize: isTablet ? 15 : 14,
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
            if (note != null && note.isNotEmpty) ...[
              SizedBox(height: 8),
              Container(
                padding: EdgeInsets.symmetric(
                  vertical: isTablet ? 8 : 6,
                  horizontal: isTablet ? 12 : 10,
                ),
                decoration: BoxDecoration(
                  color: Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: Color(0xFFD1D5DB),
                    width: 0.5,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.sticky_note_2,
                      color: Color(0xFF6B7280),
                      size: isTablet ? 16 : 14,
                    ),
                    SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Ghi chú: $note',
                        style: TextStyle(
                          color: Color(0xFF4B5563),
                          fontSize: isTablet ? 13 : 12,
                          fontWeight: FontWeight.w500,
                          fontStyle: FontStyle.italic,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      );
    } catch (e) {
      return Container(
        padding: EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Color(0xFFF7FAFC),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Text(
              '• ',
              style: TextStyle(
                color: Color(0xFF667eea),
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            Expanded(
              child: Text(
                itemLine.substring(1).trim(),
                style: TextStyle(
                  color: Color(0xFF4A5568),
                  fontSize: 13,
                  height: 1.3,
                ),
              ),
            ),
          ],
        ),
      );
    }
  }

  List<Widget> _buildDescriptionContent(String description) {
    List<Widget> widgets = [];

    try {
      final lines = description.split('\n');

      for (String line in lines) {
        line = line.trim();
        if (line.isEmpty) continue;

        if (line.startsWith('Đặt món từ bàn:')) {
          continue;
        } else if (line.startsWith('-')) {
          widgets.add(_buildMenuItem(line));
          widgets.add(SizedBox(height: 8));
        } else {
          widgets.add(
            Text(
              line,
              style: TextStyle(
                color: Color(0xFF4A5568),
                fontSize: 13,
                height: 1.4,
              ),
            ),
          );
          widgets.add(SizedBox(height: 6));
        }
      }

      if (widgets.isEmpty) {
        widgets.add(
          Center(
            child: Text(
              'Không có thông tin chi tiết',
              style: TextStyle(
                color: Color(0xFF9CA3AF),
                fontSize: 13,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        );
      }
    } catch (e) {
      widgets.add(
        Text(
          description,
          style: TextStyle(
            color: Color(0xFF4A5568),
            fontSize: 13,
            height: 1.4,
          ),
        ),
      );
    }

    return widgets;
  }

  String _formatTimestamp() {
    final now = DateTime.now();
    return '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')} hôm nay';
  }
}
