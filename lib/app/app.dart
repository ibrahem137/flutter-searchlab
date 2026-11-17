import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../features/search/data/fake_catalog_api.dart';
import '../features/search/presentation/cubit/search_cubit.dart';
import 'lab_home.dart';

class SearchLabApp extends StatelessWidget {
  const SearchLabApp({super.key});
  @override
  Widget build(BuildContext context) => BlocProvider(
        create: (_) => SearchCubit(FakeCatalogApi()),
        child: MaterialApp(
            title: 'SearchLab',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
                colorScheme:
                    ColorScheme.fromSeed(seedColor: const Color(0xFF087F8C)),
                useMaterial3: true),
            home: const LabHome()),
      );
}
