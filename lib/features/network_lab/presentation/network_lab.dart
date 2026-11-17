import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../search/presentation/cubit/search_cubit.dart';
import '../../search/presentation/cubit/search_state.dart';

class NetworkLab extends StatefulWidget {
  final VoidCallback onUpdate;
  const NetworkLab({super.key, required this.onUpdate});
  @override
  State<NetworkLab> createState() => _NetworkLabState();
}

class _NetworkLabState extends State<NetworkLab> {
  @override
  Widget build(BuildContext context) {
    final c = context.read<SearchCubit>();
    return BlocBuilder<SearchCubit, SearchState>(
        builder: (context, state) =>
            ListView(padding: const EdgeInsets.all(20), children: [
              const Text('Network Playground',
                  style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold)),
              const Text(
                  'Disable protections to demonstrate incorrect results. Restore all switches afterward.'),
              const SizedBox(height: 20),
              Text('Simulated latency: ${c.api.delayMs} ms'),
              Slider(
                  value: c.api.delayMs.toDouble(),
                  min: 0,
                  max: 2000,
                  divisions: 20,
                  onChanged: (v) => setState(() => c.api.delayMs = v.round())),
              SwitchListTile(
                  title: const Text('Debouncing (400 ms)'),
                  value: c.debounceEnabled,
                  onChanged: (v) => setState(() => c.debounceEnabled = v)),
              SwitchListTile(
                  title: const Text('Cancel previous request'),
                  value: c.cancellationEnabled,
                  onChanged: (v) => setState(() => c.cancellationEnabled = v)),
              SwitchListTile(
                  title: const Text('Generation guard'),
                  subtitle: const Text('Reject stale responses'),
                  value: c.generationGuardEnabled,
                  onChanged: (v) =>
                      setState(() => c.generationGuardEnabled = v)),
              const Divider(),
              Text('Requests sent: ${c.api.requestCount}'),
              FilledButton(
                  onPressed: () {
                    c.api.requestCount = 0;
                    widget.onUpdate();
                    setState(() {});
                  },
                  child: const Text('Reset request counter')),
              const SizedBox(height: 12),
              const Text(
                  'Demo: turn off Debouncing, Cancellation and Generation Guard. Search quickly, then restore the protections and repeat.'),
            ]));
  }
}
