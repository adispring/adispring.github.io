---
title: 'Transducers Explained: Part 1 中文'
date: 2016-10-24 10:10:20
tags:
---

译者注：本文翻译自 Kevin Beaty 的《[Transducers Explained: Part 1](http://simplectic.com/blog/2014/transducers-explained-1/)》, 转载请与[原作者](https://github.com/kevinbeaty)或[本人](https://github.com/adispring)联系。 
对原文中出现的专业术语，在不妨碍理解的情况下采用原文单词。

Transduce 相较于 Reduce 的改进，用一句话概括：在使用 Reduce 对每个元素归并之前，先对取出的每个元素进行转换。

Transduce 的时间复杂度为 O(n), 传统 compose + reduce 的为O(mn)，m：compose 中包含 转变函数的个数，n：输入“数组”的长度。

名词解释：

* reduce：归并、折叠。
* reducer：用来进行 reduce 的二元函数。
* result：reducer 的首个参数，累积值。
* item：reducer 的第二个参数，reduce 数组遍历过程中的当前元素。


* transduce：transform + reduce。
* transducer：传入一个transformer，返回一个新的transformer。
* transformer：在 reduce 过程中，对当前处理元素进行转换的对象，其中包含三个方法： `{ init, step, result }`
* xf：reduce 函数的首个参数，可以是 *reducer*，也可以是 transformer。
* stepper：等同于 reducer。

下面开始正文。

---

本文使用 JavaScript 对 transducers 原理进行剖析。首先介绍数组的 reducing(归并) 过程，并定义用于 数据转换 的 transformers；然后逐步引入 transducers，并将其用于 transduce 中。文末会有总结、展望、一些补充链接，以及当前涉及 transducer 的一些库。

**Transducers...**


## 什么是 Transducers ？

[原文](http://clojure.org/reference/transducers)解释如下

> Transducers 是可组合的算法变换。它们独立于输入和输出的上下文，并且作为一个独立的单元提供最基本的 转换(transformation)。由于 transducers 与输入和输出相解耦，所以它们可以用于许多不同的处理场景：collections, streams, channels, observables（集合、流、管道、观察者模式）等。Transducers 可以直接组合，与输入无关,且不会产生额外的中间变量。

**嗯...**

## 还是不太理解

我们来找一些相关的代码看看。当使用 transducers 时，所谓的 "算法变换" 就已经以函数的形式被定义好了（或至少部分定义好了）, transducer 类似于传入 reduce 的 `reducer`。[Clojure 文档](http://clojure.org/reference/transducers) 将这些 "算法变换" 称为 *reducing function*。这又是什么东西？好吧…… ，让我们从 `Array#reduce` 函数开始讲解。首先来看看 [MDN 的定义](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Array/reduce)。 

## Reduce

> reduce() 方法将一个二元函数，作用于一个累积值、以及数组中的每个元素（按从左到右的顺序）， 最终将数组 reduce（归并、折叠）成一个单值。

更多解释可以参考 [MDN 文档](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Array/reduce)（译者注：reduce 在某些语言中称为 foldl 左折叠，如 Haskell）。由于大家可能对 reduce 已经比较熟悉，这里将举几个例子来快速说明一下。

```js
const sum = (result, item) => result + item;

const mult = (result, item) => result * item;

// 10 (=1+2+3+4)
const summed = [2,3,4].reduce(sum, 1);

// 24 (=1*2*3*4)
const multed = [2,3,4].reduce(mult, 1);
```

上述代码中的 *reducer*s 是 `sum` 和 `mult`。*reducer*s 连同初始值：1，一起传入 `reduce` 中。“输入源” 是数组 [2, 3, 4]，“输出源” 是通过 reduce 内部实现创建的新数组。

关于 `reduce`， 有几个非常重要的点需要注意：

1. 归并从输入的初始值开始。
2. *reducer* 一次处理一个元素，操作过程如下：
    * 使用传入 `reduce` 的初始值作为第一步的累积值
    * 当次操作的返回值作为下次操作的累积值
3. 将最后一次计算结果作为整体的返回值。

注意，在上述两例中，*reducer* 是一个二元函数。第一个参数为累积值，其值为由外部传入的初始值，或上次 *reducer* 的计算结果；第二个参数是在迭代过程中传入的单个元素。在本例中，reduce 对数组中的每个元素进行迭代，并进行归并处理。我们稍后会看到其他的迭代方式。我们使用 *reducer* 函数来描述 “转换的本质”。

## Transformer

接下来，我们来明确 *transformer* 的归并过程：

```js
const createTransformer = reducer => ({
  // 1. 作为 reduce 的初始值
  init: () => 1,

  // 2. 每次输入一个元素，并将本次计算结果
  //    传给下次迭代的 reducer
  step: reducer,

  // 3. 将最后一次的计算结果作为最终输出
  result: result => result,
});
```

我们创建一个对象来封装 reducer，并将其命名为 `step`；该对象还包含另外两个函数：1. `init` 函数用于初始化 transformer，`result` 函数用于将最后一次计算结果转换为最终输出。注意，本文将只关注 `step` 函数，`init` 和 `result` 函数将在后续文章中做深入分析。现在，你可以把它们当作管理 “转换” 生命周期的方法：`init` 用于初始化，`step` 用于迭代，`result` 用于输出整个结果。

现在，我们来将刚定义的 transformer 运用到 reduce 中。

```js
const input = [2,3,4];

const xf = createTransformer(sum);
const output = input.reduce(xf.step, xf.init());
// output = 10 (=1+2+3+4)

const xf = createTransformer(mult);
const output = input.reduce(xf.step, xf.init());
// output = 24 (=1*2*3*4)
```

我们的最终目标是将 转换 与输入、输出解耦，所以我们将 `reduce` 定义为函数的形式。

```js
const reduce = (xf, init, input) => {
  let result = input.reduce(xf.step, init);
  return xf.result(result);
};
```

为了使用 reduce ，我们向 reduce 传入 transformer、初始值和输入源。上述实现结合了 transformer 的 `step` 函数和数组的 reduce 函数，并将 `step` 函数的结果作为输出。这里的 reduce 内部实现仍然假设输入类型为数组。 稍后将去掉这个假设。

我们显式地向 reduce 传入一个初始值，其实本可以使用 transformer 的 `init` 函数提供初始值，但考虑到 reduce 函数的灵活性，需要能够自定义初始值。在实践中，transformer 的 `init` 函数仅在 reduce 未提供初始值的情况下使用。

新 reduce 函数的使用类似于之前的 reduce 。

```js
const input = [2,3,4];
const xf = createTransformer(sum);
const output = reduce(xf, xf.init(), input);
// output = 10 (=1+2+3+4)

const input = [2,3,4];
const xf = createTransformer(mult);
const output = reduce(xf, xf.init(), input);
// output = 24 (=1*2*3*4)
```

若想要改变初始值，还可以显式地向 reduce 传入初始值。

```js
const input = [2,3,4];
const xf = createTransformer(sum);
const output = reduce(xf, 2, input);
// output = 11 (=2+2+3+4)

const input = [2,3,4];
const xf = createTransformer(mult);
const output = reduce(xf, 2, input);
// output = 48 (=2*2*3*4)
```

reduce 函数现在需要一个 transformer。由于 transformer 的 `init` 函数未在 reduce 内部用到，且 `result` 通常是个恒等函数：一个直接返回输入本身的函数，我们将定义一个辅助函数，先将 *reducer* 转换为 transformer，然后将 transformer 传入 reduce 使用。

```js
const reduce = (xf, init, input) => {
  if(typeof xf === 'function'){
    // 确保含有 transformer 
    xf = wrap(xf);
  }
  const result = input.reduce(xf.step, init);
  return xf.result(result);
}

const wrap = xf => ({
  // 1. 我们会显式的传入一个 reduce 的初始值，
  //    所以这里不再需要内部的 init 函数
  init: () => {
    throw new Error('init not supported');
  },

  // 2. 每次输入一个元素，并将本次计算结果
  //    传给下次迭代
  step: xf,

  // 3. 将最后一次的计算结果作为输出
  result: result => result,
}
```

首先我们检查参数 `xf` 的类型是否为 function。若是，我们假定它是一个 reducer (step) 函数, 并调用 `wrap` 函数将其转换为 transformer。然后像之前一样调用 reduce 。

现在已经可以直接向 reduce 传递 reducer 了。

```js
const input = [2,3,4];
const output = reduce(sum, 1, input);
// output = 10 (=1+2+3+4)

const input = [2,3,4];
const output = reduce(mult, 2, input);
// output = 48 (=2*2*3*4)
```

![reduce](./reduce.png)

但我们仍然可以向 reduce 传 transformers。

```js
const input = [2,3,4];
const xf = wrap(sum);
const output = reduce(xf, 2, input);
// output = 11 (=2+2+3+4)

const input = [2,3,4];
const xf = wrap(mult);
const output = reduce(xf, 1, input);
// output = 24 (=1*2*3*4)
```

注意，这里在外部使用 `wrap` 将已有的 `reducer` 转换为 transformer。这在使用 transducers 会经常碰到：开发者将转换定义为简单的函数，transducers 库会自动将将其转换为 transformer。

## 不一样的数组拷贝

目前，我们一直使用数字作为初始值和加法作为 *reducer* 。其实不一定非要这样，`reduce` 也可以将数组作为初始值。

```js
const append = (result, item) => result.push(item);

const input = [2,3,4];
const output = reduce(append, [], input);
// output = [2, 3, 4]
```

我们定义了一个步进函数（stepper/reducer）`append`，用于将每个元素拷贝到新数组中，并返回该数组。借助 `append`， reduce 便可以创建一份数组的拷贝。

上述操作是否够酷？或许算不上...。当你在将元素拷贝到数组前，先对它变换一下，情况开始变得有趣起来。

## 最孤单的数字

（注：One is the loneliest number，一句英文歌词，引出 `plus1` 转换）

假设我们想让每个元素加1，定义一个加1函数。

```js
const plus1 = item => item + 1;
```

使用上面的函数创建一个 transformer，在 transformer 的 `step` 中，会对每个元素进行转换。

```js
const xfplus1 = {
  init: () => { throw new Error('init not needed'); },

  step: (result, item) => {
    const plus1ed = plus1(item);
    return append(result, plus1ed);
  },
  // step: (result, item) => append(result, plus1(item)),
  
  result: result => result,
}
```

我们可以使用 transformer 逐步输出结果。

```js
const xf = xfplus1;
const init = [];
let result = xf.step(init, 2);
// [3] (=append([], 2+1)))

result = xf.step(result, 3);
// [3,4] (=append([3], 3+1)))

result = xf.step(result, 4);
// [3,4,5] (=append([3,4], 4+1)))

const output = xf.result(result);
// [3,4,5]
```

我们使用一个 transformer 来遍历元素：将每个元素加 1 后，添加到输出数组中。

如果想计算数组元素加 1  后的总和，该怎么办呢？可以使用 reduce 。

```js
const output = reduce(sum, 0, output);
// 12 (=0+3+4+5)
```

上述方案虽然可行，但不幸的是，我们在获得最终答案的过程中，不得不创建一个中间数组。有更好的方案吗？

答案是有的。再来看下上面的 `xfplus1` ，如果将 `append` 替换为 `sum` ，并且以 0 作为初始值，就可以定义一个直接对元素求和，但不会生成中间结果（数组）的 transformer。

但是，有时我们想立即查看替换 *reducer* 后的结果，因为涉及到的改变仅仅只是将 `append` 替换成了 `sum`。因此我们希望有一个能够创建 转换 的函数，该函数不依赖于用于组合结果的 transformer。

```js
const transducerPlus1 = (xf) => ({
  init: () => xf.init(),
  step: (result, item) => {
    const plus1ed = plus1(item);
    return xf.step(result, plus1ed);
  },
  result: result => xf.result(result),
});
```

该函数接受一个 transformer：`xf`，返回一个基于 `xf` 的新 transformer。新 transformer 将经过 `plus1` 转换的值传给 `xf`，相当于对 `xf` 进行代理。由于使用 `step` 函数可以完全定义这个转换，所以新 transformer 可以复用旧 transformer -- `xf` 的 `init` 和 `result` 函数。新 transformer 每次对元素进行 `plus1` 转换后，利用转换的值对封装的 transformer 的 `step` 函数进行调用。

## Transducer

我们刚刚创建了第一个 transducer：一个接受已有 transformer，返回新 transformer 的函数。transducer 会将一些额外的处理行为委托给新 transformer。

我们来尝试一下，使用刚才的 transducer 来重新实现前面的例子。

```js
const stepper = wrap(append);
const init = [];
const transducer = transducerPlus1;
const xf = transducer(stepper);
let result = xf.step(init, 2);
// [3] (=append([], 2+1)))

result = xf.step(result, 3);
// [3,4] (=append([3], 3+1)))

result = xf.step(result, 4);
// [3,4,5] (=append([3,4], 4+1)))

const output = xf.result(result);
// [3,4,5]
```

运行过程和结果与之前相同，很好。唯一的区别是 transformer：`xf` 的创建。我们使用 `wrap` 将 `append` 转换成名为 `stepper` 的 transformer，然后使用 transducer 封装这个 stepper 并返回一个 `plus1` 转换。然后我们就可以像从前一样使用转换函数：xf 对每个元素逐步操作，并得到结果。

## 中间辅助元素

从现在开始，事情变得有趣起来：我们可以用同一 transducer，仅在改变 stepper 和初始值的情况下，获得最终的累加和，而不需要中间辅助数组。

```js
const stepper = wrap(sum);
const init = 0;
const transducer = transducerPlus1;
const xf = transducer(stepper);
let result = xf.step(init, 2);
// 3 (=sum(0, 2+1)))

result = xf.step(result, 3);
// 7 (=sum(3, 3+1)))

result = xf.step(result, 4);
// 12 (=sum(7, 4+1)))

const output = xf.result(result);
// 12
```

不需要计算中间数组，一次遍历即可得到结果。`sum` 与 `append` 例子只有两处不同：

* 创建 stepper 时，用 sum 代替 append 进行封装。
* 初始值使用 0 代替 []。

仅此两处差异，其他完全一样。

需要注意的是，只有 `stepper` 转换知道 `result` 的数据类型。当封装 `sum` 时，`result` 的类型为数字，封装 `append` 时，`result` 的类型是数组。初始值类型与 stepper 的 `result` 参数类型相同。每次迭代元素的类型不限，因为 `stepper` 知道如何组合上次输出的结果和当前的元素，并返回一个新的组合的结果；本次输出结果可能会用于下次迭代中的组合，如此迭代循环。

这些特性允许我们定义独立于输出的转换。

## 可能会变糟

(注：第二句歌词，Can be as bad as one，作者意思应该是，如果 `plus2` 还跟 `plus1` 一样从头重新实现一遍，就比较坑了)

假如我们想要在归并之前 `plus2`，需要改变哪些地方呢？我们可以定义一个类似于 `transducerPlus1` 的新的 `transducerPlus2` 。回头看一下 `transducerPlus1` 是如何实现的，并决定哪些地方需要更改。但这样做违反了 DRY 原则。

有更好的方案吗？

实际上，除了将 step 的值用 `plus2` 替换掉 `plus1` 以外，其他都是一样的。

让我们将 `plus1` 提取出来，并将其作为函数 `f` 进行传递。

```js
const map = f => xf => ({
  init: () => xf.init(),
  step: (result, item) => {
    const mapped = f(item);
    return xf.step(result, mapped);
  },
  result: result => xf.result(result),
});
```

我们定义了 mapping transducer，让我们使用它来逐步转换。

```js
const plus2 = (input) => input + 2;
const transducer = map(plus2);
const stepper = wrap(append);
const xf = transducer(stepper);
const init = [];
let result = xf.step(init, 2);
// [4] (=append([], 2+2)))

result = xf.step(result, 3);
// [4,5] (=append([4], 3+2)))

result = xf.step(result, 4);
// [4,5,6] (=append([4,5], 4+1)))

const output = xf.result(result);
// [4,5,6]
```

本例相较于之前使用`plus1` 和 `append` 函数的例子，唯一的区别在于使用 `map` 创建 transducer。我们可以类似地使用 `map(plus1)` 来创建 `plus1` transducer。`transducerPlus1` 虽然只是短暂的出现便被 `map(plus1)` 代替，但它对我们理解 transduce 的内部原理帮助很大。

## Transduce

前面的示例讲解了使用 transducers 手动转换一系列的输入。让我们进一步优化。

首先通过调用一个包含 stepper 转换的 transducer 来初始化 transformation，并定义 transduce 的初始值。

```js
const transducer = map(plus1);
const stepper = wrap(append);
const xf = transducer(stepper);
const init = [];
```

然后使用 *reducer* `xf.step` 来遍历每个输入元素。将初始值作为 step 函数的第一个 `result` 参数（另一个是输入源中的元素），上一个 step 函数的返回值供所有后续元素迭代使用。

```js
let result = xf.step(init, 2);
// [3] (=append([], 2+1)))

result = xf.step(result, 3);
// [3,4] (=append([3], 3+1)))

result = xf.step(result, 4);
// [3,4,5] (=append([3,4], 4+1)))
```

我们使用 `xf.result` 输出最终结果。

```js
const output = xf.result(result);
// [3,4,5]
```

可能你已经注意到了，这与上面定义的 `reduce` 实现非常相似。 事实也是如此。 我们可以将这个过程封装成一个新的函数 `transduce`。

```js
const transduce = (transducer, stepper, init, input) => {
  if(typeof stepper === 'function'){
    // 确保存在用于步进（迭代）的 transformer
    stepper = wrap(stepper);
  }

  // 传入 stepper 来创建 transformer：xf
  const xf = transducer(stepper);
  // xf 现在成为一个 transformer
  // 现在可以使用上面定义的 reduce 来迭代并
  // （在迭代之前）变换输入元素
  return reduce(xf, init, input);
};
```

就像 reduce，我们需要确保 stepper 是一个 transformer。然后通过向 transducer 传入 stepper 来创建新的 transformer。 最后，我们使用包含新的 transformer 的 reduce 来进行迭代和转换结果。也就是说 transducer 的函数类型为：transformer -> transformer。

我们来实践一下。

```js
const transducer = map(plus1);
const stepper = append;
const init = [];
const input = [2,3,4];
const output = transduce(transducer, stepper, init, input);
// [3,4,5]

const transducer = map(plus2);
const stepper = append;
const init = [];
const input = [2,3,4];
const output = transduce(transducer, stepper, init, input);
// [4,5,6]
```

上述两例的唯一区别是传递给 map 的函数不同。

我们来尝试一下不同的 step function 和初始值。

```js
const transducer = map(plus1);
const stepper = sum;
const init = 0;
const input = [2,3,4];
const output = transduce(transducer, stepper, init, input);
// 12 (=3+4+5)

const transducer = map(plus2);
const stepper = sum;
const init = 0;
const input = [2,3,4];
const output = transduce(transducer, stepper, init, input);
// 15 (=4+5+6)

const transducer = map(plus1);
const stepper = mult;
const init = 1;
const input = [2,3,4];
const output = transduce(transducer, stepper, init, input);
// 60 (=3*4*5)

const transducer = map(plus2);
const stepper = mult;
const init = 1;
const input = [2,3,4];
const output = transduce(transducer, stepper, init, input);
// 120 (=4*5*6)
```

![transduce](./transduce.png)

这里我们只是改变了 stepper 和初始值，便可以得到不同的结果。我们可以在不依赖中间变量的情况下，遍历一次便可求得累加和或乘积。

## 组合

如果我们想加3，改怎么办呢？我们可以定义 `plus3` 并且使用 `map`，但更好的方法是利用 transducers 的一个特性。

事实上，我们可以通过其他两个函数：`plus1` 和 `plus2`，来定义 `plus3`。

```js
const plus3 = item => puls2(plus1(item));
```

或许你已经看出来，其实这就是[函数组合](https://en.wikipedia.org/wiki/Function_composition_%28computer_science%29)。让我们通过函数组合来重新定义 `plus3`。

```js
const compose2 = (fn1, fn2) => item => fn1(fn2(item));

const plus3 = compose2(plus1, plus2);

const output = [plus3(2), plus3(3), plus3(4)];
// [5,6,7]
```

`compose2` 用于组合两个函数，调用顺序从右向左，看一下 `compose2` 的实现就可以知道为什么调用顺序是从右向左的了。最后一个 function 接受传入参数，返回结果作为下个 function 的输入。如此迭代，直到输出结果。

让我们使用 `compose2` 来定义一个 transducer，该 transducer 由 `plus1` 和 `plus2` 组合而成，用于将每个迭代的元素加3。

```js
const transducerPlus3 = map(compose2(plus1, plus2));
const transducer = transducerPlus3;
const stepper = append;
const init = [];
const input = [2,3,4];
const output = transduce(transducer, stepper, init, input);
// [5,6,7]
```

我们使用“函数组合”来组合 `plus1` 和 `plus2` 而不是重新定义 `plus3`，来组合出传入 map 的加3操作。

将上述这些的目的是什么呢？实际上，我们可以通过组合其他的 transducers 来创建新的 transducers。

```js
const transducerPlus1 = map(plus1);
const transducerPlus2 = map(plus2);
const transducerPlus3 = compose2(transducerPlus1, transducerPlus2);
const transducer = transducerPlus3;
const stepper = append;
const init = [];
const input = [2,3,4];
const output = transduce(transducer, stepper, init, input);
// [5,6,7]
```

新组合出来的 transducer 可以用于组合其他的 transducer 。

```js
const transducerPlus1 = map(plus1);
const transducerPlus2 = map(plus2);
const transducerPlus3 = compose2(transducerPlus1, transducerPlus2);
const transducerPlus4 = compose2(transducerPlus3, transducerPlus1);
const transducer = transducerPlus4;
const stepper = append;
const init = [];
const input = [2,3,4];
const output = transduce(transducer, stepper, init, input);
```
![compose_transducers](./compose_transducers.png)

再次注意，与本节前面的例子的唯一区别是 transducer 的创建。其它都没变。

组合之所以能工作，是因为 transducers 的定义：接受一个 transformer 并返回一个新的 transformer。也即 transducer 的输入与返回值类型相同，且为单输入单输出。只要符合上述条件，便可以使用函数组合来创建与“输入函数”相同类型的“新函数”。

由上可得，transducers 是一种 “可组合的算法变换”。这在实践中已经证明其强大之处：可以将新的变换定义为一系列较小变换的组合，然后将它们通过 `compose` 或 `pipe` 组合起来。我们将在后续章节中展示更多的例子。

事实上，虽然函数组合调用顺序为由右向左，而 transformation 调用是自左向右的（译者注：这也是理解 transduce 的难点之一，理解了这个，也就基本理解了 transduce。可以通过单个 transducer 和 transformer 的组合，来理解 transformation 的调用顺序。transduce 本质上做的事情是 **在对每个元素进行归并之前先对其进行变换** ，将这句话重复五遍：），这也是 transduce 区别于 reduce 的“唯一”不同点）。

在上面的 `transducersPlus4` 示例中，每个元素先进行 `plus3` 转换，然后进行 `plus1` 转换。

虽然在本例中 transducers 的调用顺序对结果没有影响，但是**从左向右**的变换顺序还是需要牢记在心。这个变换调用顺序让你在阅读代码时更容易理解，因为它与你的阅读顺序是一至的（如果使用的是英文，或者中文）。

## part 1 总结

Transducers 将 “可组合的算法转换” 抽象出来，使其独立于输入、输出，甚至迭代的整个过程。

本文演示了如何使用 transducers 来抽象算法转换，transducer 将一个 transformer 转换为另一个 transformer。transformer 可以用于 transduce 进行迭代和转换输入源。

相较于 [Underscore.js](http://underscorejs.org/) 或 [Lo-Dash](https://lodash.com/)对数组和计算中间结果的对象进行操作，transducers 定义的 transformation 在函数方面类似于传递给 reduce 的 stepping function：将初始值作为首次迭代的“结果参数”，执行输入为一个“结果参数”和元素的函数，返回可能变换过的结果，并将其作为下次迭代的“结果参数”。一旦将 transformation 从数据中抽象出来，就可以将相同的 transformations 应用于以某初始值开始并遍历某个“累积结果”的不同处理过程。

我们已经展示了相同的 transducers 可以操作不同的“输出源”，只需改变创建 transducer 时用到的初始值和 stepper。这种抽象的好处之一是：可以遍历一次得到结果，且没有中间数组产生。

尽管没有明确说明，我们还是展示了 transducers 将 transducer 与 迭代过程及输入源解耦。在迭代过程中，我们使用相同的 transducer 对元素进行转换，并将转换结果传给 step function，我们使用数组的 reduce 从数组中获取数据。

## 还想了解更多！

[看这里](http://simplectic.com/blog/2014/transducers-explained-pipelines/) ,以后的文章中将会进一步讨论 transducers 并不会每步都输出元素；并且可能会提前终止迭代，并返回终止前已经归并的结果。本文只讨论了 step，未讨论 init 和 result，将来会有补充。

我们将会了解到，输入源可以是任意产生一系列值的东西：惰性列表，不确定的序列生成器，CSP（通信顺序进程），[Node.js streams](https://github.com/transduce/transduce-stream)
lazy lists, indefinite sequence generation, CSP[http://phuu.net/2014/08/31/csp-and-transducers.html), [push streams][12], [Node.js streams](https://github.com/transduce/transduce-stream), iterators, generators, immutable-js data structures, 等等。

## 等不及了！

在此期间，可以查看 [Clojure文档](http://clojure.org/transducers), 或者观看[视频](https://www.youtube.com/watch?v=6mTbuzafcII)或这篇[文章](http://phuu.net/2014/08/31/csp-and-transducers.html)，还有其他更多更好的介绍，可以自行 Google 。

想要立刻实践一下？已经有三个库实现了相似的API：[transducers-js](https://github.com/cognitect-labs/transducers-js)、[transducers.js](https://github.com/jlongster/transducers.js)、[ramda](https://github.com/ramda/ramda/blob/v0.22.1/src/transduce.js)(译者注：ramda 中 transducer 部分也是本文作者写的）。本文介绍与 transducers-js 实现类似，但概念同样适用于 transducers.js。

[Underscore.js](http://underscorejs.org/) 的粉丝？可以查看 [underarm](http://simplectic.com/projects/underarm/)，基于 [transduce](https://github.com/transduce/transduce) 库（译者注：本文作者写的库）写的。

怎样将 transducer 应用到 [Node.js streams](https://github.com/transduce/transduce-stream) 中呢？我们还在探索。

希望得到新文章的通知？可以在 Twitter 上关注 [simplectic](https://twitter.com/simplectic)。

