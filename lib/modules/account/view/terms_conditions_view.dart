import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../shared/widgets/back_icon_widget.dart';

class _SectionHeading extends StatelessWidget {
  final String text;
  const _SectionHeading(this.text);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
      child: Text(
        text,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _BulletList extends StatelessWidget {
  final List<String> items;
  const _BulletList(this.items);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items
          .map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 4.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• ', style: TextStyle(height: 1.5)),
                  Expanded(
                    child: Text(item, style: theme.textTheme.bodyMedium),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

class TermsConditionsView extends StatelessWidget {
  const TermsConditionsView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leadingWidth: 44,
        leading: const BackIconWidget(),
        centerTitle: false,
        titleSpacing: 0,
        title: Text(
          'Terms and Conditions'.tr,
          style: const TextStyle(fontWeight: FontWeight.normal, fontSize: 18),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Last updated: 24 November 2025',
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 16),
                const _SectionHeading('1. Acceptance of Terms'),
                Text(
                  'These Terms & Conditions ("Terms") govern your access to and use of the Kartly mobile application and any related services (collectively, the "Service"). By downloading, accessing or using the Service, you agree to be bound by these Terms. If you do not agree to these Terms, you must not use the Service.',
                  style: theme.textTheme.bodyMedium,
                ),
                const _SectionHeading(
                  '2. Eligibility and Account Registration',
                ),
                Text(
                  'To use certain features of Kartly, you may be required to create an account. You must be at least 18 years old (or the age of majority in your jurisdiction) or have consent from a parent or legal guardian. You agree to provide accurate, current and complete information during registration and to keep this information updated. You are responsible for maintaining the confidentiality of your login credentials and for all activities that occur under your account.',
                  style: theme.textTheme.bodyMedium,
                ),
                const _SectionHeading('3. Licence to Use'),
                Text(
                  'Subject to your compliance with these Terms, we grant you a limited, non‑exclusive, non‑transferable, non‑sublicensable and revocable licence to download and use the Kartly app on your personal device solely for your own non‑commercial use【95042552180243†L270-L276】. You may not copy, modify, distribute, sell or lease any part of the Service, reverse engineer or attempt to extract the source code, except as permitted by law.',
                  style: theme.textTheme.bodyMedium,
                ),
                const _SectionHeading('4. Prohibited Conduct'),
                Text(
                  'You agree not to engage in any of the following prohibited activities:',
                  style: theme.textTheme.bodyMedium,
                ),
                const _BulletList([
                  'Violating any applicable law, regulation or third‑party rights.',
                  'Harassing, threatening, abusing or intimidating other users.',
                  'Impersonating another person or entity or misrepresenting your affiliation.',
                  'Spamming, sending unsolicited messages or performing fraudulent transactions.',
                  'Uploading or transmitting viruses, malware or any other malicious code.',
                  'Attempting to gain unauthorised access to the Service or another user’s account.',
                  'Reverse engineering or decompiling the app or engaging in any activity that interferes with or disrupts the Service.',
                ]),
                const _SectionHeading('5. Purchases, Payments and Taxes'),
                Text(
                  'When you make a purchase through Kartly, you agree to provide valid payment information and to pay all charges incurred by you or on your behalf, including any applicable taxes. Prices and availability of products are subject to change without notice. We may use third‑party payment processors to facilitate transactions; your use of these services may be subject to additional terms.',
                  style: theme.textTheme.bodyMedium,
                ),
                const _SectionHeading('6. Shipping, Delivery and Returns'),
                Text(
                  'We will deliver products to the address you provide at checkout. Delivery times are estimates and not guaranteed; delays may occur due to circumstances beyond our control. Return and refund eligibility is described in our Return & Refund Policy, which is incorporated by reference. You are responsible for any customs duties, import taxes or additional fees imposed by your jurisdiction.',
                  style: theme.textTheme.bodyMedium,
                ),
                const _SectionHeading('7. User Content'),
                Text(
                  'Kartly may allow you to post reviews, comments or other content (collectively, "User Content"). By submitting User Content, you grant us a non‑exclusive, worldwide, royalty‑free licence to use, store, display, reproduce, modify and distribute your User Content in connection with operating and improving the Service. You represent that you have all necessary rights to grant this licence and that your User Content does not violate any law or infringe any third‑party rights. We reserve the right to remove User Content that violates these Terms or is otherwise objectionable.',
                  style: theme.textTheme.bodyMedium,
                ),
                const _SectionHeading('8. Intellectual Property'),
                Text(
                  'The Service and all content, trademarks, logos and software associated with it are owned by Kartly or its licensors and are protected by intellectual property laws. Except for the limited licence granted above, nothing in these Terms conveys to you any right or interest in the Service or its content. You may not use Kartly’s trademarks or branding without our prior written consent.',
                  style: theme.textTheme.bodyMedium,
                ),
                const _SectionHeading('9. Third‑Party Services'),
                Text(
                  'The Service may contain links to third‑party websites or services that are not owned or controlled by Kartly. We are not responsible for the content, policies or practices of any third‑party services. Your use of any third‑party service is at your own risk and subject to that third party’s terms and policies.',
                  style: theme.textTheme.bodyMedium,
                ),
                const _SectionHeading('10. Disclaimer of Warranties'),
                Text(
                  'Kartly provides the Service on an "as is" and "as available" basis without warranties of any kind, either express or implied. To the maximum extent permitted by law, we expressly disclaim all warranties of merchantability, fitness for a particular purpose, non‑infringement and any warranties arising out of course of dealing or usage of trade. We do not warrant that the Service will be uninterrupted, error‑free or secure, or that any defects will be corrected.',
                  style: theme.textTheme.bodyMedium,
                ),
                const _SectionHeading('11. Limitation of Liability'),
                Text(
                  'To the fullest extent permitted by law, Kartly and its affiliates will not be liable for any indirect, incidental, special, consequential or punitive damages, or any loss of profits or revenues, whether incurred directly or indirectly, or any loss of data, use, goodwill or other intangible losses, resulting from (i) your access to or use of or inability to access or use the Service; (ii) any conduct or content of any third party on the Service; (iii) any products purchased through the Service; or (iv) unauthorised access, use or alteration of your transmissions or content.',
                  style: theme.textTheme.bodyMedium,
                ),
                const _SectionHeading('12. Indemnification'),
                Text(
                  'You agree to defend, indemnify and hold harmless Kartly and its affiliates, officers, directors, employees and agents from and against any claims, liabilities, damages, losses and expenses (including reasonable attorney\'s fees) arising out of or in any way connected with your access to or use of the Service, your User Content, or your violation of these Terms.',
                  style: theme.textTheme.bodyMedium,
                ),
                const _SectionHeading('13. Termination'),
                Text(
                  'We may suspend or terminate your access to the Service at any time, with or without notice, if you violate these Terms or if we believe suspension is necessary to protect our interests or those of other users. Upon termination, all licences and rights granted to you in these Terms will immediately cease. You may delete your account at any time through the app settings or by contacting us. Upon account deletion, we will remove your data as described in our Privacy Policy【974206023269784†L252-L266】.',
                  style: theme.textTheme.bodyMedium,
                ),
                const _SectionHeading('14. Governing Law'),
                Text(
                  'These Terms are governed by and construed in accordance with the laws of Bangladesh, without regard to its conflict of law principles. If you are located outside of Bangladesh, you agree that any dispute arising under these Terms shall be subject to the exclusive jurisdiction of the courts of Bangladesh.',
                  style: theme.textTheme.bodyMedium,
                ),
                const _SectionHeading('15. Changes to Terms'),
                Text(
                  'We may modify these Terms from time to time to reflect changes to our practices or for legal, regulatory or security reasons. If we make material changes, we will notify you by updating the “Last updated” date above and, in some cases, by providing additional notice (for example, by displaying a message within the app). Your continued use of the Service after the effective date of the updated Terms constitutes your acceptance of the changes.',
                  style: theme.textTheme.bodyMedium,
                ),
                const _SectionHeading('16. Contact Information'),
                Text(
                  'For questions or concerns about these Terms or the Service, please contact us at:\n\nEmail: support@kartly.app\nAddress: Kartly, Dhaka, Bangladesh\n',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
