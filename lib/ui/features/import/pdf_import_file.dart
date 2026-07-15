import 'dart:io';

import 'package:file_picker/file_picker.dart';

const int maxPdfImportBytes = 25 * 1024 * 1024;

class PickedPdfFile {
  const PickedPdfFile({required this.path, required this.name});

  final String path;
  final String name;
}

class ValidatedPdfFile extends PickedPdfFile {
  const ValidatedPdfFile({
    required super.path,
    required super.name,
    required this.size,
  });

  final int size;
}

enum PdfFileValidationError { inaccessible, tooLarge, invalidSignature }

class PdfFileValidationException implements Exception {
  const PdfFileValidationException(this.error);

  final PdfFileValidationError error;
}

abstract class PdfFilePicker {
  Future<PickedPdfFile?> pick();
}

class PlatformPdfFilePicker implements PdfFilePicker {
  const PlatformPdfFilePicker();

  @override
  Future<PickedPdfFile?> pick() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf'],
      withData: false,
    );
    if (result == null) return null;
    final file = result.files.single;
    final path = file.path;
    if (path == null) {
      throw const PdfFileValidationException(
        PdfFileValidationError.inaccessible,
      );
    }
    return PickedPdfFile(path: path, name: file.name);
  }
}

class PdfFileValidator {
  const PdfFileValidator({this.maxBytes = maxPdfImportBytes});

  final int maxBytes;

  Future<ValidatedPdfFile> validate(PickedPdfFile picked) async {
    RandomAccessFile? handle;
    try {
      final file = File(picked.path);
      final size = await file.length();
      if (size > maxBytes) {
        throw const PdfFileValidationException(PdfFileValidationError.tooLarge);
      }
      handle = await file.open();
      final signature = await handle.read(5);
      if (signature.length != 5 ||
          signature[0] != 0x25 ||
          signature[1] != 0x50 ||
          signature[2] != 0x44 ||
          signature[3] != 0x46 ||
          signature[4] != 0x2D) {
        throw const PdfFileValidationException(
          PdfFileValidationError.invalidSignature,
        );
      }
      return ValidatedPdfFile(path: picked.path, name: picked.name, size: size);
    } on PdfFileValidationException {
      rethrow;
    } on FileSystemException {
      throw const PdfFileValidationException(
        PdfFileValidationError.inaccessible,
      );
    } finally {
      await handle?.close();
    }
  }
}
