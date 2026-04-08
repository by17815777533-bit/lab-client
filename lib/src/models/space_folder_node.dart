class SpaceFolderNode {
  SpaceFolderNode({
    required this.id,
    required this.folderName,
    required this.children,
  });

  final int id;
  final String folderName;
  final List<SpaceFolderNode> children;

  factory SpaceFolderNode.fromJson(Map<String, dynamic> json) {
    final rawChildren = json['children'] as List<dynamic>? ?? const <dynamic>[];
    return SpaceFolderNode(
      id: (json['id'] as num?)?.toInt() ?? 0,
      folderName: json['folderName']?.toString() ?? '',
      children: rawChildren
          .whereType<Map>()
          .map((item) => SpaceFolderNode.fromJson(item.cast<String, dynamic>()))
          .toList(),
    );
  }
}
