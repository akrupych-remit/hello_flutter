import 'dart:async';
import 'dart:math';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/cupertino.dart';

import 'package:google_sign_in/google_sign_in.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_database/ui/firebase_animated_list.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'package:image_picker/image_picker.dart';

final firebaseAuth = FirebaseAuth.instance;
final googleSignIn = new GoogleSignIn();
final analytics = new FirebaseAnalytics();

void main() => runApp(new App());

bool _isAndroid() {
  return defaultTargetPlatform == TargetPlatform.android;
}

Future<Null> _signIn() async {
  GoogleSignInAccount account = googleSignIn.currentUser;
  if (account == null) account = await googleSignIn.signInSilently();
  if (account == null) {
    await googleSignIn.signIn();
    analytics.logLogin();
  }
  if (await firebaseAuth.currentUser() == null) {
    GoogleSignInAuthentication googleAuth = await googleSignIn.currentUser.authentication;
    await firebaseAuth.signInWithGoogle(
        idToken: googleAuth.idToken,
        accessToken: googleAuth.accessToken
    );
  }
}

final ThemeData androidTheme = new ThemeData(
  primarySwatch: Colors.red,
  accentColor: Colors.orange,
);

final ThemeData iosTheme = new ThemeData(
    primarySwatch: Colors.grey,
    accentColor: Colors.blue
);

class App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: "Friendly Chat",
      home: new ChatScreen(),
      theme: _isAndroid() ? androidTheme : iosTheme,
    );
  }
}

class ChatScreen extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return new ChatScreenState();
  }
}

class ChatScreenState extends State<ChatScreen> {

  final _messagesDb = FirebaseDatabase.instance.reference().child("messages");
  final TextEditingController _textController = new TextEditingController();
  bool _canSend = false;

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
        appBar: new AppBar(
          title: new Text("Friendly Chat"),
          elevation: _isAndroid() ? 4.0 : 0.0,
        ),
        body: new Column(
          children: <Widget>[
            _buildMessageList(),
            new Divider(height: 1.0),
            _buildTextInput()
          ],
        ));
  }

  Widget _buildMessageList() {
    return new Flexible(
        child: new FirebaseAnimatedList(
          query: _messagesDb,
          sort: (a, b) => b.key.compareTo(a.key),
          padding: new EdgeInsets.all(8.0),
          reverse: true,
          itemBuilder: (BuildContext buildContext, DataSnapshot dataSnapshot,
              Animation<double> animation) {
            return new ChatMessage(dataSnapshot: dataSnapshot, animation: animation);
          },
        )
    );
  }

  Widget _buildTextInput() {
    return new IconTheme(
        data: new IconThemeData(color: Theme.of(context).accentColor),
        child: new Container(
            child: new Row(
              children: <Widget>[
                new IconButton(
                    icon: new Icon(Icons.photo_camera),
                    onPressed: () => _pickImage()
                ),
                new Flexible(
                  child: new TextField(
                    controller: _textController,
                    onChanged: (String text) {
                      setState(() {
                        _canSend = text.length > 0;
                      });
                    },
                    onSubmitted: (_) => _onTextSubmitted(),
                    decoration: new InputDecoration.collapsed(
                        hintText: "Send a message"
                    ),
                  ),
                ),
                _buildSendButton(),
              ],
            )));
  }

  Widget _buildSendButton() {
    return _isAndroid()
        ? new IconButton(
            icon: new Icon(Icons.send),
            onPressed: _canSend ? _onTextSubmitted : null)
        : new CupertinoButton(
            child: new Text("Send"),
            onPressed: _canSend ? _onTextSubmitted : null);
  }

  void _onTextSubmitted() {
    setState(() {
      _canSend = false;
    });
    _sendMessage(text: _textController.text);
    _textController.clear();
  }

  void _sendMessage({String text, String imageUrl}) async {
    await _signIn();
    _messagesDb.push().set({
      "text": text,
      "image_url": imageUrl,
      "sender_name": googleSignIn.currentUser.displayName,
      "sender_image": googleSignIn.currentUser.photoUrl
    });
    analytics.logEvent(name: "send_message");
  }

  void _pickImage() async {
    await _signIn();
    File image = await ImagePicker.pickImage();
    String userId = googleSignIn.currentUser.id;
    int microsecond = new DateTime.now().microsecondsSinceEpoch;
    StorageReference ref = FirebaseStorage.instance.ref().child("$userId$microsecond");
    Uri imageUrl = (await ref.put(image).future).downloadUrl;
    _sendMessage(imageUrl: imageUrl.toString());
  }
}

class ChatMessage extends StatelessWidget {

  DataSnapshot dataSnapshot;
  Animation<double> animation;

  ChatMessage({this.dataSnapshot, this.animation});

  @override
  Widget build(BuildContext context) {
    return new FadeTransition(
        opacity: new CurvedAnimation(
            parent: animation, curve: Curves.easeIn),
        child: new SizeTransition(
            sizeFactor: new CurvedAnimation(
                parent: animation, curve: Curves.easeOut),
            axisAlignment: 0.0,
            child: new Container(
                color: Colors.blueGrey[100],
                margin: new EdgeInsets.only(top: 8.0),
                padding: new EdgeInsets.all(8.0),
                child: new Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    new CircleAvatar(
                      backgroundImage:
                      new NetworkImage(dataSnapshot.value['sender_image']),
                    ),
                    new Expanded(
                      child: new Container(
                        margin: new EdgeInsets.only(left: 8.0),
                        child: new Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            new Text(dataSnapshot.value['sender_name'],
                                style: Theme
                                    .of(context)
                                    .textTheme
                                    .caption),
                            new Container(
                                margin: new EdgeInsets.only(top: 4.0),
                                child: dataSnapshot.value["image_url"] != null ?
                                    new Image.network(dataSnapshot.value["image_url"]) :
                                    new Text(dataSnapshot.value['text'])),
                          ],
                        ),
                      ),
                    )
                  ],
                )
            )
        )
    );
  }
}
