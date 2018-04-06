import 'package:flutter/material.dart';

void main() =>
    runApp(new MaterialApp(
      home: new Home(),
    ));

class Home extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return new _HomeState();
  }
}

class _HomeState extends State<Home> with TickerProviderStateMixin {

  AnimationController _opacityController;
  AnimationController _controllerMenu;
  AnimationController _controllerText;

  Animation<double> _opacityAnimation;
  Animation<double> _animationMenu;
  Animation<double> _animationText;

  bool _menuOpened = false;
  bool _showeasy = false;
  bool _showHint = false;

  @override
  void initState() {
    super.initState();
    _opacityController = new AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 800)
    );
    _controllerMenu = new AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 500)
    );
    _controllerText = new AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 500)
    );
    _opacityAnimation = new CurvedAnimation(
        parent: _opacityController,
        curve: Curves.easeInOut
    );
    _opacityAnimation.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _opacityController.reverse();
      } else if (status == AnimationStatus.dismissed) {
        _opacityController.forward();
      }
    });
    _opacityController.forward();
  }

  @override
  void dispose() {
    super.dispose();
    _opacityController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return new Container(
      color: Colors.white,
        child: new Stack(
            alignment: Alignment.center,
            children: <Widget>[
              new FadeTransition(
                opacity: _opacityAnimation,
                child: new Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    new Icon(Icons.arrow_back),
                    new Padding(padding: const EdgeInsets.only(left: 8.0)),
                    new Text("Swipe it",
                      style: new TextStyle(
                          fontSize: 16.0,
                          color: Colors.blueGrey
                      ),
                    )
                  ],
                ),
              ),
            ]
        )
    );
  }
}