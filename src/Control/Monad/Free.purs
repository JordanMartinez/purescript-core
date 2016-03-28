module Control.Monad.Free
  ( Free()
  , suspendF
  , liftF
  , liftFI
  , mapF
  , injF
  , foldFree
  , runFree
  , runFreeM
  ) where

import Prelude (class Functor, class Applicative, class Monad, class Apply, class Bind, (<>), (<$>), pure, (<<<), id, (>>=), ap, return)

import Control.Monad.Rec.Class (class MonadRec, tailRecM)
import Control.Monad.Trans (class MonadTrans)

import Data.CatList (CatList(), empty, snoc, uncons)
import Data.Either (Either(..), either)
import Data.Identity (Identity(..), runIdentity)
import Data.Inject (class Inject, inj)
import Data.Maybe (Maybe(..))
import Data.NaturalTransformation (NaturalTransformation())
import Data.Tuple (Tuple(..))

import Unsafe.Coerce (unsafeCoerce)

-- | The free monad for a type constructor `f`.
-- |
-- | Implemented in the spirit of [Relection without Remorse](http://okmij.org/ftp/Haskell/zseq.pdf),
-- | the free monad is represented using a sequential data structure in
-- | order to overcome the quadratic complexity of left-associated binds
-- | and traversal through the free monad structure.
data Free f a = Free (FreeView f Val Val) (CatList (ExpF f))

newtype ExpF f = ExpF (Val -> Free f Val)

data FreeView f a b = Return a | Bind (f b) (b -> Free f a)

data Val

instance freeFunctor :: Functor (Free f) where
  map k f = f >>= return <<< k

instance freeBind :: Bind (Free f) where
  bind (Free v s) k = Free v (snoc s (ExpF (unsafeCoerceBind k)))
    where
    unsafeCoerceBind :: forall a b. (a -> Free f b)-> (Val -> Free f Val)
    unsafeCoerceBind = unsafeCoerce

instance freeApplicative :: Applicative (Free f) where
  pure = fromView <<< Return

instance freeApply :: Apply (Free f) where
  apply = ap

instance freeMonad :: Monad (Free f)

instance freeMonadTrans :: MonadTrans Free where
  lift = liftF

instance freeMonadRec :: MonadRec (Free f) where
  tailRecM k a = k a >>= either (tailRecM k) pure

-- | Lift an impure value described by the generating type constructor `f` into the free monad.
liftF :: forall f a. f a -> Free f a
liftF f = fromView (Bind (unsafeCoerceF f) (pure <<< unsafeCoerceVal))
  where
  unsafeCoerceF :: f a -> f Val
  unsafeCoerceF = unsafeCoerce

  unsafeCoerceVal :: Val -> a
  unsafeCoerceVal = unsafeCoerce

-- | Lift an action described by the generating type constructor `f` into
-- | `Free g` using `Inject` to go from `f` to `g`.
liftFI :: forall f g a. (Inject f g) => f a -> Free g a
liftFI fa = liftF (inj fa :: g a)

-- | Suspend a value given the applicative functor `f` into the free monad.
suspendF :: forall f a. (Applicative f) => Free f a -> Free f a
suspendF f = fromView (Bind (unsafeCoerceF (pure f :: f (Free f a))) (id <<< unsafeCoerceVal))
  where
  unsafeCoerceF :: f (Free f a) -> f Val
  unsafeCoerceF = unsafeCoerce

  unsafeCoerceVal :: Val -> Free f a
  unsafeCoerceVal = unsafeCoerce

-- | Use a natural transformation to change the generating type constructor of a free monad.
mapF :: forall f g a. NaturalTransformation f g -> Free f a -> Free g a
mapF k = foldFree (liftF <<< k)

-- | Embed computations in one `Free` monad as computations in the `Free` monad for
-- | a coproduct type constructor.
-- |
-- | This construction allows us to write computations which are polymorphic in the
-- | particular `Free` monad we use, allowing us to extend the functionality of
-- | our monad later.
injF :: forall f g a. (Inject f g) => Free f a -> Free g a
injF = mapF inj

-- | Run a free monad with a natural transformation from the type constructor `f`
-- | to the tail-recursive monad `m`. See the `MonadRec` type class for more details.
foldFree :: forall f m a. (MonadRec m) => NaturalTransformation f m -> Free f a -> m a
foldFree k = tailRecM go
  where
  go :: Free f a -> m (Either (Free f a) a)
  go f =
    case toView f of
         Return a -> Right <$> pure a
         Bind g i -> (Left <<< i) <$> k g

-- | Run a free monad with a function that unwraps a single layer of the functor `f` at a time.
runFree :: forall f a. (Functor f) => (f (Free f a) -> Free f a) -> Free f a -> a
runFree k = runIdentity <<< runFreeM (Identity <<< k)

-- | Run a free monad with a function mapping a functor `f` to a tail-recursive monad `m`.
-- | See the `MonadRec` type class for more details.
runFreeM :: forall f m a. (Functor f, MonadRec m) => (f (Free f a) -> m (Free f a)) -> Free f a -> m a
runFreeM k = tailRecM go
  where
  go :: Free f a -> m (Either (Free f a) a)
  go f =
    case toView f of
         Return a -> Right <$> pure a
         Bind g i -> Left <$> k (i <$> g)

fromView :: forall f a. FreeView f a Val -> Free f a
fromView f = Free (unsafeCoerceFreeView f) empty
  where
  unsafeCoerceFreeView :: FreeView f a Val -> FreeView f Val Val
  unsafeCoerceFreeView = unsafeCoerce

toView :: forall f a. Free f a -> FreeView f a Val
toView (Free v s) =
  case v of
       Return a -> case (uncons s) of
                        Nothing -> Return (unsafeCoerceVal a)
                        Just (Tuple h t) -> toView (unsafeCoerceFree (concatF ((runExpF h) a) t))
       Bind f k -> Bind f (\a -> unsafeCoerceFree (concatF (k a) s))
  where
  concatF :: Free f Val -> CatList (ExpF f) -> Free f Val
  concatF (Free v l) r = Free v (l <> r)

  runExpF :: ExpF f -> (Val -> Free f Val)
  runExpF (ExpF k) = k

  unsafeCoerceFree :: Free f Val -> Free f a
  unsafeCoerceFree = unsafeCoerce

  unsafeCoerceVal :: Val -> a
  unsafeCoerceVal = unsafeCoerce
