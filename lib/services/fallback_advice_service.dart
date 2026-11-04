// Fallback layer (required now, before any live API work).
// Used ONLY when the query matches nothing in the 24-entry base
// and nothing in the 6-topic base. Gives safe general guidance plus
// links to the real authorities — never invents medical facts.

class FallbackAdviceService {
  // Safe general answer for unmatched queries (no diagnosis, no dosage).
  static String build(String query) {
    final buffer = StringBuffer();
    buffer.writeln('I don\'t have verified info on "$query" yet.');
    buffer.writeln('');
    buffer.writeln('General steps you can take now:');
    buffer.writeln('- Rest and drink clean water.');
    buffer.writeln('- Note your symptoms and when they started.');
    buffer.writeln('- Check one of the sources below for verified guidance.');
    buffer.writeln('- See a qualified health worker if unsure or worsening.');
    buffer.writeln('');
    buffer.writeln('Verify here:');
    buffer.writeln('- WHO fact sheets: https://www.who.int/news-room/fact-sheets');
    buffer.writeln('- CDC: https://www.cdc.gov');
    buffer.writeln('- MedlinePlus: https://medlineplus.gov');
    buffer.writeln('- NHS conditions: https://www.nhs.uk/conditions');
    return buffer.toString();
  }
}
