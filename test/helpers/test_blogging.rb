# encoding: utf-8

require 'test/helper'

class Nanoc3::Helpers::BloggingTest < MiniTest::Unit::TestCase

  include Nanoc3::TestHelpers

  include Nanoc3::Helpers::Blogging
  include Nanoc3::Helpers::Text

  def mock_article
    item = mock
    item.stubs(:[]).with(:updated_at).returns(Time.now - 500)
    item.stubs(:[]).with(:kind).returns('article')
    item.stubs(:[]).with(:created_at).returns(Time.now - 1000)
    item.stubs(:[]).with(:title).returns('An Item')
    item.stubs(:[]).with(:custom_path_in_feed).returns(nil)
    item.stubs(:[]).with(:custom_url_in_feed).returns(nil)
    item.stubs(:[]).with(:excerpt).returns(nil)
    item.stubs(:path).returns("/item/")
    item.stubs(:author_name).returns(nil)
    item.stubs(:author_uri).returns(nil)
    item.stubs(:compiled_content).returns('item content')
    item
  end

  def mock_item
    item = mock
    item.stubs(:[]).with(:kind).returns('item')
    item
  end

  def test_articles
    # Create items
    @items = [
      Nanoc3::Item.new(
        'blah',
        { :kind => 'item' },
        '/0/'
      ),
      Nanoc3::Item.new(
        'blah blah',
        { :kind => 'article' },
        '/1/'
      ),
      Nanoc3::Item.new(
        'blah blah blah',
        { :kind => 'article' },
        '/2/'
      )
    ]

    # Check
    assert_equal(2, articles.size)
    assert articles.include?(@items[1])
    assert articles.include?(@items[2])
  ensure
    # Cleanup
    @items = nil
  end

  def test_sorted_articles
    # Create items
    @items = [
      Nanoc3::Item.new(
        'blah',
        { :kind => 'item' },
        '/0/'
      ),
      Nanoc3::Item.new(
        'blah',
        { :kind => 'article', :created_at => (Time.now - 1000).to_s },
        '/1/'
      ),
      Nanoc3::Item.new(
        'blah',
        { :kind => 'article', :created_at => (Time.now - 500).to_s },
        '/2/'
      )
    ]

    # Check
    assert_equal(2,         sorted_articles.size)
    assert_equal(@items[2], sorted_articles[0])
    assert_equal(@items[1], sorted_articles[1])
  ensure
    # Cleanup
    @items = nil
  end

  def test_atom_feed
    if_have 'builder' do
      # Create items
      @items = [ mock, mock_article, mock_article ]

      # Create item 0
      @items[0].stubs(:[]).with(:kind).returns('item')

      # Create item 1
      @items[1].expects(:compiled_content).with(:snapshot => :pre).returns('item 1 content')

      # Create item 2
      @items[2].expects(:compiled_content).with(:snapshot => :pre).returns('item 2 content')

      # Mock site
      @site = mock
      @site.stubs(:config).returns({ :base_url => 'http://example.com' })

      # Create feed item
      @item = mock
      @item.stubs(:[]).with(:title).returns('My Cool Blog')
      @item.stubs(:[]).with(:author_name).returns('Denis Defreyne')
      @item.stubs(:[]).with(:author_uri).returns('http://stoneship.org/')
      @item.stubs(:[]).with(:feed_url).returns(nil)
      @item.stubs(:path).returns("/journal/feed/")

      # Check
      atom_feed
    end
  end

  def test_atom_feed_with_times
    if_have 'builder' do
      # Create items
      @items = [ mock_item, mock_article, mock_article ]

      # Create item 1
      @items[1].stubs(:[]).with(:updated_at).returns(Time.now - 500)
      @items[1].stubs(:[]).with(:created_at).returns(Time.now - 1000)
      @items[1].expects(:compiled_content).returns('item 1 content')

      # Create item 2
      @items[2].stubs(:[]).with(:updated_at).returns(Time.now - 250)
      @items[2].stubs(:[]).with(:created_at).returns(Time.now - 1200)
      @items[2].expects(:compiled_content).returns('item 2 content')

      # Mock site
      @site = mock
      @site.stubs(:config).returns({ :base_url => 'http://example.com' })

      # Create feed item
      @item = mock
      @item.stubs(:[]).with(:title).returns('My Cool Blog')
      @item.stubs(:[]).with(:author_name).returns('Denis Defreyne')
      @item.stubs(:[]).with(:author_uri).returns('http://stoneship.org/')
      @item.stubs(:[]).with(:feed_url).returns(nil)
      @item.stubs(:path).returns("/journal/feed/")

      # Check
      atom_feed
    end
  end

  def test_atom_feed_without_articles
    if_have 'builder' do
      # Mock items
      @items = [ mock_item, mock_item ]

      # Mock site
      @site = mock
      @site.stubs(:config).returns({ :base_url => 'http://example.com' })

      # Create feed item
      @item = mock
      @item.stubs(:[]).with(:title).returns('My Blog Or Something')
      @item.stubs(:[]).with(:author_name).returns('J. Doe')
      @item.stubs(:[]).with(:author_uri).returns('http://example.com/~jdoe')

      # Check
      error = assert_raises(RuntimeError) do
        atom_feed
      end
      assert_equal(
        'Cannot build Atom feed: no articles',
        error.message
      )
    end
  end

  def test_atom_feed_without_base_url
    if_have 'builder' do
      # Create items
      @items = [ mock_item, mock_article ]

      # Mock site
      @site = mock
      @site.stubs(:config).returns({:base_url => nil})

      # Create feed item
      @item = mock
      @item.stubs(:[]).with(:title).returns('My Blog Or Something')
      @item.stubs(:[]).with(:author_name).returns('J. Doe')
      @item.stubs(:[]).with(:author_uri).returns('http://example.com/~jdoe')

      # Check
      error = assert_raises(RuntimeError) do
        atom_feed
      end
      assert_equal(
        'Cannot build Atom feed: site configuration has no base_url',
        error.message
      )
    end
  end

  def test_atom_feed_without_title
    if_have 'builder' do
      # Create items
      @items = [ mock_item, mock_article ]

      # Mock site
      @site = mock
      @site.stubs(:config).returns({ :base_url => 'http://example.com' })

      # Create feed item
      @item = mock
      @item.stubs(:[]).with(:title).returns(nil)
      @item.stubs(:[]).with(:author_name).returns('J. Doe')
      @item.stubs(:[]).with(:author_uri).returns('http://example.com/~jdoe')

      # Check
      error = assert_raises(RuntimeError) do
        atom_feed
      end
      assert_equal(
        'Cannot build Atom feed: no title in params, item or site config',
        error.message
      )
    end
  end

  def test_atom_feed_without_author_name
    if_have 'builder' do
      # Create items
      @items = [ mock_item, mock_article ]

      # Mock site
      @site = mock
      @site.stubs(:config).returns({ :base_url => 'http://example.com' })

      # Create feed item
      @item = mock
      @item.stubs(:[]).with(:title).returns('My Blog Or Something')
      @item.stubs(:[]).with(:author_name).returns(nil)
      @item.stubs(:[]).with(:author_uri).returns('http://example.com/~jdoe')

      # Check
      error = assert_raises(RuntimeError) do
        atom_feed
      end
      assert_equal(
        'Cannot build Atom feed: no author_name in params, item or site config',
        error.message
      )
    end
  end

  def test_atom_feed_without_author_uri
    if_have 'builder' do
      # Create items
      @items = [ mock_item, mock_article ]

      # Mock site
      @site = mock
      @site.stubs(:config).returns({ :base_url => 'http://example.com' })

      # Create feed item
      @item = mock
      @item.stubs(:[]).with(:title).returns('My Blog Or Something')
      @item.stubs(:[]).with(:author_name).returns('J. Doe')
      @item.stubs(:[]).with(:author_uri).returns(nil)

      # Check
      error = assert_raises(RuntimeError) do
        atom_feed
      end
      assert_equal(
        'Cannot build Atom feed: no author_uri in params, item or site config',
        error.message
      )
    end
  end

  def test_atom_feed_without_articles_created_at
    if_have 'builder' do
      # Create items
      @items = [ mock_item, mock_article, mock_article ]
      @items[1].stubs(:[]).with(:created_at).returns(Time.now.to_s)
      @items[2].stubs(:[]).with(:created_at).returns(nil)

      # Mock site
      @site = mock
      @site.stubs(:config).returns({ :base_url => 'http://example.com' })

      # Create feed item
      @item = mock
      @item.stubs(:[]).with(:title).returns('My Blog Or Something')
      @item.stubs(:[]).with(:author_name).returns('J. Doe')
      @item.stubs(:[]).with(:author_uri).returns('http://example.com/~jdoe')

      # Check
      error = assert_raises(RuntimeError) do
        atom_feed
      end
      assert_equal(
        'Cannot build Atom feed: one or more articles lack created_at',
        error.message
      )
    end
  end

  def test_atom_feed_with_title_author_name_and_uri_as_params
    if_have 'builder' do
      # Create items
      @items = [ mock_item, mock_article ]
      @items[1].expects(:compiled_content).with(:snapshot => :pre).returns('asdf')

      # Mock site
      @site = mock
      @site.stubs(:config).returns({ :base_url => 'http://example.com' })

      # Create feed item
      @item = mock
      @item.stubs(:[]).with(:title).returns(nil)
      @item.stubs(:[]).with(:author_name).returns(nil)
      @item.stubs(:[]).with(:author_uri).returns(nil)
      @item.stubs(:[]).with(:[]).with(:feed_url).returns('http://example.com/feed')

      # Check
      atom_feed(
        :author_name => 'Bob',
        :author_uri  => 'http://example.com/~bob/',
        :title       => 'My Blog Or Something'
      )
    end
  end

  def test_atom_feed_with_title_author_name_and_uri_from_config
    if_have 'builder' do
      # Create items
      @items = [ mock_item, mock_article ]
      @items[1].expects(:compiled_content).with(:snapshot => :pre).returns('asdf')

      # Mock site
      @config = {
        :author_name => 'Bob',
        :author_uri  => 'http://example.com/~bob/',
        :title       => 'My Blog Or Something',
        :base_url    => 'http://example.com'
      }
      @site = mock
      @site.stubs(:config).returns(@config)

      # Create feed item
      @item = mock
      @item.stubs(:[]).with(:title).returns(nil)
      @item.stubs(:[]).with(:author_name).returns(nil)
      @item.stubs(:[]).with(:author_uri).returns(nil)
      @item.stubs(:[]).with(:[]).with(:feed_url).returns('http://example.com/feed')

      # Check
      atom_feed
    end
  end

  def test_atom_feed_with_articles_param
    if_have 'builder' do
      # Mock items
      @items = [ mock_article, mock_article ]

      @items[0].expects(:compiled_content).never
      @items[1].stubs(:[]).with(:title).returns('Item One')
      @items[1].expects(:compiled_content).with(:snapshot => :pre).returns('asdf')

      # Mock site
      @site = mock
      @site.stubs(:config).returns({ :base_url => 'http://example.com' })

      # Create feed item
      @item = mock
      @item.stubs(:[]).with(:title).returns('My Blog Or Something')
      @item.stubs(:[]).with(:author_name).returns('J. Doe')
      @item.stubs(:[]).with(:author_uri).returns('http://example.com/~jdoe')
      @item.stubs(:[]).with(:[]).with(:feed_url).returns('http://example.com/feed')

      # Check
      atom_feed :articles => [ @items[1] ]
    end
  end

  def test_atom_feed_with_limit_param
    if_have 'builder' do
      # Mock articles
      @items = [ mock_article, mock_article ]
      @items.each_with_index do |article, i|
        article.stubs(:[]).with(:title).returns("Article #{i}")
        article.stubs(:[]).with(:created_at).returns(Time.now - i)
      end

      # Mock site
      @site = mock
      @site.stubs(:config).returns({ :base_url => 'http://example.com' })

      # Create feed item
      @item = mock
      @item.stubs(:[]).with(:title).returns('My Blog Or Something')
      @item.stubs(:[]).with(:author_name).returns('J. Doe')
      @item.stubs(:[]).with(:author_uri).returns('http://example.com/~jdoe')
      @item.stubs(:[]).with(:feed_url).returns('http://example.com/feed')

      # Check
      result = atom_feed :limit => 1, :articles => @items
      assert_match(
        Regexp.new('Article 0', Regexp::MULTILINE),
        result
      )
      refute_match(
        Regexp.new('Article 1', Regexp::MULTILINE),
        result
      )
    end
  end

  def test_atom_feed_sorting
    if_have 'builder' do
      # Mock articles
      @items = [ mock_article, mock_article ]
      @items.each_with_index do |article, i|
        article.stubs(:[]).with(:title).returns("Article #{i}")
      end
      @items[0].stubs(:[]).with(:created_at).returns('23-02-2009')
      @items[1].stubs(:[]).with(:created_at).returns('22-03-2009')

      # Mock site
      @site = mock
      @site.stubs(:config).returns({ :base_url => 'http://example.com' })

      # Create feed item
      @item = mock
      @item.stubs(:[]).with(:title).returns('My Blog Or Something')
      @item.stubs(:[]).with(:author_name).returns('J. Doe')
      @item.stubs(:[]).with(:author_uri).returns('http://example.com/~jdoe')
      @item.stubs(:[]).with(:feed_url).returns('http://example.com/feed')

      # Check
      result = atom_feed
      assert_match(
        Regexp.new('Article 1.*Article 0', Regexp::MULTILINE),
        result
      )
    end
  end

  def test_atom_feed_with_content_proc_param
    if_have 'builder' do
      # Mock article
      @items = [ mock_article ]

      # Mock site
      @site = mock
      @site.stubs(:config).returns({ :base_url => 'http://example.com' })

      # Create feed item
      @item = mock
      @item.stubs(:[]).with(:title).returns('My Blog Or Something')
      @item.stubs(:[]).with(:author_name).returns('J. Doe')
      @item.stubs(:[]).with(:author_uri).returns('http://example.com/~jdoe')
      @item.stubs(:[]).with(:feed_url).returns('http://example.com/feed')

      # Check
      result = atom_feed :content_proc => lambda { |a| 'foobar!' }
      assert_match 'foobar!</content>', result
    end
  end

  def test_atom_feed_with_excerpt_proc_param
    if_have 'builder' do
      # Mock article
      @items = [ mock_article ]

      # Mock site
      @site = mock
      @site.stubs(:config).returns({ :base_url => 'http://example.com' })

      # Create feed item
      @item = mock
      @item.stubs(:[]).with(:title).returns('My Blog Or Something')
      @item.stubs(:[]).with(:author_name).returns('J. Doe')
      @item.stubs(:[]).with(:author_uri).returns('http://example.com/~jdoe')
      @item.stubs(:[]).with(:[]).with(:feed_url).returns('http://example.com/feed')

      # Check
      result = atom_feed :excerpt_proc => lambda { |a| 'foobar!' }
      assert_match 'foobar!</summary>', result
    end
  end

  def test_atom_feed_with_item_without_path
    if_have 'builder' do
      # Create items
      @items = [ mock_article ]
      @items[0].stubs(:path).returns(nil)

      # Mock site
      @site = mock
      @site.stubs(:config).returns({ :base_url => 'http://example.com' })

      # Create feed item
      @item = mock
      @item.stubs(:identifier).returns('/feed/')
      @item.stubs(:[]).with(:title).returns('My Cool Blog')
      @item.stubs(:[]).with(:author_name).returns('Denis Defreyne')
      @item.stubs(:[]).with(:author_uri).returns('http://stoneship.org/')
      @item.stubs(:[]).with(:feed_url).returns(nil)
      @item.stubs(:path).returns("/journal/feed/")

      # Check
      atom_feed
    end
  end

  def test_url_for_without_custom_path_in_feed
    # Create site
    @site = Nanoc3::Site.new({ :base_url => 'http://example.com' })

    # Create article
    item = Nanoc3::Item.new('content', {}, '/foo/')
    item.reps << Nanoc3::ItemRep.new(item, :default)
    item.reps[0].path = '/foo/bar/'

    # Check
    assert_equal('http://example.com/foo/bar/', url_for(item))
  ensure
    # Cleanup
    @item = nil
  end

  def test_url_for_with_custom_path_in_feed
    # Create site
    @site = Nanoc3::Site.new({ :base_url => 'http://example.com' })

    # Create article
    item = Nanoc3::Item.new(
      'content', { :custom_path_in_feed => '/meow/woof/' }, '/foo/')
    item.reps << Nanoc3::ItemRep.new(item, :default)

    # Check
    assert_equal('http://example.com/meow/woof/', url_for(item))
  ensure
    # Cleanup
    @item = nil
  end

  def test_url_for_with_custom_url_in_feed
    # Create site
    @site = Nanoc3::Site.new({ :base_url => 'http://example.com' })

    # Create article
    item = Nanoc3::Item.new(
      'content', { :custom_url_in_feed => 'http://example.org/x' }, '/foo/')
    item.reps << Nanoc3::ItemRep.new(item, :default)

    # Check
    assert_equal('http://example.org/x', url_for(item))
  ensure
    # Cleanup
    @item = nil
  end

  def test_url_for_without_base_url
    # Create site
    @site = Nanoc3::Site.new({})

    # Check
    assert_raises(RuntimeError) do
      url_for(nil)
    end
  end

  def test_url_for_without_path
    # Create site
    @site = Nanoc3::Site.new({ :base_url => 'http://example.com' })

    # Create article
    item = Nanoc3::Item.new('content', {}, '/foo/')
    item.reps << Nanoc3::ItemRep.new(item, :default)
    item.reps[0].path = nil

    # Check
    assert_equal(nil, url_for(item))
  end

  def test_feed_url_without_custom_feed_url
    # Create site
    @site = Nanoc3::Site.new({ :base_url => 'http://example.com' })

    # Create article
    @item = Nanoc3::Item.new('content', {}, '/foo/')
    @item.reps << Nanoc3::ItemRep.new(@item, :default)
    @item.reps[0].path = '/foo/bar/'

    # Check
    assert_equal('http://example.com/foo/bar/', feed_url)
  ensure
    # Cleanup
    @item = nil
  end

  def test_feed_url_with_custom_feed_url
    # Create site
    @site = Nanoc3::Site.new({ :base_url => 'http://example.com' })

    # Create feed item
    @item = Nanoc3::Item.new('content', { :feed_url => 'http://example.com/feed/' }, '/foo/')
    @item.reps << Nanoc3::ItemRep.new(@item, :default)
    @item.reps[0].path = '/foo/bar/'

    # Check
    assert_equal('http://example.com/feed/', feed_url)
  ensure
    # Cleanup
    @item = nil
  end

  def test_feed_url_without_base_url
    # Create site
    @site = Nanoc3::Site.new({})

    # Check
    assert_raises(RuntimeError) do
      feed_url
    end
  end

  def test_atom_tag_for_with_path
    # Create site
    @site = Nanoc3::Site.new({ :base_url => 'http://example.com' })

    # Create article
    item = Nanoc3::Item.new('content', { :created_at => '2008-05-19' }, '/foo/')
    item.reps << Nanoc3::ItemRep.new(item, :default)
    item.reps[0].path = '/foo/bar/'

    # Check
    assert_equal('tag:example.com,2008-05-19:/foo/bar/', atom_tag_for(item))
  end

  def test_atom_tag_for_without_path
    # Create site
    @site = Nanoc3::Site.new({ :base_url => 'http://example.com' })

    # Create article
    item = Nanoc3::Item.new('content', { :created_at => '2008-05-19' }, '/baz/qux/')
    item.reps << Nanoc3::ItemRep.new(item, :default)

    # Check
    assert_equal('tag:example.com,2008-05-19:/baz/qux/', atom_tag_for(item))
  end

  def test_atom_tag_for_with_base_url_in_dir
    # Create site
    @site = Nanoc3::Site.new({ :base_url => 'http://example.com/somedir' })

    # Create article
    item = Nanoc3::Item.new('content', { :created_at => '2008-05-19' }, '/foo/')
    item.reps << Nanoc3::ItemRep.new(item, :default)
    item.reps[0].path = '/foo/bar/'

    # Check
    assert_equal('tag:example.com,2008-05-19:/somedir/foo/bar/', atom_tag_for(item))
  end

end
