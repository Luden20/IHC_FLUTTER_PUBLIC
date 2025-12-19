import 'dart:async';

import 'package:appihv/components/general/shinny_button.dart';
import 'package:appihv/components/general/toast.dart';

import 'package:appihv/dtos/users.dart';
import 'package:appihv/service/pocketbase.service.dart';
import 'package:appihv/theme/app_theme.dart';
import 'package:flutter/material.dart';

import '../components/profile_specific/buttons/logout_button.dart';
import '../components/profile_specific/buttons/notification_button.dart';
import '../components/profile_specific/buttons/theme_button.dart';
import '../service/data_provider.service.dart';
import 'register_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, required this.themeController});

  final AppThemeController themeController;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  ActualUserDTO? _usuario;
  bool _loading = false;
  StreamSubscription? _authSub;

  @override
  void initState() {
    super.initState();
    _usuario = PBService.isLoggedIn ? DataProvider.getUser() : null;
    //_refreshUser();
    // Mantener el perfil sincronizado cuando cambia la sesión
    _authSub = PBService.client.authStore.onChange.listen((_) {
      if (!mounted) return;
      if (PBService.isLoggedIn) {
        setState(() {
          _usuario = DataProvider.getUser();
        });
      } else {
        setState(() {
          _usuario = null;
        });
      }
    });
  }

  Future<void> _refreshUser() async {
    if (!PBService.isLoggedIn || !mounted) return;
    setState(() => _loading = true);
    try {
      final updated = await PBService.client
          .collection('users')
          .getOne(PBService.actualUser!.id);
      if (!mounted) return;
      setState(() {
        _usuario = ActualUserDTO.fromRecordModel(updated);
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }



  @override
  Widget build(BuildContext context) {
    final ActualUserDTO? usuario = _usuario;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        title: Text(
          'Perfil',
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),



      body: usuario == null
          ? Center(
              child: _loading
                  ? const CircularProgressIndicator()
                  : const Text('No se pudo cargar el perfil.'),
            )
          : Center(
              child: ListView(
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 30),
                      Container(
                        margin: const EdgeInsets.only(bottom: 20),
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: theme.colorScheme.primary,
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 75,
                          backgroundColor: theme.colorScheme.surface,
                          backgroundImage: usuario.avatar.isNotEmpty
                              ? NetworkImage(usuario.avatar)
                              : null,
                          child: usuario.avatar.isEmpty
                              ? Icon(
                                  Icons.person,
                                  size: 64,
                                  color: theme.colorScheme.onSurfaceVariant,
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        usuario.name,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onBackground,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        usuario.email,
                        style: TextStyle(
                          fontSize: 16,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 30),
                      AnimatedBuilder(
                        animation: widget.themeController,
                        builder: (context, _) {
                          final isDark = widget.themeController.mode == AppThemeMode.dark;
                          return ThemeButton(isDark: isDark, widget: widget);
                        },
                      ),
                      const SizedBox(height: 24),

                      NotificationButton(),
                      const SizedBox(height: 24),
                      ShinnyButton(
                        onPressed: _loading
                            ? null
                            : () async {
                                final bool? updated = await Navigator.of(context)
                                    .push<bool>(
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            RegisterScreen(usuario: usuario),
                                      ),
                                    );

                                if (updated == true && mounted) {
                                  await _refreshUser();
                                  if (!mounted) return;
                                  personalizedToast(context, 'Perfil actualizado.');
                                }
                              },
                        text: 'Editar perfil',
                        icons: Icons.edit_outlined,
                        width: 220,
                        height: 48,
                        isLoading: _loading,
                      ),
                      const SizedBox(height: 24),

                      LogoutButton(),
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }
}


