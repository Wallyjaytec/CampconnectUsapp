import '../../../core/config/app_config.dart';

String normalizeUrl(String? raw) {
  final u = (raw ?? '').trim();
  if (u.isEmpty) return '';
  if (u.startsWith('http://') || u.startsWith('https://')) return u;
  if (u.startsWith('/')) return AppConfig.assetUrl(u);
  return u;
}

bool isYouTubeUrl(String url) {
  final u = url.toLowerCase();
  return u.contains('youtube.com/') || u.contains('youtu.be/');
}

String? extractYouTubeId(String url) {
  final patterns = <RegExp>[
    RegExp(r'[?&]v=([0-9A-Za-z_-]{11})'),
    RegExp(r'youtu\.be/([0-9A-Za-z_-]{11})'),
    RegExp(r'embed/([0-9A-Za-z_-]{11})'),
    RegExp(r'shorts/([0-9A-Za-z_-]{11})'),
  ];
  for (final re in patterns) {
    final m = re.firstMatch(url);
    if (m != null && m.groupCount >= 1) return m.group(1);
  }
  return null;
}

String youtubeThumb(String id) =>
    'https://img.youtube.com/vi/$id/hqdefault.jpg';

class MediaItem {
  final bool isVideo;
  final String url;
  final String? videoId;
  final String? thumb;

  MediaItem.image(this.url) : isVideo = false, videoId = null, thumb = null;

  MediaItem.youtube({
    required this.url,
    required this.videoId,
    required this.thumb,
  }) : isVideo = true;
}
