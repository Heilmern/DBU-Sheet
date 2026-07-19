/// rule_text.dart
/// ---------------------------------------------------------------------------
/// LIVE-VALUE ANNOTATION for verbatim rule text.
///
/// The site's effect texts are written against scaling tokens — `N(T)` (× Tier
/// of Power), `N(bT)` (× Base Tier), `Z` (Awakening Stacks), `G` (Grade), `L`
/// (State Level). [annotateRuleText] appends the RESOLVED value right after
/// each occurrence, so "increase your Strike Rolls by 1(T)" reads
/// "…by 1(T) [=3]" on a Tier-3 character, and "equal to 2Z" reads
/// "…2Z [=4]" at 2 Stacks. The verbatim wording is never altered — the
/// computed value is purely appended in `[=N]` brackets (chosen so it can't
/// be confused with the site's own parenthesised notation, e.g. a Trait's
/// "(2)" Stack requirement).
///
/// Tokens whose context value isn't supplied (e.g. `Z` outside a
/// Transformation card) are left untouched. This is a DISPLAY helper only:
/// the rules engine never parses text — all automation flows through the
/// structured `RaceTraitAutomation`/AMB machinery as ever.
/// ---------------------------------------------------------------------------
library;

/// Matches `N(T)` / `N(bT)` — a coefficient directly attached to a Tier
/// bracket (the site's universal scaling notation).
final RegExp _tierToken = RegExp(r'(\d+)\((bT|T)\)');

/// Matches `Z` / `NZ` as a standalone word (the Stacks token).
final RegExp _stacksToken = RegExp(r'\b(\d*)Z\b');

/// Matches `G` / `NG` as a standalone word (the Grade token).
final RegExp _gradeToken = RegExp(r'\b(\d*)G\b');

/// Matches `L` / `NL` as a standalone word (the State-Level token).
final RegExp _levelToken = RegExp(r'\b(\d*)L\b');

/// Appends the computed value after every scaling token in [text].
///
/// [tier]/[baseTier] resolve `(T)`/`(bT)`; [stacks]/[grade]/[level] resolve
/// `Z`/`G`/`L` when provided (pass null to leave that token un-annotated).
String annotateRuleText(
  String text, {
  required int tier,
  required int baseTier,
  int? stacks,
  int? grade,
  int? level,
}) {
  var result = text.replaceAllMapped(_tierToken, (m) {
    final n = int.parse(m[1]!);
    final scale = m[2] == 'bT' ? baseTier : tier;
    return '${m[0]} [=${n * scale}]';
  });
  String expand(RegExp token, int value) => result.replaceAllMapped(token, (m) {
        final raw = m[1]!;
        final n = raw.isEmpty ? 1 : int.parse(raw);
        return '${m[0]} [=${n * value}]';
      });
  if (stacks != null) result = expand(_stacksToken, stacks);
  if (grade != null) result = expand(_gradeToken, grade);
  if (level != null) result = expand(_levelToken, level);
  return result;
}
