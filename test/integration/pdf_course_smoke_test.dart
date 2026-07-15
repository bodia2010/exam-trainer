// Host-run mirror of the device integration journey. Keeping this entry point
// in the ordinary suite makes the smoke flow deterministic in CI environments
// where no Android device is attached.
import '../../integration_test/pdf_course_smoke_test.dart' as smoke;

void main() => smoke.runPdfCourseSmokeTests();
