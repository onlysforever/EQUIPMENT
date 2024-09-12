class ReturnObject {
  String result;
  dynamic data;
  String message;

  ReturnObject(
      {required this.result, required this.data, required this.message});

  factory ReturnObject.fromJsonMap(Map<String, dynamic> map) {
    return ReturnObject(
      result: map['result'] ?? 'SUCCESS',
      data: map['data'] ?? Null,
      message: map['message'] ?? '',
    );
  }
}
