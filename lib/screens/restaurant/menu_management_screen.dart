import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:r_foods/providers/restaurant_provider.dart';
import 'package:r_foods/models/menu_item_model.dart';
import 'package:r_foods/services/cloudinary_service.dart';

class MenuManagementScreen extends ConsumerWidget {
  const MenuManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final menuItemsAsync = ref.watch(myMenuItemsProvider);
    final restaurantAsync = ref.watch(myRestaurantProvider);
    
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;
    final subtextColor = isDark ? Colors.grey[400] : Colors.grey[600];

    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: menuItemsAsync.when(
            data: (menuItems) {
              return Column(
                children: [
                  // Header with add button
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Menu Items',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                            restaurantAsync.when(
                              data: (restaurant) => Text(
                                '${menuItems.length} / ${restaurant?.maxMenuItems ?? '∞'} items',
                                style: TextStyle(
                                  color: subtextColor,
                                  fontSize: 14,
                                ),
                              ),
                              loading: () => const SizedBox(),
                              error: (_, __) => const SizedBox(),
                            ),
                          ],
                        ),
                        ElevatedButton.icon(
                          onPressed: () => _showAddEditDialog(context, ref),
                          icon: const Icon(Icons.add),
                          label: const Text('Add Item'),
                        ),
                      ],
                    ),
                  ),

                  // Menu items list
                  if (menuItems.isEmpty)
                    Expanded(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.restaurant_menu,
                                size: 80, color: subtextColor),
                            const SizedBox(height: 16),
                            Text(
                              'No menu items yet',
                              style:
                                  TextStyle(fontSize: 18, color: subtextColor),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Add your first menu item to start!',
                              style:
                                  TextStyle(fontSize: 14, color: subtextColor),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final isWide = constraints.maxWidth > 900;
                          final crossAxisCount = isWide
                              ? 3
                              : constraints.maxWidth > 600
                                  ? 2
                                  : 1;

                          return GridView.builder(
                            padding: const EdgeInsets.all(16),
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: crossAxisCount,
                              childAspectRatio: 0.85,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                            ),
                            itemCount: menuItems.length,
                            itemBuilder: (context, index) {
                              final item = menuItems[index];
                              return _MenuItemCard(
                                item: item,
                                onEdit: () =>
                                    _showAddEditDialog(context, ref, item: item),
                                onDelete: () => _deleteMenuItem(context, ref, item),
                                onToggleAvailability: () =>
                                    _toggleAvailability(ref, item),
                              );
                            },
                          );
                        },
                      ),
                    ),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(child: Text('Error: $error', style: TextStyle(color: textColor))),
          ),
        ),
      ),
    );
  }

  void _showAddEditDialog(BuildContext context, WidgetRef ref,
      {MenuItem? item}) {
    showDialog(
      context: context,
      builder: (context) => _AddEditMenuItemDialog(item: item),
    );
  }

  Future<void> _deleteMenuItem(
      BuildContext context, WidgetRef ref, MenuItem item) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF2C2C2C) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardColor,
        title: Text('Delete Menu Item', style: TextStyle(color: textColor)),
        content: Text('Are you sure you want to delete "${item.name}"?', style: TextStyle(color: textColor)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref.read(menuItemServiceProvider).deleteMenuItem(item.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Menu item deleted')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _toggleAvailability(WidgetRef ref, MenuItem item) async {
    try {
      await ref
          .read(menuItemServiceProvider)
          .toggleItemAvailability(item.id, !item.isAvailable);
    } catch (e) {
      // Error handling will be shown in UI via stream
    }
  }
}

class _MenuItemCard extends StatelessWidget {
  final MenuItem item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggleAvailability;

  const _MenuItemCard({
    required this.item,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleAvailability,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF2C2C2C) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;
    final subtextColor = isDark ? Colors.grey[400] : Colors.grey[600];

    return Card(
      color: cardColor,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Image with overlay controls
          Expanded(
            flex: 3,
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(16)),
                  child: Image.network(
                    item.imageUrl,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: isDark ? Colors.grey[800] : Colors.grey[200],
                      child: Icon(Icons.restaurant, size: 60, color: subtextColor),
                    ),
                  ),
                ),
                // Availability overlay
                if (!item.isAvailable)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(16)),
                      ),
                      child: const Center(
                        child: Text(
                          'UNAVAILABLE',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                // Action buttons
                Positioned(
                  top: 8,
                  right: 8,
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: onEdit,
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white,
                          padding: const EdgeInsets.all(8),
                        ),
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: onDelete,
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.red,
                          padding: const EdgeInsets.all(8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Details
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.categoryDisplay,
                    style: TextStyle(fontSize: 12, color: subtextColor),
                  ),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '₦${item.price.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      Switch(
                        value: item.isAvailable,
                        onChanged: (_) => onToggleAvailability(),
                        activeColor: Colors.green,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddEditMenuItemDialog extends ConsumerStatefulWidget {
  final MenuItem? item;

  const _AddEditMenuItemDialog({this.item});

  @override
  ConsumerState<_AddEditMenuItemDialog> createState() =>
      _AddEditMenuItemDialogState();
}

class _AddEditMenuItemDialogState
    extends ConsumerState<_AddEditMenuItemDialog> {
  final _formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final descriptionController = TextEditingController();
  final priceController = TextEditingController();
  final quantityController = TextEditingController();

  String? selectedCategory;
  String? selectedSubCategory;
  XFile? imageFile;
  Uint8List? imageBytes;
  bool _isLoading = false;

  final CloudinaryService _cloudinary = CloudinaryService();
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    if (widget.item != null) {
      nameController.text = widget.item!.name;
      descriptionController.text = widget.item!.description ?? '';
      priceController.text = widget.item!.price.toString();
      selectedCategory = widget.item!.category;
      selectedSubCategory = widget.item!.subCategory;
      if (widget.item!.quantityAvailable != null) {
        quantityController.text = widget.item!.quantityAvailable.toString();
      }
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    descriptionController.dispose();
    priceController.dispose();
    quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF2C2C2C) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;
    final subtextColor = isDark ? Colors.grey[400] : Colors.grey[600];
    final borderColor = isDark ? Colors.grey[700]! : Colors.grey[300]!;

    return Dialog(
      backgroundColor: cardColor,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.item == null ? 'Add Menu Item' : 'Edit Menu Item',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 24),

                // Image picker
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    height: 200,
                    decoration: BoxDecoration(
                      border: Border.all(color: borderColor),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: imageBytes != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.memory(imageBytes!, fit: BoxFit.cover),
                          )
                        : widget.item?.imageUrl != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  widget.item!.imageUrl,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_photo_alternate,
                                      size: 48, color: subtextColor),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Tap to add image',
                                    style: TextStyle(color: subtextColor),
                                  ),
                                ],
                              ),
                  ),
                ),
                if (imageFile == null && widget.item == null)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text(
                      'Image is required',
                      style: TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ),
                const SizedBox(height: 16),

                // Name
                TextFormField(
                  controller: nameController,
                  style: TextStyle(color: textColor),
                  decoration: InputDecoration(
                    labelText: 'Item Name',
                    labelStyle: TextStyle(color: subtextColor),
                    border: const OutlineInputBorder(),
                    enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: borderColor)),
                  ),
                  validator: (v) =>
                      v?.isEmpty ?? true ? 'Enter item name' : null,
                ),
                const SizedBox(height: 16),

                // Description
                TextFormField(
                  controller: descriptionController,
                  style: TextStyle(color: textColor),
                  decoration: InputDecoration(
                    labelText: 'Description (Optional)',
                    labelStyle: TextStyle(color: subtextColor),
                    border: const OutlineInputBorder(),
                    enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: borderColor)),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),

                // Price
                TextFormField(
                  controller: priceController,
                  style: TextStyle(color: textColor),
                  decoration: InputDecoration(
                    labelText: 'Price (₦)',
                    labelStyle: TextStyle(color: subtextColor),
                    border: const OutlineInputBorder(),
                    enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: borderColor)),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (v?.isEmpty ?? true) return 'Enter price';
                    if (double.tryParse(v!) == null) return 'Enter valid price';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Category
                DropdownButtonFormField<String>(
                  dropdownColor: cardColor,
                  style: TextStyle(color: textColor),
                  value: selectedCategory,
                  decoration: InputDecoration(
                    labelText: 'Category',
                    labelStyle: TextStyle(color: subtextColor),
                    border: const OutlineInputBorder(),
                    enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: borderColor)),
                  ),
                  items: MenuCategory.mainCategories
                      .map((c) => DropdownMenuItem(value: c, child: Text(c, style: TextStyle(color: textColor))))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedCategory = value;
                      selectedSubCategory = null;
                    });
                  },
                  validator: (v) => v == null ? 'Select category' : null,
                ),
                const SizedBox(height: 16),

                // Sub-category
                if (selectedCategory != null)
                  DropdownButtonFormField<String>(
                    dropdownColor: cardColor,
                    style: TextStyle(color: textColor),
                    value: selectedSubCategory,
                    decoration: InputDecoration(
                      labelText: 'Sub-Category',
                      labelStyle: TextStyle(color: subtextColor),
                      border: const OutlineInputBorder(),
                      enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: borderColor)),
                    ),
                    items: MenuCategory.getSubCategories(selectedCategory!)
                        .map((c) =>
                            DropdownMenuItem(value: c, child: Text(c, style: TextStyle(color: textColor))))
                        .toList(),
                    onChanged: (value) =>
                        setState(() => selectedSubCategory = value),
                    validator: (v) => v == null ? 'Select sub-category' : null,
                  ),
                const SizedBox(height: 24),

                // Action buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _saveMenuItem,
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(widget.item == null ? 'Add' : 'Save'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    final XFile? picked =
        await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      setState(() {
        imageFile = picked;
        imageBytes = bytes;
      });
    }
  }

  Future<void> _saveMenuItem() async {
    if (!_formKey.currentState!.validate()) return;
    if (imageFile == null && widget.item == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add an image'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Not logged in');

      // Upload image if new
      String imageUrl;
      if (imageFile != null) {
        imageUrl = await _cloudinary.uploadImageFromBytes(
          bytes: imageBytes!,
          fileName: imageFile!.name,
          folder: CloudinaryFolders.menuItems,
        );
      } else {
        imageUrl = widget.item!.imageUrl;
      }

      final menuItem = MenuItem(
        id: widget.item?.id ?? '',
        restaurantId: user.uid,
        name: nameController.text.trim(),
        description: descriptionController.text.trim().isEmpty
            ? null
            : descriptionController.text.trim(),
        price: double.parse(priceController.text.trim()),
        category: selectedCategory!,
        subCategory: selectedSubCategory!,
        imageUrl: imageUrl,
        isAvailable: widget.item?.isAvailable ?? true,
        quantityAvailable: quantityController.text.trim().isEmpty
            ? null
            : int.parse(quantityController.text.trim()),
        createdAt: widget.item?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (widget.item == null) {
        await ref.read(menuItemServiceProvider).createMenuItem(menuItem);
      } else {
        await ref.read(menuItemServiceProvider).updateMenuItem(menuItem);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.item == null
                ? 'Menu item added'
                : 'Menu item updated'),
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
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
