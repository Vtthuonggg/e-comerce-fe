import 'dart:async';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app/bootstrap/app.dart';
import 'package:flutter_app/bootstrap/boot.dart';
import 'package:flutter_app/config/common_define.dart';
import 'package:flutter_app/config/storage_keys.dart';
import 'package:flutter_app/login_page.dart';
import 'package:flutter_app/resources/pages/main_page.dart';
import 'package:flutter_app/resources/themes/styles/light_theme_colors.dart';

import 'package:intl/date_symbol_data_local.dart';
import 'package:nylo_framework/nylo_framework.dart';

void main() async {
  Nylo.init();
  Nylo nylo = await Nylo.init(setup: Boot.nylo, setupFinished: Boot.finished);

  initializeDateFormatting('vi_VN').then((_) => runApp(AppBuild(
        navigatorKey: NyNavigator.instance.router.navigatorKey,
        onGenerateRoute: nylo.router!.generator(),
        debugShowCheckedModeBanner: false,
        initialRoute: SplashScreen.path,
        themeData: ThemeData(
          dialogTheme: DialogTheme(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            shadowColor: Colors.black.withOpacity(0.1),
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            titleTextStyle: TextStyle(
              color: Colors.black87,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
            contentTextStyle: TextStyle(
              color: Colors.black87,
              fontSize: 16,
              fontWeight: FontWeight.w400,
            ),
            actionsPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
          textSelectionTheme: TextSelectionThemeData(
            selectionColor: Colors.grey.shade400.withOpacity(0.3),
            selectionHandleColor: Colors.grey.shade600,
            cursorColor: Colors.grey.shade700,
          ),
          brightness: Brightness.light,
          primarySwatch: createColor(LightThemeColors().primaryAccent),
          inputDecorationTheme: InputDecorationTheme(
            contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 0),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                width: 1.0,
              ),
            ),
          ),
          segmentedButtonTheme: SegmentedButtonThemeData(
            style: ButtonStyle(
              backgroundColor: MaterialStateProperty.resolveWith<Color>(
                (Set<MaterialState> states) {
                  if (states.contains(MaterialState.selected)) {
                    return createColor(LightThemeColors().primaryAccent);
                  }

                  return Colors.white;
                },
              ),
              foregroundColor: MaterialStateProperty.resolveWith<Color>(
                (Set<MaterialState> states) {
                  if (states.contains(MaterialState.selected)) {
                    return Colors.white;
                  }

                  return createColor(LightThemeColors().primaryAccent);
                },
              ),
              overlayColor: MaterialStateProperty.all<Color>(
                Colors.white.withOpacity(.1),
              ),
              shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              side: MaterialStateProperty.all<BorderSide>(
                BorderSide(
                  color: createColor(LightThemeColors().primaryAccent),
                ),
              ),
            ),
          ),
          datePickerTheme: DatePickerThemeData(
            backgroundColor: Colors.white,
            headerBackgroundColor:
                createColor(LightThemeColors().primaryAccent),
            headerForegroundColor: Colors.white,
            weekdayStyle: TextStyle(color: Colors.black87),
            dayStyle: TextStyle(color: Colors.black87),
            yearStyle: TextStyle(color: Colors.black87),
            dayForegroundColor: MaterialStateProperty.resolveWith<Color?>(
              (Set<MaterialState> states) {
                if (states.contains(MaterialState.selected)) {
                  return Colors.white;
                }
                if (states.contains(MaterialState.hovered)) {
                  return createColor(LightThemeColors().primaryAccent);
                }
                return Colors.black87;
              },
            ),
            dayBackgroundColor: MaterialStateProperty.resolveWith<Color?>(
              (Set<MaterialState> states) {
                if (states.contains(MaterialState.selected)) {
                  return createColor(LightThemeColors().primaryAccent);
                }
                return Colors.white;
              },
            ),
            todayBackgroundColor: MaterialStateProperty.resolveWith<Color?>(
              (Set<MaterialState> states) {
                if (states.contains(MaterialState.selected)) {
                  return createColor(LightThemeColors().primaryAccent);
                }
                return Colors.white;
              },
            ),
            todayForegroundColor: MaterialStateProperty.resolveWith<Color?>(
              (Set<MaterialState> states) {
                if (states.contains(MaterialState.selected)) {
                  return Colors.white;
                }
                return createColor(LightThemeColors().primaryAccent);
              },
            ),
            todayBorder: BorderSide(
              color: createColor(LightThemeColors().primaryAccent),
              width: 1,
            ),
            surfaceTintColor: Colors.transparent,
          ),
          timePickerTheme: TimePickerThemeData(
            backgroundColor: Colors.white,
            dialBackgroundColor: Colors.grey.shade50,
            hourMinuteColor: MaterialStateColor.resolveWith((states) {
              if (states.contains(MaterialState.selected)) {
                return Colors.blue.shade100;
              }
              return Colors.grey.shade100;
            }),
            hourMinuteTextColor: MaterialStateColor.resolveWith((states) {
              if (states.contains(MaterialState.selected)) {
                return Colors.blue.shade700;
              }
              return Colors.grey.shade800;
            }),
            dayPeriodColor: MaterialStateColor.resolveWith((states) {
              if (states.contains(MaterialState.selected)) {
                return Colors.blue.shade100;
              }
              return Colors.grey.shade100;
            }),
            dayPeriodTextColor: MaterialStateColor.resolveWith((states) {
              if (states.contains(MaterialState.selected)) {
                return Colors.blue.shade700;
              }
              return Colors.grey.shade800;
            }),
            dialHandColor: Colors.blue.shade600,
            dialTextColor: Colors.black87,
            entryModeIconColor: Colors.blue.shade600,
            helpTextStyle: TextStyle(color: Colors.grey.shade700),
            hourMinuteTextStyle: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w600,
            ),
            dayPeriodTextStyle: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          colorScheme: ColorScheme.light(
            primary: createColor(LightThemeColors().primaryAccent),
            onPrimary: Colors.white,
            secondary:
                createColor(LightThemeColors().primaryAccent).withOpacity(0.2),
            onSecondary: Colors.white,
            surface: Colors.white,
            onSurface: Colors.black87,
            surfaceVariant: Colors.white,
            outline: Colors.grey.shade300,
            primaryContainer: Colors.white,
            onPrimaryContainer: Colors.black87,
            background: Colors.white,
            onBackground: Colors.black87,
          ),
          floatingActionButtonTheme: FloatingActionButtonThemeData(
            backgroundColor: Colors.grey.shade600,
            foregroundColor: Colors.white,
          ),
          switchTheme: SwitchThemeData(
            thumbColor: MaterialStateProperty.resolveWith<Color>(
              (Set<MaterialState> states) {
                if (states.contains(MaterialState.selected)) {
                  return createColor(LightThemeColors().primaryAccent);
                }
                return Colors.white;
              },
            ),
            trackColor: MaterialStateProperty.resolveWith<Color>(
              (Set<MaterialState> states) {
                if (states.contains(MaterialState.selected)) {
                  return createColor(LightThemeColors().primaryAccent)
                      .withOpacity(0.3);
                }
                return Colors.grey.shade300;
              },
            ),
          ),
          checkboxTheme: CheckboxThemeData(
            fillColor: MaterialStateProperty.resolveWith<Color>(
              (Set<MaterialState> states) {
                if (states.contains(MaterialState.selected)) {
                  return Colors.grey.shade600;
                }
                return Colors.transparent;
              },
            ),
            checkColor: MaterialStateProperty.all(Colors.white),
          ),
          radioTheme: RadioThemeData(
            fillColor: MaterialStateProperty.resolveWith<Color>(
              (Set<MaterialState> states) {
                if (states.contains(MaterialState.selected)) {
                  return Colors.grey.shade600;
                }
                return Colors.grey.shade400;
              },
            ),
          ),
          appBarTheme: AppBarTheme(
            backgroundColor: createColor(LightThemeColors().primaryAccent),
            foregroundColor: Colors.white,
          ),
        ),
      )));
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  static const path = '/splash_screen';
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkUserToken();
  }

  void _checkUserToken() async {
    String? userToken = await NyStorage.read(StorageKey.userToken);
    if (userToken != null) {
      routeTo(MainPage.path, navigationType: NavigationType.pushReplace);
    } else {
      routeTo(LoginPage.path, navigationType: NavigationType.pushReplace);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Transform.scale(
              scale: 0.5, child: Image.asset('public/assets/images/bate.png')),
          CircularProgressIndicator(
            color: Colors.blue,
          )
        ],
      ),
    );
  }
}
