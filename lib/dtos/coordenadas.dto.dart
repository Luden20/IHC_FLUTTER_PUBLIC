class Coordenadas {
  final double Latitud;
  final double Longitud;

  Coordenadas({required this.Latitud, required this.Longitud});

  factory Coordenadas.fromMap(Map<String, dynamic> data) => Coordenadas(
    Latitud: (data['lat'] ?? 0).toDouble(),
    Longitud: (data['lon'] ?? 0).toDouble(),
  );

  static Coordenadas? tryParse(dynamic value) {
    if (value is Map<String, dynamic>) {
      return Coordenadas.fromMap(value);
    }
    return null;
  }
  bool isValid() => Latitud != 0 && Longitud !=0;

  Map<String, double> toMap() => {'lat': Latitud, 'lon': Longitud};
}
