import 'package:auto_complete_widget_flutter/auto_complete_widget_flutter.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: AutoCompleteField<String>(
            builder: (s, str, selected) => Container(
              color: selected ? Colors.grey.withOpacity(.2) : null,
              padding: const EdgeInsets.symmetric(
                vertical: 4,
                horizontal: 12,
              ),
              child: RichText(
                text: TextSpan(
                  children: s.selected(str).span,
                ),
              ),
            ),
            onSort: (p0, p1) => p1.contains(p0),
            result: (p0) => p0,
            decoration: BoxDecoration(
              color: Colors.grey[200],
            ),
            onResult: (p0) {},
            separatorBuilder: Container(
              height: 1,
              color: Colors.black,
              margin: const EdgeInsets.symmetric(horizontal: 16),
            ),
            values: const [
              'a',
              'b',
              'c',
              'd',
              'dasdkfjahsdfkjashdflkjahsdfjksadhflakjs1',
              'dasdkfjahsdfkjashdflkjahsdfjksadhflakjs2',
              'dasdkfjahsdfkjashdflkjahsdfjksadhflakjs3',
              'dasdkfjahsdfkjashdflkjahsdfjksadhflakjs4',
              'dasdkfjahsdfkjashdflkjahsdfjksadhflakjs5',
              'dasdkfjahsdfkjashdflkjahsdfjksadhflakjs6',
              'dasdkfjahsdfkjashdflkjahsdfjksadhflakjs7',
              'dasdkfjahsdfkjashdflkjahsdfjksadhflakjs8',
              'dasdkfjahsdfkjashdflkjahsdfjksadhflakjs9',
              'dasdkfjahsdfkjashdflkjahsdfjksadhflakjs10',
              'dasdkfjahsdfkjashdflkjahsdfjksadhflakjs11',
              'dasdkfjahsdfkjashdflkjahsdfjksadhflakjs111',
              'dasdkfjahsdfkjashdflkjahsdfjksadhflakjs1111',
              'dasdkfjahsdfkjashdflkjahsdfjksadhflakjs11111',
              'dasdkfjahsdfkjashdflkjahsdfjksadhflakjs111111',
            ],
          ),
        ),
      ),
    );
  }
}
