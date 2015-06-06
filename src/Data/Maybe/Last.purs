module Data.Maybe.Last where

import Prelude

import Control.Comonad (Comonad)
import Control.Extend (Extend, extend)
import Data.Functor.Invariant (Invariant, imapF)
import Data.Maybe (Maybe(..))
import Data.Monoid (Monoid)

-- | Monoid returning the last (right-most) non-`Nothing` value.
-- |
-- | ``` purescript
-- | Last (Just x) <> Last (Just y) == Last (Just y)
-- | Last (Just x) <> Nothing == Last (Just x)
-- | Last Nothing <> Nothing == Last Nothing
-- | mempty :: Last _ == Last Nothing
-- | ```
newtype Last a = Last (Maybe a)

runLast :: forall a. Last a -> Maybe a
runLast (Last m) = m

instance eqLast :: (Eq a) => Eq (Last a) where
  eq (Last x) (Last y) = x == y

instance ordLast :: (Ord a) => Ord (Last a) where
  compare (Last x) (Last y) = compare x y

instance boundedLast :: (Bounded a) => Bounded (Last a) where
  top = Last top
  bottom = Last bottom

instance functorLast :: Functor Last where
  map f (Last x) = Last (f <$> x)

instance applyLast :: Apply Last where
  apply (Last f) (Last x) = Last (f <*> x)

instance applicativeLast :: Applicative Last where
  pure = Last <<< pure

instance bindLast :: Bind Last where
  bind (Last x) f = Last (bind x (runLast <<< f))

instance monadLast :: Monad Last

instance extendLast :: Extend Last where
  extend f (Last x) = Last (extend (f <<< Last) x)

instance invariantLast :: Invariant Last where
  imap = imapF

instance showLast :: (Show a) => Show (Last a) where
  show (Last a) = "Last (" ++ show a ++ ")"

instance semigroupLast :: Semigroup (Last a) where
  append _ last@(Last (Just _)) = last
  append last (Last Nothing) = last

instance monoidLast :: Monoid (Last a) where
  mempty = Last Nothing
