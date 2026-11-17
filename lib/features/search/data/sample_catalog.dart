import '../domain/book.dart';

const categories = ['All', 'Technology', 'History', 'Literature', 'Research'];

const centers = [
  'All',
  'Aleppo University',
  'Culture Directorate',
  'Cultural Center'
];
const titles = [
  'Artificial Intelligence Fundamentals',
  'History of Aleppo',
  'Modern Arabic Literature',
  'Cultural Heritage Studies',
  'Introduction to Programming',
  'Machine Learning Basics',
  'Syrian Architecture',
  'Research Methods',
  'Networks and Security',
  'Poetry and Society',
  'Digital Libraries',
  'Data Science Handbook',
];
final sampleBooks = List.generate(
    120,
    (i) => Book(
          i + 1,
          '${titles[i % titles.length]}${i >= titles.length ? ' · Vol ${i ~/ titles.length + 1}' : ''}',
          [
            'Ibrahem Alhuossien',
            'Wael Habbal',
            'Omar Hasan',
            'Lina Darwish'
          ][i % 4],
          centers[1 + i % 3],
          categories[1 + i % 4],
          2000 + i % 27,
        ));
