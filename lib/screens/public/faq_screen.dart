import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';


class FAQScreen extends StatelessWidget {
  const FAQScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final faqs = [
      {
        'q': 'How do I track my order?',
        'a': 'You can track your order by going to My Orders > Order Details > Track Order. We also send updates via SMS and Email.'
      },
      {
        'q': 'What is your return policy?',
        'a': 'Since we deal with perishable items, we only accept returns if the quality is compromised at the time of delivery. Please check the items during delivery.'
      },
      {
        'q': 'Are your fruits organic?',
        'a': 'Yes, all our fruits are sourced from certified organic farms and are tested for pesticides before listing.'
      },
      {
        'q': 'How long does delivery take?',
        'a': 'Orders placed before 2 PM are delivered the same day. Orders after 2 PM are delivered the next morning.'
      },
      {
        'q': 'Can I cancel my order?',
        'a': 'You can cancel your order within 30 minutes of placing it through the My Orders section.'
      },
    ];

    return Title(
      title: 'FAQ | Blissfruitz',
      color: Colors.green,
      child: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withValues(alpha: 0.05),
            ),
            child: Column(
              children: [
                Text(
                  'HELP CENTER',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Theme.of(context).primaryColor,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Frequently Asked Questions',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1,
                  ),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(24),
              itemCount: faqs.length,
              itemBuilder: (context, index) {
                final faq = faqs[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.08)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Theme(
                    data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      shape: const RoundedRectangleBorder(side: BorderSide.none),
                      collapsedShape: const RoundedRectangleBorder(side: BorderSide.none),
                      title: Text(
                        faq['q']!,
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      iconColor: Theme.of(context).primaryColor,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                          child: Text(
                            faq['a']!,
                            style: GoogleFonts.beVietnamPro(
                              fontSize: 14,
                              height: 1.6,
                              color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

