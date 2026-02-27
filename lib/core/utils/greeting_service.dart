class GreetingService {
  final Map<String, List<String>> _templates = {
    'Gia đình': [
      "Chúc ông bà bách niên giai lão, sống lâu trăm tuổi cùng con cháu!",
      "Chúc bố mẹ năm mới dồi dào sức khỏe, luôn tươi trẻ và hạnh phúc.",
      "Chúc anh chị năm mới vạn sự như ý, tỷ sự như mơ, làm ăn phát đạt.",
      "Chúc cả nhà mình một năm mới an khang, thịnh vượng, tình cảm thêm gắn kết!",
    ],
    'Họ hàng': [
      "Chúc cô dì chú bác năm mới phát tài phát lộc, vạn sự hanh thông.",
      "Chúc gia đình mình năm mới an khang, may mắn đầy nhà, phúc lộc đầy tay.",
      "Chúc họ hàng ta một năm mới con cháu thảo hiền, gia đình đầm ấm.",
    ],
    'Bạn bè': [
      "Chúc mày năm mới sớm có người yêu, tiền vào như nước, tiền ra nhỏ giọt!",
      "Chúc bạn năm mới công việc ổn định, thăng quan tiến chức, vạn sự như ý.",
      "Chúc chúng ta một năm mới quẩy hết mình, vui hết nấc, tình bạn bền lâu!",
      "Năm mới chúc bạn vạn sự khởi đầu nan, gian nan đừng có nản, tiền bạc thì xông xênh!",
    ],
    'Đồng nghiệp': [
      "Chúc anh/chị năm mới KPI vượt chỉ tiêu, lương thưởng đầy túi!",
      "Chúc đồng nghiệp năm mới sự nghiệp thăng tiến, sếp quý đồng nghiệp thương.",
      "Chúc team mình năm mới dự án nào cũng thành công, đoàn kết là sức mạnh.",
      "Chúc sếp năm mới mã đáo thành công, đưa công ty ngày càng phát triển!",
    ],
  };

  List<String> getGreetings(String group) {
    return _templates[group] ?? ["Chúc mừng năm mới an khang thịnh vượng!"];
  }

  String generateRandomGreeting() {
    final all = _templates.values.expand((element) => element).toList();
    all.shuffle();
    return all.first;
  }
}
