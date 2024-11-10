import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class InstructionsBottomSheet extends StatefulWidget {
  const InstructionsBottomSheet({super.key});

  @override
  State<InstructionsBottomSheet> createState() =>
      _InstructionsBottomSheetState();
}

class _InstructionsBottomSheetState extends State<InstructionsBottomSheet> {
  @override
  void initState() {
    super.initState();
    _checkFirstRun();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: IconButton(
        icon: const Icon(Icons.help),
        color: Colors.white,
        onPressed: () {
          instructionsBottomSheet(context);
        },
      ),
    );
  }

  Future<void> _checkFirstRun() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final bool? isFirstRun = prefs.getBool('first_run');

    if (isFirstRun == null || isFirstRun == false) {
      await prefs.setBool('first_run', true);
      await instructionsBottomSheet(context);
    }
  }

  Future<void> instructionsBottomSheet(BuildContext context) {
    return showModalBottomSheet<void>(
      backgroundColor: Colors.black,
      context: context,
      builder: (BuildContext context) {
        return Container(
          margin: const EdgeInsets.all(20),
          child: SizedBox(
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const SizedBox(
                  width: double.infinity,
                  child: Text(
                    'Istruzioni d\'uso',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 24),
                  ),
                ),
                const SizedBox(height: 15),
                const Text(
                  '1. Inquadra la scena che vuoi analizzare con il telefono e clicca su qualsiasi parte dello schermo',
                  style: TextStyle(
                      color: Color.fromARGB(255, 190, 190, 190), fontSize: 16),
                ),
                const SizedBox(height: 10),
                const Text(
                  '2. Attendi che il tuo telefono abbia finito di analizzare la scena',
                  style: TextStyle(
                      color: Color.fromARGB(255, 190, 190, 190), fontSize: 16),
                ),
                const SizedBox(height: 10),
                const Text(
                  '3. Ascolta la descrizione di cio che è davanti a te',
                  style: TextStyle(
                      color: Color.fromARGB(255, 190, 190, 190), fontSize: 16),
                ),
                const SizedBox(height: 25),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ButtonStyle(
                      backgroundColor:
                          WidgetStateProperty.all<Color>(Colors.blue),
                    ),
                    child:
                        const Text('Ok', style: TextStyle(color: Colors.white)),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
