/// Danh sách địa chỉ chi nhánh thực tế của các siêu thị/cửa hàng
class MarketBranches {
  static const Map<String, List<String>> branches = {
    'WinMart': [
      'WinMart Tràng Thi, 4B Tràng Thi, Hoàn Kiếm, Hà Nội',
      'WinMart Times City, 458 Minh Khai, Hai Bà Trưng, Hà Nội',
      'WinMart Royal City, 72A Nguyễn Trãi, Thanh Xuân, Hà Nội',
      'WinMart Mipec Long Biên, 2 Long Biên, Long Biên, Hà Nội',
      'WinMart Hòa Lạc, Khu CNC Hòa Lạc, Thạch Thất, Hà Nội',
    ],
    'Co.opmart': [
      'Co.opmart Hà Đông, 1 Trần Phú, Hà Đông, Hà Nội',
      'Co.opmart Hoàng Mai, 459 Trương Định, Hoàng Mai, Hà Nội',
    ],
    'Big C': [
      'Big C Thăng Long, Phạm Hùng, Nam Từ Liêm, Hà Nội',
      'Big C Mỹ Đình, Lê Đức Thọ, Nam Từ Liêm, Hà Nội',
      'Big C Long Biên, 216 Nguyễn Văn Cừ, Long Biên, Hà Nội',
    ],
    'Bách Hoá Xanh': [
      'Bách Hoá Xanh Hòa Lạc, Đại lộ Thăng Long, Hà Nội',
      'Bách Hoá Xanh Hà Đông, Quang Trung, Hà Đông, Hà Nội',
    ],
    'Chợ truyền thống': [
      'Chợ Đồng Xuân, Đồng Xuân, Hoàn Kiếm, Hà Nội',
      'Chợ Bưởi, Bưởi, Tây Hồ, Hà Nội',
      'Chợ Hà Đông, Nguyễn Trãi, Hà Đông, Hà Nội',
    ],
  };

  /// Trả về danh sách địa chỉ theo tên chợ, fallback về tên chợ nếu không có
  static List<String> getBranches(String marketName) {
    // Tìm key khớp (không phân biệt hoa thường)
    for (final key in branches.keys) {
      if (marketName.toLowerCase().contains(key.toLowerCase()) ||
          key.toLowerCase().contains(marketName.toLowerCase())) {
        return branches[key]!;
      }
    }
    // Fallback: chỉ dùng tên chợ làm search query
    return [marketName];
  }
}
