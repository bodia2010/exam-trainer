const pdfCacheResultFixture = r'''
{
  "id": "smoke-course",
  "title": "PDF Smoke Course",
  "source_filename": "exam-fixture.pdf",
  "parsed_at": "2026-07-15T10:00:00.000Z",
  "exam_provider": "telc",
  "exam_course_type": "Beruf",
  "exam_level": "B2",
  "sections": {
    "lesen_teil1": [
      {
        "variant_number": 1,
        "topic": "Integration fixture",
        "questions": [
          {
            "number": 1,
            "type": "choice",
            "text": "Welche Antwort ist richtig?",
            "options": [
              {"letter": "a", "text": "Die richtige Antwort"},
              {"letter": "b", "text": "Die falsche Antwort"}
            ],
            "answer": "a"
          }
        ]
      }
    ]
  }
}
''';
