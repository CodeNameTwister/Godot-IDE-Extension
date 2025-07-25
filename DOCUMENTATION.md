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
* ![Private](https://raw.githubusercontent.com/CodeNameTwister/Godot-IDE/315d6504a11802773da1beef81e54275bd60a524/addons/_Godot-IDE_/shared_resources/func_private.svg "Private") **Private Member**
	* It should only be used by the same class.

##### Other Modifiers
* ![Exported](https://raw.githubusercontent.com/CodeNameTwister/Godot-IDE/b38e75b73381225e15cb1c3e65e8c3b8e1659bda/addons/_Godot-IDE_/shared_resources/MemberAnnotation.svg "Exported") Export
* ![Signals](https://raw.githubusercontent.com/CodeNameTwister/Godot-IDE/b38e75b73381225e15cb1c3e65e8c3b8e1659bda/addons/_Godot-IDE_/shared_resources/MemberSignal.svg "Signals") Signal
* ![Static](https://raw.githubusercontent.com/CodeNameTwister/Godot-IDE/b38e75b73381225e15cb1c3e65e8c3b8e1659bda/addons/_Godot-IDE_/shared_resources/static.svg "Static") Static
* ![Constant](https://raw.githubusercontent.com/CodeNameTwister/Godot-IDE/b38e75b73381225e15cb1c3e65e8c3b8e1659bda/addons/_Godot-IDE_/shared_resources/MemberConstant.svg "Constant") Constant
* ![Override](https://raw.githubusercontent.com/CodeNameTwister/Godot-IDE/b38e75b73381225e15cb1c3e65e8c3b8e1659bda/addons/_Godot-IDE_/shared_resources/MethodOverride.svg "Override") Overrided member

## Fancy Search Files
This plugin scans and displays all files by cataloging them by type.

#### Preview
![Preview](https://private-user-images.githubusercontent.com/153237709/464450067-750cb78c-bb22-4023-a2bf-832ab506cc91.png?jwt=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJnaXRodWIuY29tIiwiYXVkIjoicmF3LmdpdGh1YnVzZXJjb250ZW50LmNvbSIsImtleSI6ImtleTUiLCJleHAiOjE3NTM0MjExNjAsIm5iZiI6MTc1MzQyMDg2MCwicGF0aCI6Ii8xNTMyMzc3MDkvNDY0NDUwMDY3LTc1MGNiNzhjLWJiMjItNDAyMy1hMmJmLTgzMmFiNTA2Y2M5MS5wbmc_WC1BbXotQWxnb3JpdGhtPUFXUzQtSE1BQy1TSEEyNTYmWC1BbXotQ3JlZGVudGlhbD1BS0lBVkNPRFlMU0E1M1BRSzRaQSUyRjIwMjUwNzI1JTJGdXMtZWFzdC0xJTJGczMlMkZhd3M0X3JlcXVlc3QmWC1BbXotRGF0ZT0yMDI1MDcyNVQwNTIxMDBaJlgtQW16LUV4cGlyZXM9MzAwJlgtQW16LVNpZ25hdHVyZT0yNDFhNDAyZWRlMTM2NjU5NzBjOWMyYTkyYmJjZDQwMjdjN2Q5ZDJmMGRkNmNlOTgyOWM4ZmQ0OTBlMzZiNTYzJlgtQW16LVNpZ25lZEhlYWRlcnM9aG9zdCJ9.0H_S9fRz2jhTYw5IxQVuo_CnCSYLqcsLZfzNsj1OFfE "Preview")

#### Features
* Search and show all files by type.
* History of recents searched files.

#### Shortcut
* `Ctrl + Alt + Space` to show window panel.

## Fancy Search Class
This plugin scans and displays all files by cataloging them by class type.

#### Preview
![Classt](https://private-user-images.githubusercontent.com/153237709/464450016-f2ae6616-7063-4906-9f88-d4505543d30f.png?jwt=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJnaXRodWIuY29tIiwiYXVkIjoicmF3LmdpdGh1YnVzZXJjb250ZW50LmNvbSIsImtleSI6ImtleTUiLCJleHAiOjE3NTM0MjExNjAsIm5iZiI6MTc1MzQyMDg2MCwicGF0aCI6Ii8xNTMyMzc3MDkvNDY0NDUwMDE2LWYyYWU2NjE2LTcwNjMtNDkwNi05Zjg4LWQ0NTA1NTQzZDMwZi5wbmc_WC1BbXotQWxnb3JpdGhtPUFXUzQtSE1BQy1TSEEyNTYmWC1BbXotQ3JlZGVudGlhbD1BS0lBVkNPRFlMU0E1M1BRSzRaQSUyRjIwMjUwNzI1JTJGdXMtZWFzdC0xJTJGczMlMkZhd3M0X3JlcXVlc3QmWC1BbXotRGF0ZT0yMDI1MDcyNVQwNTIxMDBaJlgtQW16LUV4cGlyZXM9MzAwJlgtQW16LVNpZ25hdHVyZT00NzZjYjM1Mzg4ZThhNmRmMTYwOTdhZGFjMjQzZDVmOWY4NWZhNjY0OTFmOTJhZjQ2NDE4NzRjYmRkMWYyYmM4JlgtQW16LVNpZ25lZEhlYWRlcnM9aG9zdCJ9.cyx_5Uvf-kI8j64dhtkfn4wiqOh0CIJ9FU27LmSWtzM "Classt")

#### Features
* Search and show all files by class.
* History of recents searched class files.

#### Shortcut
* `Alt + Delete` to show window panel.







