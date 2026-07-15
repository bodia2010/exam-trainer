import '../../../models/parsed_course.dart';
import '../../../services/course_storage.dart';
import '../../../services/parse_service.dart';
import 'pdf_import_file.dart';

abstract class PdfImportServices {
  Future<String> convertPdf(ValidatedPdfFile file);

  Future<bool> isPremium();

  Future<Map<String, List<dynamic>>?> getCachedSections(String markdown);

  Future<List<DiscoveredItem>> discoverSections(String markdown);

  Map<String, List<VariantGroup>> groupChunksBySectionType(
    String markdown,
    List<DiscoveredItem> items,
  );

  Future<({List<dynamic> items, List<String> errors})> parseVariantGroups(
    List<VariantGroup> groups,
    String sectionType, {
    void Function(int done, int total)? onProgress,
  });

  Future<void> cacheSections(
    String markdown,
    Map<String, List<dynamic>> sections,
  );

  Future<void> saveCourse(ParsedCourse course);
}

class ProductionPdfImportServices implements PdfImportServices {
  const ProductionPdfImportServices();

  @override
  Future<String> convertPdf(ValidatedPdfFile file) =>
      ParseService.instance.convertPdfFile(file.path, contentLength: file.size);

  @override
  Future<bool> isPremium() => ParseService.instance.isPremium();

  @override
  Future<Map<String, List<dynamic>>?> getCachedSections(String markdown) =>
      ParseService.instance.getCachedSections(markdown);

  @override
  Future<List<DiscoveredItem>> discoverSections(String markdown) =>
      ParseService.instance.discoverSections(markdown);

  @override
  Map<String, List<VariantGroup>> groupChunksBySectionType(
    String markdown,
    List<DiscoveredItem> items,
  ) => ParseService.instance.groupChunksBySectionType(markdown, items);

  @override
  Future<({List<dynamic> items, List<String> errors})> parseVariantGroups(
    List<VariantGroup> groups,
    String sectionType, {
    void Function(int done, int total)? onProgress,
  }) => ParseService.instance.parseVariantGroups(
    groups,
    sectionType,
    onProgress: onProgress,
  );

  @override
  Future<void> cacheSections(
    String markdown,
    Map<String, List<dynamic>> sections,
  ) => ParseService.instance.cacheSections(markdown, sections);

  @override
  Future<void> saveCourse(ParsedCourse course) =>
      CourseStorage.instance.save(course);
}
