import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'api_service.dart';

class RevenueCatService {
  static const _androidKey = 'goog_WRXqiydNgOjqkmqvhWLaUoLLmPg';
  // iOS key — dodaj kad budeš radio iOS build
  static const _iosKey = 'PASTE_IOS_KEY_HERE';

  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;
    await Purchases.setLogLevel(kDebugMode ? LogLevel.debug : LogLevel.error);
    final config = PurchasesConfiguration(
      Platform.isIOS ? _iosKey : _androidKey,
    );
    await Purchases.configure(config);
    _initialized = true;
  }

  /// Returns true if user has active 'lastwish Pro' entitlement
  static Future<bool> isPro() async {
    try {
      final info = await Purchases.getCustomerInfo();
      return info.entitlements.active.containsKey('lastwish Pro');
    } catch (e) {
      debugPrint('REVENUECAT isPro ERROR: $e');
      return false;
    }
  }

  /// Fetch current offering packages
  static Future<List<Package>> getPackages() async {
    try {
      final offerings = await Purchases.getOfferings();
      return offerings.current?.availablePackages ?? [];
    } catch (e) {
      debugPrint('REVENUECAT getPackages ERROR: $e');
      return [];
    }
  }

  /// Purchase a package, returns true on success
  static Future<bool> purchase(Package package) async {
    try {
      final result = await Purchases.purchase(PurchaseParams.package(package));
      final hasPro = result.customerInfo.entitlements.active.containsKey('lastwish Pro');
      if (hasPro) {
        // Sync is_pro to backend
        await ApiService.syncProStatus(isPro: true);
      }
      return hasPro;
    } on PurchasesErrorCode catch (e) {
      if (e == PurchasesErrorCode.purchaseCancelledError) return false;
      debugPrint('REVENUECAT purchase ERROR: $e');
      return false;
    } catch (e) {
      debugPrint('REVENUECAT purchase ERROR: $e');
      return false;
    }
  }

  /// Restore purchases (for reinstalls)
  static Future<bool> restore() async {
    try {
      final info = await Purchases.restorePurchases();
      final hasPro = info.entitlements.active.containsKey('lastwish Pro');
      await ApiService.syncProStatus(isPro: hasPro);
      return hasPro;
    } catch (e) {
      debugPrint('REVENUECAT restore ERROR: $e');
      return false;
    }
  }

  /// Identify user (call after login)
  static Future<void> identify(String userId) async {
    try {
      await Purchases.logIn(userId);
    } catch (e) {
      debugPrint('REVENUECAT identify ERROR: $e');
    }
  }

  /// Logout (call on app logout)
  static Future<void> logout() async {
    try {
      await Purchases.logOut();
    } catch (e) {
      debugPrint('REVENUECAT logout ERROR: $e');
    }
  }
}
