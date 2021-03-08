
import 'dart:async';
import 'dart:io';


import 'package:App_PHOTO_Succ/display_pictures.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

class CameraApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: TakePictureScreen(),
    );
  }
}

List<CameraDescription> _cameras = [];

Future<void> main() async {
  // Fetch the available cameras before initializing the app.
  try {
    WidgetsFlutterBinding.ensureInitialized();
    _cameras = await availableCameras();
  } on CameraException catch (e) {
    logError(e.code, e.description);
  }
  runApp(CameraApp());
}


// A screen that allows users to take a picture using a given camera.
class TakePictureScreen extends StatefulWidget {


  const TakePictureScreen({
    Key key,
  
  }) : super(key: key);

  @override
  TakePictureScreenState createState() => TakePictureScreenState();
}


void logError(String code, String message) =>
    print('Error: $code\nError Message: $message');

class TakePictureScreenState extends State<TakePictureScreen> with WidgetsBindingObserver, TickerProviderStateMixin {
  CameraController _controller;
  Future<void> _initializeControllerFuture;
  Directory dir;
  String lastimage;


  double _minAvailableExposureOffset = 0.0;
  double _maxAvailableExposureOffset = 0.0;
  double _currentExposureOffset = 0.0;
  AnimationController _flashModeControlRowAnimationController;
  Animation<double> _flashModeControlRowAnimation;
  AnimationController _exposureModeControlRowAnimationController;
  Animation<double> _exposureModeControlRowAnimation;
  AnimationController _focusModeControlRowAnimationController;

  double _minAvailableZoom;
  double _maxAvailableZoom;
  double _currentScale = 1.0;
  double _baseScale = 1.0;
  
  // Counting pointers (number of user fingers on screen)
  int _pointers = 0;

  

 final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

@override
void initState() {
   WidgetsBinding.instance.addObserver(this);
    _flashModeControlRowAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _flashModeControlRowAnimation = CurvedAnimation(
      parent: _flashModeControlRowAnimationController,
      curve: Curves.easeInCubic,
    );
    _exposureModeControlRowAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _exposureModeControlRowAnimation = CurvedAnimation(
      parent: _exposureModeControlRowAnimationController,
      curve: Curves.easeInCubic,
    );
    _focusModeControlRowAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
  _initCamera();
  super.initState();
}

@override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // App state changed before we got the chance to initialize.
    if (_controller == null || !_controller.value.isInitialized) {
      return;
    }
    if (state == AppLifecycleState.inactive) {
      _controller?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      if (_controller != null) {
        onNewCameraSelected(_controller.description);
      }
    }
  }
  void onNewCameraSelected(CameraDescription cameraDescription) async {
    if (_controller != null) {
      await _controller.dispose();
    }
    _controller = CameraController(
      cameraDescription,
      ResolutionPreset.medium,
     
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    // If the controller is updated then update the UI.
    _controller.addListener(() {
      if (mounted) setState(() {});
      if (_controller.value.hasError) {
        showInSnackBar('Camera error ${_controller.value.errorDescription}');
      }
    });

    try {
      await _controller.initialize();
      await Future.wait([
        _controller
            .getMinExposureOffset()
            .then((value) => _minAvailableExposureOffset = value),
        _controller
            .getMaxExposureOffset()
            .then((value) => _maxAvailableExposureOffset = value),
        _controller.getMaxZoomLevel().then((value) => _maxAvailableZoom = value),
        _controller.getMinZoomLevel().then((value) => _minAvailableZoom = value),
      ]);
    } on CameraException catch (e) {
      _showCameraException(e);
    }

    if (mounted) {
      setState(() {});
    }
  }
Future<void> _initCamera() async {
  _cameras = await availableCameras();
    _controller = CameraController(_cameras[0], ResolutionPreset.medium);
    _controller.initialize().then((_) {
      if (!mounted) {
        return;
      }
      setState(() {});
    });
}

@override
void dispose() {
  _controller?.dispose();
  WidgetsBinding.instance.removeObserver(this);
    _flashModeControlRowAnimationController.dispose();
    _exposureModeControlRowAnimationController.dispose();
  super.dispose();
}


  @override
  Widget build(BuildContext context) {

   if (_controller != null) {
      if (!_controller.value.isInitialized) {
        return Container();
      }
    } else {
      return const Center(
        child: SizedBox(
          width: 32,
          height: 32,
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (!_controller.value.isInitialized) {
      return Container();
    }
    
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(title: Text('Take a picture')),
      
      body: Container(
      child:Stack(
            children: <Widget>[
        
    
      Container(child:FutureBuilder<void>(
   
        builder: (context, snapshot) {
   
            // If the Future is complete, display the preview.
           return _cameraPreviewWidget();
          
    
        }
      )
      ,),
    
                      
     
              Container(
          alignment:Alignment.bottomCenter,
          padding: EdgeInsets.all(16.0),
          child:ClipRRect(
           child: FloatingActionButton(
             highlightElevation:100 ,
             elevation: 50,
                            
            backgroundColor: Colors.blueGrey,
                            
                            
             child: Icon(Icons.camera_alt),
          // Provide an onPressed callback.
              onPressed: () async {
             
             Directory tempDir = await getTemporaryDirectory();
            // Take the Picture in a try / catch block. If anything goes wrong,
            // catch the error.
            try {
              // Ensure that the camera is initialized.
              await _initializeControllerFuture;
         
    
              // Attempt to take a picture and get the file `image`
              // where it was saved.
              final image =await _controller.takePicture();
             
    
               print(image);
               print(image.path);
               print(tempDir);
               print(tempDir.path);
               setState(() {
                 dir=tempDir;
                 lastimage=image.path;
                
               });
              } catch (e) {
              // If an error occurs, log the error to the console.
              print(e);
            }}
            ),),),
       
                 Container(
                   alignment: Alignment.bottomLeft,
                    padding: EdgeInsets.all(20.0),
                    
                  
                   child: InkWell(child: getimage(),
                            onTap:() {
                              Navigator.push(
                                context, 
                                MaterialPageRoute(builder: (context)=>DisplayPictureScreen(directory: dir)));
                            },
                            highlightColor:Colors.white ,),
                 ),
                 _modeControlRowWidget(),
                 

      ]) 
      ,
          ),
         
          ); 
      }
  
Widget getimage(){
 
        if (lastimage == null) {return Image(image:AssetImage("assets/placeholder.jpg"),width: 40,height: 40 ,fit: BoxFit.fill,);}
        else{
        
       
          return Image.file(File(lastimage),width: 40,height: 40,fit: BoxFit.fill);
           
     }          
}
      Future<void> _onCameraSwitch() async {
  final CameraDescription cameraDescription =
      (_controller.description == _cameras[0]) ? _cameras[1] : _cameras[0];
  if (_controller != null) {
    await _controller.dispose();
  }
  _controller = CameraController(cameraDescription, ResolutionPreset.medium);
  _controller.addListener(() {
    if (mounted) setState(() {});
    if (_controller.value.hasError) {
      showInSnackBar('Camera error ${_controller.value.errorDescription}');
    }
  });

  try {
    await _controller.initialize();
  } on CameraException catch (e) {
    _showCameraException(e);
  }

  if (mounted) {
    setState(() {});
  }
}
  void _showCameraException(CameraException e) {
    logError(e.code, e.description);
    showInSnackBar('Error: ${e.code}\n${e.description}');
  }

  void showInSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
  void logError(String code, String message) =>
      print('Error: $code\nError Message: $message');





 /// Display a bar with buttons to change the flash and exposure modes
  Widget _modeControlRowWidget() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          mainAxisSize: MainAxisSize.max,
          children: <Widget>[
            IconButton(
        icon: Icon(
          Icons.switch_camera,
          color: Colors.blue,
        ),
        onPressed: _onCameraSwitch,
      ),
            IconButton(
              icon: Icon(Icons.flash_on),
              color: Colors.blue,
              onPressed: _controller != null ? onFlashModeButtonPressed : null,
            ),
            IconButton(
              icon: Icon(Icons.exposure),
              color: Colors.blue,
              onPressed:
                  _controller != null ? onExposureModeButtonPressed : null,
            ),
           
          ],
        ),
        _flashModeControlRowWidget(),
        _exposureModeControlRowWidget(),
        
      ],
    );
  }

  Widget _flashModeControlRowWidget() {
    return SizeTransition(
      sizeFactor: _flashModeControlRowAnimation,
      child: ClipRect(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          mainAxisSize: MainAxisSize.max,
          children: [
            IconButton(
              icon: Icon(Icons.flash_off),
              color: _controller?.value?.flashMode == FlashMode.off
                  ? Colors.orange
                  : Colors.blue,
              onPressed: _controller != null
                  ? () => onSetFlashModeButtonPressed(FlashMode.off)
                  : null,
            ),
            IconButton(
              icon: Icon(Icons.flash_auto),
              color: _controller?.value?.flashMode == FlashMode.auto
                  ? Colors.orange
                  : Colors.blue,
              onPressed: _controller != null
                  ? () => onSetFlashModeButtonPressed(FlashMode.auto)
                  : null,
            ),
            IconButton(
              icon: Icon(Icons.flash_on),
              color: _controller?.value?.flashMode == FlashMode.always
                  ? Colors.orange
                  : Colors.blue,
              onPressed: _controller != null
                  ? () => onSetFlashModeButtonPressed(FlashMode.always)
                  : null,
            ),
            IconButton(
              icon: Icon(Icons.highlight),
              color: _controller?.value?.flashMode == FlashMode.torch
                  ? Colors.orange
                  : Colors.blue,
              onPressed: _controller != null
                  ? () => onSetFlashModeButtonPressed(FlashMode.torch)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _exposureModeControlRowWidget() {
    

    return SizeTransition(
      sizeFactor: _exposureModeControlRowAnimation,
      child: ClipRect(
        child: Container(
          child: Column(
            children: [
              
              Center(
                child: Text("Brightness"),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                mainAxisSize: MainAxisSize.max,
                children: [
                  Text(_minAvailableExposureOffset.toString()),
                  Slider(
                    value: _currentExposureOffset,
                    min: _minAvailableExposureOffset,
                    max: _maxAvailableExposureOffset,
                    label: _currentExposureOffset.toString(),
                    onChanged: _minAvailableExposureOffset ==
                            _maxAvailableExposureOffset
                        ? null
                        : setExposureOffset,
                  ),
                  Text(_maxAvailableExposureOffset.toString()),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }



  void onFlashModeButtonPressed() {
    if (_flashModeControlRowAnimationController.value == 1) {
      _flashModeControlRowAnimationController.reverse();
    } else {
      _flashModeControlRowAnimationController.forward();
      _exposureModeControlRowAnimationController.reverse();
      _focusModeControlRowAnimationController.reverse();
    }
  }

  void onExposureModeButtonPressed() {
    if (_exposureModeControlRowAnimationController.value == 1) {
      _exposureModeControlRowAnimationController.reverse();
    } else {
      _exposureModeControlRowAnimationController.forward();
      _flashModeControlRowAnimationController.reverse();
      _focusModeControlRowAnimationController.reverse();
    }
  }

  void onFocusModeButtonPressed() {
    if (_focusModeControlRowAnimationController.value == 1) {
      _focusModeControlRowAnimationController.reverse();
    } else {
      _focusModeControlRowAnimationController.forward();
      _flashModeControlRowAnimationController.reverse();
      _exposureModeControlRowAnimationController.reverse();
    }
  }

  

  void onCaptureOrientationLockButtonPressed() async {
    if (_controller != null) {
      if (_controller.value.isCaptureOrientationLocked) {
        await _controller.unlockCaptureOrientation();
        showInSnackBar('Capture orientation unlocked');
      } else {
        await _controller.lockCaptureOrientation();
        showInSnackBar(
            'Capture orientation locked to ${_controller.value.lockedCaptureOrientation.toString().split('.').last}');
      }
    }
  }

  void onSetFlashModeButtonPressed(FlashMode mode) {
    setFlashMode(mode).then((_) {
      if (mounted) setState(() {});
      showInSnackBar('Flash mode set to ${mode.toString().split('.').last}');
    });
  }

  void onSetExposureModeButtonPressed(ExposureMode mode) {
    setExposureMode(mode).then((_) {
      if (mounted) setState(() {});
      showInSnackBar('Exposure mode set to ${mode.toString().split('.').last}');
    });
  }

  void onSetFocusModeButtonPressed(FocusMode mode) {
    setFocusMode(mode).then((_) {
      if (mounted) setState(() {});
      showInSnackBar('Focus mode set to ${mode.toString().split('.').last}');
    });
  }

  Future<void> setFlashMode(FlashMode mode) async {
    try {
      await _controller.setFlashMode(mode);
    } on CameraException catch (e) {
      _showCameraException(e);
      rethrow;
    }
  }

  Future<void> setExposureMode(ExposureMode mode) async {
    try {
      await _controller.setExposureMode(mode);
    } on CameraException catch (e) {
      _showCameraException(e);
      rethrow;
    }
  }

  Future<void> setExposureOffset(double offset) async {
    setState(() {
      _currentExposureOffset = offset;
    });
    try {
      offset = await _controller.setExposureOffset(offset);
    } on CameraException catch (e) {
      _showCameraException(e);
      rethrow;
    }
  }

 Future<void> setFocusMode(FocusMode mode) async {
    try {
      await _controller.setFocusMode(mode);
    } on CameraException catch (e) {
      _showCameraException(e);
      rethrow;
    }
  }
  

  void onViewFinderTap(TapDownDetails details, BoxConstraints constraints) {
    final offset = Offset(
      details.localPosition.dx / constraints.maxWidth,
      details.localPosition.dy / constraints.maxHeight,
    );
    _controller.setExposurePoint(offset);
    _controller.setFocusPoint(offset);
  }
 

 


 Widget _cameraPreviewWidget() { 
      return Listener(
        onPointerDown: (_) => _pointers++,
        onPointerUp: (_) => _pointers--,
        child: CameraPreview(
        
          _controller,
          child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
            return GestureDetector(
              
              behavior: HitTestBehavior.opaque,
              onScaleStart: _handleScaleStart,
              onScaleUpdate: _handleScaleUpdate,
              onTapDown: (details) => onViewFinderTap(details, constraints),
            );
          }),
        ),
      );
    
  }

  void _handleScaleStart(ScaleStartDetails details) {
    _baseScale = _currentScale;
  }

  Future<void> _handleScaleUpdate(ScaleUpdateDetails details) async {
    // When there are not exactly two fingers on screen don't scale
    if (_pointers != 2) {
      return;
    }

    _currentScale = (_baseScale * details.scale)
        .clamp(_minAvailableZoom, _maxAvailableZoom);

    await _controller.setZoomLevel(_currentScale);
  }


}

