import 'package:flutter/material.dart';

class IPhone17ProMaxFrame extends StatelessWidget {
  final Widget child;

  const IPhone17ProMaxFrame({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // iPhone 17 Pro Max dimensions (approximation)
        const double deviceWidth = 430;
        const double deviceHeight = 932;
        const double aspectRatio = deviceWidth / deviceHeight;

        // Calculate scaled dimensions to fit screen while maintaining aspect ratio
        double frameWidth;
        double frameHeight;

        if (constraints.maxWidth / constraints.maxHeight > aspectRatio) {
          // Screen is wider than device aspect ratio
          frameHeight = constraints.maxHeight * 0.95;
          frameWidth = frameHeight * aspectRatio;
        } else {
          // Screen is taller than device aspect ratio
          frameWidth = constraints.maxWidth * 0.95;
          frameHeight = frameWidth / aspectRatio;
        }

        return Center(
          child: Container(
            width: frameWidth,
            height: frameHeight,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(55 * (frameWidth / deviceWidth)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 40,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.topCenter,
              children: [
                // Device frame border
                Container(
                  margin: EdgeInsets.all(8 * (frameWidth / deviceWidth)),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.grey.shade800,
                      width: 2 * (frameWidth / deviceWidth),
                    ),
                    borderRadius: BorderRadius.circular(48 * (frameWidth / deviceWidth)),
                  ),
                ),
                // Dynamic Island
                Positioned(
                  top: 12 * (frameWidth / deviceWidth),
                  left: frameWidth * 0.3,
                  child: Container(
                    width: frameWidth * 0.4,
                    height: 37 * (frameWidth / deviceWidth),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(25 * (frameWidth / deviceWidth)),
                    ),
                  ),
                ),
                // App content with clip
                Container(
                  margin: EdgeInsets.all(12 * (frameWidth / deviceWidth)),
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(45 * (frameWidth / deviceWidth)),
                  ),
                  child: SizedBox(
                    width: frameWidth - (24 * (frameWidth / deviceWidth)),
                    height: frameHeight - (24 * (frameWidth / deviceWidth)),
                    child: child,
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
