import 'dart:io';

import 'package:appihv/components/general/app_text_form_field.dart';
import 'package:appihv/components/general/form_section_label.dart';
import 'package:appihv/components/general/shinny_button.dart';
import 'package:appihv/service/pocketbase.service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' show MultipartFile;
import 'package:image_picker/image_picker.dart';
import 'package:pocketbase/pocketbase.dart';

import '../dtos/users.dart';

class RegisterScreen extends StatefulWidget {
  final ActualUserDTO? usuario;
  const RegisterScreen({super.key, this.usuario});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _passwordCtrl = TextEditingController();
  final TextEditingController _confirmCtrl = TextEditingController();
  final FocusNode _nameFocus = FocusNode();
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();
  final FocusNode _confirmFocus = FocusNode();

  XFile? _avatar;

  bool _loading = false;
  bool _showPassword = false;
  bool _showConfirm = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    _nameFocus.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _confirmFocus.dispose();
    super.dispose();
  }
  @override
  void initState() {
    super.initState();
    final user = widget.usuario;
    if (user != null) {
      _nameCtrl.text = user.name;
      _emailCtrl.text = user.email;
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    setState(() => _loading = true);

    try {
      final bool isEdit = widget.usuario != null;
      final String email =
          isEdit ? widget.usuario!.email : _emailCtrl.text.trim();
      final files = <MultipartFile>[];
      final body = <String, dynamic>{
        'email': email,
        'name': _nameCtrl.text.trim(),
        'emailVisibility': true,
      };
      String? password;
      if (!isEdit) {
        password = _passwordCtrl.text;
        body['password'] = password;
        body['passwordConfirm'] = _confirmCtrl.text;
      }
      if (_avatar != null) {
        files.add(await MultipartFile.fromPath('avatar', _avatar!.path));
      }
      if (!isEdit) {
        await PBService.client.collection('users').create(
          body: body,
          files: files,
        );
      } else {
        final updated = await PBService.client.collection('users').update(
          widget.usuario!.id,
          body: body,
          files: files,
        );
        final String token = PBService.client.authStore.token;
        PBService.client.authStore.save(token, updated);
      }

      if (!isEdit) {
        await PBService.client
            .collection('users')
            .authWithPassword(email, password!);
        await PBService.loginActions();
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      debugPrint('RegisterScreen error: $error');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_errorMessageFor(error))),
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );

    if (picked != null) {
      setState(() => _avatar = picked);
    }
  }

  String _errorMessageFor(Object error) {
    if (error is ClientException) {
      final dynamic message = error.response['message'];
      if (message is String && message.isNotEmpty) return message;

      final dynamic data = error.response['data'];
      if (data is Map<String, dynamic>) {
        for (final dynamic entry in data.values) {
          if (entry is Map<String, dynamic>) {
            final dynamic msg = entry['message'];
            if (msg is String && msg.isNotEmpty) return msg;
          }
        }
      }
    }
    return 'No se pudo realizar la accion. Intenta nuevamente.';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isEdit = widget.usuario != null;
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        title: Text(
          (widget.usuario == null) ? 'Crear cuenta' : 'Editar cuenta',
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Únete a AlbuME',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onBackground,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Crea tu cuenta para descubrir y crear los mejores eventos.',
                style: TextStyle(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 28),
              const FormSectionLabel(
                text: 'Avatar',
                icon: Icons.photo_camera_front,
              ),
              const SizedBox(height: 16),
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            theme.colorScheme.secondary.withOpacity(0.6),
                            theme.colorScheme.primary.withOpacity(0.6),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: theme.colorScheme.secondary.withOpacity(0.4),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 52,
                        backgroundColor: theme.colorScheme.surface,
                        backgroundImage:
                        _avatar != null
                            ? FileImage(File(_avatar!.path))
                            : (widget.usuario?.avatar != null
                            ? NetworkImage(widget.usuario!.avatar)
                            : null),
                      ),
                    ),
                    const SizedBox(height: 14),
                    ShinnyButton(
                      onPressed: _loading ? null : _pickAvatar,
                      text: _avatar == null
                          ? 'Seleccionar imagen'
                          : 'Cambiar imagen',
                      icons: Icons.image_outlined,
                      width: 200,
                      height: 48,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              const FormSectionLabel(
                text: 'Datos de acceso',
                icon: Icons.assignment_ind_rounded,
              ),
              const SizedBox(height: 16),
              AppTextFormField(
                controller: _nameCtrl,
                focusNode: _nameFocus,
                textInputAction:
                    isEdit ? TextInputAction.done : TextInputAction.next,
                onFieldSubmitted: (_) {
                  if (!isEdit) {
                    FocusScope.of(context).requestFocus(_emailFocus);
                  } else {
                    _submit();
                  }
                },
                label: 'Nombre',
                icon: Icons.person,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Ingresa tu nombre';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              if (!isEdit)
                AppTextFormField(
                  controller: _emailCtrl,
                  focusNode: _emailFocus,
                  textInputAction: TextInputAction.next,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  onFieldSubmitted: (_) =>
                      FocusScope.of(context).requestFocus(_passwordFocus),
                  label: 'Correo electrónico',
                  icon: Icons.email_outlined,
                  validator: (value) {
                    final email = value?.trim() ?? '';
                    if (email.isEmpty) {
                      return 'Ingresa tu correo';
                    }
                    final emailRegex =
                        RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                    if (!emailRegex.hasMatch(email)) {
                      return 'Correo no válido';
                    }
                    return null;
                  },
                ),

              const SizedBox(height: 16),
              if (!isEdit) ...[
                AppTextFormField(
                  controller: _passwordCtrl,
                  focusNode: _passwordFocus,
                  textInputAction: TextInputAction.next,
                  onFieldSubmitted: (_) =>
                      FocusScope.of(context).requestFocus(_confirmFocus),
                  obscureText: !_showPassword,
                  autofillHints: const [AutofillHints.newPassword],
                  label: 'Contraseña',
                  icon: Icons.lock_outline,
                  suffixIcon: IconButton(
                    onPressed: () =>
                        setState(() => _showPassword = !_showPassword),
                    icon: Icon(
                      _showPassword ? Icons.visibility_off : Icons.visibility,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Ingresa una contraseña';
                    }
                    if (value.length < 8) {
                      return 'La contraseña debe tener al menos 8 caracteres';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                AppTextFormField(
                  controller: _confirmCtrl,
                  focusNode: _confirmFocus,
                  textInputAction: TextInputAction.done,
                  obscureText: !_showConfirm,
                  autofillHints: const [AutofillHints.newPassword],
                  label: 'Confirmar contraseña',
                  icon: Icons.lock_person_outlined,
                  suffixIcon: IconButton(
                    onPressed: () =>
                        setState(() => _showConfirm = !_showConfirm),
                    icon: Icon(
                      _showConfirm ? Icons.visibility_off : Icons.visibility,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Confirma tu contraseña';
                    }
                    if (value != _passwordCtrl.text) {
                      return 'Las contraseñas no coinciden';
                    }
                    return null;
                  },
                ),
              ],
              const SizedBox(height: 24),
              ShinnyButton(
                alternative: true,
                onPressed: _loading ? null : _submit,
                text: isEdit ? 'Guardar cambios' : 'Crear cuenta',
                icons: isEdit ? Icons.save_outlined : Icons.person_add_alt_1,
                isLoading: _loading,
              ),
              const SizedBox(height: 16),
              if (!isEdit)...[
                Text(
                  'Al registrarte aceptas nuestros Términos y Condiciones.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: theme.disabledColor,
                    fontSize: 12,
                  ),
                )
              ]
,
            ],
          ),
        ),
      ),
    );
  }
}
