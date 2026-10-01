import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import '../utils/api_links.dart';

class InstagramException implements Exception {
  final String mensagem;
  const InstagramException(this.mensagem);
  @override
  String toString() => mensagem;
}

class InstagramProfile {
  final String username;
  final String fullName;
  final String biography;
  final String profilePicUrl;
  final int followers;
  final int following;
  final int posts;
  final bool isPrivate;
  final bool isVerified;
  final String? externalUrl;
  final List<InstagramPost> recentPosts;

  InstagramProfile({
    required this.username,
    required this.fullName,
    required this.biography,
    required this.profilePicUrl,
    required this.followers,
    required this.following,
    required this.posts,
    required this.isPrivate,
    required this.isVerified,
    this.externalUrl,
    this.recentPosts = const [],
  });

  factory InstagramProfile.fromJson(Map<String, dynamic> json) {
    final profileJson = (json['profile'] is Map)
        ? Map<String, dynamic>.from(json['profile'] as Map)
        : json;

    int readInt(List<String> keys) {
      for (final key in keys) {
        final value = profileJson[key];
        if (value is num) return value.toInt();
        if (value is String) return int.tryParse(value) ?? 0;
      }
      return 0;
    }

    String readString(List<String> keys) {
      for (final key in keys) {
        final value = profileJson[key];
        if (value != null) return value.toString();
      }
      return '';
    }

    bool readBool(List<String> keys) {
      for (final key in keys) {
        final value = profileJson[key];
        if (value is bool) return value;
        if (value is String) return value.toLowerCase() == 'true';
      }
      return false;
    }

    final postsJson = profileJson['recentPosts'] ?? profileJson['recent_posts'];
    final recentPosts = postsJson is List
        ? postsJson
            .whereType<Map>()
            .map((post) => InstagramPost.fromJson(Map<String, dynamic>.from(post)))
            .toList()
        : <InstagramPost>[];

    if (profileJson.containsKey('followers') ||
        profileJson.containsKey('seguidores') ||
        profileJson.containsKey('followersCount')) {
      return InstagramProfile(
        username: readString(['username']),
        fullName: readString(['fullName', 'full_name']),
        biography: readString(['biography', 'bio']),
        profilePicUrl: readString(['profilePicUrl', 'profile_pic_url', 'hd_profile_pic']),
        followers: readInt(['followers', 'seguidores', 'followersCount']),
        following: readInt(['following', 'seguindo', 'followingCount']),
        posts: readInt(['posts', 'postsCount']),
        isPrivate: readBool(['isPrivate', 'is_private']),
        isVerified: readBool(['isVerified', 'is_verified']),
        externalUrl: profileJson['externalUrl']?.toString() ?? profileJson['external_url']?.toString(),
        recentPosts: recentPosts,
      );
    }
    final user = profileJson['data']?['user'] ?? profileJson;
    final edgeFollowedBy = user['edge_followed_by'] ?? {};
    final edgeFollow = user['edge_follow'] ?? {};
    final edgeMedia = user['edge_owner_to_timeline_media'] ?? {};
    return InstagramProfile(
      username: user['username'] ?? '',
      fullName: user['full_name'] ?? '',
      biography: user['biography'] ?? '',
      profilePicUrl: user['profile_pic_url_hd'] ?? user['profile_pic_url'] ?? '',
      followers: edgeFollowedBy['count'] ?? 0,
      following: edgeFollow['count'] ?? 0,
      posts: edgeMedia['count'] ?? 0,
      isPrivate: user['is_private'] ?? false,
      isVerified: user['is_verified'] ?? false,
      externalUrl: user['external_url'],
    );
  }
}

class InstagramPost {
  final String id;
  final String displayUrl;
  final String? caption;
  final int likes;
  final int comments;
  final String timestamp;
  final bool isVideo;
  final String? videoUrl;

  InstagramPost({
    required this.id,
    required this.displayUrl,
    this.caption,
    required this.likes,
    required this.comments,
    required this.timestamp,
    required this.isVideo,
    this.videoUrl,
  });

  factory InstagramPost.fromJson(Map<String, dynamic> json) {
    if (json.containsKey('display_url')) {
      return InstagramPost(
        id: json['id'] ?? '',
        displayUrl: json['display_url'] ?? '',
        caption: json['caption'],
        likes: json['likes'] ?? 0,
        comments: json['comments'] ?? 0,
        timestamp: json['timestamp'] ?? '',
        isVideo: json['is_video'] ?? false,
        videoUrl: json['video_url'],
      );
    }
    final edgeLiked = json['edge_liked_by'] ?? json['edge_media_preview_like'] ?? {};
    final edgeComment = json['edge_media_to_comment'] ?? {};
    return InstagramPost(
      id: json['id'] ?? '',
      displayUrl: json['display_url'] ?? '',
      caption: json['edge_media_to_caption']?['edges']?.isNotEmpty == true
          ? json['edge_media_to_caption']['edges'][0]['node']['text']
          : json['accessibility_caption'] ?? '',
      likes: edgeLiked['count'] ?? 0,
      comments: edgeComment['count'] ?? 0,
      timestamp: json['taken_at_timestamp']?.toString() ?? '',
      isVideo: json['is_video'] ?? false,
      videoUrl: null,
    );
  }

  String get timeAgo {
    try {
      final dt = DateTime.parse(timestamp);
      final diff = DateTime.now().difference(dt);
      if (diff.inDays > 365) return '${(diff.inDays / 365).floor()}a';
      if (diff.inDays > 30) return '${(diff.inDays / 30).floor()}m';
      if (diff.inDays > 0) return '${diff.inDays}d';
      if (diff.inHours > 0) return '${diff.inHours}h';
      return '${diff.inMinutes}min';
    } catch (_) {
      return '';
    }
  }
}

class InstagramLiker {
  final String username;
  final String fullName;
  InstagramLiker({required this.username, required this.fullName});
  
  factory InstagramLiker.fromJson(Map<String, dynamic> json) {
    return InstagramLiker(
      username: json['username'] ?? '',
      fullName: json['full_name'] ?? '',
    );
  }
}

class TimelineEvent {
  final String type;
  final String username;
  final String fullName;
  final String date;
  final String? postId;
  final String? text;
  final int? likes;

  TimelineEvent({
    required this.type,
    required this.username,
    required this.fullName,
    required this.date,
    this.postId,
    this.text,
    this.likes,
  });

  factory TimelineEvent.fromJson(Map<String, dynamic> json) {
    return TimelineEvent(
      type: json['type'] ?? '',
      username: json['atorUsername'] ?? json['username'] ?? '',
      fullName: json['atorFullName'] ?? json['full_name'] ?? '',
      date: json['date'] ?? '',
      postId: json['post_id'],
      text: json['text'],
      likes: json['likes'],
    );
  }

  String get typeLabel {
    switch (type) {
      case 'new_follower': return 'Começou a seguir você';
      case 'unfollowed': return 'Deixou de seguir você';
      case 'you_followed': return 'Você começou a seguir';
      case 'unfollowed_by_you': return 'Você deixou de seguir';
      case 'liked_post': return 'Curtiu sua foto';
      case 'unliked_post': return 'Deixou de curtir sua foto';
      case 'comment': return 'Comentou';
      case 'bio_updated': return 'Bio atualizada';
      case 'followers_count': return 'Mudança de seguidores';
      case 'following_count': return 'Mudança de seguindo';
      case 'posts_count': return 'Mudança de posts';
      default: return type;
    }
  }

  String get emoji {
    switch (type) {
      case 'new_follower': return '\u{1F465}';
      case 'unfollowed': return '\u{1F6AB}';
      case 'you_followed': return '\u{1F464}';
      case 'unfollowed_by_you': return '\u{1F519}';
      case 'liked_post': return '\u{2764}\u{FE0F}';
      case 'unliked_post': return '\u{1F941}';
      case 'comment': return '\u{1F4AC}';
      case 'bio_updated': return '\u{1F4DD}';
      case 'followers_count': return '\u{1F465}';
      case 'following_count': return '\u{1F441}';
      case 'posts_count': return '\u{1F4F8}';
      default: return '\u{1F514}';
    }
  }

  DateTime? get dateTime {
    try {
      return DateTime.parse(date);
    } catch (_) {
      return null;
    }
  }

  String get timeAgo {
    final dt = dateTime;
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inDays > 365) return '${(diff.inDays / 365).floor()}a';
    if (diff.inDays > 30) return '${(diff.inDays / 30).floor()}m';
    if (diff.inDays > 0) return '${diff.inDays}d';
    if (diff.inHours > 0) return '${diff.inHours}h';
    if (diff.inMinutes > 0) return '${diff.inMinutes}min';
    return 'agora';
  }

  String get dateFormatted {
    final dt = dateTime;
    if (dt == null) return date;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final eventDay = DateTime(dt.year, dt.month, dt.day);
    final diff = today.difference(eventDay).inDays;
    String dayLabel;
    if (diff == 0) dayLabel = 'Hoje';
    else if (diff == 1) dayLabel = 'Ontem';
    else if (diff < 7) dayLabel = 'Ha $diff dias';
    else dayLabel = '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    return '$dayLabel \u{2022} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

class InstagramService {
  static const _defaultLocalApi = 'http://127.0.0.1:8500';
  static String _pythonApiUrl = _defaultLocalApi;
  static bool _localAvailable = false;

  // Base do backend Java (AppAcademia). Usa a mesma base canônica do app
  // (ApiLinks.baseUrl = $BACKEND_URL/boletobancos) — o context-path /boletobancos
  // é obrigatório, sem ele todos os endpoints Java retornam 404.
  static String get _backendUrl => ApiLinks.baseUrl;

  static bool shouldProbeLocalApi({
    required bool isWeb,
    required Uri appUri,
    required Uri apiUri,
  }) {
    if (!isWeb) return true;
    return !_isLoopbackHost(apiUri.host) || _isLoopbackHost(appUri.host);
  }

  static bool _isLoopbackHost(String host) {
    final normalized = host.toLowerCase();
    return normalized == 'localhost' ||
        normalized == '127.0.0.1' ||
        normalized == '::1';
  }

  static Future<void> checkLocalApi() async {
    try {
      final config = await fetchApiConfig();
      _pythonApiUrl = config?['python_server_url']?.trim() ?? _defaultLocalApi;
      final apiUri = Uri.tryParse(_pythonApiUrl);
      if (apiUri == null ||
          !shouldProbeLocalApi(
            isWeb: kIsWeb,
            appUri: Uri.base,
            apiUri: apiUri,
          )) {
        _localAvailable = false;
        return;
      }
      final r = await http
          .get(apiUri.resolve('/health'))
          .timeout(const Duration(seconds: 2));
      _localAvailable = r.statusCode == 200;
    } catch (_) {
      _localAvailable = false;
    }
  }

  static bool get hasLocalApi => _localAvailable;

  /// Retorna perfil ou lança [InstagramException] com mensagem específica.
  static Future<InstagramProfile?> fetchProfile(String username) async {
    final clean = username.replaceAll('@', '').trim();
    if (clean.isEmpty) return null;

    try {
      final r = await http.get(
        Uri.parse('$_backendUrl/api/instagram/perfis/${Uri.encodeComponent(clean)}'),
        headers: await AuthService().jsonHeaders(),
      ).timeout(const Duration(seconds: 15));

      if (r.statusCode == 200) {
        final data = json.decode(r.body) as Map<String, dynamic>;
        return InstagramProfile.fromJson(data);
      }

      if (r.statusCode == 404) {
        throw InstagramException('Perfil @$clean nao encontrado. Verifique o nome ou as credenciais RapidAPI.');
      }

      if (r.statusCode == 401 || r.statusCode == 403) {
        throw const InstagramException('Sessao expirada ou sem permissao para consultar o Instagram Monitor.');
      }
    } on InstagramException {
      rethrow;
    } catch (_) {
      throw const InstagramException('Nao foi possivel consultar o perfil no backend. Verifique sua conexao e tente novamente.');
    }
    return null;
  }

  static final InstagramException notFound = InstagramException('Perfil nao encontrado ou privado');

  static Future<List<InstagramPost>> fetchPosts(String username, {int amount = 12}) async {
    if (_localAvailable) {
      try {
        final r = await http.get(Uri.parse('$_pythonApiUrl/posts?username=$username&amount=$amount')).timeout(const Duration(seconds: 20));
        if (r.statusCode == 200) {
          final data = json.decode(r.body);
          if (data.containsKey('posts')) {
            return (data['posts'] as List).map((p) => InstagramPost.fromJson(p)).toList();
          }
        }
      } catch (_) {}
    }
    return [];
  }

  static Future<List<InstagramPost>> fetchPostsFromDb(String username) async {
    final clean = username.replaceAll('@', '').trim();
    if (clean.isEmpty) return [];
    try {
      final r = await http.get(
        Uri.parse('$_backendUrl/api/instagram/posts/${Uri.encodeComponent(clean)}'),
        headers: await AuthService().jsonHeaders(),
      ).timeout(const Duration(seconds: 15));
      if (r.statusCode == 200) {
        final data = json.decode(r.body);
        if (data is List) {
          return data
              .whereType<Map>()
              .map((post) => InstagramPost.fromJson(Map<String, dynamic>.from(post)))
              .toList();
        }
      }
    } catch (_) {}
    return [];
  }

  static Future<List<InstagramLiker>> fetchLikers(String mediaId) async {
    if (!_localAvailable) return [];
    try {
      final r = await http.get(Uri.parse('$_pythonApiUrl/likers?media_id=$mediaId')).timeout(const Duration(seconds: 15));
      if (r.statusCode == 200) {
        final data = json.decode(r.body);
        if (data.containsKey('likers')) {
          return (data['likers'] as List).map((l) => InstagramLiker.fromJson(l)).toList();
        }
      }
    } catch (_) {}
    return [];
  }

  static Future<List<InstagramLiker>> fetchFollowers(String username, {int amount = 5000}) async {
    if (!_localAvailable) return [];
    try {
      final r = await http.get(Uri.parse('$_pythonApiUrl/followers?username=$username&amount=$amount')).timeout(const Duration(seconds: 90));
      if (r.statusCode == 200) {
        final data = json.decode(r.body);
        if (data.containsKey('followers')) {
          return (data['followers'] as List).map((f) => InstagramLiker.fromJson(f)).toList();
        }
      }
    } catch (_) {}
    return [];
  }

  static Future<List<InstagramLiker>> fetchFollowing(String username, {int amount = 5000}) async {
    if (!_localAvailable) return [];
    try {
      final r = await http.get(Uri.parse('$_pythonApiUrl/following?username=$username&amount=$amount')).timeout(const Duration(seconds: 90));
      if (r.statusCode == 200) {
        final data = json.decode(r.body);
        if (data.containsKey('following')) {
          return (data['following'] as List).map((f) => InstagramLiker.fromJson(f)).toList();
        }
      }
    } catch (_) {}
    return [];
  }

  static String formatCount(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
    return count.toString();
  }

  static Future<bool> untrackProfile(int id) async {
    try {
      final r = await http.delete(
        Uri.parse('$_backendUrl/api/instagram/tracked/$id'),
        headers: await AuthService().jsonHeaders(),
      ).timeout(const Duration(seconds: 10));
      return r.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> trackProfile(String username, {String fullName = '', String profilePicUrl = ''}) async {
    try {
      final r = await http.post(
        Uri.parse('$_backendUrl/api/instagram/track'),
        headers: await AuthService().jsonHeaders(),
        body: json.encode({
          'username': username,
          'fullName': fullName,
          'profilePicUrl': profilePicUrl,
        }),
      ).timeout(const Duration(seconds: 10));
      return r.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static Future<Map<String, dynamic>?> takeSnapshot(String username) async {
    if (!_localAvailable) return null;

    final followers = await fetchFollowers(username);
    final following = await fetchFollowing(username);

    final followerData = followers.map((f) => {'username': f.username, 'full_name': f.fullName}).toList();
    final followingData = following.map((f) => {'username': f.username, 'full_name': f.fullName}).toList();

    final posts = await fetchPosts(username, amount: 12);
    final postLikes = <String, List<Map<String, String>>>{};
    for (final post in posts) {
      final likers = await fetchLikers(post.id);
      postLikes[post.id] = likers.map((l) => {'username': l.username, 'full_name': l.fullName}).toList();
    }

    try {
      await http.post(
        Uri.parse('$_backendUrl/api/instagram/snapshot'),
        headers: await AuthService().jsonHeaders(),
        body: json.encode({
          'username': username,
          'snapshotType': 'followers',
          'data': json.encode(followerData),
        }),
      ).timeout(const Duration(seconds: 30));

      await http.post(
        Uri.parse('$_backendUrl/api/instagram/snapshot'),
        headers: await AuthService().jsonHeaders(),
        body: json.encode({
          'username': username,
          'snapshotType': 'following',
          'data': json.encode(followingData),
        }),
      ).timeout(const Duration(seconds: 30));

      await http.post(
        Uri.parse('$_backendUrl/api/instagram/snapshot'),
        headers: await AuthService().jsonHeaders(),
        body: json.encode({
          'username': username,
          'snapshotType': 'post_likes',
          'data': json.encode(postLikes),
        }),
      ).timeout(const Duration(seconds: 30));

      return {
        'followers': followerData.length,
        'following': followingData.length,
        'posts_liked': postLikes.length,
      };
    } catch (_) {
      return null;
    }
  }

  static Future<Map<String, dynamic>> fetchTimelinePaginado(
      String username, {int page = 0, int size = 100}) async {
    try {
      final r = await http.get(
        Uri.parse('$_backendUrl/api/instagram/timeline/$username?page=$page&size=$size'),
        headers: await AuthService().jsonHeaders(),
      ).timeout(const Duration(seconds: 20));
      if (r.statusCode == 200) {
        final data = json.decode(r.body) as Map<String, dynamic>;
        final eventos = (data['events'] as List? ?? [])
            .map((e) => TimelineEvent.fromJson(e))
            .toList();
        return {
          'events': eventos,
          'total': data['total'] ?? 0,
          'hasMore': data['hasMore'] ?? false,
          'page': data['page'] ?? page,
        };
      }
    } catch (_) {}
    return {'events': <TimelineEvent>[], 'total': 0, 'hasMore': false, 'page': page};
  }

  /// Lista os usuarios de uma relacao do dashboard.
  /// tipo: 'mutuos' | 'sigo_nao_me_segue' | 'me_segue_nao_sigo'.
  static Future<List<InstagramLiker>> fetchRelacaoDashboard(String username, String tipo) async {
    try {
      final r = await http.get(
        Uri.parse('$_backendUrl/api/instagram/dashboard/$username/relacao?tipo=$tipo'),
        headers: await AuthService().jsonHeaders(),
      ).timeout(const Duration(seconds: 20));
      if (r.statusCode == 200) {
        final data = json.decode(r.body);
        return (data['itens'] as List? ?? [])
            .map((e) => InstagramLiker(username: e['username'] ?? '', fullName: e['fullName'] ?? ''))
            .toList();
      }
    } catch (_) {}
    return [];
  }

  /// Resumo do dashboard: relacoes atuais + serie temporal de seguidores/seguindo.
  static Future<Map<String, dynamic>> fetchDashboard(String username) async {
    try {
      final r = await http.get(
        Uri.parse('$_backendUrl/api/instagram/dashboard/$username'),
        headers: await AuthService().jsonHeaders(),
      ).timeout(const Duration(seconds: 20));
      if (r.statusCode == 200) {
        return json.decode(r.body) as Map<String, dynamic>;
      }
    } catch (_) {}
    return {};
  }

  static Future<List<TimelineEvent>> fetchTimeline(String username, {int days = 30}) async {
    try {
      final r = await http.get(
        Uri.parse('$_backendUrl/api/instagram/timeline/$username'),
        headers: await AuthService().jsonHeaders(),
      ).timeout(const Duration(seconds: 15));
      if (r.statusCode == 200) {
        final data = json.decode(r.body);
        if (data.containsKey('events')) {
          return (data['events'] as List).map((e) => TimelineEvent.fromJson(e)).toList();
        }
      }
    } catch (_) {}
    return [];
  }

  static Future<List<Map<String, dynamic>>> fetchTrackedProfiles() async {
    try {
      final r = await http.get(
        Uri.parse('$_backendUrl/api/instagram/tracked'),
        headers: await AuthService().jsonHeaders(),
      ).timeout(const Duration(seconds: 10));
      if (r.statusCode == 200) {
        final data = json.decode(r.body);
        if (data.containsKey('profiles')) {
          return List<Map<String, dynamic>>.from(data['profiles']);
        }
      }
    } catch (_) {}
    return [];
  }

  /// Retorna o histórico unificado de ações para o username monitorado.
  /// Endpoint: GET /api/instagram/historico/{username}?page=0&size=50
  static Future<Map<String, dynamic>> fetchHistorico(
      String username, {int page = 0, int size = 50}) async {
    try {
      final r = await http.get(
        Uri.parse('$_backendUrl/api/instagram/historico/${Uri.encodeComponent(username)}?page=$page&size=$size'),
        headers: await AuthService().jsonHeaders(),
      ).timeout(const Duration(seconds: 20));
      if (r.statusCode == 200) {
        return json.decode(r.body) as Map<String, dynamic>;
      }
    } catch (_) {}
    return {'items': <dynamic>[], 'total': 0, 'page': page, 'size': size, 'hasMore': false};
  }

  static Future<List<Map<String, dynamic>>> fetchChangeLogs(String username) async {
    try {
      final r = await http.get(
        Uri.parse('$_backendUrl/api/instagram/change-logs/$username'),
        headers: await AuthService().jsonHeaders(),
      ).timeout(const Duration(seconds: 15));
      if (r.statusCode == 200) {
        final data = json.decode(r.body);
        if (data.containsKey('logs')) {
          return List<Map<String, dynamic>>.from(data['logs']);
        }
      }
    } catch (_) {}
    return [];
  }

  static Future<List<InstagramLiker>> fetchFollowersFromDb(String username) async {
    try {
      final r = await http.get(
        Uri.parse('$_backendUrl/api/instagram/followers/$username'),
        headers: await AuthService().jsonHeaders(),
      ).timeout(const Duration(seconds: 15));
      if (r.statusCode == 200) {
        final data = json.decode(r.body);
        if (data.containsKey('followers')) {
          return (data['followers'] as List)
              .map((f) => InstagramLiker(username: f['username'] ?? '', fullName: f['fullName'] ?? ''))
              .toList();
        }
      }
    } catch (_) {}
    return [];
  }

  static Future<List<InstagramLiker>> fetchFollowingFromDb(String username) async {
    try {
      final r = await http.get(
        Uri.parse('$_backendUrl/api/instagram/following/$username'),
        headers: await AuthService().jsonHeaders(),
      ).timeout(const Duration(seconds: 15));
      if (r.statusCode == 200) {
        final data = json.decode(r.body);
        if (data.containsKey('following')) {
          return (data['following'] as List)
              .map((f) => InstagramLiker(username: f['username'] ?? '', fullName: f['fullName'] ?? ''))
              .toList();
        }
      }
    } catch (_) {}
    return [];
  }

  /// Retorna lista com última execução de cada job do monitor.
  static Future<List<Map<String, dynamic>>?> fetchJobsStatus() async {
    try {
      final r = await http.get(
        Uri.parse('$_backendUrl/api/admin/jobs'),
        headers: await AuthService().jsonHeaders(),
      ).timeout(const Duration(seconds: 10));
      if (r.statusCode == 200) {
        final data = json.decode(r.body);
        return List<Map<String, dynamic>>.from(data);
      }
    } catch (_) {}
    return null;
  }

  /// Apaga o histórico de Timeline (instagram_event) de um perfil monitorado.
  static Future<bool> limparTimeline(String username) async {
    try {
      final r = await http.delete(
        Uri.parse('$_backendUrl/api/instagram/timeline/${Uri.encodeComponent(username)}'),
        headers: await AuthService().jsonHeaders(),
      ).timeout(const Duration(seconds: 15));
      return r.statusCode == 204 || r.statusCode == 200;
    } catch (_) {}
    return false;
  }

  /// Apaga o histórico de Change Logs (instagram_change_log) de um perfil monitorado.
  static Future<bool> limparChangeLogs(String username) async {
    try {
      final r = await http.delete(
        Uri.parse('$_backendUrl/api/instagram/change-logs/${Uri.encodeComponent(username)}'),
        headers: await AuthService().jsonHeaders(),
      ).timeout(const Duration(seconds: 15));
      return r.statusCode == 204 || r.statusCode == 200;
    } catch (_) {}
    return false;
  }

  /// Retorna curtidas e comentários detectados para o username monitorado.
  static Future<Map<String, dynamic>?> fetchInteracoes(String username, {int limit = 20}) async {
    try {
      final r = await http.get(
        Uri.parse('$_backendUrl/api/instagram/interacoes?username=${Uri.encodeComponent(username)}&limit=$limit'),
        headers: await AuthService().jsonHeaders(),
      ).timeout(const Duration(seconds: 15));
      if (r.statusCode == 200) {
        return json.decode(r.body) as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }

  /// Carrega configurações de API (rapidapi_key, python_server_url) do backend Java.
  static Future<Map<String, String>?> fetchApiConfig() async {
    try {
      final r = await http.get(
        Uri.parse('$_backendUrl/api/instagram/config'),
        headers: await AuthService().jsonHeaders(),
      ).timeout(const Duration(seconds: 10));
      if (r.statusCode == 200) {
        final data = json.decode(r.body) as Map<String, dynamic>;
        return data.map((k, v) => MapEntry(k, v?.toString() ?? ''));
      }
    } catch (_) {}
    return null;
  }

  /// Salva configurações de API no backend Java.
  static Future<bool> saveApiConfig(Map<String, String> config) async {
    try {
      final headers = await AuthService().jsonHeaders();
      final r = await http.put(
        Uri.parse('$_backendUrl/api/instagram/config'),
        headers: {...headers, 'Content-Type': 'application/json'},
        body: json.encode(config),
      ).timeout(const Duration(seconds: 10));
      return r.statusCode == 200;
    } catch (_) {}
    return false;
  }

  /// Status do pool de sessões no servidor Python local (total, ativa, labels).
  static Future<Map<String, dynamic>?> fetchSessionsStatus() async {
    try {
      final r = await http.get(Uri.parse('$_pythonApiUrl/sessions'))
          .timeout(const Duration(seconds: 5));
      if (r.statusCode == 200) return json.decode(r.body) as Map<String, dynamic>;
    } catch (_) {}
    return null;
  }

  /// Remove uma sessão do pool pelo apelido. Retorna true se removida.
  static Future<bool> deleteSession(String label) async {
    try {
      final r = await http.delete(
        Uri.parse('$_pythonApiUrl/sessions/${Uri.encodeComponent(label)}'),
      ).timeout(const Duration(seconds: 5));
      return r.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Salva o pool de sessões (1+ contas) no servidor Python local.
  /// Cada item: {'label': ..., 'sessionid': ...}. Retorna o total salvo, ou null em falha.
  static Future<int?> saveSessions(List<Map<String, String>> sessoes) async {
    try {
      final r = await http.post(
        Uri.parse('$_pythonApiUrl/sessions'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'sessions': sessoes}),
      ).timeout(const Duration(seconds: 15));
      if (r.statusCode == 200) {
        final data = json.decode(r.body);
        return data['total'] as int?;
      }
    } catch (_) {}
    return null;
  }
}

extension _ProfileCopy on InstagramProfile {
  InstagramProfile copyWith({List<InstagramPost>? posts}) {
    return InstagramProfile(
      username: username,
      fullName: fullName,
      biography: biography,
      profilePicUrl: profilePicUrl,
      followers: followers,
      following: following,
      posts: posts?.length ?? this.posts,
      isPrivate: isPrivate,
      isVerified: isVerified,
      externalUrl: externalUrl,
      recentPosts: posts ?? recentPosts,
    );
  }
}
