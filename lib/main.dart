import 'dart:io';

import 'package:flutter/material.dart';
import 'dart:async';
//Esense Library
import 'package:esense_flutter/esense.dart';
import 'package:permission_handler/permission_handler.dart';
//Audioplayer für Signaltöne
import 'package:audioplayers/audioplayers.dart';
//Diagramme
import 'package:fl_chart/fl_chart.dart';
//Sliver Bar Chart
import 'package:sliver_bar_chart/sliver_bar_chart.dart';

//Sliver Bar Chart

void main() => runApp(const MyApp());

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key); //Konstruktor

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _deviceName = 'Unknown';
  double _voltage = -1;
  String _deviceStatus = '';
  bool sampling = false;
  String _event = '';
  double _eventAccel = 0.0;
  String _button = 'not pressed';
  bool connected = false;
  // Erstelle den Play Button als Widget
  final PlayWidget _myPlayWidget = PlayWidget();
  //Erstelle eine Diagramm-Liste
  List<MyDiagram> sprintS = <MyDiagram>[];


  // Eigene Widgets
  // Test
  Widget ifPressed(){
    return SliverToBoxAdapter(
      child: Text('eSense Button Event: \t$_button')
    );
  }

  Widget Dumb(){
    return SliverToBoxAdapter(
      child: Text('Du hast den Knopf gedrückt!')
    );
  }

  /*Widget createDiagrams(List<MyDiagram> finalList){
    return SliverList(
      delegate: SliverChildBuilderDelegate(
          (BuildContext context, int index){
            return SliverToBoxAdapter(
              child: LineChart(
                LineChartData(
                  lineBarsData: [
                    LineChartBarData(
                      spots: finalList[0].myDiagramList,
                      isCurved: true,
                      color: Colors.blue,
                      dotData: FlDotData(show: false),
                      belowBarData: BarAreaData(show: false),
                    ),
                  ],
                ),
              ),
            );
          }
      ),
    );
  }*/
  Widget test(List<MyDiagram> finalList){
    if(finalList.length==0){
      return SliverToBoxAdapter(
        child: Text(
          'Keine Einträge vorhanden'
        )
      );
    } else{
      return SliverToBoxAdapter(
        child: Text(
          'Jetzt hab ich Kinder: ' + finalList[0].myDiagramList.length.toString(),
        )
      );
    }
  }
  Widget createDiagrams(List<MyDiagram> finalList) {
    return
      SliverList(
      delegate: SliverChildBuilderDelegate(
          (BuildContext context, int index){
            if (finalList.isEmpty){
              return const SliverToBoxAdapter(
                child: Center(
                  child: Text(
                    'Keine Einträge vorhanden'
                  ),
                ),
              );
            } else {
              List<FlSpot> currentSpotList = finalList[index].myDiagramList;
              return SliverToBoxAdapter(
                child: LineChart(
                LineChartData(
                  lineBarsData: [
                    LineChartBarData(
                      spots: currentSpotList,
                      isCurved: true,
                    ),
                  ],
                ),
              ),
              );
            }
          },
        childCount: finalList.isEmpty ? 1: finalList.length,
      ),
    );
  }


  Widget connectButtons(){
    return SliverList(
      delegate: SliverChildListDelegate([
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton(
              onPressed: () {
                _connectToESense();
              },
              child: Text(_deviceStatus),
            ),
            ElevatedButton(
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all<Color>(Colors.black),
              ),
              onPressed: () {
                // Aktion für den zweiten Button
              },
              child: Text(_deviceName),
            ),
          ],
        ),
      ]),
    );
  }

  // the name of the eSense device to connect to -- change this to your own device.
  // String eSenseName = 'eSense-0164';
  static const String eSenseDeviceName = 'HB';
  ESenseManager eSenseManager = ESenseManager(eSenseDeviceName);

  @override
  void initState() {
    super.initState();
    _listenToESense();
  }

  Future<void> _askForPermissions() async {
    if (!(await Permission.bluetoothScan
        .request()
        .isGranted &&
        await Permission.bluetoothConnect
            .request()
            .isGranted)) {
      print(
          'WARNING - no permission to use Bluetooth granted. Cannot access eSense device.');
    }
    // for some strange reason, Android requires permission to location for Bluetooth to work.....?
    if (Platform.isAndroid) {
      if (!(await Permission.locationWhenInUse
          .request()
          .isGranted)) {
        print(
            'WARNING - no permission to access location granted. Cannot access eSense device.');
      }
    }
  }

  Future<void> _listenToESense() async {
    await _askForPermissions();

    // if you want to get the connection events when connecting,
    // set up the listener BEFORE connecting...
    eSenseManager.connectionEvents.listen((event) {
      print('CONNECTION event: $event');

      // when we're connected to the eSense device, we can start listening to events from it
      if (event.type == ConnectionType.connected) _listenToESenseEvents();

      setState(() {
        connected = false;
        switch (event.type) {
          case ConnectionType.connected:
            _deviceStatus = 'connected';
            connected = true;
            break;
          case ConnectionType.unknown:
            _deviceStatus = 'unknown';
            break;
          case ConnectionType.disconnected:
            _deviceStatus = 'disconnected';
            sampling = false;
            break;
          case ConnectionType.device_found:
            _deviceStatus = 'device_found';
            break;
          case ConnectionType.device_not_found:
            _deviceStatus = 'device_not_found';
            break;
        }
      });
    });
  }

  Future<void> _connectToESense() async {
    if (!connected) {
      print('Trying to connect to eSense device...');
      connected = await eSenseManager.connect();

      setState(() {
        _deviceStatus = connected ? 'connecting...' : 'connection failed';
      });
    }
  }

  List<double> _handleAccel(SensorEvent event){
    if(event.accel != null){
      return [
      event.accel![0].toDouble(),
      event.accel![1].toDouble(),
      event.accel![2].toDouble(),
    ];
    } else{
      return [0.0, 0.0, 0.0];
    }

  }
  //Spielt den Startsound für die Sensor-Daten-Erfassung
  void playStartSound() async{
    final player = AudioPlayer();
    player.play(AssetSource('audio/beep.mp3'));
  }

  void playStopSound() async{
    final player = AudioPlayer();
    player.play(AssetSource('audio/achieve.mp3'));
  }

  void addListElement(List<MyDiagram> oldList) async{
    bool listInit = false;
    int listLength = oldList.length;
    MyDiagram temp = MyDiagram();
    temp.myDiagramName = 'Sprint ' + listLength.toString();
    print(temp.myDiagramName);
    _startListenToSensorEvents();
    temp.myDiagramList = getSensorDataForList(temp).myDiagramList;
    sprintS.add(temp);
    print('Anzahl Diagramme: ' + sprintS.length.toString());
    print('Sensorwerte: ' + _event);
    Future.delayed(Duration(seconds: 11), (){
      listInit = true;
      setState(() {
        sprintS.length;
      });
      playStopSound();
      _pauseListenToSensorEvents();
    });
    // _pauseListenToSensorEvents();
  }

  MyDiagram getSensorDataForList(MyDiagram uebergabe){
    //List<FlSpot> tempList = uebergabe.myDiagramList;
    //FlSpot temp;
    double Seconds = 0;
    double currentAccel;
    Timer.periodic(Duration(milliseconds: 200), (Timer timer){
      currentAccel = _eventAccel;
      uebergabe.myDiagramList.add(FlSpot(Seconds, currentAccel));
      Seconds += 0.2;
      print('Beschleunigung: ' + currentAccel.toString());
      print(Seconds);
      //Wenn 10 Sekunden vorbei sind, soll der Timer abbrechen.
      if (Seconds >= 9.8){
        timer.cancel();
      }
    });

    return uebergabe;

  }
  //Solange der PlayButton auf play ist, solange soll die Funktion createDiagramEntry aufgerufen werden
  void whilePlay() async{
    //print('in here');
    if(_myPlayWidget.getWidgetIsPlay()){
      //print('widget isplay: ' + _myPlayWidget.getWidgetIsPlay().toString());
      //_createDiagramEntry();
      print('Fahrradtour begonnen');
      playStartSound();
      //Der Signalton geht 4 Sekunden lang. Erst danach sollen die Werte gemessen werden.
      Future.delayed(Duration(seconds: 4), (){
        addListElement(sprintS);
      });
    } else {
      print('Beginne zuerst deine Fahrradtour!');
    }
  }
  void _createDiagramEntry() async {
    //MyDiagramList Hubert;
    if (_deviceStatus=='connected'&& _myPlayWidget.getWidgetIsPlay()==true){
      print('tracking...');
    }
  }
  void _listenToESenseEvents() async {
    eSenseManager.eSenseEvents.listen((event) {
      print('ESENSE event: $event');

      setState(() {
        switch (event.runtimeType) {
          case DeviceNameRead:
            _deviceName = (event as DeviceNameRead).deviceName ?? 'Unknown';
            break;
          case BatteryRead:
            _voltage = (event as BatteryRead).voltage ?? -1;
            break;
          case ButtonEventChanged:
            _button = (event as ButtonEventChanged).pressed
                ? 'pressed'
                : 'not pressed';
            if((event as ButtonEventChanged).pressed) {
              whilePlay();
            }
            break;
          case AccelerometerOffsetRead:
          // TODO
            break;
          case AdvertisementAndConnectionIntervalRead:
          // TODO
            break;
          case SensorConfigRead:
          // TODO
            break;
        }
      });
    });

    _getESenseProperties();
  }

  void _getESenseProperties() async {
    // get the battery level every 10 secs
    Timer.periodic(
      const Duration(seconds: 10),
          (timer) async =>
      (connected) ? await eSenseManager.getBatteryVoltage() : null,
    );

    // wait 2, 3, 4, 5, ... secs before getting the name, offset, etc.
    // it seems like the eSense BTLE interface does NOT like to get called
    // several times in a row -- hence, delays are added in the following calls
    Timer(const Duration(seconds: 2),
            () async => await eSenseManager.getDeviceName());
    Timer(const Duration(seconds: 3),
            () async => await eSenseManager.getAccelerometerOffset());
    Timer(
        const Duration(seconds: 4),
            () async =>
        await eSenseManager.getAdvertisementAndConnectionInterval());
    Timer(const Duration(seconds: 15),
            () async => await eSenseManager.getSensorConfig());
  }

  StreamSubscription? subscription;

  void _startListenToSensorEvents() async {
    // // any changes to the sampling frequency must be done BEFORE listening to sensor events
    // print('setting sampling frequency...');
    // await eSenseManager.setSamplingRate(10);

    // subscribe to sensor event from the eSense device
    subscription = eSenseManager.sensorEvents.listen((event) {
      //Unterhalb ist eine Kontrolle, ob alle Sensorwerte ausgegeben werden
      print('SENSOR event: $event');
      setState(() {
        _event = event.toString();
        _eventAccel = event.accel![0].toDouble();
      });
    });
    setState(() {
      sampling = true;
    });
  }

  void _pauseListenToSensorEvents() async {
    subscription?.cancel();
    setState(() {
      sampling = false;
    });
  }

  @override
  void dispose() {
    _pauseListenToSensorEvents();
    eSenseManager.disconnect();
    super.dispose();
  }

/*
  @override
  Widget build(BuildContext context) {
    //Material App ist das Material Design --> Design von Google (Quasi default)
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('SprintS'),
          centerTitle: true,
        ),
        body: Align(
          alignment: Alignment.topLeft,
          child:
            ListView(
            children: <Widget> [
              Text('eSense Device Status: \t$_deviceStatus'),
              Text('eSense Device Name: \t$_deviceName'),
              Text('eSense Battery Level: \t$_voltage'),
              Text('eSense Button Event: \t$_button'),
              const Text(''),
              const Text(''),
              const Text(''),
              const Text(''),
              Text(_event),
              const Text(''),
              const Text(''),
              Container(
                height: 100,
                width: 200,
                decoration:
                BoxDecoration(borderRadius: BorderRadius.circular(10), color: Colors.amber),
                padding: EdgeInsets.all(8.0),
                child: TextButton.icon(
                  onPressed: _connectToESense,
                  icon: const Icon(Icons.login_outlined, size: 48),
                  label: const Text(
                    'CONNECT....',
                    style: TextStyle(fontSize: 48),
                  ),
                ),
              ),
            ],
          ),

        ),

        floatingActionButton: FloatingActionButton(
          // a floating button that starts/stops listening to sensor events.
          // is disabled until we're connected to the device.
          onPressed: (!eSenseManager.connected)
              ? null
              : (!sampling)
              ? _startListenToSensorEvents
              : _pauseListenToSensorEvents,
          tooltip: 'Listen to eSense sensors',
          child: (!sampling)
              ? const Icon(Icons.play_arrow)
              : const Icon(Icons.pause),
        ),

      ),
    );
  }
}
 */
/*
  @override
  Widget build(BuildContext context) {
    //Material App ist das Material Design --> Design von Google (Quasi default)
    return MaterialApp(
        home: Scaffold(
            body: CustomScrollView(
                slivers: <Widget>[
                  SliverAppBar(
                    shape: ContinuousRectangleBorder(
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(30),
                        bottomRight: Radius.circular(30),
        ),
                    ),

                    pinned: true,
                    floating: true,
                    expandedHeight: 160.0,
                      flexibleSpace: FlexibleSpaceBar(
                         title: Container(
                           decoration: BoxDecoration(
                           color: Colors.white.withOpacity(0.5),
                           borderRadius: BorderRadius.all(Radius.circular(30)),
    ),
                           child: Padding(
                             padding: const EdgeInsets.all(8.0),
                             child: Text(
                               'SprintS',
                               style: TextStyle(
                                 color: Colors.black,
                                 fontWeight: FontWeight.bold,
                                 letterSpacing: 2,
                               ),
                             ),
                           ),
                         ),
                          centerTitle: true,
                          background: Image.asset(
                          'images/bike.jpg',
                          fit: BoxFit.cover,
                      ),
                      ),




                  ),
                ],
            ),
        ),
    );
  }
}*/

  @override
  Widget build(BuildContext context) {
    //Material App ist das Material Design --> Design von Google (Quasi default)
    return MaterialApp(
      home: Scaffold(
        body: CustomScrollView(
          slivers: <Widget>[
            SliverAppBar(
              shape: ContinuousRectangleBorder(
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(60),
                  bottomRight: Radius.circular(60),
                ),
              ),
              pinned: true,
              floating: true,
              expandedHeight: 160.0,
              flexibleSpace: FlexibleSpaceBar(
                title: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.5),
                    borderRadius: BorderRadius.all(Radius.circular(30)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      'SprintS',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ),
                centerTitle: true,
                background: Image.asset(
                  'images/bike.jpg',
                  fit: BoxFit.cover,
                ),
              ),
            ),
            connectButtons(),
            _myPlayWidget,
            test(sprintS),
            //createDiagrams(sprintS),
            /*LineChart(
                LineChartData(
                  lineBarsData: [
                    LineChartBarData(
                      spots: testDiagram,
                      isCurved: true,
                    ),
                  ],
                ),
              ),*/
            ifPressed(),
            // Hier kannst du weitere Sliver-Widgets hinzufügen, wenn benötigt
          ],
        ),
      ),
    );
  }
}

// Eigene Klassen
/*
class PlayWidget extends StatefulWidget {
  const PlayWidget({Key? key}) : super(key: key);

  @override
  State<PlayWidget> createState() => _PlayWidgetState();
}

class _PlayWidgetState extends State<PlayWidget> with TickerProviderStateMixin{
  bool _isplay = false;
  late AnimationController _controller;
  @override
  void initState(){
    _controller= AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    super.initState();
  }
  @override
  void dispose(){
    _controller.dispose();
        super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
        child: GestureDetector(
        onTap: () {
          if (_isplay == false) {
            _controller.forward();
            _isplay = true;
          } else {
            _controller.reverse();
            _isplay = false;
          }
        },
          child:AnimatedIcon(
          icon: AnimatedIcons.play_pause,
          progress: _controller,
          size:100,
        )
      )
    );
  }
}
*/
/*
class MyDiagramList{
  final double x;
  final double y;
  MyDiagramList(this.x, this.y);
}*/

class MyDiagram{
  String myDiagramName ='';
  //List<MyDiagramList> myDiagramList = [];
  List<FlSpot> myDiagramList = [];
}

class PlayWidget extends StatefulWidget {
  //final bool _isplay = false;
  bool widgetIsPlay = false;
  PlayWidget({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => PlayWidgetState();
  //
  // bool getIsPlay() {
    // return _isplay;
  // }

  bool getWidgetIsPlay() {
    return widgetIsPlay;
  }
}

class PlayWidgetState extends State<PlayWidget> with TickerProviderStateMixin{
  bool _isplay = false;
  late AnimationController _controller;

  bool getIsPlay(){
    return _isplay;
  }

  @override
  void initState(){
    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    super.initState();
  }

  @override
  void dispose(){
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Center(
        child: GestureDetector(
          onTap: () {
            if (_isplay == false) {
              print('state isplay is false');
              widget.widgetIsPlay = true;
              _controller.forward();
              _isplay = true;
            } else {
              print('state isplay is true');
              widget.widgetIsPlay = false;
              _controller.reverse();
              _isplay = false;
            }
          },
          child: AnimatedIcon(
            icon: AnimatedIcons.play_pause,
            progress: _controller,
            size: 100,
          ),
        ),
      ),
    );
  }
}
