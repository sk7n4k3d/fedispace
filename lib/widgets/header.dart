// import 'dart:ui';
import 'package:fedispace/core/api.dart';
import 'package:fedispace/models//account.dart';
import 'package:flutter/material.dart';

class HeaderWidget extends StatelessWidget implements PreferredSizeWidget {
  final ApiService apiService;

  const HeaderWidget({required this.apiService, Key? key}) : super(key: key);

  Future<Account> _fetchAccount() async {
    return await apiService.getCurrentAccount();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Account>(
        future: _fetchAccount(),
        builder: (BuildContext context, AsyncSnapshot<Account> snapshot) {
          if (snapshot.hasData) {
            return AppBar(
                elevation: 20,
                centerTitle: false,
                excludeHeaderSemantics: true,
                automaticallyImplyLeading: false,
                leading: Container(),
                flexibleSpace: Container(
                  decoration: const BoxDecoration(
                      borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(20),
                          bottomRight: Radius.circular(20)),
                      gradient: LinearGradient(
                          colors: [Colors.blueGrey, Colors.grey],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter)),
                ),
                title: Container(
                  margin: const EdgeInsetsDirectional.all(10),
                  child: const Text('FEDI SPACE',
                      style: TextStyle(
                        fontFamily: 'glitch',
                        fontSize: 30,
                      )),
                ));
          } else if (snapshot.hasError) {
            return const Text('Has error in function');
          }
          return const CircularProgressIndicator();

          // Reprendre ici loading !
        });
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
