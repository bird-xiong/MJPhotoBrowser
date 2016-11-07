# MJPhotoBrowser
基于MJPhotoBrowser优化了图片加载模式与动画机制，修复了一些bug
## 示例
![image](https://github.com/bird-xiong/MJPhotoBrowser/blob/master/MJPhotoBrowser/mj.gif) 
## 修改
1、MJ浏览窗口是基于window层级，修改为viewController present的方式展示窗口<p>
2、MJ动画没有从View层级中分离，修改为present 的自定义转场动画<p>
3、MJ浏览图片展示基于ScrollView，修改为CollectiionView，重写了热加载机制<p>
## 依赖
本项目使用Masonry 写界面布局，运行前请在项目根目录执行`pod install` 命令
本项目使用pod版本为1.0.1，使用前先使用以下命令升级pod版本
```shell
$ sudo gem update --system
$ sudo gem install cocoapods
$ pod setup
```
