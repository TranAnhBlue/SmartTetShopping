import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../domain/entities/lucky_money.dart';
import '../../providers/lucky_money_provider.dart';

class LuckyMoneyScreen extends StatefulWidget {
  const LuckyMoneyScreen({super.key});

  @override
  State<LuckyMoneyScreen> createState() => _LuckyMoneyScreenState();
}

class _LuckyMoneyScreenState extends State<LuckyMoneyScreen> {
  final currencyFormat = NumberFormat('#,###', 'vi_VN');

  @override
  void initState() {
    super.initState();
    final provider = context.read<LuckyMoneyProvider>();
    provider.loadLuckyMoney();
    provider.syncCloudToLocal();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Quản lý Lì xì 🧧"),
        actions: [
          IconButton(
            icon: const Icon(Icons.cloud_sync),
            tooltip: "Đồng bộ đám mây",
            onPressed: () async {
              final provider = context.read<LuckyMoneyProvider>();
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              scaffoldMessenger.showSnackBar(
                const SnackBar(content: Text("Đang đồng bộ Lì xì...")),
              );
              await provider.syncCloudToLocal();
              scaffoldMessenger.showSnackBar(
                const SnackBar(
                    content: Text("✅ Đã đồng bộ Lì xì!"),
                    backgroundColor: Colors.green),
              );
            },
          ),
        ],
        elevation: 0,
      ),
      body: Consumer<LuckyMoneyProvider>(
        builder: (context, provider, child) {
          return Column(
            children: [
              _buildSummaryHeader(provider),
              Expanded(
                child: provider.luckyMoneyList.isEmpty
                    ? _buildEmptyState()
                    : _buildLuckyMoneyList(provider),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddLuckyMoneyDialog(context),
        backgroundColor: Colors.red,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildSummaryHeader(LuckyMoneyProvider provider) {
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.redAccent, Colors.red],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatItem("Tổng ngân sách", 
                  "${currencyFormat.format(provider.totalBudget)}đ", Colors.white),
              const Icon(Icons.account_balance_wallet, color: Colors.white70),
            ],
          ),
          const Divider(color: Colors.white24, height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem("Đã chuẩn bị", 
                  "${currencyFormat.format(provider.preparedAmount)}đ", Colors.white),
              _buildStatItem("Đã tặng", 
                  "${currencyFormat.format(provider.gaveAmount)}đ", Colors.white),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: color.withOpacity(0.7), fontSize: 13)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.volunteer_activism, size: 80, color: Colors.red.withOpacity(0.3)),
          const SizedBox(height: 16),
          const Text("Chưa có danh sách lì xì nào", 
            style: TextStyle(color: Colors.grey, fontSize: 16)),
          const Text("Nhấn (+) để thêm người nhận", 
            style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildLuckyMoneyList(LuckyMoneyProvider provider) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: provider.luckyMoneyList.length,
      itemBuilder: (context, index) {
        final item = provider.luckyMoneyList[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              backgroundColor: _getGroupColor(item.group).withOpacity(0.2),
              child: Text(item.recipient[0], 
                style: TextStyle(color: _getGroupColor(item.group), fontWeight: FontWeight.bold)),
            ),
            title: Text(item.recipient, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("${currencyFormat.format(item.amount)}đ", 
                  style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _buildFlag(item.isPrepared == 1 ? "Đã chuẩn bị" : "Chưa chuẩn bị", 
                        item.isPrepared == 1 ? Colors.green : Colors.orange),
                    const SizedBox(width: 8),
                    if (item.isGave == 1)
                      _buildFlag("Đã tặng", Colors.blue),
                  ],
                ),
              ],
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') {
                  // TODO: Edit
                } else if (value == 'delete') {
                  provider.deleteLuckyMoney(item.id!);
                } else if (value == 'toggle_prepared') {
                  provider.updateLuckyMoney(item.copyWith(isPrepared: item.isPrepared == 1 ? 0 : 1));
                } else if (value == 'toggle_gave') {
                  provider.updateLuckyMoney(item.copyWith(isGave: item.isGave == 1 ? 0 : 1));
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'toggle_prepared',
                  child: Text(item.isPrepared == 1 ? 'Chưa chuẩn bị' : 'Đã chuẩn bị'),
                ),
                PopupMenuItem(
                  value: 'toggle_gave',
                  child: Text(item.isGave == 1 ? 'Chưa tặng' : 'Đã tặng'),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem(value: 'delete', child: Text('Xóa', style: TextStyle(color: Colors.red))),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFlag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 10)),
    );
  }

  Color _getGroupColor(String group) {
    switch (group) {
      case 'Gia đình': return Colors.red;
      case 'Họ hàng': return Colors.orange;
      case 'Bạn bè': return Colors.blue;
      case 'Đồng nghiệp': return Colors.teal;
      default: return Colors.grey;
    }
  }

  void _showAddLuckyMoneyDialog(BuildContext context) {
    final nameController = TextEditingController();
    final amountController = TextEditingController();
    String selectedGroup = 'Gia đình';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Thêm người nhận lì xì"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: "Họ và tên"),
              ),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Số tiền (đ)"),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedGroup,
                items: ['Gia đình', 'Họ hàng', 'Bạn bè', 'Đồng nghiệp'].map((e) => 
                  DropdownMenuItem(value: e, child: Text(e))
                ).toList(),
                onChanged: (v) => selectedGroup = v!,
                decoration: const InputDecoration(labelText: "Nhóm"),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Hủy")),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty && amountController.text.isNotEmpty) {
                final amount = double.tryParse(amountController.text) ?? 0;
                context.read<LuckyMoneyProvider>().addLuckyMoney(
                  LuckyMoney(
                    recipient: nameController.text,
                    amount: amount,
                    group: selectedGroup,
                  ),
                );
                Navigator.pop(context);
              }
            },
            child: const Text("Lưu"),
          ),
        ],
      ),
    );
  }
}
