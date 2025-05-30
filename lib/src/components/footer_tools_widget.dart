import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:touch_craft_editor/src/constants/primary_color.dart';
import 'package:touch_craft_editor/src/extensions/context_extension.dart';

/// A widget for displaying footer tools.
///
/// This widget is a part of the UI where the user can interact with footer tools.
/// It is a stateless widget that takes several parameters to control its behavior and appearance.
/// It uses an ElevatedButton to display a done button, and the user can interact with it by tapping on it.
class FooterToolsWidget extends StatelessWidget {
  /// Creates an instance of the widget.
  ///
  /// The onDone parameter is required and must not be null.
  /// The doneButtonChild and isLoading parameters are optional.
  const FooterToolsWidget({
    super.key,
    required this.onDone,
    this.doneButtonChild,
    this.isLoading = false,
  });

  /// A callback function that is called when the done button is pressed.
  final AsyncCallback onDone;

  /// The child widget of the done button.
  final Widget? doneButtonChild;

  /// Indicates whether the widget is in loading state.
  final bool isLoading;

  /// Describes the part of the user interface represented by this widget.
  ///
  /// The framework calls this method when this widget is inserted into the tree in a given BuildContext and when the dependencies of this widget change.
  @override
  Widget build(BuildContext context) {
    return Container(
      height: context.bottomPadding + kToolbarHeight,
      alignment: Alignment.topCenter,
      child: Padding(
        padding: const EdgeInsets.only(right: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            ElevatedButton(
              onPressed: onDone,
              style: ButtonStyle(
                shape: WidgetStateProperty.all(
                  const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(22)),
                  ),
                ),
                shadowColor: WidgetStateProperty.all(Colors.white),
                backgroundColor: WidgetStateProperty.all(primaryThemeColor),
              ),
              child: isLoading
                  ? const CupertinoActivityIndicator()
                  : doneButtonChild ??
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            children: [
                              SizedBox(width: 4),
                              Text(
                                'Done',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                              ),
                              SizedBox(width: 4),
                              Icon(
                                CupertinoIcons.forward,
                                color: Colors.white,
                                size: 18,
                              ),
                            ],
                          ),
                        ],
                      ),
            ),
          ],
        ),
      ),
    );
  }
}
