import 'package:flutter/material.dart';
import 'package:smart_farm/theme/app_colors.dart';

class TopBar extends StatefulWidget {
  const TopBar({super.key, required this.title, this.isBack = true});
  final String title;
  final bool isBack;

  @override
  State<TopBar> createState() => _TopBarState();
}

class _TopBarState extends State<TopBar> {
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final pix = size.width / 375;

    return Container(
      height: 70 * pix,
      width: size.width,
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          widget.isBack
              ? Container(
                  width: pix * 50,
                  margin: EdgeInsets.only(top: 0 * pix),
                  child: IconButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    icon: Container(
                      padding: EdgeInsets.all(0 * pix),
                      child: Icon(
                        Icons.arrow_back_ios_new,
                        color: Colors.white,
                        size: 20 * pix,
                      ),
                    ),
                  ))
              : const SizedBox(),
          Expanded(
            child: Container(
              height: 70 * pix,
              padding: EdgeInsets.only(top: 16 * pix),
              child: Text(
                widget.title,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24 * pix,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'BeVietnamPro',
                  letterSpacing: 0.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          SizedBox(width: widget.isBack ? 50 * pix : 0),
        ],
      ),
    );
  }
}
