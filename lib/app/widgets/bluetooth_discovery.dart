import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:multiparingbase/app/data/models/models.dart';
import 'package:permission_handler/permission_handler.dart';

class BluetoothDiscovery extends StatefulWidget {
  final Function(SensorType, BluetoothDevice)? onTap;

  const BluetoothDiscovery({
    super.key,
    this.onTap,
  });

  @override
  State<BluetoothDiscovery> createState() => _BluetoothDiscoveryState();
}

class _BluetoothDiscoveryState extends State<BluetoothDiscovery> {
  int stepperIndex = 0;
  SensorType? sensorTypeValue = SensorType.bwt901cl;
  BluetoothDevice? sensorValue;

  bool isDiscovering = true;
  final List<BluetoothDiscoveryResult> results = <BluetoothDiscoveryResult>[];
  StreamSubscription<BluetoothDiscoveryResult>? streamSubscription;

  @override
  void initState() {
    init();

    super.initState();
  }

  @override
  void dispose() {
    FlutterBluetoothSerial.instance.cancelDiscovery();

    super.dispose();
  }

  Future<void> init() async {
    await requestPermission();
    bluetoothDiscovery();
  }

  Future<void> requestPermission() async {
    await [
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.bluetoothAdvertise,
    ].request();
  }

  void update() {
    if (!mounted) return;
    setState(() {});
  }

  bluetoothDiscovery() {
    isDiscovering = true;
    update();

    streamSubscription = FlutterBluetoothSerial.instance.startDiscovery().listen((r) {
      final existingIndex = results.indexWhere((element) => element.device.address == r.device.address);
      if (existingIndex >= 0) {
        results[existingIndex] = r;
      } else if (r.device.name?.isNotEmpty ?? false) {
        results.add(r);
      }
      update();
    });

    streamSubscription?.onDone(() {
      isDiscovering = false;
      update();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 350,
      height: 500,
      child: Stepper(
        currentStep: stepperIndex,
        onStepCancel: () {
          if (stepperIndex > 0) {
            setState(() {
              stepperIndex -= 1;
            });
          }
        },
        onStepContinue: () {
          if (stepperIndex <= 0) {
            setState(() {
              stepperIndex += 1;
            });
          } else {
            if (sensorValue == null) return;
            widget.onTap?.call(sensorTypeValue!, sensorValue!);
          }
        },
        controlsBuilder: (BuildContext context, ControlsDetails details) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              ElevatedButton(
                onPressed: details.onStepContinue,
                child: Text(stepperIndex == 1 ? 'Connect' : 'Continue'),
              ),
              TextButton(
                onPressed: details.onStepCancel,
                child: const Text('Back'),
              ),
            ],
          );
        },
        steps: [
          Step(
            title: const Text('Select Sensor Type'),
            isActive: stepperIndex == 0,
            content: Container(
              alignment: Alignment.center,
              child: ListView(
                shrinkWrap: true,
                children: [
                  RadioListTile(
                    value: SensorType.bwt901cl,
                    groupValue: sensorTypeValue,
                    title: const Text('BWT901CL'),
                    onChanged: (value) => setState(() {
                      sensorTypeValue = value;
                    }),
                  ),
                  RadioListTile(
                    value: SensorType.strainGauge,
                    groupValue: sensorTypeValue,
                    title: const Text('Strain Gauge'),
                    onChanged: (value) => setState(() {
                      sensorTypeValue = value;
                    }),
                  ),
                ],
              ),
            ),
          ),
          Step(
            title: const Text('Select Sensor'),
            isActive: stepperIndex == 1,
            content: SizedBox(
              height: 280,
              child: ListView(
                children: [
                  ...results.map((r) => RadioListTile(
                        value: r.device,
                        groupValue: sensorValue,
                        title: Text('${r.device.name}'),
                        subtitle: Text(r.device.address),
                        onChanged: (value) => setState(() {
                          sensorValue = value;
                        }),
                      )),
                  if (isDiscovering) const Center(child: CircularProgressIndicator()),
                  if (!isDiscovering) TextButton(onPressed: bluetoothDiscovery, child: const Text('다시 검색'))
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
