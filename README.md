# Godot-IDE
Godot IDE Extension

<a href='https://ko-fi.com/S6S11CPSR5' target='_blank'><img height='36' style='border:0px;height:36px;' src='https://storage.ko-fi.com/cdn/kofi4.png?v=6' border='0' alt='Buy Me a Coffee at ko-fi.com' /></a>

[![Godot Engine 4.3](https://img.shields.io/badge/Godot_Engine-4.x-blue)](https://godotengine.org/) ![Copyrights License](https://img.shields.io/badge/License-MIT-blue)

This addon extend Godot Features

![Preview](images/preview0.png)

### This repository contain work from:
How it works is also described in each link.

* Multi Split Container:
  https://github.com/CodeNameTwister/Multi-Split-Container
* Script Spliter:
  https://github.com/CodeNameTwister/Script-Spliter
* Quick Folds:
  https://github.com/CodeNameTwister/Quick-Folds
* GD Override Functions:
  https://github.com/CodeNameTwister/GD-Override-Functions
* Fancy Filters Script:
  *Integrated with this plugin, not repository released.*
* Fancy Search Files:
  *Integrated with this plugin, not repository released.*

# Objetive
The goal of this project is to provide godot with some additional features without worrying about adding extra load to the CPU if it means improving the development experience.

# How contribute

### Make new plugin
To add a plugin that works alongside Godot-IDE, simply create a plugin as you normally would and add it to the \_Godot-IDE\_/plugins folder.

>[!TIP]
> The Godot-IDE search by plugin.cfg file what file should enable.

### Make a Request
In Issue tab, you can write you request/changes for the future of this plugin.

### FAQ
* Why called \_Godot-IDE\_ folder?
	* This is due to the way addons are loaded in Godot, currently in alphabetical order giving priority to this addon avoiding any incompatibility for the plugins.

# Quick Tips

* Split Windows:
	* Can use [Ctrl + 1, Ctrl + 2, Ctrl + 3, Ctrl + 4] for change of type split (Required more than 1 script opened)
  	* You can create/remove split with Right mouse Button Context Menu. (Depend of script opened or split current count)

* Quick Flods:
	* Can use [Atl + 1, Atl + 2, ... Atl + 9, Atl + 0] for fold lines.
	* Can use [Shift + Atl + 1, Shift + Atl + 2, ... Shift + Atl + 9, Shift + Atl + 0] as inversed for show lines.

* GD Override Functions
	* RMB (Right Mouse Button) On editing Script for show Override Functions: Can generate functions inherited.

* Fancy Search Files
	* [Ctrl + Atl + Space] Invoke Easy Searcher Window

* Fancy Filters Script
	* In File tab on editor, you can Show/Hide/Toggle The neighbor panel of the editor.


# TODO
* Documentation.


#
> Twister
>
> I hope this is helpful. Personally, I've decided to do everything in gdscript for compatibility reasons, but I might create a C++ extension if a future feature requires it, as in cases I've had for generations or using recursive functions that still offer poor performance.
>
> Now use it, break it, modify it, fix it, and improve it to your liking.

Copyrights (c) CodeNameTwister. See [LICENSE](LICENSE) for details.

[godot engine]: https://godotengine.org/
