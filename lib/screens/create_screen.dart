import 'dart:io';
import 'dart:async';
import 'package:appihv/components/general/toast.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' show MultipartFile;
// Using Theme.of(context).colorScheme directly

import '../components/general/app_text_form_field.dart';
import '../components/general/shinny_button.dart';
import '../components/general/shinny_alt_button.dart';
import '../dtos/coordenadas.dto.dart';
import '../service/pocketbase.service.dart';
import '../service/place_picker.service.dart';
import '../service/date_time.util.dart';

class CreateScreen extends StatefulWidget {
  const CreateScreen({super.key, required this.onEventCreated});

  final ValueChanged<String> onEventCreated;

  @override
  State<CreateScreen> createState() => _CreateScreenState();
}

class _CreateScreenState extends State<CreateScreen> {
  final _frm = GlobalKey<FormState>();
  final _tituloCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _lugarCtrl = TextEditingController();
  final FocusNode _tituloFocus = FocusNode();
  final FocusNode _descFocus = FocusNode();
  final FocusNode _lugarFocus = FocusNode();
  DateTime? _fecha;
  XFile? _portada;
  Coordenadas? _geoLugar;
  bool _loading = false;

  @override
  void dispose() {
    _tituloCtrl.dispose();
    _descCtrl.dispose();
    _lugarCtrl.dispose();
    _tituloFocus.dispose();
    _descFocus.dispose();
    _lugarFocus.dispose();
    super.dispose();
  }

  Future<void> _pickPortada() async {
    final picker = ImagePicker();
    final img = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (img != null) setState(() => _portada = img);
  }

  Future<void> _pickFecha() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final initial = _fecha ?? today;
    final d = await showDatePicker(
      context: context,
      firstDate: today,
      lastDate: today.add(const Duration(days: 365 * 3)),
      initialDate: initial.isBefore(today) ? today : initial,
    );
    if (d == null) return;
    final t = await showTimePicker(
      context: context,
      initialTime: _fecha != null
          ? TimeOfDay.fromDateTime(_fecha!)
          : TimeOfDay.now(),
    );
    if (t == null) return;
    setState(() => _fecha = DateTime(d.year, d.month, d.day, t.hour, t.minute));
  }

  Future<void> _pickGeoLugar() async {
    final initialPosition = _geoLugar == null
        ? null
        : LatLng(_geoLugar!.Latitud, _geoLugar!.Longitud);
    final result = await PlacePickerService.pickPlace(
      context: context,
      initialPosition: initialPosition,
    );
    if (!mounted || result == null) return;
    final location = result.geometry?.location;
    if (location == null) return;
    setState(() {
      _geoLugar = Coordenadas(Latitud: location.lat, Longitud: location.lng);
    });
  }

  void _clearGeoLugar() {
    setState(() {
      _geoLugar = null;
    });
  }

  void _clearLugarText() {
    if (_lugarCtrl.text.isEmpty) return;
    _lugarCtrl.clear();
  }

  Future<void> _submit() async {
    if (!_frm.currentState!.validate()) return;
    if (_fecha == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Selecciona la fecha')));
      return;
    }

    setState(() => _loading = true);

    try {
      final Map<String, dynamic> body = {
        "Titulo": _tituloCtrl.text.trim(),
        "Descripcion": _descCtrl.text.trim(),
        // Guardar normalizado en UTC con formato PocketBase (espacio)
        "Fecha": formatAsPocketbaseUtc(_fecha!, useSpaceSeparator: true),
        "Lugar": _lugarCtrl.text.trim().isEmpty ? null : _lugarCtrl.text.trim(),
        "Creador": PBService.actualUser?.id,
      };
      if (_geoLugar != null) {
        body['GeoLugar'] = _geoLugar!.toMap();
      }

      final List<MultipartFile> files = _portada != null
          ? [await MultipartFile.fromPath('Portada', _portada!.path)]
          : [];

      final record = await PBService.client
          .collection('evento_cabecera')
          .create(body: body, files: files);

      if (!mounted) return;
      widget.onEventCreated(record.id);
      _resetForm();
    } catch (e) {
      if (!mounted) return;
      personalizedToast(context,"Error al crear, revise su conexion");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Colors.transparent, // Fondo transparente para degradado
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        title: Text(
          'Crear evento',
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        centerTitle: true,
        //elevation: 5,
      ),
      body: Form(
        key: _frm,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'Hora de la fiesta!!!',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.secondary,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 20),

            // 🔸 Campo: Título
            AppTextFormField(
              icon: Icons.event,
              controller: _tituloCtrl,
              focusNode: _tituloFocus,
              textInputAction: TextInputAction.next,
              onFieldSubmitted: (_) =>
                  FocusScope.of(context).requestFocus(_descFocus),
              label: 'Título',
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Requerido' : null,
            ),

            const SizedBox(height: 20),

            // 🔸 Campo: Descripción
            AppTextFormField(
              controller: _descCtrl,
              focusNode: _descFocus,
              keyboardType: TextInputType.multiline,
              textInputAction: TextInputAction.next,
              onFieldSubmitted: (_) =>
                  FocusScope.of(context).requestFocus(_lugarFocus),
              maxLines: 3,
              icon: Icons.description_outlined,

              label: 'Descripción',
            ),

            const SizedBox(height: 20),

            // 🔸 Selector de fecha
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: theme.colorScheme.outline),
                    ),
                    child: Text(
                      _fecha == null
                          ? 'Sin seleccionar'
                          : formatLocalYmdHHmm(_fecha!),
                      style: TextStyle(
                        color: _fecha == null
                            ? theme.disabledColor
                            : theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ShinnyButton(
                  onPressed: _pickFecha,
                  text: 'Elegir',
                  icons: Icons.event,
                  expand: false,
                  height: 52,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // 🔸 Campo: Lugar
            AppTextFormField(
              controller: _lugarCtrl,
              focusNode: _lugarFocus,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _submit(),
              label: 'Lugar (opcional)',
              icon: Icons.location_on_outlined,
              suffixIcon: IconButton(
                tooltip: 'Limpiar texto',
                icon: const Icon(Icons.clear),
                onPressed: _clearLugarText,
              ),
            ),

            const SizedBox(height: 20),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: theme.colorScheme.outline),
              ),
              child: Row(
                children: [
                  Icon(Icons.location_on_outlined,
                      color: theme.colorScheme.secondary),

                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _geoLugar == null
                          ? 'Lugar en el mapa (Opcional)'
                          : 'Lugar seleccionado',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                  ShinnyButton(onPressed:_pickGeoLugar , text: '',expand: false,icons: Icons.map_outlined,),
                  if (_geoLugar != null)
                    IconButton(
                      tooltip: 'Quitar coordenadas',
                      icon: const Icon(Icons.clear),
                      onPressed: _clearGeoLugar,
                    ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: theme.colorScheme.outline),
              ),
              child: Row(
                children: [
                  if (_portada != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.file(
                          File(_portada!.path),
                          width: 72,
                          height: 72,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ShinnyButton(
                    onPressed: _pickPortada,
                    text: _portada == null ? 'Seleccionar' : 'Cambiar',
                    icons: Icons.image_outlined,
                    expand: false,
                    height: 52,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            Center(
              child: ShinnyButton(
                alternative: true,
                icons: Icons.create,
                onPressed: _loading ? null : _submit,
                text: 'Crear evento',
                isLoading: _loading,
                confetti: true,
                width: 230,
                height: 60,
              ),
            ),



          ],
        ),
      ),
    );
  }

  void _resetForm() {
    _frm.currentState?.reset();
    _tituloCtrl.clear();
    _descCtrl.clear();
    _lugarCtrl.clear();
    FocusScope.of(context).unfocus();
    setState(() {
      _fecha = null;
      _portada = null;
      _geoLugar = null;
    });
  }
}
