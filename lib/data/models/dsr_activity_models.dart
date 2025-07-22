import 'dart:convert';

class DropdownOption {
  final String code;
  final String description;

  DropdownOption({required this.code, required this.description});

  factory DropdownOption.fromJson(Map<String, dynamic> json) => DropdownOption(
        code: json['Code'] ?? '',
        description: json['Description'] ?? '',
      );

  Map<String, dynamic> toJson() => {
        'Code': code,
        'Description': description,
      };
}

class DsrActivityRequest {
  String processType;
  DateTime submissionDate;
  DateTime reportDate;
  String createId;
  String areaCode;
  String purchaser;
  String purchaserCode;
  String deptCode;
  String statFlag;
  String cusRtlCd;
  String marketName;
  String participationDisplayContest;
  String pendingIssues;
  String pendingIssueDetails;
  String issueSpecification;
  double wcEnrollmentSlab;
  double wcpEnrollmentSlab;
  double vapEnrollmentSlab;
  double bwStockWc;
  double bwStockWcp;
  double bwStockVap;
  String brandsSellingWc;
  String brandsSellingWcp;
  String wcIndustryVolume;
  String wcpIndustryVolume;
  DateTime? orderExecutionDate;
  String otherRemarks;
  String latitude;
  String longitude;
  String customerLatitude;
  String customerLongitude;
  String locationAddress;
  String exceptionReason;
  bool isTileRetailer;
  double tileStock;
  String? documentNumber;
  List<DsrDetailRequest> details;
  List<MarketDetailRequest> marketDetails;
  List<GiftDistributionRequest> giftDistribution;
  List<LastThreeMonthsAverage> lastThreeMonthsData;

  DsrActivityRequest({
    this.processType = 'A',
    DateTime? submissionDate,
    DateTime? reportDate,
    this.createId = '',
    this.areaCode = '',
    this.purchaser = '',
    this.purchaserCode = '',
    this.deptCode = '',
    this.statFlag = 'N',
    this.cusRtlCd = '',
    this.marketName = '',
    this.participationDisplayContest = '',
    this.pendingIssues = '',
    this.pendingIssueDetails = '',
    this.issueSpecification = '',
    this.wcEnrollmentSlab = 0,
    this.wcpEnrollmentSlab = 0,
    this.vapEnrollmentSlab = 0,
    this.bwStockWc = 0,
    this.bwStockWcp = 0,
    this.bwStockVap = 0,
    this.brandsSellingWc = '',
    this.brandsSellingWcp = '',
    this.wcIndustryVolume = '',
    this.wcpIndustryVolume = '',
    this.orderExecutionDate,
    this.otherRemarks = '',
    this.latitude = '',
    this.longitude = '',
    this.customerLatitude = '',
    this.customerLongitude = '',
    this.locationAddress = '',
    this.exceptionReason = '',
    this.isTileRetailer = false,
    this.tileStock = 0,
    this.documentNumber,
    List<DsrDetailRequest>? details,
    List<MarketDetailRequest>? marketDetails,
    List<GiftDistributionRequest>? giftDistribution,
    List<LastThreeMonthsAverage>? lastThreeMonthsData,
  })  : submissionDate = submissionDate ?? DateTime.now(),
        reportDate = reportDate ?? DateTime.now(),
        details = details ?? [],
        marketDetails = marketDetails ?? [],
        giftDistribution = giftDistribution ?? [],
        lastThreeMonthsData = lastThreeMonthsData ?? [];

  Map<String, dynamic> toJson() => {
        'ProcessType': processType,
        'SubmissionDate': submissionDate.toIso8601String(),
        'ReportDate': reportDate.toIso8601String(),
        'CreateId': createId,
        'AreaCode': areaCode,
        'Purchaser': purchaser,
        'PurchaserCode': purchaserCode,
        'DeptCode': deptCode,
        'StatFlag': statFlag,
        'CusRtlCd': cusRtlCd,
        'MarketName': marketName,
        'ParticipationDisplayContest': participationDisplayContest,
        'PendingIssues': pendingIssues,
        'PendingIssueDetails': pendingIssueDetails,
        'IssueSpecification': issueSpecification,
        'WcEnrollmentSlab': wcEnrollmentSlab,
        'WcpEnrollmentSlab': wcpEnrollmentSlab,
        'VapEnrollmentSlab': vapEnrollmentSlab,
        'BwStockWc': bwStockWc,
        'BwStockWcp': bwStockWcp,
        'BwStockVap': bwStockVap,
        'BrandsSellingWc': brandsSellingWc,
        'BrandsSellingWcp': brandsSellingWcp,
        'WcIndustryVolume': wcIndustryVolume,
        'WcpIndustryVolume': wcpIndustryVolume,
        'OrderExecutionDate': orderExecutionDate?.toIso8601String(),
        'OtherRemarks': otherRemarks,
        'Latitude': latitude,
        'Longitude': longitude,
        'CustomerLatitude': customerLatitude,
        'CustomerLongitude': customerLongitude,
        'LocationAddress': locationAddress,
        'ExceptionReason': exceptionReason,
        'IsTileRetailer': isTileRetailer,
        'TileStock': tileStock,
        'DocumentNumber': documentNumber,
        'Details': details.map((e) => e.toJson()).toList(),
        'MarketDetails': marketDetails.map((e) => e.toJson()).toList(),
        'GiftDistribution': giftDistribution.map((e) => e.toJson()).toList(),
        'LastThreeMonthsData': lastThreeMonthsData.map((e) => e.toJson()).toList(),
      };
}

class DsrDetailRequest {
  String productCategory;
  String productCode;
  double productQuantity;
  double projectedQuantity;
  String actionRemarks;
  DateTime? targetDate;

  DsrDetailRequest({
    this.productCategory = '',
    this.productCode = '',
    this.productQuantity = 0,
    this.projectedQuantity = 0,
    this.actionRemarks = '',
    this.targetDate,
  });

  Map<String, dynamic> toJson() => {
        'ProductCategory': productCategory,
        'ProductCode': productCode,
        'ProductQuantity': productQuantity,
        'ProjectedQuantity': projectedQuantity,
        'ActionRemarks': actionRemarks,
        'TargetDate': targetDate?.toIso8601String(),
      };
}

class MarketDetailRequest {
  String brandName;
  String productCode;
  double priceB;
  double priceC;

  MarketDetailRequest({
    this.brandName = '',
    this.productCode = '',
    this.priceB = 0,
    this.priceC = 0,
  });

  Map<String, dynamic> toJson() => {
        'BrandName': brandName,
        'ProductCode': productCode,
        'PriceB': priceB,
        'PriceC': priceC,
      };
}

class GiftDistributionRequest {
  String giftType;
  double quantity;

  GiftDistributionRequest({
    this.giftType = '',
    this.quantity = 0,
  });

  Map<String, dynamic> toJson() => {
        'GiftType': giftType,
        'Quantity': quantity,
      };
}

class LastThreeMonthsAverage {
  String type;
  double wcQuantity;
  double wcpQuantity;

  LastThreeMonthsAverage({
    this.type = '',
    this.wcQuantity = 0,
    this.wcpQuantity = 0,
  });

  Map<String, dynamic> toJson() => {
        'Type': type,
        'WcQuantity': wcQuantity,
        'WcpQuantity': wcpQuantity,
      };
}

class DsrActivityResponse {
  String documentNumber;
  String status;
  DateTime documentDate;
  String customerCode;
  String customerName;
  String areaCode;
  String marketName;
  String participationDisplayContest;
  String pendingIssues;
  String pendingIssueDetails;
  String issueSpecification;
  double wcEnrollmentSlab;
  double wcpEnrollmentSlab;
  double vapEnrollmentSlab;
  double bwStockWc;
  double bwStockWcp;
  double bwStockVap;
  String brandsSellingWc;
  String brandsSellingWcp;
  DateTime? orderExecutionDate;
  String otherRemarks;
  String latitude;
  String longitude;
  String customerLatitude;
  String customerLongitude;
  bool isTileRetailer;
  double tileStock;
  List<DsrDetailResponse> details;
  List<MarketDetailResponse> marketDetails;
  List<GiftDistributionResponse> giftDistribution;

  DsrActivityResponse({
    this.documentNumber = '',
    this.status = '',
    DateTime? documentDate,
    this.customerCode = '',
    this.customerName = '',
    this.areaCode = '',
    this.marketName = '',
    this.participationDisplayContest = '',
    this.pendingIssues = '',
    this.pendingIssueDetails = '',
    this.issueSpecification = '',
    this.wcEnrollmentSlab = 0,
    this.wcpEnrollmentSlab = 0,
    this.vapEnrollmentSlab = 0,
    this.bwStockWc = 0,
    this.bwStockWcp = 0,
    this.bwStockVap = 0,
    this.brandsSellingWc = '',
    this.brandsSellingWcp = '',
    this.orderExecutionDate,
    this.otherRemarks = '',
    this.latitude = '',
    this.longitude = '',
    this.customerLatitude = '',
    this.customerLongitude = '',
    this.isTileRetailer = false,
    this.tileStock = 0,
    List<DsrDetailResponse>? details,
    List<MarketDetailResponse>? marketDetails,
    List<GiftDistributionResponse>? giftDistribution,
  })  : documentDate = documentDate ?? DateTime.now(),
        details = details ?? [],
        marketDetails = marketDetails ?? [],
        giftDistribution = giftDistribution ?? [];

  factory DsrActivityResponse.fromJson(Map<String, dynamic> json) => DsrActivityResponse(
        documentNumber: json['DocumentNumber'] ?? '',
        status: json['Status'] ?? '',
        documentDate: DateTime.tryParse(json['DocumentDate'] ?? '') ?? DateTime.now(),
        customerCode: json['CustomerCode'] ?? '',
        customerName: json['CustomerName'] ?? '',
        areaCode: json['AreaCode'] ?? '',
        marketName: json['MarketName'] ?? '',
        participationDisplayContest: json['ParticipationDisplayContest'] ?? '',
        pendingIssues: json['PendingIssues'] ?? '',
        pendingIssueDetails: json['PendingIssueDetails'] ?? '',
        issueSpecification: json['IssueSpecification'] ?? '',
        wcEnrollmentSlab: (json['WcEnrollmentSlab'] ?? 0).toDouble(),
        wcpEnrollmentSlab: (json['WcpEnrollmentSlab'] ?? 0).toDouble(),
        vapEnrollmentSlab: (json['VapEnrollmentSlab'] ?? 0).toDouble(),
        bwStockWc: (json['BwStockWc'] ?? 0).toDouble(),
        bwStockWcp: (json['BwStockWcp'] ?? 0).toDouble(),
        bwStockVap: (json['BwStockVap'] ?? 0).toDouble(),
        brandsSellingWc: json['BrandsSellingWc'] ?? '',
        brandsSellingWcp: json['BrandsSellingWcp'] ?? '',
        orderExecutionDate: json['OrderExecutionDate'] != null ? DateTime.tryParse(json['OrderExecutionDate']) : null,
        otherRemarks: json['OtherRemarks'] ?? '',
        latitude: json['Latitude'] ?? '',
        longitude: json['Longitude'] ?? '',
        customerLatitude: json['CustomerLatitude'] ?? '',
        customerLongitude: json['CustomerLongitude'] ?? '',
        isTileRetailer: json['IsTileRetailer'] ?? false,
        tileStock: (json['TileStock'] ?? 0).toDouble(),
        details: (json['Details'] as List?)?.map((e) => DsrDetailResponse.fromJson(e)).toList() ?? [],
        marketDetails: (json['MarketDetails'] as List?)?.map((e) => MarketDetailResponse.fromJson(e)).toList() ?? [],
        giftDistribution: (json['GiftDistribution'] as List?)?.map((e) => GiftDistributionResponse.fromJson(e)).toList() ?? [],
      );
}

class DsrDetailResponse {
  String productCategory;
  String productCode;
  double productQuantity;
  double projectedQuantity;
  String actionRemarks;
  DateTime? targetDate;

  DsrDetailResponse({
    this.productCategory = '',
    this.productCode = '',
    this.productQuantity = 0,
    this.projectedQuantity = 0,
    this.actionRemarks = '',
    this.targetDate,
  });

  factory DsrDetailResponse.fromJson(Map<String, dynamic> json) => DsrDetailResponse(
        productCategory: json['ProductCategory'] ?? '',
        productCode: json['ProductCode'] ?? '',
        productQuantity: (json['ProductQuantity'] ?? 0).toDouble(),
        projectedQuantity: (json['ProjectedQuantity'] ?? 0).toDouble(),
        actionRemarks: json['ActionRemarks'] ?? '',
        targetDate: json['TargetDate'] != null ? DateTime.tryParse(json['TargetDate']) : null,
      );
}

class MarketDetailResponse {
  String brandName;
  String productCode;
  double priceB;
  double priceC;

  MarketDetailResponse({
    this.brandName = '',
    this.productCode = '',
    this.priceB = 0,
    this.priceC = 0,
  });

  factory MarketDetailResponse.fromJson(Map<String, dynamic> json) => MarketDetailResponse(
        brandName: json['BrandName'] ?? '',
        productCode: json['ProductCode'] ?? '',
        priceB: (json['PriceB'] ?? 0).toDouble(),
        priceC: (json['PriceC'] ?? 0).toDouble(),
      );
}

class GiftDistributionResponse {
  String giftType;
  double quantity;

  GiftDistributionResponse({
    this.giftType = '',
    this.quantity = 0,
  });

  factory GiftDistributionResponse.fromJson(Map<String, dynamic> json) => GiftDistributionResponse(
        giftType: json['GiftType'] ?? '',
        quantity: (json['Quantity'] ?? 0).toDouble(),
      );
} 