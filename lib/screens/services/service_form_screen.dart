import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../viewmodels/service_viewmodel.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../models/service_model.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_button.dart';

class ServiceFormScreen extends ConsumerStatefulWidget {
  final String? serviceId; // null for new service

  const ServiceFormScreen({super.key, this.serviceId});

  @override
  ConsumerState<ServiceFormScreen> createState() => _ServiceFormScreenState();
}

class _ServiceFormScreenState extends ConsumerState<ServiceFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();

  bool _isLoading = false;
  bool _isEditing = false;
  ServiceModel? _existingService;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.serviceId != null;
    if (_isEditing) {
      _loadService();
    }
  }

  Future<void> _loadService() async {
    setState(() => _isLoading = true);
    try {
      final services = await ref.read(servicesStreamProvider.future);
      _existingService = services.firstWhere((s) => s.id == widget.serviceId);

      _nameController.text = _existingService!.name;
      _descriptionController.text = _existingService!.description;
      _priceController.text = _existingService!.unitPrice.toStringAsFixed(2);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao carregar serviço: $e'),
            backgroundColor: Colors.red,
          ),
        );
        context.pop();
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _saveService() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final price = double.parse(_priceController.text.replaceAll(',', '.'));
      final user = ref.read(authStateProvider).value;

      if (user == null) throw Exception('Usuário não autenticado');

      if (_isEditing) {
        await ref
            .read(serviceViewModelProvider.notifier)
            .updateService(
              serviceId: _existingService!.id,
              name: _nameController.text.trim(),
              description: _descriptionController.text.trim(),
              unitPrice: price,
            );
      } else {
        await ref
            .read(serviceViewModelProvider.notifier)
            .createService(
              userId: user.uid,
              name: _nameController.text.trim(),
              description: _descriptionController.text.trim(),
              unitPrice: price,
            );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditing
                  ? 'Serviço atualizado com sucesso!'
                  : 'Serviço criado com sucesso!',
            ),
            backgroundColor: Colors.green,
          ),
        );
        context.pop();
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar Serviço' : 'Novo Serviço'),
      ),
      body: _isLoading && _isEditing
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header
                    Text(
                      _isEditing
                          ? 'Atualize as informações do serviço'
                          : 'Preencha os dados do novo serviço',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Name field
                    CustomTextField(
                      controller: _nameController,
                      label: 'Nome do Serviço',
                      hint: 'Ex: Instalação de tomada',
                      prefixIcon: Icons.build,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Nome é obrigatório';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Description field
                    CustomTextField(
                      controller: _descriptionController,
                      label: 'Descrição',
                      hint: 'Descreva o serviço (opcional)',
                      prefixIcon: Icons.description,
                      maxLines: 4,
                    ),
                    const SizedBox(height: 16),

                    // Price field
                    CustomTextField(
                      controller: _priceController,
                      label: 'Preço Unitário',
                      hint: '0,00',
                      prefixIcon: Icons.attach_money,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Preço é obrigatório';
                        }
                        final price = double.tryParse(
                          value.replaceAll(',', '.'),
                        );
                        if (price == null || price <= 0) {
                          return 'Insira um preço válido';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),

                    // Save button
                    CustomButton(
                      text: _isEditing ? 'Salvar Alterações' : 'Criar Serviço',
                      onPressed: _saveService,
                      isLoading: _isLoading,
                    ),
                    const SizedBox(height: 12),

                    // Cancel button
                    OutlinedButton(
                      onPressed: _isLoading ? null : () => context.pop(),
                      child: const Text('Cancelar'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
