import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'admin_edit_user_page.dart';

class AdminUsersPage extends StatefulWidget {
  const AdminUsersPage({super.key});

  @override
  State<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends State<AdminUsersPage> {
  final searchCtrl = TextEditingController();

  String searchText = '';
  String selectedFilter = 'All';
  bool selectionMode = false;

  final Set<String> selectedUsers = {};

  final Color navy = const Color(0xFF1A1F5E);
  final Color bg = const Color(0xFFF5F5FA);
  final Color border = const Color(0xFFE0E0F0);
  final Color green = const Color(0xFF4CAF50);
  final Color red = const Color(0xFFE53935);
  final Color orange = const Color(0xFFFF9800);

  final List<String> filters = [
    'All',
    'Active',
    'Deactivated',
    'Admin',
    'User',
  ];

  @override
  void initState() {
    super.initState();

    searchCtrl.addListener(() {
      setState(() {
        searchText = searchCtrl.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    searchCtrl.dispose();
    super.dispose();
  }

  String _getName(Map<String, dynamic> data) {
    return (data['fullName'] ??
        data['name'] ??
        data['username'] ??
        data['displayName'] ??
        'No Name')
        .toString();
  }

  String _getEmail(Map<String, dynamic> data) {
    return (data['email'] ?? 'No Email').toString();
  }

  String _getRole(Map<String, dynamic> data) {
    return (data['role'] ?? 'user').toString().toLowerCase();
  }

  bool _isSuspended(Map<String, dynamic> data) {
    return data['suspended'] == true;
  }

  String _getSkills(Map<String, dynamic> data) {
    final rawSkills = data['skills'];

    if (rawSkills == null) return 'No skills added';

    if (rawSkills is List) {
      if (rawSkills.isEmpty) return 'No skills added';
      return rawSkills.map((e) => e.toString()).join(', ');
    }

    return rawSkills.toString();
  }

  String _getProfileImage(Map<String, dynamic> data) {
    return (data['profileImageUrl'] ??
        data['photoUrl'] ??
        data['photoURL'] ??
        '')
        .toString();
  }

  bool _matchesSearch(Map<String, dynamic> data) {
    final name = _getName(data).toLowerCase();
    final email = _getEmail(data).toLowerCase();
    final skills = _getSkills(data).toLowerCase();

    return name.contains(searchText) ||
        email.contains(searchText) ||
        skills.contains(searchText);
  }

  bool _matchesFilter(Map<String, dynamic> data) {
    final role = _getRole(data);
    final suspended = _isSuspended(data);

    if (selectedFilter == 'Active') {
      return suspended == false;
    }

    if (selectedFilter == 'Deactivated') {
      return suspended == true;
    }

    if (selectedFilter == 'Admin') {
      return role == 'admin';
    }

    if (selectedFilter == 'User') {
      return role == 'user';
    }

    return true;
  }

  Future<void> _toggleSuspend(String uid, bool currentStatus) async {
    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'suspended': !currentStatus,
    });

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          currentStatus ? 'Account activated.' : 'Account deactivated.',
        ),
      ),
    );
  }

  Future<void> _deleteUsers(Set<String> uids) async {
    if (uids.isEmpty) return;

    final currentUid = FirebaseAuth.instance.currentUser?.uid;

    final deletableUids = uids.where((uid) => uid != currentUid).toList();

    if (deletableUids.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You cannot delete your own admin account.'),
        ),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Selected Accounts'),
          content: Text(
            'Are you sure you want to delete ${deletableUids.length} account(s)?\n\nThis will remove the user records from Firestore.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    final batch = FirebaseFirestore.instance.batch();

    for (final uid in deletableUids) {
      final ref = FirebaseFirestore.instance.collection('users').doc(uid);
      batch.delete(ref);
    }

    await batch.commit();

    if (!mounted) return;

    setState(() {
      selectedUsers.clear();
      selectionMode = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${deletableUids.length} account(s) deleted.'),
      ),
    );
  }

  void _toggleSelection(String uid) {
    setState(() {
      if (selectedUsers.contains(uid)) {
        selectedUsers.remove(uid);
      } else {
        selectedUsers.add(uid);
      }
    });
  }

  void _selectAllVisible(List<QueryDocumentSnapshot> docs) {
    setState(() {
      for (final doc in docs) {
        selectedUsers.add(doc.id);
      }
    });
  }

  void _clearSelection() {
    setState(() {
      selectedUsers.clear();
      selectionMode = false;
    });
  }

  Widget _filterChip(String label) {
    final selected = selectedFilter == label;

    return ChoiceChip(
      label: Text(label),
      selected: selected,
      selectedColor: navy,
      backgroundColor: Colors.white,
      labelStyle: TextStyle(
        color: selected ? Colors.white : navy,
        fontWeight: FontWeight.bold,
      ),
      side: BorderSide(color: selected ? navy : border),
      onSelected: (_) {
        setState(() {
          selectedFilter = label;
          selectedUsers.clear();
          selectionMode = false;
        });
      },
    );
  }

  Widget _selectionBar(List<QueryDocumentSnapshot> visibleDocs) {
    if (!selectionMode) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: navy,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Text(
            '${selectedUsers.length} selected',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),

          const Spacer(),

          TextButton(
            onPressed: () {
              _selectAllVisible(visibleDocs);
            },
            child: const Text(
              'Select All',
              style: TextStyle(color: Colors.white),
            ),
          ),

          IconButton(
            onPressed: selectedUsers.isEmpty
                ? null
                : () {
              _deleteUsers(selectedUsers);
            },
            icon: const Icon(Icons.delete_outline),
            color: Colors.white,
          ),

          IconButton(
            onPressed: _clearSelection,
            icon: const Icon(Icons.close),
            color: Colors.white,
          ),
        ],
      ),
    );
  }

  void _showActions(String uid, Map<String, dynamic> data) {
    final name = _getName(data);
    final email = _getEmail(data);
    final suspended = _isSuspended(data);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              const SizedBox(height: 18),

              Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: navy,
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : '?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
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
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          email,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 8),

              _sheetButton(
                icon: Icons.edit_outlined,
                label: 'Edit Profile',
                color: navy,
                bgColor: const Color(0xFFF5F5FA),
                onTap: () {
                  Navigator.pop(context);

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AdminEditUserPage(
                        uid: uid,
                        userData: data,
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 8),

              _sheetButton(
                icon: suspended
                    ? Icons.check_circle_outline
                    : Icons.block_outlined,
                label: suspended ? 'Activate Account' : 'Deactivate Account',
                color: orange,
                bgColor: const Color(0xFFFFF8E1),
                onTap: () {
                  Navigator.pop(context);
                  _toggleSuspend(uid, suspended);
                },
              ),

              const SizedBox(height: 8),

              _sheetButton(
                icon: Icons.delete_outline,
                label: 'Delete Account',
                color: red,
                bgColor: const Color(0xFFFFEBEE),
                onTap: () {
                  Navigator.pop(context);
                  _deleteUsers({uid});
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _sheetButton({
    required IconData icon,
    required String label,
    required Color color,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),

            const SizedBox(width: 12),

            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _userCard(String uid, Map<String, dynamic> data) {
    final name = _getName(data);
    final email = _getEmail(data);
    final skills = _getSkills(data);
    final role = _getRole(data);
    final suspended = _isSuspended(data);
    final profileImageUrl = _getProfileImage(data);

    final isSelected = selectedUsers.contains(uid);

    return GestureDetector(
      onLongPress: () {
        setState(() {
          selectionMode = true;
          selectedUsers.add(uid);
        });
      },
      onTap: () {
        if (selectionMode) {
          _toggleSelection(uid);
        } else {
          _showActions(uid, data);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
            color: isSelected ? navy : border,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            if (selectionMode)
              Checkbox(
                value: isSelected,
                activeColor: navy,
                onChanged: (_) {
                  _toggleSelection(uid);
                },
              ),

            CircleAvatar(
              backgroundColor: navy,
              backgroundImage: profileImageUrl.isNotEmpty
                  ? NetworkImage(profileImageUrl)
                  : null,
              child: profileImageUrl.isEmpty
                  ? Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: const TextStyle(color: Colors.white),
              )
                  : null,
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
                      fontSize: 14,
                    ),
                  ),

                  Text(
                    email,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    skills,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),

            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  role.toUpperCase(),
                  style: TextStyle(
                    color: role == 'admin' ? navy : green,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),

                const SizedBox(height: 6),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: suspended
                        ? const Color(0xFFFFEBEE)
                        : const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    suspended ? 'Deactivated' : 'Active',
                    style: TextStyle(
                      color: suspended ? red : green,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  selectionMode ? 'Tap to select' : 'Tap to manage',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _searchBox() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
      child: TextField(
        controller: searchCtrl,
        decoration: InputDecoration(
          hintText: 'Search by name, email, skill...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: searchCtrl.text.isNotEmpty
              ? IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () {
              searchCtrl.clear();
            },
          )
              : null,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

  Widget _filterRow() {
    return SizedBox(
      height: 46,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          return _filterChip(filters[index]);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: const Text('User Management'),
        backgroundColor: navy,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacementNamed(context, '/admin/user-management');
          },
        ),
        actions: [
          IconButton(
            tooltip: selectionMode ? 'Cancel selection' : 'Select users',
            icon: Icon(
              selectionMode ? Icons.close : Icons.checklist_outlined,
            ),
            onPressed: () {
              setState(() {
                selectionMode = !selectionMode;
                selectedUsers.clear();
              });
            },
          ),
        ],
      ),

      body: Column(
        children: [
          _searchBox(),

          _filterRow(),

          const SizedBox(height: 10),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .orderBy('email')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}'),
                  );
                }

                final docs = snapshot.data?.docs ?? [];

                final filteredDocs = docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return _matchesSearch(data) && _matchesFilter(data);
                }).toList();

                if (filteredDocs.isEmpty) {
                  return const Center(
                    child: Text('No users found'),
                  );
                }

                return Column(
                  children: [
                    _selectionBar(filteredDocs),

                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        itemCount: filteredDocs.length,
                        separatorBuilder: (context, index) {
                          return const SizedBox(height: 10);
                        },
                        itemBuilder: (context, index) {
                          final doc = filteredDocs[index];
                          final data = doc.data() as Map<String, dynamic>;

                          return _userCard(doc.id, data);
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}