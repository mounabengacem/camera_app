import 'package:flutter/material.dart';

import 'dart:io';

// A widget that displays the picture taken by the user.
class DisplayPictureScreen extends StatefulWidget {
  final Directory directory;
  
  const DisplayPictureScreen({Key key, this.directory}) : super(key: key);

  @override
  _DisplayPictureScreenState createState() => _DisplayPictureScreenState();
}

class _DisplayPictureScreenState extends State<DisplayPictureScreen> {
  
  @override
  Widget build(BuildContext context) {
  
    var imageList = widget.directory
        .listSync()
        .map((item) => item.path)
        .where((item) => item.endsWith(".jpg"))
        .toList(growable: false);
    return GridView.builder(
      itemCount: imageList.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3, childAspectRatio: 3.0 / 4.6),
      itemBuilder: (context, index) {
       
        return Card(
          shape:
       
                        RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
         
               child: Padding(
                 padding: new EdgeInsets.all(4.0),
                 
                 child: Image.file(
                   File(imageList[index]),
                   fit: BoxFit.cover,
                 ),
                 
               ),
          
        );
      },
    );
  }




}