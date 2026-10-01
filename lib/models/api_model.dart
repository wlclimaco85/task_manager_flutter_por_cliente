class Data {
  late String firstname;
  late String birthday;
  Data({
    required this.firstname,
    required this.birthday,
  });

  Data.fromJson(Map<String, dynamic> json) {
    firstname = json['firstname'];
    birthday = json['birthday'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['firstname'] = firstname;
    data['birthday'] = birthday;
    return data;
  }
}
