// ignore_for_file: deprecated_member_use, null_argument_to_non_null_type, use_build_context_synchronously

import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:heidi/src/data/model/model.dart';
import 'package:heidi/src/data/model/model_favorite.dart';
import 'package:heidi/src/data/model/model_product.dart';
import 'package:heidi/src/presentation/main/home/product_detail/cubit/cubit.dart';
import 'package:heidi/src/presentation/widget/app_button.dart';
import 'package:heidi/src/presentation/widget/app_placeholder.dart';
import 'package:heidi/src/presentation/widget/app_user_info.dart';
import 'package:heidi/src/utils/configs/application.dart';
import 'package:heidi/src/utils/configs/routes.dart';
import 'package:heidi/src/utils/translate.dart';
import 'package:url_launcher/url_launcher.dart';

class ProductDetailScreen extends StatefulWidget {
  const ProductDetailScreen({Key? key, required this.item}) : super(key: key);

  final ProductModel item;

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final _scrollController = ScrollController();
  final _productDetailCubit = ProductDetailCubit();
  Color? _iconColor = Colors.white;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _productDetailCubit.onLoad(widget.item);
  }

  @override
  void dispose() {
    _productDetailCubit.close();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    Color? color;
    if (_scrollController.position.extentBefore < 110) {
      color = Colors.white;
    }
    if (color != _iconColor) {
      setState(() {
        _iconColor = color;
      });
    }
  }

  void _showMessage(String message) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            Translate.of(context).translate('explore_product'),
          ),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(
                  message,
                  style: Theme.of(context).textTheme.bodyText1,
                ),
              ],
            ),
          ),
          actions: <Widget>[
            AppButton(
              Translate.of(context).translate('close'),
              onPressed: () {
                Navigator.of(context).pop();
              },
              type: ButtonType.text,
            ),
          ],
        );
      },
    );
  }

  ///Phone action
  void _phoneAction(String phone) async {
    String cleanedPhone = phone.replaceAll(' ', '');
    try {
      await launch('tel:$cleanedPhone');
    } catch (e) {
      _showMessage(Translate.of(context).translate('cannot_make_action'));
    }
  }

  ///Mail action
  void _mailAction(String email) async {
    try {
      launch('mailto:$email');
    } catch (e) {
      _showMessage(Translate.of(context).translate('cannot_make_action'));
    }
  }

  Future<void> _makeAction(String link) async {
    if (!link.startsWith("https://") && !link.startsWith("http://")) {
      link = "https://$link";
    }
    if (await canLaunch(link)) {
      await launchUrl(Uri.parse(link), mode: LaunchMode.inAppWebView);
    } else {
      throw 'Could not launch $link';
    }
  }

  ///Build content UI
  Widget _buildContent(ProductModel? product, List<FavoriteModel>? favoriteList,
      UserModel? userDetail, bool isLoggedIn) {
    ///Build UI loading
    List<Widget> action = [];
    Widget actionGalleries = Container();
    // Widget actionMapView = Container();
    Widget banner = AppPlaceholder(
      child: Container(
        color: Colors.white,
      ),
    );
    Widget address = Container();
    Widget phone = Container();
    Widget fax = Container();
    Widget email = Container();
    Widget website = Container();
    Widget startDate = Container();
    Widget endDate = Container();
    Widget openHours = Container();
    Widget attachments = Container();
    Widget description = Container();
    Widget createdDate = Container();
    Widget info = AppPlaceholder(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              margin: const EdgeInsets.symmetric(vertical: 16),
              height: 16,
              width: 150,
              color: Colors.white,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Container(
                      height: 16,
                      width: 100,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 4),
                    Container(
                      height: 20,
                      width: 150,
                      color: Colors.white,
                    ),
                  ],
                ),
                Container(
                  height: 10,
                  width: 100,
                  color: Colors.white,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: <Widget>[
                Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Container(
                      height: 10,
                      width: 100,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 4),
                    Container(
                      height: 10,
                      width: 200,
                      color: Colors.white,
                    ),
                  ],
                )
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: <Widget>[
                Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Container(
                      height: 10,
                      width: 100,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 4),
                    Container(
                      height: 10,
                      width: 200,
                      color: Colors.white,
                    ),
                  ],
                )
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: <Widget>[
                Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Container(
                      height: 10,
                      width: 100,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 4),
                    Container(
                      height: 10,
                      width: 200,
                      color: Colors.white,
                    ),
                  ],
                )
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: <Widget>[
                Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Container(
                      height: 10,
                      width: 100,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 4),
                    Container(
                      height: 10,
                      width: 200,
                      color: Colors.white,
                    ),
                  ],
                )
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: <Widget>[
                Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Container(
                      height: 10,
                      width: 100,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 4),
                    Container(
                      height: 10,
                      width: 200,
                      color: Colors.white,
                    ),
                  ],
                )
              ],
            ),
            const SizedBox(height: 24),
            Container(height: 10, color: Colors.white),
            const SizedBox(height: 4),
            Container(height: 10, color: Colors.white),
            const SizedBox(height: 4),
            Container(height: 10, color: Colors.white),
            const SizedBox(height: 4),
            Container(height: 10, color: Colors.white),
            const SizedBox(height: 4),
            Container(height: 10, color: Colors.white),
            const SizedBox(height: 4),
            Container(height: 10, color: Colors.white),
          ],
        ),
      ),
    );

    if (product != null) {
      ///Action
      action = [
        actionGalleries,
        const SizedBox(width: 8),
      ];

      banner = InkWell(
        onTap: () {
          Navigator.pushNamed(
            context,
            Routes.imageZoom,
            arguments: "${Application.picturesURL}${product.image}",
          );
        },
        child: CachedNetworkImage(
          imageUrl: "${Application.picturesURL}${product.image}",
          placeholder: (context, url) {
            return AppPlaceholder(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                ),
              ),
            );
          },
          imageBuilder: (context, imageProvider) {
            return Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: imageProvider,
                  fit: BoxFit.fitHeight,
                ),
              ),
            );
          },
          errorWidget: (context, url, error) {
            return AppPlaceholder(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                ),
                child: const Icon(Icons.error),
              ),
            );
          },
        ),
      );

      if (product.address.isNotEmpty) {
        address = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            Row(
              children: <Widget>[
                Expanded(
                  child: InkWell(
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Theme.of(context).dividerColor,
                          ),
                          child: const Icon(
                            Icons.location_on_outlined,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                Translate.of(context).translate('address'),
                                style: Theme.of(context).textTheme.caption,
                              ),
                              Text(
                                product.address,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyText1!
                                    .copyWith(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      }

      if (product.phone.isNotEmpty) {
        phone = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            InkWell(
              onTap: () {
                _phoneAction(product.phone);
              },
              child: Row(
                children: <Widget>[
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Theme.of(context).dividerColor,
                    ),
                    child: const Icon(
                      Icons.phone_outlined,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          Translate.of(context).translate('phone'),
                          style: Theme.of(context).textTheme.caption,
                        ),
                        Text(
                          product.phone,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context)
                              .textTheme
                              .bodyText1!
                              .copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ],
        );
      }

      if (product.email.isNotEmpty) {
        email = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            InkWell(
              onTap: () {
                _mailAction(product.email);
              },
              child: Row(
                children: <Widget>[
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Theme.of(context).dividerColor,
                    ),
                    child: const Icon(
                      Icons.email_outlined,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          Translate.of(context).translate('email'),
                          style: Theme.of(context).textTheme.caption,
                        ),
                        Text(
                          product.email,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context)
                              .textTheme
                              .bodyText1!
                              .copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ],
        );
      }

      if (product.website.isNotEmpty) {
        website = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            InkWell(
              onTap: () {
                _makeAction(product.website);
              },
              child: Row(
                children: <Widget>[
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Theme.of(context).dividerColor,
                    ),
                    child: const Icon(
                      Icons.language_outlined,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          Translate.of(context).translate('website'),
                          style: Theme.of(context).textTheme.caption,
                        ),
                        Text(
                          product.website,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context)
                              .textTheme
                              .bodyText1!
                              .copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ],
        );
      }

      if (product.description.isNotEmpty) {
        String modifiedDescription = product.description;

        modifiedDescription = modifiedDescription.replaceAll(
            RegExp(r'color: [^;]+;'), "color: white");

        description = HtmlWidget(
          modifiedDescription,
          textStyle:
              const TextStyle(fontSize: 16.0, color: Colors.white, height: 1.6),
          customStylesBuilder: (element) {
            if (element.localName == 'img') {
              return {'max-width': '100%'};
            } else if (element.localName == '') {
              return {'color': '#ffffff'};
            }
            var style = element.attributes['style'];
            if (style != null) {
              style =
                  style.replaceAll(RegExp(r'color:[^;];?'), 'color: #ffffff;');
            } else {
              style = 'color: #ffffff;';
            }

            return {'style': style};
          },
          onTapUrl: (url) {
            if (Uri.parse(url).hasAbsolutePath) {
              _makeAction(url);
            }
            return false;
          },
        );
      }

      if (product.startDate.isNotEmpty) {
        startDate = Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              Translate.of(context).translate(
                'start_date',
              ),
              style: Theme.of(context).textTheme.caption,
            ),
            const SizedBox(width: 8),
            Text(
              product.startDate,
              style: Theme.of(context)
                  .textTheme
                  .subtitle2!
                  .copyWith(fontWeight: FontWeight.bold),
            )
          ],
        );
      }

      if (product.endDate.isNotEmpty) {
        endDate = Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              Translate.of(context).translate(
                'end_date',
              ),
              style: Theme.of(context).textTheme.caption,
            ),
            const SizedBox(width: 8),
            Text(
              product.endDate,
              style: Theme.of(context)
                  .textTheme
                  .subtitle2!
                  .copyWith(fontWeight: FontWeight.bold),
            )
          ],
        );
      }

      ///Create Date
      if (product.createDate.isNotEmpty) {
        createdDate = Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              product.createDate,
              style: Theme.of(context)
                  .textTheme
                  .subtitle2!
                  .copyWith(fontWeight: FontWeight.bold),
            )
          ],
        );
      }

      info = Padding(
        padding: const EdgeInsets.only(left: 16, right: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Expanded(
                  child: Text(
                    product.title,
                    style: Theme.of(context).textTheme.titleMedium!.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                // price,
                // booking,
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      product.category != null
                          ? product.category as String
                          : '',
                      style: Theme.of(context)
                          .textTheme
                          .caption
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                  ],
                ),
                Visibility(
                  visible: isLoggedIn,
                  child: IconButton(
                    icon: Icon(
                      product.favorite ? Icons.favorite : Icons.favorite_border,
                      color: Theme.of(context).primaryColor,
                    ),
                    onPressed: () async {
                      setState(() {
                        _productDetailCubit.setFavoriteIconValue();
                        product.favorite =
                            _productDetailCubit.getFavoriteIconValue();
                      });
                      if (_productDetailCubit.getFavoriteIconValue()) {
                        await _productDetailCubit.onAddFavorite(widget.item);
                      } else {
                        await _productDetailCubit.onDeleteFavorite(widget.item);
                      }
                    },
                  ),
                ),
              ],
            ),
            createdDate,
            Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                startDate,
                endDate
                // priceRange,
              ],
            ),
            description,
            address,
            phone,
            fax,
            email,
            website,
            openHours,
            attachments,
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(8),
              margin: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Theme.of(context).cardColor,
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).dividerColor.withOpacity(
                          .05,
                        ),
                    spreadRadius: 4,
                    blurRadius: 4,
                    offset: const Offset(
                      0,
                      2,
                    ), // changes position of shadow
                  ),
                ],
              ),
              child: AppUserInfo(
                user: userDetail,
                onPressed: () async {
                  final loggedInUserId = await context
                      .read<ProductDetailCubit>()
                      .getLoggedInUserId();
                  if (!mounted) return;
                  final productUserId = await context
                      .read<ProductDetailCubit>()
                      .getUserDetails(widget.item.userId, widget.item.cityId);

                  if (productUserId?.id == loggedInUserId) {
                    if (!mounted) return;
                    Navigator.pushNamed(context, Routes.profile,
                        arguments: {'user': userDetail, 'editable': true});
                  } else {
                    if (!mounted) return;
                    Navigator.pushNamed(context, Routes.profile,
                        arguments: {'user': userDetail, 'editable': false});
                  }
                },
                type: UserViewType.information,
                showDirectionIcon: true,
              ),
            ),
            // socials,
            const SizedBox(height: 16),

            const SizedBox(height: 16),

            // feature,
            // tags,
          ],
        ),
      );
    }

    return CustomScrollView(
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      controller: _scrollController,
      slivers: <Widget>[
        SliverAppBar(
          expandedHeight: MediaQuery.of(context).size.height * 0.25,
          pinned: true,
          actions: action,
          iconTheme: Theme.of(context).iconTheme.copyWith(color: _iconColor),
          flexibleSpace: FlexibleSpaceBar(
            collapseMode: CollapseMode.pin,
            background: banner,
          ),
        ),
        SliverToBoxAdapter(
          child: SafeArea(
            top: false,
            child: Column(
              children: <Widget>[
                const SizedBox(height: 16),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Row(),
                ),
                info,
                // latest,
                const SizedBox(height: 16),
                // related,
              ],
            ),
          ),
        )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocProvider(
        create: (context) => _productDetailCubit,
        child: BlocBuilder<ProductDetailCubit, ProductDetailState>(
          builder: (context, state) {
            ProductModel? product;
            List<FavoriteModel>? favoriteList;
            bool isLoggedIn = false;
            UserModel? userDetail;
            if (state is ProductDetailLoaded) {
              product = state.product;
              favoriteList = state.favoritesList;
              isLoggedIn = state.isLoggedIn;
              userDetail = state.userDetail;
            }
            return _buildContent(product, favoriteList, userDetail, isLoggedIn);
          },
        ),
      ),
    );
  }
}
