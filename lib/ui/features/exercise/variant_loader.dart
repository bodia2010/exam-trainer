import '../../../widgets/course_load_state.dart';

/// CR-13: every exercise screen (Universal, Beschwerde, Sprachbausteine 1/2,
/// Telefonnotiz, Hören Teil 1) duplicated the same ~20 lines to look up a
/// course, bounds-check the requested variant index, and turn the result
/// into loading/notFound/error/loaded — this is that logic, extracted once
/// so each screen's `_load()` is now "call this, then setState the result."
///
/// Not a ViewModel/framework — a single reusable async function screens
/// still drive from their own `State.setState`, matching the existing
/// UI → Controller/Service layering without adding a new dependency.
class VariantLoadResult<T> {
  const VariantLoadResult.loaded(this.variant) : failure = null;
  const VariantLoadResult.notFound()
    : variant = null,
      failure = CourseLoadFailure.notFound;
  const VariantLoadResult.error()
    : variant = null,
      failure = CourseLoadFailure.error;

  /// Non-null exactly when [failure] is null.
  final T? variant;
  final CourseLoadFailure? failure;
}

/// Looks up [courseId] via [courseLoader], bounds-checks [index] against
/// `course.sections[sectionType]`, and parses the variant at that index
/// through [fromJson] — which, for every DTO in lib/models/exercises/,
/// already walks its own nested lists/maps eagerly (CR-08), so schema
/// drift anywhere inside the variant surfaces here as [VariantLoadResult.error]
/// instead of crashing later during build().
///
/// Callers must check `mounted` immediately after awaiting this (the same
/// place the old inline `_load()` methods checked it) before calling
/// `setState` with the result — this function has exactly one `await`
/// (the [courseLoader] call), same as before.
Future<VariantLoadResult<T>> loadVariant<T>({
  required CourseLoader courseLoader,
  required String courseId,
  required String sectionType,
  required int index,
  required T Function(Map<String, dynamic> json) fromJson,
}) async {
  try {
    final all = await courseLoader();
    final course = all.where((c) => c.id == courseId).firstOrNull;
    final variants = course?.sections[sectionType] ?? [];
    if (course == null || index < 0 || index >= variants.length) {
      return const VariantLoadResult.notFound();
    }
    final variant = fromJson(variants[index] as Map<String, dynamic>);
    return VariantLoadResult.loaded(variant);
  } catch (_) {
    return const VariantLoadResult.error();
  }
}
