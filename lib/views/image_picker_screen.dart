import 'dart:io';

import 'package:first_ai_project/interpreter_services.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ImagePickerScreen extends StatefulWidget {
  const ImagePickerScreen({super.key});

  @override
  State<ImagePickerScreen> createState() => _ImagePickerScreenState();
}

class _ImagePickerScreenState extends State<ImagePickerScreen> {
  List<dynamic>? _outputs;
  File? _image;
  bool _loading = false;
  final InterpreterServices _interpreterServices =
      InterpreterServices(); // Create a single instance

  @override
  void initState() {
    super.initState();
    _loadModel();
  }

  Future<void> _loadModel() async {
    setState(() {
      _loading = true;
    });

    await _interpreterServices.loadModel(); // Load the model only once
    setState(() {
      _loading = false;
    });
  }

  Future<void> pickImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    setState(() {
      _loading = true;
      _image = File(pickedFile.path);
    });

    _interpreterServices.classifyImage(
      _image!,
      (result) {
        setState(() {
          _loading = false;
          _outputs = result;
        });
      },
      () {
        setState(() {
          _loading = false;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
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
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(
              color: Colors.purple,
            ))
          : Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: MediaQuery.of(context).size.width,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _image == null
                        ? Container()
                        : ClipRRect(
                            borderRadius: BorderRadiusGeometry.circular(20),
                            child: SizedBox(
                              height: 450,
                              width: MediaQuery.of(context).size.width,
                              child: Image.file(
                                _image!,
                              ),
                            ),
                          ),
                    const SizedBox(height: 20),
                    _outputs != null
                        ? Text(
                            "${_outputs![0]}",
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
