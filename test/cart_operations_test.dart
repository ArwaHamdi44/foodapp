import 'package:flutter_test/flutter_test.dart';
import 'package:foodapp/data/models/cart.dart';
import 'package:foodapp/data/models/cart_item.dart';

void main() {
  group('Cart Item Quantity Operations', () {
    test('incrementing quantity should increase totalPrice', () {
      final cartItem = CartItem(
        foodId: 'food1',
        name: 'Burger',
        price: 50,
        quantity: 2,
        image: 'burger.jpg',
        restaurantId: 'rest1',
      );

      expect(cartItem.totalPrice, 100);

      final incrementedItem = cartItem.copyWith(quantity: cartItem.quantity + 1);

      expect(incrementedItem.quantity, 3);
      expect(incrementedItem.totalPrice, 150);
    });

    test('decrementing quantity should decrease totalPrice', () {
      final cartItem = CartItem(
        foodId: 'food1',
        name: 'Pizza',
        price: 80,
        quantity: 4,
        image: 'pizza.jpg',
        restaurantId: 'rest1',
      );

      expect(cartItem.totalPrice, 320);

      final decrementedItem = cartItem.copyWith(quantity: cartItem.quantity - 1);

      expect(decrementedItem.quantity, 3);
      expect(decrementedItem.totalPrice, 240);
    });

    test('decrementing quantity to 1 should keep item with quantity 1', () {
      final cartItem = CartItem(
        foodId: 'food1',
        name: 'Fries',
        price: 30,
        quantity: 2,
        image: 'fries.jpg',
        restaurantId: 'rest1',
      );

      final decrementedItem = cartItem.copyWith(quantity: cartItem.quantity - 1);

      expect(decrementedItem.quantity, 1);
      expect(decrementedItem.totalPrice, 30);
    });

    test('quantity should never be negative', () {
      final cartItem = CartItem(
        foodId: 'food1',
        name: 'Drink',
        price: 20,
        quantity: 1,
        image: 'drink.jpg',
        restaurantId: 'rest1',
      );

      final decrementedItem = cartItem.copyWith(quantity: 0);

      expect(decrementedItem.quantity, 0);
      expect(decrementedItem.totalPrice, 0); // 20 * 0 = 0
    });
  });

  group('Cart Subtotal Recalculation', () {
    test('adding item to cart should update subtotal correctly', () {
      // Initial cart with 1 item
      final item1 = CartItem(
        foodId: 'food1',
        name: 'Burger',
        price: 50,
        quantity: 2,
        image: 'burger.jpg',
        restaurantId: 'rest1',
      );

      final cart = Cart(
        userId: 'user1',
        items: [item1],
        subtotal: 100, 
      );

      expect(cart.subtotal, 100);

      final item2 = CartItem(
        foodId: 'food2',
        name: 'Pizza',
        price: 80,
        quantity: 1,
        image: 'pizza.jpg',
        restaurantId: 'rest1',
      );

      final updatedItems = [...cart.items, item2];
      final newSubtotal = updatedItems.fold(0, (sum, item) => sum + item.totalPrice);
      
      final updatedCart = cart.copyWith(
        items: updatedItems,
        subtotal: newSubtotal,
      );

      expect(updatedCart.items.length, 2);
      expect(updatedCart.subtotal, 180); 
    });

    test('incrementing item quantity should update cart subtotal', () {
      final item1 = CartItem(
        foodId: 'food1',
        name: 'Burger',
        price: 50,
        quantity: 2,
        image: 'burger.jpg',
        restaurantId: 'rest1',
      );

      final cart = Cart(
        userId: 'user1',
        items: [item1],
        subtotal: 100, 
      );

      final updatedItem = item1.copyWith(quantity: item1.quantity + 1);
      final updatedItems = [updatedItem];
      final newSubtotal = updatedItems.fold(0, (sum, item) => sum + item.totalPrice);

      final updatedCart = cart.copyWith(
        items: updatedItems,
        subtotal: newSubtotal,
      );

      expect(updatedCart.items[0].quantity, 3);
      expect(updatedCart.subtotal, 150);
      expect(updatedCart.total, 180);
    });

    test('decrementing item quantity should update cart subtotal', () {
      final item1 = CartItem(
        foodId: 'food1',
        name: 'Pizza',
        price: 80,
        quantity: 3,
        image: 'pizza.jpg',
        restaurantId: 'rest1',
      );

      final cart = Cart(
        userId: 'user1',
        items: [item1],
        subtotal: 240, 
      );

      final updatedItem = item1.copyWith(quantity: item1.quantity - 1);
      final updatedItems = [updatedItem];
      final newSubtotal = updatedItems.fold(0, (sum, item) => sum + item.totalPrice);

      final updatedCart = cart.copyWith(
        items: updatedItems,
        subtotal: newSubtotal,
      );

      expect(updatedCart.items[0].quantity, 2);
      expect(updatedCart.subtotal, 160); 
      expect(updatedCart.total, 190); 
    });

    test('removing item from cart should update subtotal', () {
      final item1 = CartItem(
        foodId: 'food1',
        name: 'Burger',
        price: 50,
        quantity: 2,
        image: 'burger.jpg',
        restaurantId: 'rest1',
      );

      final item2 = CartItem(
        foodId: 'food2',
        name: 'Pizza',
        price: 80,
        quantity: 1,
        image: 'pizza.jpg',
        restaurantId: 'rest1',
      );

      final cart = Cart(
        userId: 'user1',
        items: [item1, item2],
        subtotal: 180, 
      );

      final updatedItems = cart.items.where((item) => item.foodId != 'food2').toList();
      final newSubtotal = updatedItems.fold(0, (sum, item) => sum + item.totalPrice);

      final updatedCart = cart.copyWith(
        items: updatedItems,
        subtotal: newSubtotal,
      );

      expect(updatedCart.items.length, 1);
      expect(updatedCart.subtotal, 100); 
      expect(updatedCart.total, 130); 
    });
  });

  group('Multiple Items in Cart', () {
    test('incrementing one item should not affect other items', () {
      final item1 = CartItem(
        foodId: 'food1',
        name: 'Burger',
        price: 50,
        quantity: 2,
        image: 'burger.jpg',
        restaurantId: 'rest1',
      );

      final item2 = CartItem(
        foodId: 'food2',
        name: 'Pizza',
        price: 80,
        quantity: 1,
        image: 'pizza.jpg',
        restaurantId: 'rest1',
      );

      final cart = Cart(
        userId: 'user1',
        items: [item1, item2],
        subtotal: 180,
      );

      final updatedItem1 = item1.copyWith(quantity: item1.quantity + 1);
      final updatedItems = [updatedItem1, item2];
      final newSubtotal = updatedItems.fold(0, (sum, item) => sum + item.totalPrice);

      final updatedCart = cart.copyWith(
        items: updatedItems,
        subtotal: newSubtotal,
      );

      expect(updatedCart.items[0].quantity, 3);
      expect(updatedCart.items[0].totalPrice, 150);
      
      expect(updatedCart.items[1].quantity, 1);
      expect(updatedCart.items[1].totalPrice, 80);
      
      // Subtotal should be recalculated
      expect(updatedCart.subtotal, 230); 
    });

    test('totalItems should update when quantities change', () {
      final item1 = CartItem(
        foodId: 'food1',
        name: 'Burger',
        price: 50,
        quantity: 2,
        image: 'burger.jpg',
        restaurantId: 'rest1',
      );

      final item2 = CartItem(
        foodId: 'food2',
        name: 'Pizza',
        price: 80,
        quantity: 3,
        image: 'pizza.jpg',
        restaurantId: 'rest1',
      );

      final cart = Cart(
        userId: 'user1',
        items: [item1, item2],
        subtotal: 340, 
      );


      expect(cart.totalItems, 5);

      final updatedItem1 = item1.copyWith(quantity: item1.quantity + 1);
      final updatedCart = cart.copyWith(items: [updatedItem1, item2]);

      expect(updatedCart.totalItems, 6);
    });
  });
}