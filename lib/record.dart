class Record {
  final String text;
  final int integer;
  final double decimal;
  final String string;
  final DateTime datetime;

  Record({
    required this.text,
    required this.integer,
    required this.decimal,
    required this.string,
    required this.datetime,
  });

  factory Record.fromJson(Map<String, dynamic> json) {
    return Record(
      text: json['text'],
      integer: json['integer'],
      decimal: double.parse(json['decimal']),
      string: json['string'],
      datetime: DateTime.parse(json['datetime']),
    );
  }
}
