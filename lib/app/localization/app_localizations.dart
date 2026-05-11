import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

class AppLocalizations {
  AppLocalizations(this.locale, this._localizedValues);

  final Locale locale;
  final Map<String, Map<String, String>> _localizedValues;

  static const Locale fallbackLocale = Locale('de');
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('de'),
  ];

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static const Map<String, Map<String, String>>
  _fallbackLocalizedValues = <String, Map<String, String>>{
    'en': <String, String>{
      'common.loading': 'Loading...',
      'common.selectLanguage': 'Select Language',
      'common.english': 'English',
      'common.german': 'German',
      'login.genericError': 'Unable to sign in right now. Please try again.',
      'login.welcome': 'Welcome to Financial\nLife Planner',
      'login.email': 'Email',
      'login.emailHint': 'Enter Email',
      'login.emailRequired': 'Enter your email',
      'login.password': 'Password',
      'login.passwordHint': 'Enter Password',
      'login.passwordRequired': 'Enter your password',
      'login.rememberMe': 'Remember me',
      'login.forgotPassword': 'Forgot password?',
      'login.logIn': 'LOG IN',
      'login.noAccount': "Don't have an account? ",
      'login.createNow': 'CREATE NOW',
      'forgotPassword.title': 'Forgot Password',
      'forgotPassword.description':
          'Forgot password flow is the next login piece to port from the NativeScript app.',
      'settings.title': 'Settings',
      'settings.languageHeader': 'Select Language',
      'preferences.title': 'Preferences',
      'preferences.biometricTitle': 'Biometric',
      'preferences.biometricDescription':
          'Allow your device biometric fingerprint scan for easy login to FiLiP mobile app.',
      'preferences.pinTitle': 'PIN',
      'preferences.pinDescription':
          'Set recovery PIN in case of wrong biometric fingerprint or face ID attempts',
      'preferences.resetPin': 'RESET PIN',
      'preferences.actionPending':
          'This Preferences action is not available in Flutter yet.',
      'account.title': 'My Account',
      'account.fullName': 'Full Name',
      'account.emailAddress': 'Email Address',
      'account.updateEmail': 'UPDATE EMAIL',
      'account.phoneNumber': 'Phone Number',
      'account.updatePhone': 'UPDATE PHONE',
      'account.password': 'Password',
      'account.changePassword': 'CHANGE PASSWORD',
      'account.preferences': 'Preferences',
      'account.consentsTitle': 'My Consents and Preferences',
      'account.consentsDescription':
          'Update your GDPR Consent & Email preferences here',
      'account.deleteAccount': 'DELETE FILIP ACCOUNT',
      'account.actionPending':
          'This My Account action is not available in Flutter yet.',
      'onboarding.skip': 'SKIP',
      'onboarding.startNow': 'START NOW',
      'onboarding.manageContracts.title': 'Manage Contracts',
      'onboarding.manageContracts.description':
          'Get current information about your investment, insurance, retirement, and financing contracts.',
      'onboarding.realEstate.title': 'My Real Estate Overview',
      'onboarding.realEstate.description':
          'With FiLiP, you can now monitor, value, and search all properties and make smarter decisions with real-estate tools.',
      'onboarding.documents.title': 'Documents at a Glance',
      'onboarding.documents.description':
          'Upload and manage all important documents in your document area.',
      'onboarding.chat.title': 'Chat with Your Advisor',
      'onboarding.chat.description':
          'Use FiLiP to communicate with your advisor more easily anytime and anywhere.',
      'tns.me': 'Me',
      'tns.household': 'Household',
      'tns.business': 'Business',
      'tns.contractsAvailable': 'Contracts available',
      'tns.leaveHousehold': 'Leave household',
      'tns.leaveHouseholdBottomSheetTitle':
          'Are you sure you want to leave this household?',
      'tns.leaveHouseholdBottomSheetSubTitle':
          "Click 'Confirm' to leave this household or click 'Cancel' to go back.",
      'tns.myContracts': 'My Contracts',
      'tns.investment': 'Investments',
      'tns.nonLifeinsurance': 'Non-Life Insurance',
      'tns.insurance': 'Insurance',
      'tns.retirement': 'Retirement',
      'tns.loan': 'Loan',
      'tns.investmentContracts': 'Investment Contracts',
      'tns.insuranceContracts': 'Insurance Contracts',
      'tns.retirementContracts': 'Retirement Contracts',
      'tns.loanContracts': 'Loan Contracts',
      'tns.investmentDetails': 'Investment Details',
      'tns.investmentDetailsSubtitle':
          'View all the details of your investments and their status in our Investment Cockpit',
      'tns.personalPerformance': 'Personal Performance',
      'tns.totalInvestment': 'Total Investment',
      'tns.totalInvestmentSLS': 'Total Investment',
      'tns.investmentRisk': 'Investment Risk',
      'tns.investorProfile': 'Investor Profile',
      'tns.moneyMarketAccount': 'Money Market Account',
      'tns.clearingAccount': 'Clearing Account',
      'tns.fixedDepositAccounts': 'Fixed Deposit Accounts',
      'tns.seeMore': 'See more',
      'tns.seeLess': 'See less',
      'tns.noDataAddedYet': 'No data has been added yet!',
      'tns.noDataFound': 'No data found',
      'tns.multipleSelection': 'Multiple selection',
      'tns.selectAll': 'Select all',
      'tns.showContracts': 'Show contracts',
      'contracts.householdCannotDeselectAll':
          'At least one household member must stay selected.',
      'tns.importantNotice': 'Important Notice',
      'tns.insureinfotext':
          'Please note that the availability of your contract data depends on the data delivery of your product partner.',
      'tns.retirementInfoText':
          'Please note that the availability of your contract data depends on the data delivery of your product partner.',
      'tns.addInvestmentContract': 'Add Investment Contract',
      'tns.addRetirementContract': 'Add Retirement Contract',
      'tns.formPreviewHint':
          'This is the first Flutter form shell for contracts. Submission wiring can be connected next.',
      'tns.contractTitle': 'Contract Title',
      'tns.partner': 'Partner',
      'tns.amount': 'Amount',
      'tns.type': 'Type',
      'tns.endDate': 'End Date',
      'tns.annualPremium': 'Annual Premium',
      'tns.addInsuranceContract': 'Add Insurance Contract',
      'tns.addLoanContract': 'Add Loan Contract',
      'tns.create': 'Create',
      'common.retry': 'Retry',
      'common.yes': 'Yes',
      'common.no': 'No',
      'tns.contractFormLoadFailed':
          'The add contract form could not be loaded right now.',
      'tns.contractCreateFailed':
          'The contract could not be created right now.',
      'tns.fieldRequired': 'This field is required.',
      'tns.minimumCharacters': 'Enter at least {{count}} characters.',
      'tns.maximumCharacters': 'Enter no more than {{count}} characters.',
      'tns.addNOTE': 'Add Note',
      'tns.editNOTE': 'Edit Note',
      'tns.deleteNote': 'Delete Note',
      'tns.deleteNoteConfirmationMessage':
          'This will delete your file permanently and can not be undone',
      'tns.writeTextHere': 'Write text here',
      'tns.noteUpdateFailed': 'The note could not be updated right now.',
      'tns.enterValidNumber': 'Enter a valid number.',
      'tns.minimumValue': 'Enter a value of at least {{value}}.',
      'tns.maximumValue': 'Enter a value no greater than {{value}}.',
      'tns.contractNumber': 'Contract Number',
      'tns.premiumFrequency': 'Premium Frequency',
      'tns.pensionFrequency': 'Pension Frequency',
      'tns.grossPremium': 'Gross Premium',
      'tns.selectPartner': 'Select Partner',
      'tns.insuranceAmount': 'Insurance Amount',
      'tns.startDate': 'Start Date',
      'tns.notes': 'Notes',
      'tns.dueDate': 'Due Date',
      'tns.status': 'Status',
      'tns.active': 'Active',
      'tns.inactive': 'Inactive',
      'tns.unknown': 'Unknown',
      'tns.loanType': 'Loan Type',
      'tns.purposeOfUse': 'Purpose of Use',
      'tns.bankingInstitute': 'Banking Institute',
      'tns.loanAmount': 'Loan Amount',
      'tns.startOfRepayment': 'Start of Repayment',
      'tns.typeOfInterest': 'Type of Interest',
      'tns.fixedInterestRate': 'Fixed Interest Rate',
      'tns.fixedInterestRateDuration': 'Fixed Interest Rate Duration',
      'tns.referenceInterestRate': 'Reference Interest Rate',
      'tns.bankSurcharge': 'Bank Surcharge',
      'tns.tradeInValue': 'Trade-in Value',
      'tns.remainingLoan': 'Remaining Loan',
      'tns.dateOfRemainingDebt': 'Date of Remaining Debt',
      'tns.loanConclusionDate': 'Loan Conclusion Date',
      'tns.contractDetails': 'Contract Details',
      'tns.paymentMethod': 'Payment Method',
      'tns.targetSumSavingsPlan': 'Target Sum Savings Plan',
      'tns.lumpSumInvestment': 'Lump Sum Investment',
      'tns.risk': 'Risk',
      'tns.isin': 'ISIN',
      'tns.currentValue': 'Current Value',
      'tns.currentShareValue': 'Current Share Value',
      'tns.currentValueDate': 'Current Value Date',
      'tns.numberOfShares': 'Number of Shares',
      'tns.couponRate': 'Coupon Rate',
      'tns.couponPeriod': 'Coupon Period',
      'tns.couponType': 'Coupon Type',
      'tns.issuer': 'Issuer',
      'tns.bondPrice': 'Bond Price',
      'tns.bondPriceDate': 'Bond Price Date',
      'tns.currency': 'Currency',
      'tns.iban': 'IBAN',
      'tns.bic': 'BIC',
      'tns.premiumBenefit': 'Premium Benefit',
      'tns.interestRate': 'Interest Rate',
      'tns.bookValueBond': 'Book Value',
      'tns.investmentAmount': 'Investment Amount',
      'tns.bookValue': 'Book Value',
      'tns.priceDate': 'Price Date',
      'tns.valueAtOpening': 'Value at Opening',
      'tns.purchaseDate': 'Purchase Date',
      'tns.maturityDate': 'Maturity Date',
      'tns.accountNumber': 'Account Number',
      'tns.edit': 'Edit',
      'tns.delete': 'Delete',
      'tns.save': 'Save',
      'tns.cancel': 'Cancel',
      'tns.ok': 'OK',
      'tns.monthly': 'Monthly',
      'tns.quarterly': 'Quarterly',
      'tns.halfYearly': 'Half Yearly',
      'tns.annually': 'Annually',
      'tns.oneTime': 'One Time',
      'tns.semiAnnually': 'Semi Annually',
      'tns.once': 'Once',
      'tns.otherUnknown': 'other, unknown',
      'tns.variable': 'Variable',
      'tns.fixed': 'Fixed',
      'tns.euribor3m': '3-Month Euribor',
      'tns.euribor6m': '6-Month Euribor',
      'tns.euribor12m': '12-Month Euribor',
      'tns.primeRate': 'Prime Rate',
      'tns.fixedRate': 'Fixed Rate',
      'tns.stepUpRate': 'Step-Up Rate',
      'tns.variableRate': 'Variable Rate',
      'tns.zeroCoupon': 'Zero Coupon',
      'tns.other': 'Other',
      'tns.contractTypeHomeownersInsurance': 'Homeowners Insurance',
      'tns.contractTypeHouseholdInsurance': 'Household insurance',
      'tns.contractTypeHouseholdAndHomeInsurance':
          'Household and home insurance',
      'tns.contractTypeLegalProtectionInsurance': 'Legal protection insurance',
      'tns.contractTypeCarInsurance': 'Car insurance',
      'tns.contractTypeOtherInsurance': 'Other insurance',
      'tns.contractTypeBuildingSavings': 'Building savings',
      'tns.contractTypeSavingsBook': 'Savings book',
      'tns.contractTypeSavingsAccountOrCash': 'Savings account or cash',
      'tns.contractTypeFixedDeposit': 'Fixed deposit',
      'tns.contractTypeBonds': 'Bonds',
      'tns.confirm': 'Confirm',
      'tns.capturePhoto': 'Capture Photo',
      'tns.UploadFile': 'Upload File',
      'tns.CreateNewFolder': 'Create New Folder',
      'tns.clickHereToSelectFile': 'Click here to select file',
      'tns.maximumFileUploaded': 'Max Number of Files Reached',
      'tns.maxFileSizeError': 'Maximum file size is 6 MB.',
      'tns.FolderName': 'Folder Name',
      'tns.EnterFolderName': 'Enter folder name',
      'tns.UPLOAD_SUCCESS': 'File uploaded successfully.',
      'tns.UPLOAD_FAILED': 'File upload failed.',
      'tns.DOWNLOAD_FAILED': 'File download failed.',
      'tns.FOLDER_CREATED': 'Folder created successfully.',
      'tns.FOLDER_CREATE_FAILED': 'Folder creation failed.',
      'tns.title': 'Title',
      'tns.Favorite': 'Favorite',
      'tns.PHOTO_CAPTURE_FAILED': 'Photo capture failed.',
      'tns.deleting': 'Deleting...',
      'tns.editContract': 'Edit Contract',
      'tns.editInsuranceContract': 'Edit Insurance Contract',
      'tns.editRetirementContract': 'Edit Retirement Contract',
      'tns.editLoanContract': 'Edit Loan Contract',
      'tns.editInvestmentContract': 'Edit Investment Contract',
      'tns.deleteContract': 'Delete Contract',
      'tns.deleteHeader': 'Delete this contract?',
      'tns.deleteContractConfirmPrompt':
          'Are you sure you want to delete this contract?',
      'tns.deleteContractBody': 'This action cannot be undone.',
      'tns.contractDeleted': 'Contract deleted successfully.',
      'tns.contractDeleteFailed': 'Unable to delete the contract right now.',
      'tns.contractEditPending': 'Edit action will be connected next.',
      'tns.realEstateOverview': 'My Real Estate overview',
      'tns.realEstateOverviewBody':
          'Manage all real estate and make smart decisions with property tools',
      'common.close': 'Close',
      'dashboard.summaryTitle': 'My Financial Summary',
      'dashboard.explorerTitle': 'FiLiP Explorer',
      'dashboard.totalFixedAsset': 'TOTAL FIXED ASSET',
      'dashboard.slsInvestment': 'SLS INVESTMENT',
      'dashboard.totalMonthlyPremium': 'TOTAL MONTHLY PREMIUM',
      'dashboard.totalLiabilities': 'TOTAL LIABILITIES',
      'explorer.tileDrive': 'Drive',
      'explorer.oneStopSolution':
          'One stop solution to handle all your Financial needs.',
      'explorer.slider.contracts.title': 'Manage my contracts in FiLiP',
      'explorer.slider.contracts.description':
          'Get real time updates of your Insurance, Retirement, Investment and other contracts.',
      'explorer.slider.realEstate.title': 'My real estate overview',
      'explorer.slider.realEstate.description':
          'With FiLiP, you can now monitor, value, and search all properties and make smarter decisions with real-estate tools.',
      'explorer.slider.drive.title': 'My documents at a glance',
      'explorer.slider.drive.description':
          'Upload and manage all important documents in your document area.',
      'explorer.slider.message.title': 'Chat with your advisor',
      'explorer.slider.message.description':
          'Use FiLiP to communicate with your advisor more easily anytime and anywhere.',
      'dashboard.totalInvestment': 'Total Investment',
      'dashboard.currentInvestmentDistribution':
          'Current Investment Distribution',
      'dashboard.monthlyPremium': 'Monthly Premium',
      'dashboard.monthlyPremiumDistribution': 'Monthly Premium Distribution',
      'dashboard.monthlyPayment': 'Monthly Payment',
      'dashboard.yearlyPayment': 'Yearly Payment',
      'dashboard.monthlyPensionDistribution': 'Monthly Pension Distribution',
      'dashboard.noDataAdded': 'No chart data found',
      'dashboard.otherCategories': 'Other Categories',
      'dashboard.investmentPortalUnavailable':
          'The investment portal is not available right now.',
      'dashboard.investmentPortalOpenFailed':
          'Unable to open the investment portal right now.',
      'dashboard.navDashboard': 'Dashboard',
      'dashboard.navContracts': 'Contracts',
      'dashboard.navRealEstate': 'My Real Estate',
      'dashboard.navMessage': 'Message',
      'dashboard.drawerTagline': 'Financial Life Planner',
      'dashboard.drawerAccount': 'MY ACCOUNT',
      'dashboard.drawerPreferences': 'PREFERENCES',
      'dashboard.drawerHousehold': 'HOUSEHOLD',
      'dashboard.drawerSurvey': 'SURVEY',
      'dashboard.drawerSupport': 'SUPPORT',
      'dashboard.drawerAbout': 'ABOUT',
      'dashboard.drawerLogout': 'LOG OUT',
      'dashboard.drawerLegal': 'LEGAL',
      'dashboard.drawerDataPrivacy': 'DATA PRIVACY',
      'dashboard.drawerBrand': 'Swiss Life Select',
      'common.oclock': "o'clock",
      'common.month.1': 'January',
      'common.month.2': 'February',
      'common.month.3': 'March',
      'common.month.4': 'April',
      'common.month.5': 'May',
      'common.month.6': 'June',
      'common.month.7': 'July',
      'common.month.8': 'August',
      'common.month.9': 'September',
      'common.month.10': 'October',
      'common.month.11': 'November',
      'common.month.12': 'December',
      'support.title': 'Support',
      'support.hours': 'Monday to Friday (09:00 to 17:00)',
      'support.email': 'filip@swisslife-select.at',
      'about.title': 'About',
      'about.version': 'FiLiP App Version',
      'about.copyright': '© Swiss Life Select',
      'about.allRightsReserved': 'All rights reserved.',
      'about.technologyDesign': 'Technology & Design by',
      'about.selise': 'SELISE Digital Platforms',
      'about.imprint': 'IMPRINT',
      'about.dataPrivacy': 'DATA PRIVACY',
      'about.legal': 'LEGAL',
      'advisor.title': 'My Financial Advisor',
      'advisor.noAdvisorAssigned': 'No advisor assigned',
      'advisor.noAdvisorDescription':
          'No financial advisor is currently assigned to this profile.',
      'advisor.noEmail': 'No advisor email address is available.',
      'advisor.noPhone': 'No advisor phone number is available.',
      'advisor.openEmailFailed': 'Unable to open the email app right now.',
      'advisor.openPhoneFailed': 'Unable to open the phone app right now.',
      'page.contracts.title': 'Contracts',
      'page.contracts.description':
          'Use this module for customer contracts, archived contracts, insurance details, and investment contract journeys.',
      'page.documents.title': 'Documents',
      'page.documents.description':
          'Document manager, PDF viewing, uploads, and signatures will live here.',
      'page.investments.title': 'Investments',
      'page.investments.description':
          'Investment contracts and related detail modules will live here.',
      'page.notifications.title': 'Notifications',
      'page.notifications.description':
          'Push notifications, inbox, and alert settings will live here.',
      'tns.notification': 'Notification',
      'tns.youDontHaveNotification': 'You do not have any notifications.',
      'tns.notificationLoadError':
          'Notifications could not be loaded right now.',
      'tns.justNow': 'just now',
      'tns.contractsAddedNotificationSubtitle':
          'contract added through synchronization or advisor',
      'tns.contractsUpdateNotificationSubtitle': 'contract will be expiring on',
      'tns.esignNotificationSubtitle': 'document has received for eSignature',
      'CONTRACT_ADDED': 'Contract Added',
      'CONTRACT_UPDATE': 'Contract update',
      'NEW_SIGNATURE_DOCUMENT_UPLOADED': 'New document to sign!',
      'SLS_INVESTMENT_NOTIFICATION_TITLE': 'More clarity for you',
      'SLS_INVESTMENT_NOTIFICATION_SUB_TITLE':
          'Your total SLS investment is now shown in a more prominent spot in the overview.',
      'value1_value2_ago': '{{value1}} {{value2}} ago',
      'hour': 'hour',
      'hours': 'hours',
      'min': 'min',
      'mins': 'mins',
      'day': 'day',
      'days': 'days',
      'page.profile.title': 'Profile',
      'page.profile.description':
          'My account, household, preferences, and account settings will live here.',
      'page.realEstate.title': 'Real Estate',
      'page.realEstate.description':
          'Property search, valuation, and real estate advisory flows will live here.',
      'page.retirement.title': 'Retirement',
      'page.retirement.description':
          'Retirement dashboards, detail pages, and planning flows will live here.',
      'page.loans.title': 'Loans',
      'page.loans.description':
          'Loan dashboard and loan detail journeys will live here.',
      'page.support.title': 'Support',
      'page.support.description':
          'Support, survey, chat, and help-related modules will live here.',
      'page.chat.title': 'Chat',
      'page.chat.description':
          'Advisor chat and conversation threads will live here.',
    },
    'de': <String, String>{
      'common.loading': 'Laden...',
      'common.selectLanguage': 'Sprachauswahl',
      'common.english': 'English',
      'common.german': 'German',
      'login.genericError':
          'Anmeldung ist derzeit nicht moglich. Bitte versuchen Sie es erneut.',
      'login.welcome': 'Willkommen beim Financial\nLife Planner',
      'login.email': 'E-Mail',
      'login.emailHint': 'E-Mail eingeben',
      'login.emailRequired': 'Bitte E-Mail eingeben',
      'login.password': 'Passwort',
      'login.passwordHint': 'Passwort eingeben',
      'login.passwordRequired': 'Bitte Passwort eingeben',
      'login.rememberMe': 'Angemeldet bleiben',
      'login.forgotPassword': 'Passwort vergessen?',
      'login.logIn': 'ANMELDEN',
      'login.noAccount': 'Sie haben noch kein Konto? ',
      'login.createNow': 'JETZT ERSTELLEN',
      'forgotPassword.title': 'Passwort vergessen',
      'forgotPassword.description':
          'Der Passwort-zurucksetzen-Ablauf ist das nachste Login-Element, das aus der NativeScript-App portiert wird.',
      'settings.title': 'Einstellungen',
      'settings.languageHeader': 'Sprachauswahl',
      'preferences.title': 'Einstellungen',
      'preferences.biometricTitle': 'Biometrie',
      'preferences.biometricDescription':
          'Erlauben Sie den biometrischen Fingerabdruckscan Ihres Geräts für eine einfache Anmeldung in der FiLiP Mobile App.',
      'preferences.pinTitle': 'PIN',
      'preferences.pinDescription':
          'Legen Sie eine Recovery-PIN fest für den Fall falscher biometrischer Fingerabdruck- oder Face-ID-Versuche',
      'preferences.resetPin': 'PIN ZURÜCKSETZEN',
      'preferences.actionPending':
          'Diese Einstellungen-Aktion ist in Flutter noch nicht verfügbar.',
      'account.title': 'Mein Konto',
      'account.fullName': 'Vollständiger Name',
      'account.emailAddress': 'E-Mail-Adresse',
      'account.updateEmail': 'E-MAIL AKTUALISIEREN',
      'account.phoneNumber': 'Telefonnummer',
      'account.updatePhone': 'TELEFON AKTUALISIEREN',
      'account.password': 'Passwort',
      'account.changePassword': 'PASSWORT ÄNDERN',
      'account.preferences': 'Einstellungen',
      'account.consentsTitle': 'Meine Einwilligungen und Präferenzen',
      'account.consentsDescription':
          'Aktualisieren Sie hier Ihre DSGVO-Einwilligungen und E-Mail-Präferenzen',
      'account.deleteAccount': 'FILIP KONTO LÖSCHEN',
      'account.actionPending':
          'Diese Mein-Konto-Aktion ist in Flutter noch nicht verfügbar.',
      'onboarding.skip': 'UBERSPRINGEN',
      'onboarding.startNow': 'JETZT STARTEN',
      'onboarding.manageContracts.title': 'Vertrage verwalten',
      'onboarding.manageContracts.description':
          'Erhalten Sie aktuelle Informationen uber Ihre Veranlagungs-, Versicherungs-, Vorsorge- und Finanzierungsvertrage.',
      'onboarding.realEstate.title': 'Meine Immobilienubersicht',
      'onboarding.realEstate.description':
          'Mit FiLiP konnen Sie jetzt alle Immobilien beobachten, bewerten und suchen und mit Hilfe von Immobilien-Tools intelligente Entscheidungen treffen.',
      'onboarding.documents.title': 'Dokumente im Uberblick',
      'onboarding.documents.description':
          'Hochladen und Verwalten aller wichtigen Dokumente in Ihrem Dokumentenbereich.',
      'onboarding.chat.title': 'Chatten Sie mit Ihrem Berater',
      'onboarding.chat.description':
          'Nutzen Sie FiLiP, um mit Ihrem Berater jederzeit und uberall einfacher zu kommunizieren.',
      'tns.me': 'Ich',
      'tns.household': 'Haushalt',
      'tns.business': 'Business',
      'tns.contractsAvailable': 'Verfugbare Vertrage',
      'tns.leaveHousehold': 'Haushalt auflosen',
      'tns.leaveHouseholdBottomSheetTitle':
          'Ich mochte meinen Haushalt auflosen',
      'tns.leaveHouseholdBottomSheetSubTitle':
          'Ihr Financial Planner wird sich fur die Auflosung ihres Haushalts mit ihnen in Verbindung setzten.',
      'tns.myContracts': 'Meine Vertrage',
      'tns.investment': 'Investment',
      'tns.nonLifeinsurance': 'Versicherung',
      'tns.insurance': 'Versicherung',
      'tns.retirement': 'Vorsorge',
      'tns.loan': 'Finanzierung',
      'tns.investmentContracts': 'Investmentverträge',
      'tns.insuranceContracts': 'Versicherungsverträge',
      'tns.retirementContracts': 'Vorsorgeverträge',
      'tns.loanContracts': 'Kreditverträge',
      'tns.investmentDetails': 'Investment Details',
      'tns.investmentDetailsSubtitle':
          'Sehen Sie sich alle Details Ihrer Investitionen und deren Status in unserem Investment-Cockpit an.',
      'tns.personalPerformance': 'Persönliche Performance',
      'tns.totalInvestment': 'Gesamtes Investment',
      'tns.totalInvestmentSLS': 'Gesamtes SLS Investment',
      'tns.investmentRisk': 'Depotrisiko',
      'tns.investorProfile': 'Anlegerprofil',
      'tns.moneyMarketAccount': 'Geldmarktkonto',
      'tns.clearingAccount': 'Verrechnungskonto',
      'tns.fixedDepositAccounts': 'Festgeldkonten',
      'tns.seeMore': 'mehr anzeigen',
      'tns.seeLess': 'weniger anzeigen',
      'tns.noDataAddedYet': 'Es wurden noch keine Daten eingegeben!',
      'tns.noDataFound': 'Keine Daten gefunden',
      'tns.multipleSelection': 'Mehrfachauswahl',
      'tns.selectAll': 'Alle auswahlen',
      'tns.showContracts': 'Vertrage anzeigen',
      'contracts.householdCannotDeselectAll':
          'Mindestens eine Person muss ausgewahlt bleiben.',
      'tns.importantNotice': 'Wichtiger Hinweis',
      'tns.insureinfotext':
          'Bitte beachten Sie, dass die Vollstandigkeit Ihrer Vertragsdaten von der Datenlieferung Ihres Produktpartners abhangt.',
      'tns.retirementInfoText':
          'Bitte beachten Sie, dass die Vollstandigkeit Ihrer Vertragsdaten von der Datenlieferung Ihres Produktpartners abhangt.',
      'tns.addInvestmentContract': 'Investmentvertrag hinzufugen',
      'tns.addRetirementContract': 'Vorsorgevertrag hinzufugen',
      'tns.formPreviewHint':
          'Dies ist die erste Flutter-Formvorschau fur Vertrage. Die Speicherung kann als nachster Schritt angebunden werden.',
      'tns.contractTitle': 'Vertragstitel',
      'tns.partner': 'Partner',
      'tns.amount': 'Betrag',
      'tns.type': 'Typ',
      'tns.endDate': 'Enddatum',
      'tns.annualPremium': 'Jahrespramie',
      'tns.addInsuranceContract': 'Versicherungsvertrag hinzufugen',
      'tns.addLoanContract': 'Kreditvertrag hinzufugen',
      'tns.create': 'Erstellen',
      'common.retry': 'Erneut versuchen',
      'common.yes': 'Ja',
      'common.no': 'Nein',
      'tns.contractFormLoadFailed':
          'Das Formular zum Hinzufugen des Vertrags konnte derzeit nicht geladen werden.',
      'tns.contractCreateFailed':
          'Der Vertrag konnte derzeit nicht erstellt werden.',
      'tns.fieldRequired': 'Dieses Feld ist erforderlich.',
      'tns.minimumCharacters': 'Bitte mindestens {{count}} Zeichen eingeben.',
      'tns.maximumCharacters':
          'Bitte nicht mehr als {{count}} Zeichen eingeben.',
      'tns.enterValidNumber': 'Bitte eine gueltige Zahl eingeben.',
      'tns.minimumValue': 'Bitte einen Wert ab {{value}} eingeben.',
      'tns.maximumValue': 'Bitte einen Wert bis {{value}} eingeben.',
      'tns.addNOTE': 'Bemerkung',
      'tns.editNOTE': 'Anmerkung bearbeiten',
      'tns.deleteNote': 'Notiz loeschen',
      'tns.deleteNoteConfirmationMessage':
          'Die Aktion wird die Datei permanent loeschen und kann nicht rueckgaengig gemacht werden.',
      'tns.writeTextHere': 'Text hier eintragen',
      'tns.noteUpdateFailed':
          'Die Notiz konnte gerade nicht aktualisiert werden.',
      'tns.contractNumber': 'Vertragsnummer',
      'tns.premiumFrequency': 'Pramienfrequenz',
      'tns.pensionFrequency': 'Pensionsfrequenz',
      'tns.grossPremium': 'Bruttopramie',
      'tns.selectPartner': 'Partner auswahlen',
      'tns.insuranceAmount': 'Versicherungssumme',
      'tns.startDate': 'Startdatum',
      'tns.notes': 'Notizen',
      'tns.dueDate': 'Falligkeitsdatum',
      'tns.status': 'Status',
      'tns.active': 'Aktiv',
      'tns.inactive': 'Inaktiv',
      'tns.unknown': 'Unbekannt',
      'tns.loanType': 'Kredittyp',
      'tns.purposeOfUse': 'Verwendungszweck',
      'tns.bankingInstitute': 'Bankinstitut',
      'tns.loanAmount': 'Kreditbetrag',
      'tns.startOfRepayment': 'Beginn der Ruckzahlung',
      'tns.typeOfInterest': 'Zinsart',
      'tns.fixedInterestRate': 'Fixzinssatz',
      'tns.fixedInterestRateDuration': 'Dauer des Fixzinssatzes',
      'tns.referenceInterestRate': 'Referenzzinssatz',
      'tns.bankSurcharge': 'Bankaufschlag',
      'tns.tradeInValue': 'Tauschwert',
      'tns.remainingLoan': 'Restschuld',
      'tns.dateOfRemainingDebt': 'Datum der Restschuld',
      'tns.loanConclusionDate': 'Darlehensabschluss',
      'tns.contractDetails': 'Vertragsdetails',
      'tns.paymentMethod': 'Zahlungsweise',
      'tns.targetSumSavingsPlan': 'Zielsparplan',
      'tns.lumpSumInvestment': 'Einmalanlage',
      'tns.risk': 'Risiko',
      'tns.isin': 'ISIN',
      'tns.currentValue': 'Aktueller Wert',
      'tns.currentShareValue': 'Aktueller Anteilspreis',
      'tns.currentValueDate': 'Datum aktueller Wert',
      'tns.numberOfShares': 'Anzahl Anteile',
      'tns.couponRate': 'Kuponrate',
      'tns.couponPeriod': 'Kuponperiode',
      'tns.couponType': 'Kuponart',
      'tns.issuer': 'Emittent',
      'tns.bondPrice': 'Anleihekurs',
      'tns.bondPriceDate': 'Datum Anleihekurs',
      'tns.currency': 'Wahrung',
      'tns.iban': 'IBAN',
      'tns.bic': 'BIC',
      'tns.premiumBenefit': 'Pramienvorteil',
      'tns.interestRate': 'Zinssatz',
      'tns.bookValueBond': 'Buchwert',
      'tns.investmentAmount': 'Investmentbetrag',
      'tns.bookValue': 'Buchwert',
      'tns.priceDate': 'Kursdatum',
      'tns.valueAtOpening': 'Wert bei Eroffnung',
      'tns.purchaseDate': 'Kaufdatum',
      'tns.maturityDate': 'Falligkeit',
      'tns.accountNumber': 'Kontonummer',
      'tns.edit': 'Bearbeiten',
      'tns.delete': 'Loeschen',
      'tns.save': 'Speichern',
      'tns.cancel': 'Abbrechen',
      'tns.ok': 'OK',
      'tns.monthly': 'Monatlich',
      'tns.quarterly': 'Vierteljaehrlich',
      'tns.halfYearly': 'Halbjaehrlich',
      'tns.annually': 'Jaehrlich',
      'tns.oneTime': 'Einmalig',
      'tns.semiAnnually': 'Halbjaehrlich',
      'tns.once': 'Einmal',
      'tns.otherUnknown': 'Andere, unbekannt',
      'tns.variable': 'Variabel',
      'tns.fixed': 'Fest',
      'tns.euribor3m': '3-Monats-Euribor',
      'tns.euribor6m': '6-Monats-Euribor',
      'tns.euribor12m': '12-Monats-Euribor',
      'tns.primeRate': 'Prime Rate',
      'tns.fixedRate': 'Fester Satz',
      'tns.stepUpRate': 'Stufenweise steigend',
      'tns.variableRate': 'Variabler Satz',
      'tns.zeroCoupon': 'Nullkupon',
      'tns.other': 'Andere',
      'tns.contractTypeHomeownersInsurance': 'Wohngebaeudeversicherung',
      'tns.contractTypeHouseholdInsurance': 'Haushaltsversicherung',
      'tns.contractTypeHouseholdAndHomeInsurance':
          'Haushalt- und Wohngebaeudeversicherung',
      'tns.contractTypeLegalProtectionInsurance': 'Rechtsschutzversicherung',
      'tns.contractTypeCarInsurance': 'Autoversicherung',
      'tns.contractTypeOtherInsurance': 'Sonstige Versicherung',
      'tns.contractTypeBuildingSavings': 'Bausparen',
      'tns.contractTypeSavingsBook': 'Sparbuch',
      'tns.contractTypeSavingsAccountOrCash': 'Sparkonto oder Bargeld',
      'tns.contractTypeFixedDeposit': 'Festgeld',
      'tns.contractTypeBonds': 'Anleihen',
      'tns.confirm': 'Bestaetigen',
      'tns.capturePhoto': 'Foto aufnehmen',
      'tns.UploadFile': 'Datei hochladen',
      'tns.CreateNewFolder': 'Neuen Ordner erstellen',
      'tns.clickHereToSelectFile': 'Hier tippen, um Datei auszuwahlen',
      'tns.maximumFileUploaded': 'Maximale Dateianzahl erreicht',
      'tns.maxFileSizeError': 'Maximale Dateigrosse ist 6 MB.',
      'tns.FolderName': 'Ordnername',
      'tns.EnterFolderName': 'Ordnernamen eingeben',
      'tns.UPLOAD_SUCCESS': 'Datei erfolgreich hochgeladen.',
      'tns.UPLOAD_FAILED': 'Datei-Upload fehlgeschlagen.',
      'tns.DOWNLOAD_FAILED': 'Datei-Download fehlgeschlagen.',
      'tns.FOLDER_CREATED': 'Ordner erfolgreich erstellt.',
      'tns.FOLDER_CREATE_FAILED': 'Ordner konnte nicht erstellt werden.',
      'tns.title': 'Titel',
      'tns.Favorite': 'Favorit',
      'tns.PHOTO_CAPTURE_FAILED': 'Fotoaufnahme fehlgeschlagen.',
      'tns.deleting': 'Wird geloescht...',
      'tns.editContract': 'Vertrag bearbeiten',
      'tns.editInsuranceContract': 'Versicherungsvertrag bearbeiten',
      'tns.editRetirementContract': 'Vorsorgevertrag bearbeiten',
      'tns.editLoanContract': 'Kreditvertrag bearbeiten',
      'tns.editInvestmentContract': 'Anlagevertrag bearbeiten',
      'tns.deleteContract': 'Vertrag loeschen',
      'tns.deleteHeader': 'Diesen Vertrag loeschen?',
      'tns.deleteContractConfirmPrompt':
          'Moechten Sie diesen Vertrag wirklich loeschen?',
      'tns.deleteContractBody':
          'Diese Aktion kann nicht rueckgaengig gemacht werden.',
      'tns.contractDeleted': 'Vertrag wurde geloescht.',
      'tns.contractDeleteFailed':
          'Der Vertrag konnte derzeit nicht geloescht werden.',
      'tns.contractEditPending':
          'Die Bearbeiten-Aktion wird als naechstes eingebunden.',
      'tns.realEstateOverview': 'Meine Immobilienubersicht',
      'tns.realEstateOverviewBody':
          'Verwalten Sie alle Immobilien und treffen Sie kluge Entscheidungen mit Immobilien-Tools',
      'common.close': 'Schliessen',
      'dashboard.summaryTitle': 'Meine Finanzubersicht',
      'dashboard.explorerTitle': 'FiLiP Explorer',
      'dashboard.totalFixedAsset': 'GESAMTVERMOGEN',
      'dashboard.slsInvestment': 'SLS INVESTMENT',
      'dashboard.totalMonthlyPremium': 'GESAMTE MONATSPRAMIE',
      'dashboard.totalLiabilities': 'GESAMTVERBINDLICHKEITEN',
      'explorer.tileDrive': 'Drive',
      'explorer.oneStopSolution':
          'Eine Losung um alle finanziellen Bedurfnisse zu erledigen.',
      'explorer.slider.contracts.title': 'Meine Vertrage in FiLiP verwalten',
      'explorer.slider.contracts.description':
          'Erhalten Sie Echtzeit-Updates zu Ihren Versicherungs-, Vorsorge-, Anlage- und anderen Vertragen.',
      'explorer.slider.realEstate.title': 'Meine Immobilienubersicht',
      'explorer.slider.realEstate.description':
          'Mit FiLiP konnen Sie alle Immobilien uberwachen, bewerten und suchen und mit Immobilien-Tools smartere Entscheidungen treffen.',
      'explorer.slider.drive.title': 'Meine Dokumente auf einen Blick',
      'explorer.slider.drive.description':
          'Laden Sie alle wichtigen Dokumente in Ihrem Dokumentenbereich hoch und verwalten Sie sie.',
      'explorer.slider.message.title': 'Chat mit Ihrem Berater',
      'explorer.slider.message.description':
          'Nutzen Sie FiLiP, um einfacher jederzeit und uberall mit Ihrem Berater zu kommunizieren.',
      'dashboard.totalInvestment': 'Gesamtinvestment',
      'dashboard.currentInvestmentDistribution':
          'Aktuelle Investmentverteilung',
      'dashboard.monthlyPremium': 'Monatspramie',
      'dashboard.monthlyPremiumDistribution': 'Verteilung der Monatspramie',
      'dashboard.monthlyPayment': 'Monatliche Zahlung',
      'dashboard.yearlyPayment': 'Jahrliche Zahlung',
      'dashboard.monthlyPensionDistribution': 'Verteilung der Monatspension',
      'dashboard.noDataAdded': 'Keine Diagrammdaten gefunden',
      'dashboard.otherCategories': 'Weitere Kategorien',
      'dashboard.investmentPortalUnavailable':
          'Das Investment-Portal ist derzeit nicht verfugbar.',
      'dashboard.investmentPortalOpenFailed':
          'Das Investment-Portal konnte derzeit nicht geoffnet werden.',
      'dashboard.navDashboard': 'Dashboard',
      'dashboard.navContracts': 'Vertrage',
      'dashboard.navRealEstate': 'Immobilien',
      'dashboard.navMessage': 'Nachrichten',
      'dashboard.drawerTagline': 'Financial Life Planner',
      'dashboard.drawerAccount': 'MEIN KONTO',
      'dashboard.drawerPreferences': 'EINSTELLUNGEN',
      'dashboard.drawerHousehold': 'HAUSHALT',
      'dashboard.drawerSurvey': 'UMFRAGE',
      'dashboard.drawerSupport': 'SUPPORT',
      'dashboard.drawerAbout': 'ÜBER UNS',
      'dashboard.drawerLogout': 'ABMELDEN',
      'dashboard.drawerLegal': 'RECHTLICHES',
      'dashboard.drawerDataPrivacy': 'DATENSCHUTZ',
      'dashboard.drawerBrand': 'Swiss Life Select',
      'common.oclock': 'Uhr',
      'common.month.1': 'Januar',
      'common.month.2': 'Februar',
      'common.month.3': 'März',
      'common.month.4': 'April',
      'common.month.5': 'Mai',
      'common.month.6': 'Juni',
      'common.month.7': 'Juli',
      'common.month.8': 'August',
      'common.month.9': 'September',
      'common.month.10': 'Oktober',
      'common.month.11': 'November',
      'common.month.12': 'Dezember',
      'support.title': 'Support',
      'support.hours': 'Montag bis Freitag (09:00 bis 17:00)',
      'support.email': 'filip@swisslife-select.at',
      'about.title': 'Über uns',
      'about.version': 'FiLiP App Version',
      'about.copyright': '© Swiss Life Select',
      'about.allRightsReserved': 'Alle Rechte vorbehalten.',
      'about.technologyDesign': 'Technologie & Design von',
      'about.selise': 'SELISE Digital Platforms',
      'about.imprint': 'IMPRESSUM',
      'about.dataPrivacy': 'DATENSCHUTZ',
      'about.legal': 'RECHTLICHES',
      'advisor.title': 'Mein Finanzberater',
      'advisor.noAdvisorAssigned': 'Kein Berater zugewiesen',
      'advisor.noAdvisorDescription':
          'Diesem Profil ist derzeit kein Finanzberater zugewiesen.',
      'advisor.noEmail': 'Keine E-Mail-Adresse des Beraters verfugbar.',
      'advisor.noPhone': 'Keine Telefonnummer des Beraters verfugbar.',
      'advisor.openEmailFailed':
          'Die E-Mail-App konnte derzeit nicht geoffnet werden.',
      'advisor.openPhoneFailed':
          'Die Telefon-App konnte derzeit nicht geoffnet werden.',
      'page.contracts.title': 'Vertrage',
      'page.contracts.description':
          'Hier werden Kundenvertrage, archivierte Vertrage, Versicherungsdetails und Investment-Vertragswege eingebunden.',
      'page.documents.title': 'Dokumente',
      'page.documents.description':
          'Dokumentenverwaltung, PDF-Ansicht, Uploads und Signaturen werden hier eingebunden.',
      'page.investments.title': 'Investments',
      'page.investments.description':
          'Investmentvertrage und zugehorige Detailmodule werden hier eingebunden.',
      'page.notifications.title': 'Benachrichtigungen',
      'page.notifications.description':
          'Push-Benachrichtigungen, Inbox und Benachrichtigungseinstellungen werden hier eingebunden.',
      'tns.notification': 'Benachrichtigung',
      'tns.youDontHaveNotification': 'Sie haben keine Benachrichtigungen.',
      'tns.notificationLoadError':
          'Benachrichtigungen konnten derzeit nicht geladen werden.',
      'tns.justNow': 'jetzt',
      'tns.contractsAddedNotificationSubtitle':
          'Ein Vertrag wurde durch das System oder den Berater hinzugefügt.',
      'tns.contractsUpdateNotificationSubtitle': 'Vertrag läuft aus am',
      'tns.esignNotificationSubtitle': 'Dokument für Unterschrift erhalten',
      'CONTRACT_ADDED': 'Vertrag hinzugefügt',
      'CONTRACT_UPDATE': 'Vertragsaktualisierung',
      'NEW_SIGNATURE_DOCUMENT_UPLOADED': 'Neues Dokument zum Unterschreiben!',
      'SLS_INVESTMENT_NOTIFICATION_TITLE': 'Mehr Überblick für Sie',
      'SLS_INVESTMENT_NOTIFICATION_SUB_TITLE':
          'Ihre Gesamtsumme im SLS Investment sehen Sie jetzt noch prominenter in der Übersicht.',
      'value1_value2_ago': '{{value1}} {{value2}} vergangen',
      'hour': 'Stunde',
      'hours': 'Stunden',
      'min': 'Minute',
      'mins': 'Minuten',
      'day': 'Tag',
      'days': 'Tage',
      'page.profile.title': 'Profil',
      'page.profile.description':
          'Mein Konto, Haushalt, Einstellungen und Kontokonfiguration werden hier eingebunden.',
      'page.realEstate.title': 'Immobilien',
      'page.realEstate.description':
          'Immobiliensuche, Bewertung und Immobilienberatungsablaufe werden hier eingebunden.',
      'page.retirement.title': 'Vorsorge',
      'page.retirement.description':
          'Vorsorge-Dashboards, Detailseiten und Planungsablaufe werden hier eingebunden.',
      'page.loans.title': 'Finanzierungen',
      'page.loans.description':
          'Finanzierungs-Dashboard und Detailablaufe werden hier eingebunden.',
      'page.support.title': 'Support',
      'page.support.description':
          'Support-, Umfrage-, Chat- und Hilfemodule werden hier eingebunden.',
      'page.chat.title': 'Chat',
      'page.chat.description':
          'Berater-Chat und Konversationsverlaufe werden hier eingebunden.',
    },
  };

  static AppLocalizations of(BuildContext context) {
    final localizations = Localizations.of<AppLocalizations>(
      context,
      AppLocalizations,
    );
    assert(localizations != null, 'No AppLocalizations found in context.');
    return localizations!;
  }

  bool get isGerman => locale.languageCode == 'de';

  String tr(String key, [Map<String, String>? replacements]) {
    final localizedMap = _localizedValues[locale.languageCode];
    final fallbackMap = _localizedValues[fallbackLocale.languageCode]!;
    var value =
        localizedMap?[key] ??
        _resolveWithPrefixFallback(localizedMap, key) ??
        fallbackMap[key] ??
        _resolveWithPrefixFallback(fallbackMap, key) ??
        key;
    if (replacements != null) {
      replacements.forEach((replacementKey, replacementValue) {
        value = value.replaceAll('{{$replacementKey}}', replacementValue);
      });
    }
    return value;
  }

  String resolve(String keyOrValue) {
    if (_localizedValues[fallbackLocale.languageCode]!.containsKey(
      keyOrValue,
    )) {
      return tr(keyOrValue);
    }
    return keyOrValue;
  }

  String trBestEffort(String value) {
    final raw = value.trim();
    if (raw.isEmpty) {
      return value;
    }

    final upperSnake = raw
        .replaceAll(RegExp(r'[^A-Za-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '')
        .toUpperCase();
    final lower = raw.toLowerCase();
    final lowerSnake = upperSnake.toLowerCase();

    final candidates = <String>{
      raw,
      upperSnake,
      lower,
      lowerSnake,
      'tns.$raw',
      'tns.$lower',
      'tns.$lowerSnake',
      'FREQ_$upperSnake',
    };

    for (final key in candidates) {
      if (_hasTranslationForKey(key)) {
        return tr(key);
      }
    }

    return value;
  }

  bool _hasTranslationForKey(String key) {
    final localizedMap = _localizedValues[locale.languageCode];
    final fallbackMap = _localizedValues[fallbackLocale.languageCode]!;
    return localizedMap?.containsKey(key) == true ||
        fallbackMap.containsKey(key) ||
        _resolveWithPrefixFallback(localizedMap, key) != null ||
        _resolveWithPrefixFallback(fallbackMap, key) != null;
  }

  String? _resolveWithPrefixFallback(
    Map<String, String>? localizedMap,
    String key,
  ) {
    if (localizedMap == null) {
      return null;
    }
    if (key.startsWith('tns.')) {
      return localizedMap[key.substring(4)];
    }
    return localizedMap['tns.$key'];
  }

  static Future<Map<String, String>> _loadLanguageJson(
    String languageCode,
  ) async {
    final source = await rootBundle.loadString(
      'assets/i18n/$languageCode.json',
    );
    final decoded = jsonDecode(source);
    if (decoded is! Map<String, dynamic>) {
      return const <String, String>{};
    }
    return _flattenJson(decoded);
  }

  static Map<String, String> _flattenJson(Map<String, dynamic> source) {
    final result = <String, String>{};

    void visit(Map<String, dynamic> node, [String prefix = '']) {
      node.forEach((key, value) {
        final nextKey = prefix.isEmpty ? key : '$prefix.$key';
        if (value is Map<String, dynamic>) {
          visit(value, nextKey);
          return;
        }
        result[nextKey] = value?.toString() ?? '';
      });
    }

    visit(source);
    return result;
  }
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return AppLocalizations.supportedLocales.any(
      (supportedLocale) => supportedLocale.languageCode == locale.languageCode,
    );
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    final languageCode = locale.languageCode;
    final fallbackCode = AppLocalizations.fallbackLocale.languageCode;
    final localizedValues = <String, Map<String, String>>{
      for (final entry in AppLocalizations._fallbackLocalizedValues.entries)
        entry.key: <String, String>{...entry.value},
    };

    try {
      localizedValues[fallbackCode] = <String, String>{
        ...localizedValues[fallbackCode] ?? const <String, String>{},
        ...await AppLocalizations._loadLanguageJson(fallbackCode),
      };
      localizedValues[languageCode] = <String, String>{
        ...localizedValues[languageCode] ?? const <String, String>{},
        ...await AppLocalizations._loadLanguageJson(languageCode),
      };
    } catch (_) {
      // Keep app running with in-code fallback translations.
    }

    return AppLocalizations(locale, localizedValues);
  }

  @override
  bool shouldReload(covariant LocalizationsDelegate<AppLocalizations> old) {
    return false;
  }
}

extension AppLocalizationContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
