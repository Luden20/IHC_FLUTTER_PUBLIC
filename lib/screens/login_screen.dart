import 'dart:async';

import 'package:appihv/components/general/app_text_form_field.dart';
import 'package:appihv/components/general/form_section_label.dart';
import 'package:appihv/components/general/shinny_button.dart';
import 'package:appihv/components/general/shinny_alt_button.dart';
import 'package:appihv/screens/register_screen.dart';
import 'package:appihv/service/pocketbase.service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:url_launcher/url_launcher.dart';

import '../components/general/toast.dart';

enum _LoginAction { password, google, facebook }

class _LoginOperation {
  _LoginOperation(this.id, this.action);

  final int id;
  final _LoginAction action;
  bool cancelled = false;
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with WidgetsBindingObserver {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _passwordCtrl = TextEditingController();
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();
  bool _showPassword = false;
  _LoginOperation? _operation;
  int _operationSeed = 0;
  Timer? _resumeCheckTimer;

  bool get _isBusy => _operation != null;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _resumeCheckTimer?.cancel();
    _cancelOperation(_operation);
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;

    _resumeCheckTimer?.cancel();
    final _LoginOperation? op = _operation;
    if (op == null) return;
    if (op.action != _LoginAction.google &&
        op.action != _LoginAction.facebook) {
      return;
    }

    _resumeCheckTimer = Timer(const Duration(milliseconds: 1200), () {
      if (!mounted || op.cancelled || PBService.isLoggedIn) return;
      if (!identical(_operation, op)) return;
      _cancelOperation(op, message: 'Inicio cancelado. Inténtalo de nuevo.');
    });
  }

  Future<void> _loginWithPassword() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isBusy) return;
    FocusScope.of(context).unfocus();

    final op = _startOperation(_LoginAction.password);
    final String email = _emailCtrl.text.trim();
    final String password = _passwordCtrl.text;

    try {
      await PBService.client
          .collection('users')
          .authWithPassword(email, password);
      if (_shouldIgnore(op)) return;
      await _handlePostLogin(op);
    } catch (error) {
      if (_shouldIgnore(op)) return;
      personalizedToast(context,_errorMessageFor(error));
    } finally {
      _finishOperation(op);
    }
  }

  Future<void> _openRegister() async {
    final bool? created = await Navigator.of(
      context,
    ).push<bool>(MaterialPageRoute(builder: (_) => const RegisterScreen()));

    if (created == true && mounted) {
      personalizedToast(context,'Cuenta creada con éxito. ¡Bienvenido!');
    }
  }

  Future<void> _loginWithOAuth({
    required String provider,
    required _LoginAction action,
  }) async {
    if (_isBusy) return;

    final op = _startOperation(action);

    try {
      await PBService.client.collection('users').authWithOAuth2(provider, (
        url,
      ) async {
        var launched = await launchUrl(url, mode: LaunchMode.inAppBrowserView);

        if (!launched) {
          launched = await launchUrl(url, mode: LaunchMode.platformDefault);
        }

        if (!launched) {
          throw PlatformException(
            code: 'LAUNCH_FAILED',
            message: 'No se pudo abrir la ventana de inicio de sesión.',
          );
        }
      });

      if (_shouldIgnore(op)) return;
      await _handlePostLogin(op);
    } catch (error) {
      if (_shouldIgnore(op)) return;
      final message = _errorMessageFor(
        error,
        fallback: 'No se completó el inicio de sesión. Inténtalo nuevamente.',
      );
      personalizedToast(context,message);
    } finally {
      _finishOperation(op);
    }
  }

  String _errorMessageFor(
    Object error, {
    String fallback = 'Credenciales inválidas. Intenta nuevamente.',
  }) {
    if (error is PlatformException) {
      if (error.code == 'CANCELED') {
        return 'Inicio cancelado. Inténtalo de nuevo.';
      }
      if (error.code == 'LAUNCH_FAILED') {
        return error.message ??
            'No se pudo abrir la ventana de inicio de sesión.';
      }
      if (error.code == 'ACTIVITY_NOT_FOUND') {
        return 'No encontramos una app para continuar con el inicio de sesión.';
      }
    }

    if (error is TimeoutException) {
      return 'La solicitud tardó demasiado. Comprueba tu conexión e inténtalo de nuevo.';
    }

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

    if (error is StateError && error.message.contains('redirect')) {
      return 'No se pudo validar la respuesta del proveedor. Inténtalo de nuevo.';
    }

    return fallback;
  }

  bool _shouldIgnore(_LoginOperation op) => !mounted || op.cancelled;

  _LoginOperation _startOperation(_LoginAction action) {
    _resumeCheckTimer?.cancel();
    final op = _LoginOperation(++_operationSeed, action);
    setState(() {
      _operation = op;
    });
    return op;
  }

  void _finishOperation(_LoginOperation op) {
    if (!mounted || !identical(_operation, op)) return;
    _resumeCheckTimer?.cancel();
    setState(() {
      _operation = null;
    });
  }

  void _cancelOperation(_LoginOperation? op, {String? message}) {
    if (op == null || op.cancelled) return;
    op.cancelled = true;
    _resumeCheckTimer?.cancel();

    if (op.action != _LoginAction.password) {
      unawaited(
        PBService.client.realtime
            .unsubscribeByPrefix('@oauth2')
            .catchError((_) {}),
      );
    }

    if (mounted && identical(_operation, op)) {
      setState(() {
        _operation = null;
      });
    }

    if (message != null && mounted) {
      personalizedToast(context,message);
    }
  }

  Future<void> _handlePostLogin(_LoginOperation op) async {
    try {
      await PBService.loginActions();
      _emailCtrl.text="";
      _passwordCtrl.text="";
    } catch (error, stackTrace) {
      if (_shouldIgnore(op)) return;
      debugPrint('loginActions failed: $error\n$stackTrace');
      personalizedToast(
        context,
        "Sesión iniciada, pero no se pudieron activar las notificaciones push.",
      );
    }
  }



  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        title: Text(
          'Iniciar sesión',
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 36.0, vertical: 20),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      theme.colorScheme.secondary,
                      theme.colorScheme.primary,
                    ],
                  ).createShader(bounds),
                  child: Text(
                    'AlbuME',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.w800,
                      color: theme.colorScheme.onPrimary,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  'Tu entrada al mundo de las mejores fiestas 🎉',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: theme.colorScheme.outline,
                    fontSize: 15,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 40),
                const FormSectionLabel(text: 'Inicia sesión con tu correo'),
                const SizedBox(height: 16),
                AppTextFormField(
                  controller: _emailCtrl,
                  focusNode: _emailFocus,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.email],
                  onFieldSubmitted: (_) =>
                      FocusScope.of(context).requestFocus(_passwordFocus),
                  label: 'Correo electrónico',
                  icon: Icons.email_outlined,
                  validator: (value) {
                    final email = value?.trim() ?? '';
                    if (email.isEmpty) return 'Ingresa tu correo';
                    final emailRegex = RegExp(
                      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
                    );
                    if (!emailRegex.hasMatch(email)) return 'Correo no válido';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                AppTextFormField(
                  controller: _passwordCtrl,
                  focusNode: _passwordFocus,
                  textInputAction: TextInputAction.done,
                  obscureText: !_showPassword,
                  autofillHints: const [AutofillHints.password],
                  label: 'Contraseña',
                  icon: Icons.lock_outline,
                  suffixIcon: IconButton(
                    onPressed: () =>
                        setState(() => _showPassword = !_showPassword),
                    icon: Icon(
                      _showPassword ? Icons.visibility_off : Icons.visibility,
                    ),
                  ),
                  onFieldSubmitted: (_) => _loginWithPassword(),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Ingresa tu contraseña';
                    }
                    if (value.length < 8) {
                      return 'Debe tener al menos 8 caracteres';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                Center(
                  child: ShinnyButton(
                    onPressed: _isBusy ? null : _loginWithPassword,
                    text: 'Iniciar sesión',
                    icons: Icons.lock_open_rounded,
                    isLoading: _operation?.action == _LoginAction.password,
                    width: 230,
                    height: 48,
                  ),
                ),

                const SizedBox(height: 12),

                Center(
                  child: ShinnyButton(
                    onPressed: _isBusy ? null : _openRegister,
                    text: 'Crear cuenta nueva',
                    icons: Icons.person_add_alt_1,
                    width: 230,
                    height: 48,
                  ),
                ),

                const SizedBox(height: 32),

                Row(
                  children: [
                    Expanded(
                      child: Divider(
                        color: theme.colorScheme.outline.withOpacity(0.3),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'o continua con',
                        style: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Divider(
                        color: theme.colorScheme.outline.withOpacity(0.3),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                SocialLoginButton(
                  text: 'Google',
                  icon: Icons.g_mobiledata,
                  action: _LoginAction.google,
                  provider: 'google',
                ),

                const SizedBox(height: 18),
          /*      SocialLoginButton(
                  text: 'Continuar con Facebook',
                  icon: Icons.facebook,
                  action: _LoginAction.facebook,
                  provider: 'facebook',
                ),*/
                const SizedBox(height: 40),
                Text(
                  'Al continuar aceptas nuestros Términos y Condiciones',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: theme.disabledColor.withOpacity(0.8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget SocialLoginButton({
    required String text,
    required IconData icon,
    required _LoginAction action,
    required String provider,
  }) {
    return ShinnyButton(
      alternative: true,
      onPressed: _isBusy
          ? null
          : () => _loginWithOAuth(provider: provider, action: action),
      text: text,
      icons: icon,
      expand: false,
      isLoading: _operation?.action == action,
    );
  }
}
