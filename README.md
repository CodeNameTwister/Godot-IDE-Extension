# Godot-IDE
Godot IDE Extension

<a href='https://ko-fi.com/S6S11CPSR5' target='_blank'><img height='36' style='border:0px;height:36px;' src='https://storage.ko-fi.com/cdn/kofi4.png?v=6' border='0' alt='Buy Me a Coffee at ko-fi.com' /></a>

[![Godot Engine 4.3](https://img.shields.io/badge/Godot_Engine-4.x-blue)](https://godotengine.org/) ![Copyrights License](https://img.shields.io/badge/License-MIT-blue)

This addon extends Godot's native code editor with additional functionality and usability.

## Why use this?
If you're looking for a similar experience to other IDEs for developing in GDScript integrated in Godot, this plugin is ideal.

The Godot-IDE extension doesn't collect your data; it's completely free and open source. 

## Table of contents

- [Preview](#preview)
- [Features](#features)
- [Objectives](#objetives)
- [How to Use](#how-to-use)
- [How to Contribute](#how-to-contribute)
- [FAQ](#faq)
- [Special Thanks](#special-thanks-)

## Objetives
The goal of this project is to provide Godot with some additional features by adding some extra overload to improve the development experience and make it more similar to other existing development environments, but designed specifically by Godot users for Godot users.

## Preview
![Preview0](images/preview0.png)
![Preview1](images/preview1.png)

![image-20250823151418567](./images/image-20250823151418567.png)

![image-20250823151502218](./images/image-20250823151502218.png)

## Features

Each feature is described more fully in it's own repository, as well as down below.

* Multi Split Container:
	https://github.com/CodeNameTwister/Multi-Split-Container
* Script Spliter:
	https://github.com/CodeNameTwister/Script-Spliter
* Quick Folds:
	https://github.com/CodeNameTwister/Quick-Folds
* GD Override Functions:
	https://github.com/CodeNameTwister/GD-Override-Functions
* Refactor Tool Symbol Navigator:
	https://github.com/CodeNameTwister/Godot-IDE/tree/main/addons/_Godot-IDE_/plugins/symbol_navigator
	*  Find Symbol References (`Shift + F12`)
	  - **Instant Search**: Select a symbol and press `Shift + F12` to find all its usages.
	  - **Interactive Panel**: View results grouped by file in the bottom panel.
	  - **Code Preview**: Click any reference to see a preview of the code context.
	  - **Quick Navigation**: Double-click a reference to jump directly to the line.
	  - **Advanced Filtering**: Customize searches with case sensitivity, multiple match modes, and directory exclusion.
	* Rename Symbol (`F2`)
	  - **Smart Refactoring**: Select a symbol and press `F2` to open the rename dialog.
	  - **Interactive Preview**: Review all potential changes before renaming. Use checkboxes to include or exclude specific references.
	  - **Scope Control**: Choose to rename within the current file or the entire project.
	  - **Seamless Updates**: Modifies open files directly without annoying "reload" popups, preserving your scroll and cursor position.
	  - **Safe & Verified**: Automatically verifies that changes were applied correctly after the operation.
* The following plugins are integrated with this addon, they are not published as a separate plugin.
  * Fancy Filters Script: 
  * Fancy Search Files
  * Fancy Search Class
  * Macro-N

* [Documentation](https://github.com/CodeNameTwister/Godot-IDE/blob/main/DOCUMENTATION.md)

>[!TIP]
>* If you delete any plugin in the plugins folder, this addon will still work, so feel free to delete anything you don't want.
>* If there are more plugin contributors in the future, I will add a panel to enable and disable plugins at your discretion.


## How to use

* Script Spliter:
	* Use the new toolbar on the right to split/merge columns/rows.
  	* You can create/remove a split with the right mouse button context menu. (Depends on the number of opened scripts)
  	* You can also add popout windows from the same context menu

* Quick Folds:
	* Use `Alt + num` to fold all lines of the specified indent. e.g. `Alt + 1` folds everything, `Alt + 2` folds only second-level indented blocks.
	* Hold `Shift` at the same time to show folded lines. e.g. `Shift + Alt + 1` unfolds all code.

* GD Override Functions
	* From the right mouse button context menu the Override Virtual Functions can be opened.
	* This allows you to automatically generate override methods for virtual funcions in parent classes.
	* Use `Alt + insert` to open the override functions window.

* Fancy Search Files
	* Use `Ctrl + Alt + Space` to open the file search window where you can easily search all files in your project by type, name, etc.

* Fancy Search Class Files
	* Use `Alt + Delete` to open the class & script search window where you can easily view where individual classes and scripts are being used in your project.

* Fancy Filters Script
	* In the script editor two new tabs have been added to the left panel: Settings and Script Info. The Script Info tab gives you an overview of the current script and also allows you to view the properties of all classes which the current script inherits from. The Settings tab lets you configure the Script Info tab to your liking.
 	* Use `Ctrl + T` for show/hide the panel.
  	* Use `Ctrl + G` to switch between **script info** and the **script list** panels. (Only if separate script list is enabled)
  	* Flat mode in the settings tab allows a simple display of files/class members.
 
* Macro-N
	* Create Macro with `Context Menu (RMB)` (Show only to create Macro-N if you have text selected)
	* With selected text use `Ctrl + E` for Invoke Macro.
	* With selected text use `Ctrl + SHIFT + E` for Invoke Macro with bypass.
 	* Show all saved Macros with `Alt + END`shortcut.

* Refactor Tool Symbol Navigator:
	* Find References
	  1. In the script editor, place your cursor on or select a symbol (e.g., a function or variable name).
	  2. Press **`Shift + F12`**.
	  3. The "Find References" panel will open at the bottom with the results.
	* Rename Symbol
	  1. In the script editor, select a symbol you want to rename.
	  2. Press **`F2`**.
	  3. In the dialog, enter the new name, review the previewed changes, and click **Rename**.
	
* Editor Settings
	* In Editor Settings (with Advanced option enabled) you can change any option of this plugin in `plugin/godot_ide` or neighbors plugins of Godot-IDE.
 	* All plugins have their configuration parameters defined in that section, even for inputs.

## How to contribute

### Submit issues
Report any bugs you find in the [Issues](https://github.com/CodeNameTwister/Godot-IDE/issues) tab, as well as any feature requests you may have. Influence the future of this plugin!

### Submit pull requests
If you'd like to help out with development don't hesitate to submit a pull request!

### Integrate with this plugin
To add a plugin that works alongside Godot-IDE, simply create a plugin as you normally would and add it to the `_Godot-IDE_/plugins` folder.

>[!TIP]
> Additional scripts must also be enabled in the `plugin.cfg` file.

## FAQ
* Why is the folder called `_Godot-IDE_`?
	* This is due to the way addons are loaded in Godot, which is alphabetical. This naming gives priority to this addon, avoiding any incompatibility for other plugins.

## Special Thanks 📜
This section lists users who have contributed to improving the quality of this project.

- [@kyrosle](https://github.com/kyrosle)
- [@nathan-coleman](https://github.com/nathan-coleman)
- [@sam-online](https://github.com/sam-online)
- [@WILSON](https://github.com/WlLSON)

##
> I hope this is helpful. Personally, I've decided to do everything in gdscript for compatibility reasons, but I might create a C++ extension if a future feature requires it, as in cases I've had for generations or using recursive functions that still offer poor performance.
>
> Now use it, modify it, break it, fix it, and improve it to your liking.

Twister

##
Copyrights (c) CodeNameTwister. See [LICENSE](LICENSE) for details.

[godot engine]: https://godotengine.org/
