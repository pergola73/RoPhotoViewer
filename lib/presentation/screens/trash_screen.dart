import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kphoto/presentation/blocs/gallery_bloc.dart';
import 'package:intl/intl.dart';

class TrashScreen extends StatefulWidget {
  const TrashScreen({super.key});

  @override
  State<TrashScreen> createState() => _TrashScreenState();
}

class _TrashScreenState extends State<TrashScreen> {
  @override
  void initState() {
    super.initState();
    context.read<GalleryBloc>().add(LoadTrash());
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GalleryBloc, GalleryState>(
      builder: (context, state) {
        final isSelectionMode = state.selectedTrashIds.isNotEmpty;

        return Scaffold(
          appBar: AppBar(
            title: isSelectionMode 
                ? Text('${state.selectedTrashIds.length} geselecteerd')
                : const Text('Prullenbak'),
            actions: [
              if (isSelectionMode) ...[
                IconButton(
                  icon: const Icon(Icons.restore),
                  onPressed: () => _confirmRestore(context),
                  tooltip: 'Herstellen',
                ),
                IconButton(
                  icon: const Icon(Icons.delete_forever),
                  onPressed: () => _confirmPermanentDelete(context, state),
                  tooltip: 'Definitief verwijderen',
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => context.read<GalleryBloc>().add(ClearTrashSelection()),
                ),
              ] else if (state.trashItems.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.delete_sweep),
                  onPressed: () => _confirmEmptyTrash(context),
                  tooltip: 'Prullenbak legen',
                ),
            ],
          ),
          body: state.status == GalleryStatus.loading && state.trashItems.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : state.trashItems.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.delete_outline, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text('De prullenbak is leeg'),
                          Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Text(
                              'Items in de prullenbak worden na 60 dagen automatisch verwijderd door kDrive.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: state.trashItems.length,
                      itemBuilder: (context, index) {
                        final item = state.trashItems[index];
                        final String id = (item['id'] ?? '').toString();
                        final String name = (item['name'] ?? 'Onbekend').toString();
                        final bool isSelected = state.selectedTrashIds.contains(id);
                        
                        dynamic deletedAtRaw = item['deleted_at'];
                        String subtitle = 'Verwijderd op: Onbekend';
                        
                        if (deletedAtRaw != null) {
                          try {
                            DateTime? dt;
                            if (deletedAtRaw is num) {
                              dt = DateTime.fromMillisecondsSinceEpoch(deletedAtRaw.toInt() * 1000);
                            } else {
                              dt = DateTime.tryParse(deletedAtRaw.toString());
                            }
                            
                            if (dt != null) {
                              subtitle = 'Verwijderd op: ${DateFormat('d MMMM yyyy HH:mm', 'nl_NL').format(dt)}';
                            }
                          } catch (_) {}
                        }

                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.grey[200],
                            child: const Icon(Icons.image, color: Colors.grey),
                          ),
                          title: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
                          subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
                          trailing: isSelectionMode
                              ? Checkbox(
                                  value: isSelected,
                                  onChanged: (_) => context.read<GalleryBloc>().add(ToggleTrashSelection(id)),
                                )
                              : null,
                          selected: isSelected,
                          onTap: () {
                            HapticFeedback.lightImpact();
                            if (isSelectionMode) {
                              context.read<GalleryBloc>().add(ToggleTrashSelection(id));
                            } else {
                              // Optioneel: toon preview of ga naar selectie modus
                              context.read<GalleryBloc>().add(ToggleTrashSelection(id));
                            }
                          },
                          onLongPress: () {
                            HapticFeedback.mediumImpact();
                            context.read<GalleryBloc>().add(ToggleTrashSelection(id));
                          },
                        );
                      },
                    ),
        );
      },
    );
  }

  void _confirmRestore(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Items herstellen?'),
        content: const Text('De geselecteerde items worden teruggeplaatst naar hun oorspronkelijke map.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuleren')),
          TextButton(
            onPressed: () {
              context.read<GalleryBloc>().add(RestoreSelectedFromTrash());
              Navigator.pop(context);
            },
            child: const Text('Herstellen'),
          ),
        ],
      ),
    );
  }

  void _confirmPermanentDelete(BuildContext context, GalleryState state) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Definitief verwijderen?'),
        content: Text('Weet je zeker dat je deze ${state.selectedTrashIds.length} items definitief wilt verwijderen? Dit kan niet ongedaan worden gemaakt.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuleren')),
          TextButton(
            onPressed: () {
              context.read<GalleryBloc>().add(const DeleteSelectedFromTrash(permanent: true));
              Navigator.pop(context);
            },
            child: const Text('Verwijderen', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _confirmEmptyTrash(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Prullenbak legen?'),
        content: const Text('Alle items in de prullenbak worden definitief verwijderd. Dit kan niet ongedaan worden gemaakt.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuleren')),
          TextButton(
            onPressed: () async {
              context.read<GalleryBloc>().add(EmptyTrash());
              Navigator.pop(context);
            },
            child: const Text('Legen', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
