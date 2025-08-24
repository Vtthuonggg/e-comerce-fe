import 'package:draggable_fab/draggable_fab.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/app/utils/dashboard.dart';
import 'package:flutter_app/bootstrap/helpers.dart';
import 'package:flutter_app/config/constant.dart';
import 'package:flutter_app/resources/widgets/gradient_appbar.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:nylo_framework/nylo_framework.dart';
import 'package:url_launcher/url_launcher.dart';

class DashboardPage extends StatefulWidget {
  static const path = '/dashboard_page';

  const DashboardPage({Key? key}) : super(key: key);

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  @override
  Widget build(BuildContext context) {
    var shortestSide = MediaQuery.of(context).size.shortestSide;
    ScreenUtil.init(context);
    return Scaffold(
      appBar: GradientAppBar(
          title: Text(
        'Bate - Quản lý nhà hàng',
        style: TextStyle(fontWeight: FontWeight.bold),
      )),
      floatingActionButton: DraggableFab(
        securityBottom: 60,
        child: SpeedDial(
            backgroundColor: Colors.white.withOpacity(0.8),
            foregroundColor: ThemeColor.get(context).primaryAccent,
            spacing: 20,
            spaceBetweenChildren: 10,
            icon: Icons.support_agent,
            activeIcon: Icons.close,
            buttonSize: Size(70, 70),
            children: [
              SpeedDialChild(
                  // add bulkd
                  child: Image.asset(
                    getImageAsset('ic_messenger.png'),
                    width: 20,
                    height: 20,
                  ),
                  label: 'Messenger',
                  onTap: () {
                    _launchMessengerURL();
                  }),
              SpeedDialChild(
                  child: Image.asset(
                    getImageAsset('ic_zalo.png'),
                    width: 20,
                    height: 20,
                  ),
                  label: 'Zalo',
                  onTap: () {
                    _launchZaloURL();
                  }),
              SpeedDialChild(
                  child: Icon(
                    Icons.call,
                    color: Colors.green,
                    size: 20,
                  ),
                  label: 'Call',
                  onTap: () {
                    _launchCallURL();
                  }),
            ]),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                children: [
                  GridView.count(
                      physics: NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      crossAxisCount: shortestSide < 600 ? 3 : 5,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 1,
                      padding: EdgeInsets.all(14),
                      children: [
                        ...getDashboardItems().map((item) {
                          return buildItem(
                            item.icon,
                            item.name,
                            onTab: () {
                              if (item.routePath != null) {
                                routeTo(item.routePath!);
                              }
                            },
                          );
                        }).toList(),
                      ]),
                  // _buildBottomBarView(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildItem(dynamic iconData, String title,
      {Function()? onTab, bool isFlip = false}) {
    return Container(
      padding: EdgeInsets.all(8.0),
      decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.8),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: ThemeColor.get(context).primaryAccent.withOpacity(0.5))),
      child: InkWell(
        onTap: onTab,
        child: Container(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Transform.flip(
                flipX: isFlip,
                child: Icon(
                  iconData,
                  size: 40,
                  color: ThemeColor.get(context).primaryAccent,
                ),
              ),
              SizedBox(height: 4),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF5C5E5D),
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  _launchMessengerURL() async {
    final Uri url = Uri.parse(MESSENGER_SUPPORT_URL);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }

  _launchZaloURL() async {
    final Uri url = Uri.parse(ZALO_SUPPORT_URL);
    if (!await launchUrl(
      url,
      mode: LaunchMode.externalApplication,
    )) {
      throw Exception('Could not launch $url');
    }
  }

  _launchCallURL() async {
    final Uri url = Uri.parse('tel:$HOT_LINE');
    if (!await launchUrl(url)) {
      throw Exception('Could not launch $url');
    }
  }
}
