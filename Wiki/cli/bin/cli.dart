library;

import 'dart:io'; // Add this line at the top
import 'package:http/http.dart' as http;
import 'package:command_runner/command_runner.dart';
import 'package:command_runner/src/console.dart';

const version = '0.0.1';

void main(List<String> arguments) {
  var commandRunner = CommandRunner(
    onOutput: (String output) async {
      await write(output);
    },
    onError: (Object error) {
      if (error is Error) {
        throw error;
      }
      if (error is Exception) {
        print(error);
      }
    },
  )..addCommand(HelpCommand());
  commandRunner.run(arguments);
}

void searchWikipedia(List<String>? arguments) async {
  late String? articleTitle;

  // If the user didn't pass in arguments, request an article title.
  if (arguments == null || arguments.isEmpty) {
    print('Please provide an article title.');
    final inputFromStdin = stdin.readLineSync();

    if (inputFromStdin == null || inputFromStdin!.isEmpty) {
      print('No article title provided.');
      return;
    }
    // Await input and provide a default empty string if the input is null.
    articleTitle = inputFromStdin;
  } else {
    // Otherwise, join the arguments into the CLI into a single string
    articleTitle = arguments.join(' ');
  }

  print('Looking up articles about "$articleTitle". Please wait.');
  // Call the API to get the article summary.
  var articleContent = await getWikipediaArticle(articleTitle!);
  print('Here ya go!');
  print(articleContent);
}

Future<String> getWikipediaArticle(String articleTitle) async {
  final client = http.Client(); // Create an HTTP client.
  final url = Uri.https(
    'en.wikipedia.org', 
     '/api/rest_v1/page/summary/$articleTitle', // API path for article summary
    );
    final response = await client.get(url);
    if (response.statusCode == 200) {
      return response.body;
    } else {
      throw Exception('Failed to load article: ${response.statusCode}');
    }

    return '';
}

void printUsage() { // Add this new function
  print(
    "The following commands are valid: 'help', 'version', 'search <ARTICLE-TITLE>'"
  );
}
