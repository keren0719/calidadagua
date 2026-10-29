import '../models/analysis_result.dart';

/// Texto que se muestra al usuario para cada clase que devuelve un modelo.
class DiagnosisInfo {
  const DiagnosisInfo({
    required this.status,
    required this.title,
    required this.finding,
    required this.explanation,
    required this.recommendations,
  });

  final ResultStatus status;
  final String title;
  final String finding;
  final String explanation;
  final List<String> recommendations;
}

/// Catálogo de diagnósticos.
///
/// ⚠️ IMPORTANTE: las claves deben coincidir con las clases reales de tus
/// modelos (`model/config/classes.json` para bacterias y `result.names` del
/// YOLO de pepinos). Las claves se comparan normalizadas: minúsculas y
/// cualquier separador convertido a `_` (ej. "Downy Mildew" → `downy_mildew`).
///
/// Si llega una clase que no está aquí, se muestra un texto genérico con
/// el nombre de la clase, así que la app nunca se rompe por una clase nueva.
class DiagnosisCatalog {
  DiagnosisCatalog._();

  static String normalize(String label) => label
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9áéíóúñü]+'), '_')
      .replaceAll(RegExp(r'^_+|_+$'), '');

  /// Convierte `downy_mildew` en `Downy mildew`.
  static String prettify(String label) {
    final text = label.replaceAll(RegExp(r'[_\-.]+'), ' ').trim();
    if (text.isEmpty) return 'Sin clasificar';
    return text[0].toUpperCase() + text.substring(1);
  }

  // ---------------------------------------------------------------------------
  // AGUA → /predict/bacteria (EfficientNet-B0)
  // ---------------------------------------------------------------------------

  static const waterClean = DiagnosisInfo(
    status: ResultStatus.good,
    title: 'Calidad favorable',
    finding: 'Sin anomalías visibles',
    explanation:
        'La muestra no presenta turbidez, partículas ni coloración atípica visibles. '
        'Este análisis visual no sustituye una prueba de laboratorio.',
    recommendations: [
      'Conserva la muestra en un recipiente limpio.',
      'Realiza controles periódicos de pH y conductividad.',
      'Solicita un análisis de laboratorio antes del consumo.',
    ],
  );

  static const _waterContaminated = [
    'No uses esta agua para consumo ni para riego de hortalizas de hoja.',
    'Hierve o desinfecta el agua antes de cualquier uso doméstico.',
    'Envía una muestra a un laboratorio certificado para confirmar.',
  ];

  static final Map<String, DiagnosisInfo> water = {
    for (final key in [
      'sin_bacterias',
      'clean',
      'negative',
      'negativo',
      'limpia',
      'agua_limpia',
      'none',
    ])
      key: waterClean,
    for (final key in ['e_coli', 'escherichia_coli', 'ecoli'])
      key: const DiagnosisInfo(
        status: ResultStatus.danger,
        title: 'Posible E. coli',
        finding: 'Indicador de contaminación fecal',
        explanation:
            'El patrón observado es compatible con Escherichia coli, un indicador '
            'de contaminación fecal en el agua. Confirma el resultado con una prueba de laboratorio.',
        recommendations: _waterContaminated,
      ),
    for (final key in ['coliformes', 'coliforms', 'total_coliforms'])
      key: const DiagnosisInfo(
        status: ResultStatus.warning,
        title: 'Coliformes detectados',
        finding: 'Calidad microbiológica comprometida',
        explanation:
            'Se identificaron patrones compatibles con bacterias coliformes. '
            'Su presencia indica que el agua puede estar expuesta a contaminación.',
        recommendations: _waterContaminated,
      ),
    for (final key in ['salmonella', 'salmonella_spp'])
      key: const DiagnosisInfo(
        status: ResultStatus.danger,
        title: 'Posible Salmonella',
        finding: 'Bacteria patógena',
        explanation:
            'El patrón observado es compatible con Salmonella, una bacteria que puede '
            'causar enfermedades gastrointestinales.',
        recommendations: _waterContaminated,
      ),
    for (final key in ['pseudomonas', 'pseudomonas_aeruginosa'])
      key: const DiagnosisInfo(
        status: ResultStatus.warning,
        title: 'Posible Pseudomonas',
        finding: 'Bacteria oportunista',
        explanation:
            'Se detectaron patrones compatibles con Pseudomonas aeruginosa, frecuente '
            'en tanques y tuberías con biopelícula.',
        recommendations: [
          'Limpia y desinfecta tanques, mangueras y tuberías.',
          'Evita el estancamiento del agua.',
          'Confirma el resultado con un laboratorio.',
        ],
      ),
    for (final key in ['staphylococcus', 'staphylococcus_aureus'])
      key: const DiagnosisInfo(
        status: ResultStatus.warning,
        title: 'Posible Staphylococcus',
        finding: 'Contaminación por manipulación',
        explanation:
            'El patrón es compatible con Staphylococcus aureus, asociado normalmente a '
            'contaminación por contacto o manipulación.',
        recommendations: _waterContaminated,
      ),
    for (final key in ['vibrio', 'vibrio_cholerae'])
      key: const DiagnosisInfo(
        status: ResultStatus.danger,
        title: 'Posible Vibrio cholerae',
        finding: 'Bacteria patógena de alto riesgo',
        explanation:
            'El patrón observado es compatible con Vibrio cholerae. Es un hallazgo '
            'de alto riesgo que debe confirmarse de inmediato.',
        recommendations: _waterContaminated,
      ),
  };

  static DiagnosisInfo waterFallback(String label) => DiagnosisInfo(
    status: ResultStatus.warning,
    title: prettify(label),
    finding: 'Microorganismo identificado',
    explanation:
        'El modelo identificó la clase "${prettify(label)}" en la muestra. '
        'Confirma el resultado con una prueba de laboratorio antes de usar el agua.',
    recommendations: _waterContaminated,
  );

  // ---------------------------------------------------------------------------
  // PLANTA → /predict/cucumber (YOLOv11)
  // ---------------------------------------------------------------------------

  static const plantHealthy = DiagnosisInfo(
    status: ResultStatus.good,
    title: 'Hoja saludable',
    finding: 'Sin signos de enfermedad',
    explanation:
        'La hoja presenta coloración uniforme y estructura saludable. No se detectaron '
        'patrones compatibles con plagas, hongos o deficiencias nutricionales.',
    recommendations: [
      'Mantén el riego actual evitando encharcamientos.',
      'Revisa el reverso de las hojas una vez por semana.',
      'Repite el análisis si aparecen manchas o cambios de color.',
    ],
  );

  /// Cuando YOLO no detecta nada en la imagen.
  static const plantNoDetections = DiagnosisInfo(
    status: ResultStatus.warning,
    title: 'Sin detecciones',
    finding: 'No identificamos la planta',
    explanation:
        'El modelo no encontró hojas ni frutos reconocibles en la imagen. '
        'Acércate más, mejora la iluminación y vuelve a intentarlo.',
    recommendations: [
      'Encuadra una sola hoja o fruto ocupando la mayor parte de la foto.',
      'Evita fondos con muchas plantas u objetos.',
      'Toma la foto con luz natural y sin sombras fuertes.',
    ],
  );

  static const _fungus = [
    'Retira y destruye las hojas afectadas, lejos del cultivo.',
    'Evita mojar el follaje; riega directamente en la base.',
    'Mejora la ventilación entre plantas y consulta a un agrónomo sobre fungicidas.',
  ];

  static final Map<String, DiagnosisInfo> plant = {
    for (final key in [
      'healthy',
      'sana',
      'saludable',
      'fresh_leaf',
      'fresh_cucumber',
      'good',
      'healthy_leaf',
    ])
      key: plantHealthy,
    for (final key in ['downy_mildew', 'mildiu', 'mildiu_velloso'])
      key: const DiagnosisInfo(
        status: ResultStatus.danger,
        title: 'Mildiu velloso',
        finding: 'Infección por hongo detectada',
        explanation:
            'Se observan manchas angulares amarillentas compatibles con mildiu velloso '
            '(Pseudoperonospora cubensis), que avanza rápido con humedad alta.',
        recommendations: _fungus,
      ),
    for (final key in ['powdery_mildew', 'oidio', 'oídio'])
      key: const DiagnosisInfo(
        status: ResultStatus.warning,
        title: 'Oídio',
        finding: 'Polvo blanco en la superficie',
        explanation:
            'Se detectaron zonas con aspecto polvoriento blanco compatibles con oídio, '
            'un hongo que reduce la fotosíntesis de la planta.',
        recommendations: _fungus,
      ),
    for (final key in ['anthracnose', 'antracnosis'])
      key: const DiagnosisInfo(
        status: ResultStatus.danger,
        title: 'Antracnosis',
        finding: 'Lesiones oscuras hundidas',
        explanation:
            'Las lesiones observadas son compatibles con antracnosis (Colletotrichum), '
            'que afecta hojas y frutos.',
        recommendations: _fungus,
      ),
    for (final key in ['gummy_stem_blight', 'tizon_gomoso'])
      key: const DiagnosisInfo(
        status: ResultStatus.danger,
        title: 'Tizón gomoso del tallo',
        finding: 'Lesiones con exudado',
        explanation:
            'Se detectaron síntomas compatibles con tizón gomoso, que provoca lesiones '
            'en tallos y hojas con exudado ámbar.',
        recommendations: _fungus,
      ),
    for (final key in ['bacterial_wilt', 'marchitez_bacteriana'])
      key: const DiagnosisInfo(
        status: ResultStatus.danger,
        title: 'Marchitez bacteriana',
        finding: 'Marchitamiento de la planta',
        explanation:
            'El patrón es compatible con marchitez bacteriana (Erwinia tracheiphila), '
            'transmitida principalmente por escarabajos del pepino.',
        recommendations: [
          'Retira las plantas afectadas para evitar la propagación.',
          'Controla la población de escarabajos del pepino.',
          'Desinfecta las herramientas después de usarlas.',
        ],
      ),
    for (final key in ['angular_leaf_spot', 'mancha_angular'])
      key: const DiagnosisInfo(
        status: ResultStatus.warning,
        title: 'Mancha angular',
        finding: 'Lesiones angulares en la hoja',
        explanation:
            'Se observan lesiones limitadas por las nervaduras, compatibles con mancha '
            'angular bacteriana (Pseudomonas syringae).',
        recommendations: [
          'Evita el riego por aspersión.',
          'Elimina restos de cultivo infectados.',
          'Usa semilla certificada en la próxima siembra.',
        ],
      ),
    for (final key in ['mosaic_virus', 'cmv', 'virus_mosaico'])
      key: const DiagnosisInfo(
        status: ResultStatus.danger,
        title: 'Virus del mosaico',
        finding: 'Patrón de mosaico en la hoja',
        explanation:
            'La coloración irregular verde claro y oscuro es compatible con el virus del '
            'mosaico del pepino, transmitido por pulgones.',
        recommendations: [
          'Retira las plantas con síntomas.',
          'Controla pulgones y malezas hospederas.',
          'Desinfecta las herramientas entre plantas.',
        ],
      ),
    for (final key in ['belly_rot', 'pythium_fruit_rot', 'fruit_rot', 'pudricion'])
      key: const DiagnosisInfo(
        status: ResultStatus.warning,
        title: 'Pudrición del fruto',
        finding: 'Daño en el fruto',
        explanation:
            'Se detectaron zonas compatibles con pudrición del fruto, asociada al contacto '
            'con suelo húmedo.',
        recommendations: [
          'Evita que los frutos toquen el suelo (usa tutores o acolchado).',
          'Reduce el exceso de riego.',
          'Cosecha y retira los frutos dañados.',
        ],
      ),
  };

  static DiagnosisInfo plantFallback(String label) => DiagnosisInfo(
    status: ResultStatus.warning,
    title: prettify(label),
    finding: 'Hallazgo detectado',
    explanation:
        'El modelo detectó "${prettify(label)}" en la imagen. Revisa la planta con '
        'atención y consulta a un agrónomo si los síntomas avanzan.',
    recommendations: const [
      'Aísla o marca la planta para seguir su evolución.',
      'Repite el análisis en unos días para comparar.',
      'Consulta a un agrónomo si el daño se extiende.',
    ],
  );
}
