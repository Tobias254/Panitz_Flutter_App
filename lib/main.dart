// ignore_for_file: avoid_print, unused_field, library_private_types_in_public_api, must_be_immutable, type_literal_in_constant_pattern, unnecessary_cast, non_constant_identifier_names

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

//Main
void main() => runApp(const MyApp());

class MyApp extends StatefulWidget {
  const MyApp({super.key}); //Konstruktor

  @override
  _MyAppState createState() => _MyAppState();
}

//Globale Variabeln
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

  //create Diagrams erzeugt dynamisch auf Knopfdruck Diagramme, die die Beschleunigung des Nutzer über einen Zeitraum von 10s anzeigt
  Widget createDiagrams(List<MyDiagram> finalList) {
    if (finalList.isEmpty) {
      return SliverToBoxAdapter(
        child: Center(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.all(Radius.circular(60)),
              color: Colors.red.withOpacity(0.2),
            ),
            margin: const EdgeInsets.all(30.0),
            height: 100,
            width: 300,
            child: Align(
              alignment: Alignment.center,
              child: Text(
                "Noch keine Einträge vorhanden",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black.withOpacity(0.5),
                ),
              ),
            ),
          ),
        ),
      );
    } else {
      return SliverList(
        delegate: SliverChildBuilderDelegate(
          (BuildContext context, int index) {
            List<FlSpot> currentSpotList = finalList[index].myDiagramList;
            return SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  minX: 0,
                  maxX: 10,
                  minY: -20,
                  maxY: 20,
                  borderData: FlBorderData(show: true),
                  gridData: FlGridData(
                    show: true,
                    getDrawingHorizontalLine: (value) {
                      return const FlLine(
                        color: Colors.blueGrey,
                        strokeWidth: 1,
                      );
                    },
                    getDrawingVerticalLine: (value) {
                      return const FlLine(
                        color: Colors.blueGrey,
                        strokeWidth: 0.2,
                      );
                    },
                  ),
                  titlesData: const FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 50,
                      ),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 50,
                      ),
                    ),

                    //rightTitles: AxisTitles(ShowTitles: false),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                        spots: currentSpotList,
                        isCurved: true,
                        barWidth: 4,
                        dotData: const FlDotData(show: false),
                        color: Colors.red,
                        belowBarData: BarAreaData(
                            show: true,
                            gradient: LinearGradient(
                              colors: [
                                Colors.red.withOpacity(0.7),
                                Colors.white60,
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ))),
                  ],
                ),
              ),
            );
          },
          childCount: finalList.length,
        ),
      );
    }
  }

  //Die AppBar erzeugt eine dynamische AppBar, die zu Beginn ein Rennrad zeigt und sich beim nach untenscrollen versteckt
  Widget appBar() {
    return SliverAppBar(
      shape: const ContinuousRectangleBorder(
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
            color: Colors.white.withOpacity(0.6),
            borderRadius: const BorderRadius.all(Radius.circular(30)),
          ),
          child: const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              'SprintS',
              style: TextStyle(
                color: Colors.red,
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
    );
  }

  //Diese Buttons dienen dazu die Kopfhörer mit der App zu verbinden und den Gerätenamen von E-Sense anzuzeigen
  Widget connectButtons() {
    return SliverList(
      delegate: SliverChildListDelegate([
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton(
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all<Color>(
                    Colors.red.withOpacity(0.8)),
                foregroundColor: MaterialStateProperty.all<Color>(Colors.white),
              ),
              onPressed: () {
                _connectToESense();
              },
              child: Text(_deviceStatus),
            ),
            ElevatedButton(
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all<Color>(
                    Colors.red.withOpacity(0.8)),
                foregroundColor: MaterialStateProperty.all<Color>(Colors.white),
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

  //Der Reset Button, löscht alle Elemente der Liste. So kann man z.B. alte Daten löschen und eine neue Fahrt beginnen.
  Widget resetButton() {
    return SliverList(
      delegate: SliverChildListDelegate(
        [
          Column(
            children: [
              SizedBox(
                  width: 200,
                  child: ElevatedButton(
                    onPressed: () {
                      // Hier kannst du deine gewünschte Funktion einfügen
                      print('Setze den Datensatz zurueck');
                      sprintS = <MyDiagram>[];
                      _pauseListenToSensorEvents();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent, // Hintergrundfarbe
                      foregroundColor: Colors.white, // Textfarbe
                      minimumSize: const Size(100.0, 50.0),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(26.0), // abgerundete Ecken
                      ),
                    ),
                    child: const Text(
                      'Reset',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ))
            ],
          )
        ],
      ),
    );
  }

  // Name des E-Sense Gerätes --> Wurde zu dem uns übergebenen Kopfhörer geändert
  // String eSenseName = 'eSense-0164'; - In unserem Fall heißt das Gerät "HB"
  static const String eSenseDeviceName = 'HB';
  ESenseManager eSenseManager = ESenseManager(eSenseDeviceName);

  @override
  void initState() {
    super.initState();
    _listenToESense();
  }

  Future<void> _askForPermissions() async {
    if (!(await Permission.bluetoothScan.request().isGranted &&
        await Permission.bluetoothConnect.request().isGranted)) {
      print(
          'WARNING - no permission to use Bluetooth granted. Cannot access eSense device.');
    }
    // for some strange reason, Android requires permission to location for Bluetooth to work.....?
    if (Platform.isAndroid) {
      if (!(await Permission.locationWhenInUse.request().isGranted)) {
        print(
            'WARNING - no permission to access location granted. Cannot access eSense device.');
      }
    }
  }

  Future<void> _listenToESense() async {
    await _askForPermissions();

    eSenseManager.connectionEvents.listen((event) {
      print('CONNECTION event: $event');

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
            _deviceStatus = 'found';
            break;
          case ConnectionType.device_not_found:
            _deviceStatus = 'no device found';
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

  //Spielt den Startsound für die Sensor-Daten-Erfassung: Sprint Beginnt
  void playStartSound() async {
    final player = AudioPlayer();
    player.play(AssetSource('audio/beep.mp3'));
  }

  //Spielt den EndSound für die Sensor-Daten-Erfassung: Sprint Abgeschlossen
  void playStopSound() async {
    final player = AudioPlayer();
    player.play(AssetSource('audio/achieve.mp3'));
  }

  //Fügt der Liste ein neues Element hinzu, sobald der Sprint abgeschlossen ist.
  void addListElement(List<MyDiagram> oldList) {
    int listLength = oldList.length;
    MyDiagram temp = MyDiagram();
    temp.myDiagramName = 'Sprint $listLength';
    print(temp.myDiagramName);
    _startListenToSensorEvents();
    temp.myDiagramList = getSensorDataForList(temp).myDiagramList;
  }

  //Dient dazu die Sensordaten innerhalb eines Intervalls von 10-Sekunden zu sammeln
  MyDiagram getSensorDataForList(MyDiagram uebergabe) {
    double Seconds = 0.0;
    double currentAccel = 0;
    Timer.periodic(const Duration(milliseconds: 200), (Timer timer) {
      currentAccel = _eventAccel == 0 ? 0 : _eventAccel / 1000;
      uebergabe.myDiagramList.add(FlSpot(Seconds, currentAccel));
      Seconds += 0.2;
      print('Beschleunigung: $currentAccel');
      print(Seconds);
      //Wenn 10 Sekunden vorbei sind, soll der Timer abbrechen.
      if (Seconds >= 9.8) {
        timer.cancel();
        sprintS.add(uebergabe);
        print("Länge: ${sprintS.length}");
        print("Länge eines Elements: ${sprintS[0].myDiagramList.length}");
        print('Anzahl Diagramme: ${sprintS.length}');
        print('Sensorwerte: $_event');
        playStopSound();
        _pauseListenToSensorEvents();
      }
    });

    return uebergabe;
  }

  //Solange der PlayButton auf play ist, solange soll die Funktion createDiagramEntry aufgerufen werden
  void whilePlay() async {
    if (_myPlayWidget.getWidgetIsPlay()) {
      print('Fahrradtour begonnen');
      playStartSound();
      //Der Signalton geht 4 Sekunden lang. Erst danach sollen die Werte gemessen werden.
      Future.delayed(const Duration(seconds: 4), () {
        addListElement(sprintS);
      });
    } else {
      print('Beginne zuerst deine Fahrradtour!');
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
            if ((event as ButtonEventChanged).pressed) {
              whilePlay();
            }
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

    subscription = eSenseManager.sensorEvents.listen((event) {
      //Unterhalb ist eine Kontrolle, ob alle Sensorwerte ausgegeben werden
      //print('SENSOR event: $event');
      setState(() {
        _event = event.toString();
        _eventAccel = event.accel![1].toDouble();
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

  @override
  //Das ist der Widget Tree: So ist die App von oben nach unten aufgebaut
  Widget build(BuildContext context) {
    //Material App ist das Material Design --> Design von Google (Quasi default)
    return MaterialApp(
      home: Scaffold(
        body: CustomScrollView(
          slivers: <Widget>[
            //Sliver App Bar, um das Bild einzubinden
            appBar(),
            //erzeugt 2 Buttons um die Kopfhörer mit der App zu verbinden
            connectButtons(),
            //erzeugt einen PlayButton um eine Fahrradtour zu beginnen
            _myPlayWidget,
            //Erzeugt eine dynamische Liste mit Diagrammen, die die Beschleunigungswerte über einen Zeitraum von 10s darstellen
            createDiagrams(sprintS),
            //setzt die Liste zurück um eine neue Tour zu beginnen
            resetButton(),
          ],
        ),
      ),
    );
  }
}

//Ein Diagramm besteht immer aus einem Namen und einer Liste mit FLSpots
class MyDiagram {
  String myDiagramName = '';
  //List<MyDiagramList> myDiagramList = [];
  List<FlSpot> myDiagramList = [];
}

//Das ist der animierte Play-Button
class PlayWidget extends StatefulWidget {
  //final bool _isplay = false;
  bool widgetIsPlay = false;
  PlayWidget({super.key});

  @override
  State<StatefulWidget> createState() => PlayWidgetState();

  bool getWidgetIsPlay() {
    return widgetIsPlay;
  }
}

class PlayWidgetState extends State<PlayWidget> with TickerProviderStateMixin {
  bool _isplay = false;

  late AnimationController _controller;

  bool getIsPlay() {
    return _isplay;
  }

  @override
  void initState() {
    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    super.initState();
  }

  @override
  void dispose() {
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
            color: Colors.red,
            progress: _controller,
            size: 100,
          ),
        ),
      ),
    );
  }
}
