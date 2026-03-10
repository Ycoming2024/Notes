import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../core/di.dart';
import '../../reminders/presentation/reminders_page.dart';
import '../data/note_content_codec.dart';
import '../domain/note.dart';

enum _NoteFilter { all, pinned, checklist }

class NotesPage extends StatefulWidget {
  const NotesPage({super.key});

  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  List<Note> _notes = const [];
  bool _loading = true;
  int _pendingCount = 0;
  String _query = '';
  _NoteFilter _filter = _NoteFilter.all;
  Timer? _autoSyncTimer;

  @override
  void initState() {
    super.initState();
    _reload();
    _autoSyncTimer = Timer.periodic(
      const Duration(seconds: 25),
      (_) => _reload(silent: true),
    );
  }

  @override
  void dispose() {
    _autoSyncTimer?.cancel();
    super.dispose();
  }

  Future<void> _refreshPendingCount() async {
    final count = await AppDI.syncManager.pendingCount();
    if (!mounted) return;
    setState(() => _pendingCount = count);
  }

  Future<void> _reload({bool silent = false}) async {
    if (!silent) setState(() => _loading = true);
    try {
      try {
        await AppDI.syncManager.syncOnce();
      } catch (_) {}
      final notes = await AppDI.noteRepo.list();
      if (!mounted) return;
      setState(() => _notes = notes);
      await _refreshPendingCount();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Backend is unreachable')),
      );
    } finally {
      if (mounted && !silent) setState(() => _loading = false);
    }
  }

  Future<void> _forceSync() async {
    setState(() => _loading = true);
    try {
      await AppDI.syncManager.forceFullSync();
      await _reload(silent: true);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Full sync completed')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Full sync failed')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _showNoteEditor({Note? note}) async {
    final result = await Navigator.of(context).push<_NoteEditorResult>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => _NoteEditorPage(note: note),
      ),
    );

    if (result == null) return;

    if (note == null) {
      final created = await AppDI.noteRepo.create(
        title: result.title,
        content: result.content,
      );
      if (!mounted) return;
      if (created.id.startsWith('local-note-')) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Saved offline, sync queued')),
        );
      }
    } else {
      await AppDI.noteRepo.update(
        Note(
          id: note.id,
          title: result.title,
          content: result.content,
          isPinned: note.isPinned,
          version: note.version,
          updatedAt: note.updatedAt,
        ),
      );
    }

    await _reload();
  }

  Future<void> _toggleChecklist(Note note, ChecklistItem item) async {
    final parsed = NoteContentCodec.decode(note.content);
    final updated = parsed.checklist
        .map((e) => e.id == item.id ? e.copyWith(done: !e.done) : e)
        .toList();

    await AppDI.noteRepo.update(
      Note(
        id: note.id,
        title: note.title,
        content: NoteContentCodec.encode(text: parsed.text, checklist: updated),
        isPinned: note.isPinned,
        version: note.version,
        updatedAt: note.updatedAt,
      ),
    );

    await _reload(silent: true);
  }

  Future<void> _confirmDeleteNote(Note note) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete note?'),
        content: Text(
            '"${note.title.isEmpty ? '(Untitled)' : note.title}" will be removed.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete')),
        ],
      ),
    );

    if (yes != true) return;
    await AppDI.noteRepo.remove(note.id);
    if (!mounted) return;
    await _reload();
  }

  Widget _pendingChip() {
    final hasPending = _pendingCount > 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: hasPending ? const Color(0xFFFFEEE6) : const Color(0xFFEAF8EF),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        hasPending ? 'Pending $_pendingCount' : 'Synced',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: hasPending ? const Color(0xFFB54708) : const Color(0xFF027A48),
        ),
      ),
    );
  }

  List<Note> get _visibleNotes {
    final query = _query.trim().toLowerCase();
    return _notes.where((note) {
      final parsed = NoteContentCodec.decode(note.content);
      final byFilter = switch (_filter) {
        _NoteFilter.all => true,
        _NoteFilter.pinned => note.isPinned,
        _NoteFilter.checklist => parsed.checklist.isNotEmpty,
      };
      if (!byFilter) return false;
      if (query.isEmpty) return true;

      final checklistText =
          parsed.checklist.map((e) => e.text.toLowerCase()).join(' ');
      return note.title.toLowerCase().contains(query) ||
          parsed.text.toLowerCase().contains(query) ||
          checklistText.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      body: Stack(
        children: [
          Positioned(
            top: -120,
            left: -70,
            child: Container(
              width: 320,
              height: 320,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                    colors: [Color(0x40A7C7FF), Color(0x10A7C7FF)]),
              ),
            ),
          ),
          Positioned(
            top: -80,
            right: -100,
            child: Container(
              width: 280,
              height: 280,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                    colors: [Color(0x30B8F2D2), Color(0x08B8F2D2)]),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Notes',
                          style: TextStyle(
                              fontSize: 34, fontWeight: FontWeight.w800),
                        ),
                      ),
                      _pendingChip(),
                      IconButton(
                        onPressed: _reload,
                        icon: const Icon(CupertinoIcons.refresh_thick),
                      ),
                      IconButton(
                        onPressed: _forceSync,
                        icon: const Icon(CupertinoIcons.arrow_2_circlepath),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                  child: TextField(
                    onChanged: (v) => setState(() => _query = v),
                    decoration: const InputDecoration(
                      hintText: 'Search notes and checklist',
                      prefixIcon: Icon(CupertinoIcons.search),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: CupertinoSlidingSegmentedControl<_NoteFilter>(
                    groupValue: _filter,
                    onValueChanged: (v) {
                      if (v == null) return;
                      setState(() => _filter = v);
                    },
                    children: const {
                      _NoteFilter.all: Padding(
                        padding: EdgeInsets.symmetric(vertical: 6),
                        child: Text('All'),
                      ),
                      _NoteFilter.pinned: Padding(
                        padding: EdgeInsets.symmetric(vertical: 6),
                        child: Text('Pinned'),
                      ),
                      _NoteFilter.checklist: Padding(
                        padding: EdgeInsets.symmetric(vertical: 6),
                        child: Text('Checklist'),
                      ),
                    },
                  ),
                ),
                Expanded(
                  child: _loading
                      ? const Center(child: CircularProgressIndicator())
                      : _visibleNotes.isEmpty
                          ? const Center(child: Text('No notes yet'))
                          : ListView.separated(
                              padding:
                                  const EdgeInsets.fromLTRB(16, 6, 16, 120),
                              itemCount: _visibleNotes.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 10),
                              itemBuilder: (_, i) {
                                final note = _visibleNotes[i];
                                final parsed =
                                    NoteContentCodec.decode(note.content);
                                final total = parsed.checklist.length;
                                final done = parsed.checklist
                                    .where((e) => e.done)
                                    .length;

                                return InkWell(
                                  borderRadius: BorderRadius.circular(22),
                                  onTap: () => _showNoteEditor(note: note),
                                  onLongPress: () => _confirmDeleteNote(note),
                                  child: Ink(
                                    decoration: BoxDecoration(
                                      color:
                                          Colors.white.withValues(alpha: 0.84),
                                      borderRadius: BorderRadius.circular(22),
                                      border: Border.all(
                                          color: Colors.white
                                              .withValues(alpha: 0.96)),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                          14, 14, 14, 12),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  note.title.isEmpty
                                                      ? '(Untitled)'
                                                      : note.title,
                                                  style: const TextStyle(
                                                      fontSize: 18,
                                                      fontWeight:
                                                          FontWeight.w700),
                                                ),
                                              ),
                                              if (total > 0)
                                                Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 10,
                                                      vertical: 5),
                                                  decoration: BoxDecoration(
                                                    color:
                                                        const Color(0xFFEAF2FF),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            999),
                                                  ),
                                                  child: Text(
                                                    '$done/$total done',
                                                    style: const TextStyle(
                                                      fontSize: 11,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color: Color(0xFF004FBA),
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                          if (parsed.text
                                              .trim()
                                              .isNotEmpty) ...[
                                            const SizedBox(height: 8),
                                            Text(
                                              parsed.text,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                color: Color(0xFF4A4A54),
                                                height: 1.35,
                                              ),
                                            ),
                                          ],
                                          if (parsed.checklist.isNotEmpty) ...[
                                            const SizedBox(height: 10),
                                            ...parsed.checklist.take(4).map(
                                                  (item) => InkWell(
                                                    onTap: () =>
                                                        _toggleChecklist(
                                                            note, item),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            10),
                                                    child: Padding(
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                          vertical: 3),
                                                      child: Row(
                                                        children: [
                                                          Icon(
                                                            item.done
                                                                ? CupertinoIcons
                                                                    .check_mark_circled_solid
                                                                : CupertinoIcons
                                                                    .circle,
                                                            size: 18,
                                                            color: item.done
                                                                ? const Color(
                                                                    0xFF34C759)
                                                                : const Color(
                                                                    0xFF8C8C96),
                                                          ),
                                                          const SizedBox(
                                                              width: 8),
                                                          Expanded(
                                                            child: Text(
                                                              item.text,
                                                              maxLines: 1,
                                                              overflow:
                                                                  TextOverflow
                                                                      .ellipsis,
                                                              style: TextStyle(
                                                                fontSize: 14,
                                                                color: const Color(
                                                                    0xFF4A4A54),
                                                                decoration: item
                                                                        .done
                                                                    ? TextDecoration
                                                                        .lineThrough
                                                                    : null,
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.extended(
            heroTag: 'to_reminders',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const RemindersPage()),
            ),
            label: const Text('Reminders'),
            icon: const Icon(CupertinoIcons.bell),
          ),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            heroTag: 'add_note',
            onPressed: () => _showNoteEditor(),
            label: const Text('New Note'),
            icon: const Icon(CupertinoIcons.add),
          ),
        ],
      ),
    );
  }
}

class _NoteEditorResult {
  const _NoteEditorResult({required this.title, required this.content});

  final String title;
  final String content;
}

class _ChecklistDraft {
  _ChecklistDraft({required this.id, required this.done, required String text})
      : controller = TextEditingController(text: text);

  final String id;
  bool done;
  final TextEditingController controller;

  factory _ChecklistDraft.empty() {
    final id = 'item-${DateTime.now().microsecondsSinceEpoch}';
    return _ChecklistDraft(id: id, done: false, text: '');
  }

  factory _ChecklistDraft.fromItem(ChecklistItem item) {
    return _ChecklistDraft(id: item.id, done: item.done, text: item.text);
  }

  ChecklistItem toItem() {
    return ChecklistItem(id: id, text: controller.text, done: done);
  }

  void dispose() {
    controller.dispose();
  }
}

class _NoteEditorPage extends StatefulWidget {
  const _NoteEditorPage({required this.note});

  final Note? note;

  @override
  State<_NoteEditorPage> createState() => _NoteEditorPageState();
}

class _NoteEditorPageState extends State<_NoteEditorPage> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _bodyCtrl;
  late final List<_ChecklistDraft> _items;

  @override
  void initState() {
    super.initState();
    final parsed = NoteContentCodec.decode(widget.note?.content ?? '');
    _titleCtrl = TextEditingController(text: widget.note?.title ?? '');
    _bodyCtrl = TextEditingController(text: parsed.text);
    _items = parsed.checklist.map((e) => _ChecklistDraft.fromItem(e)).toList();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    for (final item in _items) {
      item.dispose();
    }
    super.dispose();
  }

  void _save() {
    final checklist = _items.map((e) => e.toItem()).toList();
    final content = NoteContentCodec.encode(
      text: _bodyCtrl.text,
      checklist: checklist,
    );
    Navigator.of(context).pop(
      _NoteEditorResult(
        title: _titleCtrl.text.trim(),
        content: content,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      appBar: AppBar(
        title: Text(widget.note == null ? 'New Note' : 'Edit Note'),
        leading: TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        leadingWidth: 76,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilledButton(
              onPressed: _save,
              child: const Text('Save'),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          const Text('Title', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          TextField(
            controller: _titleCtrl,
            decoration: const InputDecoration(hintText: 'Enter title'),
          ),
          const SizedBox(height: 14),
          const Text('Description',
              style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          TextField(
            controller: _bodyCtrl,
            minLines: 4,
            maxLines: 8,
            decoration:
                const InputDecoration(hintText: 'Add details for this note'),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Text('Checklist',
                  style: TextStyle(fontWeight: FontWeight.w700)),
              const Spacer(),
              TextButton.icon(
                onPressed: () =>
                    setState(() => _items.add(_ChecklistDraft.empty())),
                icon: const Icon(CupertinoIcons.add, size: 16),
                label: const Text('Add item'),
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (_items.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.65),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'No checklist items yet',
                style: TextStyle(color: Color(0xFF7A7A84)),
              ),
            ),
          ..._items.asMap().entries.map((entry) {
            final i = entry.key;
            final item = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Checkbox(
                    value: item.done,
                    onChanged: (v) => setState(() => item.done = v ?? false),
                  ),
                  Expanded(
                    child: TextField(
                      controller: item.controller,
                      decoration: const InputDecoration(
                        isDense: true,
                        labelText: 'Task item',
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        item.dispose();
                        _items.removeAt(i);
                      });
                    },
                    icon: const Icon(CupertinoIcons.delete, size: 18),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
