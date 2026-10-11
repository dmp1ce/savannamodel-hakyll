--------------------------------------------------------------------------------
-- quote-check: validate quotes/*.html citations using the site's own parsing.
--
-- Complements scripts/verify_quotes.py in savannamodel-info (which checks
-- quote text against the extracted book pages). This executable checks what
-- the site itself parses at build time: every quote file must have a valid
-- frontmatter with a known 'book' and a numeric 'page', plus a non-empty
-- body; and every (book, page) pair must resolve to a chapter from
-- sources/chapters.json.
--
-- Run from the repo root:  stack exec -- quote-check
--------------------------------------------------------------------------------
module Main (main) where



import           Data.Aeson (FromJSON, decode)
import qualified Data.ByteString.Lazy as BSL
import           Data.List (sort)
import qualified Data.Map as Map
import           Data.Maybe (isJust)
import           GHC.Generics (Generic)
import           Hakyll.Core.Metadata (lookupString)
import           Hakyll.Core.Provider.Metadata (parsePage)
import           System.Directory (listDirectory)
import           System.Environment (getArgs)
import           System.Exit (exitFailure)
import           System.FilePath ((</>), takeExtension)
import           Text.Read (readMaybe)



validBooks :: [String]
validBooks = ["Deadly Harvest", "Paleo in a Nutshell"]



data Chapter = Chapter
  { chapter  :: String
  , start    :: Int
  } deriving (Generic, Show)

instance FromJSON Chapter

loadChapters :: IO (Maybe (Map.Map String [Chapter]))
loadChapters = decode <$> BSL.readFile "sources/chapters.json"

-- | Resolve the chapter title a printed page belongs to, or Nothing if
-- the page falls outside every chapter.
chapterFor :: String -> Int -> IO (Maybe String)
chapterFor book page = do
  mchapters <- loadChapters
  return $ do
    chapters <- Map.lookup book =<< mchapters
    case [c | c <- chapters, start c <= page] of
      []  -> Nothing
      cs  -> Just (chapter (last cs))



main :: IO ()
main = do
  args <- getArgs
  let dir = case args of
        (a : _) -> a
        []      -> "quotes"
  files <- sort <$> listDirectory dir
  let nonHtml = [f | f <- files, takeExtension f /= ".html"]
      htmlFiles = [f | f <- files, takeExtension f == ".html"]
  problems <- concat <$> mapM (checkQuote dir) htmlFiles
  let problems' = problems ++ [f ++ ": not a .html file" | f <- nonHtml]
  if null problems'
    then putStrLn ("quote-check: " ++ show (length htmlFiles) ++ " quotes OK")
    else do
      mapM_ putStrLn problems'
      putStrLn ("quote-check: " ++ show (length problems')
                ++ " problem(s) in " ++ show (length htmlFiles) ++ " quotes")
      exitFailure

checkQuote :: FilePath -> FilePath -> IO [String]
checkQuote dir file = do
  raw <- readFile (dir </> file)
  case parsePage raw of
    Left err -> return [file ++ ": does not parse: " ++ show err]
    Right (meta, body) -> do
      let problems = map (\p -> file ++ ": " ++ p)
                (bookProblems meta ++ pageProblems meta ++ bodyProblems body)
      chapterProbs <- chapterProblems meta
      return (problems ++ chapterProbs)
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
    chapterProblems meta =
      case (lookupString "book" meta, lookupString "page" meta >>= readMaybeInt) of
        (Just b, Just n) -> do
          mchapter <- chapterFor b n
          return ["no chapter covers page " ++ show n ++ " in " ++ b | not (isJust mchapter)]
        _ -> return []
    readMaybeInt :: String -> Maybe Int
    readMaybeInt = readMaybe
    bodyProblems :: String -> [String]
    bodyProblems body = [ "empty body" | all (`elem` (" \t\r\n" :: String)) body ]
