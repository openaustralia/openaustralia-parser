# frozen_string_literal: true

# !/usr/bin/env ruby

$:.unshift "#{File.dirname(__FILE__)}/../lib"

require "test/unit"
require "name"

class TestName < Test::Unit::TestCase
  def setup
    @matthew = Name.new(first: "Matthew", middle: "Noah", last: "Landauer")
    @joanna_gash = Name.new(first: "Joanna", last: "Gash")
  end

  def test_new
    assert_equal("Matthew", @matthew.first)
    assert_equal("Noah", @matthew.middle)
    assert_equal("Landauer", @matthew.last)
  end

  def test_new_wrong_parameters
    assert_raise(RuntimeError) { Name.new(first: "foo", blah: "dibble") }
  end

  def test_equals
    assert_equal(@matthew, Name.new(last: "Landauer", middle: "Noah", first: "Matthew"))
    assert_not_equal(@matthew, Name.new(last: "Landauer"))
  end

  def test_simple_parse
    assert_equal(@joanna_gash, Name.last_title_first("Gash Joanna"))
  end

  def test_capitals
    assert_equal(@joanna_gash, Name.last_title_first("GASH joanna"))
  end

  #  def test_comma
  #    assert_equal(@joanna_gash, Name.last_title_first("Gash, Joanna"))
  #  end

  def test_middle_name
    assert_equal(Name.new(last: "Albanese", first: "Anthony", middle: "Norman"),
                 Name.last_title_first("Albanese Anthony Norman"))
  end

  def test_two_middle_names
    assert_equal(Name.new(last: "Albanese", first: "Anthony", middle: "Norman peter"),
                 Name.last_title_first("Albanese Anthony Norman Peter"))
  end

  def test_the_hon
    assert_equal(Name.new(last: "Baird", title: "the Hon.", first: "Bruce", middle: "George"),
                 Name.last_title_first("Baird the Hon. Bruce George"))
  end

  def test_initials_last
    assert_equal(Name.new(last: "Johnson", initials: "JF"),
                 Name.last_title_first("Johnson, JF"))
  end

  def test_initials_last2
    assert_equal(Name.new(last: "Johnson", initials: "JFK"),
                 Name.last_title_first("Johnson, JFK"))
  end

  def test_nickname
    assert_equal(Name.new(last: "Abbott", title: "the Hon.", first: "Anthony", middle: "John"),
                 Name.last_title_first("ABBOTT, the Hon. Anthony (Tony) John"))
  end

  def test_dr
    assert_equal(Name.new(last: "Emerson", title: "Dr", first: "Craig", middle: "Anthony"),
                 Name.last_title_first("EMERSON, Dr Craig Anthony"))
  end

  def test_informal_name
    assert_equal("Matthew Landauer", Name.new(first: "Matthew", last: "Landauer", title: "Dr").informal_name)
  end

  def test_full_name
    name = Name.new(last: "Abbott", title: "the Hon.", first: "Anthony", middle: "John")
    assert_equal("the Hon. Anthony John Abbott", name.full_name)
  end

  def test_capitals_irish_name
    assert_equal("O'Connor", Name.new(last: "o'connor").last)
  end

  def test_capitals_scottish_name
    assert_equal("McMullan", Name.new(last: "mcmullan").last)
  end

  def test_dath
    assert_equal("D'Ath", Name.new(last: "d’ath").last)
  end

  def test_first_name_ed
    name = Name.title_first_last("Ed Husic")
    assert_equal("Husic", name.last)
    assert_equal("Ed", name.first)
  end

  def test_non_breaking_space
    # First check names without any unicode
    # assert_equal(Name.new(:title => "Mr", :first => "John", :last => "Smith"), Name.title_first_last("Mr John Smith"))
    # assert_equal(Name.new(:title => "Mr", :first => "John", :last => "Smith"), Name.last_title_first("Smith, Mr John"))
    # Now check similar names with unicode
    nbsp = [160].pack("U")
    assert_equal(Name.new(title: "Mr", first: "John", last: "Smith"), Name.title_first_last("Mr#{nbsp}John#{nbsp}Smith"))
    # assert_equal(Name.new(:title => "Mr", :first => "John", :last => "Smith"), Name.last_title_first("Smith,#{nbsp}Mr#{nbsp}John"))
  end

  def test_double_barrelled
    assert_equal("Hanson-Young", Name.new(last: "hanson-young").last)
  end

  def test_title_first_last
    assert_equal(Name.new(title: "Dr", first: "John", last: "Smith"), Name.title_first_last("Dr John Smith"))
    assert_equal(Name.new(title: "Dr", last: "Smith"), Name.title_first_last("Dr Smith"))
    assert_equal(Name.new(title: "Mr", last: "Smith"), Name.title_first_last("Mr Smith"))
    assert_equal(Name.new(title: "Mrs", last: "Smith"), Name.title_first_last("Mrs Smith"))
    assert_equal(Name.new(title: "Ms", first: "Julie", last: "Smith"), Name.title_first_last("Ms Julie Smith"))
    assert_equal(Name.new(title: "Ms", first: "Julie", middle: "Sarah Marie", last: "Smith"),
                 Name.title_first_last("Ms Julie Sarah Marie Smith"))
  end

  def test_john_debus
    # He has a title of "Hon." rather than "the Hon."
    name = Name.last_title_first("DEBUS, Hon. Robert (Bob) John")
    assert_equal("Debus", name.last)
    assert_equal("Hon.", name.title)
    assert_equal("Robert", name.first)
    assert_equal("John", name.middle)
  end

  # Deal with weirdo titles at the end
  def test_post_title
    name = Name.last_title_first("COMBET, the Hon. Gregory (Greg) Ivan, AM")
    assert_equal("Combet", name.last)
    assert_equal("the Hon.", name.title)
    assert_equal("Gregory", name.first)
    assert_equal("Ivan", name.middle)
    assert_equal("AM", name.post_title)
  end

  def test_post_title_mbe
    assert_equal(Name.new(first: "John", last: "Smith", post_title: "MBE"), Name.last_title_first("Smith, John, MBE"))
  end

  def test_post_title_qc
    assert_equal(Name.new(first: "John", last: "Smith", post_title: "QC"), Name.last_title_first("Smith, John, QC"))
  end

  def test_post_title_obe
    assert_equal(Name.new(first: "John", last: "Smith", post_title: "OBE"), Name.last_title_first("Smith, John, OBE"))
  end

  def test_post_title_ksj
    assert_equal(Name.new(first: "John", last: "Smith", post_title: "KSJ"), Name.last_title_first("Smith, John, KSJ"))
  end

  def test_post_title_jp
    assert_equal(Name.new(first: "John", last: "Smith", post_title: "JP"), Name.last_title_first("Smith, John, JP"))
  end

  def test_capilisation_on_middle_name
    assert_equal("McCahon", Name.new(middle: "mccahon").middle)
  end

  def test_ian_sinclair
    assert_equal(Name.new(last: "Sinclair", title: "the Rt Hon.", first: "Ian", middle: "McCahon"),
                 Name.last_title_first("SINCLAIR, the Rt Hon. Ian Mccahon"))
  end

  def test_two_post_titles
    assert_equal(Name.new(last: "Williams", title: "the Hon.", first: "Daryl", middle: "Robert", post_title: "AM QC"),
                 Name.last_title_first("WILLIAMS, the Hon. Daryl Robert, AM, QC"))
  end

  def test_stott_despoja
    # Difficult situation of two last names which aren't hyphenated
    assert_equal(Name.new(last: "Stott Despoja", first: "Natasha", middle: "Jessica"),
                 Name.last_title_first("STOTT DESPOJA, Natasha Jessica"))
    assert_equal(Name.new(last: "Stott Despoja", title: "Senator"),
                 Name.title_first_last("Senator STOTT DESPOJA"))
    assert_equal(Name.new(last: "Stott Despoja", first: "Natasha"),
                 Name.title_first_last("Natasha Stott Despoja"))
  end

  # Class for simple (naive) way of comparing two names. Only compares parts of the name
  # that exist in both names
  def test_matches
    dr_john_smith = Name.new(title: "Dr", first: "John", last: "Smith")
    peter_smith = Name.new(first: "Peter", last: "Smith")
    smith = Name.new(last: "Smith")
    dr_john = Name.new(title: "Dr", first: "John")
    assert(dr_john_smith.matches?(dr_john_smith))
    assert(!dr_john_smith.matches?(peter_smith))
    # When there is no overlap between the names they should not match
    assert(!smith.matches?(dr_john))
  end

  def test_nickname_after_middle_names
    assert_equal(Name.new(last: "Macdonald", title: "the Hon.", first: "John", middle: "Alexander Lindsay"),
                 Name.last_title_first("MACDONALD, the Hon. John Alexander Lindsay (Sandy)"))
  end

  # This test for the regression introduced by adding support for initials
  def test_matches_with_middle_name_missing
    name1 = Name.new(first: "Kim", middle: "William", last: "Wilkie")
    name2 = Name.new(first: "Kim", last: "Wilkie")
    assert(name1.matches?(name2))
  end

  def test_the_hon_john_howard_mp
    assert_equal(Name.title_first_last("The Hon John Howard MP"),
                 Name.new(title: "the Hon.", first: "John", last: "Howard", post_title: "MP"))
  end

  def test_senator_the_hon_nick_minchin
    assert_equal(Name.title_first_last("Senator the Hon Nick Minchin"),
                 Name.new(title: "Senator the Hon.", first: "Nick", last: "Minchin"))
  end

  def test_title_first_last_djc_kerr
    assert_equal(Name.new(initials: "DJC", last: "Kerr"), Name.title_first_last("DJC Kerr"))
  end

  def test_parsing_initials
    assert_equal(Name.new(initials: "LK", last: "Johnson"), Name.title_first_last("LK Johnson"))
  end

  def test_matches_with_first_initials
    l_johnson = Name.title_first_last("L Johnson")
    leonard_keith_johnson = Name.new(first: "Leonard", middle: "Keith", last: "Johnson")
    leslie_royston_johnson = Name.new(first: "Leslie", middle: "Royston", last: "Johnson")
    peter_francis_johnson = Name.new(first: "Peter", middle: "Francis", last: "Johnson")
    assert(!peter_francis_johnson.matches?(l_johnson))
    assert(leonard_keith_johnson.matches?(l_johnson))
    assert(leslie_royston_johnson.matches?(l_johnson))
  end

  def test_matches_with_middle_initials
    lk_johnson = Name.title_first_last("LK Johnson")
    leonard_keith_johnson = Name.new(first: "Leonard", middle: "Keith", last: "Johnson")
    leslie_royston_johnson = Name.new(first: "Leslie", middle: "Royston", last: "Johnson")

    assert(!leslie_royston_johnson.matches?(lk_johnson))
    assert(leonard_keith_johnson.matches?(lk_johnson))

    assert(lk_johnson.matches?(leonard_keith_johnson))
  end

  def test_initials
    assert_equal("DJ", Name.title_first_last("Dan John Van Manen").real_initials)
    assert_equal("JEP", Name.new(first: "John", middle: "Edward Peter").real_initials)
    assert_equal("DJ", Name.new(first: "Dan", middle: "John", last: "Van Manen").real_initials)
    assert_equal("MN", Name.new(initials: "MN").real_initials)
  end

  def test_first_initial
    assert_equal("J", Name.new(first: "John", middle: "Edward Peter").first_initial)
    assert_equal("M", Name.new(initials: "MN").first_initial)
  end

  def test_middle_initials
    assert_equal("EP", Name.new(first: "John", middle: "Edward Peter").middle_initials)
    assert_equal("N", Name.new(initials: "MN").middle_initials)
  end

  def test_another_three_letter_initial
    assert_equal(Name.new(title: "Hon.", initials: "DGH", last: "Adams"), Name.title_first_last("Hon. DGH Adams"))
    assert_equal(Name.new(title: "Hon.", initials: "DGH", last: "Adams"), Name.title_first_last("Hon. D.G.H. Adams"))
  end

  def test_lady_bjelke_petersen
    assert_equal(Name.new(last: "Bjelke-Petersen", title: "Lady"), Name.last_title_first("BJELKE-PETERSEN, Lady (Florence Isabel)"))
  end

  def test_initials_with_fullstops
    assert("DGH", Name.initials_with_fullstops("D.G.H."))
    assert("AB", Name.initials_with_fullstops("A.B."))
    assert("M", Name.initials_with_fullstops("M."))
    assert("AB", Name.initials_with_fullstops("AB."))
    assert_nil(Name.initials_with_fullstops("AB"))
    assert("", Name.initials_with_fullstops(".."))
  end

  def test_empty_name
    assert_equal(Name.new({}), Name.title_first_last(""))
    assert_equal(Name.new({}), Name.last_title_first(""))
  end

  def test_initials_at_end
    assert_equal(Name.new(initials: "MAJ", last: "Vaile"), Name.last_title_first("Vaile, M.A.J."))
    assert_equal(Name.new(initials: "M", last: "Turnbull"), Name.last_title_first("Turnbull, M."))
  end

  def test_initials_with_spaces
    assert_equal(Name.new(last: "Wakelin", initials: "BH"), Name.last_title_first("Wakelin, B. H."))
  end

  # If only people could learn how to type properly
  def test_initials_with_multiple_fullstops
    assert_equal(Name.new(last: "Trood", initials: "RB"), Name.last_title_first("Trood R.B.."))
  end
end
