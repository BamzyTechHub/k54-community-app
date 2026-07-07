import 'package:flutter/material.dart';
import 'package:k54_mobile/features/home/screens/home_page.dart';
import 'package:k54_mobile/core/services/auth_service.dart';
import 'package:k54_mobile/core/services/buddyboss_service.dart';

class ProfileSetup extends StatefulWidget {
  const ProfileSetup({super.key});

  @override
  State<ProfileSetup> createState() => _ProfileSetupState();
}

class _ProfileSetupState extends State<ProfileSetup> {

  // Text Controllers

  final AuthService authService = AuthService();
  final BuddyBossService buddyBossService = BuddyBossService();

  bool isSaving = false;

  final TextEditingController usernameController =
      TextEditingController();

  final TextEditingController bioController =
      TextEditingController();

  final TextEditingController facebookController =
      TextEditingController();

  final TextEditingController linkedinController =
      TextEditingController();

  
  // Dropdown Values

  String? selectedField;

  String? selectedLevel;

  String? selectedGender;


  // Date of Birth
  DateTime? selectedDate;


  // Dropdown Lists

  final List<String> fields = [
    "Software Development",
    "UI/UX Design",
    "Digital Marketing",
    "Business",
    "Education",
    "Others",
  ];


  final List<String> levels = [
    "Beginner",
    "Intermediate",
    "Advanced",
    "Expert",
  ];


  final List<String> genders = [
    "Male",
    "Female",
    "Prefer not to say",
  ];


  @override
  void dispose() {

    usernameController.dispose();

    bioController.dispose();

    facebookController.dispose();

    linkedinController.dispose();

    super.dispose();
  }


  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Colors.white,

      body: SafeArea(

        child: SingleChildScrollView(

          child: Padding(

            padding: const EdgeInsets.symmetric(
              horizontal: 25,
            ),

            child: Column(

              children: [

                // Part 2 continues here
                const SizedBox(height: 25),


// K54 Logo
Image.asset(
  "assets/images/k54_logo.png",
  width: 120,
),


const SizedBox(height: 25),


// Welcome Text
Text(
  usernameController.text.isEmpty
      ? "Welcome!"
      : "Welcome ${usernameController.text}!",
  style: const TextStyle(
    fontSize: 30,
    fontWeight: FontWeight.bold,
  ),
),

const SizedBox(height: 5),


const Text(
  "Kindly setup your profile",
  style: TextStyle(
    color: Colors.grey,
    fontSize: 15,
  ),
),


const SizedBox(height: 25),


// Username Field
TextField(
  controller: usernameController,
  onChanged: (value) {
    setState(() {});
  },
  decoration: InputDecoration(
    labelText: "Create username",
    hintText: "NO SPACES ALLOWED",
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
    ),
  ),
),


const SizedBox(height: 15),


// Field/Profession Dropdown
DropdownButtonFormField<String>(
  initialValue: selectedField,
  decoration: InputDecoration(
    labelText: "What field are you in?",
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
    ),
  ),

  items: fields.map((field) {
    return DropdownMenuItem(
      value: field,
      child: Text(field),
    );
  }).toList(),

  onChanged: (value) {
    setState(() {
      selectedField = value;
    });
  },
),


const SizedBox(height: 15),


// Professional Level Dropdown
DropdownButtonFormField<String>(
  initialValue: selectedLevel,

  decoration: InputDecoration(
    labelText: "Professional Level",
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
    ),
  ),

  items: levels.map((level) {
    return DropdownMenuItem(
      value: level,
      child: Text(level),
    );
  }).toList(),

  onChanged: (value) {
    setState(() {
      selectedLevel = value;
    });
  },
),


const SizedBox(height: 15),


// Date Picker
GestureDetector(
  onTap: () async {

    DateTime? pickedDate =
        await showDatePicker(
      context: context,
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      initialDate: DateTime.now(),
    );


    if (pickedDate != null) {
      setState(() {
        selectedDate = pickedDate;
      });
    }

  },


  child: Container(

    width: double.infinity,
    padding: const EdgeInsets.all(16),

    decoration: BoxDecoration(
      border: Border.all(
        color: Colors.grey,
      ),
      borderRadius: BorderRadius.circular(12),
    ),

    child: Text(

      selectedDate == null
          ? "Select Birth Date"
          : "${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}",

      style: const TextStyle(
        fontSize: 16,
      ),
    ),
  ),
),


const SizedBox(height: 15),


// Gender Dropdown
DropdownButtonFormField<String>(
  initialValue: selectedGender,

  decoration: InputDecoration(
    labelText: "Select Gender",
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
    ),
  ),

  items: genders.map((gender) {

    return DropdownMenuItem(
      value: gender,
      child: Text(gender),
    );

  }).toList(),


  onChanged: (value) {

    setState(() {
      selectedGender = value;
    });

  },
),


const SizedBox(height: 20),


// Biography
TextField(

  controller: bioController,

  maxLines: 5,

  decoration: InputDecoration(

    hintText:
        "Write about yourself, hobbies, passions and expectations...",

    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
    ),
  ),
),


const SizedBox(height: 20),


// Social Links
const Text(
  "Social Links",
  style: TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
  ),
),


const SizedBox(height: 15),


// Facebook
TextField(
  controller: facebookController,

  decoration: InputDecoration(
    prefixIcon: const Icon(
      Icons.facebook,
      color: Colors.blue,
    ),

    hintText: "Facebook link",

    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
    ),
  ),
),


const SizedBox(height: 15),


// LinkedIn
TextField(
  controller: linkedinController,

  decoration: InputDecoration(
    prefixIcon: const Icon(
      Icons.business,
      color: Colors.blue,
    ),

    hintText: "LinkedIn link",

    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
    ),
  ),
),


const SizedBox(height: 25),


// Part 3 continues here
// Save and Continue Button

GestureDetector(

  onTap: isSaving ? null : () async {

    // Username Validation
    if (usernameController.text.isEmpty) {

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Username cannot be empty"),
        ),
      );

      return;
    }

    if (selectedField == null ||
    selectedLevel == null ||
    selectedGender == null ||
    selectedDate == null) {

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text(
        "Please complete all required fields",
      ),
    ),
  );

  return;
}


    // No spaces validation
    if (usernameController.text.contains(" ")) {

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Username cannot contain spaces"),
        ),
      );

      return;
    }

    setState(() => isSaving = true);

    try {
      // Username is set at signup (registration's field_3) and isn't
      // editable via xprofile, so it's validated above but never re-sent
      // here. Field/Industry (31), Professional Status (5), Gender (18),
      // and Birth Date (4) are confirmed xprofile fields, but the write
      // payload shape BuddyBoss expects for their selectbox/gender/datebox
      // types hasn't been confirmed against a live response - sending a
      // guess risks a silent wrong value or a rejected write, so only the
      // plain-text Biography field (17) is actually persisted here.
      final user = await authService.getCurrentUser();
      final userId = user.data["id"].toString();

      await buddyBossService.updateProfileField(
        userId: userId,
        fieldId: 17,
        value: bioController.text.trim(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Bio saved. Field, Professional Level, Gender, Birth Date "
            "and Social Links aren't syncing yet - we're still confirming "
            "how the website expects those.",
          ),
          duration: Duration(seconds: 4),
        ),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const HomePage(),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Failed to save profile: $e",
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  },
  child: Container(

    width: double.infinity,
    height: 55,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(25),
      gradient: const LinearGradient(
        colors: [
          Color(0xFF008000),
          Color(0xFFAB8000),
          Color(0xFF008000),
        ],
      ),

    ),

    child: Center(

      child: isSaving
          ? const SizedBox(
              height: 22,
              width: 22,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            )
          : const Text(

        "Save and Continue",

        style: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),

      ),

    ),

  ),

),


const SizedBox(height: 15),


// Go Back Button

GestureDetector(

  onTap:() {

    Navigator.pop(context);

  },


  child: Container(

    width: double.infinity,
    height: 55,

    decoration: BoxDecoration(

      borderRadius: BorderRadius.circular(25),

      border: Border.all(
        color: const Color(0xFF008000),
        width: 2,
      ),

    ),


    child: const Center(

      child: Text(

        "Go Back",

        style: TextStyle(

          color: Color(0xFF008000),
          fontSize: 18,
          fontWeight: FontWeight.bold,

        ),

      ),

    ),

  ),

),


const SizedBox(height: 30),


              ],

            ),

          ),

        ),

      ),

    );

  }

}