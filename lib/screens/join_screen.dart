import 'package:appihv/components/general/app_text_form_field.dart';
import 'package:flutter/material.dart';
import '../components/general/toast.dart';
import '../components/general/shinny_button.dart';


import '../screen_enums.dart';
import '../service/data_provider.service.dart';
import 'qr_scanner_screen.dart';

class JoinScreen extends StatefulWidget {
  const JoinScreen({super.key, required this.onEventJoined,required this.onIndexChange});

  final ValueChanged<String> onEventJoined;
  final void Function(screens value) onIndexChange;
  @override
  State<JoinScreen> createState() => JoinScreenState();
}

class JoinScreenState extends State<JoinScreen> {
  final TextEditingController _codeController = TextEditingController();

  void clearInput() {
    _codeController.clear();
  }

  Future<void> llenar(String code) async {
    setState(() {
      _codeController.text = code;
    });
    await joinEvent();
  }
  void escanearQR() async {
    final navigator = Navigator.of(context, rootNavigator: false);
    final result = await navigator.push<String>(
      MaterialPageRoute(builder: (_) => const QrScannerScreen()),
    );
    if (!mounted || result == null || result.isEmpty) return;
    guardarResultado(result);
  }

  Future<void> guardarResultado(String valor) async {
    try{
      final aux = valor.split("=");
      valor = aux[1];
      setState(() {
        _codeController.text = valor;
      });
      await joinEvent();
    }catch(e){
      personalizedToast(context,'Código inválido');
    }

  }

  Future<void> joinEvent() async {
    try{
      final code = _codeController.text.trim();
      if (code.isEmpty) {
        personalizedToast(context,'Ingresa un código válido');
        return;
      }
      final res = await DataProvider.joinEvent(code);
      if (!mounted) return;
      personalizedToast(context, res.message);
      if (res.status.toLowerCase() == 'success') {
        // Limpia el código ingresado cuando el join fue exitoso
        setState(() {
          _codeController.clear();
        });
        widget.onEventJoined(res.id);
      }
    }
    catch(e){
      personalizedToast(context,'Error al unirse al evento,revise su conexion a internet');
    }

  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        title: Text(
          'Unirme',
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: ListView(
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),
                  Text(
                    'Unirse al Evento',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Ingresa el código para empezar la fiesta',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: theme.colorScheme.outline,
                      fontSize: 17,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 22),
                  SizedBox(
                    width: 300,
                    child: AppTextFormField(
                      controller: _codeController,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => joinEvent(),
                      label: 'Código del evento',
                      hint: 'Ingresa el código del evento',
                      icon: Icons.key_outlined,
                    ),
                  ),
                  const SizedBox(height: 40),
                  ShinnyButton(
                    alternative: true,
                    onPressed: joinEvent,
                    text: 'Unirse',
                    confetti: false,
                    icons: Icons.add,
                    width: 200,
                  ),
                  const SizedBox(height: 20),
                  ShinnyButton(
                    onPressed: escanearQR,
                    confetti: false,
                    text: 'Unirse con QR',
                    icons: Icons.qr_code_scanner,
                    width: 200,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
