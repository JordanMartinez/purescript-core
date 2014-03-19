module Control.Monad.Eff.Ref where

import Control.Monad.Eff

foreign import data Ref :: !

foreign import data RefVal :: * -> *

foreign import newRef 
  "function newRef(val) {\
  \  return function () {\
  \    return { value: val };\
  \  };\
  \}" :: forall s r. s -> Eff (ref :: Ref | r) (RefVal s)

foreign import readRef 
  "function readRef(ref) {\
  \  return function() {\
  \    return ref.value;\
  \  };\
  \}" :: forall s r. RefVal s -> Eff (ref :: Ref | r) s


foreign import modifyRef 
  "function modifyRef(ref) {\
  \  return function(f) {\
  \    return function() {\
  \      ref.value = f(ref.value);\
  \      return {};\
  \    };\
  \  };\
  \}" :: forall s r. RefVal s -> (s -> s) -> Eff (ref :: Ref | r) {}

foreign import writeRef 
  "function writeRef(ref) {\
  \  return function(val) {\
  \    return function() {\
  \      ref.value = val;\
  \      return {};\
  \    };\
  \  };\
  \}" :: forall s r. RefVal s -> s -> Eff (ref :: Ref | r) {}
