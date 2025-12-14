import 'package:flutter_test/flutter_test.dart';
import 'package:foodapp/data/models/cart.dart';
import 'package:foodapp/data/models/cart_item.dart';

void main() {
  group('CartItem', () {
    test('totalPrice should calculate price * quantity correctly', () {
      final cartItem = CartItem(
        foodId: 'food1',
        name: 'Burger',
        price: 50,
        quantity: 3,
        image: 'burger.jpg',
        restaurantId: 'rest1',
      );

      expect(cartItem.totalPrice, 150);
    });

    test('totalPrice should be 0 when quantity is 0', () {
      final cartItem = CartItem(
        foodId: 'food1',
        name: 'Burger',
        price: 50,
        quantity: 0,
        image: 'burger.jpg',
        restaurantId: 'rest1',
      );

      expect(cartItem.totalPrice, 0);
    });

    test('copyWith should update quantity correctly', () {
      final cartItem = CartItem(
        foodId: 'food1',
        name: 'Burger',
        price: 50,
        quantity: 2,
        image: 'burger.jpg',
        restaurantId: 'rest1',
      );

      final updatedItem = cartItem.copyWith(quantity: 5);

      expect(updatedItem.quantity, 5);
      expect(updatedItem.name, 'Burger'); 
      expect(updatedItem.totalPrice, 250); 
    });
  });

  group('Cart', () {
    test('total should calculate subtotal + deliveryFee + taxes', () {
      final cart = Cart(
        userId: 'user1',
        items: [],
        subtotal: 100,
        deliveryFee: 20,
        taxes: 10,
      );

      expect(cart.total, 130);
    });

    test('total should use default values for deliveryFee and taxes', () {
      final cart = Cart(
        userId: 'user1',
        items: [],
        subtotal: 100,
      );

      expect(cart.total, 130); 
      expect(cart.deliveryFee, 20);
      expect(cart.taxes, 10);
    });

    test('totalItems should sum all item quantities', () {
      final items = [
        CartItem(
          foodId: 'food1',
          name: 'Burger',
          price: 50,
          quantity: 2,
          image: 'burger.jpg',
          restaurantId: 'rest1',
        ),
        CartItem(
          foodId: 'food2',
          name: 'Pizza',
          price: 80,
          quantity: 3,
          image: 'pizza.jpg',
          restaurantId: 'rest1',
        ),
        CartItem(
          foodId: 'food3',
          name: 'Fries',
          price: 30,
          quantity: 1,
          image: 'fries.jpg',
          restaurantId: 'rest1',
        ),
      ];

      final cart = Cart(
        userId: 'user1',
        items: items,
        subtotal: 370,
      );

      expect(cart.totalItems, 6); 
    });

    test('totalItems should be 0 when cart is empty', () {
      final cart = Cart(
        userId: 'user1',
        items: [],
        subtotal: 0,
      );

      expect(cart.totalItems, 0);
      expect(cart.isEmpty, true);
    });

    test('isEmpty should be false when cart has items', () {
      final items = [
        CartItem(
          foodId: 'food1',
          name: 'Burger',
          price: 50,
          quantity: 1,
          image: 'burger.jpg',
          restaurantId: 'rest1',
        ),
      ];

      final cart = Cart(
        userId: 'user1',
        items: items,
        subtotal: 50,
      );

      expect(cart.isEmpty, false);
    });
  });
}