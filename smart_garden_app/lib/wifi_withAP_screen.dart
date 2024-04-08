import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;

class UrlLaunchPage extends StatelessWidget {
  UrlLaunchPage({super.key});
  final Uri url = Uri.parse('http://192.168.4.1');

  Future<void> _launchURL(Uri url) async {
    if (await canLaunchUrl(url)) {
      if (!await launchUrl(url)) {
        throw Exception('Could not launch $url');
      }
    }
    else {
      throw 'Could not launch $url';
    }
  }

  Future<bool> _checkURL(Uri url) async{
    try{
      final response = await http.head(url).timeout(const Duration(seconds: 1), onTimeout:(){return http.Response('Error', 408);});
      if (response.statusCode != 200){
        return false;
      }
      return true;
    }
    catch(e){
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
      title: const Text('Wifi Manager'),),
      body: Center(
          child: Column(
            children: [
              Text("Make sure your device is connected to arduino AP and click to lunch wifi manager",style: TextStyle(fontSize: 20),),
              ElevatedButton(
                onPressed: () async{
                  if(!await _checkURL(url)){
                    print("got here");
                    showErrorApDialog(context);
                  }
                  else{
                    print("sdfsdfsdfsdfsdfsdf");
                    try{
                      _launchURL(url);
                    }
                    catch(e){
                      print("1222222222222222222222222222");
                      showErrorApDialog(context);
                    }
                  }
                },
                child: Text('Launch Wifi Manager'),
              ),
            ],
          ),
        ),
    );
  }

  void showErrorApDialog(BuildContext context) {
    showDialog<void>(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Error'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Can't access wifi manager. Make sure you are connected to arduino AP and try again!"),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: ()  {
                  Navigator.of(context).pop();
                  },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      },
    );
  }
}
