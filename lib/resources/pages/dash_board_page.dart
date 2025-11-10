import 'package:draggable_fab/draggable_fab.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/app/models/user.dart';
import 'package:flutter_app/app/utils/dashboard.dart';
import 'package:flutter_app/app/utils/formatters.dart';
import 'package:flutter_app/bootstrap/helpers.dart';
import 'package:flutter_app/config/constant.dart';
import 'package:flutter_app/resources/pages/report/report_page.dart';
import 'package:flutter_app/resources/themes/styles/color_styles.dart';
import 'package:flutter_app/resources/widgets/gradient_appbar.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:flutter_svg/svg.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:nylo_framework/nylo_framework.dart';
import 'package:url_launcher/url_launcher.dart';

class DashboardPage extends StatefulWidget {
  static const path = '/dashboard_page';

  const DashboardPage({Key? key}) : super(key: key);

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage>
    with SingleTickerProviderStateMixin {
  User get user => Auth.user<User>()!;
  @override
  Widget build(BuildContext context) {
    var shortestSide = MediaQuery.of(context).size.shortestSide;
    ScreenUtil.init(context);
    return Scaffold(
      appBar: GradientAppBar(
        title: Text(
          'Bate - Quản lý nhà hàng',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
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
      body: Stack(
        children: [
          Container(
            height: 105,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                  colors: [Color(0xff179A6E), Color(0xff34B362)]),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(90),
                bottomRight: Radius.circular(90),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  buildInfoCard(),
                  Expanded(
                    child: ListView(
                      children: [
                        buildOrderButtons(),
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
          ),
        ],
      ),
    );
  }

  Widget buildInfoCard() {
    return Container(
      width: 1.sw,
      padding: const EdgeInsets.all(20),
      margin: EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            offset: const Offset(0, 1),
            blurRadius: 30,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Xin chào: ${user.name}',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            Divider(
              color: HexColor.fromHex('#EAEAEA'),
              height: 12,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          IconsaxPlusLinear.chart_1,
                          size: 24,
                          color: Color(0xffE28B00),
                        ),
                        SizedBox(
                          width: 10,
                        ),
                        Text(
                          'Doanh số hôm nay',
                          style: TextStyle(
                            color: Color(0xff5C5C5C),
                            fontSize: 18,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(
                      height: 10,
                    ),
                    Text(vnd.format(1000000 ?? 0).replaceAll('.', ','),
                        style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                            color: ThemeColor.get(context).primaryAccent))
                  ],
                ),
                IconButton(
                    onPressed: () {
                      routeTo(ReportPage.path);
                    },
                    icon: Icon(Icons.arrow_forward_ios,
                        size: 16, color: ThemeColor.get(context).primaryAccent))
              ],
            ),
            Divider(
              color: HexColor.fromHex('#EAEAEA'),
              height: 3,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tuần này',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w400,
                          color: Color(0xff5C5C5C)),
                    ),
                    Text(
                      vnd.format(74390000).replaceAll('.', ','),
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tháng này',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w400,
                          color: Color(0xff5C5C5C)),
                    ),
                    Text(
                      vnd.format(348960005000).replaceAll('.', ','),
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black),
                    ),
                  ],
                )
              ],
            )
          ]),
    );
  }

  Widget buildOrderButtons() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: IntrinsicHeight(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 9,
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () {
                    // routeTo(AddStoragePage.path);
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xff028175), Color(0xff35B562)],
                      ),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0xff0D9A6F).withOpacity(0.20),
                          blurRadius: 18,
                          spreadRadius: 0,
                          offset: Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(IconsaxPlusLinear.import_1,
                            size: 24, color: Colors.white),
                        SizedBox(height: 6),
                        Text(
                          'Nhập',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 19,
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () {
                    // routeTo(ManageTablePage.path);
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 40),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xff028175), Color(0xff35B562)],
                      ),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0xff0D9A6F).withOpacity(0.20),
                          blurRadius: 18,
                          spreadRadius: 0,
                          offset: Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SvgPicture.asset(
                          getImageAsset('svg/table.svg'),
                          width: 30,
                          height: 30,
                          colorFilter:
                              ColorFilter.mode(Colors.white, BlendMode.srcIn),
                        ),
                        Flexible(
                          child: Text(
                            "Xem bàn",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            )
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
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
