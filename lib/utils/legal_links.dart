import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';

class LegalLinks {
  static const terms = 'https://bombaycastingcompany.com/terms';
  static const privacy = 'https://bombaycastingcompany.com/privacy';
  static const refunds = 'https://bombaycastingcompany.com/refunds';
}

Future<void> openLegalPage(BuildContext context, String url) async {
  final uri = Uri.parse(url);
  try {
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the page')),
      );
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open the page: $e')),
      );
    }
  }
}

class LegalPolicyLinks extends StatelessWidget {
  final String prefix;
  final TextAlign textAlign;

  const LegalPolicyLinks({
    super.key,
    this.prefix = 'By continuing, you agree to our ',
    this.textAlign = TextAlign.center,
  });

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      color: AppColors.textSecondary,
      fontSize: 12,
      height: 1.5,
    );
    final linkStyle = style.copyWith(
      color: context.colors.primary,
      fontWeight: FontWeight.w600,
      decoration: TextDecoration.underline,
    );

    return Text.rich(
      TextSpan(
        style: style,
        children: [
          TextSpan(text: prefix),
          _linkSpan(context, 'Terms & Conditions', LegalLinks.terms, linkStyle),
          const TextSpan(text: ', '),
          _linkSpan(context, 'Privacy Policy', LegalLinks.privacy, linkStyle),
          const TextSpan(text: ' and '),
          _linkSpan(
            context,
            'Refund & Cancellation Policy',
            LegalLinks.refunds,
            linkStyle,
          ),
          const TextSpan(text: '.'),
        ],
      ),
      textAlign: textAlign,
    );
  }

  WidgetSpan _linkSpan(
    BuildContext context,
    String label,
    String url,
    TextStyle style,
  ) {
    return WidgetSpan(
      alignment: PlaceholderAlignment.baseline,
      baseline: TextBaseline.alphabetic,
      child: GestureDetector(
        onTap: () => openLegalPage(context, url),
        child: Text(label, style: style),
      ),
    );
  }
}
