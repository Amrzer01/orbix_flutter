import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CreditScreen extends StatefulWidget {
  final String initialLink;
  const CreditScreen({super.key, this.initialLink = ''});

  @override
  State<CreditScreen> createState() => _CreditScreenState();
}

class _CreditScreenState extends State<CreditScreen> with TickerProviderStateMixin {
  bool _isScanning = true;
  bool _cardReadSuccess = false;
  late TextEditingController _linkController;
  late AnimationController _radarController;
  late AnimationController _pulseController;
  late String _defaultLink;

  @override
  void initState() {
    super.initState();

    // جلب الـ UID الخاص بالمستخدم لإنشاء الرابط الأساسي
    final String uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    _defaultLink = 'https://eng-amar.com/info/index.php?id=$uid';

    // وضع الرابط الأساسي بشكل افتراضي إذا لم يتم تمرير رابط أولي
    _linkController = TextEditingController(
      text: widget.initialLink.isNotEmpty ? widget.initialLink : _defaultLink,
    );

    // الاستماع لتغييرات النص لإظهار/إخفاء زر استرجاع الرابط
    _linkController.addListener(() {
      setState(() {});
    });

    _radarController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _startNfcScan();
  }

  @override
  void dispose() {
    NfcManager.instance.stopSession();
    _radarController.dispose();
    _pulseController.dispose();
    _linkController.dispose();
    super.dispose();
  }

  Future<void> _startNfcScan() async {
    bool isAvailable = await NfcManager.instance.isAvailable();
    if (!isAvailable) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('NFC is not supported or not enabled')),
        );
      }
      return;
    }
    setState(() {
      _isScanning = true;
      _cardReadSuccess = false;
    });
    NfcManager.instance.startSession(onDiscovered: (NfcTag tag) async {
      if (!_isScanning) return;
      Ndef? ndef = Ndef.from(tag);
      if (ndef == null) {
        _handleError('This card does not support NDEF');
        return;
      }
      try {
        final cachedMessage = ndef.cachedMessage;
        if (cachedMessage != null && cachedMessage.records.isNotEmpty) {
          final record = cachedMessage.records.first;
          final String decodedLink = _decodeNdefRecord(record);
          setState(() {
            _linkController.text = decodedLink;
            _cardReadSuccess = true;
            _isScanning = false;
          });
        } else {
          setState(() {
            _cardReadSuccess = true;
            _isScanning = false;
          });
        }
      } catch (e) {
        _handleError('Error while reading the card');
      }
    });
  }

  Future<void> _writeNfcCard() async {
    if (_linkController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the link first')),
      );
      return;
    }
    NfcManager.instance.stopSession();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const FaIcon(FontAwesomeIcons.nfcSymbol, size: 56, color: Color(0xFF101112)),
              const SizedBox(height: 20),
              const Text(
                'Writing to card...',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF101112)),
              ),
              const SizedBox(height: 10),
              const Text(
                'Hold the card near the back of your phone',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF9A9EA6), fontSize: 13),
              ),
              const SizedBox(height: 24),
              TextButton(
                onPressed: () {
                  NfcManager.instance.stopSession();
                  Navigator.pop(context);
                  _startNfcScan();
                },
                child: const Text('Cancel', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      },
    );
    NfcManager.instance.startSession(onDiscovered: (NfcTag tag) async {
      var ndef = Ndef.from(tag);
      if (ndef == null || !ndef.isWritable) {
        NfcManager.instance.stopSession(errorMessage: "Card is not writable");
        if (mounted) {
          Navigator.pop(context);
          _startNfcScan();
        }
        return;
      }
      try {
        await ndef.write(NdefMessage([
          NdefRecord.createUri(Uri.parse(_linkController.text)),
        ]));
        NfcManager.instance.stopSession();
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Card updated successfully!'),
              backgroundColor: Color(0xFFC8F331),
              duration: Duration(seconds: 2),
            ),
          );
          _startNfcScan();
        }
      } catch (e) {
        NfcManager.instance.stopSession(errorMessage: e.toString());
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to write to the card'), backgroundColor: Colors.red),
          );
          _startNfcScan();
        }
      }
    });
  }

  String _decodeNdefRecord(NdefRecord record) {
    if (record.typeNameFormat == NdefTypeNameFormat.nfcWellknown) {
      if (record.type.length == 1 && record.type.first == 0x55) {
        final payload = record.payload;
        if (payload.isNotEmpty) {
          final prefixCode = payload[0];
          final urlPrefixes = {
            0x01: 'http://www.',
            0x02: 'https://www.',
            0x03: 'http://',
            0x04: 'https://',
            0x00: '',
          };
          final prefix = urlPrefixes[prefixCode] ?? '';
          return prefix + utf8.decode(payload.sublist(1));
        }
      }
    }
    return String.fromCharCodes(record.payload);
  }

  void _handleError(String error) {
    setState(() => _isScanning = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF101112), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'NFC Setup',
          style: TextStyle(color: Color(0xFF101112), fontWeight: FontWeight.bold, fontSize: 17),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: AnimatedBuilder(
                animation: Listenable.merge([_radarController, _pulseController]),
                builder: (context, child) {
                  return SizedBox(
                    width: 260,
                    height: 260,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        ...List.generate(3, (i) {
                          final progress = (_radarController.value + i * 0.33) % 1.0;
                          return Container(
                            width: 70 + progress * 190,
                            height: 70 + progress * 190,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFFC8F331).withOpacity((0.45 - progress * 0.45).clamp(0.0, 1.0)),
                                width: 1.8,
                              ),
                            ),
                          );
                        }),
                        Transform.scale(
                          scale: 1.0 + (_pulseController.value * 0.12),
                          child: Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFFC8F331).withOpacity(0.12),
                              border: Border.all(color: const Color(0xFFC8F331), width: 2),
                            ),
                            child: const Icon(
                              Icons.nfc,
                              size: 42,
                              color: Color(0xFFC8F331),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          Text(
            _isScanning ? 'Searching for NFC card...' : 'Card detected',
            style: const TextStyle(
              color: Color(0xFF101112),
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              _isScanning
                  ? 'Hold the card near the back of your phone'
                  : 'You can now edit the link and write to the card',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: const Color(0xFF101112).withOpacity(0.55),
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(height: 36),
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              boxShadow: [
                BoxShadow(
                  color: Color(0x0D000000),
                  blurRadius: 20,
                  offset: Offset(0, -4),
                ),
              ],
            ),
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Card Link',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF9A9EA6),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _linkController,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF101112),
                  ),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color(0xFFF4F5F7),
                    hintText: 'https://...',
                    hintStyle: const TextStyle(color: Color(0xFF9A9EA6)),
                    prefixIcon: const Icon(Icons.link, color: Color(0xFF101112)),
                    // زر استرجاع الرابط يظهر فقط في حال تم تغيير الرابط الأساسي
                    suffixIcon: _linkController.text != _defaultLink
                        ? IconButton(
                      icon: const Icon(Icons.refresh, color: Color(0xFF9A9EA6)),
                      tooltip: 'Restore Default Link',
                      onPressed: () {
                        setState(() {
                          _linkController.text = _defaultLink;
                        });
                      },
                    )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(vertical: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: _writeNfcCard,
                    icon: const Icon(Icons.nfc, color: Color(0xFF101112)),
                    label: const Text(
                      'Save & Write to Card',
                      style: TextStyle(
                        color: Color(0xFF101112),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFC8F331),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}