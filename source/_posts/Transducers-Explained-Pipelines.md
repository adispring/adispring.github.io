---
title: 'Transducers Explained: Pipelines 中文'
date: 2016-11-01 23:25:55
tags:
---

本文是 Transducer Explained 教程的第二篇。在[第一篇](https://adispring.github.io/2016/10/24/Transducers-Explained-Part-1/)中，从 *reducer* 开始讲起，到 *transformers*，再到在 `transduce` 中使用 `map` *transducers*。本文将介绍四个新的 *transducers*：`filter`、`remove`、`drop` 和 `take`。我们将展示如何将 *transducers* 组合成 流（*pipeline*s），并讨论转换的顺序。我们还将改变 `reduce` 的实现，使其能够借助 `reduced` 提前终止迭代操作。

那么，上次讲到哪了呢？

## Transformer

在[第一篇](https://adispring.github.io/2016/10/24/Transducers-Explained-Part-1/)文章中，通过定义 *transformer* 协议来规范了 `reduce` 的步骤。

所有 transformers 都包含3个方法：

1. 使用初始值初始化初始化转换，`init`
2. 使用 *reducer* 来组合每个元素，`step`
3. 将最后累积值转换为输出，`result`

在第一篇文章中，我们使用下面的 *reducer* 来转换输入源: `mult`、`add` 和 `append`。

```js
const append = (value, item) => {
  value.push(item);
  return value;
};
```

本文只会用到 `append`，将元素拼接到数组的尾部。

## Reduce

我们定义了自己的 `reduce` 实现，它接受以下参数：

1. 一个 transformer 或者将被封装成 transformer 的 *reducer*
2. 一个初始值（例如`[]`)。
3. 一个输入源（例如一个将要被归并的数组）

目前的实现使用 transformer 的 `step` 函数作为对原生数组进行归并的 *reducer*，我们稍后将修改这一实现。

在迭代过程中，`step` 函数接受两个参数：`result` 和 `item`。初始的 `result` 值 由调用者提供，后续的每个 `result` 使用当前 `step` 函数的返回值。

`item` 由迭代过程内部提供。在第一篇文章中展示了两个过程：1. 归并数组的每个元素; 2. 手动调用 `step` 函数处理每个元素。（在后续文章中将看到更多例子）。

## Transducer

我们创建了 mapping *transducer*。

```js
const map = f => xf => ({
  init: () => xf.init(),
  step: (result, item) => xf.step(result, f(item)),
  result: result => xf.result(result),
});
```

`map` transducer 接受一个映射函数：`f`，并返回一个真正的 transducer：

1. 接受一个已有 transformer
2. 返回一个新的 transformer，用来通过 `f` 转换 `items`
3. 对封装的 transformer 进行代理，添加一些额外的处理过程（如添加映射操作）

函数 `f`，可以是对数据进行映射（转换）的任意函数。

```js
const plus1 = input => input + 1;

const plus2 = input => input + 2;
```

在本文的例子中将继续使用这两个简单的映射函数。

## Transduce

我们定义了一个新函数，`transduce`, 其接受：

1. 一个 transducer: 定义转换的过程
2. 一个 stepper（reducer）函数，或 transformer (如 `append`)
3. 一个 stepper 函数 的初始值 (如 `[]`)
4. 输入源 (如一个待转换的数组)

通过 transducer 和 `stepper`（reducer） 函数，可以创建一个 transformer, 然后将该 transformer、初始值和输入源一同传入 `reduce`。

我们已经展示过，同一 transducer 可以生成不同的结果，只要改变传入 `transduce` 的初始值和 `stepper` 函数。

## Composition

最后，我们展示了可以通过组合已有 transducers 来创建新的 transducers

```js
const compose2 = (fn1, fn2) => item => fn1(fn2(item));

const transducer = compose2(
      compose2(map(plus1), map(plus2)),
      map(plus1));
const stepper = append;
const init = [];
const input = [2,3,4];
const output = transduce(transducer, stepper, init, input);
// [6,7,8]
```

被组合的 transducer 从左向右对输入源进行转换。

本文从这里开始讲起。如果对上面这个例子不太熟悉，可以参考[第一篇文章的讲解](https://adispring.github.io/2016/10/24/Transducers-Explained-Part-1/)

## Pipelines (流水线)

首先，定义一个新的函数，用它可以组合任意数量的函数。

```js
const compose = (...fns) => xf => {
  let i = fns.length - 1;
  for(; i >=0; i--) { xf = fns[i](xf); }
  return xf;
};
```

`compose` 是对 `compose2` 的扩展。`compose` 从右向左进行函数组合：组合出来的函数调用时，右侧函数的返回值，作为左侧函数的输入，不断重复该过程，知道最后一个函数的输出，作为整个函数的结果输出。

可以通过组合 `plus1` 和 `plus2` 来创建 `plus4`。

```js
// 手动调用 
const value = plus1(plus1(plus2(5)));
// 9

// 使用组合函数 (允许函数复用)
const plus4 = compose(plus1, plus1, plus2);
const value = plus4(5);
// 9
```

我们来通过组合 `map` transducers 来创建一个 `plus5` transducer。

```js
const transducer = compose(
  map(plus1),  // [3,4,5]
  map(plus2),  // [5,6,7]
  map(plus1),  // [6,7,8]
  map(plus1)); // [7,8,9]
const stepper = append;
const init = [];
const input = [2,3,4];
const output = transduce(transducer, stepper, init, input);
// [7,8,9]
```

每个 transducer 旁边的注释将每个转换通过数组展示出来，这样每次可以完整的查看整个转换。

然而，需要注意的是，在整个转换过程中，transducers 每次只顺序转换一个 item，并且不会产生中间结果。注释仅仅表示 pipeline 的每步的转换结果。我们将在下面继续讨论这个问题。

实际上，虽然组合是从右向左，转换的顺序实际上是从左向右的（在示例中是从上向下）。（需要将 transducers 的组合顺序 和 组合后 transducers 对输入源的转换顺序区分开)。在本例中顺序并不重要，但下一个例子中，便需要考虑调用顺序了。

## Filter

我们来定义 `filter` transducer

```js
const filter = predicate => xf => ({
  init: () => xf.init(),
  step: (value, item) => {
    const allow = predicate(item);
    if(allow){
      value = xf.step(value, item);
    }
    return value;
  },
  result: (value) => xf.result(value),
};
```

注意，通过 `filter` 创建的 transformer，只有在判断函数 `predicate` 返回 真值 时，才会调用给下一个 transformer。当 `predicate` 返回 false 时，当前元素会被忽略，并返回上次的迭代结果。

我们创建一个 transducer ，来过滤出所有奇数。

```js
const isOdd = num => num % 2 === 1;

const transducer = filter(isOdd);
const stepper = append;
const init = [];
const input = [1,2,3,4,5];
const output = transduce(transducer, stepper, init, input);
// [1,3,5]
```

我们使用 `isOdd` 的判断函数，来创建一个过滤元素的 transducer。然后使用 `transduce` 将其作用于一个整数数组，输出数组中只包含奇数。

我们再创建一个函数，该函数调用后，返回一个检查当前输入值是否等于之前输入值的判断函数。

```js
// another predicate 
const isEqual = y => x => x === y;

const transducer = filter(isEqual(2));
const stepper = append;
const init = [];
const input = [1,2,3,4,5];
const output = transduce(transducer, stepper, init, input);
// [2]
```

可以看到，创建出来的判断函数 `isEqual(2)` 只允许输出数组中包含数字 2。

再来一个辅助函数，其接受一个判断函数，对其结果取反。

```js
const not = predicate => x => !predicate(x);

const transducer = filter(not(isEqual(2)));
const stepper = append;
const init = [];
const input = [1,2,3,4,5];
const output = transduce(transducer, stepper, init, input);
// [1,3,4,5]
```

我们修改了前面的例子：对判断函数 `isEqual(2)` 取反，由此创建了一个移除输入源中所有数字 2 的 transducer。

现在在我们的 pipeline 库中添加了另一件武器（`filter`），一起来玩一下吧。

## Pipeline 顺序

我们来对每个元素加 1，然后过滤出奇数。

```js
const transducer = compose(
  map(plus1),         // [2,3,4,5,6]
  filter(isOdd));     // [3,5]
const stepper = append;
const init = [];
const input = [1,2,3,4,5];
const output = transduce(transducer, stepper, init, input);
// [3,5]
```

首先调用 `map(plus1)` transducer 对每个元素加 1，然后调用下一步转换：过滤出所有奇数。

我们改变一下 transducers 的顺序，看看会发生什么。

```js
const transducer = compose(
      filter(isOdd),      // [1,3,5]
      map(plus1));        // [2,4,6]
const stepper = append;
const init = [];
const input = [1,2,3,4,5];
const output = transduce(transducer, stepper, init, input);
// [2,4,6]
```

我们首先过滤出所有奇数。`filter(isOdd)` transformer 只将奇数传给下一个 transformer。所有传到下一步的元素(奇数)会使用 `plus1` 进行映射。

这展示了 *组合 transducers* 的两个重要性质：

1. 虽然 transducers组合 是从右向左，但数据转换是从左向右。
2. 越早使用 transducers 减少 pipeline 中元素的数量，效率可能会越高。
 
注意到，在最后一个例子中，`map(plus1)` 仅仅使用所有元素的子集调用。同样的，并未创建中间数组，仅仅作为注释便于理解而已。

## Remove

准备好了吗？现在开始讲另一个 transducer。

```js
const remove = predicate => filter(not(predicate));
```

很简单吧。实际上，我们可以通过对 predicate 取反 和 复用 `filter` 来创建 `remove` transducer。

现在来实践一下。

```js
const transducer = compose(
  filter(isOdd),        // [1,3,5]
  map(plus1),           // [2,4,6] 
  remove(isEqual(4)));  // [2,6]
const stepper = append;
const init = [];
const input = [1,2,3,4,5];
const output = transduce(transducer, stepper, init, input);
// [2,6]
```

首先过滤出奇数，然后对每项加1，然后删除 `4`。

## Drop 

如果想在迭代开始时跳过前 `n` 个元素，该做么做呢？这正是 `drop` transducer 的作用。

```js
const drop = n => xf => {
  var left = n;
  return {
    init: () => xf.init(),
    step: function(value, item){
      if(left > 0){
        left--;
      } else {
        value = xf.step(value, item);
      }
      return value;
    },
    result: result => xf.result(result),
  }
}
```

可以这样使用 `drop`：

```js
var transducer = drop(2);
var stepper = append;
var init = [];
var input = [1,2,3,4,5];
var output = transduce(transducer, stepper, init, input);
// [3,4,5]
```

`drop` 接受丢弃元素的个数。这是第一个创建有状态变换的 transducer 的示例。每次调用 `drop` transducer 创建一个转换时，便会创建一个变量 `left`，用来指示当前还剩多少个元素需要被丢弃。`left` 被初始化为 `n`。

注意，我们使用一个无状态的 transducer 创建了一个有状态的 transformer。这是一个重要的区别。这意味着我们可以重用 `drop(2)` transducer 任意多次，而不必担心任何状态。状态是在 transformer 中创建的，而不是 transducer 中。

假如我们不想丢弃，而是获取前 `n` 个元素并丢弃剩余元素，该怎么办呢？为方便实现，假设 `n > 0`。

我们来尝试一下。

```js
const take = n => xf => {
  var left = n;
  return {
    init: () => xf.init(),
    step: function(value, item){
      value = xf.step(value, item);
      if(--left <= 0){
        // 如何停止???
      }
      return value;
    },
    result: result => xf.result(result),
  }
};
```

哦噢，麻烦来了。我们知道如何逐步处理每个元素，并且通过 transformer 的状态来保持剩余元素的计数。但是，如何停止对剩余元素的迭代呢？

为什么需要表明转换已经完成，不再接受任何额外元素呢？不仅因为继续接受元素是一种浪费，还因为无法保证迭代能够完成。有可能迭代是无限的。如果可以，我们当然想终止无限迭代。

那么如何表示提前终止呢？我们需要在看一下迭代的源代码：`transduce`。

## Reduce redux (终极 Reduce)

下面是来自[第一篇文章](https://adispring.github.io/2016/10/24/Transducers-Explained-Part-1/)中 `transduce` 和 `reduce` 的定义，：

```js
const transduce = (transducer, stepper, init, input) => {
  if(typeof stepper === 'function'){
    stepper = wrap(stepper);
  }

  var xf = transducer(stepper);
  return reduce(xf, init, input);
};

const reduce(xf, init, input) => {
  if(typeof xf === 'function'){
    xf = wrap(xf);
  }
  // 怎样才能结束呢?? 
  var value = input.reduce(xf.step, init); 
  return xf.result(value);
};

const wrap = stepper => ({
  init: () => throw new Error('init not supported'),
  step: stepper,
  result: value => value,
};
```

从上面的实现可知，我们正在使用原生数组 `reduce` 方法进行迭代，`reduce` 的 `reducer` 来自 transformer。后续文章中，我们将删除输入源是数组的假设，但现在还需继续使用该假设。我们来定义自己的 `arrayReduce` 实现。

```js
const reduce = (xf, init, input) => {
  if(typeof xf === 'function'){
    xf = wrap(xf);
  }

  return arrayReduce(xf, init, input);
};

const arrayReduce(xf, init, array) => {
  var value = init;
  var idx = 0;
  var length = array.length;
  for(; idx < length; idx++){
    value = xf.step(value, array[idx]);
    // We need to break here, but how do we know?
  }
  return xf.result(value);
};
```

`arrayReduce` 的实现接受一个 transformer 、一个初始值和输入数组。然后使用 `for` 循环遍历每个元素，并使用累加值 value 和数组元素来调用 transformer 的 `step` 函数。

我们需要一个方法来打破这个循环，打破循环需要依赖某些标记值。幸运的是，我们可以采用已有的 [transducer 协议](https://github.com/cognitect-labs/transducers-js#reduced)。

为了在调用 transformer 中的 `step` 之后发出提前终止信号，我们可以将 *reduced* 值封装在包含两个属性的对象中：

1. `value`: 存储实际要封装的值。
2. `__transducers_reduced__`: bool 类型值，为`true`时，表示该对象已经 reduced （归并过）了，迭代需要被终止。

实现如下：

```js
const reduced = value => ({
  value: value,
  __transducers_reduced__: true,
});
```

我们还将添加一个 predicate 判断函数来确定值是否是 reduced 。

```js
const iReduced = value => value && value.__transducers_reduced__;
```

此外，我还需要一个方法来提取，或 `deref`(解引用) reduced 的值。

现在我们可以调整一下 `arrayReduce` 的实现，来来处理提前终止的 reduced 的值。

```js
const arrayReduce => (xf, init, array) => {
  var value = init;
  var idx = 0;
  var length = array.length;
  for(; idx < length; idx++){
    value = xf.step(value, array[idx]);
    if(isReduced(value)){
      value = deref(value);
      break;
    }
  }
  return xf.result(value);
}
```

现在可以像以前一样对每个元素进行迭代，但每次调用 `step` 之后，会先检查是否当前值是否 reduced。如果是，则提取当前值并终止迭代。我们仍然对最终值调用 `result` 方法，不管它来自 reduced value 还是完整的迭代。

## Take 2

现在可以完成 `take` 的实现了：

```js
const take = n => xf => {
  var left = n;
  return {
    init: () => xf.init(),
    step: function(value, item){
      value = xf.step(value, item);
      if(--left <= 0){
        // 任务完成，发出 reduced 信号
        value = reduced(value);
      }
      return value;
    },
    result: value => xf.result(value),
  }
};
```

我们之前唯一缺失的是：当检测到转换完成后使用 `reduced` 对值进行封装。(现在已经补上了)

让我们看看它是否能工作：

```js
const transducer = take(3);
const stepper = append;
const init = [];
const input = [1,2,3,4,5];
const output = transduce(transducer, stepper, init, input);
// [1,2,3]
```

工作正常！

就像任何其他的 transducer，你可以将 `drop` 和 `take` 组合成一个 pipeline

```js
const transducer = compose(
  drop(1),    // [2,3,4,5]
  take(3),    // [2,3,4]
  drop(1));   // [3,4]
const stepper = append;
const init = [];
const input = [1,2,3,4,5];
const output = transduce(transducer, stepper, init, input);
// [3,4]
```

第一个 `drop` 跳过第一个元素，然后将剩余元素传给下一个 transformer。`take`  transformer 获取从第一个 `drop` 传过来的数组中的前三个元素，然后停止迭代。最后一个 `drop` 删除从 `take` 传过来的数组中的首个元素，并且在终止之前逐一发送剩余的两个元素。

## 第二部分总结

我们首先总结了在第一篇文章中学到的内容，然后添加了 4 个新的 transducers：`filter`、`remove`、`take`、`drop`。我们通过组合 transducers 来创建 transformer pipelines，并看到数据变换的顺序是从左到右。

我们看到，除了在转换期间改变元素，transformer 还可以决定跳过任意元素，通过不调用下一个 transformer 的 `step` 来实现。每一个 transformer 的实现决定了什么会传递到下个 transformer。有些情况下， transformer 可能会发送多个值，例如 `cat` 或 [`transduce-string`](https://github.com/transduce/transduce-string)。

我们还看到了可以创建有状态变换的 transducer 的一些例子。状态由 transformer 管理，而不是 transducer。这允许无状态 transducer 的重用，即时它们创建的 transformers 管理状态。

当实现 `take` 时，我们意识到需要添加一个用于提前终止迭代的方法。我们改变了 `reduce` 的实现来处理和解包 reduced 的值，并且实现 `take` 用于在取完数据时，终止迭代。

## 还有别的吗？

在入门教程的最后一篇文章中还有一些需要解释的相关问题。我们仍未解释 transformer 的 `init` 和 `reduce` 的作用。我们将添加 `into` 并一般化 `reduce` 的实现来支持迭代器。

我们还看到输入元素可以是产生 sequence 值的任意东西：惰性列表、无限序列生成器、[CSP](http://phuu.net/2014/08/31/csp-and-transducers.html)、[Node.js streams](https://github.com/transduce/transduce-stream)、迭代器、生成器、immutable-js 数据结构等。

想要获取新文章的通知吗？可以关注 获取 [simplectic](https://twitter.com/simplectic) 的 Twitter。

## 我现在已经准备好了！

已经准备使用 transducers 了吗？如果通读了这篇文章，你应该已经具备良好的知识体系： [transducers-js](https://github.com/cognitect-labs/transducers-js) 和 [transducers.js](https://github.com/jlongster/transducers.js)。我们主要参考 transducers-js 的实现，但这些概念同样适用于 transducers.js。

如果你喜欢 [Underscore.js](http://underscorejs.org/)，可以查看 [underarm](http://simplectic.com/projects/underarm)。它是基于 [transduce](https://github.com/transduce/transduce) 的库，允许针对 transducers.js 和 transducer-js 支持的公共协议定义 API。

