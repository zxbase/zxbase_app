import 'package:flutter/material.dart';

class SpinWidget extends StatelessWidget {
  const SpinWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) {
        return const Scaffold(
          body: SafeArea(
            child: Stack(
              children: [
                Form(
                  child: Center(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          SizedBox(
                            height: 150,
                            width: 150,
                            child: Center(child: CircularProgressIndicator()),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
