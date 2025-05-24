import 'dart:io';
import 'dart:ui';
import 'dart:ui' as ui;
import 'package:crop_image/crop_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:touch_craft_editor/src/components/connectivity_wrapper.dart';
import 'package:touch_craft_editor/src/components/cutout_image_overlay_widget.dart';
import 'package:touch_craft_editor/src/components/image_crop_view.dart';
import 'package:touch_craft_editor/src/components/no_internert_widget.dart';
import 'package:touch_craft_editor/src/components/app_alert_dialogue.dart';
import 'package:touch_craft_editor/src/constants/font_styles.dart';
import 'package:touch_craft_editor/src/constants/primary_color.dart';
import 'package:touch_craft_editor/src/gif/enough_giphy_flutter.dart';
import 'package:touch_craft_editor/src/services/connectivity_service.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:saver_gallery/saver_gallery.dart';
import 'package:screen_recorder/screen_recorder.dart';

import 'src/components/background_gradient_selector_widget.dart';
import 'src/components/font_family_select_widget.dart';
import 'src/components/footer_tools_widget.dart';
import 'src/components/overlay_item_widget.dart';
import 'src/components/remove_widget.dart';
import 'src/components/size_slider_widget.dart';
import 'src/components/text_color_select_widget.dart';
import 'src/components/text_field_widget.dart';
import 'src/components/top_tools_widget.dart';
import 'src/constants/font_colors.dart';
import 'src/constants/gradients.dart';
import 'src/constants/enums.dart';
import 'src/extensions/context_extension.dart';
import 'src/models/canvas_element.dart';

export 'src/models/canvas_element.dart';
export 'src/constants/enums.dart';

/// A customizable Flutter-based design editor widget.
///
/// Provides options to enable/disable features like text, sticker, image, gif, and background gradient editing.
/// Includes customization for fonts, colors, and animation behavior.
class TouchCraftEditor extends StatefulWidget {
  const TouchCraftEditor({
    super.key,
    required this.onDesignReady,
    this.animationsDuration = const Duration(milliseconds: 300),
    this.backgroundGradientColorList = gradientColors,
    this.fontFamilyList = googleFontFamilyList,
    this.fontColorList = defaultColors,
    this.enableStickerEditor = true,
    this.enableTextEditor = true,
    this.enableBackgroundGradientEditor = true,
    this.enableGifEditor = true,
    this.enableImageEditor = true,
    this.enableDownloadDesignButton = true,
    this.imageFormatType = ImageFormatType.png,
    this.internetConnectionWidget = const NoInternetWidget(
      title: 'Please Check Internet Connection',
    ),
    this.editDesignJson,
    this.doneButtonWidget,
    this.primaryColor,
    this.downloadIconWidget,
    this.backgroundColorIconWidget,
    this.imageIconWidget,
    this.gifIconWidget,
    this.stickerIconWidget,
    this.textIconWidget,
    this.snackbarContent,
    this.giphyApiKey,
  });

  /// The duration for all animated transitions within the widget.
  final Duration animationsDuration;

  /// The widget to display as the "Done" button.
  final Widget? doneButtonWidget;

  /// The widget to display as the download button.
  final Widget? downloadIconWidget;

  /// The widget to display as the add backgrund color button.
  final Widget? backgroundColorIconWidget;

  /// The widget to display as the add text button.
  final Widget? imageIconWidget;

  /// The widget to display as the add image button.
  final Widget? textIconWidget;

  /// The widget to display as the add GIF button.
  final Widget? gifIconWidget;

  /// The widget to display as the add sticker button.
  final Widget? stickerIconWidget;

  final Widget? snackbarContent;

  // This parameters is used to enable text editor
  final bool enableTextEditor;

  // This parameters is used to enable background-gradient editor.
  final bool enableBackgroundGradientEditor;

  // This parameters is used to enable image editor.
  final bool enableImageEditor;

  // This parameters is used to add GIF in design.
  final bool enableGifEditor;

  // This parameters is used to enable sticker creation.
  final bool enableStickerEditor;

  // This parameters is used to enable button to download and save design created.
  final bool enableDownloadDesignButton;

  // Provide custom gradient color list
  // backgroundGradientColorList : [  [Color(0xFF1488CC), Color(0xFF2B32B2)],[Color(0xFFec008c), Color(0xFFfc6767)],];
  final List<List<Color>> backgroundGradientColorList;

  // Provide custom GoogleFonts family list for font-style.
  // fontFamilyList : [ 'Lato', 'Montserrat', 'Lobster'];
  final List<String> fontFamilyList;

  // Provide custom color list for font colors
  // fontColorList : [ Colors.white, Colors.black, Colors.red];
  final List<Color> fontColorList;

  // An enum to handle final image generation formate by package user.
  final ImageFormatType imageFormatType;

  // Called when design export is complete
  // Returns image file or GIF as per design
  // Also Returns list of CanvasElement included in design
  final void Function(File? designFile, Map<String, dynamic> canvasDesignJson)
      onDesignReady;

  // A widget to show when there is no internet connection.
  final Widget internetConnectionWidget;

  /// Map having info to re-edit the previous made design.
  /// Note : return [canvasDesignJson] which was previously returned on Done tap.
  final Map<String, dynamic>? editDesignJson;

  /// Color apply to match theme of your application.
  final Color? primaryColor;

  /// Pass Giphy API key for GIF editing feature.
  final String? giphyApiKey;

  @override
  State<TouchCraftEditor> createState() => _TouchCraftEditorState();
}

class _TouchCraftEditorState extends State<TouchCraftEditor> {
  // A global key used to get the context of the widget tree.
  GlobalKey previewContainer = GlobalKey();

  // The currently active editable item.
  CanvasElement? _activeItem;

  // The initial position of the active item.
  Offset _initPos = Offset.zero;

  // The current position of the active item.
  Offset _currentPos = Offset.zero;

  // The current scale of the active item.
  double _currentScale = 1;

  // The current rotation of the active item.
  double _currentRotation = 1;

  // Indicates whether the widget is in action.
  bool _inAction = false;

  // Used to identify which item to add based on tap of TopToolsWidgets.
  ItemType? _addNewItemOfType;

  // Used to identify which item is getting edited.
  ItemType? _currentlyEditingItemType;

  // The current text in the text input field.
  String _currentText = '';

  // The currently selected text color.
  Color _selectedTextColor = const Color(0xffffffff);

  // The index of the currently selected text background gradient.
  int _selectedTextBackgroundGradient = 0;

  // The index of the currently selected background gradient.
  int _selectedBackgroundGradient = 1;

  // The currently selected font size.
  double _selectedFontSize = 26;

  // The index of the currently selected font family.
  int _selectedFontFamily = 0;

  // Indicates whether the widget is in delete position.
  bool _isDeletePosition = false;

  // Indicates whether the color picker is selected.
  bool _isColorPickerSelected = false;

  // Indicates whether the background color picker is selected.
  bool _isBackgroundColorPickerSelected = false;

  // Indicates whether the widget is in loading state.
  bool _isLoading = false;

  // Used while creating stricker
  String? imagePathForSticker;

  // The controller for the font family PageView.
  late PageController _familyPageController;

  // The controller for the text colors PageView.
  late PageController _textColorsPageController;

  // The controller for the gradients PageView.
  late PageController _gradientsPageController;

  // The controller for the text editing field.
  final _editingController = TextEditingController();

  // The stack data for the editable items.
  late final List<CanvasElement> _stackData;

  // The controller for the crop functionality.
  final _cropController = CropController(
    aspectRatio: 1,
    defaultCrop: Rect.fromLTRB(0.2, 0.2, 0.9, 0.9),
  );

  // The controller to record and get widget as GIF.
  final _screenRecordingController = ScreenRecorderController(
    pixelRatio: 1,
    skipFramesBetweenCaptures: 2,
  );

  // An instance of ConnectivityService class.
  late final ConnectivityService _connectivityService;

  /// Called when this object is inserted into the tree.
  ///
  /// The framework will call this method exactly once for each [State] object it creates.
  /// This method is where you should put any expensive computations, network calls, initializations, or subscriptions.
  /// In this case, it calls the [_init] method to initialize the state of the widget.
  @override
  void initState() {
    super.initState();
    _init();
  }

  /// Initializes the state of the widget.
  ///
  /// This method is called in [initState] to set up the initial state of the widget.
  /// It also initializes the [_familyPageController], [_textColorsPageController], and [_gradientsPageController] with their respective viewport fractions.
  void _init() {
    _familyPageController = PageController(viewportFraction: .125);
    _textColorsPageController = PageController(viewportFraction: .1);
    _gradientsPageController = PageController(viewportFraction: .175);
    if (widget.primaryColor != null) {
      primaryThemeColor = widget.primaryColor!;
    }
    _connectivityService = ConnectivityService(
      noInternetWidget: widget.internetConnectionWidget,
    );
    if (widget.editDesignJson != null) {
      _createImageToEdit(widget.editDesignJson!);
    } else {
      setState(() {
        _stackData = [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTextHeightBehavior(
      textHeightBehavior: const TextHeightBehavior(
        leadingDistribution: TextLeadingDistribution.even,
      ),
      child: Overlay(
        key: _connectivityService.overlayKey,
        initialEntries: [
          OverlayEntry(
            builder: (context) {
              return ConnectivityWrapper(
                connectivityService: _connectivityService,
                child: Scaffold(
                  resizeToAvoidBottomInset: false,
                  body: Stack(
                    clipBehavior: Clip.antiAlias,
                    children: [
                      GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onTap: _showTextView,
                        child: Container(
                          height: context.height,
                          width: context.width,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: widget.backgroundGradientColorList[
                                  _selectedBackgroundGradient],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: context.topPadding,
                        left: 0,
                        right: 0,
                        child: ClipRect(
                          child: AspectRatio(
                            aspectRatio: context.width / context.height,
                            child: GestureDetector(
                              onScaleStart: _onScaleStart,
                              onScaleUpdate: _onScaleUpdate,
                              onTap: () {
                                if (_activeItem == null &&
                                    _addNewItemOfType == null &&
                                    _currentlyEditingItemType == null) {
                                  _showTextView();
                                } else {
                                  _onScreenTap();
                                }
                              },
                              child: Stack(
                                children: [
                                  RepaintBoundary(
                                    key: previewContainer,
                                    child: ScreenRecorder(
                                      width: context.width,
                                      height: context.height,
                                      controller: _screenRecordingController,
                                      child: Container(
                                        height: double.infinity,
                                        width: double.infinity,
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: widget
                                                    .backgroundGradientColorList[
                                                _selectedBackgroundGradient],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                        ),
                                        child: Stack(
                                          children: [
                                            ..._stackData.map(
                                              (
                                                canvasElement,
                                              ) =>
                                                  OverlayItemWidget(
                                                canvasElement: canvasElement,
                                                backgroundColorList: widget
                                                    .backgroundGradientColorList,
                                                fontFamilyList:
                                                    widget.fontFamilyList,
                                                onItemTap: () {
                                                  _onOverlayItemTap(
                                                    canvasElement,
                                                  );
                                                },
                                                onPointerDown: (details) {
                                                  _onOverlayItemPointerDown(
                                                    canvasElement,
                                                    details,
                                                  );
                                                },
                                                onPointerUp: (details) {
                                                  _onOverlayItemPointerUp(
                                                    canvasElement,
                                                    details,
                                                  );
                                                },
                                                onPointerMove: (details) {
                                                  _onOverlayItemPointerMove(
                                                    canvasElement,
                                                    details,
                                                  );
                                                },
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  AnimatedSwitcher(
                                    duration: widget.animationsDuration,
                                    child: _addNewItemOfType != ItemType.text
                                        ? const SizedBox()
                                        : Container(
                                            height: context.height,
                                            width: context.width,
                                            color: Colors.black.withValues(
                                              alpha: 0.4,
                                            ),
                                            child: Stack(
                                              children: [
                                                TextFieldWidget(
                                                  controller:
                                                      _editingController,
                                                  onChanged: _onTextChange,
                                                  onSubmit: _onTextSubmit,
                                                  fontSize: _selectedFontSize,
                                                  fontFamilyIndex:
                                                      _selectedFontFamily,
                                                  textColor: _selectedTextColor,
                                                  fontFamilyList:
                                                      widget.fontFamilyList,
                                                  backgroundColorIndex:
                                                      _selectedTextBackgroundGradient,
                                                  backgroundColorList: widget
                                                      .backgroundGradientColorList,
                                                ),
                                                SizeSliderWidget(
                                                  animationsDuration:
                                                      widget.animationsDuration,
                                                  selectedValue:
                                                      _selectedFontSize,
                                                  onChanged: (input) {
                                                    setState(() {
                                                      _selectedFontSize = input;
                                                    });
                                                  },
                                                ),
                                              ],
                                            ),
                                          ),
                                  ),
                                  AnimatedSwitcher(
                                    duration: widget.animationsDuration,
                                    child: _currentlyEditingItemType !=
                                            ItemType.image
                                        ? const SizedBox()
                                        : ImageCropView(
                                            imageValue: _activeItem!.value,
                                            cropController: _cropController,
                                          ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (_currentlyEditingItemType == ItemType.text)
                        if (!_isColorPickerSelected)
                          FontFamilySelectWidget(
                            animationsDuration: widget.animationsDuration,
                            pageController: _familyPageController,
                            selectedFamilyIndex: _selectedFontFamily,
                            fontFamilyList: widget.fontFamilyList,
                            onPageChanged: _onFamilyChange,
                            onTap: (index) {
                              _onStyleChange(index);
                            },
                          )
                        else
                          TextColorSelectWidget(
                            animationsDuration: widget.animationsDuration,
                            pageController: _textColorsPageController,
                            selectedTextColor: _selectedTextColor,
                            onPageChanged: _onTextColorChange,
                            fontColorList: widget.fontColorList,
                            onTap: (index) {
                              _onColorChange(index);
                            },
                          ),
                      BackgroundGradientSelectorWidget(
                        isTextInput: _addNewItemOfType == ItemType.text,
                        isBackgroundColorPickerSelected:
                            _isBackgroundColorPickerSelected,
                        inAction: _inAction,
                        animationsDuration: widget.animationsDuration,
                        gradientsPageController: _gradientsPageController,
                        onPageChanged: _onChangeBackgroundGradient,
                        onItemTap: _onBackgroundGradientTap,
                        selectedGradientIndex: _selectedBackgroundGradient,
                        backgroundColorList: widget.backgroundGradientColorList,
                      ),
                      if (_currentlyEditingItemType == ItemType.sticker)
                        CutoutImageOverlayWidget(
                          imagePath: imagePathForSticker!,
                          onScreenTap: (stickerPath) {
                            if (stickerPath != null) {
                              setState(() {
                                _stackData.add(
                                  CanvasElement()
                                    ..type = ItemType.sticker
                                    ..value = stickerPath,
                                );
                              });
                            }
                            _onScreenTap();
                          },
                        ),
                      TopToolsWidget(
                        currentlyEditingItemType: _currentlyEditingItemType,
                        selectedBackgroundGradientIndex:
                            _selectedBackgroundGradient,
                        animationsDuration: widget.animationsDuration,
                        backgroundColorIconWidget:
                            widget.backgroundColorIconWidget,
                        downloadIconWidget: widget.downloadIconWidget,
                        gifIconWidget: widget.gifIconWidget,
                        imageIconWidget: widget.imageIconWidget,
                        stickerIconWidget: widget.stickerIconWidget,
                        textIconWidget: widget.textIconWidget,
                        onPickerTap: _onToggleBackgroundGradientPicker,
                        onScreenTap: _showTextView,
                        selectedTextBackgroundGradientIndex:
                            _selectedTextBackgroundGradient,
                        onToggleTextColorPicker: _onToggleTextColorSelector,
                        onChangeTextBackground: _onChangeTextBackground,
                        activeItem: _activeItem,
                        onImagePickerTap: _onImagepickerTap,
                        onCropTap: _onCropImagetap,
                        onAddGiphyTap: _onAddGifTap,
                        onCreateStickerTap: _onCreateStickerTap,
                        onCloseStickerOverlay: _onScreenTap,
                        onDownloadTap: () async {
                          await _onDone(
                            shouldSaveToGallery: true,
                            buildContext: context,
                          );
                        },
                        backgroundColorList: widget.backgroundGradientColorList,
                        shouldShowBackgroundGradientButton:
                            widget.enableBackgroundGradientEditor,
                        shouldShowGifButton: widget.enableGifEditor,
                        shouldShowImageButton: widget.enableImageEditor,
                        shouldShowStickerButton: widget.enableStickerEditor,
                        shouldShowTextButton: widget.enableTextEditor,
                        shouldShowDownloadButton: _isLoading
                            ? false
                            : widget.enableDownloadDesignButton,
                      ),
                      RemoveWidget(
                        animationsDuration: widget.animationsDuration,
                        activeItem: _activeItem,
                        isDeletePosition: _isDeletePosition,
                        shouldShowDeleteButton: _inAction,
                      ),
                      if (_currentlyEditingItemType == null && !_isLoading)
                        Align(
                          alignment: Alignment.bottomCenter,
                          child: FooterToolsWidget(
                            onDone: () async {
                              await _onDone(
                                shouldSaveToGallery: false,
                                buildContext: context,
                              );
                            },
                            doneButtonChild: widget.doneButtonWidget,
                            isLoading: _isLoading,
                          ),
                        ),
                      if (_isLoading)
                        Align(
                          alignment: Alignment.center,
                          child: CircularProgressIndicator(color: Colors.white),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showSnackbar({
    required BuildContext buildContext,
    required String content,
  }) {
    ScaffoldMessenger.of(buildContext).showSnackBar(
      SnackBar(
        content: widget.snackbarContent ??
            Center(
              child: Text(
                content,
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
        backgroundColor: primaryThemeColor.withAlpha(128),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _createImageToEdit(Map<String, dynamic> editDesignJson) {
    final backgroundGradientColorList = editDesignJson['backgroundColor'];
    final List<CanvasElement> canvasElementList = [];
    for (final json
        in (editDesignJson['designItems'] as List<Map<String, dynamic>>)) {
      canvasElementList.add(
        CanvasElement.fromJson(
          json: json,
          fontFamilyList: widget.fontFamilyList,
          textDecorationColorList: widget.backgroundGradientColorList,
        ),
      );
    }
    _selectedBackgroundGradient = widget.backgroundGradientColorList.indexWhere(
      (element) => element == backgroundGradientColorList,
    );
    _stackData = canvasElementList;
    setState(() {});
  }

  /// Handles the image picker tap action.
  ///
  /// Handles image picker tap, requests permissions, and adds selected image to stack data.
  /// Opens gallery for image selection; if an image is picked, it's added as an editable item.
  /// Calls setState to update UI after adding the image.
  Future<void> _onImagepickerTap() async {
    await [Permission.photos, Permission.storage].request();
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      _stackData.add(
        CanvasElement()
          ..type = ItemType.image
          ..value = pickedFile.path,
      );
      setState(() {});
    }
  }

  /// Handles the submission of text input.
  ///
  /// This method is called when the user submits the text input field.
  /// If the input is not empty, it calls the [_onSubmitText] method to add the text to the stack data.
  /// If the input is empty, it resets the [_currentText] to an empty string.
  void _onTextSubmit(String input) {
    if (input.isNotEmpty) {
      setState(_onSubmitText);
    } else {
      setState(() {
        _currentText = '';
      });
    }

    setState(() {
      _addNewItemOfType = null;
      _activeItem = null;
    });
  }

  /// Handles the change of text input.
  ///
  /// This method is called when the user types into the text input field.
  /// It updates the [_currentText] with the new input.
  void _onTextChange(input) {
    setState(() {
      _currentText = input;
    });
  }

  /// Changes the background of the text.
  ///
  /// This method is called when the user taps on the text background change button.
  /// It increments the [_selectedTextBackgroundGradient] index if it's less than the length of provided backgroundGradientColors array.
  /// If the index has reached the end of the array, it resets it to 0.
  void _onChangeTextBackground() {
    if (_selectedTextBackgroundGradient <
        widget.backgroundGradientColorList.length - 1) {
      setState(() {
        _selectedTextBackgroundGradient++;
      });
    } else {
      setState(() {
        _selectedTextBackgroundGradient = 0;
      });
    }
  }

  /// Toggles the text color selector.
  ///
  /// This method is called when the user taps on the text color selector button.
  /// It toggles the [_isColorPickerSelected] flag to show or hide the color picker.
  void _onToggleTextColorSelector() {
    setState(() {
      _isColorPickerSelected = !_isColorPickerSelected;
    });
  }

  /// Handles the change of text color.
  ///
  /// This method is called when the user selects a new text color from the color picker.
  /// It updates the [_selectedTextColor] with the new color.
  /// The [index] parameter is the index of the selected color in the provided fontColorList list.
  void _onTextColorChange(index) {
    HapticFeedback.lightImpact();
    setState(() {
      _selectedTextColor = widget.fontColorList[index];
    });
  }

  /// Handles the change of font family.
  ///
  /// This method is called when the user selects a new font family from the font family picker.
  /// It updates the [_selectedFontFamily] with the new font family.
  /// The [index] parameter is the index of the selected font family in the [fontFamilyList] list.
  void _onFamilyChange(index) {
    HapticFeedback.lightImpact();
    setState(() {
      _selectedFontFamily = index;
    });
  }

  /// Toggles the background gradient picker.
  ///
  /// This method is called when the user taps on the background gradient picker button.
  /// It toggles the [_isBackgroundColorPickerSelected] flag to show or hide the background gradient picker.
  void _onToggleBackgroundGradientPicker() {
    setState(() {
      _isBackgroundColorPickerSelected = !_isBackgroundColorPickerSelected;
    });
  }

  /// Handles the selection of a background gradient.
  ///
  /// This method is called when the user selects a new background gradient from the gradient picker.
  /// It updates the [_selectedBackgroundGradient] with the new gradient and jumps the [_gradientsPageController] to the selected page.
  /// The [index] parameter is the index of the selected gradient in the provided backgroundGradientColor list.
  void _onBackgroundGradientTap(index) {
    setState(() {
      _selectedBackgroundGradient = index;
      _gradientsPageController.jumpToPage(index);
    });
  }

  /// Handles the change of background gradient.
  ///
  /// This method is called when the user selects a new background gradient from the gradient picker.
  /// It updates the [_selectedBackgroundGradient] with the new gradient.
  /// The [index] parameter is the index of the selected gradient in the provided backgroundGradientColor list.
  void _onChangeBackgroundGradient(index) {
    HapticFeedback.lightImpact();
    setState(() {
      _selectedBackgroundGradient = index;
    });
  }

  /// Handles the start of a scale gesture.
  ///
  /// This method is called when the user starts a scale gesture on the active item.
  /// It sets the [_initPos], [_currentPos], [_currentScale], and [_currentRotation] to the initial values of the gesture.
  /// The [details] parameter contains the details of the scale start gesture.
  void _onScaleStart(ScaleStartDetails details) {
    if (_activeItem == null) {
      return;
    }
    _initPos = details.focalPoint;
    _currentPos = _activeItem!.position;
    _currentScale = _activeItem!.scale;
    _currentRotation = _activeItem!.rotation;
  }

  /// Handles the update of a scale gesture.
  ///
  /// This method is called when the user updates a scale gesture on the active item.
  /// It calculates the new position, rotation, and scale of the active item based on the gesture details and updates the state.
  /// The [details] parameter contains the details of the scale update gesture.
  void _onScaleUpdate(ScaleUpdateDetails details) {
    if (_activeItem == null) {
      return;
    }
    final delta = details.focalPoint - _initPos;
    final left = (delta.dx / context.width) + _currentPos.dx;
    final top = (delta.dy / context.height) + _currentPos.dy;

    setState(() {
      _activeItem!.position = Offset(left, top);
      _activeItem!.rotation = details.rotation + _currentRotation;
      _activeItem!.scale = details.scale * _currentScale;
    });
  }

  /// Handles the screen tap event.
  ///
  /// This method is called when the user taps on the screen.
  /// If the current text is not empty, it calls the [_onSubmitText] method to add the text to the stack data.
  /// It also initializes the [_familyPageController] and [_textColorsPageController] with their respective viewport fractions.
  void _onScreenTap() {
    setState(() {
      _addNewItemOfType = null;
      _activeItem = null;
      _currentlyEditingItemType = null;
      _isBackgroundColorPickerSelected = false;
    });

    if (_currentText.isNotEmpty) {
      setState(_onSubmitText);
    }
    _familyPageController = PageController(
      initialPage: _selectedFontFamily,
      viewportFraction: .125,
    );
    _textColorsPageController = PageController(
      initialPage: widget.fontColorList.indexWhere(
        (element) => element == _selectedTextColor,
      ),
      viewportFraction: .1,
    );
  }

  /// Shows the text editor view if enabled.
  ///
  /// Sets the item type to text for adding or editing.
  /// Calls setState to update the UI with the selected item type.
  void _showTextView() {
    if (!widget.enableTextEditor) {
      return;
    }
    setState(() {
      _addNewItemOfType = ItemType.text;
      _currentlyEditingItemType = ItemType.text;
    });
  }

  /// Handles the submission of text input.
  ///
  /// This method is called when the user submits the text input field.
  /// It adds a new [CanvasElement] of type [ItemType.text] to the [_stackData] with the current text, text color, text style, font size, and font family.
  /// It then resets the [_editingController] and [_currentText] to an empty string.
  void _onSubmitText() {
    _stackData.add(
      CanvasElement()
        ..type = ItemType.text
        ..value = _currentText
        ..textColor = _selectedTextColor
        ..textDecorationColor = _selectedTextBackgroundGradient
        ..fontSize = _selectedFontSize
        ..fontFamily = _selectedFontFamily,
    );
    _editingController.text = '';
    _currentText = '';
  }

  /// Handles the change of font style.
  ///
  /// This method is called when the user selects a new font style from the style picker.
  /// It updates the [_selectedFontFamily] with the new style and jumps the [_familyPageController] to the selected page.
  /// The [index] parameter is the index of the selected style in the [fontFamilyList] list.
  void _onStyleChange(int index) {
    HapticFeedback.lightImpact();
    setState(() {
      _selectedFontFamily = index;
    });
    _familyPageController.jumpToPage(index);
  }

  /// Handles the change of text color.
  ///
  /// This method is called when the user selects a new text color from the color picker.
  /// It updates the [_selectedTextColor] with the new color and jumps the [_textColorsPageController] to the selected page.
  /// The [index] parameter is the index of the selected color in the  provided fontColorList list.
  void _onColorChange(int index) {
    HapticFeedback.lightImpact();
    setState(() {
      _selectedTextColor = widget.fontColorList[index];
    });
    _textColorsPageController.jumpToPage(index);
  }

  /// Handles the tap event on an overlay item.
  ///
  /// This method is called when the user taps on an overlay item.
  /// It also removes the tapped item from the [_stackData] and initializes the [_familyPageController] and [_textColorsPageController] with their respective viewport fractions.
  /// The [e] parameter is the tapped [CanvasElement].
  void _onOverlayItemTap(CanvasElement e) {
    setState(() {
      _currentlyEditingItemType = e.type;
      _activeItem = e;
      _addNewItemOfType = null;
    });
    if (_currentlyEditingItemType == ItemType.text) {
      setState(() {
        _addNewItemOfType =
            _addNewItemOfType == ItemType.text ? null : ItemType.text;
        _activeItem = null;
        _editingController.text = e.value;
        _currentText = e.value;
        _selectedFontFamily = e.fontFamily;
        _selectedFontSize = e.fontSize;
        _selectedTextBackgroundGradient = e.textDecorationColor;
        _selectedTextColor = e.textColor;
        _stackData.removeAt(_stackData.indexOf(e));
      });
      _familyPageController = PageController(
        initialPage: e.textDecorationColor,
        viewportFraction: .1,
      );
      _textColorsPageController = PageController(
        initialPage: widget.fontColorList.indexWhere(
          (element) => element == e.textColor,
        ),
        viewportFraction: .1,
      );
    }
  }

  /// Handles the pointer down event on an overlay item.
  ///
  /// This method is called when the user starts a pointer down gesture on an overlay item.
  /// If the item is not an image and the widget is not in action, it sets the [_inAction] flag to true and updates the initial values of the gesture.
  /// The [e] parameter is the [CanvasElement] on which the gesture started.
  /// The [details] parameter contains the details of the pointer down gesture.
  void _onOverlayItemPointerDown(CanvasElement e, PointerDownEvent details) {
    if (_inAction) {
      return;
    }
    _inAction = true;
    _activeItem = e;
    _initPos = details.position;
    _currentPos = e.position;
    _currentScale = e.scale;
    _currentRotation = e.rotation;
  }

  /// Handles the pointer up event on an overlay item.
  ///
  /// This method is called when the user ends a pointer up gesture on an overlay item.
  /// It sets the [_inAction] flag to false and checks if the item is in the delete position.
  /// If the item is in the delete position, it removes the item from the [_stackData] and sets the [_activeItem] to null.
  /// The [e] parameter is the [CanvasElement] on which the gesture ended.
  /// The [details] parameter contains the details of the pointer up gesture.
  void _onOverlayItemPointerUp(CanvasElement e, PointerUpEvent details) {
    _inAction = false;
    if (e.position.dy >= 0.65 && e.position.dx >= 0.0 && e.position.dx <= 1.0) {
      setState(() {
        _stackData.removeAt(_stackData.indexOf(e));
        _activeItem = null;
      });
    }
    setState(() {
      _activeItem = null;
    });
  }

  /// Handles the pointer move event on an overlay item.
  ///
  /// This method is called when the user moves a pointer on an overlay item.
  /// It checks if the item is in the delete position and updates the [_isDeletePosition] flag accordingly.
  /// The [e] parameter is the [CanvasElement] on which the pointer is moving.
  /// The [details] parameter contains the details of the pointer move gesture.
  void _onOverlayItemPointerMove(CanvasElement e, PointerMoveEvent details) {
    final dyValue = e.type == ItemType.text ? 0.75 : 0.30;
    if (e.position.dy >= dyValue &&
        e.position.dx >= 0.0 &&
        e.position.dx <= 1.0) {
      setState(() {
        _isDeletePosition = true;
      });
    } else {
      setState(() {
        _isDeletePosition = false;
      });
    }
  }

  /// Crops the image and updates the image in stack.
  ///
  /// First fetces the image information from [_cropController] and convert it to File type.
  /// updates the [_activeItem] image path value.
  /// Closes the overlay by calling [_onScreenTap].
  Future<void> _onCropImagetap() async {
    final bitmap = await _cropController.croppedBitmap();
    final data = await bitmap.toByteData(format: ImageByteFormat.png);
    final bytes = data!.buffer.asUint8List();
    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final filePath = '${directory.path}/cropped_image_$timestamp.png';
    final file = File(filePath);
    final croppedImage = await file.writeAsBytes(bytes);
    setState(() {
      _activeItem!.value = croppedImage.path;
      _onScreenTap();
    });
  }

  /// Opens Giphy to select a gif and adds it to the stack.
  ///
  /// Fetches a gif using the Giphy API through [Giphy.getGif]
  /// if a gif is selected, it's added as an editable item to the stack data.
  /// Updates the state to reflect the new gif addition.
  void _onAddGifTap() async {
    if (widget.giphyApiKey == null || widget.giphyApiKey!.isEmpty) {
      showDialog(
        context: context,
        barrierDismissible: true,
        builder: (context) => AppAlertDialogue(
          title: 'Giphy API key is required',
          description:
              'Please provide api key for Giphy to use GIF editor feature',
          continueButtonTitle: 'Ok',
          shouldShowCancelButton: false,
          onContinueTap: () {
            Navigator.maybePop(context);
          },
        ),
      );
    } else {
      final gif =
          await Giphy.getGif(context: context, apiKey: widget.giphyApiKey!);
      if (gif != null) {
        setState(() {
          _stackData.add(
            CanvasElement()
              ..type = ItemType.gif
              ..giphyImage = gif,
          );
        });
      }
    }
  }

  /// Opens a dialog to create a sticker and allows image selection from gallery.
  ///
  /// Displays a dialog with options to cancel or open the gallery. If the gallery is opened,
  /// requests permissions, selects an image, and sets it as the current sticker path.
  /// Updates the state to reflect the selected sticker image.
  void _onCreateStickerTap() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AppAlertDialogue(
        title: 'Create a cutout sticker',
        description: 'Select a photo with a clear subject to create sticker.',
        continueButtonTitle: 'Open Gallery',
        cancelButtonTitle: 'Cancel',
        shouldShowCancelButton: true,
        onCancleTap: () {
          Navigator.maybePop(context);
        },
        onContinueTap: () async {
          await [Permission.photos, Permission.storage].request();
          final picker = ImagePicker();
          final pickedFile = await picker.pickImage(
            source: ImageSource.gallery,
          );
          if (context.mounted) {
            await Navigator.maybePop(context);
          }
          if (pickedFile != null) {
            setState(() {
              _currentlyEditingItemType = ItemType.sticker;
              imagePathForSticker = pickedFile.path;
            });
          }
        },
      ),
    );
  }

  /// Handles the done event.
  ///
  /// This method is called when the user taps on the done button.
  /// It captures the current state of the widget and checks if GIF is included in design.
  /// Based on items on stack it returns image or GIF.
  Future<void> _onDone({
    required bool shouldSaveToGallery,
    required BuildContext buildContext,
  }) async {
    if (_stackData.isEmpty) {
      return;
    }
    try {
      _isLoading = true;
      setState(() {});
      bool isGIFContained = false;
      for (final element in _stackData) {
        if (element.type == ItemType.gif) {
          isGIFContained = true;
          break;
        }
      }
      final File? imageFile;
      if (isGIFContained == true) {
        imageFile = await _saveGif(
          shouldSaveToGallery: shouldSaveToGallery,
          buildContext: buildContext,
        );
      } else {
        //
        imageFile = await _saveImage(
          format: widget.imageFormatType,
          buildContext: buildContext,
          shouldSaveToGallery: shouldSaveToGallery,
        );
      }
      _isLoading = false;
      setState(() {});
      if (shouldSaveToGallery) {
        return;
      }
      widget.onDesignReady(imageFile, _computeDesignConfigJson());
    } catch (e) {
      if (kDebugMode) {
        print('Some error occured while saving design $e');
      }
    }
  }

  Map<String, dynamic> _computeDesignConfigJson() {
    final List<Map<String, dynamic>> stackDataToJson = [];
    for (final item in _stackData) {
      stackDataToJson.add(
        item.toJson(
          fontBackgroundColorValue:
              widget.backgroundGradientColorList[item.textDecorationColor],
          fontFamilyValue: widget.fontFamilyList[item.fontFamily],
        ),
      );
    }
    return {
      'backgroundColor':
          widget.backgroundGradientColorList[_selectedBackgroundGradient],
      'designItems': stackDataToJson,
    };
  }

  /// Record screen and return GIF formate
  ///
  /// Waits for 3 seconds, stops recording and exports GIF and saves GIF to local storage
  Future<File?> _saveGif({
    required bool shouldSaveToGallery,
    required BuildContext buildContext,
  }) async {
    _screenRecordingController.start();
    await Future.delayed(Duration(seconds: 3));
    _screenRecordingController.stop(); 
    final gif = await _screenRecordingController.exporter.exportGif();
    if (gif != null) {
      Uint8List bytes = Uint8List.fromList(gif);
      final fileName = '${DateTime.now().millisecondsSinceEpoch}';
      if (!shouldSaveToGallery) {
        final dir = await getApplicationDocumentsDirectory();
        final file = File('${dir.path}/$fileName');
        return await file.writeAsBytes(bytes);
      } else {
        final result = await SaverGallery.saveImage(
          bytes,
          quality: 100,
          fileName: '$fileName.gif',
          skipIfExists: false,
        );
        final String content = result.isSuccess
            ? 'GIF saved successfully'
            : 'Could not save GIF. Please try again later.';
        if (!buildContext.mounted) {
          return null;
        }
        _showSnackbar(buildContext: buildContext, content: content);
        return null;
      }
    }
    return null;
  }

  /// Captures widget image from previewContainer
  ///
  /// Converts to PNG or JPG
  /// Saves image in documents directory with timestamp name based on the parameter value shouldSaveToGallery
  Future<File?> _saveImage({
    required ImageFormatType format,
    required bool shouldSaveToGallery,
    required BuildContext buildContext,
  }) async {
    final boundary = previewContainer.currentContext!.findRenderObject()
        as RenderRepaintBoundary?;
    final image = await boundary!.toImage(pixelRatio: 3);

    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

    final Uint8List imageBytes;
    final String imageExtension;
    final pngBytes = byteData!.buffer.asUint8List();
    if (format == ImageFormatType.jpg) {
      // Convert PNG bytes to JPG using image package
      final decodedImage = img.decodeImage(pngBytes);
      imageBytes = img.encodeJpg(decodedImage!);
      imageExtension = '.jpg';
    } else {
      imageBytes = pngBytes;
      imageExtension = '.png';
    }
    final directory = (await getApplicationDocumentsDirectory()).path;
    final fileName = '${DateTime.now().millisecondsSinceEpoch}';
    if (!shouldSaveToGallery) {
      // save to temporary directory
      final file = File('$directory/$fileName$imageExtension');
      return await file.writeAsBytes(imageBytes);
    } else {
      final result = await SaverGallery.saveImage(
        imageBytes,
        quality: 100,
        fileName: '$fileName$imageExtension',
        skipIfExists: false,
      );
      final String content = result.isSuccess
          ? 'Image saved successfully'
          : 'Could not save image. Please try again later.';
      if (!buildContext.mounted) {
        return null;
      }
      _showSnackbar(buildContext: buildContext, content: content);
      return null;
    }
  }

  /// Called when this object is removed from the tree permanently.
  ///
  /// The framework calls this method when this [State] object will never build again.
  /// This method is where you should unsubscribe or dispose any resources, streams, or animations that were created in [initState].
  @override
  void dispose() {
    _editingController.dispose();
    _familyPageController.dispose();
    _textColorsPageController.dispose();
    _gradientsPageController.dispose();
    super.dispose();
  }
}
