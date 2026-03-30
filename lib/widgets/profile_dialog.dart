import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

void showProfileDialog(BuildContext context) {
  final firstNameController = TextEditingController(text: 'SISA');
  final lastNameController = TextEditingController(text: 'ANTIDO');
  final nicknameController = TextEditingController(text: 'SISA SISIW');
  final birthdayController = TextEditingController(text: 'JANUARY 1, 1999');
  final areaController = TextEditingController(text: 'SAUYO');
  int selectedSex = 1;

  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (context) {
      return StatefulBuilder(builder: (context, setState) {
        final screenWidth = MediaQuery.of(context).size.width;
        final screenHeight = MediaQuery.of(context).size.height;
        final isTablet = screenWidth > 600;

        final dialogWidth = isTablet ? screenWidth * 0.65 : screenWidth * 0.75;

        final hScale = (screenHeight / 700).clamp(0.9, 1.5);
        final wScale = (dialogWidth / 320).clamp(1.0, 2.2);
        final scale = hScale < wScale ? hScale : wScale;

        final titleFontSize = 28.0 * scale;
        final subtitleFontSize = 12.0 * scale;
        final labelFontSize = 14.0 * scale;
        final fieldFontSize = 14.0 * scale;
        final avatarSize = 62.0 * scale;
        final buttonHeight = 42.0 * scale;
        final buttonFontSize = 13.0 * scale;
        final fieldHeight = 44.0 * scale;
        final spacing = 8.0 * scale;

        InputDecoration fieldDecoration(String hint) => InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.grey[500], fontSize: fieldFontSize),
              filled: true,
              fillColor: const Color(0xFFEEEEEE),
              contentPadding: EdgeInsets.symmetric(horizontal: 14 * scale, vertical: 0),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10 * scale),
                borderSide: BorderSide.none,
              ),
            );

        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.symmetric(
            horizontal: (screenWidth - dialogWidth) / 2,
            vertical: screenHeight * 0.04,
          ),
          child: Container(
            width: dialogWidth,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18 * scale),
              boxShadow: const [
                BoxShadow(color: Colors.black38, blurRadius: 16, offset: Offset(0, 8)),
              ],
            ),
            padding: EdgeInsets.symmetric(
              horizontal: dialogWidth * 0.07,
              vertical: 14 * scale,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Text(
                    'HELLO STUDENT!',
                    style: TextStyle(
                      fontSize: titleFontSize,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                      color: Colors.black87,
                    ),
                  ),
                ),
                SizedBox(height: 2 * scale),
                Center(
                  child: Text(
                    'UPDATE YOUR INFORMATION HERE!',
                    style: TextStyle(
                      fontSize: subtitleFontSize,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
                SizedBox(height: spacing * 1.2),

                Text('First Name', style: TextStyle(fontSize: labelFontSize, fontWeight: FontWeight.w800, color: Colors.black87)),
                SizedBox(height: 3 * scale),
                SizedBox(height: fieldHeight, child: TextField(controller: firstNameController, style: TextStyle(fontSize: fieldFontSize, fontWeight: FontWeight.w700), decoration: fieldDecoration('First Name'))),
                SizedBox(height: spacing),

                Text('Last Name', style: TextStyle(fontSize: labelFontSize, fontWeight: FontWeight.w800, color: Colors.black87)),
                SizedBox(height: 3 * scale),
                SizedBox(height: fieldHeight, child: TextField(controller: lastNameController, style: TextStyle(fontSize: fieldFontSize, fontWeight: FontWeight.w700), decoration: fieldDecoration('Last Name'))),
                SizedBox(height: spacing),

                Text('Nickname', style: TextStyle(fontSize: labelFontSize, fontWeight: FontWeight.w800, color: Colors.black87)),
                SizedBox(height: 3 * scale),
                SizedBox(height: fieldHeight, child: TextField(controller: nicknameController, style: TextStyle(fontSize: fieldFontSize, fontWeight: FontWeight.w700), decoration: fieldDecoration('Nickname'))),
                SizedBox(height: spacing),

                Text('Birthday', style: TextStyle(fontSize: labelFontSize, fontWeight: FontWeight.w800, color: Colors.black87)),
                SizedBox(height: 3 * scale),
                SizedBox(
                  height: fieldHeight,
                  child: TextField(
                    controller: birthdayController,
                    style: TextStyle(fontSize: fieldFontSize, fontWeight: FontWeight.w700),
                    decoration: fieldDecoration('Birthday'),
                    readOnly: true,
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime(1999, 1, 1),
                        firstDate: DateTime(1900),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        birthdayController.text = '${_monthName(picked.month)} ${picked.day}, ${picked.year}';
                      }
                    },
                  ),
                ),
                SizedBox(height: spacing),

                Text('Area', style: TextStyle(fontSize: labelFontSize, fontWeight: FontWeight.w800, color: Colors.black87)),
                SizedBox(height: 3 * scale),
                SizedBox(height: fieldHeight, child: TextField(controller: areaController, style: TextStyle(fontSize: fieldFontSize, fontWeight: FontWeight.w700), decoration: fieldDecoration('Area'))),
                SizedBox(height: spacing * 1.2),

                Center(child: Text('Sex', style: TextStyle(fontSize: labelFontSize, fontWeight: FontWeight.w800, color: Colors.black87))),
                SizedBox(height: 6 * scale),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _SexAvatar(assetPath: 'assets/misc/boy.png', selected: selectedSex == 0, checkAsset: 'assets/icons/check.png', size: avatarSize, onTap: () => setState(() => selectedSex = 0)),
                    SizedBox(width: 20 * scale),
                    _SexAvatar(assetPath: 'assets/misc/girl.png', selected: selectedSex == 1, checkAsset: 'assets/icons/check.png', size: avatarSize, onTap: () => setState(() => selectedSex = 1)),
                  ],
                ),
                SizedBox(height: spacing * 1.5),

                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: buttonHeight,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: const RadialGradient(colors: [Color(0xFF79FF9D), Color(0xFF30A65B)]),
                            borderRadius: BorderRadius.circular(25),
                            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 3))],
                          ),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25))),
                            onPressed: () => Navigator.of(context).pop(),
                            child: Text('CONFIRM', style: TextStyle(fontWeight: FontWeight.w900, fontSize: buttonFontSize, letterSpacing: 1.5)),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 10 * scale),
                    Expanded(
                      child: SizedBox(
                        height: buttonHeight,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: const RadialGradient(colors: [Color(0xFFFF797C), Color(0xFFB41E21)]),
                            borderRadius: BorderRadius.circular(25),
                            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 3))],
                          ),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25))),
                            onPressed: () => Navigator.of(context).pop(),
                            child: Text('CANCEL', style: TextStyle(fontWeight: FontWeight.w900, fontSize: buttonFontSize, letterSpacing: 1.5)),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      });
    },
  );
}

String _monthName(int month) {
  const months = ['JANUARY', 'FEBRUARY', 'MARCH', 'APRIL', 'MAY', 'JUNE', 'JULY', 'AUGUST', 'SEPTEMBER', 'OCTOBER', 'NOVEMBER', 'DECEMBER'];
  return months[month - 1];
}

class _SexAvatar extends StatelessWidget {
  const _SexAvatar({required this.assetPath, required this.selected, required this.checkAsset, required this.size, required this.onTap});

  final String assetPath;
  final bool selected;
  final String checkAsset;
  final double size;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          Container(
            width: size, height: size,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: selected ? const Color(0xFF3DBE64) : Colors.grey[300]!, width: 3),
              color: Colors.grey[200],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(11),
              child: assetPath.endsWith('.svg')
                  ? SvgPicture.asset(assetPath, fit: BoxFit.fill, width: size, height: size)
                  : Image.asset(assetPath, fit: BoxFit.fill, width: size, height: size,
                      errorBuilder: (context, error, stackTrace) =>
                          Icon(Icons.person, size: size * 0.5, color: Colors.grey[400])),
            ),
          ),
          if (selected) Positioned.fill(child: Container(decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.35), borderRadius: BorderRadius.circular(14)))),
          if (selected) Positioned.fill(child: Center(child: Image.asset(checkAsset, width: size * 0.55, height: size * 0.55, fit: BoxFit.contain, errorBuilder: (context, error, stackTrace) => Icon(Icons.check_circle, color: const Color(0xFF3DBE64), size: size * 0.55)))),
        ],
      ),
    );
  }
}