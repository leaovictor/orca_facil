import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../viewmodels/client_viewmodel.dart';
import '../../core/utils/formatters.dart';

class PremiumClientsScreen extends ConsumerStatefulWidget {
  const PremiumClientsScreen({super.key});

  @override
  ConsumerState<PremiumClientsScreen> createState() =>
      _PremiumClientsScreenState();
}

class _PremiumClientsScreenState extends ConsumerState<PremiumClientsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  // Simple view toggle: List or Pipeline (Grid)
  bool _pipelineView = false;

  @override
  Widget build(BuildContext context) {
    final clientsAsync = ref.watch(clientsStreamProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Dark Slate
      appBar: AppBar(
        title: Text(
          'CLIENT INTELLIGENCE',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            letterSpacing: 2.0,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_pipelineView ? Icons.list : Icons.grid_view),
            color: Colors.white,
            onPressed: () => setState(() => _pipelineView = !_pipelineView),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search clients...',
                hintStyle: GoogleFonts.outfit(color: Colors.white30),
                prefixIcon: const Icon(Icons.search, color: Colors.white30),
                filled: true,
                fillColor: Colors.white.withOpacity(0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              style: GoogleFonts.outfit(color: Colors.white),
              onChanged: (value) =>
                  setState(() => _searchQuery = value.toLowerCase()),
            ),
          ),
          Expanded(
            child: clientsAsync.when(
              data: (clients) {
                final filtered = clients
                    .where(
                      (c) =>
                          c.name.toLowerCase().contains(_searchQuery) ||
                          c.phone.contains(_searchQuery),
                    )
                    .toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Text(
                      'No clients found',
                      style: GoogleFonts.outfit(color: Colors.white30),
                    ),
                  );
                }

                if (_pipelineView) {
                  return _buildPipelineView(filtered);
                }
                return _buildListView(filtered);
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Text(
                  'Error: $e',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/clients/new'),
        label: Text(
          'NEW CLIENT',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        icon: const Icon(Icons.add),
        backgroundColor: const Color(0xFF38BDF8),
      ),
    );
  }

  Widget _buildListView(List<dynamic> clients) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: clients.length,
      itemBuilder: (context, index) {
        final client = clients[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            onTap: () => context.push('/clients/${client.id}', extra: client),
            leading: CircleAvatar(
              radius: 24,
              backgroundColor: Colors.white10,
              child: Text(
                client.name.isNotEmpty ? client.name[0] : 'C',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              client.name,
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.phone, size: 12, color: Colors.white54),
                    const SizedBox(width: 4),
                    Text(
                      Formatters.formatPhone(client.phone),
                      style: GoogleFonts.jetBrainsMono(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Premium Tag: e.g., "High Value" placeholder
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.purple.withOpacity(0.5)),
                  ),
                  child: Text(
                    'POTENTIAL',
                    style: GoogleFonts.outfit(
                      color: Colors.purple[200],
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            trailing: const Icon(Icons.chevron_right, color: Colors.white30),
          ),
        );
      },
    );
  }

  Widget _buildPipelineView(List<dynamic> clients) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.85,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: clients.length,
      itemBuilder: (context, index) {
        final client = clients[index];
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.08),
                Colors.white.withOpacity(0.02),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: InkWell(
            onTap: () => context.push('/clients/${client.id}', extra: client),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: Colors.white10,
                  child: Text(
                    client.name[0],
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                const Spacer(),
                Text(
                  client.name,
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'Last interaction: 2d ago', // Placeholder
                  style: GoogleFonts.outfit(
                    color: Colors.white30,
                    fontSize: 12,
                  ),
                ),
                const Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 16),
                    Text(
                      '4.8',
                      style: GoogleFonts.jetBrainsMono(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
