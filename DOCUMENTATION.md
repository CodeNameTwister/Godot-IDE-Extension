# Godot-IDE

`(Work in Progress)`

All customizable settings can be found in Editor Settings (with advance option enabled)

Reference in plugin section like `plugin/godot_ide/*`

## Index
  * [Fancy Filters Script](#fancy-filters-script)
    + [Preview](#preview)
    + [Features](#features)
    + [Shortcuts](#shortcuts)
    + [Access modifiers](#access-modifiers)
- [Fancy Search Files](#fancy-search-files)
    + [Preview](#preview-1)
    + [Features](#features-1)
    + [Shortcut](#shortcut)
- [Fancy Search Class](#fancy-search-class)
    + [Preview](#preview-2)
    + [Features](#features-2)
    + [Shortcut](#shortcut-1)
- [Macro-N](#macro-n)
    + [Preview](#preview-3)
    + [Features](#features-3)
    + [Shortcut](#shortcut-2)
 
## Fancy Filters Script

This plugin seeks to assimilate the information displayed in the editor by showing full details of script members, including inheritance, and also adds access modifiers for greater clarity of elements.

In the script editor two new tabs have been added to the left panel: Settings and Script Info. The Script Info tab gives you an overview of the current script and also allows you to view the properties of all classes which the current script inherits from. The Settings tab lets you configure the Script Info tab to your liking.

#### Preview
![Filters](https://github.com/CodeNameTwister/Godot-IDE/raw/main/images/preview1.png "Filters")

#### Features
* Show members of the current script (called "items" by the plugin)
* Access modifiers for members of the script.
* Double click for go where the member is defined.
* RMB to display a pop-up window with options:
	* Copy the header of member to clipboard.
	* Copy full header to clipboard for be override.
	* Go to where the member is defined.
* Setting panel with quick access to minor modifications.
* Change position to the right.
* Add a new menu button called Godot-IDE.

#### Shortcuts
* `Ctrl+T` Hide the panel.
* `Ctrl+G` Switch between Script Info/List.

#### Access modifiers
*`First of all, I should say that if you are a designer, you don't need to memorize this, since you probably have a high-level workflow like Unity, if that is the case, you should know that access modifiers are just a way for the developer to write code since access modifiers do not make any changes when the program is loaded into memory.`*


* ![Public](https://raw.githubusercontent.com/CodeNameTwister/Godot-IDE/315d6504a11802773da1beef81e54275bd60a524/addons/_Godot-IDE_/shared_resources/func_public.svg "Public") **Public Member**
	* Safe use to be called by other scripts.
* ![Virtual](https://raw.githubusercontent.com/CodeNameTwister/Godot-IDE/315d6504a11802773da1beef81e54275bd60a524/addons/_Godot-IDE_/shared_resources/func_virtual.svg "Virtual") **Virtual Member**
	* Safe to be called in script inheritance.
 	* By default, the member name starts with `_` example: `var _my_virtual_member`,`func _my_virtual_function()`
* ![Private](https://raw.githubusercontent.com/CodeNameTwister/Godot-IDE/315d6504a11802773da1beef81e54275bd60a524/addons/_Godot-IDE_/shared_resources/func_private.svg "Private") **Private Member**
	* It should only be used by the same class.
 	* By default, the member name starts with `__` example: `var __my_private_member`,`func __my_private_function()`

#### Native modifiers
* ![Exported](https://raw.githubusercontent.com/CodeNameTwister/Godot-IDE/b38e75b73381225e15cb1c3e65e8c3b8e1659bda/addons/_Godot-IDE_/shared_resources/MemberAnnotation.svg "Exported") Export
* ![Signals](https://raw.githubusercontent.com/CodeNameTwister/Godot-IDE/b38e75b73381225e15cb1c3e65e8c3b8e1659bda/addons/_Godot-IDE_/shared_resources/MemberSignal.svg "Signals") Signal
* ![Static](https://raw.githubusercontent.com/CodeNameTwister/Godot-IDE/b38e75b73381225e15cb1c3e65e8c3b8e1659bda/addons/_Godot-IDE_/shared_resources/static.svg "Static") Static
* ![Constant](https://raw.githubusercontent.com/CodeNameTwister/Godot-IDE/b38e75b73381225e15cb1c3e65e8c3b8e1659bda/addons/_Godot-IDE_/shared_resources/MemberConstant.svg "Constant") Constant
* ![Override](https://raw.githubusercontent.com/CodeNameTwister/Godot-IDE/b38e75b73381225e15cb1c3e65e8c3b8e1659bda/addons/_Godot-IDE_/shared_resources/MethodOverride.svg "Override") Overrided member

## Fancy Search Files
This plugin scans and displays all files by cataloging them by type.

#### Preview
<img width="487" height="497" alt="image" src="https://github.com/user-attachments/assets/ed14822f-cc92-4f53-93fb-3db573e2ebb9" />


#### Features
* Search and show all files by type.
* History of recents searched files.

#### Shortcut
* `Ctrl + Alt + Space` to show window panel.

## Fancy Search Class
This plugin scans and displays all files by cataloging them by class type.

#### Preview
<img width="491" height="493" alt="image" src="https://github.com/user-attachments/assets/df5adf92-e334-40e1-8185-2a6e1a2f25a9" />

#### Features
* Search and show all files by class.
* History of recents searched class files.

#### Shortcut
* `Alt + Delete` to show window panel.

## Macro-N
This plugin allows you to simplify any complex and repetitive code in just a few steps.

#### Preview
[Example Tutorial](https://github.com/CodeNameTwister/Godot-IDE/discussions/10)

#### Features
* Create/Edit/Remove Macro
* Generate Code by Macro
* Save Macro in `macro-n/save` folder

#### Shortcut
* `CTRL+E` : Invoke Macro.
* `CTRL+SHIFT+E`: Invoke Macro with by pass (It respects additional text you have selected and can invoke nested macros within the macro content.)
* `Context Menu`: Show only to create Macro-N if you have text selected.
* `ATL+END`: Show All Macro-N saved.



