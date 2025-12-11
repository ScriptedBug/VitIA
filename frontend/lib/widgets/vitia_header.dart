import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class VitiaHeader extends StatelessWidget {
  final String title;
  final Widget? actionIcon;

  const VitiaHeader({
    super.key,
    required this.title,
    this.actionIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Logo Centrado Superior
        const SizedBox(height: 10),
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: 'Vit',
                    style: GoogleFonts.lora(
                      fontSize: 16, // Original was 16, keep it or adjust?
                      fontWeight: FontWeight.bold,
                      fontStyle: FontStyle.italic,
                      color: Colors.black,
                      letterSpacing: 1.0,
                    ),
                  ),
                  TextSpan(
                    text: 'IA',
                    style: GoogleFonts.ibmPlexSans(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // 2. Fila Título + Acción
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: GoogleFonts.lora(
                  fontSize: 32,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF1E2623),
                ),
              ),
              if (actionIcon != null) actionIcon!,
            ],
          ),
        ),
      ],
    );
  }
}
