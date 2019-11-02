-- Dumitru Andrei-Tiberiu 321CB

module ClassState
where

import qualified Data.Map as Map

-- Utilizat pentru a obține informații despre Variabile sau Funcții
data InstrType = Var | Func  deriving (Show, Eq)

-- Se definesc cheia si valoarea
type Key = [String]
type Value = InstrType
-- Se defineste ClassState ca fiind un Map
type ClassState = Map.Map Key Value

initEmptyClass :: ClassState
initEmptyClass = Map.empty

insertIntoClass :: ClassState -> InstrType -> [String] -> ClassState
insertIntoClass clasa tip expr = Map.insert expr tip clasa

getValues :: ClassState -> InstrType -> [[String]]
getValues clasa Var = Map.keys (Map.filter (== Var) clasa)
getValues clasa Func = Map.keys (Map.filter (== Func) clasa)