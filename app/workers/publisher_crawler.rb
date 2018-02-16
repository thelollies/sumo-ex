require 'wombat'
require 'uri'

class PublisherCrawler
  include Sidekiq::Worker

  def perform( domain )

    # TODO check for crawler already running for this domain

    alexa_results = PublisherCrawler.scrape_alexa_for( domain )

    # Run in transaction so that if creating the new records fails we don't
    # clean out the old records.
    #
    DomainCountry.transaction do

      # Delete old records
      DomainCountry.where( "domain = ?", domain ).delete_all

      # Create new records
      alexa_results[ 'countries' ].each do | result |
        DomainCountry.create!(
          domain:     domain,
          country:    result[ 'country' ].gsub(/\A\p{Space}*/, ''), # Remove leading space
          percentage: result[ 'percentage' ]
      )
      end
    end

    # Now look up the domain itself
    domain_results = PublisherCrawler.domain_links_summary( domain )

    # Run in transaction so that if creating the new record fails we don't
    # clean out the old record.
    #
    Website.transaction do

      # Delete old record
      Website.where( "domain = ?", domain ).delete_all

      # Create new record
      Website.create!(
        domain: domain,
        num_external_links: domain_results[ :num_external_links ],
        num_internal_links: domain_results[ :num_internal_links ]
      )

    end

  end

  def self.scrape_alexa_for( domain )

    return Wombat.crawl do
      base_url "https://www.alexa.com/"
      path "/siteinfo/#{ domain }"

      countries "css=#demographics_div_country_table tbody tr", :iterator do
        country    xpath: "td[1]"
        percentage xpath: "td[2]"
      end

    end

  end

  def self.domain_links_summary( domain )

    # Add the scheme if it is missing
    domain_uri = URI.parse( domain )
    if !domain_uri.scheme
      domain = "http://#{ domain }"
      domain_uri = URI.parse( domain )
    end

    # Fetch all the links for the website
    results = Wombat.crawl do
      base_url domain
      path "/"

      links( { xpath: "//a/@href" }, :list )
    end

    # Construct a regex to match for the same host or the same host with a
    # subdomain.
    #
    matching_host_regex = /^(.*\.)*#{ domain_uri.host }$/

    # For counting
    links_external = 0
    links_internal = 0

    # Categorise the links
    results[ 'links' ].each do | uri_string |
      uri = URI.parse( uri_string )

      # If the host of the link is nil (local link) or for a host with the
      # same host (ignoring subdomains) it is an internal link.
      #
      if uri.host == nil || matching_host_regex.match( uri.host ) != nil
        links_internal += 1
      else
        links_external += 1
      end

    end

    return {
      num_external_links: links_external,
      num_internal_links: links_internal
    }

  end

end
