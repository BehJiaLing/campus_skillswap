import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminAuditTrackPage extends StatefulWidget {
  const AdminAuditTrackPage({super.key});

  @override
  State<AdminAuditTrackPage> createState() => _AdminAuditTrackPageState();
}

class _AdminAuditTrackPageState extends State<AdminAuditTrackPage> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchText = '';

  final Color navy = const Color(0xFF1A1F5E);
  final Color bg = const Color(0xFFF5F5FA);
  final Color border = const Color(0xFFE0E0F0);
  final Color green = const Color(0xFF4CAF50);
  final Color red = const Color(0xFFE53935);
  final Color purple = const Color(0xFFE8E4F8);
  final Color purpleDeep = const Color(0xFF7C5CBF);

  @override
  void initState() {
    super.initState();

    _searchCtrl.addListener(() {
      setState(() {
        _searchText = _searchCtrl.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  String _text(dynamic value, {String fallback = '-'}) {
    if (value == null) return fallback;

    final text = value.toString().trim();

    if (text.isEmpty) return fallback;

    return text;
  }

  String _formatDate(dynamic value) {
    if (value == null) return '-';

    if (value is Timestamp) {
      final date = value.toDate();

      final day = date.day.toString().padLeft(2, '0');
      final month = date.month.toString().padLeft(2, '0');
      final year = date.year.toString();

      final hour = date.hour.toString().padLeft(2, '0');
      final minute = date.minute.toString().padLeft(2, '0');

      return '$day/$month/$year $hour:$minute';
    }

    return value.toString();
  }

  bool _matchesSearch(Map<String, dynamic> data) {
    final name = _text(data['deletedUserName']).toLowerCase();
    final email = _text(data['deletedUserEmail']).toLowerCase();
    final deletedBy = _text(data['deletedByEmail']).toLowerCase();

    return name.contains(_searchText) ||
        email.contains(_searchText) ||
        deletedBy.contains(_searchText);
  }

  Widget _deletedUserCard(Map<String, dynamic> data) {
    final name = _text(data['deletedUserName'], fallback: 'No Name');
    final email = _text(data['deletedUserEmail'], fallback: 'No Email');
    final course = _text(data['deletedUserCourse'], fallback: 'No course');
    final skills = _text(data['deletedUserSkills'], fallback: 'No skills');
    final deletedBy = _text(data['deletedByEmail'], fallback: 'Unknown Admin');
    final deletedAt = _formatDate(data['deletedAt']);

    final isRestored = data['isRestored'] == true;
    final restoredBy = _text(data['restoredByEmail']);
    final restoredAt = _formatDate(data['restoredAt']);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: isRestored ? green : red,
            child: Icon(
              isRestored ? Icons.restore_outlined : Icons.delete_outline,
              color: Colors.white,
              size: 22,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  email,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  'Course: $course',
                  style: const TextStyle(fontSize: 12),
                ),

                Text(
                  'Skills: $skills',
                  style: const TextStyle(fontSize: 12),
                ),

                const SizedBox(height: 8),

                Text(
                  'Deleted by: $deletedBy',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                Text(
                  'Deleted at: $deletedAt',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),

                if (isRestored) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Restored by: $restoredBy',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'Restored at: $restoredAt',
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                ],

                const SizedBox(height: 8),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isRestored
                        ? const Color(0xFFE8F5E9)
                        : const Color(0xFFFFEBEE),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    isRestored ? 'Restored' : 'Deleted',
                    style: TextStyle(
                      color: isRestored ? green : red,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _deletedUsersSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'User Accounts',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      'Deleted logs archive',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                flex: 5,
                child: SizedBox(
                  height: 40,
                  child: TextField(
                    controller: _searchCtrl,
                    decoration: InputDecoration(
                      hintText: 'Search deleted accounts...',
                      hintStyle: const TextStyle(
                        fontSize: 13,
                        color: Colors.grey,
                      ),
                      prefixIcon: const Icon(
                        Icons.search,
                        size: 18,
                        color: Colors.grey,
                      ),
                      suffixIcon: _searchCtrl.text.isNotEmpty
                          ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchCtrl.clear();
                        },
                      )
                          : null,
                      filled: true,
                      fillColor: bg,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 0,
                        horizontal: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: navy,
                          width: 1.2,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          const Divider(),

          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('deleted_users_history')
                .orderBy('deletedAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Error: ${snapshot.error}',
                    style: const TextStyle(color: Colors.red),
                  ),
                );
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              final docs = snapshot.data?.docs ?? [];

              final filteredDocs = docs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return _matchesSearch(data);
              }).toList();

              if (filteredDocs.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text(
                      'No deleted user accounts matching requirements found.',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 13,
                      ),
                    ),
                  ),
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredDocs.length,
                separatorBuilder: (context, index) {
                  return const SizedBox(height: 10);
                },
                itemBuilder: (context, index) {
                  final doc = filteredDocs[index];
                  final data = doc.data() as Map<String, dynamic>;

                  return _deletedUserCard(data);
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _deletedPostsSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent Posts Deleted',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          Text(
            'Deleted community skill swap listings',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
          SizedBox(height: 16),
          Divider(),
          Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.layers_clear_outlined,
                    size: 40,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'No deleted posts recorded in this session',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,

      appBar: AppBar(
        title: const Text('Audit Track Dashboard'),
        backgroundColor: navy,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _deletedUsersSection(),

            const SizedBox(height: 24),

            _deletedPostsSection(),
          ],
        ),
      ),
    );
  }
}