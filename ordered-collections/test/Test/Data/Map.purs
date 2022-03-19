module Test.Data.Map where

import Prelude

import Control.Alt ((<|>))
import Data.Array as A
import Data.Array.NonEmpty (cons')
import Data.Foldable (foldl, for_, all, and)
import Data.FoldableWithIndex (foldrWithIndex)
import Data.Function (on)
import Data.FunctorWithIndex (mapWithIndex)
import Data.List (List(..), groupBy, length, nubBy, singleton, sort, sortBy, (:))
import Data.List.NonEmpty as NEL
import Data.Map as M
import Data.Map.Gen (genMap)
import Data.Maybe (Maybe(..), fromMaybe, maybe)
import Data.Semigroup.First (First(..))
import Data.Semigroup.Last (Last(..))
import Data.Tuple (Tuple(..), fst, uncurry)
import Effect (Effect)
import Effect.Console (log)
import Partial.Unsafe (unsafePartial)
import Test.QuickCheck ((<?>), (<=?), (===), quickCheck, quickCheck')
import Test.QuickCheck.Arbitrary (class Arbitrary, arbitrary)
import Test.QuickCheck.Gen (elements, oneOf)

newtype TestMap k v = TestMap (M.Map k v)

instance arbTestMap :: (Eq k, Ord k, Arbitrary k, Arbitrary v) => Arbitrary (TestMap k v) where
  arbitrary = TestMap <$> genMap arbitrary arbitrary

data SmallKey = A | B | C | D | E | F | G | H | I | J
derive instance eqSmallKey :: Eq SmallKey
derive instance ordSmallKey :: Ord SmallKey

instance showSmallKey :: Show SmallKey where
  show A = "A"
  show B = "B"
  show C = "C"
  show D = "D"
  show E = "E"
  show F = "F"
  show G = "G"
  show H = "H"
  show I = "I"
  show J = "J"

instance arbSmallKey :: Arbitrary SmallKey where
  arbitrary = elements $ cons' A [B, C, D, E, F, G, H, I, J]

data Instruction k v = Insert k v | Delete k

instance showInstruction :: (Show k, Show v) => Show (Instruction k v) where
  show (Insert k v) = "Insert (" <> show k <> ") (" <> show v <> ")"
  show (Delete k) = "Delete (" <> show k <> ")"

instance arbInstruction :: (Arbitrary k, Arbitrary v) => Arbitrary (Instruction k v) where
  arbitrary = oneOf $ cons' (Insert <$> arbitrary <*> arbitrary) [Delete <$> arbitrary]

runInstructions :: forall k v. Ord k => List (Instruction k v) -> M.Map k v -> M.Map k v
runInstructions instrs t0 = foldl step t0 instrs
  where
  step tree (Insert k v) = M.insert k v tree
  step tree (Delete k) = M.delete k tree

smallKey :: SmallKey -> SmallKey
smallKey k = k

number :: Int -> Int
number n = n

smallKeyToNumberMap :: M.Map SmallKey Int -> M.Map SmallKey Int
smallKeyToNumberMap m = m

mapTests :: Effect Unit
mapTests = do

  -- Data.Map

  log "Test inserting into empty tree"
  quickCheck $ \k v -> M.lookup (smallKey k) (M.insert k v M.empty) == Just (number v)
    <?> ("k: " <> show k <> ", v: " <> show v)

  log "Test inserting two values with same key"
  quickCheck $ \k v1 v2 ->
    M.lookup (smallKey k) (M.insert k v2 (M.insert k v1 M.empty)) == Just (number v2)

  log "Test insertWith combining values"
  quickCheck $ \k v1 v2 ->
    M.lookup (smallKey k) (M.insertWith (+) k v2 (M.insert k v1 M.empty)) == Just (number (v1 + v2))

  log "Test insertWith passes the first value as the first argument to the combining function"
  quickCheck $ \k v1 v2 ->
    M.lookup (smallKey k) (M.insertWith const k v2 (M.insert k v1 M.empty)) == Just (number v1)

  log "Test delete after inserting"
  quickCheck $ \k v -> M.isEmpty (M.delete (smallKey k) (M.insert k (number v) M.empty))
    <?> ("k: " <> show k <> ", v: " <> show v)

  log "Test pop after inserting"
  quickCheck $ \k v -> M.pop (smallKey k) (M.insert k (number v) M.empty) == Just (Tuple v M.empty)
    <?> ("k: " <> show k <> ", v: " <> show v)

  log "Pop non-existent key"
  quickCheck $ \k1 k2 v -> ((k1 == k2) || M.pop (smallKey k2) (M.insert k1 (number v) M.empty) == Nothing)
    <?> ("k1: " <> show k1 <> ", k2: " <> show k2 <> ", v: " <> show v)

  log "Insert two, lookup first"
  quickCheck $ \k1 v1 k2 v2 -> ((k1 == k2) || (M.lookup k1 (M.insert (smallKey k2) (number v2) (M.insert (smallKey k1) (number v1) M.empty)) == Just v1))
    <?> ("k1: " <> show k1 <> ", v1: " <> show v1 <> ", k2: " <> show k2 <> ", v2: " <> show v2)

  log "Insert two, lookup second"
  quickCheck $ \k1 v1 k2 v2 -> M.lookup k2 (M.insert (smallKey k2) (number v2) (M.insert (smallKey k1) (number v1) M.empty)) == Just v2
    <?> ("k1: " <> show k1 <> ", v1: " <> show v1 <> ", k2: " <> show k2 <> ", v2: " <> show v2)

  log "Insert two, delete one"
  quickCheck $ \k1 v1 k2 v2 -> (k1 == k2 || M.lookup k2 (M.delete k1 (M.insert (smallKey k2) (number v2) (M.insert (smallKey k1) (number v1) M.empty))) == Just v2)
    <?> ("k1: " <> show k1 <> ", v1: " <> show v1 <> ", k2: " <> show k2 <> ", v2: " <> show v2)

  log "Check balance property"
  quickCheck' 1000 $ \instrs ->
    let
      tree :: M.Map SmallKey Int
      tree = runInstructions instrs M.empty
    in M.checkValid tree <?> ("Map not balanced:\n  " <> show tree <> "\nGenerated by:\n  " <> show instrs)

  log "Lookup from empty"
  quickCheck $ \k -> M.lookup k (M.empty :: M.Map SmallKey Int) == Nothing

  log "Lookup from singleton"
  quickCheck $ \k v -> M.lookup (k :: SmallKey) (M.singleton k (v :: Int)) == Just v

  log "Random lookup"
  quickCheck' 1000 $ \instrs k v ->
    let
      tree :: M.Map SmallKey Int
      tree = M.insert k v (runInstructions instrs M.empty)
    in M.lookup k tree == Just v <?> ("instrs:\n  " <> show instrs <> "\nk:\n  " <> show k <> "\nv:\n  " <> show v)

  log "Singleton to list"
  quickCheck $ \k v -> M.toUnfoldable (M.singleton k v :: M.Map SmallKey Int) == singleton (Tuple k v)

  log "fromFoldable [] = empty"
  quickCheck (M.fromFoldable [] == (M.empty :: M.Map Unit Unit)
    <?> "was not empty")

  log "fromFoldable & key collision"
  do
    let nums = M.fromFoldable [Tuple 0 "zero", Tuple 1 "what", Tuple 1 "one"]
    quickCheck (M.lookup 0 nums == Just "zero" <?> "invalid lookup - 0")
    quickCheck (M.lookup 1 nums == Just "one"  <?> "invalid lookup - 1")
    quickCheck (M.lookup 2 nums == Nothing     <?> "invalid lookup - 2")

  log "fromFoldableWith const [] = empty"
  quickCheck (M.fromFoldableWith const [] == (M.empty :: M.Map Unit Unit)
    <?> "was not empty")

  log "fromFoldableWith (+) & key collision"
  do
    let nums = M.fromFoldableWith (+) [Tuple 0 1, Tuple 1 1, Tuple 1 1]
    quickCheck (M.lookup 0 nums == Just 1  <?> "invalid lookup - 0")
    quickCheck (M.lookup 1 nums == Just 2  <?> "invalid lookup - 1")
    quickCheck (M.lookup 2 nums == Nothing <?> "invalid lookup - 2")

  log "sort . toUnfoldable . fromFoldable = sort (on lists without key-duplicates)"
  quickCheck $ \(list :: List (Tuple SmallKey Int)) ->
    let nubbedList = nubBy (compare `on` fst) list
        f x = M.toUnfoldable (M.fromFoldable x)
    in sort (f nubbedList) == sort nubbedList <?> show nubbedList

  log "fromFoldable . toUnfoldable = id"
  quickCheck $ \(TestMap (m :: M.Map SmallKey Int)) ->
    let f m' = M.fromFoldable (M.toUnfoldable m' :: List (Tuple SmallKey Int))
    in f m == m <?> show m

  log "fromFoldableWith const = fromFoldable"
  quickCheck $ \arr ->
    M.fromFoldableWith const arr ==
    M.fromFoldable (arr :: List (Tuple SmallKey Int)) <?> show arr

  log "fromFoldableWith (<>) = fromFoldable . collapse with (<>) . group on fst"
  quickCheck $ \arr ->
    let combine (Tuple s a) (Tuple _ b) = (Tuple s $ b <> a)
        foldl1 g = unsafePartial \(Cons x xs) -> foldl g x xs
        f = M.fromFoldable <<< map (foldl1 combine <<< NEL.toList) <<<
            groupBy ((==) `on` fst) <<< sortBy (compare `on` fst) in
    M.fromFoldableWith (<>) arr === f (arr :: List (Tuple String String))

  log "toUnfoldable is sorted"
  quickCheck $ \(TestMap m) ->
    let list = M.toUnfoldable (m :: M.Map SmallKey Int)
        ascList = M.toUnfoldable m
    in ascList === sortBy (compare `on` fst) list

  log "Lookup from union"
  quickCheck $ \(TestMap m1) (TestMap m2) k ->
    M.lookup (smallKey k) (M.union m1 m2) == (case M.lookup k m1 of
      Nothing -> M.lookup k m2
      Just v -> Just (number v)) <?> ("m1: " <> show m1 <> ", m2: " <> show m2 <> ", k: " <> show k <> ", v1: " <> show (M.lookup k m1) <> ", v2: " <> show (M.lookup k m2) <> ", union: " <> show (M.union m1 m2))

  log "Union is idempotent"
  quickCheck $ \(TestMap m1) (TestMap m2) -> (m1 `M.union` m2) == ((m1 `M.union` m2) `M.union` (m2 :: M.Map SmallKey Int))

  log "Union prefers left"
  quickCheck $ \(TestMap m1) (TestMap m2) k -> M.lookup k (M.union m1 (m2 :: M.Map SmallKey Int)) == (M.lookup k m1 <|> M.lookup k m2)

  log "unionWith"
  for_ [Tuple (+) 0, Tuple (*) 1] $ \(Tuple op ident) ->
    quickCheck $ \(TestMap m1) (TestMap m2) k ->
      let u = M.unionWith op m1 m2 :: M.Map SmallKey Int
      in case M.lookup k u of
           Nothing -> not (M.member k m1 || M.member k m2)
           Just v -> v == op (fromMaybe ident (M.lookup k m1)) (fromMaybe ident (M.lookup k m2))

  log "unionWith argument order"
  quickCheck $ \(TestMap m1) (TestMap m2) k ->
    let u   = M.unionWith (-) m1 m2 :: M.Map SmallKey Int
        in1 = M.member k m1
        v1  = M.lookup k m1
        in2 = M.member k m2
        v2  = M.lookup k m2
    in case M.lookup k u of
          Just v | in1 && in2 -> Just v == ((-) <$> v1 <*> v2)
          Just v | in1        -> Just v == v1
          Just v              -> Just v == v2
          Nothing             -> not (in1 || in2)

  log "Lookup from intersection"
  quickCheck $ \(TestMap m1) (TestMap m2) k ->
    M.lookup (smallKey k) (M.intersection (m1 :: M.Map SmallKey Int) (m2 :: M.Map SmallKey Int)) == (case M.lookup k m2 of
      Nothing -> Nothing
      Just _ -> M.lookup k m1) <?> ("m1: " <> show m1 <> ", m2: " <> show m2 <> ", k: " <> show k <> ", v1: " <> show (M.lookup k m1) <> ", v2: " <> show (M.lookup k m2) <> ", intersection: " <> show (M.intersection m1 m2))

  log "Intersection is idempotent"
  quickCheck $ \(TestMap m1) (TestMap m2) -> ((m1 :: M.Map SmallKey Int) `M.intersection` m2) == ((m1 `M.intersection` m2) `M.intersection` (m2 :: M.Map SmallKey Int))

  log "intersectionWith"
  for_ [(+), (*)] $ \op ->
    quickCheck $ \(TestMap m1) (TestMap m2) k ->
      let u = M.intersectionWith op m1 m2 :: M.Map SmallKey Int
      in case M.lookup k u of
           Nothing -> not (M.member k m1 && M.member k m2)
           Just v -> Just v == (op <$> M.lookup k m1 <*> M.lookup k m2)

  log "map-apply is equivalent to intersectionWith"
  for_ [(+), (*)] $ \op ->
    quickCheck $ \(TestMap m1) (TestMap m2) ->
      let u = M.intersectionWith op m1 m2 :: M.Map SmallKey Int
      in u == (op <$> m1 <*> m2)

  log "difference"
  quickCheck $ \(TestMap m1) (TestMap m2) ->
    let d = M.difference (m1 :: M.Map SmallKey Int) (m2 :: M.Map SmallKey String)
    in and (map (\k -> M.member k m1) (A.fromFoldable $ M.keys d)) &&
       and (map (\k -> not $ M.member k d) (A.fromFoldable $ M.keys m2))

  log "size"
  quickCheck $ \xs ->
    let xs' = nubBy (compare `on` fst) xs
    in  M.size (M.fromFoldable xs') == length (xs' :: List (Tuple SmallKey Int))

  log "lookupLE result is correct"
  quickCheck $ \k (TestMap m) -> case M.lookupLE k (smallKeyToNumberMap m) of
    Nothing -> all (_ > k) $ M.keys m
    Just { key: k1, value: v } -> let
      isCloserKey k2 = k1 < k2 && k2 < k
      isLTwhenEQexists = k1 < k && M.member k m
      in   k1 <= k
        && all (not <<< isCloserKey) (M.keys m)
        && not isLTwhenEQexists
        && M.lookup k1 m == Just v

  log "lookupGE result is correct"
  quickCheck $ \k (TestMap m) -> case M.lookupGE k (smallKeyToNumberMap m) of
    Nothing -> all (_ < k) $ M.keys m
    Just { key: k1, value: v } -> let
      isCloserKey k2 = k < k2 && k2 < k1
      isGTwhenEQexists = k < k1 && M.member k m
      in   k1 >= k
        && all (not <<< isCloserKey) (M.keys m)
        && not isGTwhenEQexists
        && M.lookup k1 m == Just v

  log "lookupLT result is correct"
  quickCheck $ \k (TestMap m) -> case M.lookupLT k (smallKeyToNumberMap m) of
    Nothing -> all (_ >= k) $ M.keys m
    Just { key: k1, value: v } -> let
      isCloserKey k2 = k1 < k2 && k2 < k
      in   k1 < k
        && all (not <<< isCloserKey) (M.keys m)
        && M.lookup k1 m == Just v

  log "lookupGT result is correct"
  quickCheck $ \k (TestMap m) -> case M.lookupGT k (smallKeyToNumberMap m) of
    Nothing -> all (_ <= k) $ M.keys m
    Just { key: k1, value: v } -> let
      isCloserKey k2 = k < k2 && k2 < k1
      in   k1 > k
        && all (not <<< isCloserKey) (M.keys m)
        && M.lookup k1 m == Just v

  log "findMin result is correct"
  quickCheck $ \(TestMap m) -> case M.findMin (smallKeyToNumberMap m) of
    Nothing -> M.isEmpty m
    Just { key: k, value: v } -> M.lookup k m == Just v && all (_ >= k) (M.keys m)

  log "findMax result is correct"
  quickCheck $ \(TestMap m) -> case M.findMax (smallKeyToNumberMap m) of
    Nothing -> M.isEmpty m
    Just { key: k, value: v } -> M.lookup k m == Just v && all (_ <= k) (M.keys m)

  log "mapWithKey is correct"
  quickCheck $ \(TestMap m :: TestMap String Int) -> let
    f k v = k <> show v
    resultViaMapWithKey = m # mapWithIndex f
    toList = M.toUnfoldable :: forall k v. M.Map k v -> List (Tuple k v)
    resultViaLists = m # toList # map (\(Tuple k v) → Tuple k (f k v)) # M.fromFoldable
    in resultViaMapWithKey === resultViaLists

  log "filterWithKey gives submap"
  quickCheck $ \(TestMap s :: TestMap String Int) p ->
                 M.isSubmap (M.filterWithKey p s) s

  log "filterWithKey keeps those keys for which predicate is true"
  quickCheck $ \(TestMap s :: TestMap String Int) p ->
                 all (uncurry p) (M.toUnfoldable (M.filterWithKey p s) :: Array (Tuple String Int))

  log "filterKeys gives submap"
  quickCheck $ \(TestMap s :: TestMap String Int) p ->
                 M.isSubmap (M.filterKeys p s) s

  log "filterKeys keeps those keys for which predicate is true"
  quickCheck $ \(TestMap s :: TestMap String Int) p ->
                 all p (M.keys (M.filterKeys p s))

  log "filter gives submap"
  quickCheck $ \(TestMap s :: TestMap String Int) p ->
                 M.isSubmap (M.filter p s) s

  log "filter keeps those values for which predicate is true"
  quickCheck $ \(TestMap s :: TestMap String Int) p ->
                 all p (M.values (M.filter p s))

  log "submap with no bounds = id"
  quickCheck \(TestMap m :: TestMap SmallKey Int) ->
    M.submap Nothing Nothing m === m

  log "submap with lower bound"
  quickCheck' 1 $
    M.submap (Just B) Nothing (M.fromFoldable [Tuple A 0, Tuple B 0])
    == M.fromFoldable [Tuple B 0]

  log "submap with upper bound"
  quickCheck' 1 $
    M.submap Nothing (Just A) (M.fromFoldable [Tuple A 0, Tuple B 0])
    == M.fromFoldable [Tuple A 0]

  log "submap with lower & upper bound"
  quickCheck' 1 $
    M.submap (Just B) (Just B) (M.fromFoldable [Tuple A 0, Tuple B 0, Tuple C 0])
    == M.fromFoldable [Tuple B 0]

  log "submap"
  quickCheck' 1000 \(TestMap m :: TestMap SmallKey Int) mmin mmax key ->
    let
      m' = M.submap mmin mmax m
    in
      (if (maybe true (\min -> min <= key) mmin &&
          maybe true (\max -> max >= key) mmax)
        then M.lookup key m == M.lookup key m'
        else (not (M.member key m')))
      <?> "m: " <> show m
       <> ", mmin: " <> show mmin
       <> ", mmax: " <> show mmax
       <> ", key: " <> show key

  log "foldrWithIndex maintains order"
  quickCheck \(TestMap m :: TestMap Int Int) ->
    let outList = foldrWithIndex (\i a b -> (Tuple i a) : b) Nil m
    in outList == sort outList

  log "bind"
  quickCheck $ \(TestMap m1) (TestMap m2 :: TestMap SmallKey Int) (TestMap m3) k ->
    let
      u = do
        v <- m1
        if v then m2 else m3
    in case M.lookup k m1 of
      Just true -> M.lookup k m2 == M.lookup k u
      Just false -> M.lookup k m3 == M.lookup k u
      Nothing -> not $ M.member k u

  log "catMaybes creates a new map of size less than or equal to the original"
  quickCheck \(TestMap m :: TestMap Int (Maybe Int)) -> do
    let result = M.catMaybes m
    M.size result <=? M.size m

  log "catMaybes drops key/value pairs with Nothing values"
  quickCheck \(TestMap m :: TestMap Int Int) -> do
    let maybeMap = M.alter (const $ Just Nothing) 1 $ map Just m
    let result = M.catMaybes maybeMap
    let expected = M.delete 1 m
    result === expected

  log "SemigroupMap's Semigroup instance is based on value's Semigroup instance"
  quickCheck \(Tuple leftStr rightStr :: Tuple String String) -> do
    let key = "foo"
    let left = smSingleton key leftStr
    let right = smSingleton key rightStr
    let result = left <> right
    let expected = smSingleton key $ leftStr <> rightStr
    result == expected
  quickCheck \(Tuple leftStr rightStr :: Tuple String String) -> do
    let key = "foo"
    let left = smSingleton key $ First leftStr
    let right = smSingleton key $ First rightStr
    let result = left <> right
    result == left
  quickCheck \(Tuple leftStr rightStr :: Tuple String String) -> do
    let key = "foo"
    let left = smSingleton key $ Last leftStr
    let right = smSingleton key $ Last rightStr
    let result = left <> right
    result == right

smSingleton :: forall key value. key -> value -> M.SemigroupMap key value
smSingleton k v = M.SemigroupMap (M.singleton k v)