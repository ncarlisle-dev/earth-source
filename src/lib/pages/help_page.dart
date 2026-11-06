import 'package:flutter/material.dart';

/// List of images of app pages to accompany text for the user guide.
const List<String> helpImages = [
  "Project_Creation.png", "Project_Dashboard.png", "Layer_Creation.png",
  "Unit_Creation.png", "Data_Spec_Page.png", "AirDroid_Modal.png", 
  "AirDroid_Connections.png", "Data_Assignment.png", "Predictions.png",
  "Prediction_Creation.png", "Prediction_Page.png", "Map_View.png"
];

/// List of text labels for each step in the user guide.
const List<String> helpText = ["From the projects page, click on the plus "
  "button to pull up a form where you'll fill out the required fields for a "
  "project.", "Creating a project will take you to the project dashboard, which"
  " is where you can view and change project details and access the map, data, "
  "predictions, and settings associated with a project. To set layers and units"
  " for a project, navigate to the Site Map page.", "Add layers to a "
  "project from the Site Map page. Each layer requires an associated image to "
  "be uploaded with it, and the corner points for a layer will correspond to "
  "the corners of the entire project site.", "Additionally, add units"
  " for a site on the Site Map page. Units will require coordinates for each "
  "of their four corner points, as well as a sampling point interval which "
  "marks the distance between samples taken within that unit.", "To view and "
  "add project data, navigate to the Sample Data page from the project "
  "dashboard. pXRF data can either be uploaded from a .csv file on your local "
  "device or from a pXRF device using AirDroid.", "To upload data via AirDroid,"
  " click on the corresponding button, which will take you to the AirDroid "
  "Connections page. Click on the plus button in the lower right corner to add "
  "a connection, which will pull a form in which you'll enter the IP address "
  "and port number corresponding to the AirDroid app on your pXRF device.", 
  "Once you make a connection, you'll be able to view a list of your "
  "connections and an icon indicating the status of each (green means you're "
  "successfully connected and ready to upload data from your device). You can "
  "refresh a connection or click on a file icon to view the file system of your"
  "connected device, which will allow you to select the file you want to "
  "upload to the app.", "Once you have at least one unit and one layer created"
  " for a project, you can assign your pXRF data files to locations within the "
  "project site. To do so, navigate back to the Sample Data page and click on "
  "the Assign Layers/Units button, which will allow you to select the unit and "
  "layer "
  "associated with that data file. Assigning data to a layer is necessary in "
  "order to run predictions on that layer.", "To view and create predictions, "
  "navigate to the Predictions page from the project dashboard, which will "
  "display a list of predictions and their current status.", "Click on the plus"
  " button to generate a new prediction. It will direct you to a form in which "
  "you'll input the name and description of the prediction, as well as the "
  "layer over which you want the prediction to run.", "Once your prediction is "
  "created, you'll be taken to its individual page, where you can view and edit"
  " its information and watch the status of the running prediction job.", "At "
  "the bottom of the predictions page, you can view a map displaying the "
  "output of the prediction job once it's finished running in the form of a "
  "heatmap projected over the image of the corresponding layer. The toggle "
  "button will switch between the map view and a list of text-formatted "
  "prediction data."];

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
        Padding(
          padding: EdgeInsetsGeometry.symmetric(vertical: 16.0),
          child: Center(
            child: Text("Help",
              //dataSpec.fileName, 
              style: TextTheme.of(context).headlineLarge?.copyWith(
                fontWeight: FontWeight.bold
              )
            )
          ), //Icon
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Center(
            child: Text(
              "How to Use ArchaeoSight 2.0", 
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold, color: Colors.indigo
              )
            )
          )
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Center(
            child: Text(
              "Project Creation", 
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold, color: Colors.blue
              )
            )
          )
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: ClampingScrollPhysics(),
          itemCount: 4, 
          itemBuilder: (BuildContext context, int index) {
            return Card(
              child: SizedBox(
                child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: 
                    Row(
                        children: [
                          Flexible(
                            child: Image.asset(
                                "assets/${helpImages[index]}",
                                height: 400
                              ),
                            ),
                            Flexible(child:
                            Padding(
                              padding: EdgeInsets.all(20.0),
                              child: 
                              Column(children:[
                                Text("Step ${index + 1}",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold
                                      ),),
                                Text(helpText[index]),
                              ]),
                            ),
                          ),
                        ],
                      ),
                  ),
                ),
              );
          }
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Center(
            child: Text(
              "pXRF Data Upload", 
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold, color: Colors.blue
              )
            )
          )
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: ClampingScrollPhysics(),
          itemCount: 4, 
          itemBuilder: (BuildContext context, int index) {
            return Card(
              child: SizedBox(
                child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: 
                    Row(
                        children: [
                          Flexible(
                            child: Image.asset(
                                "assets/${helpImages[index + 4]}",
                                height: 400
                              ),
                            ),
                            Flexible(child:
                            Padding(
                              padding: EdgeInsets.all(20.0),
                              child: 
                              Column(children:[
                                Text("Step ${index + 1}",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold
                                      ),),
                                Text(helpText[index + 4]),
                              ]),
                            ),
                          ),
                        ],
                      ),
                  ),
                ),
              );
          }
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Center(
            child: Text(
              "Running Predictions", 
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold, color: Colors.blue
              )
            )
          )
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: ClampingScrollPhysics(),
          itemCount: 4, 
          itemBuilder: (BuildContext context, int index) {
            return Card(
              child: SizedBox(
                child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: 
                    Row(
                        children: [
                          Flexible(
                            child: Image.asset(
                                "assets/${helpImages[index + 8]}",
                                height: 400
                              ),
                            ),
                            Flexible(child:
                            Padding(
                              padding: EdgeInsets.all(20.0),
                              child: 
                              Column(children:[
                                Text("Step ${index + 1}",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold
                                      ),),
                                Text(helpText[index + 8]),
                              ]),
                            ),
                          ),
                        ],
                      ),
                  ),
                ),
              );
          }
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Center(
            child: Text(
              "Documentation", 
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold, color: Colors.indigo
              )
            )
          )
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Center(
            child: Text("Link to the user manual will go here once completed.")
            )
          )
      ]
    ));
  }
} 