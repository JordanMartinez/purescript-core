module Data.Maybe.First where

import Control.Comonad (Comonad)
import Control.Extend (Extend, (<<=))
import Data.Functor.Invariant (Invariant, invmap)
import Data.Maybe (Maybe(..))
import Data.Monoid (Monoid)

-- | Monoid returning the first (left-most) non-`Nothing` value.
-- |
-- | ``` purescript
-- | First (Just x) <> First (Just y) == First (Just x)
-- | First Nothing <> First (Just y) == First (Just y)
-- | First Nothing <> Nothing == First Nothing
-- | mempty :: First _ == First Nothing
-- | ```
newtype First a = First (Maybe a)

runFirst :: forall a. First a -> Maybe a
runFirst (First m) = m

instance eqFirst :: (Eq a) => Eq (First a) where
  (==) (First x) (First y) = x == y
  (/=) (First x) (First y) = x /= y

instance ordFirst :: (Ord a) => Ord (First a) where
  compare (First x) (First y) = compare x y

instance boundedFirst :: (Bounded a) => Bounded (First a) where
  top = First top
  bottom = First bottom

instance functorFirst :: Functor First where
  (<$>) f (First x) = First (f <$> x)

instance applyFirst :: Apply First where
  (<*>) (First f) (First x) = First (f <*> x)

instance applicativeFirst :: Applicative First where
  pure = First <<< pure

instance bindFirst :: Bind First where
  (>>=) (First x) f = First (x >>= runFirst <<< f)

instance monadFirst :: Monad First

instance extendFirst :: Extend First where
  (<<=) f x = f <<= x

instance invariantFirst :: Invariant First where
  invmap f _ (First x) = First (f <$> x)

instance showFirst :: (Show a) => Show (First a) where
  show (First a) = "First (" ++ show a ++ ")"

instance semigroupFirst :: Semigroup (First a) where
  (<>) first@(First (Just _)) _ = first
  (<>) _ second = second

instance monoidFirst :: Monoid (First a) where
  mempty = First Nothing
