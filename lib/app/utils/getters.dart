Map<String, String?> extractHeaderFromDescription(String description) {
  try {
    final lines = description.split('\n');
    String? headerTitle;
    String? roomNumber;
    List<String> contentLines = [];
    bool foundHeader = false;

    for (String line in lines) {
      line = line.trim();
      if (line.isEmpty) continue;

      if (line.startsWith('Đặt món từ bàn:')) {
        headerTitle = line;
        foundHeader = true;

        final regex = RegExp(r'Đặt món từ bàn:\s*(\d+)');
        final match = regex.firstMatch(line);
        if (match != null) {
          roomNumber = match.group(1);
        }
      } else if (foundHeader) {
        contentLines.add(line);
      } else {
        contentLines.add(line);
      }
    }

    return {
      'title': headerTitle,
      'roomNumber': roomNumber,
      'cleanContent': contentLines.join('\n'),
    };
  } catch (e) {
    return {
      'title': null,
      'roomNumber': null,
      'cleanContent': description,
    };
  }
}
