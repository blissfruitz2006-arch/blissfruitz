import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/theme.dart';
import '../../widgets/footer.dart';

class StaticPageScreen extends StatelessWidget {
  final String title;
  final String content;

  const StaticPageScreen({
    super.key,
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Title(
      title: '$title | BlissFruitz',
      color: Colors.white,
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 40, 24, 32),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.outfit(
                      fontSize: 40,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1.5,
                      color: AppTheme.primary,
                    ),
                  ),
                  const SizedBox(height: 32),
                  _buildContent(context),
                ],
              ),
            ),
          ),
          
          const SliverToBoxAdapter(child: AppFooter()),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    // Basic Markdown-ish rendering for the static pages
    final lines = content.split('\n');
    List<Widget> widgets = [];

    for (var line in lines) {
      line = line.trim();
      if (line.isEmpty) {
        widgets.add(const SizedBox(height: 16));
        continue;
      }

      if (line.startsWith('## ')) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(top: 24, bottom: 12),
          child: Text(
            line.replaceFirst('## ', ''),
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppTheme.onSurface,
            ),
          ),
        ));
      } else if (line.startsWith('# ')) {
        // Skip main title as it's already shown
        continue;
      } else if (line.startsWith('- ')) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('• ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primary)),
              Expanded(
                child: Text(
                  line.replaceFirst('- ', ''),
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 15,
                    height: 1.6,
                    color: const Color.fromARGB(255, 24, 152, 24),
                  ),
                ),
              ),
            ],
          ),
        ));
      } else {
        widgets.add(Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            line,
            style: GoogleFonts.beVietnamPro(
              fontSize: 15,
              height: 1.6,
              color: AppTheme.onSurfaceVariant,
            ),
          ),
        ));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }
}
