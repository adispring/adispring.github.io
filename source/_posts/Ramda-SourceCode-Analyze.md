---
title: Ramda 源码分析（一） 柯里化curry
date: 2016-10-21 09:34:59
tags:
---

## Ramda 目录说明

[Ramda](http://ramdajs.com) API 的源码都在 src/ 文件夹中，src/ 下包含一个 internal/ 文件夹和若干外部模块。直接在 **src/** 下编写的模块（函数）供**外部调用**，在 **internal/** 下编写的模块仅供**内部使用**，属于帮助函数，**内部函数以下划线 "_" 开头**。

本次源码分析使用版本号为：Ramda v0.22.1。

## 源码分析
- \_\_ 占位符

  占位符是一个 “普通的” object ，key 为 `@@functional/placeholder` ，value 为 true。
  
  ```js
  module.exports = {'@@functional/placeholder': true};
  ```
  配合柯里化函数使用，可以使柯里化函数传入实参不在限于从左往右依次传入，大大增强了柯里化函数的能力。
  
  举例如下，g 是一个柯里化的 ternary（三元）函数，\_ 代表 R.\_\_ ，下面的写法是等价的。
  
  ```js
  g(1, 2, 3)
  g(_, 2, 3)(1)
  g(_, _, 3)(1)(2)
  g(_, _, 3)(1, 2)
  g(_, 2, _)(1, 3)
  g(_, 2)(1)(3)
  g(_, 2)(1, 3)
  g(_, 2)(_, 3)(1)
  ```
  
- \_isPlaceholder
  
  判断实参是否为占位符（R.\_\_），在柯里化函数中使用。
  
  ```js
  module.exports = function _isPlaceholder(a) {
    return a != null &&
	     typeof a === 'object' &&
	     a['@@functional/placeholder'] === true;
  };
  ```
  
- \_curry1
  
  优化的内部单参数柯里化函数：对单参数函数`fn` 进行柯里化，返回柯里化了的 fn' → f1。
  
  当传入参数为空或者传入的是占位符，返回 f1；否则执行 f1 ，并返回执行结果。
  
  柯里化用到了闭包。\_curry1/\_curry2/\_curry3 是为了柯里化 ramda API 优化用的。因为 ramda API 都是原生柯里化的，且参数一般不超过3个，所以用到上述3个内部优化的柯里化函数，以提高效率。
  
  ```js
  module.exports = function _curry1(fn) {
    return function f1(a) {
      if (arguments.length === 0 || _isPlaceholder(a)) {
        return f1;
      } else {
        return fn.apply(this, arguments);
      }
    };
  };
  ```
  
- \_curry2

  优化的内部双参数柯里化函数：对双参数函数 `fn` 进行柯里化，返回柯里化了的 fn' → f2。
  
  原理讲解：
  
  1. 当无参数传入时，返回 f2；
  2. 当有一个参数（a）传入时，判断该参数是否为 R.\_\_ ：是则返回 f2，否则返回加持一个参数（a）的单参数柯里化函数；
  3. 当传入两个参数时，若都是占位符，返回 f2，若有一个占位符则返回加持一个参数的单参数柯里化函数，若无占位符，则执行 fn。
  
  ```js
  module.exports = function _curry2(fn) {
    return function f2(a, b) {
      switch (arguments.length) {
        case 0:
          return f2;
        case 1:
          return _isPlaceholder(a) ? f2
               : _curry1(function(_b) { return fn(a, _b); });
        default:
          return _isPlaceholder(a) && _isPlaceholder(b) ? f2
               : _isPlaceholder(a) ? _curry1(function(_a) { return fn(_a,   b); })
               : _isPlaceholder(b) ? _curry1(function(_b) { return fn(a, _b); })
               : fn(a, b);
      }
    };
  };
  ```

- \_arity

  没有看出来 \_arity 是干嘛用的，控制（限制）函数参数的个数？

  ```js
  module.exports = function _arity(n, fn) {
    /* eslint-disable no-unused-vars */
    switch (n) {
      case 0: return function() { return fn.apply(this, arguments); };
      case 1: return function(a0) { return fn.apply(this, arguments); };
      case 2: return function(a0, a1) { return fn.apply(this, arguments); };
      case 3: return function(a0, a1, a2) { return fn.apply(this, arguments); };
      case 4: return function(a0, a1, a2, a3) { return fn.apply(this, arguments); };
      case 5: return function(a0, a1, a2, a3, a4) { return fn.apply(this, arguments); };
      case 6: return function(a0, a1, a2, a3, a4, a5) { return fn.apply(this, arguments); };
      case 7: return function(a0, a1, a2, a3, a4, a5, a6) { return fn.apply(this, arguments); };
      case 8: return function(a0, a1, a2, a3, a4, a5, a6, a7) { return fn.apply(this, arguments); };
      case 9: return function(a0, a1, a2, a3, a4, a5, a6, a7, a8) { return fn.apply(this, arguments); };
      case 10: return function(a0, a1, a2, a3, a4, a5, a6, a7, a8, a9) { return fn.apply(this, arguments); };
      default: throw new Error('First argument to _arity must be a non-negative integer no greater than ten');
    }
  };
  ```

- curryN

  length：待柯里化函数参数的个数，fn：带柯里化函数

  参数个数为1，用 \_curry1 对 fn 柯里化；参数个数范围为 (1，10] ，用 \_curryN。

  ```js
  module.exports = _curry2(function curryN(length, fn) {
    if (length === 1) {
      return _curry1(fn);
    }
    return _arity(length, _curryN(length, [], fn));
  });
  ```
- curry

  平时实际用到的柯里化函数

  ```js
  module.exports = _curry1(function curry(fn) {
    return curryN(fn.length, fn);
  });
  ```
