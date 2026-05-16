import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SewacHeader extends StatefulWidget
    implements PreferredSizeWidget {

  final VoidCallback onLogout;

  const SewacHeader({
    super.key,
    required this.onLogout,
  });

  @override
  Size get preferredSize =>
      const Size.fromHeight(62);

  @override
  State<SewacHeader> createState() =>
      _SewacHeaderState();
}

class _SewacHeaderState
    extends State<SewacHeader> {

  String _adminName = "A";

  @override
  void initState() {
    super.initState();
    _loadAdminName();
  }

  Future<void>
  _loadAdminName() async {

    final prefs =
    await SharedPreferences
        .getInstance();

    if (!mounted) return;

    setState(() {
      _adminName =
          prefs.getString(
            "admin_name",
          ) ??
              "A";
    });
  }

  @override
  Widget build(
      BuildContext context) {

    return AppBar(

      toolbarHeight: 62,
      leadingWidth: 70,

      backgroundColor:
      const Color(
          0xFFF8FBF8),

      elevation: 0,

      surfaceTintColor:
      Colors.transparent,

      scrolledUnderElevation: 0,

      centerTitle: false,

      shape:
      const RoundedRectangleBorder(

        borderRadius:
        BorderRadius.only(

          bottomLeft:
          Radius.circular(18),

          bottomRight:
          Radius.circular(18),
        ),
      ),

      leading: Padding(
        padding:
        const EdgeInsets.only(
          left: 16,
        ),

        child: Image.asset(
          "assets/images/logo.png",

          height: 34,
          width: 34,

          fit: BoxFit.contain,
        ),
      ),

      title: const Padding(
        padding:
        EdgeInsets.only(
          left: 2,
        ),

        child: Text(
          "Helper App",

          style: TextStyle(
            color:
            Color(
                0xFF1A237E),

            fontWeight:
            FontWeight.w700,

            fontSize: 18,
          ),
        ),
      ),

      actions: [

        // Username chip
        Container(

          margin:
          const EdgeInsets.only(
            right: 8,
          ),

          padding:
          const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 6,
          ),

          decoration: BoxDecoration(

            color:
            const Color(
                0xFFF1F8F2),

            borderRadius:
            BorderRadius.circular(
                20),
          ),

          child: Row(
            mainAxisSize:
            MainAxisSize.min,

            children: [

              const CircleAvatar(
                radius: 10,

                backgroundColor:
                Color(
                    0xFF4CAF50),

                child: Icon(
                  Icons.person,

                  size: 12,

                  color:
                  Colors.white,
                ),
              ),

              const SizedBox(
                width: 6,
              ),

              Text(

                _adminName,

                style:
                const TextStyle(

                  fontSize: 11,

                  fontWeight:
                  FontWeight.w600,

                  color:
                  Color(
                      0xFF2E7D32),
                ),
              ),
            ],
          ),
        ),

        // Logout
        Container(

          margin:
          const EdgeInsets.only(
            right: 12,
          ),

          decoration:
          BoxDecoration(

            color:
            Colors.white,

            borderRadius:
            BorderRadius.circular(
                14),
          ),

          child: IconButton(
            onPressed:
            widget.onLogout,

            icon: const Icon(
              Icons.logout_rounded,

              color:
              Color(
                  0xFF1A237E),
            ),
          ),
        ),
      ],
    );
  }
}