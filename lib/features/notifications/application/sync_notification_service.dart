import 'dart:async';

class SyncNotificationService {
  final contractSyncCompleted = StreamController<Map<String, dynamic>>.broadcast();
  final investmentContractSyncCompleted = StreamController<Map<String, dynamic>>.broadcast();
  final assetCalculationSyncCompleted = StreamController<Map<String, dynamic>>.broadcast();
  final externalContractSyncCompleted = StreamController<Map<String, dynamic>>.broadcast();
  final synccustomercontract = StreamController<Map<String, dynamic>>.broadcast();
  final investmentSync = StreamController<Map<String, dynamic>>.broadcast();
  final portfolioInvestmentSync = StreamController<Map<String, dynamic>>.broadcast();
  final synccustomerdatabyid = StreamController<Map<String, dynamic>>.broadcast();
  final gdprConsentSync = StreamController<Map<String, dynamic>>.broadcast();

  void dispose() {
    contractSyncCompleted.close();
    investmentContractSyncCompleted.close();
    assetCalculationSyncCompleted.close();
    externalContractSyncCompleted.close();
    synccustomercontract.close();
    investmentSync.close();
    portfolioInvestmentSync.close();
    synccustomerdatabyid.close();
    gdprConsentSync.close();
  }
}
