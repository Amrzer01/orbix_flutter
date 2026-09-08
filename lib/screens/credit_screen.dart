import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../models/wallet.dart';

class CreditScreen extends StatefulWidget {
  const CreditScreen({super.key});

  @override
  State<CreditScreen> createState() => _CreditScreenState();
}

class _CreditScreenState extends State<CreditScreen> {
  final String? _currentUserId = FirebaseAuth.instance.currentUser?.uid;

  Color _getColorFromHex(String hexColor) {
    hexColor = hexColor.toUpperCase().replaceAll("#", "");
    if (hexColor.length == 6) hexColor = "FF$hexColor";
    return Color(int.parse(hexColor, radix: 16));
  }

  dynamic _getIconForClass(String iconClass) {
    if (iconClass.contains('wallet')) return FontAwesomeIcons.wallet;
    if (iconClass.contains('money-bill-transfer')) return FontAwesomeIcons.moneyBillTransfer;
    if (iconClass.contains('paypal')) return FontAwesomeIcons.paypal;
    if (iconClass.contains('apple-pay')) return FontAwesomeIcons.applePay;
    if (iconClass.contains('google-pay')) return FontAwesomeIcons.googlePay;
    return FontAwesomeIcons.wallet;
  }

  void _showAddWalletModal() {
    // A simple form to add a wallet for demonstration
    // Since this wasn't explicitly in the PHP file (maybe it was in admin), 
    // we'll add a quick way for users to add their wallets.
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _AddWalletBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUserId == null) return const Scaffold();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F7),
      appBar: AppBar(
        title: const Text('My Accounts (Credits)', style: TextStyle(color: Color(0xFF101112), fontSize: 17, fontWeight: FontWeight.w600)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF101112)),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('wallets')
            .where('user_id', isEqualTo: _currentUserId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No accounts added yet.', style: TextStyle(color: Colors.grey)));
          }

          final wallets = snapshot.data!.docs
              .map((doc) => Wallet.fromMap(doc.data() as Map<String, dynamic>, doc.id))
              .toList();

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: wallets.length,
            itemBuilder: (context, index) {
              final wallet = wallets[index];
              final isDarkText = wallet.type.toLowerCase().contains('binance'); // from PHP logic
              final textColor = isDarkText ? const Color(0xFF101112) : Colors.white;
              
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                height: 180,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: LinearGradient(
                    colors: [
                      _getColorFromHex(wallet.colorStart),
                      _getColorFromHex(wallet.colorEnd),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(color: _getColorFromHex(wallet.colorStart).withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 8))
                  ],
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          wallet.type,
                          style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        FaIcon(_getIconForClass(wallet.iconClass), color: textColor, size: 28),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Account / Number',
                          style: TextStyle(color: textColor.withValues(alpha: 0.7), fontSize: 12),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          wallet.details,
                          style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.w600, letterSpacing: 1.5),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddWalletModal,
        backgroundColor: const Color(0xFFC8F331),
        child: const Icon(Icons.add, color: Color(0xFF101112)),
      ),
    );
  }
}

class _AddWalletBottomSheet extends StatefulWidget {
  const _AddWalletBottomSheet();

  @override
  State<_AddWalletBottomSheet> createState() => _AddWalletBottomSheetState();
}

class _AddWalletBottomSheetState extends State<_AddWalletBottomSheet> {
  final _typeController = TextEditingController();
  final _detailsController = TextEditingController();

  Future<void> _saveWallet() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _typeController.text.isEmpty || _detailsController.text.isEmpty) return;
    
    // Quick pseudo colors for common types
    String colorStart = '#E60000';
    String colorEnd = '#B30000';
    
    final t = _typeController.text.toLowerCase();
    if (t.contains('vodafone')) {
      colorStart = '#E60000'; colorEnd = '#B30000';
    } else if (t.contains('etisalat')) {
      colorStart = '#007a33'; colorEnd = '#005924';
    } else if (t.contains('orange')) {
      colorStart = '#FF7900'; colorEnd = '#CC6100';
    } else if (t.contains('insta')) {
      colorStart = '#6C0AFF'; colorEnd = '#4A00B8';
    } else if (t.contains('binance')) {
      colorStart = '#FCD535'; colorEnd = '#E0BD22';
    }

    await FirebaseFirestore.instance.collection('wallets').add({
      'user_id': user.uid,
      'type': _typeController.text,
      'details': _detailsController.text,
      'color_start': colorStart,
      'color_end': colorEnd,
      'icon_class': 'fa-solid fa-wallet',
    });
    
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: EdgeInsets.only(
        top: 24,
        left: 24,
        right: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Add Wallet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          TextField(
            controller: _typeController,
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFFF4F5F7),
              hintText: 'Wallet Type (e.g., Vodafone Cash)',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _detailsController,
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFFF4F5F7),
              hintText: 'Number / Address',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              onPressed: _saveWallet,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF101112),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              ),
              child: const Text('Add', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}
