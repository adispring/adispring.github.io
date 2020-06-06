---
title: Functor/Applicative/Monoid/Monad
date: 2016-11-19 13:31:25
categories: 'Haskell'
---
## Applicative类 的定义

```haskell
class (Functor f) => Applicative f where
  pure :: a -> f a
  (<*>) :: f (a -> b) -> f a -> f b
```

Applicative 中定义了 `pure` 和 `<*>`

## Applicative Functor 的几个实例

### Maybe
```haskell
instance Applicative Maybe where
  pure = Just
  Nothing <*> _ = Nothing
  (Just f) <*> something = fmap f something
```

### Applicative 相较于 Functor 的改进之处：

with the Applicative type class, we can chain the use of the <\*> function, thus enabling us to seamlessly operate on several applicative values instead of just one. For instance, check this out:

```haskell
pure(+) <*> Just 3 <*> Just 5 -- Just 8
```

lift 相当于 `pure`

### Applicative 中还定义了 `<$>`

<$> 相当于中缀版的 fmap，但应用于 Applicative 的链式调用特别方便

```haskell
(<$>) :: (Functor f) => (a -> b) -> f a -> f b
f <$> x = fmap f x
-- pure f <*> x <*> y <*> ... === fmap f x <*> y... === f <$> x <*> y...
```

### List 也是 Applicative Functor

```haskell
instance Applicative [] where
  pure x = [x]
  fs <*> xs = [f x | f <- fs, x <- xs]
```

理解了 haskell 中 List 的 `<*>` 也就理解了 Ramda 中的 `liftN`
将 fs 中的每个 f map 到 xs 中的每个 x。

例如
```haskell
fs = [f1, f2, f3]
xs = [x1, x2]
fs <*> xs === [f1 x1, f1 f2, f2 x1, f2 x2, f3 x1, f3 x2]
```

### 函数 `(->) r` 也是 Applicative Functor 很有意思

```haskell
Function :: ((->) r)
Function a = ((->) r) a 
           = r -> a
```


```haskell
instance Applicative ((->) r) where
  pure x = (\_ -> x)
  f <*> g = \x -> f x (g x)
```

```haskell
(pure 3) "blah" -- 3
(+) <$> (+3) <*> (*100) $ 5 -- 508
```

`<$>` + `<*>` 大致对标 Ramda 中的 converge

## Laws

### 1. [Functor Laws](https://en.wikibooks.org/wiki/Haskell/The_Functor_class)

```haskell
fmap id = id
fmap (g . f) = fmap g . fmap f
```

### 2. [Applicative Functor Laws](https://en.wikibooks.org/wiki/Haskell/Applicative_functors)
```haskell
pure id <*> v = v                             -- Identity
pure f <*> pure x = pure (f x)                -- Homomorphism
u <*> pure y = pure ($ y) <*> u               -- Interchange
pure (.) <*> u <*> v <*> w = u <*> (v <*> w)  -- Composition
```
a bonus law
```
fmap f x = pure f <*> x
```

### 3. [Monad Laws](https://wiki.haskell.org/Monad_laws)
```haskell
return a >>= k  =  k a
m >>= return  =  m
m >>= (x -> k x >>= h)  =  (m >>= k) >>= h
```
