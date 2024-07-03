import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:heidi/src/data/model/model_citizen_service.dart';
import 'package:heidi/src/presentation/cubit/app_bloc.dart';
import 'package:heidi/src/utils/configs/preferences.dart';
import 'package:heidi/src/utils/configs/routes.dart';
import 'package:heidi/src/utils/translate.dart';
import 'package:url_launcher/url_launcher.dart';

import 'cubit/cubit.dart';

class DiscoveryScreenDetail extends StatefulWidget {
  final Map<String, dynamic> arguments;

  const DiscoveryScreenDetail({super.key, required this.arguments});

  @override
  State<DiscoveryScreenDetail> createState() => _DiscoveryScreenState();
}

class _DiscoveryScreenState extends State<DiscoveryScreenDetail> {
  int? selectedLocationId;

  @override
  void initState() {
    super.initState();
    int id = widget.arguments['id'];
    if (id == 14) {
      context.read<DiscoveryCubit>().initializeServices14();
    } else if (id == 15) {
      context.read<DiscoveryCubit>().initializeServices15();
    } else if (id == 16) {
      context.read<DiscoveryCubit>().initializeServices16();
    }
    loadLocationList();
  }

  Future<void> loadLocationList() async {
    await context.read<DiscoveryCubit>().onLoad(widget.arguments['id']);
  }

  Future<void> loadSelectedLocation() async {
    final cityId = await context.read<DiscoveryCubit>().getCitySelected();
    setState(() {
      selectedLocationId = cityId;
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvoked: (value) {
        context.read<DiscoveryCubit>().onLoad(1);
      },
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: Text(Translate.of(context).translate('cust_services')),
        ),
        body: BlocConsumer<DiscoveryCubit, DiscoveryState>(
          listener: (context, state) {
            state.maybeWhen(
              error: (msg) => ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(content: Text(msg))),
              orElse: () {},
            );
          },
          builder: (context, state) => state.when(
            loading: () {
              return const DiscoveryLoading();
            },
            loaded: (list) => DiscoveryLoaded(
              services: list,
            ),
            updated: (list) {
              return Container();
            },
            error: (e) => ErrorWidget('Failed to load listings.'),
            initial: () {
              return Container();
            },
          ),
        ),
      ),
    );
  }
}

class DiscoveryLoading extends StatelessWidget {
  const DiscoveryLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator.adaptive(),
    );
  }
}

class DiscoveryLoaded extends StatefulWidget {
  final List<CitizenServiceModel> services;

  const DiscoveryLoaded({
    super.key,
    required this.services,
  });

  @override
  State<DiscoveryLoaded> createState() => _DiscoveryLoadedState();
}

class _DiscoveryLoadedState extends State<DiscoveryLoaded> {
  bool isLoading = false;
  final _scrollController = ScrollController();
  List<CitizenServiceModel> services = [];

  @override
  void initState() {
    super.initState();
    services = widget.services;
  }

  void scrollUp() {
    _scrollController.animateTo(0,
        duration: const Duration(milliseconds: 500), //duration of scroll
        curve: Curves.fastOutSlowIn //scroll type
        );
  }

  @override
  Widget build(BuildContext context) {
    if (AppBloc.discoveryCubit.getDoesScroll()) {
      AppBloc.discoveryCubit.setDoesScroll(false);
      scrollUp();
    }
    return Scaffold(
      body: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, // Adjust the number of columns as desired
            crossAxisSpacing: 10.0,
            mainAxisSpacing: 10.0,
            mainAxisExtent: 300.0),
        itemCount: services.length,
        controller: _scrollController,
        itemBuilder: (BuildContext context, int index) {
          return InkWell(
            onTap: () {
              navigateToLink(services[index]);
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15.0),
              child: Image.asset(
                services[index].imageUrl,
                fit: BoxFit.cover,
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> navigateToLink(CitizenServiceModel service) async {
    if (service.arguments == 141) {
      await launchUrl(
          Uri.parse(
              'https://online-rathaus.einbeck.de/buergerservice/online/privat/uebersicht-0-30110.html'),
          mode: LaunchMode.inAppWebView);
    } else if (service.arguments == 142) {
      await launchUrl(
          Uri.parse(
              'https://stadt-einbeck.saas.smartcjm.com/m/Buergerbuero/extern/calendar/?uid=3e5df0d1-ea60-4078-bbc4-783f5909672c&wsid=881a0c58-9c89-4ae3-b15d-38cbff863eb0&lang=de'),
          mode: LaunchMode.inAppWebView);
    } else if (service.arguments == 143) {
      await launchUrl(Uri.parse('https://ris.kdgoe.de/EIN_public/'),
          mode: LaunchMode.inAppWebView);
    } else if (service.arguments == 151) {
      await launchUrl(Uri.parse('https://beteiligung.einbeck.de/'),
          mode: LaunchMode.inAppWebView);
    } else if (service.arguments == 152) {
      await launchUrl(
          Uri.parse(
              'https://www.einbeck.de/portal/seiten/mitwirk-o-mat-900000343-30110.html'),
          mode: LaunchMode.inAppWebView);
    } else if (service.arguments == 153) {
      await launchUrl(
          Uri.parse('https://www.einbeck.de/rathaus-politik/idee-beschwerde/'),
          mode: LaunchMode.inAppWebView);
    } else if (service.arguments == 161) {
      await launchUrl(
          Uri.parse(
              'https://www.landkreis-northeim.de/abfall-und-deponien/abfall-abc-abfall-kalender-abfall-app/wohin-mit-dem-abfall-/'),
          mode: LaunchMode.inAppWebView);
    } else if (service.arguments == 162) {
      await launchUrl(
          Uri.parse(
              'https://www.landkreis-northeim.de/abfall-und-deponien/abfall-abc-abfall-kalender-abfall-app/abfallkalender/'),
          mode: LaunchMode.inAppWebView);
    } else if (service.arguments == 163) {
      await launchUrl(
          Uri.parse(
              'https://www.landkreis-northeim.de/abfall-und-deponien/abfall-abc-abfall-kalender-abfall-app/abfall-app/'),
          mode: LaunchMode.inAppWebView);
    } else if (service.imageLink == "15") {
      await launchUrl(
          Uri.parse(await AppBloc.discoveryCubit.getCityLink() ?? ""),
          mode: LaunchMode.inAppWebView);
    } else if (service.imageLink == "10") {
      final cityId = await context.read<DiscoveryCubit>().getCitySelected();
      if (cityId != 0) {
        if (!mounted) return;
        Navigator.pushNamed(context, Routes.listGroups,
            arguments: {'id': service.arguments, 'title': 'forums'});
      } else {
        if (!mounted) return;
        _showCitySelectionPopup(context);
      }
    } else {
      AppBloc.discoveryCubit
          .setServiceValue(Preferences.type, service.type, null);
      if (service.categoryId != null) {
        AppBloc.discoveryCubit
            .setServiceValue(Preferences.categoryId, null, service.categoryId);
      }
      Navigator.pushNamed(context, Routes.listProduct, arguments: {
        'id': service.arguments,
        'title': '',
        'type': 'categoryService'
      });
    }
  }

  void _showCitySelectionPopup(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Stadt Auswählen'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(Translate.of(context).translate('please_select_city')),
              const SizedBox(height: 16),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}
