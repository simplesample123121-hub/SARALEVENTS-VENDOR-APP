import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'checkout_state.dart';
import 'screens.dart';

class CheckoutFlow extends StatelessWidget {
  final CartItem initialItem;
  CheckoutFlow({super.key, required this.initialItem});

  final GlobalKey<NavigatorState> _navKey = GlobalKey<NavigatorState>();

  static Route<void> routeWithItem(CartItem item) {
    return MaterialPageRoute<void>(
      builder: (_) => ChangeNotifierProvider(
        create: (_) {
          final state = CheckoutState();
          state.addItem(item);
          return state;
        },
        child: CheckoutFlow(initialItem: item),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final checkoutState = context.watch<CheckoutState>();
    return ChangeNotifierProvider.value(
      value: checkoutState,
      child: Navigator(
        key: _navKey,
        onGenerateRoute: (settings) {
          return MaterialPageRoute(builder: (innerCtx) {
            return CartPage(
              onNext: () {
                _navKey.currentState!.push(MaterialPageRoute(builder: (innerCtx2) {
                  return PaymentDetailsPage(
                    onChoosePayment: () {
                      _navKey.currentState!.push(MaterialPageRoute(builder: (innerCtx3) {
                        return PaymentMethodPage(onNext: () {
                          _navKey.currentState!.push(MaterialPageRoute(builder: (innerCtx4) {
                            return PaymentSummaryPage(onNext: () {
                              _navKey.currentState!..pop()..pop()..pop()..pop();
                            });
                          }));
                        });
                      }));
                    },
                    onNext: () {
                      _navKey.currentState!.push(MaterialPageRoute(builder: (innerCtx5) {
                        return PaymentSummaryPage(onNext: () {
                          _navKey.currentState!.push(MaterialPageRoute(builder: (innerCtx6) {
                            return PaymentMethodPage(onNext: () {
                              _navKey.currentState!..pop()..pop()..pop()..pop();
                            });
                          }));
                        });
                      }));
                    },
                  );
                }));
              },
            );
          });
        },
      ),
    );
  }
}


