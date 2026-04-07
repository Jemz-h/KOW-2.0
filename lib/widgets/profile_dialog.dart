import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../api_service.dart';

Future<void> showProfileDialog(BuildContext context) async {
  final profile = await ApiService.getCurrentProfile();
  if (!context.mounted) {
    return;
  }

  final storedBirthday = (profile?['birthday'] as String?)?.trim() ?? '';
  final parsedBirthday = _parseBirthday(storedBirthday);

  final firstNameController = TextEditingController(
    text: (profile?['first_name'] as String?) ?? '',
  );
  final lastNameController = TextEditingController(
    text: (profile?['last_name'] as String?) ?? '',
  );
  final nicknameController = TextEditingController(
    text: (profile?['nickname'] as String?) ?? '',
  );
  final birthdayController = TextEditingController(
    text: parsedBirthday != null
        ? _formatBirthdayDisplay(parsedBirthday)
        : storedBirthday,
  );
  final areaController = TextEditingController(
    text: (profile?['area'] as String?) ?? '',
  );
  int selectedSex = _sexIndexFromValue(profile?['sex'] as String?);
  bool isSaving = false;
  DateTime selectedBirthday = parsedBirthday ?? DateTime(1999, 1, 1);

  await showDialog(
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
                        initialDate: selectedBirthday,
                        firstDate: DateTime(1900),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        selectedBirthday = picked;
                        birthdayController.text = _formatBirthdayDisplay(picked);
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
                            onPressed: isSaving ? null : () async {
                              if (firstNameController.text.trim().isEmpty ||
                                  lastNameController.text.trim().isEmpty ||
                                  nicknameController.text.trim().isEmpty ||
                                  birthdayController.text.trim().isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Please fill all required fields.')),
                                );
                                return;
                              }

                              setState(() => isSaving = true);
                              try {
                                await ApiService.updateProfile(
                                  firstName: firstNameController.text.trim(),
                                  lastName: lastNameController.text.trim(),
                                  nickname: nicknameController.text.trim(),
                                  birthday: _toApiBirthday(
                                    birthdayController.text.trim(),
                                  ),
                                  sex: selectedSex == 0 ? 'MALE' : 'FEMALE',
                                  area: areaController.text.trim().isEmpty ? null : areaController.text.trim(),
                                );

                                if (context.mounted) {
                                  Navigator.of(context).pop();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Profile updated successfully!')),
                                  );
                                }
                              } on ApiException catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(e.message)),
                                  );
                                  setState(() => isSaving = false);
                                }
                              } catch (_) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Could not update profile. Try again.')),
                                  );
                                  setState(() => isSaving = false);
                                }
                              }
                            },
                            child: Text(isSaving ? 'SAVING...' : 'CONFIRM', style: TextStyle(fontWeight: FontWeight.w900, fontSize: buttonFontSize, letterSpacing: 1.5)),
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
                            onPressed: isSaving ? null : () => Navigator.of(context).pop(),
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

int _sexIndexFromValue(String? sex) {
  final normalized = (sex ?? '').trim().toUpperCase();
  if (normalized == 'MALE' || normalized == 'M') {
    return 0;
  }
  return 1;
}

DateTime? _parseBirthday(String? value) {
  final raw = (value ?? '').trim();
  if (raw.isEmpty) return null;

  final iso = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(raw);
  if (iso != null) {
    return DateTime(
      int.parse(iso.group(1)!),
      int.parse(iso.group(2)!),
      int.parse(iso.group(3)!),
    );
  }

  final long = RegExp(r'^([A-Z]+)\s+(\d{1,2}),\s*(\d{4})$').firstMatch(
    raw.toUpperCase(),
  );
  if (long != null) {
    final month = _monthIndex(long.group(1)!);
    if (month != null) {
      return DateTime(
        int.parse(long.group(3)!),
        month,
        int.parse(long.group(2)!),
      );
    }
  }

  return null;
}

int? _monthIndex(String monthName) {
  const months = [
    'JANUARY',
    'FEBRUARY',
    'MARCH',
    'APRIL',
    'MAY',
    'JUNE',
    'JULY',
    'AUGUST',
    'SEPTEMBER',
    'OCTOBER',
    'NOVEMBER',
    'DECEMBER',
  ];
  final i = months.indexOf(monthName.toUpperCase());
  return i < 0 ? null : i + 1;
}

String _formatBirthdayDisplay(DateTime date) {
  return '${_monthName(date.month)} ${date.day}, ${date.year}';
}

String _toApiBirthday(String value) {
  final parsed = _parseBirthday(value);
  if (parsed == null) {
    return value;
  }
  final yyyy = parsed.year.toString();
  final mm = parsed.month.toString().padLeft(2, '0');
  final dd = parsed.day.toString().padLeft(2, '0');
  return '$yyyy-$mm-$dd';
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