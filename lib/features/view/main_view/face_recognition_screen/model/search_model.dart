// To parse this JSON data, do
//
//     final searchModel = searchModelFromJson(jsonString);

import 'dart:convert';

SearchModel searchModelFromJson(String str) => SearchModel.fromJson(json.decode(str));

String searchModelToJson(SearchModel data) => json.encode(data.toJson());

class SearchModel {
  List<Datum>? data;
  Payload? payload;

  SearchModel({this.data, this.payload});

  factory SearchModel.fromJson(Map<String, dynamic> json) =>
      SearchModel(data: json["data"] == null ? [] : List<Datum>.from(json["data"]!.map((x) => Datum.fromJson(x))), payload: json["payload"] == null ? null : Payload.fromJson(json["payload"]));

  Map<String, dynamic> toJson() => {"data": data == null ? [] : List<dynamic>.from(data!.map((x) => x.toJson())), "payload": payload?.toJson()};
}

class Datum {
  int? id;
  String? userType;
  int? referenceId;
  String? image;
  String? imageUrl;
  int? classId;
  String? division;
  String? status;
  String? fullName;
  DateTime? createdAt;
  DateTime? updatedAt;
  int? createdBy;

  Datum({this.id, this.userType, this.referenceId, this.image, this.imageUrl, this.classId, this.division, this.status, this.fullName, this.createdAt, this.updatedAt, this.createdBy});

  factory Datum.fromJson(Map<String, dynamic> json) => Datum(
    id: json["id"],
    userType: json["user_type"],
    referenceId: json["reference_id"],
    image: json["image"],
    imageUrl: json["image_url"],
    classId: json["class_id"],
    division: json["division"],
    status: json["status"],
    fullName: json["full_name"],
    createdAt: json["created_at"] == null ? null : DateTime.parse(json["created_at"]),
    updatedAt: json["updated_at"] == null ? null : DateTime.parse(json["updated_at"]),
    createdBy: json["created_by"],
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "user_type": userType,
    "reference_id": referenceId,
    "image": image,
    "image_url": imageUrl,
    "class_id": classId,
    "division": division,
    "status": status,
    "full_name": fullName,
    "created_at": createdAt?.toIso8601String(),
    "updated_at": updatedAt?.toIso8601String(),
    "created_by": createdBy,
  };
}

class Payload {
  Pagination? pagination;

  Payload({this.pagination});

  factory Payload.fromJson(Map<String, dynamic> json) => Payload(pagination: json["pagination"] == null ? null : Pagination.fromJson(json["pagination"]));

  Map<String, dynamic> toJson() => {"pagination": pagination?.toJson()};
}

class Pagination {
  int? page;
  String? firstPageUrl;
  int? from;
  int? lastPage;
  List<Link>? links;
  dynamic nextPageUrl;
  int? itemsPerPage;
  dynamic prevPageUrl;
  int? to;
  int? total;

  Pagination({this.page, this.firstPageUrl, this.from, this.lastPage, this.links, this.nextPageUrl, this.itemsPerPage, this.prevPageUrl, this.to, this.total});

  factory Pagination.fromJson(Map<String, dynamic> json) => Pagination(
    page: json["page"],
    firstPageUrl: json["first_page_url"],
    from: json["from_"],
    lastPage: json["last_page"],
    links: json["links"] == null ? [] : List<Link>.from(json["links"]!.map((x) => Link.fromJson(x))),
    nextPageUrl: json["next_page_url"],
    itemsPerPage: json["items_per_page"],
    prevPageUrl: json["prev_page_url"],
    to: json["to"],
    total: json["total"],
  );

  Map<String, dynamic> toJson() => {
    "page": page,
    "first_page_url": firstPageUrl,
    "from_": from,
    "last_page": lastPage,
    "links": links == null ? [] : List<dynamic>.from(links!.map((x) => x.toJson())),
    "next_page_url": nextPageUrl,
    "items_per_page": itemsPerPage,
    "prev_page_url": prevPageUrl,
    "to": to,
    "total": total,
  };
}

class Link {
  String? url;
  dynamic label;
  bool? active;
  int? page;

  Link({this.url, this.label, this.active, this.page});

  factory Link.fromJson(Map<String, dynamic> json) => Link(url: json["url"], label: json["label"], active: json["active"], page: json["page"]);

  Map<String, dynamic> toJson() => {"url": url, "label": label, "active": active, "page": page};
}
