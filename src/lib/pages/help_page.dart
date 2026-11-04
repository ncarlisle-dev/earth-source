import 'package:flutter/material.dart';

/// A page providing a guide to using the app, documentation, troubleshooting
/// tips, and contact information.
class HelpPage extends StatefulWidget {
  const HelpPage({super.key});

  @override
  State<HelpPage> createState() => _HelpPageState();
}

/// The mutable state of the help page.
class _HelpPageState extends State<HelpPage> {

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
          padding: const EdgeInsets.all(10.0),
          child: ElevatedButton(
            onPressed: () async {
              api.NetworkService networkService = 
                await api.NetworkService.getInstance();
              bool isAuthenticated = true;
              //bool isAuthenticated = await 
              //  networkService.authenticateUser();
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
            child: Text("Login with GitHub"),
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
      ]
    ));
    }
} 