import 'dart:convert';
import 'dart:io';
import 'package:csv/csv.dart';

void main(List<String> args) async {
  final List<List<dynamic>> fields = await getFieldsFromFile("notas.csv", 7);

  final Map<String, int> results = countResultTypes(fields);

  if (args.isEmpty) {
    args.add("--all");
  }

  if (args.contains("--all") || args.contains("--count")) {
    results.forEach((result, count) {
      print('$result: $count');
    });
  }

  if (args.contains("--all") || args.contains("--rate")) {
    final rateByType = getRateByType(results);
    rateByType.forEach((type, rate) {
      print('$type: ${rate.toStringAsFixed(2)}%');
    });
  }

  if (args.contains("--all") || args.contains("--s-approve")) {
    final generalApprovedRate = getSoftGeneralApproveRate(results, "APROVADO");
    print(
        'Taxa de aprovação geral: ${generalApprovedRate.toStringAsFixed(2)}%');
  }

  if (args.contains("--all") || args.contains("--h-approve")) {
    final approvedOnlyRate = getHardGeneralApproveRate(results, "APROVADO");
    print("Taxa de 'APROVADOS': ${approvedOnlyRate.toStringAsFixed(2)}%");
  }

  if (args.contains("--all") || args.contains("--disciplines")) {
    final Map<String, double> approveRateByDiscipline =
        getApproveRateByDiscipline(fields);
    approveRateByDiscipline.forEach((key, value) {
      print("$key: ${value.toStringAsFixed(2)}%");
    });
  }
}

/// Lê e retorna uma lista contendo cada uma das linhas da tabela, em formato
/// de lista, contendo cada uma das célula daquela linha
/// O parâmetro [headerLine] deve estar entre 1 e o número de linhas total
/// da tabela.
Future<List<List<dynamic>>> getFieldsFromFile(String file,
    [int headerLine = 1]) async {
  if (headerLine < 1) {
    return [];
  }

  final input = File(file).openRead();
  final fields = await input
      .transform(utf8.decoder)
      .transform(CsvToListConverter())
      .toList();

  if (headerLine > fields.length) {
    return [];
  }

  return fields.sublist(headerLine - 1);
}

/// Retorna um mapa com cada um dos resultados existentes e a quantidade de cada
/// um em [fields].
Map<String, int> countResultTypes(List<List<dynamic>> fields) {
  final results = <String, int>{};
  for (int i = 1; i < fields.length; i++) {
    final result = fields[i][8];
    results[result] = (results[result] ?? 0) + 1;
  }

  return results;
}

/// Retorna um mapa com cada um dos resultados existentes e a taxa de ocorrência
/// para cada um deles em [results].
Map<String, double> getRateByType(Map<String, int> results) {
  int resultsCount = 0;

  final keys = results.keys.toList();
  for (int i = 1; i < keys.length; i++) {
    resultsCount += results[keys[i]] ?? 0;
  }

  final rateByType = results.map((key, value) {
    return MapEntry(key, (value / resultsCount) * 100);
  });

  return rateByType;
}

/// Calcula a porcentagem de resultados que contem o tipo [resultType] em
/// [results].
double getSoftGeneralApproveRate(
  Map<String, int> results,
  String resultType,
) {
  final typesToConsider = results.keys.where((key) {
    return key.contains(resultType);
  }).toList();

  int typesCount = 0;
  for (final type in typesToConsider) {
    typesCount += results[type] ?? 0;
  }

  int resultsCount = 0;
  for (final resultType in results.keys) {
    resultsCount += results[resultType] ?? 0;
  }

  double typesRate = (typesCount / resultsCount) * 100;

  return typesRate;
}

/// Calcula a porcentagem de resultados exatamente do tipo [resultType] em
/// [results].
double getHardGeneralApproveRate(
  Map<String, int> results,
  String resultType,
) {
  int typeCount = results[resultType] ?? 0;

  int resultsCount = 0;
  for (final resultType in results.keys) {
    resultsCount += results[resultType] ?? 0;
  }

  double typeRate = (typeCount / resultsCount) * 100;

  return typeRate;
}

/// Retorna a taxa de aprovação por disciplina em [fields]
Map<String, double> getApproveRateByDiscipline(List<List<dynamic>> fields) {
  final disciplines = fields.map((row) => "${row[1]} - ${row[2]}").toSet();
  final result = <String, double>{};

  for (var i = 1; i < disciplines.length; i++) {
    final discipline = disciplines.elementAt(i);

    final approvedByDiscipline = fields.where((row) =>
        row[8].contains('APROVADO') && "${row[1]} - ${row[2]}" == discipline);
    final studentsForDiscipline =
        fields.where((row) => "${row[1]} - ${row[2]}" == discipline).length;
    final disciplineApproveRate =
        (approvedByDiscipline.length / studentsForDiscipline) * 100;
    result[discipline] = disciplineApproveRate;
  }

  return result;
}
