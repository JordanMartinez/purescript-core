## Module Data.StrMap.ST

Helper functions for working with mutable maps using the `ST` effect.

This module can be used when performance is important and mutation is a local effect.

#### `STStrMap`

``` purescript
data STStrMap :: * -> * -> *
```

A reference to a mutable map

The first type parameter represents the memory region which the map belongs to. The second type parameter defines the type of elements of the mutable array.

The runtime representation of a value of type `STStrMap h a` is the same as that of `StrMap a`, except that mutation is allowed.

#### `new`

``` purescript
new :: forall a h r. Eff (st :: ST h | r) (STStrMap h a)
```

Create a new, empty mutable map

#### `peek`

``` purescript
peek :: forall a h r. STStrMap h a -> String -> Eff (st :: ST h | r) (Maybe a)
```

Get the value for a key in a mutable map

#### `poke`

``` purescript
poke :: forall a h r. STStrMap h a -> String -> a -> Eff (st :: ST h | r) (STStrMap h a)
```

Update the value for a key in a mutable map

#### `delete`

``` purescript
delete :: forall a h r. STStrMap h a -> String -> Eff (st :: ST h | r) (STStrMap h a)
```

Remove a key and the corresponding value from a mutable map


