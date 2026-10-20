{-# LANGUAGE DeriveGeneric #-}
module Main where

--------------------------------------------------------------------------------
import           Control.Monad (filterM, forM, when)
import           Data.Aeson (FromJSON, decode, encode, object, (.=))
import qualified Data.ByteString.Lazy as BSL
import qualified Data.ByteString as BS
import qualified Data.Text as T
import qualified Data.Text.Encoding as TE
import           Data.List (sortOn, intercalate, uncons, groupBy)
import qualified Data.Map as Map
import           Data.Maybe (fromMaybe, maybeToList)
import           GHC.Generics (Generic)
import           System.FilePath (dropExtension, takeDirectory, takeFileName, splitDirectories, joinPath)
import           Text.Read (readMaybe)
import           Hakyll

--------------------------------------------------------------------------------
main :: IO ()
main = hakyll $ do
    match "images/*" $ do
        route   idRoute
        compile copyFileCompiler

    match "semantic/dist/**" $ do
        route   idRoute
        compile copyFileCompiler

    -- Dump github files in `/` directory
    match "github/*" $ do
      route $ customRoute (takeFileName . toFilePath)
      compile copyFileCompiler

    -- Favicon and app icons served from `/`
    match "icons/*" $ do
      route $ customRoute (takeFileName . toFilePath)
      compile copyFileCompiler

    match "about.markdown" $ pageRules "page-about"
    match "changelog.markdown" $ pageRules "page-changelog"

    match (complement "foods/**/metadata" .&&. "foods/**") $ do
      route $ setExtension "html"
      compile $ do

        -- Get color context
        colorCategories <- getUnderlying >>= getCategory'
        (color, cats) <- maybe (fail "no color category in food path") return (uncons colorCategories)
        colorItem <- applyAsTemplate (constField "color" color)
                     =<< load (fromFilePath $ "colors/sections/" ++ color ++ ".html")
        colorQuotes <- loadAll $ fromGlob $ "colors/sections/" ++ joinPath (color : cats) ++ "/*"

        -- Get quotes context
        mFoodtag <- getUnderlying >>= flip getMetadataField "foodtag"
        quotes <- case mFoodtag of
          Just foodtag -> filterQuotes foodtag =<< loadAll "quotes/*"
          Nothing -> return []
        let foodCtx =
                siteVersion <>
                defaultContext <>
                constField "color" color <>
                constField "food-categories" (intercalate ", " cats) <>
                (constField "color-section" . itemBody) colorItem <>
                (if null quotes then mempty
                   else listField "quotes" quoteContext (sortQuotes quotes)) <>
                (if null colorQuotes then mempty
                   else listField "color-quotes" quoteContext (sortQuotes colorQuotes))

        pandocCompiler
          >>= loadAndApplyTemplate "templates/food.html"    foodCtx
          >>= loadAndApplyTemplate "templates/default.html" foodCtx
          >>= relativizeUrls

    match "foods.html" $ do
        route idRoute
        compile $ do
          let foodsCtx =
                constField "page-foods" "" <>
                siteVersion <>
                listField "food-color-sections" defaultContext loadFoodTable <>
                defaultContext

          getResourceBody
            >>= applyAsTemplate foodsCtx
            >>= loadAndApplyTemplate "templates/default.html" foodsCtx
            >>= relativizeUrls

    match "sources.html" $ do
        route idRoute
        compile $ do
          let sourcesCtx =
                  constField "page-sources" "" <>
                  siteVersion <>
                  listField "source-books" defaultContext buildSourceBooks <>
                  defaultContext

          getResourceBody
            >>= applyAsTemplate sourcesCtx
            >>= loadAndApplyTemplate "templates/default.html" sourcesCtx
            >>= relativizeUrls

    create ["data/foods.json"] $ do
        route   idRoute
        compile (buildFoodsJson >>= makeItem)

    create ["data/quotes.json"] $ do
        route   idRoute
        compile (buildQuotesJson >>= makeItem)

    match "index.html" $ do
        route idRoute
        compile $ do
            let indexCtx =
                    constField "page-home" "" <>
                    siteVersion <>
                    defaultContext

            getResourceBody
                >>= applyAsTemplate indexCtx
                >>= loadAndApplyTemplate "templates/default.html" indexCtx
                >>= relativizeUrls

    match "search.html" $ do
        route idRoute
        compile $ do
            let searchCtx =
                    constField "page-search" "" <>
                    siteVersion <>
                    defaultContext

            getResourceBody
                >>= applyAsTemplate searchCtx
                >>= loadAndApplyTemplate "templates/default.html" searchCtx
                >>= relativizeUrls

    match "faq.html" $ do
        route idRoute
        compile $ do
            faqItems <- loadAll "faq/*"
            categories <- buildFaqCategories faqItems
            let faqCtx =
                    constField "page-faq" "" <>
                    siteVersion <>
                    listField "faq-categories" defaultContext (return categories) <>
                    defaultContext

            getResourceBody
                >>= applyAsTemplate faqCtx
                >>= loadAndApplyTemplate "templates/default.html" faqCtx
                >>= relativizeUrls

    match "templates/*" $ compile templateBodyCompiler
    match "foods/**/metadata" $ compile templateCompiler
    match "quotes/*" $ compile getResourceBody
    match "colors/sections/**" $ compile getResourceBody
    match "faq/*" $ compile getResourceBody

-- | Obtain categories from a page. Modified from Hakyll function with the same name.
getCategory' :: MonadMetadata m => Identifier -> m [String]
getCategory' = return . tail' . splitDirectories . takeDirectory . toFilePath
  where tail' (_:xs) = xs; tail' _ = []


-- | Sort quotes
sortQuotes :: MonadMetadata m => [Item a] -> m [Item a]
sortQuotes is = do
  meta <- mapM (\i -> do
                  book <- getMetadataField (itemIdentifier i) "book"
                  page <- getMetadataField (itemIdentifier i) "page"
                  ord <- getMetadataField (itemIdentifier i) "ord"
                  let page' = readMaybe =<< page
                      ord' = readMaybe =<< ord
                  return (QuoteMetadata book page' ord',i)
              ) is
  return $ map snd $ sortOn fst meta

-- | Prioritize "Paleo in a Nutshell" first because it is a newer book.
data QuoteMetadata = QuoteMetadata (Maybe String) (Maybe Int) (Maybe Int) deriving Eq
instance Ord QuoteMetadata where
  (<=) (QuoteMetadata (Just "Paleo in a Nutshell") _ _) (QuoteMetadata (Just "Deadly Harvest") _ _) = True
  (<=) (QuoteMetadata (Just "Deadly Harvest") _ _) (QuoteMetadata (Just "Paleo in a Nutshell") _ _) = False
  (<=) (QuoteMetadata (Just "The Bond Briefing") _ _) _ = True
  (<=) _ (QuoteMetadata (Just "The Bond Briefing") _ _) = False
  (<=) (QuoteMetadata _ i o) (QuoteMetadata _ i' o') = if i == i' then o <= o' else i <= i'

-- | Return only quotes which are tagged with food name
filterQuotes :: MonadMetadata m => String -> [Item a] -> m [Item a]
filterQuotes foodtag ids =
  let f :: MonadMetadata m => String -> Item a -> m Bool
      f fn (Item i _) = do
        tags <- getTags i
        return $ elem fn tags
  in filterM (f foodtag) ids


--------------------------------------------------------------------------------
-- Chapter map from sources/chapters.json

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


--------------------------------------------------------------------------------
-- Quote rendering

-- | Quote fields used wherever a quote is rendered: $chapter$ (from
-- the chapter map) and $anchor$ (stable id for /sources.html links).
-- | Stable id for /sources.html links.
anchorOf :: Item a -> String
anchorOf = dropExtension . takeFileName . toFilePath . itemIdentifier

quoteContext :: Context String
quoteContext =
    defaultContext <>
    field "chapter" resolveChapter <>
    field "anchor" (return . anchorOf)
  where
    resolveChapter item = do
      missue <- getMetadataField (itemIdentifier item) "issue"
      case missue of
        Just issue -> return issue
        Nothing -> do
          book <- fromMaybe "" <$> getMetadataField (itemIdentifier item) "book"
          page <- getMetadataField (itemIdentifier item) "page"
          let ident = toFilePath (itemIdentifier item)
          case readMaybe =<< page of
            Just p -> do
              mchapter <- unsafeCompiler (chapterFor book p)
              maybe (fail (ident ++ ": no chapter for page " ++ show p)) return mchapter
            Nothing -> fail (ident ++ ": invalid 'page' field")


--------------------------------------------------------------------------------
-- Source browser (/sources.html)

sourceBookOrder :: [String]
sourceBookOrder = ["Paleo in a Nutshell", "Deadly Harvest", "The Bond Briefing"]

-- | Build one rendered section per book, each containing its chapters
-- and their quotes, each quote with back-links to its food pages.
buildSourceBooks :: Compiler [Item String]
buildSourceBooks = do
  foods <- loadAll (complement "foods/**/metadata" .&&. "foods/**")
  foodsByTag <- concat <$> mapM (\f -> do
      mtag <- getMetadataField (itemIdentifier f) "foodtag"
      return [(t, f) | t <- maybeToList mtag]) foods
  quotes <- sortQuotes =<< loadAll "quotes/*"
  quoteTriples <- forM quotes $ \q -> do
      book <- getMetadataField (itemIdentifier q) "book"
      page <- getMetadataField (itemIdentifier q) "page"
      return (book, readMaybe =<< page, q)
  mchapters <- unsafeCompiler loadChapters
  chaptersMap <- maybe (fail "sources/chapters.json missing or invalid") return mchapters
  forM sourceBookOrder $ \book ->
    if book == "The Bond Briefing"
      then do
        let bookQuotes = [q | (Just b, _, q) <- quoteTriples, b == book]
        issues <- mapM (\q -> fromMaybe "Newsletter" <$> getMetadataField (itemIdentifier q) "issue")
                       bookQuotes
        let sortedPairs = sortOn fst (zip issues bookQuotes)
            issueGroups = [ (maybe "" (fst . fst) (uncons gp), map snd gp)
                         | gp <- groupBy (\a b -> fst a == fst b) sortedPairs ]
        buildBriefingSections foodsByTag issueGroups
      else do
        let chapters = Map.findWithDefault [] book chaptersMap
            chapterRanges = zip chapters (drop 1 (map start chapters) ++ [maxBound])
            bookQuotes = [(p, q) | (Just b, Just p, q) <- quoteTriples, b == book]
            chapterQuoteLists = [ [q | (p, q) <- bookQuotes, start c <= p, p < next]
                               | (c, next) <- chapterRanges ]
        when (sum (map length chapterQuoteLists) /= length bookQuotes) $
          fail (book ++ ": some quotes fall outside every chapter")
        let chapterGroups = [ (chapter c, qs)
                            | ((c, _), qs) <- zip chapterRanges chapterQuoteLists
                            , not (null qs) ]
        buildBookSections book foodsByTag chapterGroups

buildBookSections :: String -> [(String, Item String)] -> [(String, [Item String])]
                  -> Compiler (Item String)
buildBookSections book foodsByTag chapterGroups = do
    chapterItems <- forM chapterGroups $ \(cname, qs) -> do
      quoteItems <- mapM (buildQuoteItem foodsByTag) qs
      let ctx = constField "chapter" cname
                <> listField "chapter-quotes" defaultContext (return quoteItems)
                <> defaultContext
      makeItem "" >>= loadAndApplyTemplate "templates/sources-chapter.html" ctx
    let ctx = constField "book" book
              <> listField "source-chapters" defaultContext (return chapterItems)
              <> defaultContext
    makeItem "" >>= loadAndApplyTemplate "templates/sources-book.html" ctx

-- | Newsletter issues on the source browser: one section per issue.
buildBriefingSections :: [(String, Item String)] -> [(String, [Item String])]
                      -> Compiler (Item String)
buildBriefingSections foodsByTag issueGroups = do
    chapterItems <- forM issueGroups $ \(iss, qs) -> do
      quoteItems <- mapM (buildQuoteItem foodsByTag) qs
      let ctx = constField "chapter" iss
                <> listField "chapter-quotes" defaultContext (return quoteItems)
                <> defaultContext
      makeItem "" >>= loadAndApplyTemplate "templates/sources-chapter.html" ctx
    let ctx = constField "book" "The Bond Briefing"
              <> listField "source-chapters" defaultContext (return chapterItems)
              <> defaultContext
    makeItem "" >>= loadAndApplyTemplate "templates/sources-book.html" ctx

-- | Render one quote for the source browser: the passage, its
-- citation, and back-links to the food pages tagged with it.  The
-- template is applied to the quote item itself so metadata fields
-- ($book$, $page$) resolve against the quote.
buildQuoteItem :: [(String, Item String)] -> Item String -> Compiler (Item String)
buildQuoteItem foodsByTag q = do
  tags <- getTags (itemIdentifier q)
  let fs = [f | t <- tags, (t2, f) <- foodsByTag, t == t2]
  foodItems <- mapM (loadAndApplyTemplate "templates/sources-food.html" defaultContext) fs
  let ctx = quoteContext <> listField "related-foods" defaultContext (return foodItems)
  loadAndApplyTemplate "templates/sources-quote.html" ctx q


--------------------------------------------------------------------------------
-- FAQ (/faq.html): one category section per newsletter Q&A topic

-- | Category slug -> display name, in display order.
faqCategories :: [(String, String)]
faqCategories =
    [ ("salt",        "Salt & Electrolytes")
    , ("water",       "Water & Hydration")
    , ("protein",     "Protein & Meat")
    , ("supplements", "Supplements & Vitamins")
    , ("fats",        "Fats & Oils")
    , ("sugar",       "Sugar & Sweeteners")
    , ("grains",      "Grains & Breads")
    , ("dairy",       "Dairy")
    , ("produce",     "Fruits & Vegetables")
    ]

faqEntryContext :: Context String
faqEntryContext =
    metaField "question" <>
    metaField "source" <>
    field "slug" (return . dropExtension . takeFileName . toFilePath . itemIdentifier) <>
    bodyField "body"
  where
    metaField k = field k (\i -> fromMaybe "" <$> getMetadataField (itemIdentifier i) k)

buildFaqCategories :: [Item String] -> Compiler [Item String]
buildFaqCategories faqs = do
  let faqPath i = dropExtension . takeFileName . toFilePath $ itemIdentifier i
  faqsBySlug <- Map.fromListWith (++) <$>
      mapM (\i -> do
              cat <- getMetadataField (itemIdentifier i) "category"
              return (fromMaybe "" cat, [i])) faqs
  forM faqCategories $ \(slug, name) -> do
    let entries = sortOn faqPath (Map.findWithDefault [] slug faqsBySlug)
    let ctx = constField "faq-category-slug" slug
              <> constField "faq-category-name" name
              <> listField "faq-entries" faqEntryContext (return entries)
              <> defaultContext
    makeItem "" >>= loadAndApplyTemplate "templates/faq-category.html" ctx

--------------------------------------------------------------------------------
-- JSON data feeds (/data/foods.json, /data/quotes.json)

-- | One entry per food page: name, tier, full category path, URL,
-- and the foodtag used to match quotes.
buildFoodsJson :: Compiler String
buildFoodsJson = do
  foods <- loadAll (complement "foods/**/metadata" .&&. "foods/**") :: Compiler [Item String]
  tierMeta <- getAllMetadata "foods/*/metadata"
  let tierSorts = [ (last (splitDirectories (takeDirectory (toFilePath i)))
                    , fromMaybe 100 (sortMetadata m))
                  | (i, m) <- tierMeta ]
  rows <- forM foods $ \f -> do
    cats <- getCategory' (itemIdentifier f)
    mtitle <- getMetadataField (itemIdentifier f) "title"
    mtag <- getMetadataField (itemIdentifier f) "foodtag"
    mroute <- getRoute (itemIdentifier f)
    let routed = fromMaybe "/" mroute
        title = fromMaybe (dropExtension . takeFileName $ routed) mtitle
    let (tier, sortKey) = case cats of
          (t:_) -> (t, (fromMaybe 100 (lookup t tierSorts), cats, title))
          []    -> ("", (100, [], title))
    return (sortKey, object
      [ "name" .= title
      , "tier" .= tier
      , "category" .= cats
      , "url" .= maybe "/" ("/" ++) mroute
      , "foodtag" .= mtag
      ])
  return (T.unpack (TE.decodeUtf8 (BS.toStrict (encode (map snd (sortOn fst rows))))))

-- | One entry per quote: book, chapter, page, tags, body, and a
-- stable link into the source browser.
buildQuotesJson :: Compiler String
buildQuotesJson = do
  quotes <- sortQuotes =<< loadAll "quotes/*" :: Compiler [Item String]
  rows <- forM quotes $ \q -> do
      let ident = toFilePath (itemIdentifier q)
      book <- fromMaybe "" <$> getMetadataField (itemIdentifier q) "book"
      mpage <- getMetadataField (itemIdentifier q) "page"
      tags <- getTags (itemIdentifier q)
      page <- maybe (fail (ident ++ ": invalid 'page' field"))
                    return (readMaybe =<< mpage) :: Compiler Int
      chapterTitle <- do
        missue <- getMetadataField (itemIdentifier q) "issue"
        case missue of
          Just issue -> return issue
          Nothing -> do
            mchapter <- unsafeCompiler (chapterFor book page)
            maybe (fail (ident ++ ": no chapter for page " ++ show page)) return mchapter
      let anchor = anchorOf q
      return $ object
        [ "book" .= book
        , "page" .= page
        , "chapter" .= chapterTitle
        , "tags" .= tags
        , "anchor" .= anchor
        , "url" .= ("/sources.html#" ++ anchor)
        , "body" .= itemBody q
        ]
  return (T.unpack (TE.decodeUtf8 (BS.toStrict (encode rows))))

pageRules :: String -> Rules ()
pageRules pageLabel = do
      let ctx = constField pageLabel "" <>
                siteVersion <>
                defaultContext

      route   $ setExtension "html"
      compile $ pandocCompiler
        >>= loadAndApplyTemplate "templates/default.html" ctx
        >>= relativizeUrls

-- | Site version read from the VERSION file, displayed in the site footer.
siteVersion :: Context a
siteVersion = field "site-version" $ \_ ->
  unsafeCompiler $ takeWhile (/= '\n') <$> readFile "VERSION"

loadFoodTable :: Compiler [Item String]
loadFoodTable = do
  colorMetadata <- getAllMetadata "foods/*/metadata"
  mapM (\(i, m) ->
          makeItem "" >>=
          loadAndApplyTemplate "templates/foods-color-section.html" (foodColorSectionCtx i m)
       ) $ sortOn (\(_, m) ->  sortMetadata m) colorMetadata

foodColorSectionCtx :: Identifier -> Metadata -> Context String
foodColorSectionCtx i m =
  let color = fromMaybe "pink" $ lookupString "css-class" m
  in constField "color-header" (fromMaybe ("Missing header in " ++ show i) $ lookupString "header" m)
  <> constField "color-class" color
  <> listField "food-categories" defaultContext
     (loadFoodCategories color (takeDirectory $ toFilePath i) "templates/food-category-section.html")
  <> defaultContext

loadFoodCategories :: String -> FilePath -> Identifier -> Compiler [Item String]
loadFoodCategories color d t = do
  let r = fromGlob $ d ++ "/*/metadata"
  categoryMetadata <- getAllMetadata r
  mapM (\(i, m) ->
          makeItem "" >>=
          (\item -> do
              let d' = takeDirectory $ toFilePath i
              mainFoodSection <- loadAll $ complement "foods/**/metadata" .&&. fromGlob (d' ++ "/*") :: Compiler [Item String]
              let mMainFoodSection = if null mainFoodSection then Nothing else Just mainFoodSection
              secondaryFoodSection <- loadFoodCategories color (takeDirectory $ toFilePath i) "templates/food-category-section-partial.html" :: Compiler [Item String]
              let mSecondaryFoodSection = if null secondaryFoodSection then Nothing else Just secondaryFoodSection
              loadAndApplyTemplate t (foodCategorySectionCtx color i m mMainFoodSection mSecondaryFoodSection) item
          )
       ) $ sortOn (\(_, m) -> sortMetadata m) categoryMetadata

foodCategorySectionCtx :: String -> Identifier -> Metadata -> Maybe [Item String] -> Maybe [Item String] -> Context String
foodCategorySectionCtx color i m mFoodSection mSecondaryFoodSection =
  let primary = maybe mempty (listField "section-category-foods" defaultContext . return) mFoodSection
      secondary = maybe mempty (listField "secondary-categories" defaultContext . return) mSecondaryFoodSection
  in constField "section-header" (fromMaybe ("Missing category header in " ++ show i) $ lookupString "header" m)
  <> constField "css-class" color
  <> primary
  <> secondary
  <> defaultContext

sortMetadata :: Metadata -> Maybe Integer
sortMetadata m = lookupString "sort" m >>= readMaybe
