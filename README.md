# Data Process in Physics
 Make life easier.

- [Hall 效应反对称化处理](#Hall-效应反对称化处理)
## Hall 效应反对称化处理

### Hall 效应反对称化处理理论基础

![Untitled](./pics/asymHall-霍尔效应反对称化处理示意图.png)

![Untitled](./pics/asymHall-binned_data.png)

由于器件制备过程中电极排布存在偏移（或外加磁场未严格垂直于电流方向），使得测得的 Hall 电压 $`V_{xy}^{raw}`$ 中混杂有纵向电压信号：

$$
V_{xy}^{raw}=V_{xy}+\delta V_{xy}
$$

一般而言，纵向电压是关于磁场的偶函数：$`V_{xx}(B)=V_{xx}(-B)`$，而 Hall 电压为磁场的奇函数：$`V_{xx}(B)=-V_{xx}(-B)`$，则

$$
V_{xy}^{raw}(B)=V_{xy}(B)+\delta V_{xx}(B)
$$

$$
V_{xy}^{raw}(-B)=-V_{xy}(B)+\delta V_{xx}(B)
$$

故：$`V_{xy}(B)=\frac{V_{xy}^{raw}(B)-V_{xy}^{raw}(-B)}{2}`$

由于正向扫场和负向扫场时未必能精确在同一磁场值下测量，因此在进行反对称化处理时，需要先采取分箱法统一测量磁场后进行处理。

参考文献：

1. Graham Kimbell, et al., Two-channel anomalous Hall effect in $\rm SrRuO_3$, PHYSICAL REVIEW MATERIALS 4, 054414 (2020)
2. 蔡冉冉，超导/铁磁异质结中自旋输运研究，北京大学 (2022)

### 参考代码

- [完整代码](./scripts/AsymHall.m)
	- [with linear subtraction](./scripts/AsymHall_with_linear_subtraction.m)：这个代码可能在处理上存在一些问题，需要修改
- [可调用函数](./scripts/asym_Hall.m)
