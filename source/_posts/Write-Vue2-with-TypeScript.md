---
title: Write Vue2 with TypeScript
date: 2022-03-24 15:28:37
tags:
---

在 Vue2 中，我们编写的 单文件组件（SCF，也即 Single-File Components），其实是 vue 自创的前端领域语言（类比小程序开发语言，也是一门领域语言），形式如下所示：

```vue
<template>
  <div class="title" @click="onClick">{{ title }}</div>
</template>

<script>
export default {
  props: {
    // 基础的类型检查 (`null` 和 `undefined` 会通过任何类型验证)
    propA: Number,
    // 多个可能的类型
    propB: [String, Number],
    // 必填的字符串
    propC: {
      type: String,
      required: true
    },
  },

  data() {
    return {
      title: 'hello, vue',
    }
  },

  methods: {
    onClick() {
      console.log('click');
    }
  }
}
</script>

<style>
.title {
  color: red;
}
</style>
```

其中 `<script> ... </script>` 标签内包含了一个使用 JavaScript 编写的、 Vue 组件的配置对象，配置对象中包含 props、data、methods 等内容。

从上面的示例可以看出，Vue 只能够对 props 进行有限的类型检查，不能对 data、methods 等其他配置项做类型声明。并且在对 props 进行类型声明时，只能使用下列原生构造函数：String Number Boolean Array Object Date Function Symbol 来做类型校验，不能进行更具体、深入的类型声明，可以说是非常鸡肋。

对一个对象进行 TypeScript 类型声明是比较困难的，而对 `class` 进行 TypeScript 类型声明是相对简单、自然的：我们可以很方便地对 class 的属性和方法添加类型，还可以通过 `extends` 继承父类的类型。如下所示：

```ts
class Animal {
  name: string;

  constructor(theName: string) {
    this.name = theName;
  }

  move(distanceInMeters: number = 0) {
    console.log(`${this.name} moved ${distanceInMeters}m.`);
  }
}
 
class Horse extends Animal {
  constructor(name: string) {
    super(name);
  }

  move(distanceInMeters = 45) {
    console.log("Galloping...");
    super.move(distanceInMeters);
  }
}
```

那么我们是否可以使用 class 来写 Vue 组件呢？这就是 [Decorators （装饰器）](https://www.typescriptlang.org/docs/handbook/decorators.html)。

本质上，装饰器就是一个函数。函数能做的事情，装饰器都能做。函数可以做任何类型的数据转换，装饰器也是一样的。

有了装饰器，我们就可以使用 `class` 和 TypeScript 来开发 Vue 组件；然后在运行时，使用装饰器将我们定义的 `class` 转换为 Vue 引擎能够识别的原生的 Vue 配置对象，如下所示。

开发时：

```ts
import { Vue, Component, Prop } from 'vue-property-decorator'

@Component
export default class YourComponent extends Vue {
  @Prop({ default: 'default value' }) readonly title!: string

  message: string = 'hello, world';

  onClick(): void {}
}
```

运行时，@Component 将自定义的组件 `YourComponent` 转换为 Vue 配置对象：

```js
export default {
  props: {
    title: {
      default: 'default value',
    },
  },

  data() {
    message: 'hello, world',
  },

  methods: {
    onClick() {}
  }
}
```

Vue2 使用 TypeScript 开发，原理就是这么简单。
