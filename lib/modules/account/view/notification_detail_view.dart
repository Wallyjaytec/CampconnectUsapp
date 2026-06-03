import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:html/parser.dart' as html_parser;
import '../../../core/constants/app_colors.dart';
import '../../../data/repositories/notification_repository.dart';
import '../../../shared/widgets/back_icon_widget.dart';
import '../model/notification_model.dart';

class NotificationDetailView extends StatefulWidget {
  final NotificationItem item;
  final String? notificationId;

  const NotificationDetailView({
    super.key,
    required this.item,
    this.notificationId,
  });

  @override
  State<NotificationDetailView> createState() => _NotificationDetailViewState();
}

class _NotificationDetailViewState extends State<NotificationDetailView> {
  late NotificationItem _item;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _item = widget.item;
    if (widget.notificationId != null && widget.notificationId!.isNotEmpty) {
      _loadFromApi();
    }
  }

  Future<void> _loadFromApi() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final repo = NotificationRepository();
      final fetched = await repo.fetchNotificationById(widget.notificationId!);
      if (mounted) {
        setState(() {
          if (fetched != null) {
            _item = fetched;
          } else {
            _error = 'Notification not found'.tr;
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load notification'.tr;
          _isLoading = false;
        });
      }
    }
  }

  String _translateMessage(String msg) {
    if (msg.isEmpty) return msg;
    
    final full = msg.tr;
    if (full != msg) return full;
    
    if (msg.contains('Contact:')) {
      final parts = msg.split('Contact:');
      final translated = '${'Your package has been handed over to a local driver. Contact:'.tr} ${parts.last.trim()}';
      return translated;
    }
    
    if (msg.contains('credited to your wallet')) {
      final parts = msg.split('credited to your wallet');
      final amount = parts.first.trim();
      return '$amount ${'credited to your wallet'.tr}';
    }
    
    if (msg.contains('debited from your wallet')) {
      final parts = msg.split('debited from your wallet');
      final amount = parts.first.trim();
      return '$amount ${'debited from your wallet'.tr}';
    }
    
    return msg;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leadingWidth: 44,
        leading: const BackIconWidget(),
        title: Text(
          'Notification Details'.tr,
          style: const TextStyle(fontWeight: FontWeight.normal, fontSize: 18),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
                      const SizedBox(height: 16),
                      Text(_error!),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadFromApi,
                        child: Text('Retry'.tr),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_item.title != null && _item.title!.isNotEmpty)
                        Text(
                          _item.title!.tr,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                      if (_item.title != null && _item.title!.isNotEmpty)
                        const SizedBox(height: 10),
                      if (_item.image != null && _item.image!.isNotEmpty)
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 20),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: isDark ? Colors.grey[800] : Colors.grey[200],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: CachedNetworkImage(
                              imageUrl: _item.image!,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                height: 200,
                                child: const Center(child: CircularProgressIndicator()),
                              ),
                              errorWidget: (context, url, error) => Container(
                                height: 200,
                                child: const Icon(Icons.broken_image, size: 50),
                              ),
                            ),
                          ),
                        ),
                      Text(
                        _translateMessage(_htmlToPlainText(_item.message)),
                        style: TextStyle(
                          fontSize: 16,
                          height: 1.5,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        _item.time,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.grey[500] : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  String _htmlToPlainText(String htmlString) {
    final doc = html_parser.parse(htmlString);
    return doc.body?.text ?? htmlString;
  }
}
