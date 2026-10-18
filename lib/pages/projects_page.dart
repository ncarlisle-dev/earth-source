import 'package:flutter/material.dart';
import '../../api/api.dart' as api;
import './project_dashboard.dart';

class UserProjectsPage extends StatefulWidget {
  const UserProjectsPage({
    super.key
  });

  @override
  State<UserProjectsPage> createState() => _UserProjectsPageState();
}

/// The mutable state of the project predictions page.
class _UserProjectsPageState extends State<UserProjectsPage>
{
  String? projectName;
  String? projectDescription;
  
  /// Fetches a list of all the user's projects.
  Future<List<api.Project>> fetchProjects() async
  {
    api.ProjectController projectController = 
      await api.ProjectController.getInstance();
    return projectController.userProjects;
  }

  void renameJob()
  {
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          scrollable: true,
          content: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Form(
              key: formKey,
              child: Column(
                children: [
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: "Enter project name:",
                    ),
                    validator: (String? value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a name for the project.';
                      }
                      return null;
                    },
                    onSaved: (value) async {
                      setState(() {
                        projectName = value;
                      });
                    },
                  ),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: "Enter project description:",
                    ),
                    validator: (String? value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a description for the project.';
                      }
                      return null;
                    },
                    onSaved: (value) async {
                      setState(() {
                        projectDescription = value;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            ElevatedButton(
              child: const Text("Submit"),
              onPressed: () {
                formKey.currentState!.save();
                Navigator.of(context).pop();
              },
            ),
          ]
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
  
    return ListView(
      children: [
        Padding(
          padding: EdgeInsetsGeometry.symmetric(vertical: 16.0),
          child: Center(
            child: Text(
              "Predictions", 
              style: TextTheme.of(context).headlineLarge?.copyWith(
                fontWeight: FontWeight.bold, 
                color: Colors.indigo
              )
            )
          ), //Icon
        ), 
        // Button for adding predictions which navigates to the prediction
        // generation page.
        Padding(
          padding: EdgeInsetsGeometry.symmetric(vertical: 16.0),
          child: FloatingActionButton(
            onPressed: () => "null",
            child: const Icon(Icons.add)
          )
        ),
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.75,
          child: FutureBuilder(
            future: fetchProjects(),
            builder: (
              BuildContext ctx, 
              AsyncSnapshot<List<api.Project>> snapshot
            ) 
            => snapshot.hasData
            ?
            ListView.builder(
              itemCount: 4, 
              itemBuilder: (BuildContext context, int index) {
                return Card(
                  elevation: 50,
                  shadowColor: Colors.black,
                  child: SizedBox(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        children: [
                          Text(
                            snapshot.data![index].name,
                            style: TextStyle(
                              fontSize: 30,
                              color: Colors.indigo,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            "Description: ${snapshot.data![index].description}",
                            style: TextStyle(fontSize: 15)
                          ),
                          Text(
                            "Date Created: ${snapshot.data![index].createdAt}",
                            style: TextStyle(fontSize: 15)
                          ),
                          Text(
                            "Last Updated: ${snapshot.data![index].lastUpdated}"
                            ,
                            style: TextStyle(fontSize: 15)
                          ),
                          Text(
                            "Number of Layers: "
                            "${snapshot.data![index].layers.length}",
                            style: TextStyle(fontSize: 15)
                          ),
                          Text(
                            "Number of Units: "
                            "${snapshot.data![index].units.length}",
                            style: TextStyle(fontSize: 15)
                          ),
                          Text(
                            "Number of Predictions: "
                            "${snapshot.data![index].predictions.length}",
                            style: TextStyle(fontSize: 15)
                          ),
                          // Button which navigates to the project dashboard
                          // page for the selected project.
                          SizedBox(
                            width: 100,
                            child: ElevatedButton(
                              onPressed: () => Navigator.push(
                                  context, 
                                  MaterialPageRoute<void>(builder: 
                                    (context) => ProjectDashboard(
                                      project: snapshot.data![index]
                                    )
                                  )
                                ),
                              child: Text("View Project")
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                );
              }
            )
            :
            Center(child:Text("No projects created so far!"))
          ),
        ),
      ],
    );
  }
}