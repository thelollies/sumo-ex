require_relative '../test_helper'
class PublisherCrawlerTest < MiniTest::Unit::TestCase

  def teardown
    DomainCountry.delete_all
    Website.delete_all
  end

  def test_domain_countries_populated_correctly

    assert( DomainCountry.count == 0, "No DomainCountrys before crawling" )

    VCR.use_cassette( 'vice.com' ) do
      PublisherCrawler.new.perform( 'vice.com' )
    end

    domain_results = DomainCountry.where( domain: 'vice.com' ).
      order( created_at: :asc ).pluck( :country, :percentage )
    expected_domain_results = [
      [ "United States",  40.9 ],
      [ "United Kingdom", 7.3  ],
      [ "Canada",         5.9  ],
      [ "Germany",        4.9  ],
      [ "France",         3.9  ]
    ]

    assert( domain_results[ 0 ] == expected_domain_results[ 0 ], "Correcetly parses the alexa page"  )

  end

  def test_websites_populated_correctly

    assert( Website.count == 0, "No Websites before crawling" )

    VCR.use_cassette( 'vice.com' ) do
      PublisherCrawler.new.perform( 'vice.com' )
    end

    website_result = Website.where( domain: 'vice.com' ).first

    assert( website_result.num_external_links == 13, "Correcetly counts external links"  )
    assert( website_result.num_internal_links == 61, "Correcetly counts external links"  )

  end

  def test_overwrites_old_data

    VCR.use_cassette( 'vice.com' ) do
      PublisherCrawler.new.perform( 'vice.com' )
    end

    assert( DomainCountry.count == 5 && Website.count == 1, "Stores crawled data" )

    VCR.use_cassette( 'vice.com' ) do
      PublisherCrawler.new.perform( 'vice.com' )
    end

    assert( DomainCountry.first.id > 5 && Website.first.id > 1, "Overwrites old data" )
    assert( DomainCountry.count == 5 && Website.count == 1, "Overwrites old data" )

  end

end
