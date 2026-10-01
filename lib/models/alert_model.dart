
class Alert {
  final int id;
  final int idUserDestino;
  final String? data;
  final String texto;
  final String status;

  Alert({
    required this.id,
    required this.idUserDestino,
    this.data,
    required this.texto,
    required this.status,
  });

  factory Alert.fromJson(Map<String, dynamic> json) {
    return Alert(
      id: json['id'],
      idUserDestino: json['idUserDestino'],
      data: json['data'],
      texto: json['texto'],
      status: json['status'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'idUserDestino': idUserDestino,
      'data': data,
      'texto': texto,
      'status': status,
    };
  }

  static List<Alert> fromJsonList(List<dynamic> jsonList) {
    return jsonList
        .map((item) => Alert.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }
}

class AlertResponse {
  final List<Alert> account;
  final ResponseStatus response;

  AlertResponse({
    required this.account,
    required this.response,
  });

  factory AlertResponse.fromJson(Map<String, dynamic> json) {
    return AlertResponse(
      account: (json['data']['account'] as List)
          .map((alert) => Alert.fromJson(alert))
          .toList(),
      response: ResponseStatus.fromJson(json['response']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'data': {
        'account': account.map((alert) => alert.toJson()).toList(),
      },
      'response': response.toJson(),
    };
  }
}

class ResponseStatus {
  final bool error;
  final String message;
  final int status;

  ResponseStatus({
    required this.error,
    required this.message,
    required this.status,
  });

  factory ResponseStatus.fromJson(Map<String, dynamic> json) {
    return ResponseStatus(
      error: json['error'],
      message: json['message'],
      status: json['status'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'error': error,
      'message': message,
      'status': status,
    };
  }
}
