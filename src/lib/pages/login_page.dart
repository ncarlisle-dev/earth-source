import 'package:flutter/material.dart';
import './home_page.dart';
import '../api/api.dart' as api;

/// A page allowing the user to log in to the app.
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => LoginPageState();
}

/// The mutable state of the login page.
class LoginPageState extends State<LoginPage> {
  // Variable storing the inputted username.
  String? _username;
  // Variable storing the inputted password.
  String? _password;
  // Boolean to track whether or not user authentication failed.
  bool authenticationFailure = false;
  // Global key for the login form.
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Material(child:ListView(
      children: [
        Image.asset(
          "assets/Logo.png",
          height: 300
        ),
        Padding(
          padding: EdgeInsetsGeometry.symmetric(vertical: 16.0),
          child: Center(
            child: Text("ArchaeoSight 2.0",
              //dataSpec.fileName, 
              style: TextTheme.of(context).headlineLarge?.copyWith(
                fontWeight: FontWeight.bold, 
                color: Colors.indigo
              )
            )
          ), //Icon
        ),
        Padding(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                TextFormField(
                  decoration: const InputDecoration(hintText: 'Username:'),
                  validator: (String? value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a value for username.';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    setState(() {
                      _username = value;
                    });
                  },
                ),
                TextFormField(
                  decoration: const InputDecoration(
                    hintText: 'Password:'
                  ),
                  validator: (String? value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a value for password.';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    setState(() {
                      _password = value;
                    });
                  },
                ),
              ],
            )
          )
        ),
        !authenticationFailure
        ? Center(child: Text(""))
        : Center(child: Text(
          "Username or password is incorrect.",
          style: TextTheme.of(context).bodyMedium?.copyWith(
            fontWeight: FontWeight.bold, 
            color: Colors.red
          )
        )),
        Padding(
          padding: const EdgeInsets.all(10.0),
          child: ElevatedButton(
            onPressed: () async {
              _formKey.currentState!.save();
              api.NetworkService networkService = 
                await api.NetworkService.getInstance();
              bool isAuthenticated = await 
                networkService.authenticateUser(_username!, _password!);
              if (isAuthenticated) {
                if (context.mounted) {
                  Navigator.push(context, MaterialPageRoute<void>(
                    builder: (context) => HomePage()
                  ));
                }
                else {
                  setState(() {
                    authenticationFailure = true;
                  });
                }
              }
            },
            child: Text("Login"),
          )
        ),
      ]
    ));
  }
}
