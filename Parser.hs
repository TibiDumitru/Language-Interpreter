-- Dumitru Andrei-Tiberiu 321CB

module Parser
where

import Util
import Data.Maybe
import InferenceDataType
import ClassState
import qualified Data.List as List

data Class = Class { name :: String
                   , parent :: String
                   , info :: ClassState
                   } deriving Show
-- Definire Program - lista de clase
type Program = [Class]
type Instruction = String

initEmptyProgram :: Program
initEmptyProgram = []

getVars :: Program -> [[String]]
getVars [] = []
getVars (e:container) = if (name e) == "Global"
                           then getValues (info e) Var
                           else getVars container

getClasses :: Program -> [String]
getClasses [] = []
getClasses (e:container) = (name e) : getClasses container

getParentClass :: String -> Program -> String
getParentClass className [] = []
getParentClass className (e:container) = if (name e) == className
                                            then (parent e)
                                            else getParentClass className container

getFuncsForClass :: String -> Program -> [[String]]
getFuncsForClass className [] = []
getFuncsForClass className (e:container) = if (name e) == className
                                              then getValues (info e) Func
                                              else getFuncsForClass className container

-- Instruction este o linie din input, un String ce reprezinta o comanda
parse :: String -> [Instruction]
parse input = List.lines input

-- Transforma caracterul ch in ' '
trsf :: Char -> String -> String
trsf ch s = map (\c->if c == ch then ' ' else c) s

{- | Transformare necesara pentru prelucrarea unei functii
   | Pune spatii unde intalneste ':', ',', '(' si ')' pentru ca definitia unei functii
   sa fie usor de prelucrat 
-}
trsf2 :: String -> String
trsf2 = (trsf ':').(trsf ',').(trsf '(').(trsf ')')

parseParam :: String -> [Expr] -> [Expr]
parseParam ")" l = l
parseParam s l = if length (List.words (trsf '.' name)) == 1
                    then (Va name) : (parseParam (snd (break (== ',') s)) l)
                    else (parseExpr s) : l
    where name = head (List.words (trsf2 s))

parseExpr :: String -> Expr
parseExpr s = FCall var f param
    where var = head (List.words (trsf '.' s))
          f   = (trsf ',' (fst (break (== '(') (List.words (trsf '.' s) !! 1))))
          param = parseParam (snd (break (== '(') (List.words (trsf '.' s) !! 1))) []

interpret :: Instruction -> Program -> Program
-- Adauga clasa Global in Program cand face match pe un container gol
interpret instr [] = interpret instr (Class {name = "Global",
                          parent = "Global",
                          info = initEmptyClass} : [])
{- | cmd reprezinta primul cuvant dintr-o instructiune si indica modul in care trebuie
    interpretata instructiunea ("class"/"newvar"), altfel este clar ca se proceseaza
    o functie
   | arg reprezinta "argumentele" comenzii, create pentru a accesa fiecare termen
    cu usurinta
   | informatiile despre functii au fost preluate separat (difera parsarea)
-}
interpret instr container
    | length splt == 0 = container
    | cmd == "class"  = if arg1 `elem` (getClasses container)
                then container
                else if length splt == 4 && arg3 `elem` (getClasses container)
                        then Class {name = arg1,
                                   parent = arg3,
                                   info = initEmptyClass} : container
                        else Class {name = arg1,
                                   parent = "Global",
                                   info = initEmptyClass} : container
    | cmd == "newvar" = if arg2 `elem` (getClasses container)
                then map (\x->if (name x) == "Global"
                                 then Class {name = "Global",
                                             parent = "Global", 
                                             info = insertIntoClass
                                                    (info x) Var [arg1,arg2]}
                                 else x) container
                else container
    | cmd == "infer" = if infer expr container == Nothing
                          then container
                          else map (\x->if (name x) == "Global"
                                 then Class {name = "Global",
                                             parent = "Global", 
                                             info = insertIntoClass
                                                    (info x) Var [arg1, valueOf(infer expr container)]}
                                 else x) container
    | otherwise = map (\x->if (name x) == fClass && 
                              -- Tipul returnat de functie este valid
                              fReturn `elem` (getClasses container) &&
                              -- Tipurile parametrilor functiei sunt valide
                              length (filter (`elem` (getClasses container)) fParams) ==
                                                                      length fParams 
                              then Class {name = name x,
                                          parent = parent x,
                                          info = insertIntoClass
                                                 (info x) Func (fName:fReturn:fParams)}
                              else x) container
    where splt = List.words (trsf '=' instr)
          cmd = head splt
          arg1 = splt !! 1
          arg2 = splt !! 2
          arg3 = splt !! 3
          spltFunc = List.words (trsf2 instr)
          fName = spltFunc !! 2
          fClass = spltFunc !! 1
          fParams = drop 3 spltFunc
          fReturn = head spltFunc
          expr = parseExpr arg2

valueOf :: Maybe String -> String
valueOf (Just x) = x

{- | Functie care verifica daca functia f se afla in lista de functii (dupa nume) si apoi
   daca parametrii sunt corespunzatori, apeland functia checkParam
-}
auxCheck :: String -> [[String]] -> [Expr] -> Program -> Bool
auxCheck f [] param container = False
auxCheck f (e:funcs) param container = if f == (head e) && checkForParams
                     then True
                     else False || (auxCheck f funcs param container)
    where checkForParams = checkParam param (tail (tail e)) container

{- | Cauta functia data atat in clasa data ca parametru cat si pe lantul de mosteniri,
   pana cand intalneste clasa Global, caz in care nu s-a gasit nicio functie 
    corespunzatoare, deci intoarce Nothing
   | Pentru verificare unei functii se apeleaza auxCheck care verifica atat numele, 
   cat si parametrii, pentru a avea aceleasi tipuri
-}
getClassForF :: String -> String -> [Expr] -> Program -> Maybe String
getClassForF f "Global" param container = Nothing
getClassForF f cl param container = if auxCheck f funcList param container
                              then Just cl
                              else getClassForF f parent param container
    where funcList = getFuncsForClass cl container
          parent = getParentClass cl container

{- | Verifica daca fiecare expresie din lista corespunde pe rand unui parametru din 
   lista de parametrii a functiei
   | Daca numarul de expresii este diferit de numarul de parametri, se va intra pe False
   | Se realizeaza evaluarea pentru toate expresiile (utilizand chiar functia infer), iar
   rezultatul va fi bun daca toti parametrii fac match (operatorul && intre evaluari)
-}
checkParam :: [Expr] -> [String] -> Program -> Bool
checkParam [] [] container     = True
checkParam [] (x:xs) container = False
checkParam (x:xs) [] container = False
checkParam (x:expP) (y:fP) container = if (infer x container) == Nothing
                                          then False
                                          else valueOf (infer x container) == y
                                               && (checkParam expP fP container)

{- | In cazul variabilelor, se verifica daca exista in lista de variabile si apoi se
   extrage tipul corespunzator fiecareia
   | In cazul functiilor, se verifica daca variabila este una valida, adica exista deja,
   pentru a i se extrage tipul, folosind inferenta pentru variabile; in cazul in care 
   este valida, se apeleaza functia getClassForF care gaseste clasa in care se afla
   functia data, facand verificarile pentru nume si potrivirea parametrilor; in cazul
   in care nu a fost gasita nicio astfel de functie, se va returna Nothing; dupa ce a 
   fost gasita functia, se extrage valoarea de retur a functiei, acesta fiind rezultatuk
   inferentei.
-}
infer :: Expr -> Program -> Maybe String
infer (Va var) container = if var `elem` (map (head) (getVars container))
                              then  Just ((head (filter (\x->(head x) == var) 
                                         (getVars container))) !! 1)
                              else Nothing
infer (FCall var f param) container
    | infer (Va var) container == Nothing = Nothing
    | findClass == Nothing = Nothing
    | var `elem` varList = Just (head (filter (\x->head x == f) 
                                (getFuncsForClass (valueOf(findClass)) container)) !! 1)
    | otherwise = Nothing
    where varList = (map (head) (getVars container))
          findClass = getClassForF f (valueOf (infer (Va var) container)) param container

