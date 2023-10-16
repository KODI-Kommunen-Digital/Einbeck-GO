import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:heidi/src/data/model/model.dart';
import 'package:heidi/src/data/model/model_category.dart';
import 'package:heidi/src/data/model/model_product.dart';
import 'package:heidi/src/data/repository/list_repository.dart';
import 'package:heidi/src/presentation/cubit/app_bloc.dart';
import 'package:heidi/src/presentation/main/add_listing/cubit/add_listing_state.dart';
import 'package:heidi/src/utils/configs/preferences.dart';
import 'package:heidi/src/utils/logging/loggy_exp.dart';

class AddListingCubit extends Cubit<AddListingState> {
  final ListRepository _repo;

  AddListingCubit(this._repo) : super(const AddListingState.loaded());

  String? selectedCity;
  int? cityId;
  int? villageId;
  int? categoryId;
  int? subCategoryId;
  List listCity = [];
  List listVillage = [];
  List listCategory = [];
  List listSubCategory = [];
  String? selectedVillage;
  String? selectedCategory;
  String? selectedSubCategory;

  Future<bool> onSubmit({
    required String title,
    required String description,
    required int cityId,
    CategoryModel? country,
    CategoryModel? state,
    String? city,
    int? statusId,
    int? sourceId,
    required String address,
    required String place,
    String? zipcode,
    required String? phone,
    String? email,
    String? website,
    String? status,
    String? startDate,
    String? endDate,
    String? price,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
  }) async {
    try {
      final response = await _repo.saveProduct(
          title,
          description,
          place,
          country,
          state,
          city,
          statusId,
          sourceId,
          address,
          zipcode,
          phone,
          email,
          website,
          status,
          startDate,
          endDate,
          startTime,
          endTime);
      if (response.success) {
        return true;
      } else {
        logError('save Product Response Failed', response.message);
        return false;
      }
    } catch (e) {
      logError('save Product Error', e);
      return false;
    }
  }

  Future<int?> getCurrentCityId() async {
    final prefs = await Preferences.openBox();
    return prefs.getKeyValue(Preferences.cityId, 0);
  }

  Future<bool> onEdit({
    int? cityId,
    int? categoryId,
    int? listingId,
    required String title,
    required String description,
    CategoryModel? country,
    CategoryModel? state,
    CategoryModel? city,
    int? statusId,
    int? sourceId,
    required String address,
    required String place,
    String? zipcode,
    required String? phone,
    String? email,
    String? website,
    String? status,
    String? startDate,
    String? endDate,
    String? price,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
    required bool isImageChanged,
  }) async {
    try {
      final response = await _repo.editProduct(
          listingId,
          categoryId,
          cityId,
          title,
          description,
          place,
          country,
          state,
          city,
          statusId,
          sourceId,
          address,
          zipcode,
          phone,
          email,
          website,
          status,
          startDate,
          endDate,
          price,
          isImageChanged,
          startTime,
          endTime);
      if (response.success) {
        await AppBloc.homeCubit.onLoad(false);
        return true;
      } else {
        logError('edit Product Response Failed', response.message);
        return false;
      }
    } catch (e) {
      logError('edit Product Error', e);
      return false;
    }
  }

  Future<bool> changeStatus(ProductModel item, int newStatus) async {
    int listingId = item.id;
    int? categoryId = item.categoryId;
    int? cityId = item.cityId;
    String title = item.title;
    String description = item.description;
    String place = "";
    CategoryModel? country = item.country;
    CategoryModel? state = item.state;
    CategoryModel? city = item.city;
    int? statusId = newStatus;
    int? sourceId = item.sourceId;
    String address = item.address;
    String? zipcode = item.zipCode;
    String? phone = item.phone;
    String? email = item.email;
    String? website = item.website;
    String? status = item.status;
    String? startDate = item.startDate;
    String? endDate = item.endDate;
    String? price = item.price;
    bool isImageChanged = false;
    TimeOfDay? startTime;
    TimeOfDay? endTime;

    if(startDate.isEmpty && endDate.isEmpty) {
      startDate = null;
      endDate = null;
    }

    //Parse Times
    if (startDate != null && endDate != null) {
      List<String> startDateTime = startDate.split(' ');
      List<String> endDateTime = endDate.split(' ');

      if (startDateTime.length == 2) {
        List<String> startTimeParts = startDateTime[1].split(':');
        int startHour = int.parse(startTimeParts[0]);
        int startMinute = int.parse(startTimeParts[1]);
        startTime = TimeOfDay(hour: startHour, minute: startMinute);
        if (endDateTime.length == 2) {
          List<String> endTimeParts = endDateTime[1].split(':');
          int endHour = int.parse(endTimeParts[0]);
          int endMinute = int.parse(endTimeParts[1]);
          endTime = TimeOfDay(hour: endHour, minute: endMinute);
        } else {
          List<String> endTimeParts = endDateTime[0].split(':');
          int endHour = int.parse(endTimeParts[0]);
          int endMinute = int.parse(endTimeParts[1]);
          endTime = TimeOfDay(hour: endHour, minute: endMinute);
        }
      }
    }

    try {
      final response = await _repo.editProduct(
          listingId,
          categoryId,
          cityId,
          title,
          description,
          place,
          country,
          state,
          city,
          statusId,
          sourceId,
          address,
          zipcode,
          phone,
          email,
          website,
          status,
          startDate,
          endDate,
          price,
          isImageChanged,
          startTime,
          endTime);
      if (response.success) {
        return true;
      } else {
        logError('save Product Response Failed', response.message);
        return false;
      }
    } catch (e) {
      logError('save Product Error', e);
      return false;
    }
  }

  void setImagePref(imagePath) async {
    await _repo.setImagePrefs(imagePath);
  }

  void clearVillage() async {
    _repo.clearVillageId();
  }

  Future<void> deletePdf(cityId, listingId) async {
    await _repo.deletePdf(cityId, listingId);
  }

  Future<void> deleteImage(cityId, listingId) async {
    await _repo.deleteImage(cityId, listingId);
  }

  void clearCityId() async {
    _repo.clearCityId();
  }

  void clearCategoryId() async {
    _repo.clearCategoryId();
  }

  Future<ResultApiModel?> getVillageId(value) async {
    try {
      return _repo.requestVillages(value);
    } catch (e) {
      logError('request Village Error', e);
      emit(AddListingState.error(e.toString()));
      return null;
    }
  }

  void setCategoryId(value) async {
    try {
      _repo.setCategoryId(value);
    } catch (e) {
      logError('request categoryID Error', e);
    }
  }

  void getSubCategoryId(value) async {
    try {
      _repo.getSubCategoryId(value);
    } catch (e) {
      logError('request subCategoryID Error', e);
    }
  }

  Future<ResultApiModel?> loadSubCategory(value) async {
    try {
      if (value != null) {
        final subCategoryResponse = _repo.loadSubCategory(value);
        return subCategoryResponse;
      }
      return null;
    } catch (e) {
      logError('request subCategoryID Error', e);
      return null;
    }
  }

  void clearSubCategory() async {
    _repo.clearSubCategory();
  }

  Future<ResultApiModel?> loadCities() async {
    try {
      final loadCitiesResponse = _repo.loadCities();
      return loadCitiesResponse;
    } catch (e) {
      logError('load cities error', e.toString());
      return null;
    }
  }

  Future<ResultApiModel?> loadCategory() async {
    try {
      final loadCategoryResponse = _repo.loadCategory();
      return loadCategoryResponse;
    } catch (e) {
      logError('load category error', e.toString());
      return null;
    }
  }

  Future<ResultApiModel> loadVillages(value) async {
    final response = await _repo.loadVillages(value);
    return response;
  }

  Future<void> clearImagePath() async {
    _repo.clearImagePath();
  }
}
