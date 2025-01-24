import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:http/http.dart' as http;
import 'package:my_project/main.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

import 'package:rive/rive.dart';

import '../../api_constants.dart';

class signup extends StatelessWidget {
   const signup({
    super.key, required this.isArabic, required this.isFrench});

  final bool isArabic;
  final bool isFrench;


   @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        IconButton(
          padding: EdgeInsets.zero,
          onPressed: () {
            showGeneralDialog(
              barrierDismissible: true,
              barrierLabel: "Sign UP",
              context: context,
              transitionDuration: const Duration(milliseconds: 400),
              transitionBuilder:
                  (context, animation, secondaryAnimation, child) {
                Tween<Offset> tween =
                    Tween(begin: const Offset(0, -1), end: Offset.zero);
                return SlideTransition(
                    position: tween.animate(CurvedAnimation(
                        parent: animation, curve: Curves.easeInOut)),
                    child: child);
              },
              pageBuilder: (context, _, __) => Center(
                child: Container(
                  height: 620,
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding:
                      const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.94),
                    borderRadius: const BorderRadius.all(
                      Radius.circular(40),
                    ),
                  ),
                  child:  Scaffold(
                    resizeToAvoidBottomInset: false,
                    backgroundColor: Colors.transparent,
                    body: SingleChildScrollView(
                      child: Column(
                        children: [
                          Text(
                            isArabic
                                ? "تسجيل حساب"
                                : isFrench
                                ?"S'inscrire"

                                : "SignUp",
                            style: const TextStyle(
                              fontSize: 40,
                              fontFamily: "Outfit",
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          signupForm( isArabic: isArabic,
                            isFrench: isFrench,),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
          icon: SvgPicture.asset(
            "assets/icons/google_box.svg",
            height: 64,
            width: 64,
          ),
        ),
      ],
    );
  }
}

//forme signup

class signupForm extends StatefulWidget {
  const signupForm({
    super.key, required this.isArabic, required this.isFrench});

  final bool isArabic;
  final bool isFrench;


  @override
  State<signupForm> createState() => _signupFormState();

}

class _signupFormState extends State<signupForm> {

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool isShowLoading = false;
  bool isShowConfetti = false;
  bool isSignInDialogShown = false;
  String? selectedOption; // Variable to store the selected option
  List<String> options = ['Parent', 'Medecin']; // Options for the dropdown button
   // Utilisez le nom approprié pour le paramètre (options -> userType)

  late SMITrigger check;
  late SMITrigger error;
  late SMITrigger reset;
  // Location variables
  String selectedCity = '';
  LatLng? selectedLocation;
  final TextEditingController _locationController = TextEditingController();

  late SMITrigger confetti;
  final TextEditingController _usrNameController = TextEditingController();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _telephoneController = TextEditingController();
  final _nombebeController = TextEditingController();
  final _prenombebeController = TextEditingController();
  final _DatenaissanceController = TextEditingController();
  void _onCheckRiveInit(Artboard artboard) {
    StateMachineController? controller =
    StateMachineController.fromArtboard(artboard, 'State Machine 1');
    artboard.addController(controller!);
    error = controller.findInput<bool>('Error') as SMITrigger;
    check = controller.findInput<bool>('Check') as SMITrigger;
    reset = controller.findInput<bool>('Reset') as SMITrigger;
  }
  bool _isPasswordVisible = false;
  void _togglePasswordVisibility() {
    setState(() {
      _isPasswordVisible = !_isPasswordVisible;
    });
  }
  void _onConfettiRiveInit(Artboard artboard) {
    StateMachineController? controller =
    StateMachineController.fromArtboard(artboard, "State Machine 1");
    artboard.addController(controller!);
    confetti = controller.findInput<bool>("Trigger explosion") as SMITrigger;
  }

  Future<bool> _handleLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          widget.isArabic
              ? "خدمات الموقع معطلة"
              : widget.isFrench
              ? "Services de localisation désactivés"
              : "Location services are disabled",
        ),
      ));
      return false;
    }
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
            widget.isArabic
                ? "تم رفض أذونات الموقع"
                : widget.isFrench
                ? "Autorisations de localisation refusées"
                : "Location permissions are denied",
          ),
        ));
        return false;
      }
    }
    return true;
  }
  // Future<String> fetchCityNameFromNominatim(double latitude, double longitude) async {
  //   final url =
  //       'https://nominatim.openstreetmap.org/reverse?format=json&lat=$latitude&lon=$longitude';
  //
  //   final response = await http.get(Uri.parse(url));
  //   if (response.statusCode == 200) {
  //     final data = jsonDecode(response.body);
  //     return data['address']['city'] ??
  //         data['address']['town'] ??
  //         data['address']['village'] ??
  //         'Unknown location';
  //   } else {
  //     throw Exception('Failed to fetch city name');
  //   }
  // }

  // Rechercher la ville en fonction du nom
  Future<void> _searchCity(String cityName) async {
    if (cityName.isEmpty) return;

    try {
      // Recherche de la ville via l'API de géocodage
      List<Location> locations = await locationFromAddress(cityName);
      if (locations.isNotEmpty) {
        setState(() {
          selectedLocation = LatLng(locations.first.latitude, locations.first.longitude);
          selectedCity = cityName;  // Mise à jour de la ville sélectionnée
          _locationController.text = cityName;  // Mise à jour du champ de texte
        });
      }
    } catch (e) {
      print("Erreur lors de la recherche de la ville : $e");
    }
  }

  // Affiche la carte pour choisir l'emplacement
  Future<void> _showLocationPicker() async {
    final LatLng initialPosition = selectedLocation ?? LatLng(0.0, 0.0);

    final LatLng? result = await showDialog(
      context: context,
      builder: (BuildContext context) {
        LatLng selectedPos = initialPosition;
        return AlertDialog(
          title: Text(
            widget.isArabic ? "حدد موقعك" : widget.isFrench ? "Sélectionnez votre emplacement" : "Select your location",
          ),
          content: SizedBox(
            height: 300,
            width: 300,
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: initialPosition,
                zoom: 15,
              ),
              onTap: (LatLng pos) {
                selectedPos = pos;
              },
              markers: {
                Marker(
                  markerId: const MarkerId('selected'),
                  position: selectedPos,
                )
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                widget.isArabic ? "إلغاء" : widget.isFrench ? "Annuler" : "Cancel",
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, selectedPos),
              child: Text(
                widget.isArabic ? "تأكيد" : widget.isFrench ? "Confirmer" : "Confirm",
              ),
            ),
          ],
        );
      },
    );

    if (result != null) {
      setState(() {
        selectedLocation = result;
        _locationController.text = "Loading..."; // Affichage d'un texte de chargement
      });

      // Géocodage inversé pour obtenir le nom de la ville
      String cityName = await fetchCityNameFromNominatim(result.latitude, result.longitude);
      setState(() {
        selectedCity = cityName;
        _locationController.text = cityName; // Mise à jour de l'emplacement avec le nom complet de la ville
      });
    }
  }

  // Fonction pour obtenir le nom de la ville en utilisant les coordonnées (géocodage inversé)
  Future<String> fetchCityNameFromNominatim(double latitude, double longitude) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(latitude, longitude);
      return placemarks.isNotEmpty ? placemarks.first.locality ?? "" : "Unknown";
    } catch (e) {
      return "Error fetching city";
    }
  }


  void signup() async {
    setState(() {
      isShowLoading = true;
      isShowConfetti = true;
    });
    Future.delayed(const Duration(seconds: 1), () async {
      if (_formKey.currentState!.validate()) {
        check.fire();
        Future.delayed(const Duration(seconds: 2), () async {
          setState(() {
            isShowLoading = false;
          });

          confetti.fire();
          Future.delayed(const Duration(seconds: 1), () async {
            Map<String, dynamic> userData = {
              'usertype': selectedOption!, // Type d'utilisateur sélectionné
              'usrname': _usrNameController.text,
              'email': _emailController.text,
              'password': _passwordController.text,
              'telephone': _telephoneController.text,
              'namebebe': _nombebeController.text,
              'fullname': _prenombebeController.text,
              'datenaissance': _DatenaissanceController.text
            };
            if (selectedOption == 'Medecin' && selectedLocation != null) {
              userData['city'] = selectedCity;
              userData['latitude'] = selectedLocation!.latitude;
              userData['longitude'] = selectedLocation!.longitude;
            }
            // Envoi des données utilisateur au serveur
            try {
              final response = await http.post(
                Uri.parse(ApiConstants.registredUrl),
                body: json.encode(userData),
                headers: {
                  'Content-Type': 'application/json',
                },
              );
              if (response.statusCode == 200) {
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(widget.isArabic
                          ? "تم إرسال بريد إلكتروني للتحقق"
                          : widget.isFrench
                          ? "Un email de verification a été envoyée"
                          : "A verification email has been sent"),
                      backgroundColor: Colors.green,
                    ));

                // L'utilisateur a été créé avec succès
                Future.delayed(const Duration(seconds: 3), () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const MyApp(),
                    ),
                  );
                });
              }
                 else {
                // Gérer les erreurs éventuelles lors de la création de l'utilisateur
                print('Erreur lors de la création de l\'utilisateur: ${response.body}');

                // Afficher un message d'erreur à l'utilisateur

              }



            } catch (e) {

              // Gérer les erreurs de connexion au serveur
              print('Erreur de connexion au serveur: $e');
              ScaffoldMessenger.of(context).showSnackBar(
                 SnackBar(
                  content: Text(widget.isArabic ? "تحقق من اتصالك" : widget.isFrench ?"verifier votre connexion" : "check your connection",
                  ),backgroundColor: Colors.red,
                ),
              );
              // Handle error
              Future.delayed(const Duration(seconds: 2), () {
                setState(() {
                  isShowLoading = false;
                });
              });

              // Afficher un message d'erreur à l'utilisateur
            }
          });
        });
      } else {
        error.fire();
        Future.delayed(const Duration(seconds: 2), () {
          setState(() {
            isShowLoading = false;
          });
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                 Row(
                  children: [
                    const Expanded(
                      child: Divider(),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                      widget.isArabic ? "بيانات" : widget.isFrench ?"Donnée" : "Data",

                        style: const TextStyle(color: Colors.black26),
                      ),
                    ),
                    const Expanded(
                      child: Divider(),
                    ),
                  ],
                ),
                 Text(
                 widget.isArabic ? "نوع المستخدم" : widget.isFrench ?"Type d'utilisateur" : "User type",
                  style: const TextStyle(color: Colors.black54),
                ),
                DropdownButtonFormField<String>(

                  value: selectedOption,
                  onChanged: (String? value) {
                    setState(() {
                      selectedOption = value;
                    });
                  },
                  items: options.map((String option) {
                    return DropdownMenuItem<String>(
                      value: option,
                      child: Text(option),
                    );
                  }).toList(),
                  decoration: const InputDecoration(
                    prefixIcon: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8.0),
                      child: Icon(Icons.person),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.blue),
                      borderRadius: BorderRadius.all(Radius.circular(25)),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return widget.isArabic ? "الرجاء تحديد نوع المستخدم" : widget.isFrench ?"Veuillez sélectionner un type d'utilisateur" : "Please select a user type";

                    }
                    return null;
                  },
                ),
                if (selectedOption == 'Medecin') ...[
                  const SizedBox(height: 16),
                  Text(
                    widget.isArabic
                        ? "المدينة"
                        : widget.isFrench
                        ? "Ville"
                        : "City",
                    style: const TextStyle(color: Colors.black54),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0, bottom: 16),
                    child: TextFormField(
                      controller: _locationController,
                      readOnly: false,  // Permet l'édition de l'emplacement
                      validator: (value) {
                        if (value?.isEmpty ?? true) {
                          return widget.isArabic
                              ? "الرجاء تحديد موقعك"
                              : widget.isFrench
                              ? "Veuillez sélectionner votre emplacement"
                              : "Please select your location";
                        }
                        return null;
                      },
                      onChanged: (value) async {
                        if (value.isNotEmpty) {
                          // Rechercher la localisation via l'API de géocodage pour compléter la saisie de l'utilisateur
                          try {
                            List<Location> locations = await locationFromAddress(value);
                            if (locations.isNotEmpty) {
                              setState(() {
                                selectedLocation = LatLng(locations.first.latitude, locations.first.longitude);
                              });
                            }
                          } catch (e) {
                            print("Erreur de géocodage : $e");
                          }
                        }
                      },
                      decoration: InputDecoration(
                        prefixIcon: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8.0),
                          child: Icon(Icons.location_on),
                        ),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.map),
                          onPressed: _showLocationPicker,  // Affiche la carte pour choisir un emplacement
                        ),
                        focusedBorder: const OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.blue),
                          borderRadius: BorderRadius.all(Radius.circular(25)),
                        ),
                      ),
                    ),
                  ),
                ],

                Text(
                   widget.isArabic ? "الاسم و اللقب" : widget.isFrench ?"Nom et Prenom" : "First and last name",

                  style: const TextStyle(color: Colors.black54),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 8.0, bottom: 24),
                  child: TextFormField(
                    controller: _usrNameController,
                    validator: (value) {
                      if (value!.isEmpty) {
                        return widget.isArabic ? "الرجاء إدخال الاسم و اللقب" : widget.isFrench ?"Veuillez entrer votre nom et votre prénom" : "Please enter your First and Last Name";
                      }
                      return null;
                    },
                    decoration: const InputDecoration(
                      prefixIcon: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8.0),
                        child: Icon(
                          Icons.account_circle,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.blue),
                          borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(25),
                              topRight: Radius.circular(25),
                              bottomRight: Radius.circular(25),
                              bottomLeft: Radius.circular(25))),
                    ),
                  ),
                ),

                 Text(
               widget.isArabic ? "بريد إلكتروني" : widget.isFrench ?"Email" : "Email",
                  style: const TextStyle(color: Colors.black54),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 8.0, bottom: 24),
                  child: TextFormField(
                    controller: _emailController,
                    validator: (value) {
                      if (value!.isEmpty) {
                        return widget.isArabic ? "الرجاء أدخل بريدك الإلكتروني" : widget.isFrench ?"Veuillez entrer votre mail" : "Please enter your email";

                      }
                      if (!value.contains('@')) {
                        return widget.isArabic ? "يجب أن يحتوي عنوان البريد الإلكتروني على @" : widget.isFrench ?"L'adresse e-mail doit contenir un @" : "The email address must contain an @";

                      }
                      // Utilisation d'une expression régulière pour valider le format de l'e-mail
                      String emailPattern = r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$';
                      RegExp regExp = RegExp(emailPattern);
                      if (!regExp.hasMatch(value)) {
                        return widget.isArabic ? "يرجى إدخال عنوان بريد إلكتروني صالح" : widget.isFrench ?"Veuillez entrer une adresse e-mail valide" : "Please enter a valid email address";

                      'Veuillez entrer une adresse e-mail valide';
                      }

                      return null;
                    },
                    decoration: const InputDecoration(
                      prefixIcon: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8.0),
                        child: Icon(
                          Icons.account_box,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.blue),
                          borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(25),
                              topRight: Radius.circular(25),
                              bottomRight: Radius.circular(25),
                              bottomLeft: Radius.circular(25))),
                    ),
                  ),
                ),
                 Text(
                widget.isArabic ? "كلمة السر" : widget.isFrench ?"Mot de passe" : "Password",

                  style: const TextStyle(color: Colors.black54),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 8.0, bottom: 16),
                  child: TextFormField(
                    controller: _passwordController,
                    validator: (value) {
                      if (value!.isEmpty) {
                        return widget.isArabic ? "الرجاء أدخل رقمك السري" : widget.isFrench ?"Veuillez entrer votre mot de passe" : "Please enter your password";

                         "Veuillez entrer votre password";
                      }
                      if (value.length < 6) {
                        return widget.isArabic ? "تحتوي كلمة المرور على 6 أحرف على الأقل" : widget.isFrench ?"Le mot de passe doit contenir au moins 6 caractères" : "Password must contain at least 6 characters";
                    }
                      return null;
                    },
                    onSaved: (password) {},


                    obscureText: !_isPasswordVisible,// Met à jour l'obscuration du texte en fonction de l'état de visibilité

                    // obscureText: true,
                    decoration:  InputDecoration(
                      prefixIcon: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8.0),
                        child: Icon(
                          Icons.beenhere,
                        ),
                      ),
                      suffixIcon: IconButton(
                        onPressed: _togglePasswordVisibility, // Appelle la fonction pour basculer la visibilité du mot de passe
                        icon: Icon(
                          _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                          color: Colors.grey,
                        ),
                      ),
                      focusedBorder: const OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.blue),
                          borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(25),
                              topRight: Radius.circular(25),
                              bottomRight: Radius.circular(25),
                              bottomLeft: Radius.circular(25))),
                    ),
                  ),
                ),
                 Text(
                 widget.isArabic ? "رقم الهاتف" : widget.isFrench ?"Numero de telephone" : "Phone number",

                  style: const TextStyle(color: Colors.black54),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 8.0, bottom: 16),
                  child: TextFormField(
                    controller: _telephoneController,
                    validator: (value) {
                      if (value!.isEmpty) {
                        return widget.isArabic ? "يرجى إدخال رقم الهاتف الخاص بك" : widget.isFrench ?"Le numéro doit contenir 8 chiffres" : "Please enter your phone number";

                        "Veuillez entrer votre numero telephone";
                      }
                      if (value.length != 8) {
                        return widget.isArabic ? "يجب أن يحتوي الرقم على 8 أرقام" : widget.isFrench ?"Le numéro doit contenir 8 chiffres" : "The number must contain 8 digits";

                      }
                      return null;
                    },
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      prefixIcon: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8.0),
                        child: Icon(
                          Icons.call,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.blue),
                          borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(25),
                              topRight: Radius.circular(25),
                              bottomRight: Radius.circular(25),
                              bottomLeft: Radius.circular(25))),
                    ),
                  ),
                ),

                // Ajout du code pour masquer les champs "nombebe" et "fullname" si l'option "Medecin" est sélectionnée
                if (selectedOption != 'Medecin')
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      Row(
                        children: [
                          const Expanded(
                            child: Divider(),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              widget.isArabic ? "معطيات الطفل" : widget.isFrench ?"donnée bébé" : "baby data",


                              style: const TextStyle(color: Colors.black26),
                            ),
                          ),
                          const Expanded(
                            child: Divider(),
                          ),
                        ],
                      ),
                      Text(
                        widget.isArabic ? "اسم الطفل" : widget.isFrench ?"prénom bébé" : "name baby",

                        style: const TextStyle(color: Colors.black54),
                      ),

                      Padding(
                        padding: const EdgeInsets.only(top: 8.0, bottom: 16),
                        child: TextFormField(
                          controller: _nombebeController,
                          validator: (value) {
                            if (value!.isEmpty) {
                              return widget.isArabic ? "الرجاء إدخال اسم الطفل" : widget.isFrench ?"Veuillez entrer le nom du bébé" : "Please enter the baby's name";

                            }
                            return null;
                          },
                          decoration: const InputDecoration(
                            prefixIcon: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8.0),
                              child: Icon(
                                Icons.child_care,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.blue),
                                borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(25),
                                    topRight: Radius.circular(25),
                                    bottomRight: Radius.circular(25),
                                    bottomLeft: Radius.circular(25))),
                          ),
                        ),
                      ),
                      Text(
                        widget.isArabic ? "لقب الطفل" : widget.isFrench ?"Nom bébé" : "Surname baby",

                        style: const TextStyle(color: Colors.black54),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0, bottom: 16),
                        child: TextFormField(
                          controller: _prenombebeController,
                          validator: (value) {
                            if (value!.isEmpty) {

                              return widget.isArabic ? "الرجاء لقب الاسم الأول للطفل" : widget.isFrench ?"Veuillez saisir le prénom du bébé" : "Please enter baby's first name";

                            }
                            return null;
                          },
                          // ignore: non_constant_identifier_names
                          onSaved: (Prenombebe) {},
                          decoration: const InputDecoration(
                            prefixIcon: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8.0),
                              child: Icon(
                                Icons.child_care,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.blue),
                                borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(25),
                                    topRight: Radius.circular(25),
                                    bottomRight: Radius.circular(25),
                                    bottomLeft: Radius.circular(25))),
                          ),
                        ),
                      ),
                      Text(
                        widget.isArabic ? "تاريخ الميلاد" : widget.isFrench ?"Date de naissance" : "Date of birth",


                        style: const TextStyle(color: Colors.black54),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0, bottom: 16),
                        child: TextFormField(
                          validator: (value) {
                            if (value!.isEmpty) {
                              return widget.isArabic ? "الرجاء إدخال تاريخ ميلاد الطفل" : widget.isFrench ? "Veuillez entrer la date de naissance de bebe" : "Please enter baby's date of birth";

                            }

                            return null;
                          },
                          // ignore: non_constant_identifier_names
                          controller: _DatenaissanceController,
                          decoration: const InputDecoration(
                            prefixIcon: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8.0),
                              child: Icon(
                                Icons.calendar_today,
                              ),
                            ),
                            filled: true,
                            focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.blue),
                                borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(10),
                                    topRight: Radius.circular(25),
                                    bottomRight: Radius.circular(25),
                                    bottomLeft: Radius.circular(25))),
                          ),
                          readOnly: true,
                          onTap: () async {
                            DateTime? picked = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now(),
                                firstDate: DateTime(2018),
                                lastDate: DateTime(2028));
                            setState(() {
                              _DatenaissanceController.text =
                              picked.toString().split(" ")[0];
                            });
                                                    },
                        ),
                      ),
                    ],
                  ),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                   Text(
                    widget.isArabic ? "هل لديك حساب؟" : widget.isFrench ? "Avez-vous un compte?" : "Do you have an account?",

                    style: const TextStyle(color: Colors.grey),
                  ),
                  TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child:  Text(widget.isArabic ? "تسجيل الدخول" : widget.isFrench ? "Login" : "SignIn",
                      ))
                ]),
                Padding(
                  padding: const EdgeInsets.only(top: 8.0, bottom: 24),
                  child: ElevatedButton.icon(
                      onPressed: () {


                        signup();
                      },
                      style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF77D8E),
                          minimumSize: const Size(double.infinity, 56),
                          shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(10),
                                  topRight: Radius.circular(25),
                                  bottomRight: Radius.circular(25),
                                  bottomLeft: Radius.circular(25)))),
                      icon: const Icon(
                        CupertinoIcons.arrow_right,
                        color: Color(0xFFFE0037),
                      ),
                      label:  Text(widget.isArabic ? "تسجيل اشتراك" : widget.isFrench ? "Enregistrer" : "Register",)),
                )
              ],
            )),
        isShowLoading
            ? CustomPositioned(
          child: RiveAnimation.asset(
            'assets/RiveAssets/check.riv',
            fit: BoxFit.cover,
            onInit: _onCheckRiveInit,
          ),
        )
            : const SizedBox(),
        isShowConfetti
            ? CustomPositioned(
          scale: 6,
          child: RiveAnimation.asset(
            "assets/RiveAssets/confetti.riv",
            onInit: _onConfettiRiveInit,
            fit: BoxFit.cover,
          ),
        )
            : const SizedBox(),
      ],
    );
  }
}

class CustomPositioned extends StatelessWidget {
  const CustomPositioned({super.key, this.scale = 1, required this.child});

  final double scale;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Column(
        children: [
          const SizedBox(height: 500),

          const Spacer(),
          SizedBox(
            height: 100,
            width: 100,
            child: Transform.scale(
              scale: scale,
              child: child,
            ),
          ),
          const Spacer(flex: 2),
        ],
      ),
    );
  }
}