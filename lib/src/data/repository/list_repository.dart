import 'dart:io';

import 'package:dio/dio.dart';
import 'package:heidi/src/data/model/model.dart';
import 'package:heidi/src/data/model/model_category.dart';
import 'package:heidi/src/data/model/model_product.dart';
import 'package:heidi/src/data/remote/api/api.dart';
import 'package:heidi/src/utils/configs/application.dart';
import 'package:heidi/src/utils/configs/preferences.dart';
import 'package:heidi/src/utils/logger.dart';
import 'package:heidi/src/utils/logging/loggy_exp.dart';
import 'package:http_parser/http_parser.dart';

class ListRepository {
  final Preferences prefs;

  ListRepository(this.prefs);

  static Future<List?> loadList({
    required categoryId,
    required type,
  }) async {
    final preference = await Preferences.openBox();
    final cityId = preference.getKeyValue(Preferences.cityId, 0);
    if (type == "category") {
      int params = categoryId;
      final response = await Api.requestCatList(params);
      if (response.success) {
        final list = List.from(response.data ?? []).map((item) {
          return ProductModel.fromJson(item, setting: Application.setting);
        }).toList();
        if (cityId != 0) {
          list.removeWhere((element) => element.cityId != cityId);
        }
        return [list, response.pagination];
      }
    } else if (type == "location") {
      int params = cityId;
      final response = await Api.requestLocList(params);
      if (response.success) {
        final list = List.from(response.data ?? []).map((item) {
          return ProductModel.fromJson(item, setting: Application.setting);
        }).toList();

        return [list, response.pagination];
      }
    } else if (type == "categoryService") {
      int params = categoryId;
      final response = await Api.requestCatList(params);
      if (response.success) {
        final list = List.from(response.data ?? []).map((item) {
          return ProductModel.fromJson(item, setting: Application.setting);
        }).toList();
        if (cityId != 0) {
          list.removeWhere((element) => element.cityId != cityId);
        }
        return [list, response.pagination];
      }
    } else if (type == "subCategoryService") {
      final response = await Api.requestSubCatList(cityId);
      if (response.success) {
        final list = List.from(response.data ?? []).map((item) {
          return ProductModel.fromJson(item, setting: Application.setting);
        }).toList();
        return [list, response.pagination];
      }
    }
    return null;
  }

  ///load wish list
  // static Future<List?> loadWishList({
  //   int? page,
  //   int? perPage,
  // }) async {
  //   Map<String, dynamic> params = {
  //     "page": page,
  //     "per_page": perPage,
  //   };
  //   final response = await Api.requestWishList(params);
  //   if (response.success) {
  //     final list = List.from(response.data ?? []).map((item) {
  //       return ProductModel.fromJson(item, setting: Application.setting);
  //     }).toList();

  //     return [list, response.pagination];
  //   }
  //   AppBloc.messageCubit.onShow(response.message);
  //   return null;
  // }

  static Future<bool> addWishList(int? userId, ProductModel items) async {
    final Map<String, dynamic> params = {};
    params['cityId'] = items.cityId;
    params['listingId'] = items.id;
    final response = await Api.requestAddWishList(userId, params);
    if (response.success) {
      return true;
    } else {
      logError('Add Wishlist Response Fail', response.message);
      return false;
    }
  }

  static Future<bool> removeWishList(int? userId, int listingId) async {
    final response = await Api.requestRemoveWishList(userId, listingId);
    if (response.success) {
      logError('Remove Wishlist Response Success', response.message);
      return true;
    } else {
      logError('Remove Wishlist Response Failed', response.message);
      return false;
    }
  }

  //
  // ///clear wishList
  // static Future<bool> clearWishList() async {
  //   final response = await Api.requestClearWishList();
  //   AppBloc.messageCubit.onShow(response.message);
  //   if (response.success) {
  //     return true;
  //   }
  //   return false;
  // }
  //
  // ///load author post
  // static Future<List?> loadAuthorList({
  //   required int page,
  //   required int perPage,
  //   required String keyword,
  //   required int userID,
  //   required FilterModel filter,
  //   bool? pending,
  // }) async {
  //   Map<String, dynamic> params = {
  //     "page": page,
  //     "per_page": perPage,
  //     "s": keyword,
  //     "user_id": userID,
  //   };
  //   if (pending == true) {
  //     params['post_status'] = 'pending';
  //   }
  //   params.addAll(await filter.getParams());
  //   final response = await Api.requestAuthorList(params);
  //   if (response.success) {
  //     final list = List.from(response.data ?? []).map((item) {
  //       return ProductModel.fromJson(item, setting: Application.setting);
  //     }).toList();
  //     return [list, response.pagination, response.user];
  //   }
  //   AppBloc.messageCubit.onShow(response.message);
  //   return null;
  // }

  ///Upload image
  static Future<ResultApiModel?> uploadImage(File image, origin) async {
    final prefs = await Preferences.openBox();
    final formData = FormData.fromMap({
      'image': await MultipartFile.fromFile(image.path,
          filename: image.path, contentType: MediaType('image', '')),
    });
    if (origin == 'profile' || origin == 'Profil') {
      final response = await Api.requestUploadImage(formData);
      return response;
    } else if (origin == 'Upload feature image' ||
        origin == 'Feature-Bild hochladen') {
      await prefs.setPickedFile(formData);
    }
    return null;
  }

  static Future<ProductModel?> loadProduct(cityId, id) async {
    final response = await Api.requestProduct(cityId, id);
    if (response.success) {
      UtilLogger.log('ErrorReason', response.data);
      return ProductModel.fromJson(response.data, setting: Application.setting);
    } else {
      logError('Product Request Response', response.message);
    }
    return null;
  }

  Future<ResultApiModel> requestVillages(value) async {
    final cityId = prefs.getKeyValue(Preferences.cityId, '');
    final response = await Api.requestVillages(cityId: cityId);
    var jsonCategory = response.data;
    final item = jsonCategory.firstWhere((item) => item['name'] == value);
    final itemId = item['id'];
    // logError()
    final villageId = itemId;
    prefs.setKeyValue(Preferences.villageId, villageId);
    return response;
  }

  void clearVillageId() async {
    prefs.deleteKey(Preferences.villageId);
  }

  void clearCityId() async {
    prefs.deleteKey(Preferences.cityId);
  }

  void clearCategoryId() async {
    prefs.deleteKey(Preferences.categoryId);
  }

  Future<void> clearImagePath() async {
    prefs.deleteKey(Preferences.path);
  }

  Future<ResultApiModel> loadCities() async {
    final response = await Api.requestSubmitCities();
    var jsonCity = response.data;
    final selectedCity = jsonCity.first['name'];
    final cityId = jsonCity.first['id'];
    prefs.setKeyValue(Preferences.cityId, cityId as int);
    loadVillages(selectedCity);
    return response;
  }

  Future<ResultApiModel> loadCategory() async {
    final response = await Api.requestSubmitCategory();
    var jsonCategory = response.data;
    final categoryId = jsonCategory.first['id'];
    prefs.setKeyValue(Preferences.categoryId, categoryId as int);
    return response;
  }

  Future<ResultApiModel> loadSubCategory(value) async {
    final response = await Api.requestSubmitCategory();
    var jsonCategory = response.data;
    final item = jsonCategory.firstWhere((item) => item['name'] == value);
    final itemId = item['id'];
    final categoryId = itemId;
    final requestSubmitResponse =
        await Api.requestSubmitSubCategory(categoryId: categoryId);
    final jsonSubCategory = requestSubmitResponse.data;
    if (!jsonSubCategory.isEmpty) {
      final subCategoryId = jsonSubCategory.first['id'];
      prefs.setKeyValue(Preferences.subCategoryId, subCategoryId as int);
    }
    return requestSubmitResponse;
  }

  Future<ResultApiModel> saveProduct(
    cityId,
    String title,
    String description,
    String place,
    CategoryModel? country,
    CategoryModel? state,
    CategoryModel? city,
    int? statusId,
    int? sourceId,
    String address,
    String? zipcode,
    String? phone,
    String? email,
    String? website,
    String? status,
    String? startDate,
    String? endDate,
    String? price,
  ) async {
    final subCategoryId = prefs.getKeyValue(Preferences.subCategoryId, null);
    final categoryId = prefs.getKeyValue(Preferences.categoryId, '');
    final villageId = prefs.getKeyValue(Preferences.villageId, null);
    final userId = prefs.getKeyValue(Preferences.userId, '');
    final cityId = prefs.getKeyValue(Preferences.cityId, '');
    final media = prefs.getKeyValue(Preferences.path, null);

    Map<String, dynamic> params = {
      "userId": userId,
      "title": title,
      "place": place,
      "description": description,
      "media": '',
      "categoryId": categoryId,
      "address": address,
      "email": email,
      "phone": phone,
      "website": website,
      "price": 100, //dummy data
      "discountPrice": 100, //dummy data
      "logo": media,
      "statusId": 3, //dummy data
      "sourceId": 1, //dummy data
      "longitude": 245.65, //dummy data
      "latitude": 22.456, //dummy data
      "villageId": villageId ?? 0,
      "cityId": cityId,
      "startDate": startDate,
      "endDate": endDate,
      "subCategoryId": subCategoryId,
    };
    final response = await Api.requestSaveProduct(cityId, params);
    return response;
  }

  Future<ResultApiModel> loadVillages(value) async {
    final response = await Api.requestSubmitCities();
    var jsonCity = response.data;
    final item = jsonCity.firstWhere((item) => item['name'] == value);
    final itemId = item['id'];
    final cityId = itemId;
    prefs.setKeyValue(Preferences.cityId, cityId);
    final requestVillageResponse = await Api.requestVillages(cityId: cityId);
    if (!requestVillageResponse.data.isEmpty) {
      prefs.setKeyValue(Preferences.villageId,
          requestVillageResponse.data.first['id'] as int);
    }
    return requestVillageResponse;
  }

  void getCategoryId(value) async {
    final response = await Api.requestSubmitCategory();
    var jsonCategory = response.data;
    final item = jsonCategory.firstWhere((item) => item['name'] == value);
    final itemId = item['id'];
    final categoryId = itemId;
    prefs.setKeyValue(Preferences.categoryId, categoryId);
  }

  void getSubCategoryId(value) async {
    final categoryId = prefs.getKeyValue(Preferences.categoryId, '');
    final response = await Api.requestSubmitSubCategory(categoryId: categoryId);
    var jsonCategory = response.data;
    final item = jsonCategory.firstWhere((item) => item['name'] == value);
    final itemId = item['id'];
    final subCategoryId = itemId;
    prefs.setKeyValue(Preferences.subCategoryId, subCategoryId);
  }

  void clearSubCategory() async {
    prefs.deleteKey(Preferences.subCategoryId);
  }

//
// ///save product
// static Future<bool> saveProduct(cityId, params) async {
//   final response = await Api.requestSaveProduct(cityId, params);
//   AppBloc.messageCubit.onShow(response.message);
//   if (response.success) {
//     return true;
//   } else {
//     return false;
//   }
// }
//
// ///Delete author item
// static Future<bool> removeProduct(id) async {
//   final response = await Api.requestDeleteProduct({"post_id": id});
//   AppBloc.messageCubit.onShow(response.message);
//   if (response.success) {
//     return true;
//   }
//   return false;
// }
//
// ///Load tags list with keyword
// static Future<List<String>?> loadTags(String keyword) async {
//   final response = await Api.requestTags({"s": keyword});
//   if (response.success) {
//     return List.from(response.data ?? []).map((e) {
//       return e['name'] as String;
//     }).toList();
//   }
//   AppBloc.messageCubit.onShow(response.message);
//   return [];
// }
}
