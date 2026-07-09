import 'package:equatable/equatable.dart';

class MemorySection extends Equatable {
  const MemorySection({required this.title, required this.content});

  final String title;
  final String content;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MemorySection &&
          other.title == title &&
          other.content == content);

  @override
  int get hashCode => Object.hash(title, content);

  @override
  String toString() => 'MemorySection(title: $title, content: $content)';

  @override
  List<Object?> get props => [title, content];
}

class MemoryDocument extends Equatable {
  const MemoryDocument({this.preamble = '', this.sections = const []});

  final String preamble;
  final List<MemorySection> sections;

  bool get isEmpty => preamble.trim().isEmpty && sections.isEmpty;

  @override
  List<Object?> get props => [preamble, sections];
}

final RegExp _sectionHeader = RegExp(r'^##\s+(.*)$', multiLine: true);

MemoryDocument parseMemory(String md) {
  if (md.isEmpty) return const MemoryDocument();
  final lines = md.split('\n');
  final preamble = StringBuffer();
  final sections = <MemorySection>[];
  String? currentTitle;
  final currentBody = StringBuffer();

  for (final line in lines) {
    final match = _sectionHeader.firstMatch(line);
    if (match != null) {
      if (currentTitle != null) {
        sections.add(
          MemorySection(
            title: currentTitle,
            content: currentBody.toString().trimRight(),
          ),
        );
        currentBody.clear();
      }
      currentTitle = match.group(1)!.trim();
    } else if (currentTitle != null) {
      if (currentBody.isNotEmpty) {
        currentBody.writeln();
      }
      currentBody.write(line);
    } else {
      if (preamble.isNotEmpty) {
        preamble.writeln();
      }
      preamble.write(line);
    }
  }
  if (currentTitle != null) {
    sections.add(
      MemorySection(
        title: currentTitle,
        content: currentBody.toString().trimRight(),
      ),
    );
  }

  final preambleStr = preamble.toString().trimRight();
  if (preambleStr.isEmpty && sections.isEmpty) {
    return const MemoryDocument();
  }
  return MemoryDocument(preamble: preambleStr, sections: sections);
}

String serializeMemory(MemoryDocument doc) {
  final buf = StringBuffer();
  if (doc.preamble.trim().isNotEmpty) {
    buf.write(doc.preamble.trim());
    if (doc.sections.isNotEmpty) {
      buf.writeln();
      buf.writeln();
    }
  }
  for (var i = 0; i < doc.sections.length; i++) {
    final s = doc.sections[i];
    buf.write('## ');
    buf.writeln(s.title);
    if (s.content.trim().isNotEmpty) {
      buf.writeln(s.content.trim());
    }
    if (i < doc.sections.length - 1) {
      buf.writeln();
    }
  }
  return buf.toString().trimRight();
}

MemoryDocument upsertSection(MemoryDocument doc, MemorySection section) {
  final sections = List<MemorySection>.from(doc.sections);
  final index = sections.indexWhere(
    (s) => s.title.toLowerCase() == section.title.toLowerCase(),
  );
  if (index >= 0) {
    sections[index] = section;
  } else {
    sections.add(section);
  }
  return MemoryDocument(preamble: doc.preamble, sections: sections);
}

MemoryDocument removeSection(MemoryDocument doc, String title) {
  final sections = doc.sections
      .where((s) => s.title.toLowerCase() != title.trim().toLowerCase())
      .toList();
  return MemoryDocument(preamble: doc.preamble, sections: sections);
}

List<MemorySection> searchSections(MemoryDocument doc, String query) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return doc.sections;
  return doc.sections.where((s) {
    return s.title.toLowerCase().contains(q) ||
        s.content.toLowerCase().contains(q);
  }).toList();
}
