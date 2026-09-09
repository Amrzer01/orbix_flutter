import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';

enum ElementType { text, icon, image }

class DesignElement {
  final String id;
  final ElementType type;
  double dx;
  double dy;
  double scale;
  String? text;
  FaIconData? icon; // ← النوع الصحيح
  File? image;
  Color color;
  String font;

  DesignElement({
    required this.id,
    required this.type,
    this.dx = 50,
    this.dy = 50,
    this.scale = 1.0,
    this.text,
    this.icon,
    this.image,
    this.color = Colors.white,
    this.font = 'Inter',
  });
}

class CardSideDesign {
  List<DesignElement> elements = [];
  Color color1 = const Color(0xFF101112);
  Color color2 = const Color(0xFF101112);
  bool isGradient = false;
  Alignment gradientBegin = Alignment.topLeft;
  Alignment gradientEnd = Alignment.bottomRight;
}

class DesignCardScreen extends StatefulWidget {
  const DesignCardScreen({super.key});

  @override
  State<DesignCardScreen> createState() => _DesignCardScreenState();
}

class _DesignCardScreenState extends State<DesignCardScreen> {
  final CardSideDesign _frontDesign = CardSideDesign();
  final CardSideDesign _backDesign = CardSideDesign();
  bool _isFront = true;
  String? _selectedElementId;
  int _selectedTab = 0;
  final ImagePicker _picker = ImagePicker();

  CardSideDesign get _currentDesign => _isFront ? _frontDesign : _backDesign;

  final List<Color> _colors = [
    Colors.black,
    Colors.white,
    const Color(0xFF6C0AFF),
    const Color(0xFFC8F331),
    Colors.red,
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.pink,
    Colors.teal,
  ];

  // ← النوع الصحيح
  final List<FaIconData> _icons = [
    FontAwesomeIcons.linkedinIn,
    FontAwesomeIcons.instagram,
    FontAwesomeIcons.facebookF,
    FontAwesomeIcons.xTwitter,
    FontAwesomeIcons.tiktok,
    FontAwesomeIcons.youtube,
    FontAwesomeIcons.whatsapp,
    FontAwesomeIcons.telegram,
    FontAwesomeIcons.globe,
    FontAwesomeIcons.phone,
    FontAwesomeIcons.solidEnvelope,
    FontAwesomeIcons.locationDot,
    FontAwesomeIcons.nfcSymbol,
    FontAwesomeIcons.qrcode,
    FontAwesomeIcons.briefcase,
    FontAwesomeIcons.crown,
  ];

  void _addElement(DesignElement element) {
    setState(() {
      _currentDesign.elements.add(element);
      _selectedElementId = element.id;
    });
  }

  void _removeElement(String id) {
    setState(() {
      _currentDesign.elements.removeWhere((e) => e.id == id);
      if (_selectedElementId == id) _selectedElementId = null;
    });
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      _addElement(DesignElement(
        id: DateTime.now().toString(),
        type: ElementType.image,
        image: File(pickedFile.path),
        dx: 20,
        dy: 20,
        scale: 1.0,
      ));
    }
  }

  void _showPreview() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PreviewScreen(
          frontDesign: _frontDesign,
          backDesign: _backDesign,
        ),
      ),
    );
  }

  Widget _buildCardCanvas(CardSideDesign design, {bool isPreview = false}) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: design.isGradient ? null : design.color1,
        gradient: design.isGradient
            ? LinearGradient(
          colors: [design.color1, design.color2],
          begin: design.gradientBegin,
          end: design.gradientEnd,
        )
            : null,
        borderRadius: BorderRadius.circular(24),
        boxShadow: isPreview
            ? []
            : [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: design.elements.map((el) {
            final bool isSelected = _selectedElementId == el.id && !isPreview;
            Widget content;

            switch (el.type) {
              case ElementType.text:
                content = Text(
                  el.text ?? '',
                  style: TextStyle(
                    color: el.color,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                );
                break;
              case ElementType.icon:
                content = FaIcon(el.icon, color: el.color, size: 40);
                break;
              case ElementType.image:
                content = Image.file(
                  el.image!,
                  width: 100,
                  height: 100,
                  fit: BoxFit.contain,
                );
                break;
            }

            return Positioned(
              left: el.dx,
              top: el.dy,
              child: isPreview
                  ? Transform.scale(scale: el.scale, child: content)
                  : GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedElementId = el.id;
                  });
                },
                onPanUpdate: (details) {
                  setState(() {
                    _selectedElementId = el.id;
                    el.dx += details.delta.dx;
                    el.dy += details.delta.dy;
                  });
                },
                child: Transform.scale(
                  scale: el.scale,
                  child: Container(
                    decoration: isSelected
                        ? BoxDecoration(
                      border: Border.all(
                        color: Colors.blueAccent,
                        width: 2 / el.scale,
                      ),
                    )
                        : null,
                    child: content,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildToolsArea() {
    return Column(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              _buildTab(0, 'Background', Icons.wallpaper),
              _buildTab(1, 'Text', Icons.text_fields),
              _buildTab(2, 'Icons', Icons.insert_emoticon),
              _buildTab(3, 'Images', Icons.image),
              _buildTab(4, 'Edit Item', Icons.tune),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Expanded(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _buildSelectedTool(),
          ),
        ),
      ],
    );
  }

  Widget _buildTab(int index, String label, IconData icon) {
    bool isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = index),
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF101112) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.transparent : Colors.grey.shade300,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : const Color(0xFF101112),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF101112),
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedTool() {
    switch (_selectedTab) {
      case 0:
        return _buildBackgroundTool();
      case 1:
        return _buildTextTool();
      case 2:
        return _buildIconTool();
      case 3:
        return _buildImageTool();
      case 4:
        return _buildEditItemTool();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildBackgroundTool() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _currentDesign.isGradient = false),
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: !_currentDesign.isGradient
                          ? const Color(0xFFC8F331)
                          : const Color(0xFFF4F5F7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        'Solid',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: !_currentDesign.isGradient
                              ? const Color(0xFF101112)
                              : Colors.grey,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _currentDesign.isGradient = true),
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: _currentDesign.isGradient
                          ? const Color(0xFFC8F331)
                          : const Color(0xFFF4F5F7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        'Gradient',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _currentDesign.isGradient
                              ? const Color(0xFF101112)
                              : Colors.grey,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text('Color 1', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _colors.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () => setState(() => _currentDesign.color1 = _colors[index]),
                  child: Container(
                    margin: const EdgeInsets.only(right: 12),
                    width: 40,
                    decoration: BoxDecoration(
                      color: _colors[index],
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                  ),
                );
              },
            ),
          ),
          if (_currentDesign.isGradient) ...[
            const SizedBox(height: 20),
            const Text('Color 2', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            SizedBox(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _colors.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () => setState(() => _currentDesign.color2 = _colors[index]),
                    child: Container(
                      margin: const EdgeInsets.only(right: 12),
                      width: 40,
                      decoration: BoxDecoration(
                        color: _colors[index],
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Gradient Direction',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              children: [
                _dirBtn('Top-Bottom', Alignment.topCenter, Alignment.bottomCenter),
                _dirBtn('Left-Right', Alignment.centerLeft, Alignment.centerRight),
                _dirBtn('Diagonal', Alignment.topLeft, Alignment.bottomRight),
              ],
            ),
          ]
        ],
      ),
    );
  }

  Widget _dirBtn(String label, Alignment begin, Alignment end) {
    bool isSel = _currentDesign.gradientBegin == begin &&
        _currentDesign.gradientEnd == end;
    return GestureDetector(
      onTap: () => setState(() {
        _currentDesign.gradientBegin = begin;
        _currentDesign.gradientEnd = end;
      }),
      child: Chip(
        label: Text(
          label,
          style: TextStyle(color: isSel ? Colors.white : Colors.black),
        ),
        backgroundColor: isSel ? const Color(0xFF101112) : const Color(0xFFF4F5F7),
      ),
    );
  }

  Widget _buildTextTool() {
    return Column(
      children: [
        TextField(
          decoration: InputDecoration(
            hintText: 'Enter text...',
            filled: true,
            fillColor: const Color(0xFFF4F5F7),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
          ),
          onSubmitted: (val) {
            if (val.isNotEmpty) {
              _addElement(
                DesignElement(
                  id: DateTime.now().toString(),
                  type: ElementType.text,
                  text: val,
                ),
              );
            }
          },
        ),
        const SizedBox(height: 16),
        const Text(
          'Type text and press enter to add to canvas.',
          style: TextStyle(color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildIconTool() {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 6,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _icons.length,
      itemBuilder: (context, index) {
        return GestureDetector(
          onTap: () {
            _addElement(
              DesignElement(
                id: DateTime.now().toString(),
                type: ElementType.icon,
                icon: _icons[index],
              ),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF4F5F7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: FaIcon(
                _icons[index],
                color: const Color(0xFF101112),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildImageTool() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: _pickImage,
          child: Container(
            width: double.infinity,
            height: 100,
            decoration: BoxDecoration(
              color: const Color(0xFFF4F5F7),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.grey.shade300,
                style: BorderStyle.solid,
              ),
            ),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_photo_alternate, size: 40, color: Colors.grey),
                SizedBox(height: 8),
                Text(
                  'Tap to upload image',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEditItemTool() {
    if (_selectedElementId == null) {
      return const Center(
        child: Text(
          'Tap an element on the card to edit it.',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    final el = _currentDesign.elements.firstWhere((e) => e.id == _selectedElementId);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Size', style: TextStyle(fontWeight: FontWeight.bold)),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _removeElement(el.id),
            ),
          ],
        ),
        Slider(
          value: el.scale,
          min: 0.1,
          max: 5.0,
          activeColor: const Color(0xFFC8F331),
          inactiveColor: const Color(0xFFF4F5F7),
          onChanged: (val) {
            setState(() {
              el.scale = val;
            });
          },
        ),
        if (el.type == ElementType.text || el.type == ElementType.icon) ...[
          const SizedBox(height: 20),
          const Text('Color', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _colors.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () => setState(() => el.color = _colors[index]),
                  child: Container(
                    margin: const EdgeInsets.only(right: 12),
                    width: 40,
                    decoration: BoxDecoration(
                      color: _colors[index],
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Color(0xFF101112),
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Design Card',
          style: TextStyle(
            color: Color(0xFF101112),
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          Center(
            child: GestureDetector(
              onTap: _showPreview,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF101112),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Preview',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _isFront = true;
                      _selectedElementId = null;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                    decoration: BoxDecoration(
                      color: _isFront ? const Color(0xFFC8F331) : const Color(0xFFF4F5F7),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Front',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _isFront ? const Color(0xFF101112) : Colors.grey,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _isFront = false;
                      _selectedElementId = null;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                    decoration: BoxDecoration(
                      color: !_isFront ? const Color(0xFFC8F331) : const Color(0xFFF4F5F7),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Back',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: !_isFront ? const Color(0xFF101112) : Colors.grey,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: AspectRatio(
              aspectRatio: 1.58,
              child: _buildCardCanvas(_currentDesign),
            ),
          ),
          const SizedBox(height: 32),
          Expanded(child: _buildToolsArea()),
        ],
      ),
    );
  }
}

class PreviewScreen extends StatefulWidget {
  final CardSideDesign frontDesign;
  final CardSideDesign backDesign;

  const PreviewScreen({
    super.key,
    required this.frontDesign,
    required this.backDesign,
  });

  @override
  State<PreviewScreen> createState() => _PreviewScreenState();
}

class _PreviewScreenState extends State<PreviewScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _showFrontSide = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(_controller)
      ..addListener(() {
        setState(() {});
      })
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _showFrontSide = false;
        } else if (status == AnimationStatus.dismissed) {
          _showFrontSide = true;
        }
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleCard() {
    if (_showFrontSide) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  Widget _buildCardCanvas(CardSideDesign design) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: design.isGradient ? null : design.color1,
        gradient: design.isGradient
            ? LinearGradient(
          colors: [design.color1, design.color2],
          begin: design.gradientBegin,
          end: design.gradientEnd,
        )
            : null,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 30,
            offset: const Offset(0, 15),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: design.elements.map((el) {
            Widget content;
            switch (el.type) {
              case ElementType.text:
                content = Text(
                  el.text ?? '',
                  style: TextStyle(
                    color: el.color,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                );
                break;
              case ElementType.icon:
                content = FaIcon(el.icon, color: el.color, size: 40);
                break;
              case ElementType.image:
                content = Image.file(
                  el.image!,
                  width: 100,
                  height: 100,
                  fit: BoxFit.contain,
                );
                break;
            }
            return Positioned(
              left: el.dx,
              top: el.dy,
              child: Transform.scale(scale: el.scale, child: content),
            );
          }).toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F7),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Color(0xFF101112)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '3D Preview',
          style: TextStyle(
            color: Color(0xFF101112),
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: _toggleCard,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: AspectRatio(
                  aspectRatio: 1.58,
                  child: Transform(
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.001)
                      ..rotateY(_animation.value * pi),
                    alignment: Alignment.center,
                    child: _animation.value < 0.5
                        ? _buildCardCanvas(widget.frontDesign)
                        : Transform(
                      transform: Matrix4.identity()..rotateY(pi),
                      alignment: Alignment.center,
                      child: _buildCardCanvas(widget.backDesign),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: _toggleCard,
              icon: const Icon(Icons.flip, color: Colors.black),
              label: const Text(
                'Flip Card',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFC8F331),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}