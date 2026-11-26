import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';

class ImageUploadField extends StatefulWidget {
  const ImageUploadField({
    super.key,
    required this.storageFolder,
    required this.onUploaded,
    this.initialImageUrl = '',
    this.circular = false,
    this.previewHeight = 140,
    this.buttonLabel,
  });

  final String storageFolder;
  final String initialImageUrl;
  final ValueChanged<String> onUploaded;
  final bool circular;
  final double previewHeight;
  final String? buttonLabel;

  @override
  State<ImageUploadField> createState() => _ImageUploadFieldState();
}

class _ImageUploadFieldState extends State<ImageUploadField> {
  static const _maximumFileSize = 10 * 1024 * 1024;
  static const _allowedExtensions = {'jpg', 'jpeg', 'png', 'webp', 'gif'};

  late String _imageUrl = widget.initialImageUrl;
  bool _uploading = false;
  String? _errorMessage;

  @override
  void didUpdateWidget(covariant ImageUploadField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialImageUrl != widget.initialImageUrl) {
      _imageUrl = widget.initialImageUrl;
    }
  }

  Future<void> _selectAndUpload() async {
    setState(() {
      _uploading = true;
      _errorMessage = null;
    });

    try {
      final file = await FilePicker.pickFile(
        dialogTitle: 'Choose an image',
        type: FileType.custom,
        allowedExtensions: _allowedExtensions.toList(),
      );
      if (file == null) return;

      final fileSize = await file.length();
      if (fileSize != null && fileSize > _maximumFileSize) {
        setState(() => _errorMessage = 'Choose an image smaller than 10 MB.');
        return;
      }

      final extension = (file.extension ?? '').toLowerCase();
      if (!_allowedExtensions.contains(extension)) {
        setState(
          () => _errorMessage = 'Choose a JPG, PNG, WEBP, or GIF image.',
        );
        return;
      }

      final bytes = await file.readAsBytes();
      if (bytes.length > _maximumFileSize) {
        setState(() => _errorMessage = 'Choose an image smaller than 10 MB.');
        return;
      }

      final contentType = switch (extension) {
        'png' => 'image/png',
        'webp' => 'image/webp',
        'gif' => 'image/gif',
        _ => 'image/jpeg',
      };
      final safeName = file.name.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
      final objectName = '${DateTime.now().microsecondsSinceEpoch}_$safeName';
      final reference = FirebaseStorage.instance.ref().child(
        '${widget.storageFolder}/$objectName',
      );
      final uploaded = await reference.putData(
        bytes,
        SettableMetadata(contentType: contentType),
      );
      final downloadUrl = await uploaded.ref.getDownloadURL();
      if (!mounted) return;

      setState(() => _imageUrl = downloadUrl);
      widget.onUploaded(downloadUrl);
    } on FirebaseException catch (error) {
      if (mounted) {
        setState(
          () => _errorMessage =
              'Image upload failed: ${error.message ?? error.code}',
        );
      }
    } on PlatformException catch (error) {
      if (mounted) {
        setState(
          () => _errorMessage =
              'Could not choose the image: ${error.message ?? error.code}',
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final preview = _imageUrl.isEmpty
        ? _imagePlaceholder()
        : Image.network(
            _imageUrl,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => _imagePlaceholder(),
          );

    return Column(
      crossAxisAlignment: widget.circular
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.stretch,
      children: [
        if (widget.circular)
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              ClipOval(child: SizedBox(width: 96, height: 96, child: preview)),
              Material(
                color: AppColors.primaryDark,
                shape: const CircleBorder(),
                child: IconButton(
                  tooltip: 'Choose profile photo',
                  onPressed: _uploading ? null : _selectAndUpload,
                  icon: const Icon(
                    Icons.camera_alt_outlined,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ],
          )
        else
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              height: widget.previewHeight,
              child: ColoredBox(
                color: AppColors.inputBackground,
                child: preview,
              ),
            ),
          ),
        const SizedBox(height: 8),
        if (widget.circular)
          TextButton(
            onPressed: _uploading ? null : _selectAndUpload,
            child: Text(widget.buttonLabel ?? 'CHANGE PROFILE PHOTO'),
          )
        else
          OutlinedButton.icon(
            onPressed: _uploading ? null : _selectAndUpload,
            icon: _uploading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.upload_file_outlined),
            label: Text(
              widget.buttonLabel ??
                  (_imageUrl.isEmpty
                      ? 'Choose image from computer'
                      : 'Replace image'),
            ),
          ),
        if (widget.circular && _uploading)
          const Padding(
            padding: EdgeInsets.only(top: 4),
            child: SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        if (!widget.circular)
          const Padding(
            padding: EdgeInsets.only(top: 4),
            child: Text(
              'JPG, PNG, WEBP, or GIF · up to 10 MB',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
            ),
          ),
        if (_errorMessage != null) ...[
          const SizedBox(height: 6),
          Text(
            _errorMessage!,
            style: const TextStyle(color: Colors.red, fontSize: 12),
          ),
        ],
      ],
    );
  }

  Widget _imagePlaceholder() => Center(
    child: Icon(
      widget.circular ? Icons.person : Icons.add_photo_alternate_outlined,
      size: 42,
      color: AppColors.textSecondary,
    ),
  );
}
