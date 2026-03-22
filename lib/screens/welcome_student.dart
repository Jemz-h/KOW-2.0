import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../navigation/route_transitions.dart';
import '../widgets/form.dart';
import '../widgets/kow_animated_button.dart';
import '../widgets/mock_background.dart';
import 'menu.dart';
import 'welcome_back.dart';

/// Student registration form screen.
class WelcomeStudentScreen extends StatelessWidget {
  const WelcomeStudentScreen({super.key});

  static const double _maxContentWidth = 560;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: MockBackground(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: _maxContentWidth),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                child: WelcomeStudentFormCard(
                  onSubmit: () => pushFade(context, const MenuScreen()),
                  onAlreadyHaveAccountTap: () =>
                      pushFade(context, const WelcomeBackScreen()),
                  onClose: () => Navigator.of(context).pop(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class WelcomeStudentFormCard extends StatefulWidget {
  const WelcomeStudentFormCard({
    super.key,
    this.onClose,
    this.onSubmit,
    this.onAlreadyHaveAccountTap,
  });

  final VoidCallback? onClose;
  final VoidCallback? onSubmit;
  final VoidCallback? onAlreadyHaveAccountTap;

  @override
  State<WelcomeStudentFormCard> createState() => _WelcomeStudentFormCardState();
}

class _WelcomeStudentFormCardState extends State<WelcomeStudentFormCard>
    with SingleTickerProviderStateMixin {
  static const double _figmaCardW = 332;
  static const List<String> _areaOptions = [
    'LAW STREET',
    'KIMCO VILLAGE',
    'WALING-WALING STREET',
    'VICTORIA SUBDIVISION',
    'SAMPAGUITA STREET',
    'DRJ VILLAGE',
    'LOWER SAUYO',
    'SPAZIO BERNARDO CONDOMINIUM',
    'VICTORIA STREET',
    'RICHLAND SUBDIVISION',
    'PASCUAL STREET',
    'GREENVILLE SUBDIVISION',
    'TEODORO COMPOUND',
    'DEL NACIA VILLE 4',
    'AREA 85',
    'NIA VILLAGE',
    'AREA 99',
    'OCEAN PARK',
    'AREA 135',
    'GREENVIEW ROYALE',
    'BISTEKVILLE 15',
    'GREENVIEW EXECUTIVE',
    'MARIAN EXTENSION',
    'BIR VILLAGE',
    'MARIAN SUBDIVISION',
    'VICTORIAN HEIGHTS',
    'MOZART EXTENSION',
    'VILLA HERMANO 1',
    'COMMERCIO',
    'VILLA HERMANO 2',
    'UPPER GULOD',
    'PRIVADA HOMES',
    'LOWER GULOD',
    'MERRY HOMES',
    'AREA 169',
    'ATHERTON',
    'AREA 160-168',
    'LAGKITAN',
    'DEL MUNDO COMPOUND',
    'HERMINIGILDO COMPOUND',
    'MABUHAY COMPOUND',
    'AREA 5A',
    'AREA 5B',
    'AREA 6A',
    'AREA 5B',
    'NAVAL',
    'VILLA ROSARIO',
    'LIPTON STREET',
    'OLD CABUYAO',
    'BALUYOT 1',
    'BALUYOT 2A',
    'BALUYOT 2B',
    'MONTINOLA',
    'BALUYOT PARK',
    'PAPELAN',
    'DAANG NAWASA',
  ];

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _nicknameController = TextEditingController();
  final _birthdayController = TextEditingController();
  final _areaController = TextEditingController();

  String? _selectedSex;
  bool _agreedToTerms = false;
  DateTime? _selectedBirthday;

  late final AnimationController _popupController;
  late final Animation<double> _popupOpacity;
  late final Animation<Offset> _popupSlide;
  late final Animation<double> _popupScale;

  @override
  void initState() {
    super.initState();
    _popupController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 780),
      animationBehavior: AnimationBehavior.preserve,
    );

    _popupOpacity = CurvedAnimation(
      parent: _popupController,
      curve: const Interval(0.0, 0.55, curve: Curves.easeOut),
    );

    _popupSlide = Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _popupController, curve: Curves.easeOutCubic),
        );

    _popupScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 0.86,
          end: 1.03,
        ).chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 72,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.03,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 28,
      ),
    ]).animate(_popupController);

    _popupController.forward();
  }

  @override
  void dispose() {
    _popupController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _nicknameController.dispose();
    _birthdayController.dispose();
    _areaController.dispose();
    super.dispose();
  }

  Future<void> _pickBirthday(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate:
          _selectedBirthday ?? DateTime(now.year - 8, now.month, now.day),
      firstDate: DateTime(1900),
      lastDate: now,
    );

    if (picked == null) return;

    setState(() {
      _selectedBirthday = picked;
      _birthdayController.text = _formatBirthday(picked);
    });
  }

  String _formatBirthday(DateTime date) {
    final mm = date.month.toString().padLeft(2, '0');
    final dd = date.day.toString().padLeft(2, '0');
    final yyyy = date.year.toString();
    return '$mm/$dd/$yyyy';
  }

  Future<void> _pickArea(BuildContext context) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (context) {
        return SafeArea(
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.62,
            child: Column(
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'SELECT AREA',
                  style: TextStyle(
                    fontFamily: 'SuperCartoon',
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF2D2D2D),
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    itemCount: _areaOptions.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final area = _areaOptions[index];
                      return ListTile(
                        dense: true,
                        title: Text(
                          area,
                          style: const TextStyle(
                            fontFamily: 'SuperCartoon',
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF2D2D2D),
                          ),
                        ),
                        onTap: () => Navigator.of(context).pop(area),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (selected == null) return;

    setState(() {
      _areaController.text = selected;
    });
  }

  Widget _buildLabel(String text, double labelSize) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: TextStyle(
          fontFamily: 'SuperCartoon',
          fontSize: labelSize,
          fontWeight: FontWeight.w800,
          color: const Color(0xFF2D2D2D),
        ),
      ),
    );
  }

  Widget _buildStrokedText({
    required String text,
    required TextStyle fillStyle,
    required Color strokeColor,
    required double strokeWidth,
    TextAlign textAlign = TextAlign.center,
  }) {
    return Stack(
      children: [
        Text(
          text,
          textAlign: textAlign,
          style: fillStyle.copyWith(
            foreground: (Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = strokeWidth
              ..color = strokeColor),
          ),
        ),
        Text(text, textAlign: textAlign, style: fillStyle),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardW = constraints.maxWidth;
        final scale = (cardW / _figmaCardW).clamp(0.88, 1.32);

        final labelSize = 13.0 * scale;
        final fieldFont = 18.0 * scale;
        final fieldHeight = (48.0 * scale).clamp(46.0, 54.0);
        final fieldRadius = (10.0 * scale).clamp(8.0, 14.0);
        final titleSize = 36.0 * scale;
        final subtitleSize = 12.5 * scale;

        final sexWidth = (140.0 * scale).clamp(126.0, 180.0);
        final sexHeight = (118.0 * scale).clamp(110.0, 150.0);
        final sexIconHeight = (94.0 * scale).clamp(86.0, 120.0);

        final promptStyle = TextStyle(
          fontFamily: 'SuperCartoon',
          fontSize: 10 * scale,
          fontWeight: FontWeight.w900,
          color: const Color(0xFFF6FF79),
        );

        final ctaStyle = TextStyle(
          fontFamily: 'SuperCartoon',
          fontSize: 10 * scale,
          color: const Color(0xFF79EBFF),
          fontWeight: FontWeight.w800,
          decoration: TextDecoration.underline,
        );

        return FadeTransition(
          opacity: _popupOpacity,
          child: SlideTransition(
            position: _popupSlide,
            child: ScaleTransition(
              scale: _popupScale,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.fromLTRB(
                      16 * scale,
                      10 * scale,
                      16 * scale,
                      8 * scale,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(13 * scale),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 12,
                          offset: Offset(0, 6),
                        ),
                      ],
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              'WELCOME\nSTUDENT!',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'SuperCartoon',
                                fontSize: titleSize,
                                fontWeight: FontWeight.w900,
                                height: 0.95,
                                color: const Color(0xFF2D2D2D),
                              ),
                            ),
                          ),
                          SizedBox(height: 1 * scale),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              'TELL US SOMETHING ABOUT YOU!',
                              style: TextStyle(
                                fontFamily: 'SuperCartoon',
                                fontSize: subtitleSize,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF606060),
                              ),
                            ),
                          ),
                          SizedBox(height: 6 * scale),

                          _buildLabel('FIRST NAME', labelSize),
                          SizedBox(height: 1 * scale),
                          KowTextField(
                            controller: _firstNameController,
                            hintText: 'Example: Sisa',
                            height: fieldHeight,
                            fontSize: fieldFont,
                            borderRadius: fieldRadius,
                          ),
                          SizedBox(height: 4 * scale),

                          _buildLabel('LAST NAME', labelSize),
                          SizedBox(height: 1 * scale),
                          KowTextField(
                            controller: _lastNameController,
                            hintText: 'Example: Oyo',
                            height: fieldHeight,
                            fontSize: fieldFont,
                            borderRadius: fieldRadius,
                          ),
                          SizedBox(height: 4 * scale),

                          _buildLabel('NICKNAME', labelSize),
                          SizedBox(height: 1 * scale),
                          KowTextField(
                            controller: _nicknameController,
                            hintText: 'Example: Sample',
                            height: fieldHeight,
                            fontSize: fieldFont,
                            borderRadius: fieldRadius,
                          ),
                          SizedBox(height: 4 * scale),

                          _buildLabel('BIRTHDAY', labelSize),
                          SizedBox(height: 1 * scale),
                          KowTextField(
                            controller: _birthdayController,
                            hintText: '10/22/2004',
                            readOnly: true,
                            onTap: () => _pickBirthday(context),
                            height: fieldHeight,
                            fontSize: fieldFont,
                            borderRadius: fieldRadius,
                            suffixIcon: Icon(
                              Icons.keyboard_arrow_down,
                              color: const Color(0xFF2D2D2D),
                              size: 22 * scale,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 1, left: 2),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                '*Your birthday will serve as your password.',
                                style: TextStyle(
                                  fontSize: 9.5 * scale,
                                  color: const Color(0xFFE55353),
                                  fontWeight: FontWeight.w600,
                                  height: 1.0,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 6 * scale),

                          _buildLabel('AREA', labelSize),
                          SizedBox(height: 1 * scale),
                          KowTextField(
                            controller: _areaController,
                            hintText: 'Select area',
                            readOnly: true,
                            onTap: () => _pickArea(context),
                            height: fieldHeight,
                            fontSize: fieldFont,
                            borderRadius: fieldRadius,
                            suffixIcon: Icon(
                              Icons.keyboard_arrow_down,
                              color: const Color(0xFF2D2D2D),
                              size: 22 * scale,
                            ),
                          ),
                          SizedBox(height: 8 * scale),

                          Text(
                            'SEX',
                            style: TextStyle(
                              fontFamily: 'SuperCartoon',
                              fontSize: 15 * scale,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF2D2D2D),
                            ),
                          ),
                          SizedBox(height: 0.01),
                          Row(
                            children: [
                              Expanded(
                                child: Center(
                                  child: SexCard(
                                    iconPath: 'assets/Icons/KOWICONS/male.svg',
                                    label: 'MALE',
                                    selected: _selectedSex == 'MALE',
                                    width: sexWidth,
                                    height: sexHeight,
                                    iconHeight: sexIconHeight,
                                    onTap: () =>
                                        setState(() => _selectedSex = 'MALE'),
                                  ),
                                ),
                              ),
                              SizedBox(width: 4 * scale),
                              Expanded(
                                child: Center(
                                  child: SexCard(
                                    iconPath: 'assets/Icons/KOWICONS/female.svg',
                                    label: 'FEMALE',
                                    selected: _selectedSex == 'FEMALE',
                                    width: sexWidth,
                                    height: sexHeight,
                                    iconHeight: sexIconHeight,
                                    onTap: () =>
                                        setState(() => _selectedSex = 'FEMALE'),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8 * scale),

                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: 18 * scale,
                                height: 18 * scale,
                                child: Checkbox(
                                  value: _agreedToTerms,
                                  onChanged: (v) => setState(
                                    () => _agreedToTerms = v ?? false,
                                  ),
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                              ),
                              SizedBox(width: 5 * scale),
                              Expanded(
                                child: RichText(
                                  text: TextSpan(
                                    style: TextStyle(
                                      fontSize: 10.5 * scale,
                                      color: const Color(0xFF2D2D2D),
                                      height: 1.3,
                                    ),
                                    children: [
                                      const TextSpan(
                                        text: 'I have agreed on the ',
                                      ),
                                      TextSpan(
                                        text: 'terms and policy',
                                        style: const TextStyle(
                                          decoration: TextDecoration.underline,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        recognizer: TapGestureRecognizer()
                                          ..onTap = () {},
                                      ),
                                      const TextSpan(
                                        text:
                                            ' about data privacy while using this application.',
                                      ),
                                      const TextSpan(
                                        text: '*',
                                        style: TextStyle(
                                          color: Color(0xFFE55353),
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 10 * scale),

                          SizedBox(
                            width: 160 * scale,
                            height: 48 * scale,
                            child: KowAnimatedButton(
                              label: 'SUBMIT',
                              backgroundColor: const Color(0xFF8CFF9A),
                              textColor: Colors.black,
                              onPressed: widget.onSubmit,
                              height: 48 * scale,
                              fontSize: 14 * scale,
                              width: 160 * scale,
                              borderRadius: BorderRadius.circular(20 * scale),
                            ),
                          ),
                          SizedBox(height: 6 * scale),

                          Wrap(
                            alignment: WrapAlignment.center,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              _buildStrokedText(
                                text: 'ALREADY HAVE AN ACCOUNT? ',
                                fillStyle: promptStyle,
                                strokeColor: const Color(0xFF2D2D2D),
                                strokeWidth: 1.6,
                              ),
                              GestureDetector(
                                onTap: widget.onAlreadyHaveAccountTap,
                                child: _buildStrokedText(
                                  text: 'CLICK ME!',
                                  fillStyle: ctaStyle,
                                  strokeColor: const Color(0xFF2D2D2D),
                                  strokeWidth: 1.6,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 4 * scale),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    top: -2 * scale,
                    right: -2 * scale,
                    child: GestureDetector(
                      onTap: widget.onClose,
                      child: SvgPicture.asset(
                        'assets/Icons/exit.svg',
                        width: 55 * scale,
                        height: 55 * scale,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
