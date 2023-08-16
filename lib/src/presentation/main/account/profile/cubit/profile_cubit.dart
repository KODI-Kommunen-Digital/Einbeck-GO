import 'package:bloc/bloc.dart';
import 'package:heidi/src/data/model/model_product.dart';
import 'package:heidi/src/data/model/model_user.dart';
import 'package:heidi/src/data/repository/list_repository.dart';
import 'package:heidi/src/presentation/main/account/profile/cubit/profile_state.dart';
import 'package:intl/intl.dart';

class ProfileCubit extends Cubit<ProfileState> {
  ListRepository repo;
  UserModel userModel;

  ProfileCubit(this.repo, this.userModel)
      : super(const ProfileState.loading()) {
    loadUserListing();
  }

  Future<List<ProductModel>> loadUserListing() async {
    List<ProductModel> listDataList = [];
    final result = await repo.loadUserListings();
    for (final list in result) {
      final product = await loadProduct(list.cityId, list.id);
      if (product != null) {
        listDataList.add(ProductModel(
            id: list.id,
            cityId: list.cityId,
            title: product.title,
            image: product.image,
            startDate: product.startDate,
            endDate: product.endDate,
            createDate: product.createDate,
            favorite: product.favorite,
            address: product.address,
            phone: product.phone,
            email: product.email,
            website: product.website,
            description: product.description,
            userId: product.userId));
      }
    }
    emit(ProfileState.loaded(listDataList));
    return listDataList;
  }

  Future<ProductModel?> loadProduct(cityId, id) async {
    final loadProductResponse = await ListRepository.loadProduct(cityId, id);
    return loadProductResponse;
  }

  String onDateParse(String date) {
    final parsedDateTime = DateTime.parse(date);
    var createDate = DateFormat('dd.MM.yyyy').format(parsedDateTime);
    return createDate;
  }

  Future<bool> deleteUserList(String? cityId, int listingId) async {
    int id = int.parse(cityId!);
    final deleteResponse = await repo.deleteUserList(id, listingId);
    return deleteResponse;
  }
}
