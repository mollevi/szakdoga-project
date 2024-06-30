import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server/gmail.dart';
import 'dart:convert';
import 'api/google_auth_api.dart';
import 'record.dart';

void main(){
  runApp(MyApp());
}

class MyApp extends StatelessWidget {

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'A',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage()
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  late Future<List<Record>> records;

  @override
  void initState() {
    super.initState();
    records = fetchRecords();
  }

  Future<List<Record>> fetchRecords() async {
    final response = await http.get(Uri.parse('https://molnarfemmuvek.hu/api/getTest'));

    if (response.statusCode == 200) {
      List jsonResponse = json.decode(response.body);
      return jsonResponse.map((record) => Record.fromJson(record)).toList();
    } else {
      throw Exception('Failed to load records');
    }
  }

  void _showFormDialog() {
    showDialog(
      context:  context,
      builder:  (BuildContext context) {
        return FormDialog(sendPutRequest: sendPutRequest);
      },
    );
  }

  Future<void> sendPutRequest(Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse('https://molnarfemmuvek.hu/api/putTest'),
      headers:  <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body:     jsonEncode(data),
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Successfully sent PUT request')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to send PUT request')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Record List'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _refreshData,
          ),
          IconButton(
            icon: Icon(Icons.outgoing_mail),
            onPressed: _sendEmail,
          ),
          IconButton(
            icon: Icon(Icons.mail_lock_outlined),
            onPressed: _sendOtherMail,
          ),
        ],
      ),
      body: Center(
        child: FutureBuilder<List<Record>>(
          future: records,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return CircularProgressIndicator();
            } else if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            } else if (!snapshot.hasData) {
              return Text('No records found');
            } else {
              return Column(
                  children: [
                    Expanded(
                      child: ListView(
                        children: snapshot.data!.map((record) {
                          return ListTile(
                            title: Text(record.string),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Text: ${record.text}'),
                                Text('Integer: ${record.integer}'),
                                Text('Decimal: ${record.decimal}'),
                                Text('Datetime: ${DateFormat('yyyy-MM-dd – kk:mm').format(record.datetime)}'),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: _showFormDialog,
                      child: Text('Add Record'),
                    ),
                  ],
              );
            }
          },
        ),
      ),
    );
  }

  void _refreshData() {
    setState(() {
      records = fetchRecords();
    });
  }

  void _sendOtherMail() async {
    final response = await http.post(Uri.parse('http://192.168.1.10:49202/api/sendTestMail'),
        headers: <String, String>{
          "Content-Type": 'application/json; charset=UTF-8'
        },
        body:jsonEncode({"email":"mollevi99@gmail.com"}),
    );
    if (response.statusCode == 200) {
      return;
    } else {
      throw Exception('Oh no, the mail was not sent.');
    }
  }

  Future _sendEmail() async {
    final user = await GoogleAuthApi.signIn();
    if(user == null){
      return;
    }

    final email = user.email;
    final auth = await user.authentication;
    final String token = user.serverAuthCode ?? "";

    final smtpServer = gmailSaslXoauth2(email, token);

    final message = Message()
      ..from = Address(email, 'wud0zl-szakdoli')
      ..recipients.add(email)
      ..subject = 'Test Dart Mailer library | ${DateTime.now()}'
      ..text = 'This is a plain text.\nThis is line 2.'
      ..html = "<h1>Test</h1>\n<p>some HTML.</p>";

    try {
      final sendReport = await send(message, smtpServer);
      print('Message sent: ' + sendReport.toString());
    } on MailerException catch (e) {
      print('Message not sent.');
      for (var p in e.problems) {
        print('Problem: ${p.code}: ${p.msg}');
      }
    }
  }
}


class FormDialog extends StatefulWidget {
  final Future<void> Function(Map<String, dynamic>) sendPutRequest;

  FormDialog({required this.sendPutRequest});

  @override
  _FormDialogState createState() => _FormDialogState();
}

class _FormDialogState extends State<FormDialog> {
  final _formKey = GlobalKey<FormState>();
  String _text = '';
  int _integer = 0;
  double _decimal = 0.0;
  String _string = '';
  DateTime _datetime = DateTime.now();

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _datetime,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (pickedDate != null && pickedDate != _datetime) {
      setState(() {
        _datetime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          _datetime.hour,
          _datetime.minute,
        );
      });
    }
  }

  // Function to show the time picker
  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_datetime),
    );
    if (pickedTime != null) {
      setState(() {
        _datetime = DateTime(
          _datetime.year,
          _datetime.month,
          _datetime.day,
          pickedTime.hour,
          pickedTime.minute,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title:    Text('Add Record'),
      content:  Form(
        key:      _formKey,
        child:    SingleChildScrollView(
          child:    Column(
            children: [
              TextFormField(
                decoration: InputDecoration(labelText: 'Text'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter text';
                  }
                  _text = value;
                  return null;
                },
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Integer'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an integer';
                  }
                  _integer = int.parse(value);
                  return null;
                },
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Decimal'),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a decimal';
                  }
                  RegExp decimalRegExp = RegExp(r'^-?(0|([1-9]\d*))(.\d+)?$');

                  if (!decimalRegExp.hasMatch(value)) {
                    return 'Please enter a decimal';
                  }

                  // Try to parse the input to a double
                  try {
                    double x = double.parse(value);

                    // Convert back to string, remove trailing zeros and dot if necessary
                    String formatted = x.toStringAsFixed(10); // Start with a high precision
                    formatted = formatted.replaceAll(RegExp(r'0*$'), ''); // Remove trailing zeros
                    if (formatted.endsWith('.')) {
                      formatted = formatted.substring(0, formatted.length - 1); // Remove trailing dot
                    }
                    _decimal = double.parse(formatted);
                    return null;
                  } catch (e) {
                    return 'Please enter a decimal';
                  }
                },
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'String'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a string';
                  }
                  _string = value;
                  return null;
                },
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Datetime'),//NEW
                readOnly: true,
                controller: TextEditingController(
                  text: DateFormat('yyyy-MM-dd – kk:mm').format(_datetime),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a datetime';
                  }
                  return null;
                },
                onTap: () async {
                  await _selectDate(context);
                  await _selectTime(context);
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final data = {
                'text': _text,
                'integer': _integer,
                'decimal': _decimal,
                'string': _string,
                'datetime': _datetime.toIso8601String(),
              };
              widget.sendPutRequest(data);
              Navigator.of(context).pop();
            }
          },
          child: Text('Submit'),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text('Cancel'),
        ),
      ],
    );
  }
}
