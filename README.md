本项目是对[liyanrui/zhfonts](https://github.com/liyanrui/zhfonts)项目的改造，谨致谢忱！目前可用于ConTeXt中文直排实验项目[vertical-typesetting](https://github.com/Fusyong/vertical-typesetting)。

## bug & TODO

* [x] 不再使用预设表，而是**根据字体数据实际测算（固定占位半字或一字），并缓存**
* [x] 标点压缩问题：短行中有禁则时导致过度压缩（**改成半字后其后胶性没有更改**）
* [x] 行头尾悬挂标点的bar的长度超越边框
* [ ] 检查并报告系统的中文标点支持预设错误无（char-scr.lua、char-def.lua、font-imp-quality.lua等）
    * [ ] 连续标点中间添加无限罚分，导致无法断行

## 调整说明

* 增加文件t-zhspuncs.mkiv，使标点压缩成为一个独立模块。使用方法`\usemodule[zhspuncs]`
* 修改文件t-zhspuncs.lua
    * 使两个模块都可以使用；
    * 增加直排标点压缩支持；
    * 为教学目的添加中文注释。

## 原作者liyanrui的说明

* Introduction

zhfonts is a module for ConTeXt MkIV. It can help some users to try ConTeXt MkIV based LuaTeX for Chinese typesetting.

The zhfonts is implemented by using "nodes.tasks.appendaction('processors','after', 'my_callback_function')" which is offered by ConTeXt MkIV.Therefore I could not guarantee zhfonts works all along unless my_callback_function is always valid.

* Usage

Please read http://garfileo.is-programmer.com/posts/23740
