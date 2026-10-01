import 'package:flutter/material.dart';
import 'dart:async';
import '../../services/instagram_service.dart';

class MatchScreen extends StatefulWidget {
  const MatchScreen({super.key});

  @override
  State<MatchScreen> createState() => _MatchScreenState();
}

class _MatchScreenState extends State<MatchScreen> with SingleTickerProviderStateMixin {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  InstagramProfile? _profile;
  bool _loading = false;
  String? _error;
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  bool _localApiStatus = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnimation = CurvedAnimation(parent: _animController, curve: Curves.easeInOut);
    _checkLocalApi();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _checkLocalApi() async {
    await InstagramService.checkLocalApi();
    if (mounted) setState(() => _localApiStatus = InstagramService.hasLocalApi);
  }

  Future<void> _search() async {
    final username = _controller.text.trim();
    if (username.isEmpty) return;

    setState(() {
      _loading = true;
      _error = null;
      _profile = null;
    });

    _animController.reset();

    final profile = await InstagramService.fetchProfile(username);
    List<InstagramPost> posts = [];
    if (profile != null) {
      posts = await InstagramService.fetchPosts(username);
    }

    if (mounted) {
      setState(() {
        _loading = false;
        if (profile != null) {
          _profile = InstagramProfile(
            username: profile.username,
            fullName: profile.fullName,
            biography: profile.biography,
            profilePicUrl: profile.profilePicUrl,
            followers: profile.followers,
            following: profile.following,
            posts: profile.posts,
            isPrivate: profile.isPrivate,
            isVerified: profile.isVerified,
            externalUrl: profile.externalUrl,
            recentPosts: posts.isNotEmpty ? posts : profile.recentPosts,
          );
          _animController.forward();
        } else {
          _error = 'Perfil nao encontrado ou privado';
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F8),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFFE1306C)))
                : _error != null
                    ? _buildError()
                    : _profile != null
                        ? _buildProfile()
                        : _buildEmpty(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF833AB4), Color(0xFFE1306C), Color(0xFFF77737)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_graph, color: Colors.white, size: 28),
              const SizedBox(width: 10),
              const Text(
                'MATCH',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 3,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _localApiStatus ? Colors.green.withValues(alpha: 0.3) : Colors.white24,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.circle, size: 8, color: _localApiStatus ? Colors.greenAccent : Colors.orange),
                    const SizedBox(width: 4),
                    Text(
                      _localApiStatus ? 'API Local' : 'Publico',
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  ],
                ),
              ),
              if (_profile != null) ...[
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  onPressed: _search,
                  tooltip: 'Atualizar',
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Monitoramento de perfis Instagram',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              onSubmitted: (_) => _search(),
              style: const TextStyle(fontSize: 15),
              decoration: InputDecoration(
                hintText: 'Digite o @ do Instagram',
                hintStyle: TextStyle(color: Colors.grey[400]),
                prefixIcon: const Icon(Icons.search, color: Color(0xFFE1306C)),
                suffixIcon: _controller.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 20),
                        onPressed: () {
                          _controller.clear();
                          setState(() {});
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.camera_alt_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text('Digite um @ para monitorar', style: TextStyle(fontSize: 16, color: Colors.grey[400])),
          const SizedBox(height: 8),
          Text('Visualize posts, seguidores e estatisticas', style: TextStyle(fontSize: 13, color: Colors.grey[400])),
          if (!_localApiStatus) ...[
            const SizedBox(height: 24),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 40),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
              ),
              child: Column(
                children: [
                  const Icon(Icons.info_outline, color: Colors.orange, size: 24),
                  const SizedBox(height: 8),
                  const Text(
                    'Modo Limitado',
                    style: TextStyle(fontWeight: FontWeight.w700, color: Colors.orange),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Para ver quem curtiu e listas completas, inicie o servidor local:\npython instagram_api/server.py',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 60, color: Color(0xFFE1306C)),
          const SizedBox(height: 16),
          Text(_error!, style: const TextStyle(fontSize: 15, color: Colors.grey)),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _search,
            icon: const Icon(Icons.refresh),
            label: const Text('Tentar novamente'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE1306C),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfile() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildProfileCard(),
            const SizedBox(height: 16),
            _buildStatsRow(),
            const SizedBox(height: 16),
            _buildQuickActions(),
            const SizedBox(height: 20),
            _buildPostsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 15, offset: const Offset(0, 5)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(colors: [Color(0xFF833AB4), Color(0xFFE1306C), Color(0xFFF77737)]),
                boxShadow: [BoxShadow(color: const Color(0xFFE1306C).withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 8))],
              ),
              padding: const EdgeInsets.all(3),
              child: CircleAvatar(
                radius: 45,
                backgroundColor: Colors.white,
                child: CircleAvatar(
                  radius: 42,
                  backgroundImage: _profile!.profilePicUrl.isNotEmpty ? NetworkImage(_profile!.profilePicUrl) : null,
                  child: _profile!.profilePicUrl.isEmpty ? const Icon(Icons.person, size: 40, color: Colors.grey) : null,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('@${_profile!.username}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF262626))),
                if (_profile!.isVerified) ...[
                  const SizedBox(width: 6),
                  const Icon(Icons.verified, color: Color(0xFF3897F0), size: 20),
                ],
              ],
            ),
            if (_profile!.fullName.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(_profile!.fullName, style: const TextStyle(fontSize: 14, color: Colors.grey)),
            ],
            if (_profile!.biography.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(12)),
                child: Text(_profile!.biography, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, color: Color(0xFF262626), height: 1.4)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        _buildStatCard('Posts', InstagramService.formatCount(_profile!.posts), Icons.grid_on_rounded, const Color(0xFF833AB4)),
        _buildStatCard('Seguidores', InstagramService.formatCount(_profile!.followers), Icons.people_alt_rounded, const Color(0xFFE1306C)),
        _buildStatCard('Seguindo', InstagramService.formatCount(_profile!.following), Icons.person_add_rounded, const Color(0xFFF77737)),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: color.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 3))],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: color)),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    if (!_localApiStatus) return const SizedBox.shrink();
    return Row(
      children: [
        _buildActionChip(Icons.people, 'Ver Seguidores', const Color(0xFFE1306C), () => _showList('followers')),
        const SizedBox(width: 8),
        _buildActionChip(Icons.person_add, 'Ver Seguindo', const Color(0xFFF77737), () => _showList('following')),
      ],
    );
  }

  Widget _buildActionChip(IconData icon, String label, Color color, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 6),
              Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPostsSection() {
    final posts = _profile!.recentPosts;
    if (posts.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
        child: Column(
          children: [
            Icon(Icons.photo_library_outlined, size: 50, color: Colors.grey[300]),
            const SizedBox(height: 12),
            Text(_profile!.isPrivate ? 'Conta privada' : 'Nenhum post encontrado', style: TextStyle(color: Colors.grey[400], fontSize: 14)),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            children: [
              const Icon(Icons.grid_on_rounded, size: 18, color: Color(0xFF262626)),
              const SizedBox(width: 8),
              Text('Posts recentes (${posts.length})', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF262626))),
            ],
          ),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 3, mainAxisSpacing: 3),
          itemCount: posts.length,
          itemBuilder: (context, index) => _buildPostCard(posts[index]),
        ),
      ],
    );
  }

  Widget _buildPostCard(InstagramPost post) {
    return GestureDetector(
      onTap: () => _showPostDetail(post),
      child: Container(
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(4), color: Colors.grey[200]),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (post.displayUrl.isNotEmpty)
              Image.network(post.displayUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(
                color: Colors.grey[300],
                child: const Icon(Icons.broken_image, color: Colors.grey),
              )),
            if (post.isVideo)
              Positioned(
                top: 6, right: 6,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(4)),
                  child: const Icon(Icons.videocam, color: Colors.white, size: 14),
                ),
              ),
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [Colors.black87, Colors.black26], begin: Alignment.bottomCenter, end: Alignment.topCenter),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.favorite, color: Colors.white, size: 14),
                    const SizedBox(width: 4),
                    Text(InstagramService.formatCount(post.likes), style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                    const SizedBox(width: 12),
                    const Icon(Icons.chat_bubble, color: Colors.white, size: 14),
                    const SizedBox(width: 4),
                    Text(InstagramService.formatCount(post.comments), style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showList(String type) async {
    if (_profile == null) return;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  type == 'followers' ? 'Seguidores' : 'Seguindo',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
              ),
              Expanded(
                child: FutureBuilder<List<InstagramLiker>>(
                  future: type == 'followers'
                      ? InstagramService.fetchFollowers(_profile!.username)
                      : InstagramService.fetchFollowing(_profile!.username),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: Color(0xFFE1306C)));
                    }
                    if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.lock_outline, size: 40, color: Colors.grey),
                            SizedBox(height: 12),
                            Text('Servidor local indisponivel', style: TextStyle(color: Colors.grey)),
                            Text('Inicie: python instagram_api/server.py', style: TextStyle(color: Colors.grey, fontSize: 12)),
                          ],
                        ),
                      );
                    }
                    final list = snapshot.data!;
                    return ListView.builder(
                      controller: scrollController,
                      itemCount: list.length,
                      itemBuilder: (context, index) {
                        final user = list[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: const Color(0xFFE1306C).withValues(alpha: 0.1),
                            child: Text(user.username[0].toUpperCase(), style: const TextStyle(color: Color(0xFFE1306C), fontWeight: FontWeight.w700)),
                          ),
                          title: Text('@${user.username}', style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: user.fullName.isNotEmpty ? Text(user.fullName, style: const TextStyle(fontSize: 12)) : null,
                          trailing: IconButton(
                            icon: const Icon(Icons.open_in_new, size: 18),
                            onPressed: () {},
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPostDetail(InstagramPost post) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (post.displayUrl.isNotEmpty)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(post.displayUrl, fit: BoxFit.contain, errorBuilder: (_, __, ___) => Container(
                          height: 300,
                          color: Colors.grey[200],
                          child: const Center(child: Icon(Icons.broken_image, size: 50)),
                        )),
                      ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _buildDetailStat(Icons.favorite, '${post.likes} curtidas', const Color(0xFFE1306C)),
                        const SizedBox(width: 20),
                        _buildDetailStat(Icons.chat_bubble, '${post.comments} comentarios', const Color(0xFF3897F0)),
                      ],
                    ),
                    if (post.timeAgo.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(post.timeAgo, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                    ],
                    if (post.caption != null && post.caption!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      const Divider(),
                      const SizedBox(height: 8),
                      Text(post.caption!, style: const TextStyle(fontSize: 13, height: 1.5)),
                    ],
                    if (_localApiStatus) ...[
                      const SizedBox(height: 16),
                      const Divider(),
                      _buildLikersSection(post),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLikersSection(InstagramPost post) {
    return FutureBuilder<List<InstagramLiker>>(
      future: InstagramService.fetchLikers(post.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator(color: Color(0xFFE1306C))),
          );
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }
        final likers = snapshot.data!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.people, size: 18, color: Color(0xFFE1306C)),
                const SizedBox(width: 8),
                Text('Quem curtiu (${likers.length})', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: likers.map((l) => Chip(
                avatar: CircleAvatar(
                  backgroundColor: const Color(0xFFE1306C).withValues(alpha: 0.1),
                  child: Text(l.username[0].toUpperCase(), style: const TextStyle(fontSize: 12, color: Color(0xFFE1306C))),
                ),
                label: Text('@${l.username}', style: const TextStyle(fontSize: 12)),
                backgroundColor: Colors.grey[100],
              )).toList(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailStat(IconData icon, String text, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
