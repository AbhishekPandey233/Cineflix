import 'package:ceniflix/features/seats/data/models/seat_availability_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
	test('SeatLayoutModel.fromJson(): parses valid layout values', () {
		final layout = SeatLayoutModel.fromJson({
			'rows': ['A', 'B', 'C'],
			'seatsPerRow': 10,
			'seatIds': ['A1', 'A2', 'B1'],
		});

		expect(layout.rows, ['A', 'B', 'C']);
		expect(layout.seatsPerRow, 10);
		expect(layout.seatIds, ['A1', 'A2', 'B1']);
	});

	test('SeatLayoutModel.fromJson(): falls back to defaults for invalid data', () {
		final layout = SeatLayoutModel.fromJson({
			'rows': 'invalid',
			'seatsPerRow': 'invalid',
			'seatIds': null,
		});

		expect(layout.rows, isEmpty);
		expect(layout.seatsPerRow, 0);
		expect(layout.seatIds, isEmpty);
	});

	test('SeatAvailabilityModel.fromJson(): parses valid seat availability data', () {
		final seatAvailability = SeatAvailabilityModel.fromJson({
			'showtimeId': 'show_1',
			'movieId': 'movie_1',
			'hallId': 'hall_1',
			'hallName': 'Hall 1',
			'startTime': '2026-02-26T13:30:00.000Z',
			'price': 250,
			'layout': {
				'rows': ['A', 'B'],
				'seatsPerRow': 4,
				'seatIds': ['A1', 'A2', 'B1', 'B2'],
			},
			'bookedSeats': ['a1', 'b2'],
		});

		expect(seatAvailability.showtimeId, 'show_1');
		expect(seatAvailability.hallName, 'Hall 1');
		expect(seatAvailability.price, 250);
		expect(seatAvailability.startTime, isNotNull);
		expect(seatAvailability.layout.rows, ['A', 'B']);
		expect(seatAvailability.bookedSeats, ['A1', 'B2']);
	});

	test('SeatAvailabilityModel.fromJson(): uses defaults for invalid values', () {
		final seatAvailability = SeatAvailabilityModel.fromJson({
			'showtimeId': null,
			'movieId': null,
			'hallId': null,
			'hallName': null,
			'startTime': 'invalid-date',
			'price': 'invalid-price',
			'layout': 'invalid-layout',
			'bookedSeats': 'invalid-booked',
		});

		expect(seatAvailability.showtimeId, '');
		expect(seatAvailability.movieId, '');
		expect(seatAvailability.hallId, '');
		expect(seatAvailability.hallName, '');
		expect(seatAvailability.startTime, isNull);
		expect(seatAvailability.price, 0);
		expect(seatAvailability.layout.rows, isEmpty);
		expect(seatAvailability.layout.seatsPerRow, 0);
		expect(seatAvailability.bookedSeats, isEmpty);
	});

	test('SeatAvailabilityModel.fromJson(): preserves decimal price values', () {
		final seatAvailability = SeatAvailabilityModel.fromJson({
			'showtimeId': 'show_2',
			'movieId': 'movie_2',
			'hallId': 'hall_2',
			'hallName': 'Hall 2',
			'startTime': null,
			'price': '199.5',
			'layout': {
				'rows': ['D'],
				'seatsPerRow': 3,
				'seatIds': ['D1', 'D2', 'D3'],
			},
			'bookedSeats': [],
		});

		expect(seatAvailability.price, 199.5);
		expect(seatAvailability.layout.seatsPerRow, 3);
	});
}
