import 'package:intl/intl.dart';

final vnd = new NumberFormat("#,##0", "vi_VN");

final vndCurrency = new NumberFormat.currency(locale: "vi_VN", symbol: "đ");

// format date
// from: 2023-07-10T03:44:11.000000Z
// to: 10/07/2023 10:44
String? formatDate(String? value) {
  if (value == null) return null;
  return DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(value).toLocal());
}

String? formatDateOnly(String? value) {
  if (value == null) return null;
  return DateFormat('dd/MM/yyyy').format(DateTime.parse(value).toLocal());
}

String? formatDateMonthTextOnly(String? value) {
  if (value == null) return null;
  return DateFormat('dd-MMM-yyyy', 'vi_VN')
      .format(DateTime.parse(value).toLocal());
}

// string to num
int? stringToInt(String? value) {
  if (value == null) return null;
  return int.tryParse(value.replaceAll(RegExp(r'[^0-9]'), ''));
}

// like string to num, but keep the decimal
double? stringToDouble(String? value) {
  if (value == null) return null;
  return double.tryParse(value);
}

String getPaymentTypeLabel(int type) {
  switch (type) {
    case 1:
      return "Tiền mặt";
    case 2:
      return "Chuyển khoản";
    case 3:
      return "Quẹt thẻ";
    default:
      return "Không xác định";
  }
}

RegExp phoneRegExp = new RegExp(r'^(84|0[3|5|7|8|9])+([0-9]{8})\b');
num concatenateIds(int variantId, int orderId) {
  return int.parse('$variantId$orderId');
}

num roundMoney(num value) {
  num wholeNumber = value.floor();
  num decimalPart = value - wholeNumber;
  if (decimalPart < 0.5) {
    return wholeNumber;
  } else {
    return wholeNumber + 1;
  }
}

String roundQuantity(num value) {
  return value
      .toStringAsFixed(3)
      .replaceAll(RegExp(r"0*$"), "")
      .replaceAll(RegExp(r"\.$"), "");
}

String prefixHttps(String url) {
  if (!url.startsWith('http://') && !url.startsWith('https://')) {
    return 'https://' + url;
  }
  return url;
}

String removeHttpPrefix(String url) {
  if (!url.startsWith('http://') && !url.startsWith('https://')) {
    return url;
  }
  return url.substring(url.indexOf('://') + 3);
}

bool isValidDomain(String domain) {
  // Regular expression to match valid domain patterns
  RegExp regex = RegExp(r'^[a-zA-Z0-9-]+(\.[a-zA-Z0-9-]+)*(\.[a-zA-Z]{2,})$');

  // Check if the domain matches the regular expression
  return regex.hasMatch(domain);
}
