module Test.Main where

import Prelude

import Control.Monad.Eff (Eff)
import Control.Monad.Eff.Console (log, CONSOLE)
import Control.Monad.Eff.Exception (EXCEPTION)
import Control.Monad.Eff.Random (RANDOM)

import Test.Data.Map (mapTests)
import Test.Data.StrMap (strMapTests)

main :: Eff (console :: CONSOLE, random :: RANDOM, exception :: EXCEPTION) Unit
main = do
  log "Running Map tests"
  mapTests

  log "Running StrMap tests"
  strMapTests
