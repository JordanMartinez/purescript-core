module Data.Witherable
  ( class Witherable
  , wilt
  , wither
  , partitionMapByWilt
  , filterMapByWither
  , traverseByWither
  , wilted
  , withered
  , witherDefault
  , wiltDefault
  , module Data.Filterable
  ) where

import Control.Applicative (class Applicative, pure)
import Control.Category ((<<<), identity)
import Data.Compactable (compact, separate)
import Data.Either (Either(..))
import Data.Filterable (class Filterable)
import Data.Functor (map)
import Data.Identity (Identity(..))
import Data.List (List)
import Data.Map (Map)
import Data.Maybe (Maybe(..))
import Data.Monoid (class Monoid, mempty)
import Data.Newtype (unwrap)
import Data.Traversable (class Traversable, traverse)
import Prelude (class Ord)

-- | `Witherable` represents data structures which can be _partitioned_ with
-- | effects in some `Applicative` functor.
-- |
-- | - `wilt` - partition a structure with effects
-- | - `wither` - filter a structure  with effects
-- |
-- | Laws:
-- |
-- | - Naturality: `t <<< wither f ≡ wither (t <<< f)`
-- | - Identity: `wither (pure <<< Just) ≡ pure`
-- | - Composition: `Compose <<< map (wither f) <<< wither g ≡ wither (Compose <<< map (wither f) <<< g)`
-- | - Multipass partition: `wilt p ≡ map separate <<< traverse p`
-- | - Multipass filter: `wither p ≡ map compact <<< traverse p`
-- |
-- | Superclass equivalences:
-- |
-- | - `partitionMap p = runIdentity <<< wilt (Identity <<< p)`
-- | - `filterMap p = runIdentity <<< wither (Identity <<< p)`
-- | - `traverse f ≡ wither (map Just <<< f)`
-- |
-- | Default implementations are provided by the following functions:
-- |
-- | - `wiltDefault`
-- | - `witherDefault`
-- | - `partitionMapByWilt`
-- | - `filterMapByWither`
-- | - `traverseByWither`
class (Filterable t, Traversable t) <= Witherable t where
  wilt :: forall m a l r. Applicative m =>
    (a -> m (Either l r)) -> t a -> m { left :: t l, right :: t r }

  wither :: forall m a b. Applicative m =>
    (a -> m (Maybe b)) -> t a -> m (t b)

-- | A default implementation of `wilt` using `separate`
wiltDefault :: forall t m a l r. Witherable t => Applicative m =>
  (a -> m (Either l r)) -> t a -> m { left :: t l, right :: t r }
wiltDefault p = map separate <<< traverse p

-- | A default implementation of `wither` using `compact`.
witherDefault :: forall t m a b. Witherable t => Applicative m =>
  (a -> m (Maybe b)) -> t a -> m (t b)
witherDefault p = map compact <<< traverse p

-- | A default implementation of `parititonMap` given a `Witherable`.
partitionMapByWilt :: forall t a l r. Witherable t =>
  (a -> Either l r) -> t a -> { left :: t l, right :: t r }
partitionMapByWilt p = unwrap <<< wilt (Identity <<< p)

-- | A default implementation of `filterMap` given a `Witherable`.
filterMapByWither :: forall t a b. Witherable t =>
  (a -> Maybe b) -> t a -> t b
filterMapByWither p = unwrap <<< wither (Identity <<< p)

-- | A default implementation of `traverse` given a `Witherable`.
traverseByWither :: forall t m a b. Witherable t => Applicative m =>
  (a -> m b) -> t a -> m (t b)
traverseByWither f = wither (map Just <<< f)

-- | Partition between `Left` and `Right` values - with effects in `m`.
wilted :: forall t m l r. Witherable t => Applicative m =>
  t (m (Either l r)) -> m { left :: t l, right :: t r }
wilted = wilt identity

-- | Filter out all the `Nothing` values - with effects in `m`.
withered :: forall t m x. Witherable t => Applicative m =>
  t (m (Maybe x)) -> m (t x)
withered = wither identity

instance witherableArray :: Witherable Array where
  wilt = wiltDefault
  wither = witherDefault

instance witherableList :: Witherable List where
  wilt = wiltDefault
  wither = witherDefault

instance witherableMap :: Ord k => Witherable (Map k) where
  wilt = wiltDefault
  wither = witherDefault

instance witherableMaybe :: Witherable Maybe where
  wilt p Nothing = pure { left: Nothing, right: Nothing }
  wilt p (Just x) = map convert (p x) where
    convert (Left l) = { left: Just l, right: Nothing }
    convert (Right r) = { left: Nothing, right: Just r }

  wither p Nothing = pure Nothing
  wither p (Just x) = p x

instance witherableEither :: Monoid m => Witherable (Either m) where
  wilt p (Left el) = pure { left: Left el, right: Left el }
  wilt p (Right er) = map convert (p er) where
    convert (Left l) = { left: Right l, right: Left mempty }
    convert (Right r) = { left: Left mempty, right: Right r }

  wither p (Left el) = pure (Left el)
  wither p (Right er) = map convert (p er) where
    convert Nothing = Left mempty
    convert (Just r) = Right r
