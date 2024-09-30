import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'main_controller.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => MainController(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('USSD Launcher Demo'),
            bottom: const TabBar(
              tabs: [
                Tab(text: 'Single Session'),
                Tab(text: 'Multi Session'),
              ],
            ),
          ),
          body: const TabBarView(
            children: [
              SingleSessionTab(),
              MultiSessionTab(),
            ],
          ),
        ),
      ),
    );
  }
}

class SingleSessionTab extends StatefulWidget {
  const SingleSessionTab({super.key});

  @override
  _SingleSessionTabState createState() => _SingleSessionTabState();
}

class _SingleSessionTabState extends State<SingleSessionTab> {
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    Provider.of<MainController>(context, listen: false).loadSimCards();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<MainController>(context);
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          DropdownButton<int>(
            value: controller.selectedSimId,
            hint: const Text('Sélectionner SIM'),
            items: controller.simCards.map((sim) {
              return DropdownMenuItem<int>(
                value: sim['subscriptionId'],
                child: Text("${sim['displayName']} (${sim['carrierName']})"),
              );
            }).toList(),
            onChanged: (value) => controller.setSelectedSimId(value),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            decoration: const InputDecoration(labelText: 'Entrer le code USSD'),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => controller.sendUssdRequest(_controller.text),
            child: const Text('Envoyer USSD'),
          ),
          const SizedBox(height: 16),
          const Text('Réponse USSD :'),
          Text(
            controller.ussdResponse,
            style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class MultiSessionTab extends StatefulWidget {
  const MultiSessionTab({super.key});

  @override
  _MultiSessionTabState createState() => _MultiSessionTabState();
}

class _MultiSessionTabState extends State<MultiSessionTab> {
  final TextEditingController _ussdController = TextEditingController();
  final List<TextEditingController> _optionControllers = [];

  @override
  void initState() {
    super.initState();
    final controller = Provider.of<MainController>(context, listen: false);
    controller.loadSimCards();
    controller.initUssdMessageListener();
  }

  void _addOptionField() {
    setState(() {
      _optionControllers.add(TextEditingController());
    });
  }

  void _removeOptionField() {
    setState(() {
      if (_optionControllers.isNotEmpty) {
        _optionControllers.removeLast().dispose();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<MainController>(context);
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        child: Column(
          children: [
            Text(
              'Slot SIM sélectionné : ${controller.selectedSlotIndex ?? "Aucun"}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            DropdownButton<int>(
              value: controller.selectedSlotIndex,
              hint: const Text('Sélectionner SIM'),
              items: controller.simCards.map((sim) {
                return DropdownMenuItem<int>(
                  value: sim['slotIndex'],
                  child: Text("${sim['displayName']} (${sim['carrierName']})"),
                );
              }).toList(),
              onChanged: (value) => controller.setSelectedSlotIndex(value),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _ussdController,
              decoration: const InputDecoration(labelText: 'Entrer le code USSD'),
            ),
            ..._optionControllers.asMap().entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: TextField(
                  controller: entry.value,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: 'Option ${entry.key + 1}'),
                ),
              );
            }),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: _addOptionField,
                  child: const Text('Ajouter Option'),
                ),
                ElevatedButton(
                  onPressed: _optionControllers.isNotEmpty ? _removeOptionField : null,
                  child: const Text('Retirer Option'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: controller.isLoading
                  ? null
                  : () => controller.launchMultiSessionUssd(
                      _ussdController.text,
                      _optionControllers.map((c) => c.text).toList()),
              child: const Text('Lancer USSD Multi-Session'),
            ),
            const SizedBox(height: 16),
            const Text('Réponses USSD :'),
            Container(
              height: 200,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.blueAccent),
                borderRadius: BorderRadius.circular(8.0),
              ),
              padding: const EdgeInsets.all(8.0),
              child: ListView.builder(
                itemCount: controller.ussdMessages.length,
                itemBuilder: (context, index) {
                  final isLastMessage = index == controller.ussdMessages.length - 1;
                  return Text(
                    controller.ussdMessages[index],
                    style: TextStyle(
                      color: isLastMessage ? Colors.red : Colors.blue,
                      fontWeight: isLastMessage ? FontWeight.bold : FontWeight.normal,
                      fontSize: isLastMessage ? 16 : 14,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            if (controller.sessionStatus.isNotEmpty)
              Text(
                controller.sessionStatus,
                style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    for (var controller in _optionControllers) {
      controller.dispose();
    }
    _ussdController.dispose();
    super.dispose();
  }
}