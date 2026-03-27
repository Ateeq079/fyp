class RelatedLink {
  final String title;
  final String url;

  RelatedLink({required this.title, required this.url});

  factory RelatedLink.fromJson(Map<String, dynamic> json) {
    return RelatedLink(
      title: json['title'] as String,
      url: json['url'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'url': url,
    };
  }
}

class VocabularyModel {
  final int id;
  final String word;
  final String? definition;
  final String? contextSentence;
  final String? sourceName;
  final String? sourceUrl;
  final List<RelatedLink>? relatedLinks;
  final int documentId;
  final DateTime createdAt;

  VocabularyModel({
    required this.id,
    required this.word,
    this.definition,
    this.contextSentence,
    this.sourceName,
    this.sourceUrl,
    this.relatedLinks,
    required this.documentId,
    required this.createdAt,
  });

  factory VocabularyModel.fromJson(Map<String, dynamic> json) {
    return VocabularyModel(
      id: json['id'] as int,
      word: json['word'] as String,
      definition: json['definition'] as String?,
      contextSentence: json['context_sentence'] as String?,
      sourceName: json['source_name'] as String?,
      sourceUrl: json['source_url'] as String?,
      relatedLinks: json['related_links'] != null
          ? (json['related_links'] as List)
              .map((i) => RelatedLink.fromJson(i as Map<String, dynamic>))
              .toList()
          : null,
      documentId: json['document_id'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'word': word,
      'definition': definition,
      'context_sentence': contextSentence,
      'source_name': sourceName,
      'source_url': sourceUrl,
      'related_links': relatedLinks?.map((i) => i.toJson()).toList(),
      'document_id': documentId,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
