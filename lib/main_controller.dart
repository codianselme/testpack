import 'package:flutter/material.dart';
import 'package:ussd_launcher/ussd_launcher.dart';
import 'package:permission_handler/permission_handler.dart';

class MainController extends ChangeNotifier {
  List<Map<String, dynamic>> simCards = [];
  int? selectedSimId;
  int? selectedSlotIndex;
  String ussdResponse = '';
  List<String> ussdMessages = [];
  String sessionStatus = '';
  bool isLoading = false;

  Future<void> loadSimCards() async {
    var status = await Permission.phone.request();
    if (status.isGranted) {
      try {
        final cards = await UssdLauncher.getSimCards();
        simCards = cards;
        if (cards.isNotEmpty) {
          selectedSimId = cards[0]['subscriptionId'] as int?;
          selectedSlotIndex = cards[0]['slotIndex'];
        }
        notifyListeners();
      } catch (e) {
        print("Erreur lors du chargement des cartes SIM: $e");
      }
    } else {
      print("Permission téléphone non accordée");
    }
  }

  Future<void> sendUssdRequest(String ussdCode) async {
    ussdResponse = 'Envoi de la requête USSD...';
    notifyListeners();

    try {
      String? response = await UssdLauncher.sendUssdRequest(
        ussdCode: ussdCode,
        subscriptionId: selectedSimId ?? -1,
      );
      ussdResponse = response ?? 'Aucune réponse reçue';
    } catch (e) {
      ussdResponse = 'Erreur: ${e.toString()}';
    }
    notifyListeners();
  }

  void setSelectedSimId(int? value) {
    selectedSimId = value;
    notifyListeners();
  }

  void setSelectedSlotIndex(int? value) {
    selectedSlotIndex = value;
    notifyListeners();
  }

  void onUssdMessageReceived(String message) {
    print("Message USSD reçu: $message");
    ussdMessages = [message];
    if (message.contains("completed") || message.contains("cancelled")) {
      sessionStatus = "Session USSD terminée.";
    }
    notifyListeners();
  }

  Future<void> launchMultiSessionUssd(String code, List<String> options) async {
    isLoading = true;
    ussdMessages.clear();
    sessionStatus = '';
    notifyListeners();

    try {
      await UssdLauncher.multisessionUssd(
        code: code,
        slotIndex: (selectedSlotIndex ?? 0),
        options: options,
      );
    } catch (e) {
      ussdMessages.add('\nErreur : ${e.toString()}');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void initUssdMessageListener() {
    UssdLauncher.setUssdMessageListener(onUssdMessageReceived);
  }
}