import 'dart:io';

import 'package:ai_image_classifier/interpreter_services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:image_picker/image_picker.dart';

class ImagePickerScreen extends HookWidget {
  const ImagePickerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final outputs = useState<List<dynamic>?>(null);
    final image = useState<File?>(null);
    final loading = useState<bool>(false);
    final interpreterServices = useMemoized(() => InterpreterServices());

    useEffect(() {
      () async {
        await interpreterServices.loadModel();
      }();
      return null;
    }, []);

    Future<void> pickImage() async {
      final pickedFile =
          await ImagePicker().pickImage(source: ImageSource.gallery);
      if (pickedFile == null) return;

      image.value = null;
      loading.value = true;
      image.value = File(pickedFile.path);

      await Future.delayed(const Duration(milliseconds: 50));

      await interpreterServices.classifyImage(
        image.value!,
        (result) {
          loading.value = false;
          outputs.value = result;
        },
        () {
          loading.value = false;
        },
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.purple,
        title: const Text(
          'Horse/Human Detector',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20.0,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: loading.value
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  spacing: 20,
                  children: [
                    Text(
                      'Image Classifying...',
                    ),
                    CircularProgressIndicator(
                      color: Colors.purple,
                    ),
                  ],
                ),
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: MediaQuery.of(context).size.width,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    image.value == null
                        ? Container()
                        : ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: SizedBox(
                              height: 450,
                              width: MediaQuery.of(context).size.width,
                              child: Image.file(
                                image.value!,
                              ),
                            ),
                          ),
                    const SizedBox(height: 20),
                    outputs.value != null
                        ? Text(
                            "${outputs.value![0]}",
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 20.0,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : Container(),
                  ],
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: pickImage,
        backgroundColor: Colors.purple,
        child: const Icon(
          Icons.image,
          color: Colors.white,
          size: 30.0,
        ),
      ),
    );
  }
}
