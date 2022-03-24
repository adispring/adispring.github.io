---
title: Write Vue2 with TypeScript
date: 2022-03-24 15:28:37
tags:
---

## Vue 使用 TypeScript 开发原理简介

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

Vue2 使用 TypeScript 开发，原理就是这么简单。下面来详细讲一下 Vue2 使用 TypeScript 开发原理。

## Vue2 使用 TypeScript 开发详解

Vue2 使用 TypeScript 开发，依赖三个库：

* vue-property-decorator: 提供所有的装饰器；开发时会直接用到的库；依赖 vue-class-component 和 vue；
* vue-class-component: 提供 @Component 装饰器 和 基本的装饰器工厂函数 `createDecorator`；开发时不会直接用到；依赖 vue；vue-property-decorator 中暴露的 @Component，其实是 vue-class-component 提供的；vue-property-decorator 中其他的装饰器，都是由 `createDecorator` 创建的；
* vue: Vue 基础库，提供 Vue 的类型声明，vue-property-decorator 中暴露的 Vue，其实就是 vue 中的 Vue 类；

我们来具体看一下这三个库对外暴露的接口：

 vue-property-decorator:

```ts
import Vue from 'vue'
import Component, { mixins } from 'vue-class-component'

export { Component, Vue, mixins as Mixins }

export { Emit } from './decorators/Emit'
export { Prop } from './decorators/Prop'
export { Ref } from './decorators/Ref'
export { Watch } from './decorators/Watch'
// ...
```

vue-class-component

```ts
import Vue, { ComponentOptions } from 'vue'
import { VueClass } from './declarations'
import { componentFactory, $internalHooks } from './component'

export { createDecorator, VueDecorator, mixins } from './util'

function Component <V extends Vue>(options: ComponentOptions<V> & ThisType<V>): <VC extends VueClass<V>>(target: VC) => VC
function Component <VC extends VueClass<Vue>>(target: VC): VC
function Component (options: ComponentOptions<Vue> | VueClass<Vue>): any {
  if (typeof options === 'function') {
    return componentFactory(options)
  }
  return function (Component: VueClass<Vue>) {
    return componentFactory(Component, options)
  }
}

Component.registerHooks = function registerHooks (keys: string[]): void {
  $internalHooks.push(...keys)
}

export default Component
```

vue

```ts
import { Vue } from "./vue";
import "./umd";

export default Vue;

export {
  CreateElement,
  VueConstructor
} from "./vue";

// ...
```

通过展示三个库对外暴露接口的 index.ts 文件，我们就可以很清晰看到它们暴露的内容，以及依赖关系。

我们再来看一下如何使用 装饰器、class 和 TypeScript 来写 Vue 组件：

```ts
import { Vue, Component, Prop } from 'vue-property-decorator'

@Component
export default class YourComponent extends Vue {
  @Prop({ default: 'default value' }) readonly title!: string

  message: string = 'hello, world';

  onClick(): void {}
}
```

`YourComponent extends Vue` 就可以继承 Vue 上面所有的属性和方法，方法包括实例方法和静态方法，YourComponent 可以直接通过 this 调用 Vue 上的实例方法，在开发时，编辑器也会自动提示。我们来看一下 Vue 的类型声明：

下面是 Vue 实例上的属性和方法的声明

```ts
export interface Vue {
  readonly $el: Element;
  readonly $options: ComponentOptions<Vue>;
  readonly $parent: Vue;
  readonly $root: Vue;
  readonly $children: Vue[];
  readonly $refs: { [key: string]: Vue | Element | (Vue | Element)[] | undefined };
  readonly $slots: { [key: string]: VNode[] | undefined };
  readonly $scopedSlots: { [key: string]: NormalizedScopedSlot | undefined };
  readonly $isServer: boolean;
  readonly $data: Record<string, any>;
  readonly $props: Record<string, any>;
  readonly $ssrContext: any;
  readonly $vnode: VNode;
  readonly $attrs: Record<string, string>;
  readonly $listeners: Record<string, Function | Function[]>;

  $mount(elementOrSelector?: Element | string, hydrating?: boolean): this;
  $forceUpdate(): void;
  $destroy(): void;
  $set: typeof Vue.set;
  $delete: typeof Vue.delete;
  $watch(
    expOrFn: string,
    callback: (this: this, n: any, o: any) => void,
    options?: WatchOptions
  ): (() => void);
  $watch<T>(
    expOrFn: (this: this) => T,
    callback: (this: this, n: T, o: T) => void,
    options?: WatchOptions
  ): (() => void);
  $on(event: string | string[], callback: Function): this;
  $once(event: string | string[], callback: Function): this;
  $off(event?: string | string[], callback?: Function): this;
  $emit(event: string, ...args: any[]): this;
  $nextTick(callback: (this: this) => void): void;
  $nextTick(): Promise<void>;
  $createElement: CreateElement;
}
```

下面是 Vue 的静态属性和静态方法，也即 Vue 构造函数上的属性和方法：

```ts
export interface VueConstructor<V extends Vue = Vue> {
  new <Data = object, Methods = object, Computed = object, PropNames extends string = never>(options?: ThisTypedComponentOptionsWithArrayProps<V, Data, Methods, Computed, PropNames>): CombinedVueInstance<V, Data, Methods, Computed, Record<PropNames, any>>;
  // ideally, the return type should just contain Props, not Record<keyof Props, any>. But TS requires to have Base constructors with the same return type.
  new <Data = object, Methods = object, Computed = object, Props = object>(options?: ThisTypedComponentOptionsWithRecordProps<V, Data, Methods, Computed, Props>): CombinedVueInstance<V, Data, Methods, Computed, Record<keyof Props, any>>;
  new (options?: ComponentOptions<V>): CombinedVueInstance<V, object, object, object, Record<keyof object, any>>;

  extend<Data, Methods, Computed, PropNames extends string = never>(options?: ThisTypedComponentOptionsWithArrayProps<V, Data, Methods, Computed, PropNames>): ExtendedVue<V, Data, Methods, Computed, Record<PropNames, any>>;
  extend<Data, Methods, Computed, Props>(options?: ThisTypedComponentOptionsWithRecordProps<V, Data, Methods, Computed, Props>): ExtendedVue<V, Data, Methods, Computed, Props>;
  extend<PropNames extends string = never>(definition: FunctionalComponentOptions<Record<PropNames, any>, PropNames[]>): ExtendedVue<V, {}, {}, {}, Record<PropNames, any>>;
  extend<Props>(definition: FunctionalComponentOptions<Props, RecordPropsDefinition<Props>>): ExtendedVue<V, {}, {}, {}, Props>;
  extend(options?: ComponentOptions<V>): ExtendedVue<V, {}, {}, {}, {}>;

  nextTick<T>(callback: (this: T) => void, context?: T): void;
  nextTick(): Promise<void>
  set<T>(object: object, key: string | number, value: T): T;
  set<T>(array: T[], key: number, value: T): T;
  delete(object: object, key: string | number): void;
  delete<T>(array: T[], key: number): void;

  directive(
    id: string,
    definition?: DirectiveOptions | DirectiveFunction
  ): DirectiveOptions;
  filter(id: string, definition?: Function): Function;

  component(id: string): VueConstructor;
  component<VC extends VueConstructor>(id: string, constructor: VC): VC;
  component<Data, Methods, Computed, Props>(id: string, definition: AsyncComponent<Data, Methods, Computed, Props>): ExtendedVue<V, Data, Methods, Computed, Props>;
  component<Data, Methods, Computed, PropNames extends string = never>(id: string, definition?: ThisTypedComponentOptionsWithArrayProps<V, Data, Methods, Computed, PropNames>): ExtendedVue<V, Data, Methods, Computed, Record<PropNames, any>>;
  component<Data, Methods, Computed, Props>(id: string, definition?: ThisTypedComponentOptionsWithRecordProps<V, Data, Methods, Computed, Props>): ExtendedVue<V, Data, Methods, Computed, Props>;
  component<PropNames extends string>(id: string, definition: FunctionalComponentOptions<Record<PropNames, any>, PropNames[]>): ExtendedVue<V, {}, {}, {}, Record<PropNames, any>>;
  component<Props>(id: string, definition: FunctionalComponentOptions<Props, RecordPropsDefinition<Props>>): ExtendedVue<V, {}, {}, {}, Props>;
  component(id: string, definition?: ComponentOptions<V>): ExtendedVue<V, {}, {}, {}, {}>;

  use<T>(plugin: PluginObject<T> | PluginFunction<T>, options?: T): VueConstructor<V>;
  use(plugin: PluginObject<any> | PluginFunction<any>, ...options: any[]): VueConstructor<V>;
  mixin(mixin: VueConstructor | ComponentOptions<Vue>): VueConstructor<V>;
  compile(template: string): {
    render(createElement: typeof Vue.prototype.$createElement): VNode;
    staticRenderFns: (() => VNode)[];
  };

  observable<T>(obj: T): T;

  util: {
    warn(msg: string, vm?: InstanceType<VueConstructor>): void;
  };

  config: VueConfiguration;
  version: string;
}
```

## 装饰器如何将 vue class 转换为 vue 配置对象

下面我们讲一下 vue 的装饰器是如何将 vue class 形式的组件，转换为 vue 引擎能识别的传统的配置对象的。

首先来讲一下装饰器的相关知识。

装饰器的定义如下：

> 装饰器是一种特殊类型的声明，它能够被附加到类声明，方法， 访问符，属性或参数上。 装饰器使用 @expression这种形式，expression求值后必须为一个函数，它会在运行时被调用，被装饰的声明信息做为参数传入。

* 装饰器修饰的对象：装饰器可以从整体上修饰类，也可以在局部修饰类中的各种类型的成员：方法， 访问符，属性或参数。总之装饰器是用来修饰类的。

* 装饰器的书写形式：@expression。expression 有两种书写形式：
  * 一种是直接写一个函数，如 `@Component`；
  * 另一种是写一个进行求值的函数，如 `@Component(options)`。

上面两种装饰器的书写，其实都是对 @ 后面的 expression 求值，返回求值的结果。只不过在 `@Component` 中，Component 求值之后还是它自身（这里需要好好理解一下）；在 `@Component(options)` 中，Component(options) 的求值结果，是 Component 调用 options 之后的函数返回值；

