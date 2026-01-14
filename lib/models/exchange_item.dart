class ExchangeItem {
  final String id;
  final String title;
  final String description;
  final String wantedItem;
  final String category;

  ExchangeItem({
    required this.id,
    required this.title,
    required this.description,
    required this.wantedItem,
    required this.category,
  });

  factory ExchangeItem.fromJson(Map<String, dynamic> json) => ExchangeItem(
        id: json['id'],
        title: json['title'],
        description: json['description'],
        wantedItem: json['wantedItem'],
        category: json['category'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'wantedItem': wantedItem,
        'category': category,
      };
}
