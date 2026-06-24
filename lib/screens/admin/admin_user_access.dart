import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'admin_drawer.dart';

class AdminUserAccessPage extends StatefulWidget {
  const AdminUserAccessPage({super.key});

  @override
  State<AdminUserAccessPage> createState() => _AdminUserAccessPageState();
}

class _AdminUserAccessPageState extends State<AdminUserAccessPage> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchText = '';

  // Theme styling colors
  final Color navy = const Color(0xFF1A1F5E);
  final Color bg = const Color(0xFFF5F5FA);
  final Color border = const Color(0xFFE0E0F0);
  final Color green = const Color(0xFF4CAF50);
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

  Future<void> _toggleAccess(String uid, bool currentStatus) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'hasAuditAccess': !currentStatus,
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update permission: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      drawer: const AdminDrawer(),
      appBar: AppBar(
        title: const Text('User Access Control'),
        backgroundColor: navy,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
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
                  // Title and Search Bar Row
                  Row(
                    children: [
                      const Expanded(
                        flex: 4,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Admin Permissions',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'Manage audit track access',
                              style: TextStyle(fontSize: 11, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 5,
                        child: SizedBox(
                          height: 38,
                          child: TextField(
                            controller: _searchCtrl,
                            decoration: InputDecoration(
                              hintText: 'Search admin...',
                              hintStyle: const TextStyle(fontSize: 12, color: Colors.grey),
                              prefixIcon: const Icon(Icons.search, size: 16, color: Colors.grey),
                              filled: true,
                              fillColor: bg,
                              contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
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
                                borderSide: BorderSide(color: navy),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),

                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .where('role', isEqualTo: 'admin')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red));
                      }
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: Padding(padding: EdgeInsets.all(24.0), child: CircularProgressIndicator()));
                      }

                      final docs = snapshot.data?.docs ?? [];

                      final filteredDocs = docs.where((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final name = (data['name'] ?? data['fullName'] ?? '').toString().toLowerCase();
                        final email = (data['email'] ?? '').toString().toLowerCase();
                        return name.contains(_searchText) || email.contains(_searchText);
                      }).toList();

                      if (filteredDocs.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 32.0),
                          child: Center(child: Text('No administrators found.', style: TextStyle(color: Colors.grey, fontSize: 13))),
                        );
                      }

                      // FIXED: Using layout Table with FlexColumnWidth to automatically fill 100% of the container space
                      return Table(
                        columnWidths: const {
                          0: FlexColumnWidth(3.5), // Allocates 35% space to Name
                          1: FlexColumnWidth(4.5), // Allocates 45% space to Email
                          2: FlexColumnWidth(2.5), // Allocates 25% space to Toggle Switch
                        },
                        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                        children: [
                          // Table Header Header Row Layout
                          TableRow(
                            decoration: BoxDecoration(
                              color: bg,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            children: const [
                              Padding(
                                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                                child: Text('ADMIN USER', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.black54)),
                              ),
                              Padding(
                                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                                child: Text('EMAIL ADDRESS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.black54)),
                              ),
                              Padding(
                                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                                child: Text('AUDIT ACCESS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.black54), textAlign: TextAlign.center),
                              ),
                            ],
                          ),

                          // Table Row Spacer Row
                          const TableRow(
                              children: [
                                SizedBox(height: 8),
                                SizedBox(height: 8),
                                SizedBox(height: 8),
                              ]
                          ),

                          // Table Data Rows
                          ...filteredDocs.map((doc) {
                            final data = doc.data() as Map<String, dynamic>;
                            final name = data['name'] ?? data['fullName'] ?? 'No Name';
                            final email = data['email'] ?? 'No Email';
                            final bool hasAccess = data['hasAuditAccess'] == true;

                            return TableRow(
                              decoration: BoxDecoration(
                                border: Border(bottom: BorderSide(color: border, width: 0.5)),
                              ),
                              children: [
                                // Column 1: Profile and User Name
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 13,
                                        backgroundColor: purple,
                                        child: Text(
                                          name.toString().isNotEmpty ? name.toString()[0].toUpperCase() : '?',
                                          style: TextStyle(color: purpleDeep, fontSize: 10, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          name,
                                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Column 2: Account Email
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                                  child: Text(
                                    email,
                                    style: const TextStyle(fontSize: 12, color: Colors.black87),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                // Column 3: Center-Aligned Toggle Control Switch
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                  child: Align(
                                    alignment: Alignment.center,
                                    child: Transform.scale(
                                      scale: 0.75,
                                      child: Switch(
                                        value: hasAccess,
                                        activeThumbColor: green,
                                        onChanged: (_) => _toggleAccess(doc.id, hasAccess),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          }),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}