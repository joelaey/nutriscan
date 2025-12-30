import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';

/// Camera Service dengan fitur Crop Image
/// Untuk fokus pada tabel Informasi Nilai Gizi
class CameraService {
  final ImagePicker _picker = ImagePicker();

  /// Ambil foto dari kamera lalu crop
  Future<File?> takePhoto({bool enableCrop = true}) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 90,  // Higher quality for better OCR
        maxWidth: 1920,    // Higher resolution for text recognition
        preferredCameraDevice: CameraDevice.rear,
      );

      if (pickedFile == null) return null;
      
      // Crop image untuk fokus pada tabel nutrisi
      if (enableCrop) {
        return await _cropImage(File(pickedFile.path));
      }
      
      return File(pickedFile.path);
    } catch (e) {
      print('Camera Error: $e');
      return null;
    }
  }

  /// Ambil gambar dari gallery lalu crop
  Future<File?> pickFromGallery({bool enableCrop = true}) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
        maxWidth: 1920,
      );

      if (pickedFile == null) return null;
      
      // Crop image untuk fokus pada tabel nutrisi
      if (enableCrop) {
        return await _cropImage(File(pickedFile.path));
      }
      
      return File(pickedFile.path);
    } catch (e) {
      print('Gallery Error: $e');
      return null;
    }
  }

  /// Crop image untuk fokus pada tabel nutrisi
  Future<File?> _cropImage(File imageFile) async {
    try {
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: imageFile.path,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Fokuskan pada Tabel Nutrisi',
            toolbarColor: const Color(0xFF4CAF50),
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: false,
            hideBottomControls: false,
            showCropGrid: true,
            activeControlsWidgetColor: const Color(0xFF4CAF50),
          ),
          IOSUiSettings(
            title: 'Fokuskan pada Tabel Nutrisi',
            resetAspectRatioEnabled: true,
            aspectRatioPickerButtonHidden: false,
            rotateButtonsHidden: false,
            rotateClockwiseButtonHidden: true,
            doneButtonTitle: 'Selesai',
            cancelButtonTitle: 'Batal',
          ),
        ],
      );

      if (croppedFile != null) {
        return File(croppedFile.path);
      }
      
      // Jika user cancel crop, return original file
      return imageFile;
    } catch (e) {
      print('Crop Error: $e');
      // Jika crop gagal, return original file
      return imageFile;
    }
  }
}
