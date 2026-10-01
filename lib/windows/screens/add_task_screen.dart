import 'package:flutter/material.dart';
import '../../../models/network_response.dart';
import '../../services/network_caller.dart';
import '../../../utils/api_links.dart';
import '../../../windows/screens/update_profile.dart';
import '../../../widgets/custom_button.dart';
import '../../constants/custom_colors.dart';
import '../../../widgets/screen_background.dart';
import '../../../widgets/user_banners.dart';

class WindowsAddTaskScreen extends StatefulWidget {
  const WindowsAddTaskScreen({super.key});

  @override
  State<WindowsAddTaskScreen> createState() => _WindowsAddTaskScreenState();
}

class _WindowsAddTaskScreenState extends State<WindowsAddTaskScreen> {
  final TextEditingController _taskNameController = TextEditingController();

  final TextEditingController _taskDescriptionController =
      TextEditingController();
  bool _addNewTaskLoading = false;

  Future<void> addNewTask() async {
    _addNewTaskLoading = true;
    if (mounted) {
      setState(() {});
    }
    Map<String, dynamic> requestBody = {
      "title": _taskNameController.text.trim(),
      "description": _taskDescriptionController.text.trim(),
      "status": "New",
    };
    final NetworkResponse response =
        await NetworkCaller().postRequest(ApiLinks.createTask, requestBody);
    _addNewTaskLoading = false;
    if (mounted) {
      setState(() {});
    }
    if (response.isSuccess) {
      _taskNameController.clear();
      _taskDescriptionController.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Task Added Successfully"),
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Task Added Failed"),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: UserBannerAppBar(onTapped: () {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => const WindowsUpdateProfileScreen()));
      }),
      body: ScreenBackground(
          child: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(
                      height: 30,
                    ),
                    const Text(
                      "Add Task",
                      style:
                          TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(
                      height: 16,
                    ),
                    CustomTextFormField(
                      hintText: "Task Title",
                      controller: _taskNameController,
                      // validator: (value) {
                      //   if (value?.isEmpty ?? true) {
                      //     return "Please enter task title";
                      //   }
                      //   return null;
                      // },
                    ),
                    const SizedBox(
                      height: 16,
                    ),
                    CustomTextFormField(
                      hintText: "Description",
                      controller: _taskDescriptionController,
                      // validator: (value) {
                      //   if (value?.isEmpty ?? true) {
                      //     return "Please enter task description";
                      //   }
                      //   return null;
                      // },
                    ),
                    const SizedBox(
                      height: 16,
                    ),
                    Visibility(
                        visible: _addNewTaskLoading == false,
                        replacement: const Center(
                          child: CircularProgressIndicator(),
                        ),
                        child: CustomButton(
                            onPresse: () {
                              addNewTask();
                            },
                            labels: "teste")),
                  ],
                )),
          ],
        ),
      )),
    );
  }
}

class CustomTextFormField extends StatelessWidget {
  final String hintText;
  final TextEditingController controller;
  final FormFieldValidator<String>? validator;

  const CustomTextFormField({
    super.key,
    required this.hintText,
    required this.controller,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          hintText: hintText,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderSide: BorderSide(
                color: CustomColors().getDarkGreenBorder(), width: 2.0),
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(
                color: CustomColors().getDarkGreenBorder(), width: 2.0),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(
                color: CustomColors().getDarkGreenBorder(), width: 2.0),
          ),
        ),
        validator: validator,
      ),
    );
  }
}
