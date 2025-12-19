import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' show MultipartFile;

import '../components/event_specific/party_hat_fallback.dart';
import '../components/general/app_text_form_field.dart';
import '../components/general/shinny_button.dart';
import '../dtos/coordenadas.dto.dart';
import '../service/data_provider.service.dart';
import '../service/pocketbase.service.dart';
import '../service/place_picker.service.dart';
import '../service/date_time.util.dart';

class EditEventScreen extends StatefulWidget {
  const EditEventScreen({super.key, required this.eventId});

  final String eventId;

  @override
  State<EditEventScreen> createState() => _EditEventScreenState();
}

class _EditEventScreenState extends State<EditEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleCtrl = TextEditingController();
  final TextEditingController _descriptionCtrl = TextEditingController();
  final TextEditingController _placeCtrl = TextEditingController();

  final ImagePicker _picker = ImagePicker();

  bool _initializing = true;
  bool _loading = false;
  DateTime? _date;
  XFile? _cover;
  String? _currentCoverUrl;
  Coordenadas? _geoLugar;
  bool _geoLugarDirty = false;

  @override
  void initState() {
    super.initState();
    _loadEvent();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descriptionCtrl.dispose();
    _placeCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadEvent() async {
    try {
      final evento = await DataProvider.getEvento(
        widget.eventId,
        forceRefresh: true,
      );
      final parsedDate = parsePocketbaseDate(evento.Fecha)?.toLocal();
      // Si la fecha del evento es anterior a hoy, por defecto usaremos hoy manteniendo la hora
      DateTime? normalizedDate = parsedDate;
      if (parsedDate != null) {
        final now = DateTime.now();
        final todayStart = DateTime(now.year, now.month, now.day);
        if (parsedDate.isBefore(todayStart)) {
          normalizedDate = DateTime(
            todayStart.year,
            todayStart.month,
            todayStart.day,
            parsedDate.hour,
            parsedDate.minute,
          );
        }
      }

      setState(() {
        _titleCtrl.text = evento.Titulo;
        _descriptionCtrl.text = evento.Descripcion;
        _placeCtrl.text = evento.Lugar;
        _date = normalizedDate;
        _currentCoverUrl =
            _isValidCoverUrl(evento.Portada) ? evento.Portada : null;
        _geoLugar = evento.GeoLugar;
        _geoLugarDirty = false;
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo cargar el evento: $error')),
      );
      Navigator.of(context).pop();
    } finally {
      if (mounted) {
        setState(() => _initializing = false);
      }
    }
  }

  Future<void> _pickGeoLugar() async {
    final initial = _geoLugar == null
        ? null
        : LatLng(_geoLugar!.Latitud, _geoLugar!.Longitud);
    final result = await PlacePickerService.pickPlace(
      context: context,
      initialPosition: initial,
    );
    if (!mounted || result == null) return;
    final geo = result.geometry?.location;
    if (geo == null) return;
    setState(() {
      _geoLugar = Coordenadas(Latitud: geo.lat, Longitud: geo.lng);
      _geoLugarDirty = true;
    });
  }

  void _clearGeoLugar() {
    setState(() {
      _geoLugar = null;
      _geoLugarDirty = true;
    });
  }

  void _clearPlaceText() {
    if (_placeCtrl.text.isEmpty) return;
    _placeCtrl.clear();
  }

  Future<void> _pickCover() async {
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (file != null) {
      setState(() {
        _cover = file;
      });
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    DateTime initialDate = _date ?? today;
    if (initialDate.isBefore(today)) {
      initialDate = today;
    }
    final firstDate = today;
    final lastDate = today.add(const Duration(days: 365 * 3));

    final date = await showDatePicker(
      context: context,
      firstDate: firstDate,
      lastDate: lastDate,
      initialDate: initialDate,
    );
    if (date == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initialDate),
    );
    if (time == null) return;

    setState(() {
      _date = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _submit() async {
    if (_loading) return;
    if (!_formKey.currentState!.validate()) return;

    if (_date == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona la fecha del evento')),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final body = <String, dynamic>{
        'Titulo': _titleCtrl.text.trim(),
        'Descripcion': _descriptionCtrl.text.trim(),
        // Guardar normalizado en UTC con formato PocketBase (espacio)
        'Fecha': formatAsPocketbaseUtc(_date!, useSpaceSeparator: true),
        'Lugar': _placeCtrl.text.trim().isEmpty ? null : _placeCtrl.text.trim(),
      };
      if (_geoLugarDirty) {
        body['GeoLugar'] = _geoLugar?.toMap();
      }

      final files = <MultipartFile>[];
      if (_cover != null) {
        files.add(await MultipartFile.fromPath('Portada', _cover!.path));
      }
      await PBService.client
          .collection('evento_cabecera')
          .update(widget.eventId, body: body, files: files);
      DataProvider.notifyEventoActualizado(widget.eventId);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Evento actualizado correctamente')),
      );
      Navigator.of(context).pop(widget.eventId);
    } catch (error) {
      debugPrint('EditEventScreen error: $error');
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al actualizar')));
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  bool _isValidCoverUrl(String? url) {
    if (url == null) return false;
    final trimmed = url.trim();
    if (trimmed.isEmpty) return false;
    final uri = Uri.tryParse(trimmed);
    if (uri == null) return false;
    if (uri.pathSegments.isEmpty) return false;
    return uri.pathSegments.last.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        title: Text(
          'Editar evento',
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        centerTitle: true,
        leading: BackButton(
          onPressed: () {
            Navigator.of(context).maybePop();
          },
        ),
      ),
      body: _initializing
          ? Center(
              child: CircularProgressIndicator(
                color: theme.colorScheme.primary,
              ),
            )
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Text(
                    'Hora de la fiesta!!!',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.secondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  AppTextFormField(
                    controller: _titleCtrl,
                    label: 'Título',
                    icon: Icons.event,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Requerido';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  AppTextFormField(
                    controller: _descriptionCtrl,
                    maxLines: 3,
                    keyboardType: TextInputType.multiline,
                    label: 'Descripción (Opcional)',
                    icon: Icons.description_outlined,
                  ),
                  const SizedBox(height: 20),
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
                          child: Row(
                            children: [
                              const Icon(Icons.date_range),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _date == null
                                      ? 'Sin seleccionar'
                                      : formatLocalYmdHHmm(_date!),
                                  style: theme.textTheme.bodyMedium,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ShinnyButton(
                        onPressed: _pickDate,
                        text: 'Elegir',
                        expand: false,
                        icons: Icons.event,
                        height: 52,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  AppTextFormField(
                    controller: _placeCtrl,
                    label: 'Lugar (opcional)',
                    icon: Icons.location_on_outlined,
                    suffixIcon: IconButton(
                      tooltip: 'Limpiar texto',
                      icon: const Icon(Icons.clear),
                        onPressed: _clearPlaceText,
                      ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                          child: Row(
                            children: [
                              Icon(Icons.location_on_outlined,
                                  color: theme.colorScheme.secondary),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  (_geoLugar != null &&
                                          (_geoLugar?.Latitud != 0 ||
                                              _geoLugar?.Longitud != 0))
                                      ? 'Geo-ubicación seleccionada'
                                      : 'Geo-ubicación (Opcional)',
                                  style: theme.textTheme.bodyMedium,
                                ),
                              ),
                              if (_geoLugar != null &&
                                  (_geoLugar?.Latitud != 0 ||
                                      _geoLugar?.Longitud != 0))
                                IconButton(
                                  tooltip: 'Quitar coordenadas',
                                  icon: const Icon(Icons.clear),
                                  onPressed: _clearGeoLugar,
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ShinnyButton(
                        onPressed: _pickGeoLugar,
                        text: 'Elegir',
                        expand: false,
                        icons: Icons.map_outlined,
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ShinnyButton(
                          onPressed: _pickCover,
                          text: _cover == null ? 'Seleccionar' : 'Cambiar',
                          icons: Icons.image_outlined,
                          expand: false,
                          height: 52,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                        ),
                        const SizedBox(width: 12),
                        if (_cover != null)
                          Padding(
                            padding: const EdgeInsets.only(left: 12),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.file(
                                File(_cover!.path),
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                              ),
                            ),
                          )
                        else if (_currentCoverUrl != null)
                          Padding(
                            padding: const EdgeInsets.only(left: 12),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.network(
                                _currentCoverUrl!,
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                              ),
                            ),
                          )
                        else
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: SizedBox(
                              width: 100,
                              height: 100,
                              child: Stack(
                                children: [
                                  Positioned.fill(
                                    child: Container(
                                      color: theme.colorScheme.primary
                                          .withOpacity(0.1),
                                    ),
                                  ),
                                  const Positioned.fill(child: PartyHatFallback()),
                                ],
                              ),
                            ),
                          ),

                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  Center(
                    child: ShinnyButton(
                      alternative: true,
                      onPressed: _loading ? null : _submit,
                      text: 'Guardar cambios',
                      icons: Icons.edit,
                      isLoading: _loading,
                      confetti: false,
                      width: 230,
                      height: 60,
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
