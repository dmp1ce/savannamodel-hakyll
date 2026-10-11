--------------------------------------------------------------------------------
-- quote-check: validate quotes/*.html citations using the site's own parsing.
--
-- Complements scripts/verify_quotes.py in savannamodel-info (which checks
-- quote text against the extracted book pages). This executable checks what
-- the site itself parses at build time: every quote file must have a valid
-- frontmatter with a known 'book' and a numeric 'page', plus a non-empty body.
--
-- Run from the repo root:  stack exec -- quote-check
--------------------------------------------------------------------------------
module Main (main) where


import           Data.List (sort)
import           Hakyll.Core.Metadata (lookupString)
import           Hakyll.Core.Provider.Metadata (parsePage)
import           System.Directory (listDirectory)
import           System.Environment (getArgs)
import           System.Exit (exitFailure)
import           System.FilePath ((</>), takeExtension)
import           Text.Read (readMaybe)


validBooks :: [String]
validBooks = ["Deadly Harvest", "Paleo in a Nutshell"]

main :: IO ()
main = do
  args <- getArgs
  let dir = case args of
        (a : _) -> a
        []      -> "quotes"
  files <- sort . filter (\f -> takeExtension f == ".html") <$> listDirectory dir
  problems <- concat <$> mapM (checkQuote dir) files
  if null problems
    then putStrLn ("quote-check: " ++ show (length files) ++ " quotes OK")
    else do
      mapM_ putStrLn problems
      putStrLn ("quote-check: " ++ show (length problems) ++ " problem(s) in "
                ++ show (length files) ++ " quotes")
      exitFailure

checkQuote :: FilePath -> FilePath -> IO [String]
checkQuote dir file = do
  raw <- readFile (dir </> file)
  return $ case parsePage raw of
    Left err -> [file ++ ": does not parse: " ++ show err]
    Right (meta, body) ->
      map (\p -> file ++ ": " ++ p)
        (bookProblems meta ++ pageProblems meta ++ bodyProblems body)
  where
    bookProblems meta = case lookupString "book" meta of
      Nothing -> ["missing 'book' field"]
      Just b
        | b `notElem` validBooks -> ["unknown book '" ++ b ++ "'"]
        | otherwise -> []
    pageProblems meta = case lookupString "page" meta of
      Nothing -> ["missing 'page' field"]
      Just p -> case readMaybe p :: Maybe Int of
        Just n | n > 0 -> []
        _ -> ["non-numeric or non-positive 'page' field: " ++ show p]
    bodyProblems :: String -> [String]
    bodyProblems body = [ "empty body" | all (`elem` (" \t\r\n" :: String)) body ]
