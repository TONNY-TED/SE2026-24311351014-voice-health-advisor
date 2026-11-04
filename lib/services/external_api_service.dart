// External API hooks (NEXT step — intentionally OFF for now).
// When ready: set useLiveApis = true, add `http: ^1.2.0` to pubspec,
// then implement the two methods below. No API calls happen until then.

// ignore_for_file: unused_element

class ExternalApiService {
  // Master switch: false = app stays fully offline on built-in + fallback.
  static const bool useLiveApis = false;

  // TODO (OpenFDA): GET https://api.fda.gov/drug/label.json
  //   ?search=openfda.brand_name:"paracetamol"&limit=1
  // Return indications + warnings, cite 'OpenFDA - <drug>'.
  static Future<String?> fetchDrugLabel(String drug) async {
    // Offline for now — enables in the API step.
    if (!useLiveApis) return null;
    throw UnimplementedError('Wire OpenFDA here in the API step.');
  }

  // TODO (MedlinePlus Connect): GET https://medlineplus.gov/connect/
  //   service?mainSearchCriteria.v.c=<code>&informationRecipient.languageCode.c=en
  // Return the summary link for the condition, cite 'MedlinePlus - <topic>'.
  static Future<String?> lookupCondition(String topic) async {
    // Offline for now — enables in the API step.
    if (!useLiveApis) return null;
    throw UnimplementedError('Wire MedlinePlus here in the API step.');
  }
}
