import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'homepage.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Projet ECF SUPER BOWL',
      theme: ThemeData(
        primaryColor: Colors.orange,
        hintColor: Colors.blueGrey,
        colorScheme: ThemeData().colorScheme.copyWith(
          primary: Colors.deepOrange,
          secondary: Colors.blueGrey,
          onPrimary: Colors.white,
        ),
        buttonTheme: ButtonThemeData(textTheme: ButtonTextTheme.primary),
        inputDecorationTheme: InputDecorationTheme(
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.deepOrange, width: 1.0),
          ),
        ),
      ),
      routes: {
        '/': (context) => LoginPage(),
        '/homepage': (context) => HomePage(),
      },

    );
  }
}

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // Déplacez vos contrôleurs et variables d'état ici
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isPasswordVisible = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Partie gauche 
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/bg.jpg'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          // Partie droite 
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 100.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset('assets/logo.png'),
                      SizedBox(height: 16),
                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _emailController,
                              decoration: InputDecoration(labelText: 'Login'),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Entrez votre email';
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: 16),
                            TextFormField(
                              controller: _passwordController,
                              decoration: InputDecoration(
                                labelText: 'Mot de passe',
                                // Ajoutez une icône d'œil à la fin du champ de texte
                                suffixIcon: IconButton(
                                  icon: Icon(
                              
                                    _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                                  ),
                                  onPressed: () {
                          
                                    setState(() {
                                      _isPasswordVisible = !_isPasswordVisible;
                                    });
                                  },
                                ),
                              ),
                              obscureText: !_isPasswordVisible, 
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Entrez votre mot de passe';
                                }
                                return null;
                              },
                            ),

                            SizedBox(height: 16),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey),
                              onPressed: () async {
                                if (_formKey.currentState!.validate()) {
                                  try {
                                    UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
                                      email: _emailController.text,
                                      password: _passwordController.text,
                                    );

            
                                    var userDoc = await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).get();

                                    if (userDoc.exists && userDoc.data()!['role'] == 'commentateur') {
                                      Navigator.pushReplacementNamed(context, '/homepage');
                                    } else {
                                      Fluttertoast.showToast(
                                        msg: "Vous n'êtes pas autorisé à vous connecter",
                                        toastLength: Toast.LENGTH_LONG,
                                        gravity: ToastGravity.BOTTOM,
                                        backgroundColor: Colors.red,
                                        textColor: Colors.white,
                                        fontSize: 16.0,
                                      );
                                    }
                                  } catch (e) {
                                    print("Exception type: ${e.runtimeType}");
                                    if (e is FirebaseAuthException) {
                                      print("FirebaseAuthException code: ${e.code}");
                                      switch (e.code) {
                                        case 'user-not-found':
                                        case 'wrong-password':
                                        case 'invalid-login-credentials':
                                          Fluttertoast.showToast(
                                            msg: "Combinaison email/mot de passe incorrecte.",
                                            toastLength: Toast.LENGTH_LONG,
                                            gravity: ToastGravity.BOTTOM,
                                            backgroundColor: Colors.orange,
                                            textColor: Colors.white,
                                            fontSize: 16.0,
                                          );
                                          break;
                                        case 'invalid-email':
                                          Fluttertoast.showToast(
                                            msg: "L'adresse e-mail est mal formatée.",
                                            toastLength: Toast.LENGTH_LONG,
                                            gravity: ToastGravity.BOTTOM,
                                            backgroundColor: Colors.orange,
                                            textColor: Colors.white,
                                            fontSize: 16.0,
                                          );
                                          break;
                                        default:
                                          Fluttertoast.showToast(
                                            msg: e.message ?? "Une erreur est survenue.",
                                            toastLength: Toast.LENGTH_LONG,
                                            gravity: ToastGravity.BOTTOM,
                                            backgroundColor: Colors.orange,
                                            textColor: Colors.white,
                                            fontSize: 16.0,
                                          );
                                      }
                                    } else {
                                      Fluttertoast.showToast(
                                        msg: "Erreur inattendue : ${e.toString()}",
                                        toastLength: Toast.LENGTH_LONG,
                                        gravity: ToastGravity.BOTTOM,
                                        backgroundColor: Colors.orange,
                                        textColor: Colors.white,
                                        fontSize: 16.0,
                                      );
                                    }
                                  }
                                }
                              },
                              child: Text('Connexion'),
                            ),
                            SizedBox(height: 16),
                            TextButton(
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      title: Text("Problème de connexion"),
                                      content: Text("Veuillez contacter votre administrateur"),
                                      actions: <Widget>[
                                        TextButton(
                                          child: Text("Fermer"),
                                          onPressed: () {
                                            Navigator.of(context).pop();
                                          },
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                              child: Text(
                                'Un problème pour vous connecter ?',
                                style: TextStyle(color: Colors.blueGrey),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
