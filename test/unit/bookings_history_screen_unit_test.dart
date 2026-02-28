import 'package:ceniflix/features/seats/data/models/user_booking_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
	test('UserBookingModel.fromJson(): parses valid booking values correctly', () {
		final booking = UserBookingModel.fromJson({
			'_id': 'booking_1',
			'showtimeId': {
				'_id': 'show_1',
				'movieId': {'_id': 'movie_1', 'title': 'Avatar 3'},
				'hallId': 'hall_1',
				'hallName': 'Hall 1',
				'startTime': '2026-02-28T12:30:00.000Z',
				'price': 300,
			},
			'seats': ['A1', 'A2'],
			'totalPrice': 600,
			'status': 'confirmed',
			'payment': {
				'status': 'paid',
				'provider': 'khalti',
				'isPaid': true,
				'pidx': 'P_IDX_123',
			},
			'createdAt': '2026-02-28T10:00:00.000Z',
		});

		expect(booking.id, 'booking_1');
		expect(booking.showtimeId, 'show_1');
		expect(booking.movieTitle, 'Avatar 3');
		expect(booking.hallName, 'Hall 1');
		expect(booking.startTime, isNotNull);
		expect(booking.seats, ['A1', 'A2']);
		expect(booking.totalPrice, 600);
		expect(booking.paymentStatus, 'paid');
		expect(booking.paymentProvider, 'khalti');
		expect(booking.isPaid, isTrue);
		expect(booking.paymentReference, 'P_IDX_123');
		expect(booking.isConfirmed, isTrue);
		expect(booking.requiresPayment, isFalse);
	});

	test('UserBookingModel.fromJson(): falls back to defaults for invalid values', () {
		final booking = UserBookingModel.fromJson({
			'_id': null,
			'showtimeId': 'invalid-structure',
			'seats': 'invalid-seats',
			'totalPrice': 'invalid-price',
			'status': null,
			'payment': 'invalid-payment',
			'createdAt': 'not-a-date',
		});

		expect(booking.id, '');
		expect(booking.showtimeId, '');
		expect(booking.movieId, '');
		expect(booking.movieTitle, 'Unknown Movie');
		expect(booking.hallId, '');
		expect(booking.hallName, '');
		expect(booking.startTime, isNull);
		expect(booking.price, 0);
		expect(booking.seats, isEmpty);
		expect(booking.totalPrice, 0);
		expect(booking.status, '');
		expect(booking.paymentStatus, '');
		expect(booking.paymentProvider, '');
		expect(booking.isPaid, isFalse);
		expect(booking.paymentReference, isNull);
		expect(booking.createdAt, isNull);
	});

	test('UserBookingModel.fromJson(): resolves paymentStatus from legacy payment_state', () {
		final booking = UserBookingModel.fromJson({
			'_id': 'booking_2',
			'showtimeId': {
				'_id': 'show_2',
				'movieId': {'_id': 'movie_2', 'title': 'Legacy Payment'},
				'hallId': 'hall_2',
				'hallName': 'Hall 2',
				'price': 250,
			},
			'seats': ['B1'],
			'totalPrice': 250,
			'status': 'pending',
			'payment_state': 'Succeeded',
		});

		expect(booking.paymentStatus, 'succeeded');
		expect(booking.isPaid, isTrue);
		expect(booking.requiresPayment, isFalse);
	});

	test('UserBookingModel.fromJson(): resolves paymentReference fallback values', () {
		final bookingWithTxn = UserBookingModel.fromJson({
			'_id': 'booking_3',
			'showtimeId': {
				'_id': 'show_3',
				'movieId': {'_id': 'movie_3', 'title': 'Txn Ref'},
				'hallId': 'hall_3',
				'hallName': 'Hall 3',
				'price': 280,
			},
			'seats': ['C1'],
			'totalPrice': 280,
			'status': 'confirmed',
			'payment': {
				'transactionId': 'TXN_987',
			},
		});

		final bookingWithRootRef = UserBookingModel.fromJson({
			'_id': 'booking_4',
			'showtimeId': {
				'_id': 'show_4',
				'movieId': {'_id': 'movie_4', 'title': 'Root Ref'},
				'hallId': 'hall_4',
				'hallName': 'Hall 4',
				'price': 320,
			},
			'seats': ['D1'],
			'totalPrice': 320,
			'status': 'confirmed',
			'paymentReference': 'ROOT_REF_555',
		});

		expect(bookingWithTxn.paymentReference, 'TXN_987');
		expect(bookingWithRootRef.paymentReference, 'ROOT_REF_555');
	});

	test('UserBookingModel getters: isConfirmed and requiresPayment are derived correctly', () {
		final cancelledUnpaid = UserBookingModel.fromJson({
			'_id': 'booking_5',
			'showtimeId': {
				'_id': 'show_5',
				'movieId': {'_id': 'movie_5', 'title': 'Cancelled'},
				'hallId': 'hall_5',
				'hallName': 'Hall 5',
				'price': 200,
			},
			'seats': ['E1'],
			'totalPrice': 200,
			'status': 'cancelled',
			'isPaid': false,
		});

		final confirmedUnpaid = UserBookingModel.fromJson({
			'_id': 'booking_6',
			'showtimeId': {
				'_id': 'show_6',
				'movieId': {'_id': 'movie_6', 'title': 'Confirmed'},
				'hallId': 'hall_6',
				'hallName': 'Hall 6',
				'price': 350,
			},
			'seats': ['F1', 'F2'],
			'totalPrice': 700,
			'status': 'confirmed',
			'isPaid': false,
		});

		expect(cancelledUnpaid.isConfirmed, isFalse);
		expect(cancelledUnpaid.requiresPayment, isFalse);

		expect(confirmedUnpaid.isConfirmed, isTrue);
		expect(confirmedUnpaid.requiresPayment, isTrue);
	});
}
