import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../constants.dart';
import '../services/product_service.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/product_image_picker.dart';
import '../widgets/theme_mode_icon_button.dart';

class AddProductPage extends StatefulWidget {
  const AddProductPage({super.key});

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _stockController = TextEditingController(
    text: '0',
  );
  final ImagePicker _imagePicker = ImagePicker();
  final ProductService _productService = const ProductService();

  Uint8List? _selectedImageBytes;
  String? _selectedImageName;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? picked = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (picked == null) {
        return;
      }

      final Uint8List bytes = await picked.readAsBytes();
      if (!mounted) {
        return;
      }

      setState(() {
        _selectedImageBytes = bytes;
        _selectedImageName = picked.name;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showSnackBar(_errorMessage(error), isError: true);
    }
  }

  void _removeImage() {
    if (!mounted) {
      return;
    }

    setState(() {
      _selectedImageBytes = null;
      _selectedImageName = null;
    });
  }

  Future<void> _submit() async {
    if (_isSubmitting) {
      return;
    }

    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final double? price = double.tryParse(_priceController.text.trim());
    final int? stock = int.tryParse(_stockController.text.trim());

    if (price == null || price <= 0) {
      _showSnackBar('Please enter a valid price.', isError: true);
      return;
    }

    if (stock == null || stock < 0) {
      _showSnackBar('Please enter a valid stock quantity.', isError: true);
      return;
    }

    if (mounted) {
      setState(() {
        _isSubmitting = true;
      });
    }

    try {
      final String? savedImageName = await _productService.addProduct(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        price: price,
        stock: stock,
        imageBytes: _selectedImageBytes,
        imageName: _selectedImageName,
      );

      if (!mounted) {
        return;
      }

      if (savedImageName != null && savedImageName.isNotEmpty) {
        setState(() {
          _selectedImageName = savedImageName;
        });
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text(productAddedMessage)));
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showSnackBar(_errorMessage(error), isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: isError ? AppColors.error : null,
        content: Text(message),
      ),
    );
  }

  String _errorMessage(Object error) {
    final String message = error.toString();
    if (message.startsWith('Exception: ')) {
      return message.substring('Exception: '.length);
    }
    return genericErrorMessage;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(addProductTitle),
        actions: const <Widget>[ThemeModeIconButton()],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                ProductImagePicker(
                  onTap: _pickImage,
                  onRemove: _selectedImageBytes == null ? null : _removeImage,
                  imageBytes: _selectedImageBytes,
                ),
                const SizedBox(height: 24),
                CustomTextField(
                  controller: _nameController,
                  labelText: 'Product Name',
                  hintText: 'Enter product name',
                  prefixIcon: Icons.label_outline,
                  textInputAction: TextInputAction.next,
                  validator: (String? value) {
                    if ((value ?? '').trim().isEmpty) {
                      return 'Product name is required.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _descriptionController,
                  labelText: 'Description',
                  hintText: 'Add a short product description',
                  prefixIcon: Icons.description_outlined,
                  textInputAction: TextInputAction.next,
                  textCapitalization: TextCapitalization.sentences,
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _priceController,
                  labelText: 'Price (₱)',
                  hintText: 'Enter price',
                  prefixIcon: Icons.payments_outlined,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  textInputAction: TextInputAction.next,
                  validator: (String? value) {
                    final String trimmed = value?.trim() ?? '';
                    final double? parsed = double.tryParse(trimmed);
                    if (trimmed.isEmpty) {
                      return 'Price is required.';
                    }
                    if (parsed == null || parsed <= 0) {
                      return 'Enter a valid positive price.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _stockController,
                  labelText: 'Stock Quantity',
                  hintText: 'Enter stock quantity',
                  prefixIcon: Icons.inventory_outlined,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  validator: (String? value) {
                    final String trimmed = value?.trim() ?? '';
                    final int? parsed = int.tryParse(trimmed);
                    if (trimmed.isEmpty) {
                      return 'Stock quantity is required.';
                    }
                    if (parsed == null || parsed < 0) {
                      return 'Enter a valid non-negative stock quantity.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                CustomButton(
                  label: 'Save Product',
                  onPressed: _isSubmitting ? null : _submit,
                  isLoading: _isSubmitting,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
