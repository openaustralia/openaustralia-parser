$:.unshift "#{File.dirname(__FILE__)}/../lib"

require 'test/unit'
require 'name'

class TestName < Test::Unit::TestCase
  def setup
    @matthew = Name.new(:first => "Matthew", :middle => "Noah", :last => "Landauer")
    @joanna_gash = Name.new(:first => "Joanna", :last => "Gash")
  end
  
  def test_new
    assert_equal("Matthew", @matthew.first)
    assert_equal("Noah", @matthew.middle)
    assert_equal("Landauer", @matthew.last)
  end
  
  def test_new_wrong_parameters
    assert_raise(NameError){ Name.new(:first => "foo", :blah => "dibble") }
  end
  
  def test_equals
    assert_equal(@matthew, Name.new(:last => "Landauer", :middle => "Noah", :first => "Matthew"))
    assert_not_equal(@matthew, Name.new(:last => "Landauer"))
  end
  
  def test_simple_parse
    assert_equal(@joanna_gash, Name.last_title_first("Gash Joanna"))
  end
  
  def test_capitals
    assert_equal(@joanna_gash, Name.last_title_first("GASH joanna"))
  end
  
  def test_comma
    assert_equal(@joanna_gash, Name.last_title_first("Gash, Joanna"))
  end
  
  def test_middle_name
    assert_equal(Name.new(:last => "Albanese", :first => "Anthony", :middle => "Norman"),
      Name.last_title_first("Albanese Anthony Norman"))
  end
  
  def test_two_middle_names
    assert_equal(Name.new(:last => "Albanese", :first => "Anthony", :middle => "Norman peter"),
      Name.last_title_first("Albanese Anthony Norman Peter"))
  end
  
  def test_the_hon
    assert_equal(Name.new(:last => "Baird", :title => "the Hon.", :first => "Bruce", :middle => "George"),
      Name.last_title_first("Baird the Hon. Bruce George"))
  end
  
  def test_nickname
    assert_equal(Name.new(:last => "Abbott", :title => "the Hon.", :first => "Anthony", :nick => "Tony", :middle => "John"),
      Name.last_title_first("ABBOTT, the Hon. Anthony (Tony) John"))
  end
  
  def test_dr
    assert_equal(Name.new(:last => "Emerson", :title => "Dr", :first => "Craig", :middle => "Anthony"),
      Name.last_title_first("EMERSON, Dr Craig Anthony"))
  end
  
  def test_informal_name
    assert_equal("Matthew Landauer", Name.new(:first => "Matthew", :last => "Landauer", :title => "Dr").informal_name)
    assert_equal("Matt Landauer", Name.new(:first => "Matthew", :nick => "Matt", :last => "Landauer", :title => "Dr").informal_name)
  end
  
  def test_full_name
    name = Name.new(:last => "Abbott", :title => "the Hon.", :first => "Anthony", :nick => "Tony", :middle => "John")
    assert_equal("the Hon. Anthony (Tony) John Abbott", name.full_name)
  end
  
  def test_capitals_irish_name
    assert_equal("O'Connor", Name.new(:last => "o'connor").last)
  end
  
  def test_capitals_scottish_name
    assert_equal("McMullan", Name.new(:last => "mcmullan").last)
  end
  
  def test_dath
    assert_equal("D'Ath", Name.new(:last => "d’ath").last)
  end
  
  def test_title_first_last
    assert_equal(Name.new(:title => "Dr", :first => "John", :last => "Smith"), Name.title_first_last("Dr John Smith"))
    assert_equal(Name.new(:title => "Dr", :last => "Smith"), Name.title_first_last("Dr Smith"))
    assert_equal(Name.new(:title => "Mr", :last => "Smith"), Name.title_first_last("Mr Smith"))
    assert_equal(Name.new(:title => "Mrs", :last => "Smith"), Name.title_first_last("Mrs Smith"))
    assert_equal(Name.new(:title => "Ms", :first => "Julie", :last => "Smith"), Name.title_first_last("Ms Julie Smith"))
    assert_equal(Name.new(:title => "Ms", :first => "Julie", :middle => "Sarah Marie", :last => "Smith"),
      Name.title_first_last("Ms Julie Sarah Marie Smith"))
  end
  
  def test_john_debus
    # He has a title of "Hon." rather than "the Hon."
    name = Name.last_title_first("DEBUS, Hon. Robert (Bob) John")
    assert_equal("Debus", name.last)
    assert_equal("Hon.", name.title)
    assert_equal("Robert", name.first)
    assert_equal("Bob", name.nick)
    assert_equal("John", name.middle)
  end
  
  # Deal with weirdo titles at the end
  def test_post_title
    name = Name.last_title_first("COMBET, the Hon. Gregory (Greg) Ivan, AM")
    assert_equal("Combet", name.last)
    assert_equal("the Hon.", name.title)
    assert_equal("Gregory", name.first)
    assert_equal("Greg", name.nick)
    assert_equal("Ivan", name.middle)
    assert_equal("AM", name.post_title)
  end
  
  def test_post_title_MBE
    assert_equal(Name.new(:first => "John", :last => "Smith", :post_title => "MBE"), Name.last_title_first("Smith, John, MBE"))
  end
  
  def test_post_title_QC
    assert_equal(Name.new(:first => "John", :last => "Smith", :post_title => "QC"), Name.last_title_first("Smith, John, QC"))
  end
  
  def test_post_title_OBE
    assert_equal(Name.new(:first => "John", :last => "Smith", :post_title => "OBE"), Name.last_title_first("Smith, John, OBE"))
  end
  
  def test_post_title_KSJ
    assert_equal(Name.new(:first => "John", :last => "Smith", :post_title => "KSJ"), Name.last_title_first("Smith, John, KSJ"))
  end
  
  def test_post_title_JP
    assert_equal(Name.new(:first => "John", :last => "Smith", :post_title => "JP"), Name.last_title_first("Smith, John, JP"))
  end
  
  def test_capilisation_on_middle_name
    assert_equal("McCahon", Name.new(:middle => "mccahon").middle)
  end
  
  def test_ian_sinclair
    assert_equal(Name.new(:last => "Sinclair", :title => "the Rt Hon.", :first => "Ian", :middle => "McCahon"),
      Name.last_title_first("SINCLAIR, the Rt Hon. Ian Mccahon"))
  end
  
  def test_two_post_titles
    assert_equal(Name.new(:last => "Williams", :title => "the Hon.", :first => "Daryl", :middle => "Robert", :post_title => "AM QC"),
      Name.last_title_first("WILLIAMS, the Hon. Daryl Robert, AM, QC"))
  end
  
  def test_stott_despoja
    # Difficult situation of two last names which aren't hyphenated
    assert_equal(Name.new(:last => "Stott Despoja", :first => "Natasha", :middle => "Jessica"),
      Name.last_title_first("STOTT DESPOJA, Natasha Jessica"))
  end
  
  # Class for simple (naive) way of comparing two names. Only compares parts of the name
  # that exist in both names
  def test_matches
    dr_john_smith = Name.new(:title => "Dr", :first => "John", :last => "Smith")
    john_smith = Name.new(:first => "John", :last => "Smith")
    peter_smith = Name.new(:first => "Peter", :last => "Smith")
    smith = Name.new(:last => "Smith")
    dr_john = Name.new(:title => "Dr", :first => "John")
    assert(dr_john_smith.matches?(dr_john_smith))
    assert(!dr_john_smith.matches?(peter_smith))
    # When there is no overlap between the names they should not match
    assert(!smith.matches?(dr_john))
  end
  
  def test_nickname_after_middle_names
    assert_equal(Name.new(:last => "Macdonald", :title => "the Hon.", :first => "John", :middle => "Alexander Lindsay", :nick => "Sandy"),
      Name.last_title_first("MACDONALD, the Hon. John Alexander Lindsay (Sandy)"))
  end
  
  def test_matches_when_firstname_is_actually_nickname
    # The form of the name that's used in one of the speeches
    # Note that the first name is actually a nickname
    name_speech = Name.new(:first => "Fran", :last => "Bailey")
    # Form of the name as it is stored internally (from members.csv)
    name_members = Name.new(:first => "Frances", :last => "Bailey", :nick => "Fran")
    
    # We need these two forms to match
    assert(name_speech.matches?(name_members))
    assert(name_members.matches?(name_speech))
  end
  
  def test_initials_when_not_given
    name = Name.new(:first => "john", :last => "smith")
    assert_equal("J", name.initials)
    name = Name.new(:first => "john", :middle => "edward", :last => "smith")
    assert_equal("JE", name.initials)
  end
  
  def test_initials_when_given
    name = Name.new(:initials => "je", :last => "smith")
    assert_equal("JE", name.initials)
  end
  
  def test_initials_when_given_but_do_not_match_first_and_middle_name
    assert_raise(NameError) do
      name = Name.new(:first => "John", :middle => "Edward", :initials => "J")
    end
  end
end