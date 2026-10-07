import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'auth_service.dart';

class PurchaseService {
  static final InAppPurchase _iap = InAppPurchase.instance;
  static StreamSubscription<List<PurchaseDetails>>? _subscription;

  static const String monthlyID = 'segurcel_pro_monthly';
  static const String yearlyID = 'segurcel_pro_yearly';

  static const Set<String> productIDs = {monthlyID, yearlyID};

  /// Inicializa el oyente del flujo de compras In-App de Google Play
  static void initializePurchaseListener() {
    _subscription?.cancel();
    _subscription = _iap.purchaseStream.listen(
      _onPurchaseUpdated,
      onDone: () => _subscription?.cancel(),
      onError: (e) => debugPrint('[InAppPurchase Error] $e'),
    );
  }

  /// Procesa los eventos de compra (completada, restaurada o fallida)
  static Future<void> _onPurchaseUpdated(List<PurchaseDetails> purchaseDetailsList) async {
    for (final purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.pending) {
        debugPrint('[InAppPurchase] Pendiente de pago en Google Play...');
      } else if (purchaseDetails.status == PurchaseStatus.error) {
        debugPrint('[InAppPurchase Error] ${purchaseDetails.error}');
        if (purchaseDetails.pendingCompletePurchase) {
          await _iap.completePurchase(purchaseDetails);
        }
      } else if (purchaseDetails.status == PurchaseStatus.purchased ||
          purchaseDetails.status == PurchaseStatus.restored) {
        // Activa la suscripción Premium en Firestore
        await _deliverProduct(purchaseDetails);

        if (purchaseDetails.pendingCompletePurchase) {
          await _iap.completePurchase(purchaseDetails);
        }
      }
    }
  }

  /// Activa Premium en Firestore para el usuario activo
  static Future<void> _deliverProduct(PurchaseDetails purchaseDetails) async {
    final user = AuthService().currentUser;
    if (user == null) return;

    try {
      final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
      await userRef.set({
        'isPremium': true,
        'subscriptionType': purchaseDetails.productID,
        'purchaseToken': purchaseDetails.verificationData.serverVerificationData,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      debugPrint('[InAppPurchase Success] ¡Suscripción Premium activada para ${user.uid}!');
    } catch (e) {
      debugPrint('[InAppPurchase Delivery Error] $e');
    }
  }

  /// Lanza el flujo oficial de compra In-App de Google Play
  static Future<bool> buyProduct(ProductDetails productDetails) async {
    try {
      final purchaseParam = PurchaseParam(productDetails: productDetails);
      return await _iap.buyConsumable(purchaseParam: purchaseParam);
    } catch (e) {
      debugPrint('[InAppPurchase Buy Error] $e');
      return false;
    }
  }

  /// Solicita el listado oficial de precios y productos desde Google Play Console
  static Future<List<ProductDetails>> fetchProducts() async {
    final bool available = await _iap.isAvailable();
    if (!available) return [];

    final response = await _iap.queryProductDetails(productIDs);
    return response.productDetails;
  }

  /// Restaura las compras de usuarios que hayan cambiado o formateado su celular
  static Future<void> restorePurchases() async {
    try {
      await _iap.restorePurchases();
    } catch (e) {
      debugPrint('[InAppPurchase Restore Error] $e');
    }
  }

  static void dispose() {
    _subscription?.cancel();
  }
}
