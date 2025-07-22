class DropdownItem {
  final String value;
  final String text;

  DropdownItem({required this.value, required this.text});

  factory DropdownItem.fromJson(Map<String, dynamic> json) {
    return DropdownItem(
      value: json['Value'] ?? json['value'] ?? '',
      text: json['Text'] ?? json['text'] ?? '',
    );
  }
} 