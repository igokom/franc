import 'dart:collection';

import 'expressions.dart';
import 'trigram_utils.dart' as trigram_utils;
import 'trigrams.dart';

/// Detects language of text

class Franc {
  ///Maximum sample length.
  int maxLength;

  ///Minimum sample length.
  int minLength;

  /** The maximum distance to add when a given trigram does
   * not exist in a trigram dictionary. */
  int maxDifference;

  Map<String, Map<String, Map<String, int>>> _languageModelData = {};

  Franc(
      {this.maxLength = 2048, this.minLength = 10, this.maxDifference = 300}) {
    //Construct trigram dictionaries
    for (String script in trigramsByLanguage.keys) {
      Map<String, String> languages = trigramsByLanguage[script]!;
      _languageModelData[script] = {};
      for (String languageCode in languages.keys) {
        List<String> model = languages[languageCode]!.split('|');
        int weight = model.length;
        final Map<String, int> trigrams = {};
        while (weight-- != 0) {
          trigrams[model[weight]] = weight;
        }
        _languageModelData[script]![languageCode] = trigrams;
      }
    }
  }

  /// Get a list of probable languages the given value is written in.
  Map<String, double> detectLanguages(String text) {
    if (text.isEmpty || text.length < minLength) {
      return {"und": 1.0}; //und()
    }
    if (text.length > maxLength) {
      text = text.substring(0, maxLength);
      print("Input text was truncated to maxLength");
    }

    //Get the script which characters occur the most in `value`.
    final List<Object?> scriptCount = _getTopScript(text, regExpByScript);

    // One languages exists for the most-used script.
    final script = scriptCount[0] as String?;
    if (script == null) return {}; //und()

    final count = scriptCount[1] as double;
    if (!_languageModelData.containsKey(script)) {
      //If no matches occurred, such as a digit only string,
      //or because the language is ignored, exit with `und`.
      if (count == 0) return {}; //und()
      return {script: 1.0};
    }

    // Get all distances for a given script, and normalize the distance values.
    return _normalize(
      text,
      _getDistances(
        trigram_utils.getCleanTrigramsAsDictionary(text),
        _languageModelData[script]!,
      ),
    );
  }

  // From `scripts`, get the most occurring expression for `value`.
  List<Object?> _getTopScript(String value, Map<String, String> scripts) {
    double topCount = -1;
    String? topScript;
    for (String script in scripts.keys) {
      final double count = _getOccurrence(value, scripts[script]!);
      if (count > topCount) {
        topCount = count;
        topScript = script;
      }
    }
    return [topScript, topCount];
  }

  // Get the occurrence ratio of `expression` for `value`.
  double _getOccurrence(String value, String expression) {
    final int matchCount = RegExp("$expression").allMatches(value).length;
    return (matchCount != 0 ? matchCount : 0) / value.length;
  }

  // Normalize the difference for each tuple in `distances`.
  Map<String, double> _normalize(String value, Map<String, int> distances) {
    final Map<String, double> normalizedDistances = {};
    final int min = distances.values.toList()[0];
    final int max = value.length * maxDifference - min;
    for (MapEntry<String, int> distance in distances.entries) {
      normalizedDistances.putIfAbsent(
          distance.key, () => 1 - (distance.value - min) / max);
    }
    return normalizedDistances;
  }

  /* Get the distance between an array of trigram--count
   * tuples, and multiple trigram dictionaries.
   */
  Map<String, int> _getDistances(
      Map<String, int> trigrams, Map<String, Map<String, int>> languages) {
    final distances = SplayTreeMap<int, String>();
    for (String language in languages.keys) {
      distances.putIfAbsent(
          _getDistance(trigrams, languages[language]!), () => language);
    }
    return distances.map((key, value) => MapEntry(value, key));
  }

  /* Get the distance between an array of trigram--count
   * tuples, and a language dictionary.
   */
  int _getDistance(Map<String, int> trigrams, Map<String, int> model) {
    int distance = 0;
    int difference;
    trigrams.forEach((trigram, weight) {
      if (model.containsKey(trigram)) {
        difference = weight - model[trigram]! - 1;
        if (difference < 0) {
          difference = -difference;
        }
      } else {
        difference = maxDifference;
      }
      distance += difference;
    });
    return distance;
  }
}
