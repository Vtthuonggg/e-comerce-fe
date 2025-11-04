import 'package:draggable_fab/draggable_fab.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_app/app/utils/dashboard.dart';
import 'package:flutter_app/bootstrap/helpers.dart';
import 'package:flutter_app/config/constant.dart';
import 'package:flutter_app/resources/widgets/gradient_appbar.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:iconsax/iconsax.dart';
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
            height: 105.h,
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
                  Container(
                    width: 1.sh,
                    height: 221.w,
                    padding: EdgeInsets.all(20.w),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 30,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Xin chào ${Auth.user()?.name}',
                          style: TextStyle(
                              color: Colors.black,
                              fontSize: 20,
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Container(
                        height: 113,
                        width: 116,
                        padding: EdgeInsets.symmetric(vertical: 16.w),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xff028175), Color(0xff35B562)],
                          ),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Color(0xff0D9A6F).withOpacity(0.35),
                              blurRadius: 30,
                              offset: Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Icon(Iconsax.import_2,
                                size: 30.w, color: Colors.white),
                            SizedBox(height: 8),
                            Text(
                              'Nhập',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Container(
                          height: 113,
                          padding: EdgeInsets.symmetric(
                              vertical: 20.w, horizontal: 40.w),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xff028175), Color(0xff35B562)],
                            ),
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: Color(0xff0D9A6F).withOpacity(0.35),
                                blurRadius: 30,
                                offset: Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Icon(Iconsax.export_3,
                                  size: 30.w, color: Colors.white),
                              Text(
                                'Bán hàng',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    ],
                  ),
                  SizedBox(height: 20),
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
          ),
        ],
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

class CurvedHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipPath(
          clipper: HeaderClipper(),
          child: Container(
            height: 180,
            color: const Color(0xFF00A86B), // màu xanh gradient hoặc 1 màu
          ),
        ),
        AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text("Ốc Cafe"),
          centerTitle: false,
        ),
      ],
    );
  }
}

class HeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.lineTo(0, size.height - 40);
    path.quadraticBezierTo(
        size.width / 2, size.height, size.width, size.height - 40);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
