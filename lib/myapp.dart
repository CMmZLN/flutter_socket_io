import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter/foundation.dart' show kIsWeb;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  late IO.Socket socket;
  final StreamController<String> _streamController = StreamController<String>();
  Stream<String> get messagesStream => _streamController.stream;

  TextEditingController controller = TextEditingController();
  TextEditingController _nameController = TextEditingController();
  List<dynamic> messages = [];

  //This will give platofrm specific url for ios and android emulator
  String socketUrl() {
    if (Platform.isAndroid) {
      return "http://10.0.2.2:4000";
    } else if (kIsWeb) {
      return "http://localhost:4000";
    } else {
      return " ";
    }
  }

  @override
  void initState() {
    super.initState();
    // Connect to the Socket.IO server
    socket = IO.io(socketUrl(), <String, dynamic>{
      'transports': ['websocket'],
    });

    socket.on('connect', (_) {
      print('Connected to server');
    });

    // Listen for messages from the server
    socket.on('chat message', (data) {
      _streamController.add(data);
    });
  }

  @override
  void dispose() {
    // Disconnect from the Socket.IO server when the app is disposed
    socket.disconnect();

    //close stream
    _streamController.close();
    super.dispose();
  }

  void sendMessage(String message) {
    // Send a message to the server
    messages.add(message);
    socket.emit('message', message);
    print(message);
  }

  @override
  Widget build(BuildContext context) {
    String? message;
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Socket.IO Flutter Demo'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: TextFormField(
                  onChanged: (value) {
                    message = value;
                  },
                  controller: controller,
                  decoration: const InputDecoration(hintText: "Enter Message"),
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.send,
                  size: 40,
                ),
                onPressed: () async {
                  if (message!.isNotEmpty) {
                    sendMessage(message!);
                  }
                  controller.clear();
                },
              ),
              const SizedBox(height: 40),
              StreamBuilder<String>(
                stream: messagesStream,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  }
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 25),
                    child: ListTile(
                      title: Text("Received Message: ${snapshot.data ?? ""}"),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
