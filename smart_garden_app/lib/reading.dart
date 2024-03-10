import 'package:firebase_database/firebase_database.dart';

class Reading{
  String? key;
  ReadingData? readingData;

  Reading({this.key,this.readingData});
}

class ReadingData{
  String? humidity;
  String? moisture;
  String? temp;
  String? light;
  DateTime? timestamp;

  ReadingData({this.humidity,this.moisture,this.temp,this.timestamp});

  ReadingData.fromJson(DataSnapshot reading){
    Map fields = reading.value as Map;
    humidity = fields["humidity"];
    moisture = fields["moisture"];
    temp = fields["temperature"];
    timestamp = DateTime.fromMillisecondsSinceEpoch(int.parse(reading.key!) * 1000);
    light = fields["light"];
  }
}