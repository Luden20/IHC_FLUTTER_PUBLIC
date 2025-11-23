class ResponseEventActionDto {
  final String status;
  final String message;
  final String id;


  ResponseEventActionDto({required this.status, required this.message,required this.id});

  factory ResponseEventActionDto.fromJson(Map<String, dynamic> json) {
    return ResponseEventActionDto(
      status: json['status'] ?? '',
      message: json['message'] ?? '',
      id: json['id'] ?? '',
    );
  }
}
