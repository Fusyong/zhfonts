本项目是对[liyanrui/zhfonts](https://github.com/liyanrui/zhfonts)项目的改造，谨致谢忱！目前可用于ConTeXt中文直排实验项目[vertical-typesetting](https://github.com/Fusyong/vertical-typesetting)。

## 使用方法

参见[jiazhu](https://github.com/Fusyong/jiazhu)项目。

## bug & TODO

* [x] 不再使用预设表，而是**根据字体数据实际测算（固定占位半字或一字），并缓存**
* [x] 标点压缩问题：短行中有禁则时导致过度压缩（**改成半字后其后胶性没有更改**）
* [x] 行头尾悬挂标点的bar的长度超越边框
* [ ] 检查并报告系统的中文标点支持预设错误无（char-scr.lua、char-def.lua、font-imp-quality.lua等）
    * [ ] 连续标点中间添加无限罚分，导致无法断行
* [ ] 《标点符号用法》5.1横排文稿标点符号的位置和书写形式
    * [x] 5.1.1 句号、逗号、顿号、分号、冒号均置于相应文字之后，占一个字位置，居左下，不出现在一行之首。
    * [x] 5.1.2 问号、叹号均置于相应文字之后，占一个字位置，居左，不出现在一行之首。两个问号（或叹号）叠用时，占一个字位置；三个问号（或叹号）叠用时，占两个字位置；问号和叹号连用时，占一个字位置。
    * [x] 5.1.3 引号、括号、书名号中的两部分标在相应项目的两端，各占一个字位置。其中前一半不出现在一行之末，后一半不出现在一行之首。
    * [ ] 5.1.4 破折号标在相应项目之间，占两个字位置，上下居中，不能中间断开分处上行之末和下行之首。
    * [ ] 5.1.5 省略号占两个字位置，两个省略号连用时占四个字位置并须单独占一行。省略号不能中间断开分处上行之末和下行之首。
    * [x] 5.1.6 连接号中的短横线比汉字“一”略短，占半个字位置；一字线比汉字“一”略长，占一个字位置；浪纹线占一个字位置。连接号上下居中，不出现在一行之首。
    * [ ] 5.1.7 间隔号标在需要隔开的项目之间，**占半个字位置，上下居中，不出现在一行之首。**
    * 5.1.8 着重号和专名号标在相应文字的下边。
    * [ ] 5.1.9 分隔号占半个字位置，不出现在一行之首或一行之末。
    * [x] 5.1.10 标点符号排在一行末尾时，若为全角字符则应占半角字符的宽度（即半个字位置），以使视觉效果更美观。
    * [x] 5.1.ll 在实际编辑出版工作中，为排版美观、方便阅读等需要，或为避免某一小节最后一个汉字转行或出现在另外一页开头等情况（浪费版面及视觉效果差），**可适当压缩标点符号所占用的空间。**
* [ ] 在夹注中应用标点悬挂

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
