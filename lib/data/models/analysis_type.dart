/// Tipos de análisis que ofrece la app y el endpoint de la API que usa cada uno.
enum AnalysisType {
  /// Planta (pepino) → YOLOv11 en `POST /predict/cucumber`.
  plant(
    id: 'plant',
    title: 'Analizar planta',
    category: 'Salud del cultivo',
    description: 'Detecta enfermedades y deficiencias',
    eyebrow: 'Diagnóstico vegetal',
    shortLabel: 'Planta',
    captureHint: 'la zona afectada de la planta',
    endpoint: '/predict/cucumber',
    photoUrl: 'https://images.unsplash.com/photo-1624720114682-3c8c43b75227?auto=format&fit=crop&w=900&q=85',
  ),

  /// Agua (bacterias) → EfficientNet-B0 en `POST /predict/bacteria`.
  water(
    id: 'water',
    title: 'Analizar agua',
    category: 'Calidad del recurso',
    description: 'Identifica anomalías visibles',
    eyebrow: 'Calidad del agua',
    shortLabel: 'Agua',
    captureHint: 'la muestra de agua',
    endpoint: '/predict/bacteria',
    photoUrl: 'https://images.unsplash.com/photo-1785063350700-8f6f2f894506?auto=format&fit=crop&w=900&q=85',
  );

  const AnalysisType({
    required this.id,
    required this.title,
    required this.category,
    required this.description,
    required this.eyebrow,
    required this.shortLabel,
    required this.captureHint,
    required this.endpoint,
    required this.photoUrl,
  });

  final String id;
  final String title;
  final String category;
  final String description;
  final String eyebrow;
  final String shortLabel;
  final String captureHint;
  final String endpoint;
  final String photoUrl;

  static AnalysisType fromId(String id) =>
      values.firstWhere((t) => t.id == id, orElse: () => AnalysisType.plant);
}
