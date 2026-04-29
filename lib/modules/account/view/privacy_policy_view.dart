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

class PrivacyPolicyView extends StatelessWidget {
  const PrivacyPolicyView({super.key});

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
          'Privacy Policy'.tr,
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
                const _SectionHeading('1. Introduction'),
                Text(
                  'Kartly ("we", "us" or "our") operates an e‑commerce platform that allows users to browse and purchase goods and services. This Privacy Policy describes how we collect, use, share and protect personal information when you use the Kartly mobile application and any related services. By using our app, you agree to the collection and use of information in accordance with this policy.',
                  style: theme.textTheme.bodyMedium,
                ),
                const _SectionHeading('2. Information We Collect'),
                Text(
                  'We collect information to provide and improve our service. Personal information may be provided directly by you or collected automatically when you interact with our app. Examples include:',
                  style: theme.textTheme.bodyMedium,
                ),
                const _BulletList([
                  'Account information such as name, email address, phone number and password.',
                  'Shipping and billing addresses, payment details and transaction history.',
                  'Profile details like avatars, preferences and communication settings.',
                  'Device and usage information such as IP address, device identifiers, browser type, operating system, app usage statistics and log data.',
                  'Location information if you permit access to your device’s location services.',
                  'Information collected through cookies and similar technologies when you browse our in‑app web views or external links.',
                  'Information received from third‑party services such as payment processors or social login providers.',
                ]),
                const _SectionHeading('3. How We Use Information'),
                Text(
                  'We use the collected information to operate, maintain and improve Kartly’s services. Specifically, we use your information to:',
                  style: theme.textTheme.bodyMedium,
                ),
                const _BulletList([
                  'Create and manage your account, authenticate your identity and provide customer support.',
                  'Process orders, facilitate payments, arrange for shipping and deliver products to you.',
                  'Communicate with you about orders, updates, promotions and marketing offers (you can opt out of marketing at any time).',
                  'Personalise your experience by showing you products, content or promotions that may be relevant to your interests.',
                  'Monitor and analyse usage to understand how users interact with our app and to improve functionality and user experience.',
                  'Detect and prevent fraud or other illegal activities and enforce our legal terms.',
                  'Comply with legal obligations and respond to lawful requests from authorities.',
                ]),
                const _SectionHeading('4. How We Share Information'),
                Text(
                  'We may share your information with third parties in certain circumstances. We do not sell personal information. We share information only:',
                  style: theme.textTheme.bodyMedium,
                ),
                const _BulletList([
                  'With service providers who help us operate our business, such as payment processors, shipping carriers, analytics providers, marketing partners and customer support tools. These providers may process personal information on our behalf and are contractually required to protect it.',
                  'With vendors and business partners when necessary to complete transactions or provide services you have requested.',
                  'With affiliated companies or subsidiaries, provided they are bound by this Privacy Policy or comparable commitments.',
                  'With law enforcement agencies, regulators, courts or other third parties when we believe disclosure is necessary to comply with applicable law, regulation, legal process or governmental request.',
                  'In connection with a merger, sale, acquisition or other business transaction involving all or part of our company; your information may be transferred as part of that transaction, subject to confidentiality obligations.',
                ]),
                const _SectionHeading('5. Cookies and Tracking Technologies'),
                Text(
                  'We and our partners use cookies, pixels and similar technologies to recognise you and/or your device. Cookies help us remember your preferences, understand how you use our app and tailor content. You can control the use of cookies through your device settings; however, disabling cookies may limit certain features.',
                  style: theme.textTheme.bodyMedium,
                ),
                const _SectionHeading('6. Data Retention and Deletion'),
                Text(
                  'We retain personal information only for as long as necessary to fulfil the purposes outlined in this policy unless a longer retention period is required or permitted by law. When you request account deletion, we will delete your account and associated data, subject to limited exceptions (for example, to comply with legal obligations, fraud prevention or regulatory requirements)【974206023269784†L252-L266】. If data is retained for legitimate reasons after account deletion, we will inform you of our retention practices.',
                  style: theme.textTheme.bodyMedium,
                ),
                const _SectionHeading('7. Data Security'),
                Text(
                  'We implement reasonable technical and organisational safeguards to protect your information against unauthorised access, alteration, disclosure or destruction. These measures include encryption, secure servers, limited access to staff on a need‑to‑know basis and ongoing security reviews. Despite our efforts, no method of transmission or storage is completely secure; therefore we cannot guarantee absolute security.',
                  style: theme.textTheme.bodyMedium,
                ),
                const _SectionHeading('8. Your Rights and Choices'),
                Text(
                  'Depending on your location, you may have rights to access, correct, update, port or delete your personal information, or to object to certain processing. You can typically exercise these rights within the app via your account settings or by contacting us. You may opt out of marketing communications by following the instructions in those messages or adjusting your settings.',
                  style: theme.textTheme.bodyMedium,
                ),
                const _SectionHeading('9. Children’s Privacy'),
                Text(
                  'Our services are not directed to children under 13. We do not knowingly collect personal information from children. If we discover that a child under 13 has provided us with personal information, we will take steps to delete such data. Parents or guardians who believe that a child has provided us with personal information can contact us for deletion.',
                  style: theme.textTheme.bodyMedium,
                ),
                const _SectionHeading('10. Third‑Party Services and Links'),
                Text(
                  'Kartly may contain links to third‑party websites or services that are not operated by us. We are not responsible for the content or privacy practices of these third parties. We encourage you to review the privacy policies of every third‑party service you visit or use.',
                  style: theme.textTheme.bodyMedium,
                ),
                const _SectionHeading('11. Changes to This Privacy Policy'),
                Text(
                  'We may update this Privacy Policy from time to time to reflect changes in our practices, technologies or legal requirements. We will notify you of any material changes by posting the new policy in the app or via other appropriate channels. Your continued use of the app after the update constitutes your acceptance of the revised policy.',
                  style: theme.textTheme.bodyMedium,
                ),
                const _SectionHeading('12. Contact Us'),
                Text(
                  'If you have any questions, concerns or requests regarding this Privacy Policy or our data practices, please contact us at:\n\nEmail: support@kartly.app\nAddress: Kartly, Dhaka, Bangladesh\n',
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
