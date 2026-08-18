enum ProductAccessLevel { guest, free, plus, familyPlus }

extension ProductAccessLevelX on ProductAccessLevel {
  bool get isPaid => this == ProductAccessLevel.plus || this == ProductAccessLevel.familyPlus;

  int get bodyMetricsAiStages => isPaid ? 15 : 5;
}
