---
title: Ramda 的哲学
date: 2017-12-16 21:39:27
tags: Ramda
---

# 目标

我们编写 Ramda 的目的是，用比原生 JavaScript 更好的方式进行编程。给定数据如下：

```js
// `projects` 是一个以下形式的对象类型的数组
//     {codename: 'atlas', due: '2013-09-30', budget: 300000, 
//      completed: '2013-10-15', cost: 325000},
//
// `assignments` 是将工程名映射到员工名的对象类型的数组，如下所示:
//     {codename: 'atlas', name: 'abby'},
//     {codename: 'atlas', name: 'greg'},
```

我们想按以下形式进行编程：

```js
var employeesByProjectName = R.pipe(
  R.propEq('codename'), 
  R.flip(R.filter)(assignments), 
  R.map(R.prop('name'))
);
var onTime = R.filter(proj => proj.completed <= proj.due);
var withinBudget = R.filter(proj => proj.cost <= proj.budget);
var topProjects = R.converge(R.intersection, [onTime, withinBudget]);
var bonusEligible = R.pipe(
  topProjects, 
  R.map(R.prop('codename')), 
  R.map(employeesByProjectName), 
  R.flatten, 
  R.uniq
);

console.log(bonusEligible(projects));
// Live version at https://codepen.io/adispring/pen/WdQjXL?editors=0012
// 译者注：原文用的 ramda@0.22.1 版本比较旧了，converge 第二个之后的函数未加中括号
//         本文采用 ramda@0.25.0
```

这段代码是一段 “函数式” 的 `pipeline`。它是由模块化、可组合的函数构建而成，这些函数拼接在一起形成长长的管道，然后我们可以从管道入口传入待处理的数据。上面的每个 var 变量声明都代表一个单输入单输出的函数。每个函数的输出结果在管道中继续传递下去。

这些函数对数据进行转换并将转换结果传给下一个函数。需要注意的是，这些函数都不会改变输入参数的值。

Ramda 的目标是让这种风格的编码在 JavaScript 中更容易些。这就是它的目的，我们的设计决策都是由这个目标驱动的。还有一个唯二值得关注的点：简洁（Simplicity）。我们追求的是简洁（Simple），而不是简单（容易，Easy）。如果你没有看过 Rich Hickey 的 "Simple Made Easy"，你应该花点时间看看。简洁，意味着不要将独立的功能点耦合或纠缠到一起。Ramda 努力坚持这个原则。（单一职责原则）

# 座右铭

Ramda 自认为是 "一个实用的 JavaScript 函数式编程库"。什么意思呢？

在本文接下来的部分，我们将这句话的解释分成几部分，并在下文中分别讨论每部分在 Ramda 中的含义。

# 为 JavaScript 编程人员而设计

## 有些惊讶？

Ramda 是为编程人员设计的库。它不是一个学术试验品。它是为一线人员构建系统而准备的，它必须能运行，并且是良好、高效地运行。

我们尽量描述清楚函数的作用，以确保不会因误解而发生意外。不过，我们做的一些事情可能会让很多学术同仁感到惊讶。但只要日常的（工业界）编程人员理解我们，我们就愿意冒这个风险。例如，Ramda 的 `is` 函数可以用来代替 `isArray`、`isNumber`、`isFunction` 等函数。Ramda 版本的类型判断函数接受一个构造函数和一个对象：

```js
is(Number, 42); //=> true
is(Function, 42); //=> false
is(Object, {}); //=> true
```

这也适用于自定义的构造函数。如果 `Square` 的原型链上包含 `Rectangle`，则可以这样做：

```js
is(Rectangle, new Square(4)); //=> true
```

但这也可能引起学术界同仁的疑惑：

```js
is(Object, 42); //=> false
```

现实世界的编程人员知道这是完全正确的。字符串、布尔值和数字是原生类型，但它们不是对象。然而学者们可能会坚持，认为包装过的 Number 类型继承自 Object，类比 Square/Rectangle ，也应该返回 true。当然，他们可以那么认为... 在他们自己的库里。这些函数对一线的编程人员才是最有用的。（译者注：Ramda 作者可能被学术界 Nerd 们的絮叨伤害过...）

## 命令式实现

我们并没有非得以函数式的方式实现 Ramda 的函数。许多我们提出的构造，像 folds、maps、filters 只能通过递归进行函数式实现。但由于 JavaScript 并没有对递归进行优化；我们不能用优雅的递归算法来编写这些函数。相反，我们诉诸于丑陋的、命令式的 while 循环。我们来编写令人讨厌的代码，以便（Ramda）用户可以编写更优雅的代码。Ramda 的实现绝不应该被认为是如何编写函数式代码的指导。（译者注：为了效率和实用性的考虑，Ramda 底层实现其实是命令式的）

虽然我们从 Haskell、ML 和 LISP（及其变种的函数式部分）等函数式语言中获得很多灵感，但 Ramda 从不试图实现这些语言的任何部分。

Ramda 也没有试图简单地以函数式的方式重写原生 API。机械的生搬硬套没有任何意义。当我们实现 `map` 函数时，我们既不用非得遵循 Array.prototype.map 的 ECMAScript 规范，也没有囿于已有的实现。我们可以自由地为我们的库定义每个函数的功能，它是如何工作的，确切的参数顺序，它会不会更改输入参数等（永远不会！），返回什么，以及它会抛出什么类型的错误等。换句话说，API 是我们自己的。我们确实受到了函数式编程的传统的限制，但如果在 JavaScript 中使用某些东西需要做出妥协，我们可以做出任何被认为实用的选择。（译者注：总之，我们对 Ramda 有绝对的掌控权）

# 作为一个库

Ramda 是一个库，一个工具包，或者类比 Underscore ，是一个辅助开发工具。它不是一个决定如何构建应用程序结构的框架（如 React）。相反，它只是一组函数，旨在使之前描述的可组合函数风格的编程更容易一些。这些函数并没有决定你的工作流程。例如，你不必为了使用过滤器而传递 `where` 函数的结果。

## 为什么不使用...

Ramda 不可避免的会与 [Underscore](http://underscorejs.org/) 和 [Lodash](http://lodash.com/) 做对比；其所提供的函数在功能和函数名称会有重叠。但是，Ramda 不会成为这些库的替代品。即使有一个神奇的参数顺序调整机制，它仍然不是一个简单的替代品。Ramda 有自身的优势、专注于不同领域。请记住，如果这些库能够很容易地按我们想要的方式进行编程，那么就不需要 Ramda 了。

当我们开始编写该库时，主要的函数式编程库有：

* Oliver Steele 的 [Functional Javascript](http://osteele.com/sources/javascript/functional/), 这是首次使用令人难以置信的方式，展示真的可以在 JavaScript 中用函数式的方式编程。但它也只是个玩具，用生产环境中不想要的技巧进行Hack。

* Reg Braithwaite 的 [allong.es](https://github.com/raganwald/allong.es)，这本书已经出来了，并且这个鲜为人知的库已经可以用了。但这个库自称是 Underscore 或 Lodash 的伴侣，虽然做得很好，但它似乎只是一个支持这本书的最小代码集合，而不是一个完整的库。

* Michael Fogus 的 [Lemonad](https://github.com/fogus/lemonad) 是一个具有前瞻性的实验品，也许是这里面最有趣的一个，它的一些函数在其他 JavaScript 库中是没有的。但它似乎只是一个 playground，基于此，该库基本上被废弃了。

* 当然还有一些大块头，比如 Jeremy Ashkenas 的 [Underscore](http://underscorejs.org/) 和 John-David Dalton 的 [Lodash](http://lodash.com/)。这些库的广泛使用，显示了大量的 JavaScript 开发人员不再害怕函数式构造。它们非常受欢迎，已经包含了许多我们想要的工具。

那么为什么我们不使用 Underscore/Lodash 呢？答案很简单。对于我们想要的编程形式，它们犯了一些根本性的错误：它们传递参数的顺序是错误的。

这听起来很可笑，甚至无足轻重，但是对于这种编程风格来说确实 **必不可少**。为了构建简单可组合的函数，我们需要能正确协同工作的工具。其中最重要的是自动柯里化。为了能正确地进行柯里化，我们必须确保最经常变化的参数 -- 通常是数据 -- 放到最后。

差别很简单。假设我们有这样一个可用的函数：

```js
var add = function(a, b) {return a + b;};
```

并且我们想要一个函数，可以计算一篮子水果的总价格，例如：

```js
var basket = [
    {item: 'apples',  per: .95, count: 3, cost: 2.85},
    {item: 'peaches', per: .80, count: 2, cost: 1.60},
    {item: 'plums',   per: .55, count: 4, cost: 2.20}
];
```

我们想要这样写：

```js
var sum = reduce(add, 0);
```

并且这样使用：

```js
var totalCost = compose(sum, pluck('cost'));
```

这就是我们想要的效果。注意看 `sum` 和 `totalCost` 是如此的简洁。使用 Underscore 写一个计算总价的函数并不难，但不会如此简洁。

```js
var sum = function(list) {
    return _.reduce(list, add, 0);
};
var totalCost = function(basket) {
    return sum(_.pluck(basket, 'cost'));
};
```

在 Lodash 中可能的实现如下：

```js
var sum = function(list) {
    return _.reduce(list, add, 0);
};
var getCosts = _.partialRight(_.pluck, 'cost');
var totalCost = _.compose(sum, getCosts);
```

或者跳过中间变量：

```js
var sum = function(list) {
    return _.reduce(list, add, 0);
};
var totalCost = _.compose(sum, .partialRight(_.pluck, 'cost'));
```

虽然这已经非常接近我们想要的效果，但是跟 Ramda 版本的相比，还是有差距的：

```js
var sum = R.reduce(add, 0);
var total = R.compose(sum, R.pluck('cost'));
```

在 Ramda 中实现这种风格的秘诀非常简单：我们将函数参数放在第一位，数据参数放到最后，并且将每个函数都柯里化。

来看一下 `pluck`。Ramda 有一个 `pluck` 函数，它和 Underscore 及 Lodash 中的 `pluck` 函数的功能差不多。这些函数接受一个字符串属性名和一个列表；返回由列表元素的属性值组成的列表。但 Underscore 和 Lodash 要求先提供列表，Ramda 希望最后传入列表。当你加入柯里化时，区别非常明显：

```js
R.pluck('cost'); //=> function :: [Object] -> [costs]
```

通过简单地暂时不传列表参数给 `pluck`，我们得到一个新函数：接受一个列表，并从新提供的列表中提取 `cost` 属性值。

重申一下，就是这个简单的区别，将数据参数放到最后的自动柯里化函数让这两种风格变得不同：

```js
var sum = function(list) {
    return _.reduce(list, add, 0);
};
var total = function(basket) {
    return sum(_.pluck(basket, 'cost'));
};
```

```js
var sum = R.reduce(add, 0);
var total = R.compose(sum, R.pluck('cost'));
```

这就是我们开始编写一个新库的原因。

# 设计选择

接下来的问题是我们想要一个什么类型的库。我们当然知道我们想要一个简洁而又不怪异的 API。但是，这里仍然有一个悬而未决的问题：需要怎样确定 API 的适用广度和深度。

API 的广度，仅仅指它想要覆盖多少不同类型的功能。有两百个函数的 API 比只有十个函数的 API 适用范围要广得多。与大多数其他库一样，我们对其广度（适用范围）没有特别的限制。我们添加有用的函数，而不用担心库的规模的增大会导致崩溃。

一个库的深度，可以衡量它的函数们在独立使用时，可以提供多少种的不同的方式。（关于它们如何组合，是另一个完全不同的问题）在这里，我们走向了与 Underscore 及 Lodash 完全不同的方向。因为 JavaScript 不会去检查参数的类型和数量，所以编写根据传入确切参数（参数的类型和数量）而具有多种不同行为的单个函数是相当容易的。Underscore 和 Lodash 使用这种方法让它们的函数更灵活。例如，在 Lodash 中，`pluck` 不仅可以作用在 list 上，还可以作用在 object 和 string 上。从这个意义上讲，Lodash 是一个相当有深度的 API。Ramda 试图保持相对较浅的深度，原因如下：

Lodash 提供的功能如下：

```js
_.pluck('abc', propertyName);
```

其将字符串拆分成由单字母字符串组成的数组，然后返回从每个字符串中提取的指定属性形成的数组。想找个这样的合适的应用场景是非常困难的：

```js
_.pluck('abc', 'length'); //=> [1, 1, 1]
```

如果你真的想要一个元素为 `1` ，且对应字符串中的每个字母的列表，下面这段代码比我的 Ramda 解法要短一些：

```js
map(always(1), split('', 'abc'));
```

但这貌似没什么用，因为唯一另外一个属性是有意义的：

```js
_.pluck('abc', '0'); //=> ['a', 'b', 'c']
```

如果 `pluck` 不存在，下面这样也是可以的：

```js
'abc'.split(''); //=> ['a', 'b', 'c']
```

所以在字符串上操作并没多大用处。之所以将其（字符串）包含进来，可能是因为所有属于 Lodash "集合" 类的函数都应该能同时适用于数组、对象和字符串；这只是一个一致性问题。（令人失望的是，Lodash 没有打算扩展到其他实际的集合中去，比如 Map 和 Set）我们已经理解了 `pluck` 是如何在数组上工作的。它涵盖的另一种类型是对象，如下所示：

```js
var flintstones1 = {
    A: {name: 'fred', age: 30},
    B: {name: 'wilma', age: 28},
    C: {name: 'pebbles', age: 2}
};
_.pluck(flintstones1, 'age'); //=> [30, 28, 2]
```

可以创建一个对象，`flintstones2` ，且以下结果为 `true`：

```js
_.isEqual(flintstones1, flintstones2); //=> true
```

但下面结果却为 `false`：

```js
_.pluck(flintstones1, 'age'); == _.pluck(flintstones2, 'age'); //=> false;
```

下面是一种可能的情况：

```js
var flintstones2 = {
    B: {name: 'wilma', age: 28},
    A: {name: 'fred', age: 30},
    C: {name: 'pebbles', age: 2}
};
_.pluck(flintstones2, 'age'); //=> [28, 30, 2]
```

问题在于，[根据规范](http://www.ecma-international.org/ecma-262/5.1/#sec-12.6.4)，对象 keys 的迭代顺序是依赖于实现的；通常它们按照添加到对象中的顺序进行迭代。。

在写本文时，我提交了一个关于这个问题的 issue。在最好的情况下，只有通过记录问题才能解决问题。但这个问题实在影响深远。如果你想统一列表和对象的行为，你将会不断遇到这个问题，除非你实现一个（非常慢的！）统一的顺序对 Object 属性进行迭代。

在 Ramda 中，`pluck` 只作用于列表。它接受一个属性名和一个列表，并返回一个相同长度的新列表。仅此而已。这个 API 深度很浅。（译者注：适用范围不太广）。

你可以将其看作特点，也可以看作是缺点。以 Lodash 的 `filter` 为例: 它接受一个数组、对象或字符串作为第一个集合（参数），然后接受一个函数、对象、字符串或者空作为它的回调，并且还需要一个对象或空作为它的 this 参数。你将一次获得 3 * 4 * 2 = 24 个函数！这要么是一个很大的问题，要么增加了从中找到一个你真正想要的方案的难度，增加了太多复杂性。决定权在于你。

在 Ramda 中，我们认为这种风格会增加不必要的复杂性。我们发现简单的函数签名对于维持简洁是至关重要的。如果我们需要函数既能作用于列表，又能作用于对象，我们会创建各自独立的函数（译者注：一般情况下会这样，但也有特例，比如 `map`）。如果有一个参数我们偶尔会用到，我们不会创建一个可选参数，而是创建两个函数。尽管这扩大了 API 的规模，但是它们保持了一至的浅度。

## API 的增长

有一个我们已经意识到的危险，一个可以用三个字母拼出来的危险："PHP"。我们不希望我们的 API 变成一个不可持续的、功能不一致的怪物。这是真正的威胁，没有强制性的规范来确定我们应该或不应该包含什么。

我们一直在努力；我们不希望包含一个貌似有用的函数。

为了避免变成 “PHP” 风格的庞然大物，我们专注于几件事情。首先，API 为王。虽然我们想要函数实现尽可能优雅，但我们为了即使是轻微的 API 性能改进，而牺牲了大量优雅的实现。我们试图执行严格的一致性标准。例如：像 `somethingBy` 这样的 Ramda 函数，以标准的方式看，与 `somethingWith` 函数是不同的。如 [issue 65](https://github.com/ramda/ramda/issues/65) 所述，我们

> 使用 xxBy 来表示单一属性的比较，无论是对象的自然属性还是合成属性；使用 xxWith 表示更具一般性的函数。

一些使用这种方式的函数的例子包括max / min / sort / uniq / difference。

# 函数式

JavaScript 是一门多范式语言。你可以编写简单的命令式代码，面对对象的代码，或函数式代码。原始命令式的代码非常直白、简单。有很多库可以帮助你将 JavaScript 作为面向对象的语言使用。但是将 JavaScript 作为函数式语言使用的库非常少。Ramda 帮忙填补了这个空缺。

如前所述，我们当然不是第一个。其他库通过各种不同方式让人们可以在 JavaScript 中进行函数式编程（FP）。在我看来，将函数式世界与 JavaScript 结合最成功的可能是 [allong.es](https://github.com/raganwald/allong.es)。但它不是一个流行的库，与 [Underscore](http://underscorejs.org/) 、 [Lodash](http://lodash.com/) 这些库不在一个级别上（就流行程度而言）；并且它有一个与 Ramda 不同的目标：它被设计为一种教学工具，一本书的演示库。

Ramda 正在尝试一些不同的东西。它的目标是成为一个能进行日常实际工作的实用的函数式库。

我们从头开始构建这个函数式库，使用了许多其他函数式语言通用的技术，以对 JavaScript 有意义的方式对这些技术进行移植。我们并没有试图弥合与面向对象世界之间的鸿沟，或者复制每一种函数式语言的每一个特性。实际上，我们甚至没有试图复制单一函数式语言的每个特性。它仍然是 JavaScript，甚至还继承了 JavaScript 缺陷。

## 函数式特性

那么，在广阔的函数式编程领域里，哪些部分是我们想要保留的，又有哪些不在我们的考虑范围呢？下面列出了函数式编程的一些主要（不完整）特性：

* 一等函数
* 高阶函数
* 词法闭包
* 引用透明
* 数据不可变
* 模式匹配
* 惰性求值
* 高效递归（TCO）
* [同像性（Homoiconic）](https://en.wikipedia.org/w/index.php?title=Homoiconicity&redirect=no)

前几个特性都已经内置在 JavaScript 中了。JavaScript 中的函数是一等公民，意味着我们可以像使用字符串、数字或对象等，对其引用或传递。我们还可以将函数作为参数传递给其他函数，并返回全新的函数，所以 JavaScript 中包含高阶函数。因为返回函数可以访问其在创建时的上下文中的所有变量，所以我们也在语言中构建出了词法闭包。

除此之外，上面列出其他的特性都没有自动包含在 JavaScript 中。有的可以轻易实现，有的只能部分或很难实现，有的则超出了语言的当前能力。

Ramda 可以确保在不会导致你的代码出问题的情况下，帮助实现（管理）上面的其他一些特性。例如，Ramda 不会改变你的输入数据。永远也不会！如果使用 `append` 将元素添加到列表的末尾，则会返回包含添加元素的新列表。你的原始列表保持不变。所以，由于 Ramda 不会尝试强行改变不可变的客户端数据，它可以很容易的与不可变数据一起工作。

另一方面，Ramda 强制要求引用透明。这个概念的意思是：可以在不改变整个程序行为的情况下，将表达式替换为其对应的计算值。对于 Ramda 来说，这意味着 Ramda 不会在应用程序中存储内部状态，也不会引用任何全局变量或者内部状态可以变的闭包。简言之，当你使用相同的值调用 Ramda 函数时，总会得到相同的结果。

在撰写本文时，正在讨论 Ramda 的惰性求值问题。一些库如 [Lazy.js](http://danieltao.com/lazy.js/) 和 [Lz.js](https://github.com/goatslacker/lz) ，表明在 JavaScript 中进行惰性求值是可行的。[Transducer](https://github.com/cognitect-labs/transducers-js) 提供了一种模拟惰性求值的方法。Ramda 正在努力增强自己这方面的能力。但这是一个巨大的改变，并不会很快实现。

Ramda 还会考虑加入一定程度的模式匹配，但不会像 Erlang 或 Haskell 这样的语言中的那么强大或方便。我们并没有看到会改变语言语法的宏，所以我们最多可以做一些类似于 [Reg Braithwaite 所描述的东西](http://raganwald.com/2014/06/23/multiple-dispatch.html#guarded-functions)。但是这至少在某种程度上讲是一种模式匹配的技术。

其他特性都超出了 Ramda 的能力。虽然有 [trampolining](https://en.wikipedia.org/wiki/Trampoline_(computing)) 技术可以让你在不使用尾递归优化工具的情况下获得递归的一些好处，但是它们由于侵入性太强而不能被普遍使用。所以 Ramda 内部没有使用太多递归，也没有提供任何帮助来实现有效的递归。好消息是它将会被提到下一版语言规范的计划中去。

然后是 **同像性（homoiconicity）** -- 某些语言（LISP、Prolog）的特性：程序的语法可以用一种在自身语言中易于理解和修改的数据结构表示的。这远远超出了 JavaScript 当前的能力，甚至超出了 Ramda 的梦想。

# 组合性

Ramda 的目标之一是，允许用户使用小的可组合函数，这是函数式编程的关键。

函数式编程通常涉及一些少量常见的数据结构，以及搭配操作它们的大量函数。这就是 Ramda 的工作原理。

简言之，Ramda 主要进行列表操作。但 JavaScript 没有列表的实现；最接近的模拟是 Array（数组）。这是 Ramda 使用的最基本的数据结构。我们不关心 JavaScript 数组的一些深层次可能的性质。我们忽略稀疏数组。如果你传了一个这样的数组给 Ramda，有可能会得到意想不到的结果。你需要传给 Ramda 以 Array 实现的列表。（如果这对你没有意义，不用担心；这是人们使用 JavaScript 数组的标准方式，你必须非常努力，才能创建出不寻常的情况（译者注：错误的情况））。

许多 Ramda 函数接受列表并且返回列表。这些函数都很容易组合。

```js
// :: [Comment] -> [Number]  
var userRatingForComments = R.compose(
    R.pluck('rating'),       // [User] -> [Number]
    R.map(R.propOf(users)),  // [String] -> [User]
    R.pluck('username')      // [Comment] -> [String]
);
```

Ramda 还包含 `pipe` 函数，它跟 `compose` 功能相同，但顺序是反的；我个人觉得它更可读一些：

```js
// :: [Comment] -> [Number]  
var userRatingForComments = R.pipe(
    R.pluck('username'),     // [Comment] -> [String]
    R.map(R.propOf(users)),  // [String] -> [User]
    R.pluck('rating')        // [User] -> [Number]
);
```

当然，组合可以作用于任何类型。如果下一个函数接受当前函数返回的类型，那么一切都应该没问题。

为了让其工作，Ramda 的函数必须具有足够小的规模。这与 Unix 的哲学不谋而合：大型的工具应该由小工具构建而成，每个工具做且只做一件事情。Ramda 的函数也是如此。理想情况下，这意味着以这些函数为基础的系统的复杂性只是问题自身固有的复杂性，而不是由库增加的附带的复杂性。

## 不变性

需要再次重申，Ramda 函数不会修改输入数据。这是函数式编程的核心原则，也是 Ramda 工作的核心。虽然这些函数可能会改变内部局部变量，但 Ramda 不会改变传递给它的任何数据。

这并不意味着你使用的所有东西都会被复制。Ramda 重用了它所能用到的。因此，在像 `assoc` 和 `assocPath` 这样的函数，返回具有特定更新属性的对象的克隆中，原始数据的所有非原生（non-primitive）属性在新对象中将以引用的方式使用。如果你想要一个对象的完全解耦的副本，Ramda 提供了 `cloneDeep`（译者注：现在 Ramda 只提供 `clone` 用作深拷贝） 函数。

这种不变性对 Ramda 来说是硬性规定。任何牵扯到变更用户数据的 pull request 都会被拒绝。我们认为这是 Ramda 的主要特征之一。

# 实用性

最后，Ramda 的目标是成为一个实用的库。这更难表述，因为实用性就像 “美丽” 一样：总是在旁观者眼中才能反映出来。永远都会有对不符合 Ramda 哲学的功能的要求，在那些提议者心目中，这些功能都是非常实用的。通常这些函数（功能）本身是有用的，但是由于不符合 Ramda 的哲学而被拒绝。

对于 Ramda 而言，实用性意味着一些具体的事情。

## 命令式实现

首先，Ramda 的实现并未遵循 LISP、ML 或者 Haskell 库中的优雅的编码技术。我们使用丑陋的命令式的循环，而不是优雅的递归代码块。一些 Ramda 的作者曾经在一个叫 [Eweda](https://github.com/CrossEye/eweda) 的早起的库中走过这条路，代码非常漂亮，但是在解决实际问题上它却失败了。许多列表函数只能处理一千个左右的条目，而且性能也很糟糕。 JavaScript 的设计没有很好的处理递归，大多数当前的引擎不执行任何尾部调用优化。

而 Ramda 的源代码却使用了乱七八糟的丑陋的 `while` 循环。

这意味着 Ramda 的实现不能作为如何编写功能良好的 JavaScript 的模型（模板）。这太糟糕了。但它是目前的 JavaScript 引擎最实用的一种选择（方案）。

## 合理的 API

Ramda 还试图就 API 中应该包含什么做出实用的选择。我们并没有试图移植 Clojure、Haskell 或任何其他函数式语言中的任何特定的函数子集，也没有试图模仿更成熟的 JavaScript 库或规范的 API。我们采纳函数的标准是，它们表现出合理的效用。当然，它们也必须与我们的函数式范式相契合才会被考虑，但这还不够；我们必须确信它们将会被用到，并且它们提供了通过当前函数不容易实现的价值。

后者是比较棘手的。有一个平衡的方案，以确定什么情况下语法糖是可以接受的。在之前，我们讨论了 `compose` 有一个执行顺序相反孪生同胞 `pipe`。有一种观点认为这是一种浪费，我们不应该把 API 因为这些多余的函数而搞乱。毕竟，

```js
R.pipe(fn1, fn2, ..., fnN)
```

可以重写为如下形式：

```js
R.apply(R.compose, R.reverse([fn1, fn2, ..., fnN]));
```

但是，我们确实选择将 `pipe` 以及其他一些看似多余的函数包含到其中，当它们符合下面的条件时：

* 很有可能会被用到
* 能更好的表达开发人员的意图
* 足够简单的实现

## 整洁且一致的 API

对于整体一致 API 的追求，听起来不像是一个现实的考虑，更像是一个纯粹主义者的目标。但事实上，提供简单而一致的 API 使得 Ramda 更易于使用。例如，一旦你习惯了 Ramda 对参数顺序的设定，你将很少需要查阅文档以确定如何构建你的调用。

另外，Ramda 坚决反对可选参数。这个决定有助于形成非常整洁的 API。一个函数应该做什么以及如何调用，通常是非常直观的。

## 并没有 “什么会帮助我” 的建议

最后，向某个人解释这个问题通常是最困难的，那就是一个用户对什么才是实用的概念与整个库的实用性实际上可能只有一点点关系。即使提出的函数有助于解决某个难题，如果问题太过狭隘，或者解决方案偏离了我们的基础哲学，那么它也不会被纳入到 Ramda 中。虽然实用性是在旁观者眼中反映出来的，但那些能够纵观整个库的旁观者会有一个宏观的不同的视野，只有那些能够在整体上提升 Ramda 的改变才会被采纳。

# 结论：生而不同

Ramda 的诞生是因为，没有任何其他的库能以我们想要的方式工作。我们想要将可以作用于不可变数据的小型可组合函数，组合成简洁的函数式的 pipeline （管道）。当 Ramda 与类似的库相比较时，这涉及到一些似乎颇具争议的决定。我们并不担心这一点。Ramda 为我们工作的很好，似乎也满足了[社区的需求](https://github.com/ramda/ramda/stargazers)。

我们不再孤单。自从我们开始以来，[FKit](https://github.com/nullobject/fkit) 也萌发了相似的想法。这是一个不太成熟的库，它的工作方式和 [Eweda](https://github.com/CrossEye/eweda) 一样，试图在 API 及其实现上同时保持真正的优雅。在我看来，他们很可能会遇到性能瓶颈。但是，我们无能为力，只能祝福他们。

Ramda 正在努力坚持它作为 “JavaScript 开发人员的实用的函数式库” 的座右铭。我们认为我们正在管理和维护 Ramda。但我们也[很乐意倾听](https://github.com/ramda/ramda/issues) 您的想法。
