import 'package:flutter/material.dart';

class SearchPage extends StatelessWidget {
  const SearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Text("search page"),
      bottomNavigationBar: BottomAppBar(child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          IconButton(
            onPressed: () {Navigator.of(context).pop();},
            icon: Icon(Icons.home_filled),
          ),
          IconButton(
            onPressed: () {},
            icon: Icon(Icons.filter_alt_rounded)
          ),
        ],
      ),),
    );
  }
}