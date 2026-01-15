import 'package:flutter/material.dart';
import '../../services/service_service.dart';
import '../../models/service.dart';
import '../../theme/app_theme.dart';

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
  final _categoryController = TextEditingController();

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
    _categoryController.dispose();
    super.dispose();
  }

  Future<void> _loadServices() async {
    try {
      final services = await _serviceService.getServices();
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
        _categoryController.text = service.category;
      } else {
        _nameController.clear();
        _descriptionController.clear();
        _durationController.clear();
        _priceController.clear();
        _categoryController.clear();
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
      _categoryController.clear();
      _error = null;
    });
  }

  Future<void> _saveService() async {
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
          category: _categoryController.text.trim(),
        );
      } else {
        await _serviceService.createService(
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          duration: int.parse(_durationController.text),
          price: double.parse(_priceController.text),
          category: _categoryController.text.trim(),
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
            backgroundColor: AppTheme.accentColor,
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Service'),
        content: const Text(
          'Are you sure you want to delete this service?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.errorColor,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _serviceService.deleteService(service.id);
        _loadServices();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Service deleted successfully'),
              backgroundColor: AppTheme.accentColor,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete service: $e'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
                  decoration: const InputDecoration(
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
                TextFormField(
                  controller: _categoryController,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    hintText: 'e.g., Consultation, Treatment, Checkup',
                    prefixIcon: Icon(Icons.category_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter category';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    prefixIcon: Icon(Icons.description_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter description';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _durationController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Duration (minutes)',
                    prefixIcon: Icon(Icons.access_time),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter duration';
                    }
                    if (int.tryParse(value) == null || int.parse(value) < 15) {
                      return 'Duration must be at least 15 minutes';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _priceController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Price (\$)',
                    prefixIcon: Icon(Icons.attach_money),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter price';
                    }
                    if (double.tryParse(value) == null ||
                        double.parse(value) < 0) {
                      return 'Please enter a valid price';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      _error!,
                      style: const TextStyle(color: AppTheme.errorColor),
                    ),
                  ),
                ElevatedButton(
                  onPressed: _loading ? null : _saveService,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
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
                  child: const Text('Cancel'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Services'),
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
                    label: const Text('Add New Service'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
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
                                color: AppTheme.textSecondary,
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
                                            color: AppTheme.primaryColor
                                                .withOpacity(0.1),
                                            borderRadius:
                                                BorderRadius.circular(20),
                                          ),
                                          child: Text(
                                            service.category,
                                            style: TextStyle(
                                              color: AppTheme.primaryColor,
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
                                          color: AppTheme.textSecondary,
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
                                          color: AppTheme.textSecondary,
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
                                    const SizedBox(height: 16),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        OutlinedButton(
                                          onPressed: () => _openForm(
                                            service: service,
                                          ),
                                          child: const Text('Edit'),
                                        ),
                                        const SizedBox(width: 8),
                                        ElevatedButton(
                                          onPressed: () =>
                                              _deleteService(service),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                AppTheme.errorColor,
                                            foregroundColor: Colors.white,
                                          ),
                                          child: const Text('Delete'),
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
