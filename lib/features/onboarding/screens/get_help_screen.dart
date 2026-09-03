import 'package:bombay_casting/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:bombay_casting/core/utils/legal_links.dart';
import 'package:bombay_casting/features/profile/screens/payment_and_subscription_screen.dart';

class GetHelpScreen extends StatefulWidget {
  const GetHelpScreen({super.key});

  @override
  State<GetHelpScreen> createState() => _GetHelpScreenState();
}

class _GetHelpScreenState extends State<GetHelpScreen> {
  bool _isProfileExpanded = false;
  bool _isJobsExpanded = false;
  bool _isPaymentExpanded = false;
  bool _isSubscriptionExpanded = false;
  bool _isPoliciesExpanded = false;

  static const _titleStyle = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w500,
    color: Colors.black87,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Text(AppLocalizations.of(context)!.howCanWeHelpYou,
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        titleSpacing: 0,
      ),
      body: ListView(
        children: [
          ExpansionTile(
            title: Text(AppLocalizations.of(context)!.relatedToMyCreatorProfile, style: _titleStyle),
            trailing: _chevron(_isProfileExpanded),
            onExpansionChanged: (expanded) {
              setState(() => _isProfileExpanded = expanded);
            },
            children: const [
              _HelpItem(
                title: 'How do I complete my creator profile?',
                body:
                    'Open Profile, tap Edit Profile, and add your photos, talent, city, and social links so agencies can find you.',
              ),
              _HelpItem(
                title: 'Is there a verification process for creators?',
                body:
                    'Keep your details accurate and upload a clear profile photo. Agencies review applications against the brief for each role.',
              ),
              _HelpItem(
                title: 'Who sees my creator profile?',
                body:
                    'Agencies and production teams on Bombay Casting Company can view your public profile when you apply or when they browse talent.',
              ),
              _HelpItem(
                title: 'Where do I see creators I saved?',
                body:
                    'Use the heart on a creator card to save it. Saved creators appear under Creators → Saved.',
              ),
              _HelpItem(
                title: 'Which jobs can I browse?',
                body:
                    'You can browse open casting calls on Home. Premium lets you apply, message, and contact agencies.',
              ),
            ],
          ),
          const Divider(height: 1, thickness: 0.5, color: Colors.black12),
          ExpansionTile(
            title: Text(AppLocalizations.of(context)!.relatedToJobs, style: _titleStyle),
            trailing: _chevron(_isJobsExpanded),
            onExpansionChanged: (expanded) {
              setState(() => _isJobsExpanded = expanded);
            },
            children: const [
              _HelpItem(
                title: 'How do I apply for a job?',
                body:
                    'Open a casting call, review the brief, then tap Apply. Premium members can submit applications directly from the app.',
              ),
              _HelpItem(
                title: 'Where do I see jobs I saved?',
                body:
                    'Use the heart on a job card to save it. Saved jobs appear under Home → Saved.',
              ),
              _HelpItem(
                title: 'How do I track applications?',
                body:
                    'Open the Messages tab to chat with agencies, or use Home → Saved to revisit roles you saved.',
              ),
              _HelpItem(
                title: 'Can I talk to the agency about a role?',
                body:
                    'Use chat or call from a job after you subscribe. Premium unlocks direct contact with the casting team.',
              ),
            ],
          ),
          const Divider(height: 1, thickness: 0.5, color: Colors.black12),
          ExpansionTile(
            title: Text(AppLocalizations.of(context)!.paymentRelated, style: _titleStyle),
            trailing: _chevron(_isPaymentExpanded),
            onExpansionChanged: (expanded) {
              setState(() => _isPaymentExpanded = expanded);
            },
            children: [
              const _HelpItem(
                title: 'How do I become a Premium member?',
                body:
                    'Open Profile and tap Become a Premium Member, or go to Account Settings → My Subscription to choose a plan.',
              ),
              const _HelpItem(
                title: 'What payment methods are supported?',
                body:
                    'Payments are processed through the in-app checkout. UPI and other methods shown at checkout depend on your bank and device.',
              ),
              const _HelpItem(
                title: 'My payment is pending. What should I do?',
                body:
                    'Stay on the payment screen until it finishes. If it stays pending, wait a few minutes, then check My Subscription. Do not pay twice.',
              ),
              _HelpItem(
                title: 'How do refunds and cancellations work?',
                body:
                    'Refund eligibility depends on the plan and timing of the request. Read the full policy on our website.',
                linkLabel: 'Open Refunds & Cancellation',
                onLinkTap: () => openLegalPage(context, LegalLinks.refunds),
              ),
            ],
          ),
          const Divider(height: 1, thickness: 0.5, color: Colors.black12),
          ExpansionTile(
            title: const Text(
              'Payment and subscription',
              style: _titleStyle,
            ),
            trailing: _chevron(_isSubscriptionExpanded),
            onExpansionChanged: (expanded) {
              setState(() => _isSubscriptionExpanded = expanded);
            },
            children: [
              ListTile(
                title: Text(
                  AppLocalizations.of(context)!.cancelSubscription,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                trailing: Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: Colors.grey.shade500,
                ),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const PaymentAndSubscriptionScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
          const Divider(height: 1, thickness: 0.5, color: Colors.black12),
          ExpansionTile(
            title: Text(AppLocalizations.of(context)!.appPolicies, style: _titleStyle),
            trailing: _chevron(_isPoliciesExpanded),
            onExpansionChanged: (expanded) {
              setState(() => _isPoliciesExpanded = expanded);
            },
            children: [
              _PolicyLink(
                title: 'Terms & Conditions',
                subtitle: 'Rules for using the Bombay Casting Company app',
                onTap: () => openLegalPage(context, LegalLinks.terms),
              ),
              _PolicyLink(
                title: 'Privacy Policy',
                subtitle: 'How we collect and use your information',
                onTap: () => openLegalPage(context, LegalLinks.privacy),
              ),
              _PolicyLink(
                title: 'Refunds & Cancellation',
                subtitle: 'Our refund and cancellation policy',
                onTap: () => openLegalPage(context, LegalLinks.refunds),
              ),
            ],
          ),
          const Divider(height: 1, thickness: 0.5, color: Colors.black12),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () => openLegalPage(context, LegalLinks.website),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFDC1C38),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                child: Text(AppLocalizations.of(context)!.contactUs,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Icon _chevron(bool expanded) {
    return Icon(
      expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
      color: Colors.grey.shade600,
    );
  }
}

class _HelpItem extends StatelessWidget {
  const _HelpItem({
    required this.title,
    required this.body,
    this.linkLabel,
    this.onLinkTap,
  });

  final String title;
  final String body;
  final String? linkLabel;
  final VoidCallback? onLinkTap;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.black87,
            fontWeight: FontWeight.w400,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  body,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.45,
                    color: Colors.grey.shade700,
                  ),
                ),
                if (linkLabel != null && onLinkTap != null) ...[
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: onLinkTap,
                    child: Text(
                      linkLabel!,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.red,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PolicyLink extends StatelessWidget {
  const _PolicyLink({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(
        title,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
      ),
      trailing: Icon(Icons.open_in_new, size: 16, color: Colors.grey.shade500),
      onTap: onTap,
    );
  }
}
