import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:r_foods/models/user_model.dart';

class AdminDashboard extends ConsumerStatefulWidget {
  const AdminDashboard({super.key});

  @override
  ConsumerState<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends ConsumerState<AdminDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedFilter = 'pending';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 900;
    
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;

    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Dashboard', style: TextStyle(color: textColor)),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: Icon(Icons.logout, color: textColor),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: textColor,
          unselectedLabelColor: isDark ? Colors.grey[400] : Colors.grey[600],
          tabs: const [
            Tab(icon: Icon(Icons.pending_actions), text: 'Pending'),
            Tab(icon: Icon(Icons.check_circle), text: 'Approved'),
            Tab(icon: Icon(Icons.cancel), text: 'Rejected'),
          ],
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints:
                BoxConstraints(maxWidth: isWide ? 1200 : double.infinity),
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildApplicationsList('pending'),
                _buildApplicationsList('approved'),
                _buildApplicationsList('rejected'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildApplicationsList(String status) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;
    final subtextColor = isDark ? Colors.grey[400] : Colors.grey[600];

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'delivery-partner')
          .where('approvalStatus', isEqualTo: status)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}', style: TextStyle(color: textColor)));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final applications = snapshot.data?.docs ?? [];

        if (applications.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  status == 'pending'
                      ? Icons.inbox
                      : status == 'approved'
                          ? Icons.check_circle_outline
                          : Icons.cancel_outlined,
                  size: 80,
                  color: subtextColor,
                ),
                const SizedBox(height: 16),
                Text(
                  status == 'pending'
                      ? 'No pending applications'
                      : status == 'approved'
                          ? 'No approved partners yet'
                          : 'No rejected applications',
                  style: TextStyle(fontSize: 18, color: subtextColor),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: applications.length,
          itemBuilder: (context, index) {
            final doc = applications[index];
            final partner = UserModel.fromFirestore(doc);
            return _buildApplicationCard(partner, status);
          },
        );
      },
    );
  }

  Widget _buildApplicationCard(UserModel partner, String status) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF2C2C2C) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;
    final subtextColor = isDark ? Colors.grey[400] : Colors.grey[600];

    return Card(
      color: cardColor,
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: InkWell(
        onTap: () => _showApplicationDetails(partner),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with profile picture and name
              Row(
                children: [
                  // Profile picture
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
                    backgroundImage: partner.profileImageUrl != null
                        ? NetworkImage(partner.profileImageUrl!)
                        : null,
                    child: partner.profileImageUrl == null
                        ? Icon(Icons.person, size: 30, color: subtextColor)
                        : null,
                  ),
                  const SizedBox(width: 16),
                  // Name and student ID
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          partner.fullName,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Student ID: ${partner.studentId}',
                          style: TextStyle(
                            color: subtextColor,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Status badge
                  _buildStatusBadge(status),
                ],
              ),
              Divider(height: 24, color: isDark ? Colors.grey[700] : null),
              // Details
              _buildInfoRow(Icons.school, partner.courseOfStudy ?? '—', subtextColor!, textColor),
              const SizedBox(height: 8),
              _buildInfoRow(Icons.calendar_today, partner.year ?? '—', subtextColor, textColor),
              const SizedBox(height: 8),
              _buildInfoRow(Icons.home, partner.hostelAddress ?? '—', subtextColor, textColor),
              const SizedBox(height: 8),
              _buildInfoRow(Icons.phone, partner.phoneNumber, subtextColor, textColor),
              const SizedBox(height: 8),
              _buildInfoRow(Icons.email, partner.email, subtextColor, textColor),

              // Action buttons for pending applications
              if (status == 'pending') ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _showApplicationDetails(partner),
                        icon: const Icon(Icons.visibility),
                        label: const Text('Review'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _approveApplication(partner),
                        icon: const Icon(Icons.check),
                        label: const Text('Approve'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _rejectApplication(partner),
                        icon: const Icon(Icons.close),
                        label: const Text('Reject'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                        ),
                      ),
                    ),
                  ],
                ),
              ],

              // Rejection reason for rejected applications
              if (status == 'rejected' && partner.rejectionReason != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline,
                          color: Colors.red, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Reason: ${partner.rejectionReason}',
                          style: TextStyle(fontSize: 13, color: textColor),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Approval info for approved applications
              if (status == 'approved' && partner.approvedAt != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.withOpacity(0.3)),
                  ),
                  child: Text(
                    'Approved on ${_formatDate(partner.approvedAt!)}',
                    style: const TextStyle(fontSize: 13, color: Colors.green),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    IconData icon;
    String text;

    switch (status) {
      case 'pending':
        color = Colors.orange;
        icon = Icons.pending;
        text = 'Pending';
        break;
      case 'approved':
        color = Colors.green;
        icon = Icons.check_circle;
        text = 'Approved';
        break;
      case 'rejected':
        color = Colors.red;
        icon = Icons.cancel;
        text = 'Rejected';
        break;
      default:
        color = Colors.grey;
        icon = Icons.help;
        text = 'Unknown';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text, Color subtextColor, Color textColor) {
    return Row(
      children: [
        Icon(icon, size: 18, color: subtextColor),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 14, color: textColor),
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  // Show full application details with documents
  void _showApplicationDetails(UserModel partner) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF2C2C2C) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;
    final subtextColor = isDark ? Colors.grey[400] : Colors.grey[600];

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: cardColor,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Row(
                    children: [
                      Text(
                        'Application Details',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: Icon(Icons.close, color: textColor),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  Divider(height: 32, color: isDark ? Colors.grey[700] : null),

                  // Profile Picture
                  Center(
                    child: CircleAvatar(
                      radius: 60,
                      backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
                      backgroundImage: partner.profileImageUrl != null
                          ? NetworkImage(partner.profileImageUrl!)
                          : null,
                      child: partner.profileImageUrl == null
                          ? Icon(Icons.person, size: 60, color: subtextColor)
                          : null,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Personal Info
                  _detailSection('Personal Information', [
                    _detailRow('Full Name', partner.fullName, subtextColor!, textColor),
                    _detailRow('Email', partner.email, subtextColor, textColor),
                    _detailRow('Phone', partner.phoneNumber, subtextColor, textColor),
                    _detailRow('Student ID', partner.studentId ?? '—', subtextColor, textColor),
                  ], textColor),

                  // Academic Info
                  _detailSection('Academic Information', [
                    _detailRow('Course', partner.courseOfStudy ?? '—', subtextColor, textColor),
                    _detailRow('Year', partner.year ?? '—', subtextColor, textColor),
                  ], textColor),

                  // Hostel Info
                  _detailSection('Hostel Information', [
                    _detailRow('Hostel', partner.hostelName ?? '—', subtextColor, textColor),
                    _detailRow('Type', partner.hostelType ?? '—', subtextColor, textColor),
                    _detailRow('Block', partner.blockNumber ?? '—', subtextColor, textColor),
                    _detailRow('Room', partner.roomNumber ?? 'Not provided', subtextColor, textColor),
                  ], textColor),

                  // Documents
                  const SizedBox(height: 24),
                  Text(
                    'Documents',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
                  ),
                  const SizedBox(height: 12),

                  // ID Card
                  if (partner.idCardImageUrl != null)
                    _documentCard(
                      'Student ID Card',
                      partner.idCardImageUrl!,
                      cardColor, textColor, subtextColor, isDark
                    ),

                  // Hostel Allocation
                  if (partner.hostelAllocationUrl != null)
                    _documentCard(
                      'Hostel Allocation',
                      partner.hostelAllocationUrl!,
                      cardColor, textColor, subtextColor, isDark
                    ),

                  // Action buttons
                  if (partner.approvalStatus == 'pending') ...[
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              _approveApplication(partner);
                            },
                            icon: const Icon(Icons.check),
                            label: const Text('Approve'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              _rejectApplication(partner);
                            },
                            icon: const Icon(Icons.close),
                            label: const Text('Reject'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                              side: const BorderSide(color: Colors.red),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _detailSection(String title, List<Widget> children, Color textColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(
          title,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }

  Widget _detailRow(String label, String value, Color subtextColor, Color textColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: subtextColor,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 15, color: textColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _documentCard(String title, String imageUrl, Color cardColor, Color textColor, Color subtextColor, bool isDark) {
    return Card(
      color: cardColor,
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showFullImage(imageUrl, title),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  imageUrl,
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      Icon(Icons.error, size: 80, color: subtextColor),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tap to view full size',
                      style: TextStyle(
                        fontSize: 12,
                        color: subtextColor,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: subtextColor),
            ],
          ),
        ),
      ),
    );
  }

  void _showFullImage(String imageUrl, String title) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF2C2C2C) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: cardColor,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              backgroundColor: cardColor,
              title: Text(title, style: TextStyle(color: textColor)),
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                  icon: Icon(Icons.close, color: textColor),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            Flexible(
              child: InteractiveViewer(
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) =>
                      Center(child: Icon(Icons.error, size: 100, color: isDark ? Colors.grey[400] : Colors.grey[600])),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _approveApplication(UserModel partner) async {
    try {
      final adminId = FirebaseAuth.instance.currentUser?.uid;
      if (adminId == null) throw Exception('Not logged in');

      await FirebaseFirestore.instance
          .collection('users')
          .doc(partner.uid)
          .update({
        'isApproved': true,
        'approvalStatus': 'approved',
        'approvedBy': adminId,
        'approvedAt': FieldValue.serverTimestamp(),
        'rejectionReason': FieldValue.delete(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${partner.fullName} has been approved!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _rejectApplication(UserModel partner) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF2C2C2C) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;
    final subtextColor = isDark ? Colors.grey[400] : Colors.grey[600];
    final borderColor = isDark ? Colors.grey[700]! : Colors.grey[300]!;

    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardColor,
        title: Text('Reject Application', style: TextStyle(color: textColor)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to reject ${partner.fullName}?', style: TextStyle(color: textColor)),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              style: TextStyle(color: textColor),
              decoration: InputDecoration(
                labelText: 'Reason for rejection',
                labelStyle: TextStyle(color: subtextColor),
                hintText: 'e.g., Invalid ID card, Unclear documents',
                hintStyle: TextStyle(color: subtextColor?.withOpacity(0.5)),
                border: const OutlineInputBorder(),
                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: borderColor)),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (reasonController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please provide a reason for rejection'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              Navigator.pop(context);

              try {
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(partner.uid)
                    .update({
                  'isApproved': false,
                  'approvalStatus': 'rejected',
                  'rejectionReason': reasonController.text.trim(),
                });

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content:
                          Text('${partner.fullName} has been rejected'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }
}
