class PublisherCrawler
  include Sidekiq::Worker

  def perform( website )
    # Do something
    #
    puts "Crawling #{ website }"
  end
end
