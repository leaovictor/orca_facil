import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../widgets/custom_button.dart';
import '../../core/theme/app_theme.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _picker = ImagePicker();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(currentUserProvider).value;
    if (user != null) {
      _nameController.text = user.name;
      _phoneController.text = user.phone ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image == null) return;

      setState(() => _isLoading = true);

      // Read as bytes to be cross-platform compatible
      final bytes = await image.readAsBytes();

      await ref.read(authViewModelProvider.notifier).uploadProfileImage(bytes);

      setState(() => _isLoading = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Foto de perfil atualizada!'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao atualizar foto: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      await ref
          .read(authViewModelProvider.notifier)
          .updateProfile(
            name: _nameController.text.trim(),
            phone: _phoneController.text.trim(),
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Perfil atualizado com sucesso!'),
            backgroundColor: AppTheme.successColor,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao atualizar perfil: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    var userAsync = ref.watch(currentUserProvider);
    final authState = ref.watch(authViewModelProvider);
    final isLoading = authState.isLoading || _isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('Editar Perfil')),
      body: userAsync.when(
        data: (user) {
          if (user == null) {
            return const Center(child: Text('Usuário não encontrado'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  Center(
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 60,
                          backgroundColor: Colors.grey[200],
                          backgroundImage: user.photoUrl != null
                              ? NetworkImage(user.photoUrl!)
                              : null,
                          child: user.photoUrl == null
                              ? Text(
                                  user.name.isNotEmpty
                                      ? user.name[0].toUpperCase()
                                      : 'U',
                                  style: const TextStyle(
                                    fontSize: 40,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: isLoading ? null : _pickImage,
                            child: CircleAvatar(
                              radius: 20,
                              backgroundColor: AppTheme.primaryBlue,
                              child: const Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nome Completo',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor, informe seu nome';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Telefone',
                      prefixIcon: Icon(Icons.phone_outlined),
                    ),
                  ),
                  const SizedBox(height: 32),
                  CustomButton(
                    text: 'Salvar Alterações',
                    onPressed: isLoading ? null : _saveProfile,
                    isLoading: isLoading,
                  ),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Erro: $error')),
      ),
    );
  }
}
