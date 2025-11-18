import 'package:flutter/material.dart';
import 'package:of_course/feature/course/write_and_edit/viewmodels/course_set_view_model.dart';

class ImagePickerRow extends StatelessWidget {
  final WriteCourseSetViewModel vm;

  const ImagePickerRow({super.key, required this.vm});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (int i = 0; i < vm.existingImages.length; i++)
          _imageBox(
            Image.network(vm.existingImages[i]).image,
            () => vm.removeExistingImage(i),
          ),

        for (int i = 0; i < vm.images.length; i++)
          _imageBox(Image.file(vm.images[i]).image, () => vm.removeNewImage(i)),

        if (vm.existingImages.length + vm.images.length < 3)
          GestureDetector(
            onTap: vm.pickImage,
            child: Container(
              width: 100,
              height: 100,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.add),
            ),
          ),
      ],
    );
  }

  Widget _imageBox(ImageProvider img, VoidCallback onRemove) {
    return Stack(
      children: [
        Container(
          width: 100,
          height: 100,
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            image: DecorationImage(image: img, fit: BoxFit.cover),
          ),
        ),
        Positioned(
          right: 0,
          top: 0,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black54,
              ),
              padding: const EdgeInsets.all(4),
              child: const Icon(Icons.close, size: 18, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}
