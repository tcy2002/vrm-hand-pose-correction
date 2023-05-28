# VRM模型手势校正笔记

### 背景

修改Godot-OpenXR插件后，将原OpenXR手势信息（来自Leap Motion）绑定到VRM模型的手部骨骼上；由于原OpenXR手模型与VRM手模型存在差异，导致重新绑定后出现的蒙皮扭曲现象，需要进行校正。校正的思路并不复杂，主要包括两个步骤：

- 将每个骨骼点的Pose-Origin校正到Rest-Origin的方向上；

- 修正由于以上改变导致的骨骼方向变化。

### 校正示意图

错误骨骼

![1.jpg](screenshots\1.jpg)

校正后的骨骼

![2.jpg](screenshots\2.jpg)

### 校正过程

1、对于一个需要校正的骨骼点，计算Rest-Origin方向与实际Origin（Rest-Origin + Pose-Origin）方向的夹角，此夹角即导致蒙皮扭曲的附加旋转角$θ$；

2、保持实际Origin的模长不变，使实际Origin的方向修正为Rest-Origin的方向，计算校正后的Pose-Origin；

3、附加旋转角$θ$对应的Basis矩阵$C$，父骨骼点Pose-Basis矩阵$B_p$，当前骨骼点Pose-Basis矩阵$B$，修正后的父骨骼点Pose-Basis矩阵为$B_p^θ=B_p·C$，校正后的当前骨骼点Pose-Basis矩阵为$B^θ​=C^{-1}·B$. 

需要注意的是，由于掌根骨骼点有5个子骨骼点，在校正掌根骨骼点时无法同时满足5个子骨骼点的姿态校正，因此在计算附加旋转角$θ$时，采用平均的方式来尽量拟合5个自骨骼点的姿态。校正代码位于./assets/adjust_hand.gd

### 校正结果

未进行校正时，扭曲的手掌蒙皮

![initial.png](screenshots\initial.png)

校正手指骨骼点后的效果

![finger.gif](screenshots\finger.gif)

校正手掌跟骨骼点后的效果

![wrist.gif](screenshots\wrist.gif)

- hand-openxr.png - openxr手部骨骼点位置图

- hand-alicia.txt - vrm模型（女生）手部骨骼点编号

- hand-test-model.txt - vrm模型（男生）手部骨骼点编号

由于男生手部骨骼点模型与openxr手模型差异较大，而且手臂IK存在问题，因此未对男生进行手势绑定。
