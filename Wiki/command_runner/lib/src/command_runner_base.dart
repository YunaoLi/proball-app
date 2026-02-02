import 'dart:collection';
import 'dart:io';
import 'arguments.dart';
import 'exceptions.dart';
import 'dart:async';

class CommandRunner {
  
  // Add a constructor that accepts the optional callback.
  CommandRunner({this.onOutput, this.onError});

  final Map<String, Command> _commands = <String, Command>{};

  UnmodifiableSetView<Command> get commands =>
      UnmodifiableSetView<Command>(<Command>{..._commands.values});

  // Define the onError property.
  FutureOr<void> Function(Object)? onError;
  /// If not null, this method is used to handle output. Useful if you want to
  /// execute code before the output is printed to the console, or if you
  /// want to do something other than print output the console.
  /// If null, the onInput method will [print] the output.
  FutureOr<void> Function(String)? onOutput;

  Future<void> run(List<String> input) async {
    try {
      final ArgResults results = parse(input);
      if (results.command != null) {
        Object? output = await results.command!.run(results);
        if (onOutput != null) {
          await onOutput!(output.toString());
        } else {
          print(output.toString());
        }
      }
    } on Exception catch (e) {
      print(e);
    }
  }



  void addCommand(Command command) {
    // TODO: handle error (Commands can't have names that conflict)
    _commands[command.name] = command;
    command.runner = this;
  }

  // [Step 6 update] This method is replaced entirely.
  ArgResults parse(List<String> input) {
      ArgResults results = ArgResults();
      if (input.isEmpty) return results;

      // Throw an exception if the command is not recognized.
      if (_commands.containsKey(input.first)) {
          results.command = _commands[input.first];
          input = input.sublist(1);
      } else {
          throw ArgumentException(
              'The first word of input must be a command.',
              null,
              input.first,
          );
      }

      // Throw an exception if multiple commands are provided.
      if (results.command != null &&
          input.isNotEmpty &&
          _commands.containsKey(input.first)) {
              throw ArgumentException(
                  'Input can only contain one command. Got ${input.first} and ${results.command!.name}',
                  null,
                  input.first,
              );
      }

      // Section: handle Options (including flags)
      Map<Option, Object?> inputOptions = {};
      int i = 0;
      while (i < input.length) {
          if (input[i].startsWith('-')) {
              var base = _removeDash(input[i]);
              // Throw an exception if an option is not recognized for the given command.
              var option = results.command!.options.firstWhere(
                  (option) => option.name == base || option.abbr == base,
                  orElse: () {
                      throw ArgumentException(
                      'Unknown option ${input[i]}',
                      results.command!.name,
                      input[i],
                      );
                  },
              );

              if (option.type == OptionType.flag) {
                  inputOptions[option] = true;
                  i++;
                  continue;
              }

              if (option.type == OptionType.option) {
              // Throw an exception if an option requires an argument but none is given.
                  if (i + 1 >= input.length) {
                      throw ArgumentException(
                          'Option ${option.name} requires an argument',
                          results.command!.name,
                          option.name,
                      );
                  }
                  if (input[i + 1].startsWith('-')) {
                      throw ArgumentException(
                          'Option ${option.name} requires an argument, but got another option ${input[i + 1]}',
                          results.command!.name,
                          option.name,
                      );
                  }
                  var arg = input[i + 1];
                  inputOptions[option] = arg;
                  i++;
              }
          } else {
              // Throw an exception if more than one positional argument is provided.
              if (results.commandArg != null && results.commandArg!.isNotEmpty) {
              throw ArgumentException(
                  'Commands can only have up to one argument.',
                  results.command!.name,
                  input[i],
              );
              }
              results.commandArg = input[i];
          }
          i++;
      }
      results.options = inputOptions;

      return results;
  }

  String _removeDash(String input) {
      if (input.startsWith('--')) {
          return input.substring(2);
      }
      if (input.startsWith('-')) {
          return input.substring(1);
      }
      return input;
  }

  // Returns usage for the executable only.
  // Should be overridden if you aren't using [HelpCommand]
  // or another means of printing usage.

  String get usage {
    final exeFile = Platform.script.path.split('/').last;
    return 'Usage: dart bin/$exeFile <command> [commandArg?] [...options?]';
  }
}
