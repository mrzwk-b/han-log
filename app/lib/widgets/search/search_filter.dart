enum SearchCategory {morpheme, word, character, none}

class SearchFilter {
  SearchCategory searchCategory;
  Map<String, dynamic> filtersMap;
  SearchFilter({
    this.searchCategory = SearchCategory.none,
    this.filtersMap = const {},
  });
}