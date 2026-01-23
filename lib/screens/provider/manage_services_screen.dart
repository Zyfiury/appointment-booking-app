import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/service_service.dart';
import '../../models/service.dart';
import '../../theme/app_theme.dart';
import '../../providers/theme_provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/service_categories.dart';
import '../../utils/validators.dart';
import '../../widgets/confirmation_dialog.dart';
import '../../utils/network_utils.dart';
import '../../widgets/retry_button.dart';


class ManageServicesScreen extends StatefulWidget {
  const ManageServicesScreen({super.key});

  @override
  State<ManageServicesScreen> createState() => _ManageServicesScreenState();
}

class _ManageServicesScreenState extends State<ManageServicesScreen> {
  final ServiceService _serviceService = ServiceService();
  final _formKey = GlobalKey<FormState>();

  List<Service> _services = [];
  bool _showForm = false;
  Service? _editingService;
  bool _loading = false;
  bool _loadingServices = true;
  String? _error;

  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _durationController = TextEditingController();
  final _priceController = TextEditingController();
  String? _selectedCategory;
  final _capacityController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadServices();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _durationController.dispose();
    _priceController.dispose();
    _capacityController.dispose();
    super.dispose();
  }

  Future<void> _loadServices() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final providerId = authProvider.user?.id;
      
      if (providerId == null) {
        setState(() {
          _loadingServices = false;
          _error = 'Provider ID not found';
        });
        return;
      }
      
      final services = await _serviceService.getServices(providerId: providerId);
      setState(() {
        _services = services;
        _loadingServices = false;
      });
    } catch (e) {
      setState(() {
        _loadingServices = false;
        _error = 'Failed to load services';
      });
    }
  }

  void _openForm({Service? service}) {
    setState(() {
      _editingService = service;
      _showForm = true;
      if (service != null) {
        _nameController.text = service.name;
        _descriptionController.text = service.description;
        _durationController.text = service.duration.toString();
        _priceController.text = service.price.toString();
        _selectedCategory = service.category;
        _capacityController.text = service.capacity.toString();
      } else {
        _nameController.clear();
        _descriptionController.clear();
        _durationController.clear();
        _priceController.clear();
        _selectedCategory = null;
        _capacityController.text = '1';
      }
      _error = null;
    });
  }

  void _closeForm() {
    setState(() {
      _showForm = false;
      _editingService = null;
      _nameController.clear();
      _descriptionController.clear();
      _durationController.clear();
      _priceController.clear();
      _selectedCategory = null;
      _capacityController.text = '1';
      _error = null;
    });
  }

  Future<void> _saveService() async {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final colors = AppTheme.getColors(themeProvider.currentTheme);
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      if (_editingService != null) {
        await _serviceService.updateService(
          _editingService!.id,
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          duration: int.parse(_durationController.text),
          price: double.parse(_priceController.text),
          category: _selectedCategory ?? 'Other',
          capacity: int.tryParse(_capacityController.text) ?? 1,
        );
      } else {
        await _serviceService.createService(
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          duration: int.parse(_durationController.text),
          price: double.parse(_priceController.text),
          category: _selectedCategory ?? 'Other',
          capacity: int.tryParse(_capacityController.text) ?? 1,
        );
      }
      _closeForm();
      _loadServices();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _editingService != null
                  ? 'Service updated successfully'
                  : 'Service created successfully',
            ),
            backgroundColor: colors.accentColor,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _loading = false;
        _error = 'Failed to save service. Please try again.';
      });
    }
  }

  Future<void> _deleteService(Service service) async {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final colors = AppTheme.getColors(themeProvider.currentTheme);
    
    final confirmed = await ConfirmationDialog.show(
      context: context,
      title: 'Delete Service',
      message: 'Are you sure you want to delete "${service.name}"? This action cannot be undone.',
      confirmText: 'Delete',
      cancelText: 'Cancel',
      confirmColor: colors.errorColor,
      icon: Icons.delete_outline,
    );

    if (confirmed == true) {
      try {
        await _serviceService.deleteService(service.id);
        _loadServices();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Service deleted successfully'),
              backgroundColor: colors.accentColor,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(NetworkUtils.getErrorMessage(e)),
              backgroundColor: colors.errorColor,
              action: NetworkUtils.isRetryable(e)
                  ? SnackBarAction(
                      label: 'Retry',
                      textColor: Colors.white,
                      onPressed: () => _deleteService(service),
                    )
                  : null,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final colors = AppTheme.getColors(themeProvider.currentTheme);

    if (_showForm) {
      return Scaffold(
        appBar: AppBar(
          title: Text(_editingService != null
              ? 'Edit Service'
              : 'Add New Service'),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Service Name',
                    prefixIcon: Icon(Icons.work_outline),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter service name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: InputDecoration(
                    labelText: 'Category',
                    prefixIcon: Icon(Icons.category_outlined),
                  ),
                  items: ServiceCategories.getAllCategoryNames().map((category) {
                    final categoryInfo = ServiceCategories.getCategory(category);
                    return DropdownMenuItem<String>(
                      value: category,
                      child: Row(
                        children: [
                          Icon(
                            categoryInfo.icon,
                            color: categoryInfo.color,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(category),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedCategory = value;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select a category';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: 'Description',
                    prefixIcon: Icon(Icons.description_outlined),
                  ),
                  validator: (value) => Validators.description(value, minLength: 10, maxLength: 500),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _durationController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Duration (minutes)',
                    prefixIcon: Icon(Icons.access_time),
                  ),
                  validator: Validators.duration,
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _priceController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Price (\$)',
                    prefixIcon: Icon(Icons.attach_money),
                  ),
                  validator: Validators.price,
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _capacityController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Capacity (concurrent bookings)',
                    hintText: '1 = one customer at a time, 10 = group class',
                    prefixIcon: Icon(Icons.groups),
                  ),
                  validator: Validators.capacity,
                ),
                const SizedBox(height: 24),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      _error!,
                      style: TextStyle(color: colors.errorColor),
                    ),
                  ),
                ElevatedButton(
                  onPressed: _loading ? null : _saveService,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(_editingService != null ? 'Update' : 'Create'),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: _loading ? null : _closeForm,
                  child: Text('Cancel'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Manage Services'),
      ),
      body: _loadingServices
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: ElevatedButton.icon(
                    onPressed: () => _openForm(),
                    icon: const Icon(Icons.add),
                    label: Text('Add New Service'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                Expanded(
                  child: _services.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.work_outline,
                                size: 64,
                                color: colors.textSecondary,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No services yet',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Add your first service to get started',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _services.length,
                          itemBuilder: (context, index) {
                            final service = _services[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            service.name,
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleLarge,
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: colors.primaryColor
                                                .withOpacity(0.1),
                                            borderRadius:
                                                BorderRadius.circular(20),
                                          ),
                                          child: Text(
                                            service.category,
                                            style: TextStyle(
                                              color: colors.primaryColor,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      service.description,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium,
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.access_time,
                                          size: 16,
                                          color: colors.textSecondary,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          '${service.duration} minutes',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium,
                                        ),
                                        const SizedBox(width: 24),
                                        Icon(
                                          Icons.attach_money,
                                          size: 16,
                                          color: colors.textSecondary,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          '\$${service.price.toStringAsFixed(2)}',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.groups,
                                          size: 16,
                                          color: colors.textSecondary,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Capacity: ${service.capacity}',
                                          style: Theme.of(context).textTheme.bodyMedium,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        OutlinedButton(
                                          onPressed: () => _openForm(
                                            service: service,
                                          ),
                                          child: Text('Edit'),
                                        ),
                                        const SizedBox(width: 8),
                                        ElevatedButton(
                                          onPressed: () =>
                                              _deleteService(service),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                colors.errorColor,
                                            foregroundColor: Colors.white,
                                          ),
                                          child: Text('Delete'),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
