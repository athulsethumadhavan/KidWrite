import 'package:equatable/equatable.dart';

class Language extends Equatable {
  final String id;
  final String displayName;
  final String nativeName;
  final String emoji;
  final String fontFamily;

  const Language({
    required this.id,
    required this.displayName,
    required this.nativeName,
    required this.emoji,
    required this.fontFamily,
  });

  @override
  List<Object?> get props => [id];
}
