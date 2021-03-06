library(knitr)
library(xml2)
library(rvest)
library(dplyr)

url <- "https://raw.githubusercontent.com/thiagobodruk/biblia/master/xml/nvi.min.xml"

books <- read_xml(url) %>% 
  xml_children()

books_names <- xml_attr(books, "name")

old_testament <- books_names[1:which(books_names == "Malaquias")]

read_chapter <- function(chapter, n) {
  text <- chapter %>% 
    xml_children() %>% 
    xml_text()
  
  tibble(capitulo = n, versiculo = seq_along(text), text = text)
}

read_book <- function(book) {
  book_name <- xml_attr(book, "name")
  
  chapters <- xml_children(book)
  
  imap_dfr(chapters, ~read_chapter(.x, .y)) %>% 
    mutate(livro = book_name,
           testamento = if_else(livro %in% old_testament,
                                "Velho Testamento",
                                "Novo Testamento")) %>% 
    select(testamento, livro, everything())
}

bible <- books %>% 
  map_dfr(read_book) %>% 
  mutate(livro = factor(livro, levels = xml_attr(books, "name")))

bible <- books %>% 
  map_dfr(read_book) %>% 
  mutate(testamento = factor(testamento, levels = c("Velho Testamento",
                                                    "Novo Testamento")),
         livro = factor(livro, levels = books_names))

readr::write_csv(bible, "datasets/bible.csv")


