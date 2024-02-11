class Reading{
  String? key;
  ReadingData? readingData;

  Reading({this.key,this.readingData});
}

class ReadingData{
  String? humidity;
  String? moisture;
  String? temp;
  String? timestamp;

  ReadingData({this.humidity,this.moisture,this.temp,this.timestamp});

  ReadingData.fromJson(Map<dynamic,dynamic> json){
    humidity = json["humidity"];
    moisture = json["moistore"];
    temp = json["temperature"];
    timestamp = json["timestamp"];
  }
}